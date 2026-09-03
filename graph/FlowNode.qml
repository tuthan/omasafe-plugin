import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs
import "../components"

// FlowNode — one node row of the Trust Flow graph (doc 04 T3.3, §10.2). A
// CursorSurface (never reads the pointer-inside flag for paint — the kit contract) plus an
// OpticalGlyph, an eliding label, a count, and a MouseArea for hover + click only.
// The column MouseArea in TrustFlow owns the wheel; TrustFlow owns the one hover
// tooltip. Nothing here encodes a verdict: every state is a word, a glyph shape or a
// weight. Glyphs resolve through model/Glyphs.js with the live family so the ASCII
// floor is honoured; no literal codepoints, no font.pixelSize literal.
CursorSurface {
  id: node

  required property var modelData          // {key,label,count,glyphKey,layer,hollow,analyzing,bold,urgent,faint,...}
  required property int index
  property int column: 0
  property bool open: true                 // false in a rail: glyph + count only
  property var gate: null                  // PointerMoveGate owned by TrustFlow
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily
  property color fg: Color.foreground
  property color urgentColor: Color.urgent
  property color dimColor: fg              // root passes dim / faint / dimHeader from dimStep (02 §2.3)
  property color faintColor: fg
  property color dimHeaderColor: fg
  property bool faint: modelData.faint === true

  // The glyph slot: urgent (block) and analyzing and hollow override the layer glyph;
  // CAPABILITIES + class-level BASELINE rows carry a class glyph; RULES / BASELINE
  // rails carry their rail glyph; PLUGINS and open RULES carry none.
  readonly property string glyphText: {
    if (modelData.urgent) return Glyphs.ui_("block", resolvedFamily)
    if (modelData.analyzing) return Glyphs.ui_("in-flight", resolvedFamily)
    if (modelData.hollow) return Glyphs.ui_("hollow", resolvedFamily)
    if (modelData.glyphKey && modelData.glyphKey !== "") return Glyphs.cap(modelData.glyphKey, resolvedFamily)
    if (!node.open) {
      if (modelData.layer === "rules") return Glyphs.ui_("rule", resolvedFamily)
      if (modelData.layer === "baseline") return Glyphs.ui_("catalog", resolvedFamily)
    }
    return ""
  }
  readonly property color labelColor: faint ? faintColor : (modelData.hollow ? dimColor : fg)

  signal cursorRequested(int column, int index)
  signal activated(int column, int index)
  signal hoverEntered(int column, int index)
  signal hoverExited(int column, int index)

  height: Style.spacing.popupRowHeight
  foreground: fg

  OpticalGlyph {
    id: glyph
    visible: node.glyphText !== ""
    anchors { left: parent.left; leftMargin: Style.space(10); verticalCenter: parent.verticalCenter }
    width: visible ? Style.space(22) : 0
    height: parent.height
    text: node.glyphText
    fontFamily: node.fontFamily
    fontSize: Style.font.bodySmall
    color: node.modelData.urgent ? node.urgentColor : node.labelColor
  }
  Text {
    visible: node.open
    anchors {
      left: glyph.visible ? glyph.right : parent.left
      leftMargin: glyph.visible ? Style.space(6) : Style.space(10)
      right: riskMark.left; rightMargin: Style.space(6)
      verticalCenter: parent.verticalCenter
    }
    textFormat: Text.PlainText
    text: node.modelData.label
    elide: Text.ElideMiddle
    color: node.labelColor
    font.family: node.fontFamily
    font.pixelSize: Style.font.bodySmall
    font.bold: node.modelData.bold === true
  }
  SemanticMark {
    id: riskMark
    anchors.right: count.left
    anchors.rightMargin: Style.space(4)
    anchors.verticalCenter: parent.verticalCenter
    width: visible ? implicitWidth : 0
    visible: node.modelData.riskLevel !== undefined &&
      ["unknown", "incomplete", "checking"].indexOf(String(node.modelData.riskLevel || "")) < 0
    compact: true
    kind: node.modelData.layer === "plugins" ? "health" : "severity"
    level: String(node.modelData.riskLevel || "unknown")
    pulse: (node.hasCursor || node.current) && ["medium", "high", "critical"].indexOf(String(node.modelData.riskLevel || "")) >= 0
    pulseInfinite: (node.hasCursor || node.current) && String(node.modelData.riskLevel || "") === "critical"
    foreground: node.fg
    dim: node.dimColor
    fontFamily: node.fontFamily
    resolvedFamily: node.resolvedFamily
  }
  Text {
    id: count
    anchors { right: parent.right; rightMargin: Style.space(8); verticalCenter: parent.verticalCenter }
    textFormat: Text.PlainText
    text: node.modelData.count           // "29" · "–" · "…" · "≈" (baseline mark) · "unavailable"
    color: node.dimHeaderColor           // a count is a data floor, never a verdict colour
    font.family: node.fontFamily
    font.pixelSize: Style.font.bodySmall
  }
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPositionChanged: function(mouse) {
      if (node.gate && node.gate.moved(node, mouse)) node.cursorRequested(node.column, node.index)
    }
    onEntered: node.hoverEntered(node.column, node.index)
    onExited: node.hoverExited(node.column, node.index)
    onClicked: node.activated(node.column, node.index)
    // no onWheel here: the column MouseArea in TrustFlow owns the wheel
    // no PanelToolTip here: TrustFlow owns the single hover tooltip
  }
}
