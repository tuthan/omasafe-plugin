import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import Quickshell.Io

Panel {
  id: root
  moduleName: "io.github.tuthan.omasafe"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var inventoryReport: null
  property var statusReport: null
  property var diffReport: null
  property string panelError: ""

  function cliCommand(args) {
    return root.hostWidget
      ? root.hostWidget.cliCommand(args)
      : ["bash", "-lc", "exit 127"]
  }

  function open() {
    root.panelError = ""
    root.controller.show()
    inventoryProcess.running = true
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function applyInventory(output) {
    try {
      var report = JSON.parse(output)
      root.inventoryReport = report.result || {}
      root.panelError = ""
      var plugins = root.inventoryReport.plugins || []
      if (plugins.length > 0) {
        statusProcess.command = root.cliCommand(["plugins", "status",
          plugins[0].id, "--format", "json"])
        statusProcess.running = true
      }
      var alerts = root.hostWidget ? root.hostWidget.alerts : []
      for (var i = 0; i < alerts.length; i++) {
        if (alerts[i].kind === "source-drift") {
          diffProcess.command = root.cliCommand(["plugins", "diff",
            alerts[i].plugin_id, "--format", "json"])
          diffProcess.running = true
          break
        }
      }
    } catch (error) {
      root.inventoryReport = null
      root.panelError = "CLI returned an invalid report"
    }
  }

  function applyStatus(output) {
    try {
      var report = JSON.parse(output)
      root.statusReport = report.result || {}
    } catch (error) {
      root.statusReport = null
      root.panelError = "CLI status report unavailable"
    }
  }

  function applyDiff(output) {
    try {
      var report = JSON.parse(output)
      root.diffReport = report.result || {}
    } catch (error) {
      root.diffReport = null
      root.panelError = "CLI diff report unavailable"
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    contentWidth: fittedContentWidth(Style.space(360))
    contentHeight: fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      width: panel.contentWidth - panel.padding * 2
      spacing: Style.space(10)

      Text {
        text: "OMASAFE"
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: root.diffReport !== null
        text: root.diffReport
          ? "Changed files: " + ((root.diffReport.changed_files || []).join(", ") || "none")
          : ""
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: root.panelError !== ""
        text: root.panelError
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.hostWidget && root.hostWidget.scanState === "unavailable"
          ? "Scan unavailable: " + (root.hostWidget.cliError || "review the CLI installation and permissions.")
          : (root.hostWidget && root.hostWidget.scanState === "missing-cli"
            ? "omasafe-cli is not installed or is not visible to Omarchy Shell. Install it from the OmaSafe GitHub release, then restart Omarchy Shell."
          : (root.hostWidget && root.hostWidget.scanState === "checking"
            ? "Scanning with omasafe-cli…"
          : (root.hostWidget && root.hostWidget.outstandingCount > 0
            ? root.hostWidget.outstandingCount + " outstanding item(s); " +
              (root.hostWidget.newCount || 0) + " new"
            : "No outstanding changes detected.")))
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: root.hostWidget && root.hostWidget.alerts.length > 0
        text: root.hostWidget ? root.hostWidget.alerts.map(function(alert) {
          return alert.plugin_id + ": " + alert.kind
        }).join("\n") : ""
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: root.inventoryReport !== null
        text: root.inventoryReport && root.inventoryReport.plugins &&
          root.inventoryReport.plugins.length > 0
          ? "Installed: " + root.inventoryReport.plugins[0].id +
            "\nClassification: " + root.inventoryReport.plugins[0].classification +
            "\nDigest: " + (root.inventoryReport.plugins[0].content_digest || "unavailable") +
            "\nCoverage: " + ((root.inventoryReport.plugins[0].limitations || []).join(", ") || "complete")
          : "Installed identity unavailable."
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: root.statusReport !== null
        text: root.statusReport
          ? "Baseline: " + (root.statusReport.trusted
            ? (root.statusReport.trusted.content_digest || "recorded")
            : "not established") +
            "\nCurrent state: " + root.statusReport.state
          : ""
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: root.inventoryReport && root.inventoryReport.marketplace
        text: root.inventoryReport && root.inventoryReport.marketplace
          ? "Marketplace: " + root.inventoryReport.marketplace[0].status +
            "\nSnapshot: " + (root.inventoryReport.marketplace_retrieved_at || "unavailable") +
            (root.inventoryReport.marketplace_stale ? "\nMarketplace snapshot is stale." : "")
          : ""
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: root.inventoryReport && root.inventoryReport.non_builtin_bar_replaces_bar
        text: "A third-party full-bar plugin replaces the OmaSafe bar widget. CLI and desktop notifications remain available."
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.hostWidget && root.hostWidget.alertCount > 0
          ? root.hostWidget.alertCount + " item(s) need review"
          : "No new actionable changes detected."
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "OmaSafe reports changes and coverage limits. It does not declare plugins safe."
        color: Util.alpha(bar ? bar.foreground : Color.foreground, 0.64)
        font.family: bar ? bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Button {
        text: "Run scan"
        onClicked: if (root.hostWidget) root.hostWidget.runScan()
      }
    }
  }

  Process {
      id: inventoryProcess
      command: root.cliCommand(["plugins", "inventory", "--format", "json"])
      stdout: StdioCollector {
        waitForEnd: true
        onStreamFinished: root.applyInventory(text)
      }
      stderr: StdioCollector {
        waitForEnd: true
        onStreamFinished: if (String(text || "").trim() !== "") root.panelError = String(text).trim()
      }
    }

    Process {
      id: statusProcess
      command: root.cliCommand(["plugins", "status", "", "--format", "json"])
      stdout: StdioCollector {
        waitForEnd: true
        onStreamFinished: root.applyStatus(text)
      }
      stderr: StdioCollector {
        waitForEnd: true
        onStreamFinished: if (String(text || "").trim() !== "") root.panelError = String(text).trim()
      }
    }

    Process {
      id: diffProcess
      command: root.cliCommand(["plugins", "diff", "", "--format", "json"])
      stdout: StdioCollector {
        waitForEnd: true
        onStreamFinished: root.applyDiff(text)
      }
      stderr: StdioCollector {
        waitForEnd: true
        onStreamFinished: if (String(text || "").trim() !== "") root.panelError = String(text).trim()
      }
    }
}
