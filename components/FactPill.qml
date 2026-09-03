import QtQuick
import qs.Commons
import qs.Ui

// A non-interactive fact pill (doc 02 §2.5, 03 §5.2): the kit's own PanelHero
// detail-pill pattern (Ui/PanelHero.qml:67–87) — a BorderSurface with
// Border.controlSpec("normal"), a bodySmall dim Text, and a PanelToolTip shown
// on the parent row's cursor. It carries the severity and confidence WORDS of an
// expanded review item; it is never a disabled Button (which would inherit
// disabled chrome and need a cursor-skip). The pill has no cursor of its own.
BorderSurface {
  id: root

  property string text: ""
  property string tooltipText: ""
  // The pill's tooltip fires on the owning row's cursor, passed in by the row.
  property bool rowHasCursor: false

  property color foreground: Color.foreground
  property color dim: Color.foreground
  property string fontFamily: Style.font.family

  implicitWidth: pillText.implicitWidth + Style.space(10)
  implicitHeight: pillText.implicitHeight + Style.space(4)
  color: "transparent"
  borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
  radius: Style.cornerRadius

  Text {
    id: pillText
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: root.text
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  PanelToolTip {
    visible: root.tooltipText !== "" && root.rowHasCursor
    text: root.tooltipText
    fontFamily: root.fontFamily
  }
}
