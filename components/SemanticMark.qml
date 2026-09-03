import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// Shared health/severity marker. Colour reinforces the printed level and glyph;
// it never carries the meaning alone. `compact` is used in dense rows and graph
// nodes, while `showLabel` is used in summaries and expanded rule sheets.
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

  readonly property bool darkSurface: {
    var b = Color.background
    return (Number(b.r) * 0.2126 + Number(b.g) * 0.7152 + Number(b.b) * 0.0722) < 0.5
  }
  readonly property string normalizedLevel: {
    var v = String(root.level || "").toLowerCase()
    if (v === "error" || v === "blocked") return "critical"
    if (v === "warning") return "medium"
    if (v === "normal" || v === "ok" || v === "pass") return "healthy"
    if (v === "checking" || v === "loading") return "checking"
    if (v === "not analyzed" || v === "not-analyzed" || v === "incomplete") return "incomplete"
    if (["healthy", "critical", "high", "medium", "low", "info", "stale", "unknown"].indexOf(v) >= 0) return v
    return "unknown"
  }
  readonly property color markColor: {
    var dark = root.darkSurface
    switch (root.normalizedLevel) {
    case "healthy": return dark ? "#72d394" : "#19733d"
    case "medium": return dark ? "#f2d16b" : "#8a6200"
    case "high": return dark ? "#ffb064" : "#a34f00"
    case "critical": return dark ? "#ff7777" : "#b42318"
    case "low": return dark ? "#9bc8ff" : "#2b65a3"
    case "info": return dark ? "#9bc8ff" : "#2b65a3"
    default: return root.dim
    }
  }
  readonly property string glyphKey: {
    switch (root.normalizedLevel) {
    case "healthy": return "healthy"
    case "critical": return "critical"
    case "high": return "alert"
    case "medium": return "medium"
    case "low":
    case "info": return "info"
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
