import QtQuick
import qs.Commons
import qs.Ui
import "model/Glyphs.js" as Glyphs

// The OmaSafe shield glyph, shared by the bar (doc 03 §2) and the hero (03 §3).
// Its SHAPE, not its colour, says whether a current scan result exists: the filled
// shield 󰒃 is drawn only when `filled`; the outline shield 󰒙 is drawn for ready,
// a missing/incompatible CLI, and every unavailable state (with or without an
// earlier result). Failure is encoded by shape, never by dim alone (a filled-but-
// dim shield is not reliably distinguishable from a quiet shield on light themes).
//
// `checking` shows a small rotating rescan glyph in the badge slot (900 ms, only
// while opened && checking); `badge` shows the urgent circle — the only urgent paint
// in the bar. The badge copies the TailscaleIcon.qml:46–64 BorderSurface but sizes
// its ink from the icon size, never the literal at TailscaleIcon.qml:61 (doc 02 §4).
Item {
  id: root

  property real iconSize: Style.font.icon
  property bool filled: false
  property bool dim: false
  property bool checking: false
  property bool badge: false
  property bool opened: false

  property color foreground: Color.foreground
  property color dimColor: Color.foreground
  property color urgent: Color.urgent
  property color badgeBorder: Color.popups.background
  property color badgeText: Color.background
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  implicitWidth: iconSize
  implicitHeight: iconSize
  width: iconSize
  height: iconSize

  OpticalGlyph {
    anchors.fill: parent
    text: root.filled
      ? Glyphs.ui_("shield-filled", root.resolvedFamily)
      : Glyphs.ui_("shield-outline", root.resolvedFamily)
    fontSize: root.iconSize
    color: root.dim ? root.dimColor : root.foreground
    fontFamily: root.fontFamily
  }

  // Rotating in-flight glyph in the badge slot (bottom-right); it never swaps the
  // shield out. Runs only while the panel is open and a scan is in flight.
  OpticalGlyph {
    id: spinner
    visible: root.checking
    width: Math.round(root.iconSize * 0.55)
    height: width
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    text: Glyphs.ui_("rescan", root.resolvedFamily)
    fontSize: root.iconSize * 0.55
    color: root.foreground
    fontFamily: root.fontFamily

    RotationAnimation on rotation {
      from: 0
      to: 360
      duration: 900
      loops: Animation.Infinite
      running: root.opened && root.checking
    }
  }

  BorderSurface {
    id: badgeCircle
    visible: root.badge && !root.checking
    width: Math.round(root.iconSize * 0.5)
    height: width
    radius: width / 2
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    color: root.urgent
    borderSpec: Border.flat(root.badgeBorder, Style.normalBorderWidth)

    OpticalGlyph {
      anchors.fill: parent
      text: "!"
      fontSize: root.iconSize * 0.5
      color: root.badgeText
      fontFamily: root.fontFamily
    }
  }
}
