import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs
import "../model/Labels.js" as Labels

// The 17-glyph capability presence strip (doc 02 §2.7, §2.8, 03 §4.1): one Text of
// 17 positions in the FIXED catalog order, so a glyph at a position means the same
// class on every plugin. A class glyph is drawn where it was observed, `·` at an
// analyzed-but-not-observed position, and a single `–` (never a run) when the plugin
// is not analyzed. A PanelToolTip lists the observed classes with counts on the
// owning row's cursor. No cursor, no colour expression of its own.
Item {
  id: root

  // true once the plugin has a cached analysis; false → the single `–` placeholder.
  property bool analyzed: false
  // { "<class-key>": <occurrence count>, … } — only observed classes are present.
  property var counts: ({})
  // The tooltip fires on the owning row's cursor, passed in by the row.
  property bool rowHasCursor: false

  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  // One fixed-width cell per catalog position, so a glyph sits at the same x on every
  // row and a wide Nerd-Font icon (whose advance is narrower than its ink) can never
  // overlap its neighbour. `·` at an analyzed-but-not-observed position; the single `–`
  // placeholder is rendered separately when the plugin is not analyzed.
  readonly property real cellW: Style.space(11)
  readonly property var _cells: {
    if (!analyzed) return []
    var order = Glyphs.capabilityOrder
    var out = []
    for (var i = 0; i < order.length; i++) {
      var cls = order[i]
      out.push((Number(counts[cls] || 0) > 0) ? Glyphs.cap(cls, resolvedFamily) : "·")
    }
    return out
  }

  // Observed classes, occurrences desc then catalog order, as the tooltip list.
  readonly property string _tooltip: {
    if (!analyzed) return "Not analyzed"
    var order = Glyphs.capabilityOrder
    var seen = []
    for (var i = 0; i < order.length; i++) {
      var cls = order[i]
      var n = Number(counts[cls] || 0)
      if (n > 0) seen.push({ cls: cls, n: n })
    }
    seen.sort(function(a, b) { return b.n - a.n })
    if (seen.length === 0) return "No capabilities observed"
    var parts = []
    for (var j = 0; j < seen.length; j++)
      parts.push(Labels.capability(seen[j].cls) + " " + seen[j].n)
    return "Observed: " + parts.join(" · ")
  }

  implicitWidth: root.analyzed ? (Glyphs.capabilityOrder.length * root.cellW) : dash.implicitWidth
  implicitHeight: dash.implicitHeight

  // Not-analyzed placeholder: a single dash, never a run.
  Text {
    id: dash
    visible: !root.analyzed
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    textFormat: Text.PlainText
    text: "–"
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  // Analyzed: one fixed-width, glyph-centred cell per catalog position.
  Row {
    visible: root.analyzed
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    Repeater {
      model: root._cells
      delegate: Item {
        required property string modelData
        width: root.cellW
        height: dash.implicitHeight
        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: modelData
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }

  PanelToolTip {
    visible: root.rowHasCursor
    text: root._tooltip
    fontFamily: root.fontFamily
  }
}
