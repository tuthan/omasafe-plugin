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

  // Both panel sizes use the same table contract as the other views: the plugin
  // label starts at the left edge and class cells share the remaining width. In
  // compact mode a full 17-class catalog can therefore scroll horizontally; when
  // the columns fit, they stretch to fill the viewport instead of leaving a
  // centered island of cells. Expanded mode only increases the label/row rhythm.
  readonly property bool expanded: !!(root.panel && root.panel.expanded)
  // Keep the first header cell present in every Matrix state. The old
  // expanded-only label made a compact all-plugin table look like an unlabeled
  // list, especially before the first analysis produced any capability columns.
  // Use the same full vocabulary as the open TrustFlow columns; this is a data
  // column rather than a narrow graph rail, so it does not need a compact alias.
  readonly property bool pluginScope: !!(root.panel && root.panel.flowScope
    && root.panel.flowScope.kind === "plugin")
  readonly property string pluginHeaderFull: root.pluginScope ? "PLUGIN" : "PLUGINS"
  readonly property int columnCount: root.model.columns ? root.model.columns.length : 0
  readonly property real rowH: root.expanded ? Style.space(32) : Style.spacing.popupRowHeight
  readonly property real headerH: root.expanded ? Style.space(40) : rowH
  readonly property real labelW: root.expanded
    ? Math.max(Style.space(140), Math.min(Style.space(220), root.width * 0.2))
    : Style.space(120)
  readonly property real cellW: {
    var n = Math.max(1, root.columnCount)
    var available = Math.max(0, root.width - root.labelW)
    return Math.max(Style.space(44), available / n)
  }
  readonly property real tableW: root.labelW + root.columnCount * root.cellW
  // Keep Matrix rows aligned with the panel's other tables. The Flickable still
  // owns horizontal overflow when the minimum cell width exceeds the viewport.
  readonly property real tableX: 0

  implicitHeight: root.headerH + root.model.rows.length * root.rowH

  Flickable {
    id: flick
    anchors.fill: parent
    contentWidth: Math.max(width, root.tableW)
    contentHeight: root.implicitHeight
    clip: true
    interactive: root.tableW > width
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds

    // header row of class glyphs
    Text {
      id: pluginHeader
      visible: true
      x: root.tableX
      width: root.labelW
      height: root.headerH
      verticalAlignment: Text.AlignVCenter
      textFormat: Text.PlainText
      text: root.pluginHeaderFull
      color: root.dimHeaderColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      elide: Text.ElideRight
    }

    Row {
      id: header
      x: root.tableX + root.labelW
      height: root.headerH
      Repeater {
        model: root.model.columns
        delegate: Item {
          required property var modelData
          width: root.cellW; height: root.headerH
          // Class glyph header; the inspector names the class in full (the kit hover
          // tooltip is not used here — the CursorSurface contract forbids reading the
          // pointer-inside flag, and a header tooltip is not worth a gate exception).
          Text {
            id: glyph
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.expanded ? -Style.space(7) : 0
            textFormat: Text.PlainText
            text: Glyphs.cap(modelData, root.resolvedFamily)
            color: root.dimHeaderColor
            font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
          }
          Text {
            visible: root.expanded
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.space(3)
            textFormat: Text.PlainText
            text: Glyphs.capability[modelData]
              ? Glyphs.capability[modelData].ascii : Labels.capability(modelData)
            color: root.dimColor
            font.family: root.fontFamily; font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
      }
    }

    PanelSeparator {
      visible: root.expanded
      x: root.tableX
      y: root.headerH - 1
      width: root.tableW
      foreground: root.dimColor
    }

    // grid rows
    Column {
      x: root.tableX
      y: root.headerH
      Repeater {
        model: root.model.rows
        delegate: Row {
          id: gridRow
          required property var modelData
          required property int index
          width: root.tableW
          height: root.rowH
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
              font.family: root.fontFamily
              font.pixelSize: root.expanded ? Style.font.body : Style.font.bodySmall
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
                font.family: root.fontFamily
                font.pixelSize: root.expanded ? Style.font.body : Style.font.bodySmall
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
