import QtQuick
import qs.Commons
import qs.Ui

// One file-reference edge (doc 03 §5.3): `<from> ─▶ <target>` with the target's
// coverage state appended when it is not `analyzed`, in bodySmall dim. A PanelToolTip
// carries `<from_path>:<line>`. A cursor target under the collapsed COVERAGE
// `<n> file references` sub-row. Presentational.
CursorSurface {
  id: root

  property string text: ""             // "BarWidget.qml ─▶ Model.js · nothing observed"
  property string tooltipText: ""      // "<from_path>:<line>"

  property color dim: Color.foreground
  property string fontFamily: Style.font.family

  width: parent ? parent.width : implicitWidth
  implicitHeight: label.implicitHeight + Style.spacing.rowPaddingX

  Text {
    id: label
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(30)
    anchors.rightMargin: Style.space(8)
    textFormat: Text.PlainText
    text: root.text
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  PanelToolTip {
    visible: root.hasCursor && root.tooltipText !== ""
    text: root.tooltipText
    fontFamily: root.fontFamily
  }
}
