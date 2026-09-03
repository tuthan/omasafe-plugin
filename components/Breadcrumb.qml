import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// The depth breadcrumb (doc 03 §8, §13): a leading back PanelActionButton 󰅁 and a
// bodySmall label. At depth 1 it renders the way back only (`󰅁 All plugins`) — the
// hero already names the plugin; at depth ≥ 2 the caller passes the full `›` path.
// Shown by the panel only at depth ≥ 1.
Row {
  id: root

  property string label: "All plugins"   // way-back label (depth 1) or full › path
  property color foreground: Color.foreground
  property color dim: Color.foreground
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  signal backRequested()

  spacing: Style.space(4)
  leftPadding: Style.space(10)

  PanelActionButton {
    anchors.verticalCenter: parent.verticalCenter
    iconText: Glyphs.ui_("back", root.resolvedFamily)
    tooltipText: "All plugins (h)"
    foreground: root.foreground
    fontFamily: root.fontFamily
    onClicked: root.backRequested()
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    textFormat: Text.PlainText
    text: root.label
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    elide: Text.ElideMiddle
  }
}
