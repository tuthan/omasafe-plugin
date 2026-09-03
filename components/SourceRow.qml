import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// One SOURCES row (doc 03 §4.1/§4.4): an empty glyph column, a label line and an
// optional dim second line, plus at most one trailing control — a bordered Button
// (`actionText`, e.g. Install) or a PanelActionButton (`iconAction`, e.g. rescan) —
// and an optional expand chevron for the overrides row. Presentational; the view owns
// the cursor and the expanded content.
CursorSurface {
  id: root

  property string label: ""
  property string sublabel: ""         // second line (dim), "" hides it
  property bool expandable: false
  property bool expanded: false

  property string actionText: ""       // bordered Button when non-empty
  property bool actionEnabled: true
  property string actionTooltip: ""
  property string iconAction: ""       // PanelActionButton glyph when non-empty
  property string iconTooltip: ""

  property color dim: Color.foreground
  property color faint: Color.foreground
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  signal actionRequested()
  signal iconActionRequested()
  signal toggleRequested()

  width: parent ? parent.width : implicitWidth
  implicitHeight: rowItem.implicitHeight + Style.spacing.rowPaddingX

  Item {
    id: rowItem
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(8)
    implicitHeight: Math.max(labels.implicitHeight, trailing.implicitHeight)

    Column {
      id: labels
      anchors.left: parent.left
      anchors.leftMargin: Style.space(22) + Style.space(8)
      anchors.right: trailing.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(1)

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: root.label
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }
      Text {
        width: parent.width
        visible: root.sublabel !== ""
        textFormat: Text.PlainText
        text: root.sublabel
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }

    Row {
      id: trailing
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(6)

      Button {
        visible: root.actionText !== ""
        text: root.actionText
        bordered: true
        enabled: root.actionEnabled
        foreground: root.actionEnabled ? root.foreground : root.faint
        fontFamily: root.fontFamily
        tooltipText: root.actionTooltip
        onClicked: root.actionRequested()
      }

      PanelActionButton {
        visible: root.iconAction !== ""
        iconText: root.iconAction
        tooltipText: root.iconTooltip
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.iconActionRequested()
      }

      PanelActionButton {
        visible: root.expandable
        iconText: Glyphs.ui_(root.expanded ? "collapse" : "expand", root.resolvedFamily)
        tooltipText: root.expanded ? "Collapse" : "Expand"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.toggleRequested()
      }
    }
  }
}
