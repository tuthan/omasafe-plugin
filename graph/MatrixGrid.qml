import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs
import "../model/Labels.js" as Labels

// MatrixGrid — the Matrix lens (doc 04 §9.5, T3.10): plugins × capability classes as a
// grid of occurrence digits. `·` = analyzed, none observed; `–` = not analyzed (never
// `0`). Columns are in catalog order (a column means the same class on every row);
// header glyphs carry the class name in a PanelToolTip. Horizontal scrolling lives
// only inside this grid's own Flickable — the panel body never scrolls sideways.
Item {
  id: root

  property var panel: null
  property var model: ({ columns: [], rows: [] })   // panel.flowMatrixModel()
  property int cursorRow: -1                          // panel.selectedIndex when focused
  property int cursorCol: -1                          // panel.flowMatrixCol (-1 = row label)
  property bool focused: false

  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily
  property color fg: Color.foreground
  property color dimColor: fg
  property color dimHeaderColor: fg
  property color urgentColor: Color.urgent

  readonly property real rowH: Style.spacing.popupRowHeight
  readonly property real labelW: Style.space(120)
  readonly property real cellW: Style.space(44)

  implicitHeight: (root.model.rows.length + 1) * rowH

  Flickable {
    id: flick
    anchors.fill: parent
    contentWidth: root.labelW + root.model.columns.length * root.cellW
    contentHeight: height
    clip: true
    interactive: contentWidth > width
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds

    // header row of class glyphs
    Row {
      id: header
      x: root.labelW
      height: root.rowH
      Repeater {
        model: root.model.columns
        delegate: Item {
          required property var modelData
          width: root.cellW; height: root.rowH
          // Class glyph header; the inspector names the class in full (the kit hover
          // tooltip is not used here — the CursorSurface contract forbids reading the
          // pointer-inside flag, and a header tooltip is not worth a gate exception).
          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: Glyphs.cap(modelData, root.resolvedFamily)
            color: root.dimHeaderColor
            font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
          }
        }
      }
    }

    // grid rows
    Column {
      y: root.rowH
      Repeater {
        model: root.model.rows
        delegate: Row {
          id: gridRow
          required property var modelData
          required property int index
          CursorSurface {
            width: root.labelW; height: root.rowH
            foreground: root.fg
            hasCursor: root.focused && root.cursorRow === gridRow.index && root.cursorCol < 0
            Text {
              anchors { left: parent.left; leftMargin: Style.space(6); right: parent.right
                        rightMargin: Style.space(6); verticalCenter: parent.verticalCenter }
              textFormat: Text.PlainText
              text: gridRow.modelData.id
              elide: Text.ElideMiddle
              color: root.fg
              font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
              font.bold: gridRow.modelData.bold === true
            }
            MouseArea {
              anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton
              onEntered: if (root.panel) { root.panel.hoverCursor("matrix", gridRow.index); root.panel.flowMatrixCol = -1 }
              onClicked: if (root.panel) { root.panel.selectedIndex = gridRow.index; root.panel.flowMatrixCol = -1; root.panel.flowMatrixActivate() }
            }
          }
          Repeater {
            model: gridRow.modelData.cells
            delegate: CursorSurface {
              required property var modelData
              required property int index
              width: root.cellW; height: root.rowH
              foreground: root.fg
              hasCursor: root.focused && root.cursorRow === gridRow.index && root.cursorCol === index
              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: modelData          // digit · "·" · "–"
                color: root.dimHeaderColor
                font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
              }
              MouseArea {
                anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton
                onEntered: if (root.panel) { root.panel.hoverCursor("matrix", gridRow.index); root.panel.flowMatrixCol = index }
                onClicked: if (root.panel) { root.panel.selectedIndex = gridRow.index; root.panel.flowMatrixCol = index; root.panel.flowMatrixActivate() }
              }
            }
          }
        }
      }
    }
  }
}
