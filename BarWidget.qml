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
  property string limitation: ""
  property string cliError: ""
  property string cliPath: ""

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

  function applyScan(output) {
    try {
      var report = JSON.parse(output)
      var result = report.result || {}
      root.alertCount = (result.alerts || []).length
      root.outstandingCount = result.outstanding || root.alertCount
      root.newCount = result.new || 0
      root.alerts = result.alerts || []
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
    if (root.cliPath === "") {
      root.scanState = "missing-cli"
      root.cliError = "omasafe-cli was not found in ~/.local/bin, /usr/local/bin, /usr/bin, or PATH"
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
        if (root.cliPath !== "") root.runScan()
      }
    }
    onExited: function(exitCode) {
      if (exitCode === 127 && root.cliPath === "") root.runScan()
    }
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
    interval: 300000
    running: true
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
    text: root.scanState === "checking"
      ? "…" : (root.scanState === "missing-cli"
      ? "CLI" : (root.scanState === "unavailable"
        ? "?" : (root.outstandingCount > 0 ? "!" : "✓")))
    slotSize: Style.bar.statusSlot
    tooltipText: root.scanState === "checking"
      ? "OmaSafe: scanning"
      : (root.scanState === "missing-cli"
      ? "OmaSafe: install omasafe-cli"
      : (root.scanState === "unavailable"
        ? "OmaSafe: scan unavailable"
        : (root.outstandingCount > 0
      ? "OmaSafe: " + root.outstandingCount + " item(s) need review"
      : "OmaSafe: " + root.scanState)))
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
