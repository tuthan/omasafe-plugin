import QtQuick
import qs.Commons
import qs.Ui

// The view-chip row. This is the kit `ButtonGroup` pattern with one change that
// matters: it is a **Flow, not a Row**, so it wraps instead of running off the panel.
//
// `ButtonGroup` is a plain `Row` — it does not wrap, elide or shrink — and the panel's
// usable width is not the number the panel is configured with: the kit puts
// `popupPadding` inside `contentWidth` and a border outside that, so a 420-unit compact
// panel has ~390 usable units on a default-padding theme. Measured across five themes,
// the five chip labels were already 383-391 units wide BEFORE any count was added, i.e.
// flush with the edge or one pixel over it, and adding counts pushed them 20-28 units
// past it with nothing on screen saying so.
//
// So the row must not be able to clip by construction. Wrapping is the guarantee; the
// tightened padding and gap below are what keep it on one line in practice, and the
// harness (`scripts/harness/chips.qml`) measures the real component rather than an
// estimate of it.
//
// The panel drives `cursorIndex` and listens on `hovered`; this component holds no
// cursor state of its own, exactly as `ButtonGroup` did for us.
Flow {
  id: root

  // [{ value, label, count }] — `count` is the already-formatted suffix ("3", "·",
  // "–") or "" for a tab with no collector. The component owns the FORMATTING, so the
  // parentheses live in one place and the width budget is measurable.
  property var options: []
  property string value: ""
  property int cursorIndex: -1

  property color foreground: Color.foreground
  property color background: Color.background
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.bodySmall

  // Tighter than the kit defaults, and both are kit tokens. Five chips pay the
  // horizontal padding ten times over, so this is where the width actually is:
  // `controlPaddingX` -> `md` buys ~40 units, and `md` -> `sm` between chips buys ~8.
  property real chipPadding: Style.spacing.md

  signal changed(string value)
  signal hovered(int index, bool isHovered)

  function optionLabel(o) {
    var label = String(o && o.label || "")
    var count = String(o && o.count || "")
    return count === "" ? label : label + " (" + count + ")"
  }

  width: parent ? parent.width : implicitWidth
  spacing: Style.spacing.sm

  // A Flow's own `implicitWidth` reports its WIDEST LINE, so once it has wrapped it
  // reports a number smaller than the content — which makes it useless as an overflow
  // signal and is why the harness measures this instead. `wrapped` is the thing to
  // assert against: false on every theme and base size is the acceptance.
  readonly property real unwrappedWidth: {
    var total = 0, n = 0
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (!child || !child.visible || child.implicitWidth === undefined) continue
      total += child.implicitWidth
      n++
    }
    return n > 0 ? total + spacing * (n - 1) : 0
  }
  readonly property bool wrapped: root.width > 0 && root.unwrappedWidth > root.width

  Repeater {
    model: root.options

    delegate: Button {
      required property var modelData
      required property int index

      text: root.optionLabel(modelData)
      tooltipText: String(modelData.tooltip || "")
      selected: String(modelData.value) === root.value
      hasCursor: root.cursorIndex === index
      bordered: true
      horizontalPadding: root.chipPadding
      foreground: root.foreground
      background: root.background
      accent: root.accent
      fontFamily: root.fontFamily
      fontSize: root.fontSize
      onClicked: root.changed(String(modelData.value))
      onHovered: function(h) { root.hovered(index, h) }
    }
  }
}
