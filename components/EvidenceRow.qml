import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// One REVIEW ITEMS row (doc 03 §5.2, 02 §2.4/§2.8). Line 1: semantic severity marker
// (blue info glyph for info/low, yellow medium, amber high, red critical) · title
// (body; bold from high). Line 2: `rule_id · path:line`
// (bodySmall) · expand chevron. Expanded: two FactPills (catalog severity, confidence),
// Evidence (WrapAnywhere), Why this rule exists (explanation), What to check
// (review_guidance), and [Open rule] which pushes a cross-view return frame (§13).
CursorSurface {
  id: root

  property string severityGlyph: ""
  property string severityLevel: "unknown"
  property bool titleBold: false
  property string title: ""
  property string subtitle: ""         // rule_id · path:line

  property bool expanded: false
  property string severityWord: ""     // e.g. "low · catalog severity"
  property string confidenceWord: ""   // e.g. "parser-backed"
  property string evidenceText: ""
  property string explanation: ""
  property string reviewGuidance: ""

  property color dim: Color.foreground
  property color urgentColor: Color.urgent
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  readonly property string _sevTip: "Catalog severity: the rule's default severity class. Not a measure of this plugin."
  readonly property string _confTip: "Confidence: evidence quality. Parser-backed = syntax tree; text match only = lexical; no parser = context or lexical build."

  signal toggleRequested()
  signal openRuleRequested()

  width: parent ? parent.width : implicitWidth
  implicitHeight: content.implicitHeight + Style.spacing.rowPaddingX

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(8)
    spacing: Style.space(6)

    // Header: severity glyph · title · subtitle · chevron.
    Item {
      width: parent.width
      height: Math.max(twoLine.implicitHeight, chevron.size)

      SemanticMark {
        id: sevGlyph
        anchors.top: parent.top
        anchors.topMargin: Style.space(1)
        compact: true
        level: root.severityLevel
        labelOverride: root.severityWord
        foreground: root.foreground
        dim: root.dim
        fontFamily: root.fontFamily
        resolvedFamily: root.resolvedFamily
      }

      Column {
        id: twoLine
        anchors.left: sevGlyph.right
        anchors.leftMargin: Style.space(8)
        anchors.right: chevron.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.title
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: root.titleBold
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.subtitle
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }
      }

      PanelActionButton {
        id: chevron
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        iconText: Glyphs.ui_(root.expanded ? "collapse" : "expand", root.resolvedFamily)
        tooltipText: root.expanded ? "Collapse" : "Expand"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.toggleRequested()
      }
    }

    // Expanded body.
    Column {
      width: parent.width
      visible: root.expanded
      leftPadding: Style.space(30)
      spacing: Style.space(6)

      Row {
        spacing: Style.space(6)
        FactPill {
          text: root.severityWord
          tooltipText: root._sevTip
          rowHasCursor: root.hasCursor
          foreground: root.foreground
          dim: root.dim
          fontFamily: root.fontFamily
        }
        FactPill {
          text: root.confidenceWord
          tooltipText: root._confTip
          rowHasCursor: root.hasCursor
          foreground: root.foreground
          dim: root.dim
          fontFamily: root.fontFamily
        }
      }

      Text {
        width: parent.width - parent.leftPadding
        visible: root.evidenceText !== ""
        textFormat: Text.PlainText
        text: "Evidence\n" + root.evidenceText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WrapAnywhere
      }

      Text {
        width: parent.width - parent.leftPadding
        visible: root.explanation !== ""
        textFormat: Text.PlainText
        text: "Why this rule exists\n" + root.explanation
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
      }

      Text {
        width: parent.width - parent.leftPadding
        visible: root.reviewGuidance !== ""
        textFormat: Text.PlainText
        text: "What to check\n" + root.reviewGuidance
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
      }

      Button {
        text: "Open rule"
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        tooltipText: "Open rule"
        onClicked: root.openRuleRequested()
      }
    }
  }
}
