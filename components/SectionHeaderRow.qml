import QtQuick
import qs.Commons
import qs.Ui

// A section header: a PanelSeparator over a Row of the kit PanelSectionHeader and,
// when present, the section's own count or state in the header's right slot (doc
// 03 §3, 02 §2.1). The right value is never a verdict — it is a count (ALERTS | 3),
// an authority (MARKETPLACE CLAIM | CATALOG …) or a state; TRUST BASELINE carries
// no right value at all (03 §5.4), so `value` is left empty there.
//
// Colours are passed in, never computed here (no colour expression, T1.2). The
// kit PanelSectionHeader keeps its own colour for the header word (doc 02 §2.3);
// the right value is OmaSafe's own Text and takes `valueColor` (dimHeader).
Column {
  id: root

  property string text: ""
  property string value: ""
  property color foreground: Color.foreground
  property color valueColor: Color.foreground
  property string fontFamily: Style.font.family

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(6)

  PanelSeparator { foreground: root.foreground }

  Row {
    width: parent.width

    PanelSectionHeader {
      text: root.text
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Item {
      width: Math.max(0, parent.width - parent.children[0].width - valueText.implicitWidth)
      height: 1
    }

    Text {
      id: valueText
      textFormat: Text.PlainText
      visible: root.value !== ""
      text: root.value
      color: root.valueColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
