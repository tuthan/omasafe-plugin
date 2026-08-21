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
  property string selectedError: ""
  property string selectedPluginId: ""
  property bool showCompliantPlugins: false
  property bool checkingPluginStatuses: false
  property var pluginStatuses: ({})
  property var statusQueue: []
  property string trustError: ""
  property bool showPluginPicker: false
  property bool trustConfirming: false
  property bool untrustConfirming: false
  property string trustOperation: ""

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property color warningColor: hostWidget ? hostWidget.warningColor : "#e5a50a"
  readonly property var alerts: hostWidget ? hostWidget.alerts : []
  readonly property string statusLevel: hostWidget ? hostWidget.statusLevel : "unknown"

  function cliCommand(args) {
    return root.hostWidget
      ? root.hostWidget.cliCommand(args)
      : ["/usr/bin/false"]
  }

  function statusColor(level) {
    if (level === "critical") return root.bar ? root.bar.urgent : Color.urgent
    if (level === "warning") return root.warningColor
    if (level === "normal") return root.contentForeground
    return Color.muted
  }

  function statusTitle() {
    if (root.statusLevel === "checking") return "Scanning"
    if (root.statusLevel === "critical") return "Critical finding"
    if (root.statusLevel === "warning") return "Review needed"
    if (root.statusLevel === "normal") return "No outstanding changes"
    return "Scan status unavailable"
  }

  function statusMessage() {
    if (!root.hostWidget) return "Waiting for the OmaSafe widget."
    if (root.hostWidget.scanState === "missing-cli")
      return "Install omasafe-cli, then restart Omarchy Shell."
    if (root.hostWidget.scanState === "unavailable")
      return root.hostWidget.cliError || "The latest scan could not be completed."
    if (root.statusLevel === "checking") return "Reading installed plugin state…"
    if (root.statusLevel === "critical") return "A confirmed critical finding needs immediate review."
    if (root.statusLevel === "warning")
      return root.hostWidget.outstandingCount + " item(s) need review" +
        (root.hostWidget.newCount > 0 ? "; " + root.hostWidget.newCount + " new" : "") + "."
    return "The latest scan found no outstanding changes."
  }

  function alertLevel(alert) {
    return alert && String(alert.severity || "").toLowerCase() === "critical"
      ? "critical" : "warning"
  }

  function alertLabel(alert) {
    var kind = String(alert && alert.kind || "finding").replace(/-/g, " ")
    return kind.charAt(0).toUpperCase() + kind.slice(1)
  }

  function pluginById(id) {
    var plugins = root.inventoryReport && root.inventoryReport.plugins || []
    for (var i = 0; i < plugins.length; i++) {
      if (plugins[i].id === id) return plugins[i]
    }
    return null
  }

  function visiblePlugins() {
    var plugins = root.inventoryReport && root.inventoryReport.plugins || []
    return plugins.filter(function(plugin) { return plugin.classification !== "backup" })
  }

  function statusForPlugin(id) {
    return root.pluginStatuses[id] || null
  }

  function baselinedUnchangedPlugins() {
    return root.visiblePlugins().filter(function(plugin) {
      var status = root.statusForPlugin(plugin.id)
      return status && status.state === "unchanged"
    })
  }

  function trustedPluginCount() {
    return root.visiblePlugins().filter(function(plugin) {
      var status = root.statusForPlugin(plugin.id)
      return status && status.state === "unchanged"
    }).length
  }

  function reviewPluginCount() {
    return root.visiblePlugins().filter(function(plugin) {
      var status = root.statusForPlugin(plugin.id)
      return status && (status.state === "changed" || status.state === "partial")
    }).length
  }

  function untrustedPluginCount() {
    return root.visiblePlugins().filter(function(plugin) {
      var status = root.statusForPlugin(plugin.id)
      return status && status.state === "untrusted"
    }).length
  }

  function selectedPlugin() {
    return root.pluginById(root.selectedPluginId)
  }

  function pluginStatusLabel(plugin) {
    var status = root.statusForPlugin(plugin.id)
    if (!status) return "Checking baseline…"
    if (status.state === "unchanged") return "Baselined & unchanged"
    if (status.state === "untrusted") return "No trust baseline"
    if (status.state === "partial") return "Partial coverage"
    if (status.state === "changed") return "Source changed"
    return "Status unavailable"
  }

  function pluginStatusLevel(plugin) {
    var status = root.statusForPlugin(plugin.id)
    if (!status || status.state === "untrusted") return "unknown"
    if (status.state === "unchanged") return "normal"
    return "warning"
  }

  function canTrustSelectedPlugin() {
    var plugin = root.selectedPlugin()
    return plugin && plugin.classification !== "backup" && !!plugin.content_digest
  }

  function canUntrustSelectedPlugin() {
    return root.statusReport && root.statusReport.trusted !== null &&
      root.statusReport.trusted !== undefined
  }

  function trustSelectedPlugin() {
    var plugin = root.selectedPlugin()
    if (!plugin || !root.canTrustSelectedPlugin()) return
    var args = ["plugins", "trust", plugin.id, "--yes", "--note", "trusted from OmaSafe panel"]
    if (plugin.head) args.push("--expected-head", plugin.head)
    if (plugin.tree) args.push("--expected-tree", plugin.tree)
    if (plugin.content_digest) args.push("--expected-digest", plugin.content_digest)
    root.trustError = ""
    root.trustOperation = "trust"
    trustProcess.command = root.cliCommand(args)
    trustProcess.running = true
  }

  function untrustSelectedPlugin() {
    if (!root.selectedPlugin() || !root.canUntrustSelectedPlugin()) return
    root.trustError = ""
    root.trustOperation = "untrust"
    trustProcess.command = root.cliCommand([
      "plugins", "review", root.selectedPluginId,
      "--action", "untrust",
      "--reason", "untrusted from OmaSafe panel",
      "--yes"
    ])
    trustProcess.running = true
  }

  function refreshPluginStatuses() {
    root.pluginStatuses = ({})
    root.statusQueue = root.visiblePlugins().map(function(plugin) { return plugin.id })
    root.checkingPluginStatuses = root.statusQueue.length > 0
    root.runNextPluginStatus()
  }

  function runNextPluginStatus() {
    if (listStatusProcess.running) return
    if (root.statusQueue.length === 0) {
      root.checkingPluginStatuses = false
      return
    }
    var queue = root.statusQueue.slice()
    var pluginId = queue.shift()
    root.statusQueue = queue
    listStatusProcess.pluginId = pluginId
    listStatusProcess.receivedReport = false
    listStatusProcess.command = root.cliCommand(["plugins", "status", pluginId, "--format", "json"])
    listStatusProcess.running = true
  }

  function recordPluginStatus(id, status) {
    var next = ({})
    for (var key in root.pluginStatuses) next[key] = root.pluginStatuses[key]
    next[id] = status
    root.pluginStatuses = next
  }

  function applyListedPluginStatus(id, output) {
    try {
      var report = JSON.parse(output)
      root.recordPluginStatus(id, report.result || { state: "unavailable" })
    } catch (error) {
      root.recordPluginStatus(id, { state: "unavailable" })
    }
  }

  function marketplaceByPlugin(id) {
    var entries = root.inventoryReport && root.inventoryReport.marketplace || []
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].plugin_id === id) return entries[i]
    }
    return null
  }

  function selectedAlert() {
    for (var i = 0; i < root.alerts.length; i++) {
      if (root.alerts[i].plugin_id === root.selectedPluginId) return root.alerts[i]
    }
    return null
  }

  function shortDigest(value) {
    value = String(value || "")
    return value.length > 18 ? value.slice(0, 16) + "…" : (value || "unavailable")
  }

  // Set a process's command and start it. If it is already running for a prior
  // selection, request the new command instead and let onExited relaunch it, so
  // rapid re-selection never drops the latest request.
  function launchProcess(process, command) {
    if (process.running) {
      process.nextCommand = command
      process.running = false
    } else {
      process.nextCommand = null
      process.command = command
      process.running = true
    }
  }

  function selectPlugin(id, alert) {
    root.selectedPluginId = id || ""
    root.showPluginPicker = false
    root.trustConfirming = false
    root.untrustConfirming = false
    root.statusReport = null
    root.diffReport = null
    root.selectedError = ""
    var plugin = root.pluginById(root.selectedPluginId)
    if (plugin) {
      root.launchProcess(statusProcess,
        root.cliCommand(["plugins", "status", plugin.id, "--format", "json"]))
    }
    if (plugin && alert && alert.kind === "source-drift") {
      root.launchProcess(diffProcess,
        root.cliCommand(["plugins", "diff", plugin.id, "--format", "json"]))
    }
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
      var plugins = root.visiblePlugins()
      var initialAlert = root.alerts.length > 0 ? root.alerts[0] : null
      var initialId = initialAlert ? initialAlert.plugin_id : (plugins.length > 0 ? plugins[0].id : "")
      var initialPlugin = root.pluginById(initialId)
      if ((!initialPlugin || initialPlugin.classification === "backup") && plugins.length > 0)
        initialId = plugins[0].id
      root.selectPlugin(initialId, initialAlert)
      root.refreshPluginStatuses()
    } catch (error) {
      root.inventoryReport = null
      root.panelError = "CLI returned an invalid inventory report"
    }
  }

  function applyStatus(output) {
    try {
      var report = JSON.parse(output)
      root.statusReport = report.result || {}
      root.selectedError = ""
    } catch (error) {
      root.statusReport = null
      root.selectedError = "Status for this plugin is unavailable."
    }
  }

  function applyDiff(output) {
    try {
      var report = JSON.parse(output)
      root.diffReport = report.result || {}
    } catch (error) {
      root.diffReport = null
      root.selectedError = "Source diff for this plugin is unavailable."
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    contentWidth: fittedContentWidth(Style.space(420))
    contentHeight: fittedContentHeight(content.implicitHeight, Style.space(600))

    Flickable {
      id: panelFlick
      anchors.fill: parent
      contentWidth: width
      contentHeight: content.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      Column {
        id: content
        width: panelFlick.width
        spacing: Style.space(12)

        Item {
          width: parent.width
          implicitHeight: summary.implicitHeight

          Row {
            id: summary
            width: parent.width
            spacing: Style.space(10)

            OmaSafeStatusIcon {
              id: summaryIcon
              anchors.verticalCenter: parent.verticalCenter
              level: root.statusLevel
              warningColor: root.warningColor
              criticalColor: root.bar ? root.bar.urgent : Color.urgent
              implicitWidth: Style.space(24)
              implicitHeight: Style.space(24)
              width: implicitWidth
              height: implicitHeight
            }

            Column {
              width: parent.width - summaryIcon.width - summary.spacing
              spacing: Style.space(2)

              Text {
                text: root.statusTitle()
                color: root.statusColor(root.statusLevel)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                width: parent.width
                text: root.statusMessage()
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          implicitHeight: summaryStats.implicitHeight + Style.space(14)
          radius: Style.cornerRadius
          color: Util.alpha(root.contentForeground, 0.05)
          border.width: 1
          border.color: Util.alpha(root.contentForeground, 0.20)

          Row {
            id: summaryStats
            anchors.centerIn: parent
            spacing: Style.space(18)

            Column {
              spacing: Style.space(2)
              Text {
                text: root.visiblePlugins().length
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                text: "INSTALLED"
                color: Util.alpha(root.contentForeground, 0.64)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
            }

            Column {
              spacing: Style.space(2)
              Text {
                text: root.checkingPluginStatuses ? "…" : root.trustedPluginCount()
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                text: "TRUSTED"
                color: Util.alpha(root.contentForeground, 0.64)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
            }

            Column {
              spacing: Style.space(2)
              Text {
                text: root.checkingPluginStatuses ? "…" : root.reviewPluginCount()
                color: root.warningColor
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                text: "REVIEW"
                color: Util.alpha(root.contentForeground, 0.64)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
            }

            Column {
              spacing: Style.space(2)
              Text {
                text: root.checkingPluginStatuses ? "…" : root.untrustedPluginCount()
                color: root.statusColor("unknown")
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                text: "UNTRUSTED"
                color: Util.alpha(root.contentForeground, 0.64)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
            }
          }
        }

        Text {
          width: parent.width
          text: "Trusted means the current source exactly matches a recorded baseline."
          wrapMode: Text.WordWrap
          color: Util.alpha(root.contentForeground, 0.58)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.panelError !== ""
          width: parent.width
          text: root.panelError
          wrapMode: Text.WordWrap
          color: root.statusColor("critical")
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.alerts.length > 0

          Text {
            text: "FINDINGS"
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }

          Repeater {
            model: root.alerts

            Rectangle {
              required property var modelData
              readonly property color severityColor: root.statusColor(root.alertLevel(modelData))
              readonly property bool selected: root.selectedPluginId === modelData.plugin_id
              width: parent.width
              implicitHeight: finding.implicitHeight + Style.space(14)
              radius: Style.cornerRadius
              clip: true
              // Findings are the actionable items — always tinted by severity so
              // they stand out from the passive detail cards, brighter when selected.
              color: Util.alpha(severityColor, selected ? 0.18 : 0.08)
              border.width: 1
              border.color: selected ? severityColor : Util.alpha(severityColor, 0.35)

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Style.space(3)
                color: parent.severityColor
              }

              Column {
                id: finding
                anchors.fill: parent
                anchors.margins: Style.space(7)
                anchors.leftMargin: Style.space(11)
                spacing: Style.space(3)

                Row {
                  spacing: Style.space(6)

                  Rectangle {
                    width: Style.space(14)
                    height: width
                    radius: width / 2
                    color: root.statusColor(root.alertLevel(modelData))
                    Text {
                      anchors.centerIn: parent
                      text: "!"
                      color: Color.background
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                  }

                  Text {
                    text: root.alertLabel(modelData)
                    color: root.statusColor(root.alertLevel(modelData))
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }
                }

                Text {
                  width: parent.width
                  text: modelData.plugin_id + " · " + modelData.message
                  wrapMode: Text.WordWrap
                  color: root.contentForeground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectPlugin(modelData.plugin_id, modelData)
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.inventoryReport !== null

          Text {
            text: "SELECTED PLUGIN"
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }

          Rectangle {
            width: parent.width
            implicitHeight: details.implicitHeight + Style.space(14)
            radius: Style.cornerRadius
            color: Util.alpha(root.contentForeground, 0.05)
            border.width: 1
            border.color: Util.alpha(root.contentForeground, 0.20)

            Column {
              id: details
              anchors.fill: parent
              anchors.margins: Style.space(7)
              spacing: Style.space(5)

              Text {
                width: parent.width
                text: root.selectedPluginId || "No installed plugin selected"
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.body
                font.bold: true
              }

              Text {
                width: parent.width
                visible: root.pluginById(root.selectedPluginId) !== null
                text: {
                  var plugin = root.pluginById(root.selectedPluginId)
                  return plugin ? "Classification: " + plugin.classification +
                    "\nDigest: " + root.shortDigest(plugin.content_digest) +
                    "\nCoverage: " + ((plugin.limitations || []).join(", ") || "complete") : ""
                }
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                visible: root.statusReport !== null
                text: root.statusReport ? "Baseline: " + (root.statusReport.trusted
                  ? root.shortDigest(root.statusReport.trusted.content_digest) : "not established") +
                  "\nCurrent state: " + root.statusReport.state : ""
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                visible: root.marketplaceByPlugin(root.selectedPluginId) !== null
                text: {
                  var marketplace = root.marketplaceByPlugin(root.selectedPluginId)
                  return marketplace ? "Marketplace: " + marketplace.status +
                    "\nSnapshot: " + (root.inventoryReport.marketplace_retrieved_at || "unavailable") +
                    (root.inventoryReport.marketplace_stale ? " (stale)" : "") : ""
                }
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                visible: root.diffReport !== null
                text: root.diffReport ? "Changed files: " +
                  ((root.diffReport.changed_files || []).slice(0, 5).join(", ") || "none") +
                  ((root.diffReport.changed_files || []).length > 5
                    ? " +" + ((root.diffReport.changed_files || []).length - 5) + " more" : "") : ""
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                visible: root.selectedError !== ""
                text: root.selectedError
                wrapMode: Text.WordWrap
                color: root.warningColor
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Rectangle {
                width: parent.width
                visible: root.canTrustSelectedPlugin() || root.canUntrustSelectedPlugin()
                implicitHeight: trustControls.implicitHeight + Style.space(18)
                radius: Style.cornerRadius
                // Distinct inset panel so the trust actions read as a control
                // surface, separate from the read-only identity above.
                color: Util.alpha(Color.accent, 0.06)
                border.width: 1
                border.color: Util.alpha(Color.accent, 0.30)

                Column {
                  id: trustControls
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: Style.space(9)
                  spacing: Style.space(7)

                  Text {
                    text: "TRUST CONTROLS"
                    color: Color.accent
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    font.letterSpacing: 1
                  }

                  Row {
                    width: parent.width
                    spacing: Style.space(8)

                    Button {
                      visible: root.canTrustSelectedPlugin()
                      width: root.canTrustSelectedPlugin() && root.canUntrustSelectedPlugin()
                        ? (parent.width - parent.spacing) / 2 : parent.width
                      text: trustProcess.running && root.trustOperation === "trust"
                        ? "Recording…"
                        : (root.statusReport && root.statusReport.trusted
                          ? "Replace baseline" : "Trust current source")
                      tooltipText: "Record this exact source identity as the plugin's trust baseline."
                      enabled: !trustProcess.running
                      focusable: true
                      background: Color.accent
                      foreground: Color.background
                      accent: Color.accent
                      fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                      onClicked: {
                        root.trustError = ""
                        root.untrustConfirming = false
                        root.trustConfirming = true
                      }
                    }

                    Button {
                      visible: root.canUntrustSelectedPlugin()
                      width: root.canTrustSelectedPlugin()
                        ? (parent.width - parent.spacing) / 2 : parent.width
                      text: trustProcess.running && root.trustOperation === "untrust"
                        ? "Removing…" : "Untrust"
                      tooltipText: "Remove this plugin's active trust baseline."
                      enabled: !trustProcess.running
                      bordered: true
                      focusable: true
                      background: Util.alpha(root.warningColor, 0.14)
                      foreground: root.warningColor
                      accent: root.warningColor
                      fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                      onClicked: {
                        root.trustError = ""
                        root.trustConfirming = false
                        root.untrustConfirming = true
                      }
                    }
                  }
                }
              }

              Button {
                text: root.showPluginPicker ? "Hide plugin list" : "Select another plugin"
                tooltipText: "Choose another installed, non-backup plugin."
                onClicked: root.showPluginPicker = !root.showPluginPicker
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.showPluginPicker

          Text {
            text: "INSTALLED PLUGINS"
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }

          Repeater {
            model: root.visiblePlugins()

            Rectangle {
              required property var modelData
              width: parent.width
              implicitHeight: pluginRow.implicitHeight + Style.space(14)
              radius: Style.cornerRadius
              color: root.selectedPluginId === modelData.id
                ? Util.alpha(root.statusColor(root.pluginStatusLevel(modelData)), 0.14) : "transparent"
              border.width: 1
              border.color: root.selectedPluginId === modelData.id
                ? root.statusColor(root.pluginStatusLevel(modelData)) : Util.alpha(root.contentForeground, 0.20)

              Row {
                id: pluginRow
                anchors.fill: parent
                anchors.margins: Style.space(7)
                spacing: Style.space(7)

                OmaSafeStatusIcon {
                  anchors.verticalCenter: parent.verticalCenter
                  level: root.pluginStatusLevel(modelData)
                  warningColor: root.warningColor
                  criticalColor: root.bar ? root.bar.urgent : Color.urgent
                }

                Column {
                  width: parent.width - Style.space(30)
                  spacing: Style.space(1)

                  Text {
                    width: parent.width
                    text: modelData.id
                    elide: Text.ElideRight
                    color: root.contentForeground
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    width: parent.width
                    text: root.pluginStatusLabel(modelData)
                    elide: Text.ElideRight
                    color: Util.alpha(root.contentForeground, 0.68)
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectPlugin(modelData.id, null)
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          visible: root.trustConfirming
          implicitHeight: trustConfirmation.implicitHeight + Style.space(14)
          radius: Style.cornerRadius
          color: Util.alpha(root.warningColor, 0.12)
          border.width: 1
          border.color: root.warningColor

          Column {
            id: trustConfirmation
            anchors.fill: parent
            anchors.margins: Style.space(7)
            spacing: Style.space(8)

            Text {
              text: root.statusReport && root.statusReport.trusted
                ? "REPLACE TRUST BASELINE?" : "TRUST CURRENT IDENTITY?"
              color: root.warningColor
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
            }

            Text {
              width: parent.width
              text: "This records the exact current source identity for " + root.selectedPluginId + "."
              wrapMode: Text.WordWrap
              color: root.contentForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              width: parent.width
              text: {
                var plugin = root.selectedPlugin()
                return plugin ? "Commit: " + (plugin.head || "unavailable") +
                  "\nTree: " + (plugin.tree || "unavailable") +
                  "\nDigest: " + (plugin.content_digest || "unavailable") : ""
              }
              wrapMode: Text.WrapAnywhere
              color: Util.alpha(root.contentForeground, 0.78)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              width: parent.width
              text: "Trusting this identity does not establish that the plugin is safe."
              wrapMode: Text.WordWrap
              color: root.warningColor
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }

            Row {
              spacing: Style.space(8)

              Button {
                text: "Cancel"
                enabled: !trustProcess.running
                bordered: true
                focusable: true
                foreground: root.contentForeground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.trustConfirming = false
              }

              Button {
                text: trustProcess.running ? "Recording…" : "Trust this identity"
                enabled: !trustProcess.running
                focusable: true
                background: Color.accent
                foreground: Color.background
                accent: Color.accent
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.trustSelectedPlugin()
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          visible: root.untrustConfirming
          implicitHeight: untrustConfirmation.implicitHeight + Style.space(14)
          radius: Style.cornerRadius
          color: Util.alpha(root.warningColor, 0.14)
          border.width: 1
          border.color: root.warningColor

          Column {
            id: untrustConfirmation
            anchors.fill: parent
            anchors.margins: Style.space(9)
            spacing: Style.space(8)

            Text {
              text: "REMOVE TRUST BASELINE?"
              color: root.warningColor
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
            }

            Text {
              width: parent.width
              text: "OmaSafe will stop treating " + root.selectedPluginId +
                " as trusted. Its previous trust record stays in history, but the plugin will need a new explicit trust decision."
              wrapMode: Text.WordWrap
              color: root.contentForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }

            Row {
              spacing: Style.space(8)

              Button {
                text: "Keep baseline"
                enabled: !trustProcess.running
                bordered: true
                focusable: true
                foreground: root.contentForeground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.untrustConfirming = false
              }

              Button {
                text: trustProcess.running && root.trustOperation === "untrust"
                  ? "Removing…" : "Untrust plugin"
                enabled: !trustProcess.running
                focusable: true
                background: root.warningColor
                foreground: Color.background
                accent: root.warningColor
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.untrustSelectedPlugin()
              }
            }
          }
        }

        Text {
          width: parent.width
          visible: root.inventoryReport && root.inventoryReport.non_builtin_bar_replaces_bar
          text: "A third-party full-bar plugin replaces the OmaSafe bar widget. CLI and desktop notifications remain available."
          wrapMode: Text.WordWrap
          color: root.warningColor
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Button {
          text: root.statusLevel === "checking" ? "Scanning…" : "Run scan"
          enabled: root.hostWidget && root.statusLevel !== "checking"
          focusable: true
          background: Color.accent
          foreground: Color.background
          accent: Color.accent
          width: parent.width
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: if (root.hostWidget) root.hostWidget.runScan()
        }

        Button {
          text: root.showCompliantPlugins ? "Hide baselined plugins" : "Show baselined plugins"
          tooltipText: "Show installed plugins whose trusted source identity exactly matches the current source."
          bordered: true
          focusable: true
          width: parent.width
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: {
            root.showCompliantPlugins = !root.showCompliantPlugins
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.showCompliantPlugins

          Text {
            text: "BASELINED & UNCHANGED"
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }

          Text {
            width: parent.width
            text: root.checkingPluginStatuses
              ? "Checking installed plugin baselines…"
              : (root.baselinedUnchangedPlugins().length > 0
                ? "These plugins match a recorded trust baseline with complete coverage."
                : "No installed plugins currently meet this condition.")
            wrapMode: Text.WordWrap
            color: Util.alpha(root.contentForeground, 0.72)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }

          Repeater {
            model: root.baselinedUnchangedPlugins()

            Rectangle {
              required property var modelData
              width: parent.width
              implicitHeight: Style.space(28)
              radius: Style.cornerRadius
              color: Util.alpha(root.contentForeground, 0.05)
              border.width: 1
              border.color: Util.alpha(root.contentForeground, 0.20)

              Row {
                anchors.fill: parent
                anchors.margins: Style.space(7)
                spacing: Style.space(6)

                OmaSafeStatusIcon {
                  anchors.verticalCenter: parent.verticalCenter
                  level: "normal"
                  warningColor: root.warningColor
                  criticalColor: root.bar ? root.bar.urgent : Color.urgent
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - Style.space(28)
                  text: modelData.id
                  elide: Text.ElideRight
                  color: root.contentForeground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }

        Text {
          width: parent.width
          text: "OmaSafe reports changes and coverage limits. It does not declare plugins safe."
          wrapMode: Text.WordWrap
          color: Util.alpha(root.contentForeground, 0.64)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
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
    property var nextCommand: null
    command: root.cliCommand(["plugins", "status", "", "--format", "json"])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatus(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") root.selectedError = String(text).trim()
    }
    onExited: if (statusProcess.nextCommand) root.launchProcess(statusProcess, statusProcess.nextCommand)
  }

  Process {
    id: diffProcess
    property var nextCommand: null
    command: root.cliCommand(["plugins", "diff", "", "--format", "json"])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyDiff(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") root.selectedError = String(text).trim()
    }
    onExited: if (diffProcess.nextCommand) root.launchProcess(diffProcess, diffProcess.nextCommand)
  }

  Process {
    id: listStatusProcess
    property string pluginId: ""
    property bool receivedReport: false
    command: root.cliCommand(["plugins", "status", "", "--format", "json"])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        listStatusProcess.receivedReport = true
        root.applyListedPluginStatus(listStatusProcess.pluginId, text)
      }
    }
    onExited: {
      if (!listStatusProcess.receivedReport)
        root.recordPluginStatus(listStatusProcess.pluginId, { state: "unavailable" })
      Qt.callLater(root.runNextPluginStatus)
    }
  }

  Process {
    id: trustProcess
    command: root.cliCommand([])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {}
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.trustError = String(text || "").trim()
    }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.trustConfirming = false
        root.untrustConfirming = false
        root.panelError = ""
        root.selectPlugin(root.selectedPluginId, root.selectedAlert())
        root.refreshPluginStatuses()
        if (root.hostWidget) root.hostWidget.runScan()
      } else {
        root.panelError = root.trustError || (root.trustOperation === "untrust"
          ? "Trust baseline could not be removed."
          : "Trust baseline could not be recorded.")
      }
      root.trustOperation = ""
    }
  }
}
