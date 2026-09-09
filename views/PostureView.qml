import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../components"
import "../model/Glyphs.js" as Glyphs
import "../model/Posture.js" as Posture

// Host posture (doc 08 §5.1, §5.2). Evidence about this machine, not a clean/safe
// verdict: the report's state words and coverage limitations stay beside every check,
// so incomplete observation can never render as a healthy result.
//
// The tab used to open on check #1 of 18 in alphabetical order — the single
// regression was item 17, both incomplete checks were 5 and 18, and the header
// printed `14 COMPLETE`, which reads as "14 fine" although `complete` means only
// that observation succeeded. This rebuild puts a summary band above the fold and
// the attention set above everything else.
//
// Presentational. Every ordering, count and sentence comes from `panel.postureModel`
// (`model/Posture.js`); this file decides layout and nothing else.
Column {
  id: root

  property var panel: null
  readonly property var model: panel ? panel.postureModel : null
  readonly property string rf: Style.font.resolvedFamily

  // Disclosure state is keyed by check id and by domain, and it lives on the panel
  // rather than here: the cursor's index space depends on it, because a collapsed
  // domain removes rows that `sectionCount("posture-checks")` must not count. It is
  // reset when the panel closes, with the rest of the expansion state.
  PointerMoveGate { id: gate; referenceItem: root }

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(10)

  function col(name) { return panel ? panel[name] : Color.foreground }
  function has(section, index) {
    return panel && panel.cursorActive && panel.focusSection === section && panel.selectedIndex === index
  }
  function glyph(key) { return Glyphs.ui_(key, root.rf) }

  function checkExpanded(id) { return panel ? panel.postureCheckExpanded(id) : false }
  function toggleCheck(id) { if (panel) panel.postureToggleCheck(id) }
  function groupCollapsed(domain) { return panel ? panel.postureGroupCollapsed(domain) : false }
  function toggleGroup(domain) { if (panel) panel.postureToggleGroup(domain) }

  // The flattened list of check rows currently on screen under OBSERVED, in the same
  // order the Repeater renders them. `Panel.sectionCount("posture-checks")` reads the
  // identical helper, so the cursor's index space and the rows on screen are the same
  // list by construction rather than by agreement.
  function observedRows() { return panel ? panel.postureObservedRows() : [] }
  function copyActions() { return panel ? panel.postureCopyActions() : [] }

  // ---- notices: unchanged copy, moved above the summary band -------------------

  NoticeRow {
    width: parent.width
    visible: !root.panel || !root.panel.cliVerified
    reason: "unavailable"
    text: "Host posture is unavailable until omasafe-cli 0.3.0 or newer is verified."
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }
  NoticeRow {
    width: parent.width
    visible: root.panel && root.panel.postureLoading
    reason: "loading"
    text: "Collecting bounded host observations…"
    foreground: root.col("fg"); dim: root.col("dim")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }
  NoticeRow {
    width: parent.width
    visible: root.panel && root.panel.postureError !== ""
    reason: "unavailable"; cliFailure: true
    text: root.panel ? root.panel.postureError : "Host posture is unavailable."
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }
  NoticeRow {
    width: parent.width
    visible: root.model && root.model.notYetRun && !(root.panel && root.panel.postureLoading)
    reason: "unsupported"
    text: "No posture scan has completed yet. Run a scan to establish the first observation; this is not a clean result."
    foreground: root.col("fg"); dim: root.col("dim")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }
  NoticeRow {
    width: parent.width
    visible: root.model && root.model.available && root.model.stale
    reason: "stale"
    text: root.model
      ? "This posture report is stale (" + root.model.ageText + "); run a scan for current observations."
      : ""
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }

  // ---- summary band (08 §5.1) --------------------------------------------------

  SectionHeaderRow {
    text: "HOST POSTURE"
    value: {
      if (!root.model) return ""
      if (root.model.notYetRun) return "NOT YET RUN"
      if (!root.model.available) return ""
      var parts = []
      if (root.model.catalogVersion !== null) parts.push("CATALOG V" + root.model.catalogVersion)
      parts.push(root.model.checkTotal + " CHECKS")
      return parts.join(" · ")
    }
    foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
    fontFamily: root.col("fontFamily")
  }

  Column {
    id: band
    width: parent.width
    visible: !!root.model && root.model.available
    // The band's lines are lines of ONE block, not separate rows, so they take the
    // tighter space(4) of the preferred set (02 §2.2) rather than the space(6) row
    // gap. Six facts have to fit above the attention set.
    spacing: Style.space(4)

    // One cell per check, in catalog order, so cell 17 is always the same check on
    // every host and every run (CH8). Colour is the third channel: the state word is
    // on the tooltip and on the row the cell links to.
    UnitStrip {
      id: strip
      width: parent.width - Style.space(18); x: Style.space(10)
      cells: {
        var out = []
        var cells = root.model ? root.model.strip : []
        for (var i = 0; i < cells.length; i++) {
          out.push({
            key: cells[i].key,
            glyph: root.glyph(cells[i].glyphKey),
            level: cells[i].level,
            tooltip: cells[i].tooltip
          })
        }
        return out
      }
      cursorIndex: root.panel && root.panel.focusSection === "posture-strip"
        ? root.panel.selectedIndex : -1
      focused: root.panel && root.panel.cursorActive && root.panel.focusSection === "posture-strip"
      foreground: root.col("fg"); dim: root.col("dim"); accent: Color.accent
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
      onHovered: function(index) { if (root.panel) root.panel.hoverCursor("posture-strip", index) }
      onActivated: function(index) { if (root.panel) root.panel.postureRevealCheck(index) }
    }

    // The STATE axis, in attention order, with every catalog state's exact count
    // including its zeros (CH1, CH7). Deleting the strip above loses speed, not
    // information.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: root.model && root.model.stateCountsText !== ""
      textFormat: Text.PlainText
      text: root.model ? root.model.stateCountsText : ""
      color: root.col("fg")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    // The OBSERVATION axis, written as a sentence precisely so it cannot be read as a
    // health tally. This is the fix for the old `14 COMPLETE · 2 INCOMPLETE · 2 N/A`.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: root.model && root.model.coverageSentence !== null
      textFormat: Text.PlainText
      text: root.model && root.model.coverageSentence !== null ? root.model.coverageSentence : ""
      color: root.col("fg")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: {
        if (!root.model) return ""
        var host = {}
        for (var i = 0; i < root.model.host.length; i++) host[root.model.host[i].label] = root.model.host[i].value
        var parts = ["Report " + root.model.ageText + " old"]
        if (host["ARCH"] && host["ARCH"] !== "unknown") parts.push(host["ARCH"] + " " + host["KERNEL"])
        if (host["OMARCHY"] && host["OMARCHY"] !== "not observed") parts.push("Omarchy " + host["OMARCHY"])
        return parts.join(" · ")
      }
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    // The tools line states the count, names the missing tool AND its consequence in
    // one sentence, so a coverage gap arrives with its cause instead of unexplained.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: root.model && root.model.tools && root.model.tools.sentence !== ""
      textFormat: Text.PlainText
      text: root.model && root.model.tools ? root.model.tools.sentence : ""
      color: root.model && root.model.tools && root.model.tools.missing.length > 0
        ? root.col("fg") : root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

  }

  // The control row sits OUTSIDE the summary band, because the band is hidden until a
  // report exists and "Run posture scan" is exactly the action a host with no report
  // needs. Losing it in the not_yet_run state would leave the tab with no way to start
  // the first scan except the `r` key.
  Row {
    x: Style.space(10)
    spacing: Style.space(6)

    Button {
      text: "Run posture scan"
      bordered: true
      enabled: root.panel && root.panel.cliVerified && !root.panel.postureLoading
      foreground: enabled ? root.col("fg") : root.col("faint")
      fontFamily: root.col("fontFamily")
      tooltipText: "Collect a current host posture report"
      onClicked: if (root.panel) root.panel.runPostureScan()
    }
    Button {
      visible: root.panel && root.panel.postureLoading
      text: "Collecting…"
      bordered: true
      enabled: false
      foreground: root.col("faint")
      fontFamily: root.col("fontFamily")
    }
    Button {
      visible: !!root.model && root.model.available
      text: root.panel && root.panel.postureHostExpanded ? "Hide host details" : "Host details"
      bordered: true
      foreground: root.col("dim")
      fontFamily: root.col("fontFamily")
      onClicked: if (root.panel) root.panel.postureHostExpanded = !root.panel.postureHostExpanded
    }
  }

  // The six-row host grid and the standing disclaimer no longer occupy the top of the
  // tab: they are one click below the age line they qualify, which is what buys the
  // attention set its place above the fold.
  Column {
    width: parent.width
    visible: !!root.model && root.model.available && root.panel && root.panel.postureHostExpanded
    spacing: Style.space(4)

    InfoGrid {
      width: parent.width
      rows: root.model ? root.model.host : []
      foreground: root.col("fg"); labelColor: root.col("dim")
      fontFamily: root.col("fontFamily")
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: root.model && root.model.lastObservedPostUpdateHook !== ""
      textFormat: Text.PlainText
      text: root.model && root.model.lastObservedPostUpdateHook !== ""
        ? "Last observed post-update hook: " + root.model.lastObservedPostUpdateHook : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: "OmaSafe observations about this host. A pass is limited to the checks and tools observed at the report time; incomplete and error states remain open coverage gaps."
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
  }

  // ---- NEEDS ATTENTION (08 §5.2) -----------------------------------------------

  Column {
    width: parent.width
    visible: !!root.model && root.model.available && root.model.attention.length > 0
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "NEEDS ATTENTION"
      value: root.model ? String(root.model.attention.length) : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    Repeater {
      id: attentionRepeater
      model: root.model ? root.model.attention : []

      delegate: CursorSurface {
        id: attentionRow
        required property var modelData
        required property int index

        width: parent.width
        // A block, not a two-line row: `rowPaddingX` would add 12 units of chrome to
        // each of three items in the one band that has to stay above the fold.
        implicitHeight: attentionBody.implicitHeight + Style.space(6)
        hasCursor: root.has("posture-attention", attentionRow.index)
        foreground: root.col("fg")

        onHasCursorChanged: if (hasCursor && root.panel) root.panel.ensureCursorVisible(this)

        PostureCheckBlock {
          id: attentionBody
          anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
          check: attentionRow.modelData
          expanded: true
          panel: root.panel
          resolvedFamily: root.rf
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
          onPositionChanged: function(mouse) {
            if (gate.moved(this, mouse) && root.panel) root.panel.hoverCursor("posture-attention", attentionRow.index)
          }
        }
      }
    }

    // Copy actions are their own horizontal section, the `trust-actions` idiom, so
    // every command the report printed is reachable with `l` and Enter and none is
    // pointer-only. OmaSafe never runs one.
    ActionRow {
      width: parent.width
      visible: root.copyActions().length > 0
      actions: {
        var out = []
        var list = root.copyActions()
        for (var i = 0; i < list.length; i++)
          out.push({ label: list[i].label, enabled: true, tooltip: list[i].tooltip })
        return out
      }
      cursorIndex: root.panel && root.panel.cursorActive &&
        root.panel.focusSection === "posture-actions" ? root.panel.selectedIndex : -1
      condition: "OmaSafe copies these to the clipboard and never runs them."
      foreground: root.col("fg"); faint: root.col("faint"); dim: root.col("dim")
      locked: root.panel && root.panel.navigationLocked
      fontFamily: root.col("fontFamily")
      onTriggered: function(index) { if (root.panel) root.panel.posturePerformCopy(index) }
      onHovered: function(index, isHovered) {
        if (isHovered && root.panel) root.panel.hoverCursor("posture-actions", index)
      }
    }
  }

  // ---- OBSERVED (08 §5.2) ------------------------------------------------------

  Column {
    width: parent.width
    visible: !!root.model && root.model.available && root.model.groups.length > 0
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "OBSERVED"
      value: {
        if (!root.model) return ""
        var n = 0
        for (var i = 0; i < root.model.groups.length; i++) n += root.model.groups[i].count
        return String(n)
      }
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    // Domain sub-headers are cursor targets in their own right: Enter collapses a
    // domain, which is how a reader with 40 checks gets the tab back to one screen.
    Repeater {
      id: groupRepeater
      model: root.model ? root.model.groups : []

      delegate: Column {
        id: group
        required property var modelData
        required property int index

        width: parent.width
        spacing: Style.space(2)

        CursorSurface {
          id: groupHeader
          width: parent.width
          implicitHeight: groupLabel.implicitHeight + Style.space(8)
          hasCursor: root.has("posture-groups", group.index)
          foreground: root.col("fg")
          onHasCursorChanged: if (hasCursor && root.panel) root.panel.ensureCursorVisible(this)

          Row {
            id: groupLabel
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(8)
            spacing: Style.space(6)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: root.glyph(root.groupCollapsed(group.modelData.domain) ? "open" : "expand")
              color: root.col("dim")
              font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: String(group.modelData.label)
              color: root.col("dimHeader")
              font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
              font.bold: true
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: String(group.modelData.count)
              color: root.col("dim")
              font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onPositionChanged: function(mouse) {
              if (gate.moved(this, mouse) && root.panel) root.panel.hoverCursor("posture-groups", group.index)
            }
            onClicked: root.toggleGroup(group.modelData.domain)
          }
        }

        Repeater {
          id: checkRepeater
          model: root.groupCollapsed(group.modelData.domain) ? [] : group.modelData.checks

          delegate: CursorSurface {
            id: checkRow
            required property var modelData

            // The cursor index is the row's position in the FLATTENED visible list,
            // which is what `sectionCount("posture-checks")` counts. Deriving it here
            // from the same helper keeps the two from drifting apart.
            readonly property int flatIndex: {
              var rows = root.observedRows()
              for (var i = 0; i < rows.length; i++) if (rows[i].id === checkRow.modelData.id) return i
              return -1
            }

            width: parent.width
            implicitHeight: checkBody.implicitHeight + Style.space(6)
            hasCursor: checkRow.flatIndex >= 0 && root.has("posture-checks", checkRow.flatIndex)
            foreground: root.col("fg")
            onHasCursorChanged: if (hasCursor && root.panel) root.panel.ensureCursorVisible(this)

            PostureCheckBlock {
              id: checkBody
              anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
              check: checkRow.modelData
              expanded: root.checkExpanded(checkRow.modelData.id)
              panel: root.panel
              resolvedFamily: root.rf
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton
              onPositionChanged: function(mouse) {
                if (gate.moved(this, mouse) && root.panel && checkRow.flatIndex >= 0)
                  root.panel.hoverCursor("posture-checks", checkRow.flatIndex)
              }
              onClicked: root.toggleCheck(checkRow.modelData.id)
            }
          }
        }
      }
    }
  }

  NoticeRow {
    width: parent.width
    visible: !!root.model && root.model.available && root.model.limitations.length > 0
    reason: "unsupported"
    text: root.model && root.model.limitations.length > 0
      ? "Overall coverage limitations: " + root.model.limitations.join("; ") : ""
    foreground: root.col("fg"); dim: root.col("dim")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }
}
