import QtQuick
import qs.Commons
import qs.Ui

// A row of mutating-action buttons (doc 02 §2.2, 03 §5.1/§5.5). Eligible verbs are
// bordered Buttons; an ineligible verb stays VISIBLE, dim (foreground: faint), and
// the unmet condition is printed once as a dim caption Text under the row (the tooltip
// is only a duplicate for pointer users). A horizontal cursor section: the view drives
// `cursorIndex` and listens on `hovered` to sync the mouse.
Column {
  id: root

  // [{ label, enabled, tooltip }]
  property var actions: []
  property int cursorIndex: -1
  property string condition: ""

  property color foreground: Color.foreground
  property color faint: Color.foreground
  property color dim: Color.foreground
  property bool locked: false          // navigationLocked → all disabled
  property string fontFamily: Style.font.family

  signal triggered(int index)
  signal hovered(int index, bool isHovered)

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(4)
  leftPadding: Style.space(30)

  Row {
    spacing: Style.space(6)

    Repeater {
      model: root.actions

      delegate: Button {
        required property var modelData
        required property int index
        text: String(modelData.label || "")
        bordered: true
        enabled: modelData.enabled === true && !root.locked
        hasCursor: root.cursorIndex === index
        foreground: (modelData.enabled === true) ? root.foreground : root.faint
        fontFamily: root.fontFamily
        tooltipText: String(modelData.tooltip || "")
        onClicked: root.triggered(index)
        onHovered: function(h) { root.hovered(index, h) }
      }
    }
  }

  Text {
    width: parent.width - parent.leftPadding
    visible: root.condition !== ""
    textFormat: Text.PlainText
    text: root.condition
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
