import QtQuick
import qs.Commons

Item {
  id: root

  property string level: "unknown"
  property int count: 0
  property color warningColor: "#e5a50a"
  property color criticalColor: Color.urgent
  property color normalColor: Color.foreground
  property color unknownColor: Color.muted

  implicitWidth: Style.space(14)
  implicitHeight: Style.space(14)
  width: implicitWidth
  height: implicitHeight

  readonly property color statusColor: root.level === "critical"
    ? root.criticalColor : (root.level === "warning"
      ? root.warningColor : (root.level === "normal" ? root.normalColor : root.unknownColor))
  // Warning/critical are actionable — fill the indicator so it reads at a glance
  // in a crowded bar. Quiet states stay as a light outline.
  readonly property bool alert: root.level === "critical" || root.level === "warning"
  readonly property string glyph: root.level === "normal" ? "✓"
    : (root.level === "checking" ? "…" : (root.level === "unknown" ? "?"
      : (root.level === "warning" && root.count > 0
        ? (root.count > 9 ? "9+" : String(root.count)) : "!")))

  Rectangle {
    anchors.centerIn: parent
    width: Style.space(13)
    height: width
    radius: width / 2
    color: root.alert ? root.statusColor : "transparent"
    border.width: Math.max(1, Style.space(1))
    border.color: root.statusColor
  }

  Text {
    anchors.centerIn: parent
    anchors.verticalCenterOffset: root.level === "checking" ? -1 : 0
    text: root.glyph
    color: root.alert ? Color.background : root.statusColor
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.bold: true
  }
}
