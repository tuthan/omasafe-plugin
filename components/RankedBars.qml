import QtQuick
import qs.Commons
import qs.Ui
import "../model/Tiers.js" as Tiers

// A sorted count list: label, length bar, right-aligned exact count (doc 02 §2.4
// CH1, CH3). It answers "is this one thing many times, or many things once?" —
// which for a 33-finding report is a different review.
//
// Bar length is relative to the LARGEST count, not to the total. A ranked list is
// read by comparing rows to each other; scaling to the total would make every row
// of a long tail an invisible stub, and CH6 would then pad them all to the same
// minimum, destroying the ranking the component exists to show. The count printed on
// each row is the datum either way (CH1).
//
// Truncation is always disclosed: `+N more` under the last row, never a silent cut.
Column {
  id: root

  // [{ label, count, level }]. Sorted here by count desc then label asc, so callers
  // cannot each pick a different tie-break.
  property var rows: []
  property int maxRows: 5
  // The collection total, printed in the truncation line so a cut list still
  // reconciles with the header (CH5).
  property int total: 0
  property real trackHeight: Style.space(5)
  // Fraction of the row width given to the label column.
  property real labelFraction: 0.52

  property color foreground: Color.foreground
  property color dim: Color.foreground
  property string fontFamily: Style.font.family

  readonly property bool darkSurface: Tiers.isDark(Color.background)

  readonly property var _sorted: {
    var list = []
    var src = root.rows || []
    for (var i = 0; i < src.length; i++) {
      var n = Number(src[i] && src[i].count)
      list.push({
        label: String(src[i] && src[i].label || ""),
        count: isFinite(n) && n > 0 ? n : 0,
        level: String(src[i] && src[i].level || "")
      })
    }
    list.sort(function(a, b) {
      if (b.count !== a.count) return b.count - a.count
      return a.label < b.label ? -1 : (a.label > b.label ? 1 : 0)
    })
    return list
  }
  readonly property int _largest: root._sorted.length > 0 ? root._sorted[0].count : 0
  readonly property var _shown: root._sorted.slice(0, Math.max(0, root.maxRows))
  readonly property int _hidden: Math.max(0, root._sorted.length - root._shown.length)

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(3)

  Repeater {
    model: root._shown

    delegate: Item {
      id: row
      required property var modelData

      width: root.width
      height: Math.max(labelText.implicitHeight, countText.implicitHeight)

      Text {
        id: labelText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(row.width * root.labelFraction)
        textFormat: Text.PlainText
        text: row.modelData.label
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideMiddle
      }

      Text {
        id: countText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: String(row.modelData.count)
        horizontalAlignment: Text.AlignRight
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      BorderSurface {
        id: bar
        anchors.left: labelText.right
        anchors.leftMargin: Style.space(8)
        anchors.right: countText.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight + Border.top(borderSpec) + Border.bottom(borderSpec)
        color: "transparent"
        radius: Style.cornerRadius
        borderSpec: Border.flat(root.dim, Style.normalBorderWidth)

        Rectangle {
          anchors.left: parent.left
          anchors.leftMargin: Border.left(bar.borderSpec)
          anchors.verticalCenter: parent.verticalCenter
          height: root.trackHeight
          // CH6: a non-zero row is never an invisible bar.
          width: root._largest > 0 && row.modelData.count > 0
            ? Math.max(Style.space(2),
                Math.round(row.modelData.count / root._largest *
                  (bar.width - Border.left(bar.borderSpec) - Border.right(bar.borderSpec))))
            : 0
          visible: width > 0
          color: {
            var tier = Tiers.color(row.modelData.level, root.darkSurface)
            return tier === "" ? root.foreground : tier
          }
        }
      }
    }
  }

  Text {
    visible: root._hidden > 0
    width: root.width
    textFormat: Text.PlainText
    text: root._hidden > 0
      ? "+" + root._hidden + " more" + (root.total > 0 ? " of " + root.total : "")
      : ""
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }
}
