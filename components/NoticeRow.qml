import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// A reasoned empty/limitation slot: a CursorSurface (no cursor) holding one Text
// (Style.font.body, WordWrap), the tailscale not-installed idiom
// (tailscale/Panel.qml:511–529). `reason` selects ONLY the glyph and paint (doc
// 03 §9): dim for everything except `lexical-only` (fg, with the alert glyph) and
// `unavailable` when it carries a CLI failure (urgent). The text always carries the
// meaning on its own; a slot is never blank, 0 or n/a — the caller supplies the
// §9 catalogue string in `text`.
CursorSurface {
  id: root

  // loading · none · unavailable · unsupported · stale · lexical-only
  property string reason: "none"
  property string text: ""
  // true when an `unavailable` notice is a CLI failure line (urgent, one of P9's
  // allowlisted uses); a plain `unavailable` stays dim.
  property bool cliFailure: false

  // `foreground` is inherited from CursorSurface; do not redeclare it. dim/urgent
  // are ours (the CursorSurface base has no such roles).
  property color dim: Color.foreground
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  readonly property bool _lexical: reason === "lexical-only"
  readonly property string _glyph: _lexical ? Glyphs.ui_("alert", resolvedFamily) : ""
  readonly property color _paint: _lexical
    ? root.foreground
    : (reason === "unavailable" && cliFailure ? root.urgent : root.dim)

  width: parent ? parent.width : implicitWidth
  implicitHeight: label.implicitHeight + Style.spacing.rowPaddingX

  Row {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(8)
    spacing: Style.space(8)

    Text {
      id: glyphText
      textFormat: Text.PlainText
      visible: root._glyph !== ""
      width: visible ? Style.space(22) : 0
      text: root._glyph
      horizontalAlignment: Text.AlignHCenter
      color: root._paint
      font.family: root.fontFamily
      font.pixelSize: Style.font.icon
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      id: label
      width: parent.width - (glyphText.visible ? glyphText.width + parent.spacing : 0)
      textFormat: Text.PlainText
      text: root.text
      wrapMode: Text.WordWrap
      color: root._paint
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
