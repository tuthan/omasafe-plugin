import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// One scan-alert row (doc 03 §4.1): glyph `󰀦` (fg; urgent only for critical/error
// severity), line 1 = the alert-kind label (body, bold), line 2 = `<id> · reported
// <relative>` (+ ` · plugin changed`) in bodySmall dim, trailing open chevron. A
// pseudo alert (marketplace / trust-history / bar id) has no open action. Presentational:
// the view owns the cursor and emits nothing here beyond openRequested.
CursorSurface {
  id: root

  property string kindLabel: ""
  property string subtitle: ""
  property string severity: ""
  property string severityLevel: "unknown"
  property bool urgent: false
  property bool pseudo: false

  property color dim: Color.foreground
  property color urgentColor: Color.urgent
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  signal openRequested()

  width: parent ? parent.width : implicitWidth
  implicitHeight: content.implicitHeight + Style.spacing.rowPaddingX

  Row {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(8)
    spacing: Style.space(8)

    SemanticMark {
      id: glyph
      anchors.verticalCenter: parent.verticalCenter
      compact: true
      level: root.severityLevel
      labelOverride: root.severity !== "" ? root.severity : "Alert"
      foreground: root.foreground
      dim: root.dim
      fontFamily: root.fontFamily
      resolvedFamily: root.resolvedFamily
    }

    Column {
      width: parent.width - glyph.width - parent.spacing
        - (openButton.visible ? openButton.width + parent.spacing : 0)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(1)

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: root.kindLabel
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
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
      id: openButton
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.pseudo
      width: visible ? size : 0
      iconText: Glyphs.ui_("open", root.resolvedFamily)
      tooltipText: "Open plugin"
      foreground: root.foreground
      fontFamily: root.fontFamily
      onClicked: root.openRequested()
    }
  }
}
