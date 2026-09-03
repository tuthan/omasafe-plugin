import QtQuick
import qs.Commons
import qs.Ui
import "../components"
import "../model/Glyphs.js" as Glyphs

// Overview view (doc 03 §4): ALERTS · PLUGINS · SOURCES with one non-destructive next
// step per row and the product disclaimer at the foot. Presentational — it binds to
// `panel.vm` and the panel cursor state, and calls back into `panel` for navigation
// and actions. The fixed hero / chips / notices live in Panel.qml above the Flickable.
Column {
  id: root

  // The Panel.qml root: colours, vm, cursor state and action callbacks.
  property var panel: null
  readonly property var vm: panel ? panel.vm : null
  readonly property string rf: Style.font.resolvedFamily

  // Filters synthetic hover churn from delegates reflowing under a stationary
  // pointer, so only real pointer motion moves the cursor (Ui/PointerMoveGate.qml).
  PointerMoveGate { id: gate; referenceItem: root }

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(12)

  readonly property bool cliVerified: panel && panel.cliVerified
  readonly property bool inventoryLoaded: panel && panel.inventoryReport !== null
  readonly property bool showBackups: panel && panel.showPluginBackups

  function has(section, index) {
    return panel && panel.cursorActive && panel.focusSection === section && panel.selectedIndex === index
  }

  // ---- CLI unavailable: one notice replaces the whole body (doc 03 §4.3) --------
  NoticeRow {
    width: parent.width
    visible: !root.cliVerified
    reason: "unavailable"
    text: "Plugins, review items, rules and the trust flow are unavailable until omasafe-cli 0.2.1 or newer is found on PATH."
    foreground: panel ? panel.fg : Color.foreground
    dim: panel ? panel.dim : Color.foreground
    urgent: panel ? panel.urgent : Color.urgent
    fontFamily: panel ? panel.fontFamily : Style.font.family
    resolvedFamily: root.rf
  }

  // ---- ALERTS (only when outstanding > 0) --------------------------------------
  Column {
    width: parent.width
    visible: root.cliVerified && root.vm && root.vm.outstanding > 0
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "ALERTS"
      value: root.vm ? String(root.vm.outstanding) : ""
      foreground: panel ? panel.dimHeader : Color.foreground
      valueColor: panel ? panel.dimHeader : Color.foreground
      fontFamily: panel ? panel.fontFamily : Style.font.family
    }

    Repeater {
      model: root.vm ? root.vm.alerts : []
      delegate: AlertRow {
        required property var modelData
        required property int index
        width: parent.width
        kindLabel: modelData.kindLabel
        subtitle: modelData.subtitle
        severity: modelData.severity
        severityLevel: modelData.severityLevel
        urgent: modelData.urgent
        pseudo: modelData.pseudo
        hasCursor: root.has("alerts", index)
        foreground: panel ? panel.fg : Color.foreground
        dim: panel ? panel.dim : Color.foreground
        urgentColor: panel ? panel.urgent : Color.urgent
        fontFamily: panel ? panel.fontFamily : Style.font.family
        resolvedFamily: root.rf
        onOpenRequested: if (panel) panel.openPluginFromAlert(modelData.pluginId)
        onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
          onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("alerts", index) }
        }
      }
    }
  }

  // ---- PLUGINS -----------------------------------------------------------------
  Column {
    width: parent.width
    visible: root.cliVerified
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "PLUGINS"
      value: {
        if (!root.inventoryLoaded) return root.vm && root.vm.plugins.length > 0 ? "LOADING PLUGINS…" : ""
        var v = root.vm.liveCount + " · " + root.vm.analyzedCount + " ANALYZED"
        if (root.showBackups && root.vm.backupCount > 0) v += " · SHOWING " + root.vm.backupCount + " BACKUPS"
        return v
      }
      foreground: panel ? panel.dimHeader : Color.foreground
      valueColor: panel ? panel.dimHeader : Color.foreground
      fontFamily: panel ? panel.fontFamily : Style.font.family
    }

    // Loading first-ever open: one notice, no rows.
    NoticeRow {
      width: parent.width
      visible: !root.inventoryLoaded && (!root.vm || root.vm.plugins.length === 0)
      reason: "loading"
      text: "Loading plugins…"
      foreground: panel ? panel.fg : Color.foreground
      dim: panel ? panel.dim : Color.foreground
      fontFamily: panel ? panel.fontFamily : Style.font.family
      resolvedFamily: root.rf
    }

    // Empty inventory.
    NoticeRow {
      width: parent.width
      visible: root.inventoryLoaded && root.vm && root.vm.plugins.length === 0
      reason: "none"
      text: "No plugins installed."
      foreground: panel ? panel.fg : Color.foreground
      dim: panel ? panel.dim : Color.foreground
      fontFamily: panel ? panel.fontFamily : Style.font.family
      resolvedFamily: root.rf
    }

    Repeater {
      model: root.vm ? root.vm.plugins : []
      delegate: PluginRow {
        required property var modelData
        required property int index
        width: parent.width
        classGlyph: Glyphs.ui_(modelData.classGlyphKey, root.rf)
        pluginId: modelData.id
        trustWord: modelData.trustWord
        trustGlyph: modelData.trustGlyphKey !== "" ? Glyphs.ui_(modelData.trustGlyphKey, root.rf) : ""
        trustBold: modelData.trustBold
        trustTooltip: modelData.trustLong
        analyzed: modelData.analyzed
        healthState: modelData.healthState
        healthLabel: modelData.healthLabel
        counts: modelData.counts
        countText: modelData.countText
        limitsText: modelData.limitsText
        lexicalText: modelData.lexicalText
        hasCursor: root.has("plugins", index)
        current: panel && modelData.id === panel.selectedPluginId
        foreground: panel ? panel.fg : Color.foreground
        dim: panel ? panel.dim : Color.foreground
        urgentColor: panel ? panel.urgent : Color.urgent
        fontFamily: panel ? panel.fontFamily : Style.font.family
        resolvedFamily: root.rf
        onOpenRequested: if (panel) panel.openPlugin(modelData.id)
        onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("plugins", index) }
          onClicked: if (panel) panel.openPlugin(modelData.id)
        }
      }
    }

    // Backup rows (shown only when the toggle is on), continuing the plugins index.
    Repeater {
      model: root.showBackups && root.vm ? root.vm.backups : []
      delegate: PluginRow {
        required property var modelData
        required property int index
        width: parent.width
        classGlyph: Glyphs.ui_("backup", root.rf)
        pluginId: modelData.id
        trustWord: modelData.trustWord
        analyzed: false
        healthState: modelData.healthState
        healthLabel: modelData.healthLabel
        counts: ({})
        countText: modelData.countText
        hasCursor: root.has("plugins", (root.vm ? root.vm.plugins.length : 0) + index)
        foreground: panel ? panel.fg : Color.foreground
        dim: panel ? panel.dim : Color.foreground
        urgentColor: panel ? panel.urgent : Color.urgent
        fontFamily: panel ? panel.fontFamily : Style.font.family
        resolvedFamily: root.rf
        onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
          onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("plugins", (root.vm ? root.vm.plugins.length : 0) + index) }
        }
      }
    }

    // Backups toggle row.
    CursorSurface {
      id: backupsRow
      width: parent.width
      visible: root.inventoryLoaded && root.vm && root.vm.backupCount > 0
      implicitHeight: backupsContent.implicitHeight + Style.spacing.rowPaddingX
      hasCursor: root.has("backups-toggle", 0)
      foreground: panel ? panel.fg : Color.foreground
      onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)

      Row {
        id: backupsContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.space(10)
        anchors.rightMargin: Style.space(8)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - toggle.width
          textFormat: Text.PlainText
          text: "Show " + (root.vm ? root.vm.backupCount : 0) + " backup copies (not scanned)"
          color: panel ? panel.fg : Color.foreground
          font.family: panel ? panel.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        ToggleSwitch {
          id: toggle
          anchors.verticalCenter: parent.verticalCenter
          interactive: false
          checked: root.showBackups
          hasCursor: backupsRow.hasCursor
          foreground: panel ? panel.fg : Color.foreground
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("backups-toggle", 0) }
        onClicked: if (panel) panel.toggleBackups()
      }
    }

    // Footer definition (doc 03 §4.1): once, verbatim.
    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.inventoryLoaded && root.vm && root.vm.plugins.length > 0
      textFormat: Text.PlainText
      text: "A baseline is the exact source identity you recorded. \"Matches\" and \"differs\" compare the installed files against it; neither is a safety judgment."
      color: panel ? panel.dim : Color.foreground
      font.family: panel ? panel.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }

  // ---- SOURCES -----------------------------------------------------------------
  Column {
    id: sourcesSection
    width: parent.width
    visible: root.cliVerified
    spacing: Style.space(6)
    readonly property var s: root.vm ? root.vm.sources : null

    SectionHeaderRow {
      text: "SOURCES"
      foreground: panel ? panel.dimHeader : Color.foreground
      fontFamily: panel ? panel.fontFamily : Style.font.family
    }

    // Schedule / catalog result or error line (doc 03 §4.4, T2.14).
    NoticeRow {
      width: parent.width
      visible: panel && panel.sourcesStatusLine() !== ""
      reason: (panel && panel.sourcesStatusIsError()) ? "unavailable" : "none"
      cliFailure: panel && panel.sourcesStatusIsError()
      text: panel ? panel.sourcesStatusLine() : ""
      foreground: panel ? panel.fg : Color.foreground
      dim: panel ? panel.dim : Color.foreground
      urgent: panel ? panel.urgent : Color.urgent
      fontFamily: panel ? panel.fontFamily : Style.font.family
      resolvedFamily: root.rf
    }

    // omasafe-cli version — the only place the CLI version is printed.
    SourceRow {
      width: parent.width
      label: "omasafe-cli " + (sourcesSection.s ? sourcesSection.s.cliVersion : "")
      hasCursor: root.has("sources", 0)
      foreground: panel ? panel.fg : Color.foreground
      dim: panel ? panel.dim : Color.foreground
      faint: panel ? panel.faint : Color.foreground
      fontFamily: panel ? panel.fontFamily : Style.font.family
      resolvedFamily: root.rf
      onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
      MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
        onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("sources", 0) } }
    }

    // Catalog snapshot + inline update progress.
    SourceRow {
      width: parent.width
      label: panel && panel.catalogUpdating
        ? ("Updating catalog… " + panel.catalogElapsed + " s")
        : ("Catalog snapshot " + (sourcesSection.s ? sourcesSection.s.snapshotCommit7 : "") + " · " + (sourcesSection.s ? sourcesSection.s.snapshotAgeText : ""))
      sublabel: (sourcesSection.s && !panel.catalogUpdating) ? sourcesSection.s.snapshotSourceText : ""
      iconAction: (panel && !panel.catalogUpdating) ? Glyphs.ui_("rescan", root.rf) : ""
      iconTooltip: "Update catalog"
      hasCursor: root.has("sources", 1)
      foreground: panel ? panel.fg : Color.foreground
      dim: panel ? panel.dim : Color.foreground
      faint: panel ? panel.faint : Color.foreground
      fontFamily: panel ? panel.fontFamily : Style.font.family
      resolvedFamily: root.rf
      onIconActionRequested: if (panel) panel.updateCatalog()
      onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
      MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
        onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("sources", 1) } }
    }

    // Scheduled scan.
    SourceRow {
      width: parent.width
      label: sourcesSection.s ? sourcesSection.s.scheduleLabel : ""
      sublabel: sourcesSection.s ? sourcesSection.s.scheduleSub : ""
      actionText: sourcesSection.s ? sourcesSection.s.scheduleAction : ""
      actionTooltip: "Install scheduled scan"
      actionEnabled: panel && !panel.navigationLocked
      hasCursor: root.has("sources", 2)
      foreground: panel ? panel.fg : Color.foreground
      dim: panel ? panel.dim : Color.foreground
      faint: panel ? panel.faint : Color.foreground
      fontFamily: panel ? panel.fontFamily : Style.font.family
      resolvedFamily: root.rf
      onActionRequested: if (panel) panel.beginSchedule()
      onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
      MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
        onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("sources", 2) } }
    }

    // Enforcement overrides.
    SourceRow {
      width: parent.width
      label: "Enforcement overrides · " + (sourcesSection.s && sourcesSection.s.overrideCount > 0
        ? (sourcesSection.s.overrideCount + " active") : "none recorded")
      expandable: sourcesSection.s && sourcesSection.s.overrideCount > 0
      expanded: panel && panel.overrideDetailsExpanded
      hasCursor: root.has("sources", 3)
      foreground: panel ? panel.fg : Color.foreground
      dim: panel ? panel.dim : Color.foreground
      faint: panel ? panel.faint : Color.foreground
      fontFamily: panel ? panel.fontFamily : Style.font.family
      resolvedFamily: root.rf
      onToggleRequested: if (panel) panel.toggleOverrides()
      onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
      MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
        onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("sources", 3) } }
    }

    // Expanded override entries (doc 03 §4.4): read-only; the panel cannot create
    // overrides, and expires_at is shown verbatim, never compared to the local clock.
    Column {
      width: parent.width
      visible: panel && panel.overrideDetailsExpanded && sourcesSection.s && sourcesSection.s.overrideCount > 0
      spacing: Style.space(1)

      Repeater {
        model: (panel && panel.overrideDetailsExpanded && sourcesSection.s) ? sourcesSection.s.overrides : []
        delegate: Column {
          required property var modelData
          width: parent.width
          spacing: Style.space(1)
          Text {
            width: parent.width - Style.space(38); x: Style.space(30)
            textFormat: Text.PlainText
            text: String(modelData.plugin_id || "") + " · " + (panel ? panel.overrideStatus(modelData.status) : "")
              + " · expires " + ((modelData.binding && modelData.binding.expires_at) ? String(modelData.binding.expires_at) : "unavailable")
            color: panel ? panel.fg : Color.foreground
            font.family: panel ? panel.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WrapAnywhere
          }
          Text {
            width: parent.width - Style.space(38); x: Style.space(30)
            textFormat: Text.PlainText
            text: "rules " + ((modelData.binding && modelData.binding.rule_ids) ? String(modelData.binding.rule_ids) : "")
              + " · commit " + ((modelData.binding && modelData.binding.commit) ? String(modelData.binding.commit).slice(0, 7) : "unavailable")
            color: panel ? panel.dim : Color.foreground
            font.family: panel ? panel.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WrapAnywhere
          }
        }
      }

      Text {
        width: parent.width - Style.space(38); x: Style.space(30)
        topPadding: Style.space(4)
        textFormat: Text.PlainText
        text: "Override validity is evaluated by the CLI; this panel cannot create overrides."
        color: panel ? panel.dim : Color.foreground
        font.family: panel ? panel.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }

    // Product disclaimer footer (doc 03 §4.1): once, verbatim.
    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      topPadding: Style.space(6)
      textFormat: Text.PlainText
      text: "OmaSafe reports changes and coverage limits. It does not declare plugins safe."
      color: panel ? panel.dim : Color.foreground
      font.family: panel ? panel.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }
}
