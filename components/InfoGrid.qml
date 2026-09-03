import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// A two-column key:value grid (doc 02 §2.2, T1.4): a fixed label column over a
// value column that fills the rest, so a 64-hex digest wraps per character instead
// of clipping (eliding a hash is forbidden, GR6). `rows` is an array of
// { label, value, mono, copyable } — `mono` values wrap WrapAnywhere (hashes),
// others WordWrap; a `copyable` value gets a copy PanelActionButton and emits
// copyRequested(value). Colours are passed in, never computed here (T1.2).
Column {
  id: root

  // [{ label: string, value: string, mono: bool, copyable: bool }]
  property var rows: []
  property real labelWidth: Style.space(72)
  property color foreground: Color.foreground
  property color labelColor: Color.foreground
  property string fontFamily: Style.font.family
  readonly property real columnSpacing: Style.space(20)

  signal copyRequested(string value)

  width: parent ? parent.width : implicitWidth
  spacing: Style.spacing.labelGap

  Repeater {
    model: root.rows

    delegate: Row {
      id: line
      required property var modelData
      width: root.width
      spacing: root.columnSpacing

      Text {
        id: labelText
        width: root.labelWidth
        textFormat: Text.PlainText
        text: String(line.modelData.label || "")
        wrapMode: Text.WordWrap
        color: root.labelColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        id: valueText
        width: root.width - root.labelWidth - root.columnSpacing
          - (copyButton.visible ? copyButton.width + line.spacing : 0)
        textFormat: Text.PlainText
        text: String(line.modelData.value || "")
        wrapMode: line.modelData.mono === true ? Text.WrapAnywhere : Text.WordWrap
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      PanelActionButton {
        id: copyButton
        visible: line.modelData.copyable === true
        iconText: Glyphs.ui_("copy", Style.font.resolvedFamily)
        tooltipText: "Copy full digest"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.copyRequested(String(line.modelData.value || ""))
      }
    }
  }
}
