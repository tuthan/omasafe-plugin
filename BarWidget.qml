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
      root.scanState = "checking"
      scanTimeout.restart()
      scanProcess.running = true
    }
  }

  Process {
    id: scanProcess
    command: root.cliCommand(["scan", "--format", "json"])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyScan(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.cliError = String(text || "").trim()
        if (root.cliError.indexOf("omasafe-cli was not found") >= 0)
          root.scanState = "missing-cli"
      }
    }
    onExited: function(exitCode) {
      scanTimeout.stop()
      if (exitCode === 127) root.scanState = "missing-cli"
      else if (exitCode !== 0 && exitCode !== 3) root.scanState = "unavailable"
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
    // Line-split rather than collect: only the first non-empty line is retained
    // (capped), and later lines are drained and discarded, so a flooding binary
    // cannot grow memory here. stderr is left unread so OS pipe backpressure and
    // the timeout/kill bound it too. Authorization still happens only in onExited.
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(line) {
        if (root.cliVersionOutput === "" && String(line).trim() !== "")
          root.cliVersionOutput = String(line).slice(0, 256)
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
    onTriggered: {
      if (scanProcess.running) {
        scanProcess.running = false
        root.scanState = "unavailable"
        root.cliError = "CLI scan timed out after 30 seconds"
      }
    }
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
