import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs
import "../model/Tiers.js" as Tiers

// Shared health/severity marker. Colour reinforces the printed level and glyph;
// it never carries the meaning alone. `compact` is used in dense rows and graph
// nodes, while `showLabel` is used in summaries and expanded rule sheets.
//
// The tier ladder itself lives in `model/Tiers.js` (doc 02 §2.3, 08 D1) so the
// v0.3.1 charts paint from the same source. This component's public API is
// unchanged; it is the ladder's first consumer, and still the only one that
// renders a tier as a ROW marker.
Item {
  id: root

  property string kind: "severity"       // severity | health | state
  property string level: "unknown"
  property string labelOverride: ""
  property bool compact: false
  property bool showLabel: false
  property bool pulse: false
  property bool pulseInfinite: false

  property color foreground: Color.foreground
  property color dim: Color.foreground
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  readonly property bool darkSurface: Tiers.isDark(Color.background)
  readonly property string normalizedLevel: Tiers.normalize(root.level)
  readonly property color markColor: {
    var tier = Tiers.color(root.normalizedLevel, root.darkSurface)
    return tier === "" ? root.dim : tier
  }
  readonly property string glyphKey: {
    switch (root.normalizedLevel) {
    case "healthy": return "healthy"
    case "critical": return "critical"
    case "high": return "alert"
    case "medium": return "medium"
    case "low":
    case "info": return "info"
    case "incomplete": return "incomplete"
    case "notApplicable": return "not-applicable"
    case "checking": return "in-flight"
    default: return "hollow"
    }
  }
  readonly property string markLabel: {
    if (root.labelOverride !== "") return root.labelOverride
    switch (root.normalizedLevel) {
    case "healthy": return root.kind === "health" ? "No active alerts" : "No local hits"
    case "medium": return "Medium"
    case "high": return "High"
    case "critical": return "Critical"
    case "low": return "Low"
    case "info": return "Info"
    case "checking": return "Checking"
    case "stale": return "Stale result"
    case "incomplete": return "Analysis incomplete"
    case "notApplicable": return "Not applicable"
    default: return "Unavailable"
    }
  }

  implicitWidth: row.implicitWidth
  implicitHeight: Math.max(row.implicitHeight, Style.space(20))

  Row {
    id: row
    spacing: root.showLabel && !root.compact ? Style.space(6) : 0

    Item {
      id: glyphBox
      width: Style.space(20)
      height: Style.space(20)

      BorderSurface {
        id: halo
        anchors.centerIn: parent
        width: Style.space(18)
        height: width
        radius: width / 2
        color: "transparent"
        borderSpec: Border.flat(root.markColor, Style.normalBorderWidth)
        opacity: 0
        visible: root.pulse

        ParallelAnimation {
          running: root.pulse && root.visible
          loops: root.pulseInfinite ? Animation.Infinite : 2
          NumberAnimation { target: halo; property: "scale"; from: 0.9; to: 1.55; duration: 900; easing.type: Easing.OutCubic }
          NumberAnimation { target: halo; property: "opacity"; from: 0.72; to: 0; duration: 900; easing.type: Easing.OutCubic }
        }
      }

      OpticalGlyph {
        anchors.fill: parent
        text: Glyphs.ui_(root.glyphKey, root.resolvedFamily)
        fontFamily: root.fontFamily
        fontSize: Style.font.icon
        color: root.markColor
      }
    }

    Text {
      visible: root.showLabel && !root.compact
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: root.markLabel
      color: root.markColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: ["high", "critical"].indexOf(root.normalizedLevel) >= 0
    }
  }
}
