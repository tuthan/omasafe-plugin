import QtQuick
import qs.Commons
import qs.Ui

// InspectorStrip — the fixed four-line inspector under the Flow body (doc 04 T3.6,
// §10.2). A PanelSeparator, a title row with one read-only navigation Button, and up
// to three fact lines describing whichever node/cell/row the cursor is on. The
// keyboard path is this strip, never a floating tooltip (Little Snitch pattern). The
// Button is always read-only navigation — no mutation ever opens from the graph.
Column {
  id: strip

  property var facts: ({ title: "", lines: [], action: "", actionEnabled: false })
  property bool actionHasCursor: false
  property string fontFamily: Style.font.family
  property color fg: Color.foreground
  property color dim: fg                 // root passes dimStep(0.33) (02 §2.3)

  signal actionClicked()

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(1)

  PanelSeparator { foreground: strip.fg }

  Row {
    width: parent.width
    spacing: Style.space(8)
    Text {
      width: parent.width - action.width - parent.spacing
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: strip.facts.title || ""
      elide: Text.ElideMiddle
      color: strip.fg
      font.family: strip.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
    }
    Button {
      id: action
      visible: (strip.facts.action || "") !== ""
      text: strip.facts.action || ""
      bordered: true
      enabled: strip.facts.actionEnabled === true
      hasCursor: strip.actionHasCursor
      foreground: strip.fg
      fontFamily: strip.fontFamily
      fontSize: Style.font.bodySmall
      onClicked: strip.actionClicked()
    }
  }

  Repeater {
    model: strip.facts.lines || []
    delegate: Text {
      required property string modelData
      width: strip.width
      textFormat: Text.PlainText
      text: modelData
      elide: Text.ElideRight
      color: strip.dim
      font.family: strip.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }
}
