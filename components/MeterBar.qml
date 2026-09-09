import QtQuick
import qs.Commons
import qs.Ui
import "../model/Tiers.js" as Tiers

// A segmented length bar: one segment per category along a common baseline (doc 02
// §2.4 CH2, CH3). It emits no text of its own — **the caller prints the counts
// line** — so a bar can never appear on screen without its numbers (CH1). Deleting
// this component from any surface loses speed, never information.
//
// Availability and zero are DIFFERENT STATES and neither implies the other (CH7):
//
//   available: false                  no track at all;  caller prints `unavailable`
//   available: true, total === 0      an empty track;   caller prints the zeros
//   available: true, total > 0        segments;         caller prints the counts
//
// A measured zero is data and keeps its zeros. Conflating it with `unavailable`
// would print "unavailable" over a scan that completed successfully, which is the
// GR3 failure in reverse.
//
// CH6: a non-zero category is never invisible. Its segment is at least
// `Style.space(2)` wide, which breaks strict proportionality at the small end — so
// the printed counts are the datum and this bar is documented as an aid.
Item {
  id: root

  // [{ key, count, level, label }] in the caller's order — attention order for a
  // state bar (CH8). This component never sorts and never drops a term.
  property var segments: []
  // The denominator, including any omitted or suppressed term the caller has added
  // to `segments`. The parts must reconcile visibly (CH5).
  property int total: 0
  // false when the collection could not be read at all.
  property bool available: true
  property real trackHeight: Style.space(6)

  property color foreground: Color.foreground
  property color dim: Color.foreground
  property string fontFamily: Style.font.family

  readonly property bool darkSurface: Tiers.isDark(Color.background)
  readonly property real minSegment: Style.space(2)

  // Sum of the segment counts, which is not necessarily `total`: a caller that has
  // not accounted for every item leaves the remainder as bare track rather than
  // having a segment silently stretch over it.
  readonly property int _counted: {
    var sum = 0
    var list = root.segments || []
    for (var i = 0; i < list.length; i++) {
      var n = Number(list[i] && list[i].count)
      if (isFinite(n) && n > 0) sum += n
    }
    return sum
  }
  readonly property int _denominator: Math.max(root.total, root._counted)

  // Widths in the same order as `segments`; 0 for a zero-count category, which is
  // absent from the bar and present in the caller's counts line (CH7).
  readonly property var _widths: {
    var list = root.segments || []
    var out = []
    var i
    for (i = 0; i < list.length; i++) out.push(0)
    var span = root.width - (Border.left(track.borderSpec) + Border.right(track.borderSpec))
    if (root._denominator <= 0 || span <= 0) return out

    var used = 0, largest = -1, largestCount = 0
    for (i = 0; i < list.length; i++) {
      var n = Number(list[i] && list[i].count)
      if (!isFinite(n) || n <= 0) continue
      var w = Math.max(root.minSegment, Math.round(n / root._denominator * span))
      out[i] = w
      used += w
      if (n > largestCount) { largestCount = n; largest = i }
    }

    // Absorb the rounding residual into the largest segment so the row fills exactly
    // — but only when the segments actually account for the whole denominator. Where
    // they do not, the shortfall stays visible as empty track.
    if (largest >= 0 && root._counted >= root._denominator) {
      out[largest] = Math.max(root.minSegment, out[largest] + (span - used))
    }
    return out
  }

  width: parent ? parent.width : implicitWidth
  visible: root.available
  implicitHeight: root.available ? track.implicitHeight : 0
  height: implicitHeight

  BorderSurface {
    id: track
    width: root.width
    implicitHeight: root.trackHeight + Border.top(borderSpec) + Border.bottom(borderSpec)
    height: implicitHeight
    color: "transparent"
    radius: Style.cornerRadius
    borderSpec: Border.flat(root.dim, Style.normalBorderWidth)

    Row {
      anchors.fill: parent
      anchors.topMargin: Border.top(track.borderSpec)
      anchors.bottomMargin: Border.bottom(track.borderSpec)
      anchors.leftMargin: Border.left(track.borderSpec)
      anchors.rightMargin: Border.right(track.borderSpec)
      spacing: 0

      Repeater {
        model: root.segments

        delegate: Rectangle {
          id: segment
          required property var modelData
          required property int index

          width: root._widths[segment.index] || 0
          height: parent ? parent.height : 0
          visible: width > 0
          color: {
            var tier = Tiers.color(segment.modelData ? segment.modelData.level : "", root.darkSurface)
            return tier === "" ? root.dim : tier
          }
        }
      }
    }
  }
}
