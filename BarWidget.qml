import QtQuick
import qs.Commons
import qs.Ui
import Quickshell.Io

BarWidget {
  id: root
  moduleName: "io.github.tuthan.omasafe"

  property int alertCount: 0
  property int outstandingCount: 0
  property int newCount: 0
  property var alerts: []
  property string scanState: "checking"
  property string highestSeverity: "none"
  property string limitation: ""
  property string cliError: ""
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

  // Single authorization gate for every operational CLI command (scan and every
  // panel command). A command may only run once resolution completed, a path was
  // found, and the version probe passed.
  readonly property bool cliVerified: root.cliResolved && root.cliCompatible &&
    root.cliPath !== ""

  // Optional operator policy (off by default so an unknown-but-valid CLI version
  // is not rejected). Set via plugin settings.
  readonly property string cliVersionMin: settings && settings.cliVersionMin
    ? String(settings.cliVersionMin) : ""
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

  visible: !vertical
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property color warningColor: "#e5a50a"
  readonly property string statusLevel: root.scanState === "checking"
    ? "checking" : (root.scanState === "ready" ? "ready"
      : (root.scanState === "missing-cli" || root.scanState === "unavailable" ||
        root.scanState === "incompatible-cli" ? "unknown"
        : (root.highestSeverity === "critical" ? "critical"
          : (root.outstandingCount > 0 ? "warning" : "normal"))))

  function iconTooltip() {
    if (root.statusLevel === "checking") return "OmaSafe: scanning"
    if (root.scanState === "ready") return "OmaSafe: click to scan"
    if (root.scanState === "missing-cli") return "OmaSafe: install omasafe-cli"
    if (root.scanState === "incompatible-cli") return "OmaSafe: incompatible omasafe-cli"
    if (root.scanState === "unavailable") return "OmaSafe: scan unavailable"
    if (root.statusLevel === "critical")
      return "OmaSafe: critical finding requires review"
    if (root.statusLevel === "warning")
      return "OmaSafe: " + root.outstandingCount + " item(s) need review"
    return "OmaSafe: no outstanding changes"
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
      var result = report.result || {}
      root.alertCount = (result.alerts || []).length
      root.outstandingCount = result.outstanding || root.alertCount
      root.newCount = result.new || 0
      root.alerts = result.alerts || []
      root.highestSeverity = String(result.highest_severity ||
        (root.alerts.some(function(alert) { return alert.severity === "critical" })
          ? "critical" : (root.alertCount > 0 ? "warning" : "none")))
      root.scanState = result.quiet === true ? "quiet" : "attention"
      root.limitation = ""
      root.cliError = ""
    } catch (error) {
      root.scanState = root.cliError.indexOf("omasafe-cli was not found") >= 0
        ? "missing-cli" : "unavailable"
      root.limitation = "CLI report unavailable"
    }
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
      root.scanState = "missing-cli"
      root.cliError = "omasafe-cli was not found in ~/.local/bin, /usr/local/bin, /usr/bin, or PATH"
      return
    }
    if (!root.cliCompatible) {
      // Version gate failed: never execute or trust an incompatible binary.
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
    root.cliError = "omasafe-cli exceeded the ~" +
      Math.round(root.scanOutputCharCap / (1024 * 1024)) + " MiB " + stream +
      " output cap; scan aborted"
    if (scanProcess.running) scanProcess.signal(9)
  }

  Process {
    id: scanProcess
    command: root.cliCommand(["scan", "--format", "json"])
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

  Component.onCompleted: cliResolver.running = true

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

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    iconComponent: Component {
      OmaSafeStatusIcon {
        anchors.centerIn: parent
        level: root.statusLevel
        count: root.outstandingCount
        warningColor: root.warningColor
        criticalColor: root.bar ? root.bar.urgent : Color.urgent
      }
    }
    slotSize: Style.bar.statusSlot
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
}
