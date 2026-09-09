import QtQuick
import qs.Commons
import qs.Ui
import "../model/Tiers.js" as Tiers

// A fixed-order unit chart: one cell per item, position carries identity (doc 02
// §2.4 CH2, CH8). This is the idiom `CapabilityStrip` already uses — 17 classes in
// catalog order — generalised so posture checks and candidate capabilities can be
// read the same way.
//
// One fixed-width `Item` per cell, so a glyph sits at the same x on every render and
// a wide Nerd-Font icon (whose ink is wider than its advance) can never overlap its
// neighbour. The strip WRAPS to a second row via `Flow` rather than scrolling: a
// 40-check catalog at base 9 must stay countable, and a horizontally scrolled unit
// chart is not.
//
// The cell vocabulary is 02 §2.4's placeholder vocabulary, unchanged:
//   level "absent" -> `–`  no data; the collection could have been omitted or capped
//   level "none"   -> `·`  observed, none — a positive claim, only where earned
//   anything else  -> the caller's glyph, in its tier colour
//
// Cursor: presentational only. The owning view holds the cursor index and reacts to
// `activated` / `hovered`, so the panel keeps one highlight on screen (the
// `CursorSurface` contract). This component never reads `containsMouse` for paint.
Item {
  id: root

  // [{ key, glyph, level, tooltip }] in CLI catalog order. Order is the caller's;
  // this component never sorts.
  property var cells: []
  // The `CapabilityStrip` cell, reused so the two strips line up on screen.
  property real cellW: Style.space(11)
  // Index of the cell holding the panel cursor, or -1. `focused` is the owning
  // section being the active cursor section.
  property int cursorIndex: -1
  property bool focused: false

  property color foreground: Color.foreground
  property color dim: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  signal activated(int index)
  signal hovered(int index)

  readonly property bool darkSurface: Tiers.isDark(Color.background)
  readonly property real cellH: Math.max(Style.space(18), Math.round(Style.font.icon * 1.35))

  // The paint for a cell: the tier colour where the level has one, `dim` for the two
  // placeholders, `foreground` for a presence mark that carries no tier.
  function cellColor(level) {
    var key = String(level || "")
    if (key === "absent" || key === "none") return root.dim
    var tier = Tiers.color(key, root.darkSurface)
    return tier === "" ? root.foreground : tier
  }

  // The rendered text for a cell. The placeholders win over any glyph the caller
  // passed, so a stale glyph can never survive a level that says "no data".
  function cellText(cell) {
    var level = String(cell && cell.level || "")
    if (level === "absent") return "–"
    if (level === "none") return "·"
    return String(cell && cell.glyph || "")
  }

  width: parent ? parent.width : implicitWidth
  implicitWidth: Math.max(1, (cells ? cells.length : 0) * cellW)
  implicitHeight: flow.implicitHeight

  Flow {
    id: flow
    width: root.width
    spacing: 0

    Repeater {
      model: root.cells

      delegate: CursorSurface {
        id: cell
        required property var modelData
        required property int index

        width: root.cellW
        height: root.cellH
        hasCursor: root.focused && root.cursorIndex === cell.index
        foreground: root.foreground
        accent: root.accent

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.cellText(cell.modelData)
          color: root.cellColor(cell.modelData ? cell.modelData.level : "")
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        // The tooltip follows the cursor, not the pointer: hover moves the cursor
        // through the view, and the cursor shows the tooltip. One highlight, one
        // tooltip, whichever device the reader is using.
        PanelToolTip {
          visible: cell.hasCursor && String(cell.modelData && cell.modelData.tooltip || "") !== ""
          text: String(cell.modelData && cell.modelData.tooltip || "")
          fontFamily: root.fontFamily
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          onEntered: root.hovered(cell.index)
          onClicked: root.activated(cell.index)
        }
      }
    }
  }
}
