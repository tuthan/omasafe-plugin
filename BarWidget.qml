import QtQuick
import qs.Commons
import qs.Ui
import Quickshell
import Quickshell.Io
import "model/Time.js" as Time

BarWidget {
  id: root
  moduleName: "io.github.tuthan.omasafe"

  property int alertCount: 0
  property int outstandingCount: 0
  property int newCount: 0
  property var alerts: []
  property string scanState: "checking"
  property bool scanResultsStale: false
  property string highestSeverity: "none"
  property string limitation: ""
  property string cliError: ""
  property string lastScanAt: ""
  property string cliPath: ""
  // cliResolver runs asynchronously; until it exits we can't tell "CLI absent"
  // from "not resolved yet", so a scan requested in that window is deferred.
  property bool cliResolved: false
  property bool scanRequested: false
  // A resolved binary is only trusted to run scans once `--version` confirms it
  // behaves like a compatible omasafe-cli. This is a compatibility gate, not an
  // authenticity control: the version is self-reported and thus spoofable, so it
  // rejects wrong/incompatible tooling but cannot detect a deliberately hostile
  // binary that mimics the expected output.
  property bool cliCompatible: false
  property string cliVersion: ""
  // Raw `--version` output, held only between the probe's stdout and its exit so
  // the version is authorized from the exit handler, never from stdout alone.
  property string cliVersionOutput: ""
  // Latches the first terminal decision for a probe (timeout OR exit). Whichever
  // fires first wins; every later callback for that probe is ignored, so a
  // process that survives SIGTERM and exits 0 after timing out cannot re-authorize.
  property bool versionSettled: false

  // Scan output must be accumulated whole to be parsed as one JSON document, so it
  // is bounded: a faulty or replaced CLI could otherwise flood stdout/stderr and
  // grow this long-lived shell's memory. Each stream is capped independently;
  // crossing the cap latches overflow, hard-kills the process, and drops the
  // partial buffers unparsed. A legitimate `scan --format json` report is tiny, so
  // the cap only ever trips on malfunctioning or hostile output.
  //
  // The cap counts UTF-16 code units, per stream, so worst-case retained output is
  // ~2x scanOutputCharCap bytes across the two streams, plus transient concat and
  // parse allocations. It is a hard bound, not a precise byte budget.
  property string scanStdout: ""
  property string scanStderr: ""
  readonly property int scanOutputCharCap: 4 * 1024 * 1024
  // Latches the first terminal decision for a scan (overflow, timeout, or exit) so
  // a later callback cannot re-parse output or overwrite the resulting state.
  property bool scanSettled: false

  // The scan result is a small, parsed snapshot so a shell restart can show the
  // last known state without pretending it is fresh. Raw stdout/stderr and the
  // potentially large analysis payload never enter this cache.
  readonly property string cacheHome: {
    var configured = String(Quickshell.env("XDG_CACHE_HOME") || "").trim()
    var home = String(Quickshell.env("HOME") || "").trim()
    return configured !== "" ? configured : home + "/.cache"
  }
  readonly property string scanCacheDir: root.cacheHome + "/omasafe"
  readonly property string scanCachePath: root.scanCacheDir + "/last-scan.json"
  property bool scanCacheDirReady: false
  property bool scanCacheReady: false
  property bool scanCacheHydrated: false
  property var pendingScanCache: null
  property var cachedScanSnapshot: null
  property string scanCacheError: ""

  // Single authorization gate for every operational CLI command (scan and every
  // panel command). A command may only run once resolution completed, a path was
  // found, and the version probe passed.
  readonly property bool cliVerified: root.cliResolved && root.cliCompatible &&
    root.cliPath !== ""

  // v0.2 features require the CLI floor; operators may raise it in settings.
  readonly property string configuredCliVersionMin: settings &&
    settings.cliVersionMin !== undefined ? String(settings.cliVersionMin) : ""
  readonly property bool cliVersionMinInvalid: settings &&
    settings.cliVersionMin !== undefined &&
    !/^\d+\.\d+(?:\.\d+)?$/.test(root.configuredCliVersionMin.trim())
  readonly property string cliVersionMin: {
    var floor = [0, 2, 1]
    var configured = root.parseVersion(root.configuredCliVersionMin)
    return configured && root.compareVersion(configured, floor) > 0
      ? configured.join(".") : "0.2.1"
  }
  readonly property bool cliVersionRequireIdentity: settings &&
    settings.cliVersionRequireIdentity === true

  readonly property bool periodicScanEnabled: settings &&
    settings.periodicScanEnabled === true
  readonly property int periodicScanIntervalMinutes: {
    var configured = settings ? Number(settings.periodicScanIntervalMinutes) : 5
    if (!isFinite(configured)) configured = 5
    return Math.max(1, Math.min(1440, Math.round(configured)))
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  // The Row/Column of icon + count sizes the widget; a vertical bar stacks them
  // (doc 03 §2). visible: !vertical is gone — the container handles both bars.
  implicitWidth: iconRow.implicitWidth
  implicitHeight: iconRow.implicitHeight

  // The bar keeps its existing urgent token contract; row-level semantic tiers live
  // in components/SemanticMark.qml and are not painted into this compact icon.
  readonly property color warningColor: bar ? bar.urgent : Color.urgent
  readonly property string statusLevel: root.scanState === "checking"
    ? "checking" : (root.scanState === "ready" ? "ready"
      : (root.scanState === "missing-cli" || root.scanState === "unavailable" ||
        root.scanState === "incompatible-cli" ? "unknown"
        : (root.highestSeverity === "critical" ? "critical"
          : (root.outstandingCount > 0 ? "warning" : "normal"))))

  // Bar-state inputs for the OmaSafeShield contract (doc 03 §2), each with an
  // explicit false/zero fallback.
  readonly property color barForeground: bar ? bar.barForeground : Color.foreground
  function dimStep(k) {
    var b = Color.background
    return Qt.rgba(barForeground.r * (1 - k) + b.r * k, barForeground.g * (1 - k) + b.g * k,
      barForeground.b * (1 - k) + b.b * k, 1)
  }
  readonly property color dim: dimStep(0.33)
  readonly property bool checking: root.scanState === "checking"
  // The two states a fresh result sets (applyScan).
  readonly property bool hasScanResult: root.scanState === "quiet" || root.scanState === "attention"
  readonly property bool earlierResultKept: root.scanResultsStale && root.lastScanAt !== ""
  readonly property bool cliFailed: root.scanState === "missing-cli" ||
    root.scanState === "incompatible-cli" || root.scanState === "unavailable"
  // Count of enforcement_summary.decisions[].outcome === "block" from the scan
  // report, when it carries one; 0 otherwise. Set in applyScan.
  property int blockedDecisions: 0
  readonly property bool urgentBadge: hasScanResult &&
    (root.highestSeverity === "critical" || root.highestSeverity === "error" ||
      root.blockedDecisions > 0)

  function iconTooltip() {
    if (root.checking) return "OmaSafe: scanning"
    if (root.scanState === "missing-cli") return "OmaSafe: omasafe-cli not found"
    if (root.scanState === "incompatible-cli")
      return "OmaSafe: omasafe-cli " + root.cliVersion + " found; " +
        root.cliVersionMin + " or newer required"
    if (root.scanState === "unavailable")
      return root.earlierResultKept
        ? "OmaSafe: last scan failed; showing results from " + root.relativeScanAge()
        : "OmaSafe: last scan failed; results unavailable"
    if (root.scanState === "ready") return "OmaSafe: click to scan"
    if (root.scanResultsStale && root.lastScanAt !== "")
      return "OmaSafe: showing cached results from " + root.relativeScanAge()
    if (root.urgentBadge) return "OmaSafe: 1 critical alert to review"
    if (root.outstandingCount > 0)
      return "OmaSafe: " + root.outstandingCount +
        (root.outstandingCount === 1 ? " alert to review" : " alerts to review")
    return "OmaSafe: no outstanding alerts"
  }

  function relativeScanAge() {
    return Time.relative(root.lastScanAt) || "an earlier scan"
  }

  // Resolve the executable once, then invoke it directly so CLI arguments never
  // pass through a shell and the scan process can terminate normally.
  function cliCommand(args) {
    return root.cliPath === ""
      ? ["/usr/bin/false"]
      : [root.cliPath].concat(args)
  }

  function resolveCliCommand() {
    var script =
      "for cli in \"$HOME/.local/bin/omasafe-cli\" " +
      "/usr/local/bin/omasafe-cli /usr/bin/omasafe-cli; do " +
      "if [ -x \"$cli\" ]; then printf '%s' \"$cli\"; exit 0; fi; " +
      "done; " +
      "command -v omasafe-cli 2>/dev/null || " +
      "exit 127"
    return ["/usr/bin/bash", "-c", script]
  }

  function versionCommand() {
    return root.cliCommand(["--version"])
  }

  // Extract the first x.y or x.y.z token; returns [major, minor, patch] or null.
  function parseVersion(text) {
    var match = String(text || "").match(/(\d+)\.(\d+)(?:\.(\d+))?/)
    if (!match) return null
    return [Number(match[1]), Number(match[2]), Number(match[3] || 0)]
  }

  // Returns >0 if a>b, <0 if a<b, 0 if equal. Inputs are parseVersion() arrays.
  function compareVersion(a, b) {
    for (var i = 0; i < 3; i++) {
      if (a[i] !== b[i]) return a[i] - b[i]
    }
    return 0
  }

  // Decide whether the resolved binary is a compatible omasafe-cli from its
  // `--version` output, applying any operator policy. Sets cliCompatible /
  // cliVersion / cliError and, when incompatible, scanState "incompatible-cli".
  function evaluateVersion(output) {
    var text = String(output || "").trim()
    var parsed = root.parseVersion(text)
    if (!parsed) {
      root.cliCompatible = false
      root.cliVersion = ""
      root.scanState = "incompatible-cli"
      root.cliError = "omasafe-cli did not report a recognizable version"
      return
    }
    if (root.cliVersionRequireIdentity && text.toLowerCase().indexOf("omasafe") < 0) {
      root.cliCompatible = false
      root.cliVersion = parsed.join(".")
      root.scanState = "incompatible-cli"
      root.cliError = "Resolved binary does not identify as omasafe-cli"
      return
    }
    if (root.cliVersionMinInvalid) {
      root.cliCompatible = false
      root.cliVersion = parsed.join(".")
      root.scanState = "incompatible-cli"
      root.cliError = "Configured cliVersionMin is invalid; use a version such as 0.2.1"
      return
    }
    var min = root.cliVersionMin ? root.parseVersion(root.cliVersionMin) : null
    if (min && root.compareVersion(parsed, min) < 0) {
      root.cliCompatible = false
      root.cliVersion = parsed.join(".")
      root.scanState = "incompatible-cli"
      root.cliError = "omasafe-cli " + parsed.join(".") +
        " is older than the required " + min.join(".")
      return
    }
    root.cliCompatible = true
    root.cliVersion = parsed.join(".")
    root.cliError = ""
  }

  function applyScan(output) {
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1" ||
          !report.result || !Array.isArray(report.result.alerts))
        throw new Error("unsupported scan report")
      root.applyScanResult(report.result, report.generated_at, false)
      root.queueScanCache(report)
    } catch (error) {
      root.scanResultsStale = true
      root.scanState = root.cliError.indexOf("omasafe-cli was not found") >= 0
        ? "missing-cli" : "unavailable"
      root.limitation = "CLI report unavailable"
    }
  }

  function applyScanResult(result, generatedAt, stale) {
      result = result || {}
      root.alertCount = (result.alerts || []).length
      root.outstandingCount = result.outstanding !== undefined
        ? Number(result.outstanding) : root.alertCount
      root.newCount = result.new || 0
      root.alerts = result.alerts || []
      root.lastScanAt = String(generatedAt || "")
      var highest = String(result.highest_severity || "").toLowerCase()
      if (highest === "error") highest = "critical"
      root.highestSeverity = highest ||
        (root.alerts.some(function(alert) {
          return ["critical", "error"].indexOf(String(alert.severity || "").toLowerCase()) >= 0
        }) ? "critical" : (root.alertCount > 0 ? "warning" : "none"))
      root.scanState = result.quiet === true ? "quiet" : "attention"
      // Count recorded enforcement blocks when the report carries a summary; the
      // urgent badge is raised for a block as well as for critical/error severity.
      var decisions = (result.enforcement_summary && result.enforcement_summary.decisions) || []
      root.blockedDecisions = Array.isArray(decisions)
        ? decisions.filter(function(d) { return String(d.outcome || "") === "block" }).length : 0
      root.scanResultsStale = stale === true
      root.limitation = ""
      root.cliError = ""
  }

  function scanCacheSnapshot(report) {
    var result = report && report.result ? report.result : {}
    return {
      schema: "omasafe.scan-cache.v1",
      generated_at: String(report && report.generated_at || ""),
      cli_version: String(root.cliVersion || ""),
      result: {
        alerts: Array.isArray(result.alerts) ? result.alerts : [],
        outstanding: result.outstanding,
        "new": result.new,
        highest_severity: result.highest_severity,
        quiet: result.quiet === true,
        enforcement_summary: result.enforcement_summary || null
      }
    }
  }

  function queueScanCache(report) {
    root.pendingScanCache = root.scanCacheSnapshot(report)
    root.flushScanCache()
  }

  function flushScanCache() {
    if (!root.scanCacheReady || !root.scanCacheDirReady || !root.pendingScanCache) return
    try {
      scanCacheFile.setText(JSON.stringify(root.pendingScanCache, null, 2) + "\n")
      root.pendingScanCache = null
      root.scanCacheError = ""
    } catch (error) {
      root.scanCacheError = "Could not save the last scan snapshot."
    }
  }

  function loadScanCache(raw) {
    if (root.scanCacheHydrated) return
    root.scanCacheHydrated = true
    root.scanCacheReady = true
    try {
      var snapshot = JSON.parse(String(raw || ""))
      if (String(snapshot.schema || "") !== "omasafe.scan-cache.v1" ||
          !snapshot.result || !Array.isArray(snapshot.result.alerts) ||
          String(snapshot.generated_at || "") === "") throw new Error("invalid cache")
      root.cachedScanSnapshot = snapshot
      root.applyCachedScan()
    } catch (error) {
      root.cachedScanSnapshot = null
    }
    root.flushScanCache()
  }

  function applyCachedScan() {
    var snapshot = root.cachedScanSnapshot
    if (!snapshot || !root.cliVerified) return
    if (String(snapshot.cli_version || "") !== String(root.cliVersion || "")) {
      root.scanCacheError = "Cached scan was produced by a different CLI version."
      return
    }
    root.applyScanResult(snapshot.result, snapshot.generated_at, true)
  }

  function runScan() {
    // Defer until the resolver has exited so an early click can't be mistaken
    // for a missing CLI; the pending request replays once resolution completes.
    if (!root.cliResolved) {
      root.scanRequested = true
      root.scanState = "checking"
      return
    }
    root.scanRequested = false
    if (root.cliPath === "") {
      root.scanResultsStale = true
      root.scanState = "missing-cli"
      root.cliError = "omasafe-cli was not found in ~/.local/bin, /usr/local/bin, /usr/bin, or PATH"
      return
    }
    if (!root.cliCompatible) {
      // Version gate failed: never execute or trust an incompatible binary.
      root.scanResultsStale = true
      root.scanState = "incompatible-cli"
      if (root.cliError === "")
        root.cliError = "omasafe-cli version is not compatible"
      return
    }
    if (!scanProcess.running) {
      root.cliError = ""
      root.scanStdout = ""
      root.scanStderr = ""
      root.scanSettled = false
      root.scanResultsStale = true
      root.scanState = "checking"
      scanKill.stop()          // disarm any stale escalation from a prior scan
      scanTimeout.restart()
      scanProcess.running = true
    }
  }

  // Abort a scan whose output crossed the cap: latch, stop the timers, hard-kill
  // the flooding process immediately, and discard the partial buffers unparsed.
  function overflowScan(stream) {
    if (root.scanSettled) return
    root.scanSettled = true
    scanTimeout.stop()
    scanKill.stop()
    root.scanStdout = ""
    root.scanStderr = ""
    root.scanState = "unavailable"
    root.scanResultsStale = true
    root.cliError = "omasafe-cli exceeded the ~" +
      Math.round(root.scanOutputCharCap / (1024 * 1024)) + " MiB " + stream +
      " output cap; scan aborted"
    if (scanProcess.running) scanProcess.signal(9)
  }

  Process {
    id: scanProcess
    command: root.cliCommand(["scan", "--include-analysis", "--format", "json"])
    // Chunked, capped reads instead of StdioCollector: a faulty or replaced CLI
    // cannot grow shell memory without bound. splitMarker "" delivers raw chunks
    // (no line buffering, so no single unbounded line is ever retained). stdout
    // and stderr are capped separately; the full JSON is parsed once, in onExited,
    // relying on onRead draining before exit (same contract as versionCheck).
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.scanSettled) return
        root.scanStdout += String(chunk)
        if (root.scanStdout.length > root.scanOutputCharCap) root.overflowScan("stdout")
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.scanSettled) return
        root.scanStderr += String(chunk)
        if (root.scanStderr.length > root.scanOutputCharCap) root.overflowScan("stderr")
      }
    }
    onExited: function(exitCode) {
      // Always disarm the timers first: a SIGTERM'd process that exits promptly
      // would otherwise early-return below with scanKill still armed, letting the
      // previous scan's kill timer fire into a scan started within the window.
      scanTimeout.stop()
      scanKill.stop()
      // Ignore a late exit if overflow or the timeout already settled this scan.
      if (root.scanSettled) return
      root.scanSettled = true
      var err = String(root.scanStderr || "").trim()
      root.scanStderr = ""
      if (err !== "") root.cliError = err
      if (exitCode === 127 || err.indexOf("omasafe-cli was not found") >= 0) {
        root.scanState = "missing-cli"
        root.scanStdout = ""
        return
      }
      if (exitCode !== 0 && exitCode !== 3) {
        root.scanResultsStale = true
        root.scanState = "unavailable"
        root.scanStdout = ""
        return
      }
      // Exit 0 (quiet) or 3 (findings) carry a valid report; applyScan sets the
      // outcome state and clears cliError on success, or falls back on bad JSON.
      root.applyScan(root.scanStdout)
      root.scanStdout = ""
    }
  }

  Process {
    id: cliResolver
    command: root.resolveCliCommand()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.cliPath = String(text || "").trim()
        // Found a binary, but do not trust it yet: verify its version before it
        // is allowed to run scans. Resolution stays pending until versionCheck
        // exits, so a click in the meantime is deferred, not run.
        if (root.cliPath !== "") {
          root.cliVersionOutput = ""
          root.versionSettled = false
          versionTimeout.restart()
          versionCheck.running = true
        }
      }
    }
    onExited: function(exitCode) {
      // exit 0 means the resolver printed a path (version check runs from stdout);
      // any other code means no CLI was found, so surface that via runScan().
      if (exitCode !== 0) {
        root.cliResolved = true
        root.runScan()
      }
    }
  }

  // Reject a resolved binary whose version probe failed, unless a terminal
  // decision was already latched for this probe.
  function failVersion(message) {
    if (root.versionSettled) return
    root.versionSettled = true
    versionTimeout.stop()
    root.cliResolved = true
    root.cliCompatible = false
    root.cliVersionOutput = ""
    root.scanState = "incompatible-cli"
    root.cliError = message
    root.scanRequested = false
  }

  Process {
    id: versionCheck
    command: root.versionCommand()
    // Chunked, capped collection: only the first 256 chars are retained and the
    // rest is drained and discarded. splitMarker "" delivers raw chunks (no line
    // buffering), so a newline-free flood cannot grow memory before the timeout.
    // stderr is left unread so OS pipe backpressure and the timeout/kill bound it
    // too. Authorization still happens only in onExited.
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.cliVersionOutput.length < 256)
          root.cliVersionOutput = (root.cliVersionOutput + String(chunk)).slice(0, 256)
      }
    }
    onExited: function(exitCode) {
      // A timeout already decided this probe: ignore a late exit (even exit 0)
      // so a process that outlived SIGTERM cannot re-authorize the CLI.
      if (root.versionSettled) return
      root.versionSettled = true
      versionTimeout.stop()
      versionKill.stop()
      root.cliResolved = true
      // A compatible CLI must answer `--version` with status 0; only then is the
      // reported version trusted enough to evaluate against the policy.
      if (exitCode === 0) {
        root.evaluateVersion(root.cliVersionOutput)
      } else {
        root.cliCompatible = false
        root.scanState = "incompatible-cli"
        if (root.cliError === "")
          root.cliError = "omasafe-cli --version exited with status " + exitCode
      }
      root.cliVersionOutput = ""
      if (root.cliCompatible) {
        root.scanState = "ready"
        root.cliError = ""
        root.applyCachedScan()
        // Replay a deferred click, or start the first scan for periodic users
        // so they get a real status at login instead of an idle "ready" badge.
        if (root.scanRequested || root.periodicScanEnabled) root.runScan()
      } else {
        if (root.scanState === "checking") root.scanState = "incompatible-cli"
        root.scanRequested = false
      }
    }
  }

  Timer {
    id: versionTimeout
    interval: 10000
    repeat: false
    // Bound the startup probe. Settle to a terminal decision first (latched, so a
    // later exit cannot override it), then request termination and escalate.
    onTriggered: {
      root.failVersion("omasafe-cli --version timed out after 10 seconds")
      if (versionCheck.running) {
        versionCheck.running = false   // SIGTERM
        versionKill.restart()          // escalate to SIGKILL if it survives
      }
    }
  }

  Timer {
    id: versionKill
    interval: 3000
    repeat: false
    // SIGKILL a probe that ignored SIGTERM. onExited is ignored (already latched).
    onTriggered: if (versionCheck.running) versionCheck.signal(9)
  }

  Timer {
    id: scanTimeout
    interval: 30000
    repeat: false
    // Bound a hung scan. Settle to a terminal decision first (latched, so a later
    // exit cannot override it), then SIGTERM and escalate to SIGKILL if ignored.
    onTriggered: {
      if (root.scanSettled) return
      root.scanSettled = true
      scanKill.stop()
      root.scanStdout = ""
      root.scanStderr = ""
      root.scanState = "unavailable"
      root.scanResultsStale = true
      root.cliError = "CLI scan timed out after 30 seconds"
      if (scanProcess.running) {
        scanProcess.running = false   // SIGTERM
        scanKill.restart()            // escalate to SIGKILL if it survives
      }
    }
  }

  Timer {
    id: scanKill
    interval: 3000
    repeat: false
    // SIGKILL a scan that ignored SIGTERM. onExited is ignored (already latched).
    onTriggered: if (scanProcess.running) scanProcess.signal(9)
  }

  Timer {
    interval: root.periodicScanIntervalMinutes * 60000
    running: root.periodicScanEnabled
    repeat: true
    onTriggered: root.runScan()
  }

  Process {
    id: scanCacheMkdir
    command: ["/usr/bin/mkdir", "-p", root.scanCacheDir]
    onExited: function(exitCode) {
      root.scanCacheDirReady = exitCode === 0
      if (!root.scanCacheDirReady) root.scanCacheError = "Could not prepare the scan cache directory."
      else scanCacheFile.reload()
      root.flushScanCache()
    }
  }

  FileView {
    id: scanCacheFile
    path: root.scanCachePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadScanCache(text())
    onLoadFailed: root.scanCacheReady = true
    onSaved: root.scanCacheError = ""
    onSaveFailed: root.scanCacheError = "Could not save the last scan snapshot."
  }

  Component.onCompleted: {
    scanCacheMkdir.running = true
    cliResolver.running = true
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  // The shield in its status slot with a sibling count Text (doc 03 §2). The count
  // cannot live inside the icon — BarIconButton fixes fixedWidth: slotSize and shows
  // its own text only when iconComponent is null — so it is a sibling and the widget
  // must reserve the gap and text width explicitly. An Item is used instead of a
  // Grid so the module slot receives the same dimensions that the two children paint
  // in both horizontal and vertical bars; this prevents the count from spilling into
  // the next status widget when the alert number appears. The trailing optical guard
  // is intentional: some neighboring Nerd Font glyphs have a negative painted
  // bearing and can otherwise draw back over the final count pixels.
  Item {
    id: iconRow
    anchors.centerIn: parent
    readonly property real countGap: countText.visible ? Style.space(2) : 0
    readonly property real countWidth: countText.visible ? countText.implicitWidth : 0
    readonly property real countHeight: countText.visible ? countText.implicitHeight : 0
    readonly property real opticalGuard: countText.visible ? Style.space(8) : 0
    implicitWidth: root.vertical
      ? Math.max(button.width, countWidth)
      : button.width + countGap + countWidth + opticalGuard
    implicitHeight: root.vertical
      ? button.height + countGap + countHeight + opticalGuard
      : Math.max(button.height, countHeight)
    width: implicitWidth
    height: implicitHeight

    BarIconButton {
      id: button
      bar: root.bar
      text: ""
      slotSize: Style.bar.statusSlot
      // BarIconButton's fixedWidth/fixedHeight describe its implicit size. This
      // explicit canvas keeps the optical slot stable while iconRow grows for text.
      width: root.vertical ? root.barSize : Style.bar.statusSlot
      height: root.vertical ? Style.bar.statusSlot : root.barSize
      x: root.vertical ? (iconRow.width - width) / 2 : 0
      y: root.vertical ? 0 : (iconRow.height - height) / 2
      iconComponent: Component {
        OmaSafeShield {
          iconSize: Style.bar.iconFont
          filled: root.hasScanResult
          dim: root.cliFailed
          checking: root.checking
          badge: root.urgentBadge
          opened: root.opened
          foreground: root.barForeground
          dimColor: root.dim
          urgent: root.bar ? root.bar.urgent : Color.urgent
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          resolvedFamily: Style.font.resolvedFamily
        }
      }
      tooltipText: root.iconTooltip()
      onPressed: function(mouseButton) {
        if (mouseButton === Qt.LeftButton && panelLoader.item) {
          root.runScan()
          root.open()
        } else if (mouseButton === Qt.MiddleButton) {
          root.runScan()
        }
      }
    }

    // A count is data: bodySmall floor (02 P7), never a filled disc; dim when it
    // belongs to a kept earlier result. Never shown when 0 (quiet has no count).
    Text {
      id: countText
      visible: (root.hasScanResult || root.earlierResultKept) && root.outstandingCount > 0
      text: root.outstandingCount > 9 ? "9+" : String(root.outstandingCount)
      textFormat: Text.PlainText
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
      color: root.earlierResultKept ? root.dim : root.barForeground
      x: root.vertical
        ? (iconRow.width - implicitWidth) / 2
        : button.width + iconRow.countGap
      y: root.vertical
        ? button.height + iconRow.countGap
        : (iconRow.height - implicitHeight) / 2
    }
  }
}
