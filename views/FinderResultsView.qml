import QtQuick
import qs.Commons
import qs.Ui
import "../components"
import "../model/Glyphs.js" as Glyphs
import "../model/ViewModel.js" as ViewModel

// Finder results (doc 03 §8): the matching groups (PLUGINS · CAPABILITIES · RULES ·
// BASELINE V3) drawn with the row grammar, one result section, ≤ 6 rows each. Groups
// with no match are not drawn. The result cursor is a single flat index over the
// groups in order (plugins → classes → rules → baseline); Enter opens the result.
Column {
  id: root

  property var panel: null
  readonly property var vm: panel ? panel.vm : null
  readonly property string rf: Style.font.resolvedFamily
  readonly property var res: (panel && vm) ? ViewModel.search(vm.finder, panel.finderText) : null

  PointerMoveGate { id: gate; referenceItem: root }

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(12)

  function col(name) { return panel ? panel[name] : Color.foreground }
  readonly property int nPlugins: res ? res.plugins.length : 0
  readonly property int nClasses: res ? res.classes.length : 0
  readonly property int nRules: res ? res.rules.length : 0

  function has(i) { return panel && panel.cursorActive && panel.focusSection === "results" && panel.selectedIndex === i }
  function hover(i) { if (panel) panel.hoverCursor("results", i) }

  // Empty state.
  NoticeRow {
    width: parent.width
    visible: root.res && root.res.empty
    reason: "none"
    text: "No plugin, class, rule or baseline id matches \"" + (panel ? panel.finderText : "") + "\"."
    foreground: root.col("fg"); dim: root.col("dim")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }

  // ---- PLUGINS -----------------------------------------------------------------
  Column {
    width: parent.width
    visible: root.nPlugins > 0
    spacing: Style.space(6)
    SectionHeaderRow { text: "PLUGINS"; value: String(root.nPlugins)
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader"); fontFamily: root.col("fontFamily") }
    Repeater {
      model: root.res ? root.res.plugins : []
      delegate: FinderResultRow {
        required property var modelData
        required property int index
        width: parent.width
        line1: modelData.id
        base: 0; idx: index
      }
    }
  }

  // ---- CAPABILITIES ------------------------------------------------------------
  Column {
    width: parent.width
    visible: root.nClasses > 0
    spacing: Style.space(6)
    SectionHeaderRow { text: "CAPABILITIES"; value: String(root.nClasses)
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader"); fontFamily: root.col("fontFamily") }
    Repeater {
      model: root.res ? root.res.classes : []
      delegate: FinderResultRow {
        required property var modelData
        required property int index
        width: parent.width
        glyph: Glyphs.cap(modelData.key, root.rf)
        line1: modelData.key + " · " + modelData.ruleCount + (modelData.ruleCount === 1 ? " rule" : " rules")
          + " · " + modelData.pluginCount + (modelData.pluginCount === 1 ? " plugin" : " plugins")
        base: root.nPlugins; idx: index
      }
    }
  }

  // ---- RULES -------------------------------------------------------------------
  Column {
    width: parent.width
    visible: root.nRules > 0
    spacing: Style.space(6)
    SectionHeaderRow { text: "RULES"; value: String(root.nRules)
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader"); fontFamily: root.col("fontFamily") }
    Repeater {
      model: root.res ? root.res.rules : []
      delegate: FinderResultRow {
        required property var modelData
        required property int index
        width: parent.width
        glyph: Glyphs.cap(modelData.capability, root.rf)
        line1: modelData.title
        line2: modelData.id + " · " + modelData.language + " · " + modelData.severity
        base: root.nPlugins + root.nClasses; idx: index
      }
    }
  }

  // ---- BASELINE V3 -------------------------------------------------------------
  Column {
    width: parent.width
    visible: root.res && root.res.baseline.length > 0
    spacing: Style.space(6)
    SectionHeaderRow { text: "BASELINE V3"; value: String(root.res ? root.res.baseline.length : 0)
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader"); fontFamily: root.col("fontFamily") }
    Repeater {
      model: root.res ? root.res.baseline : []
      delegate: FinderResultRow {
        required property var modelData
        required property int index
        width: parent.width
        glyph: modelData.relationMark
        line1: modelData.externalId
        base: root.nPlugins + root.nClasses + root.nRules; idx: index
      }
    }
  }

  // One finder result row: a CursorSurface with a glyph column, one or two lines and
  // a trailing open chevron, bound to the flat result cursor at base + idx.
  component FinderResultRow: CursorSurface {
    id: rrow
    property string glyph: ""
    property string line1: ""
    property string line2: ""
    property int base: 0
    property int idx: 0
    readonly property int flat: base + idx

    implicitHeight: rrowContent.implicitHeight + Style.spacing.rowPaddingX
    hasCursor: root.has(flat)
    foreground: root.col("fg")
    onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)

    Row {
      id: rrowContent
      anchors.left: parent.left; anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10); anchors.rightMargin: Style.space(8)
      spacing: Style.space(8)

      Text {
        width: Style.space(22)
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: rrow.glyph
        horizontalAlignment: Text.AlignHCenter
        color: root.col("fg")
        font.family: root.col("fontFamily"); font.pixelSize: Style.font.icon
      }
      Column {
        width: parent.width - Style.space(22) - openChevron.width - parent.spacing * 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: rrow.line1
          color: root.col("fg")
          font.family: root.col("fontFamily"); font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          visible: rrow.line2 !== ""
          textFormat: Text.PlainText
          text: rrow.line2
          color: root.col("dim")
          font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }
      }
      PanelActionButton {
        id: openChevron
        anchors.verticalCenter: parent.verticalCenter
        iconText: Glyphs.ui_("open", root.rf)
        tooltipText: "Open"
        foreground: root.col("fg")
        fontFamily: root.col("fontFamily")
        onClicked: if (panel) panel.openFinderResult(rrow.flat)
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) root.hover(rrow.flat) }
      onClicked: if (panel) panel.openFinderResult(rrow.flat)
    }
  }
}
