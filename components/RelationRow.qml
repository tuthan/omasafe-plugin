import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// One BASELINE V3 COVERAGE row (doc 03 §7.2): line 1 = relation mark (`=` / `≈` /
// none) · externalId; line 2 = `<n> OmaSafe rules` / `<class> (class)` / `Inventory
// behaviour only (see note)` · relation word, or `Not covered by OmaSafe` (dim). It
// expands to the covering OmaSafe rules — each with a fact about that rule only
// (`observed in <k> analyzed plugins`) — and the map note verbatim. No plugin count
// is ever placed on the row. Presentational.
CursorSurface {
  id: root

  property string mark: ""
  property string externalId: ""
  property string line2: ""
  property bool covered: true
  property bool expanded: false
  property var coveringRules: []       // [{ ruleId, observedText }]
  property string note: ""

  property color dim: Color.foreground
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  signal toggleRequested()
  signal openRule(string ruleId)

  width: parent ? parent.width : implicitWidth
  implicitHeight: content.implicitHeight + Style.spacing.rowPaddingX

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(8)
    spacing: Style.space(1)

    Item {
      width: parent.width
      height: Math.max(twoLine.implicitHeight, chevron.size)

      Text {
        id: markText
        anchors.left: parent.left
        anchors.top: parent.top
        width: Style.space(22)
        textFormat: Text.PlainText
        text: root.mark
        horizontalAlignment: Text.AlignHCenter
        color: root.covered ? root.foreground : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
      }

      Column {
        id: twoLine
        anchors.left: markText.right
        anchors.leftMargin: Style.space(8)
        anchors.right: chevron.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.externalId
          color: root.covered ? root.foreground : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.line2
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }

      PanelActionButton {
        id: chevron
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.coveringRules.length > 0 || root.note !== ""
        iconText: Glyphs.ui_(root.expanded ? "collapse" : "expand", root.resolvedFamily)
        tooltipText: root.expanded ? "Collapse" : "Expand"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.toggleRequested()
      }
    }

    Column {
      width: parent.width
      visible: root.expanded
      leftPadding: Style.space(22)
      spacing: Style.space(4)

      Repeater {
        model: root.expanded ? root.coveringRules : []
        delegate: Column {
          required property var modelData
          width: parent.width - parent.leftPadding
          spacing: Style.space(1)

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: String(modelData.ruleId)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openRule(String(modelData.ruleId))
            }
          }
          Text {
            width: parent.width
            leftPadding: Style.space(8)
            textFormat: Text.PlainText
            text: String(modelData.observedText)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }

      Text {
        width: parent.width - parent.leftPadding
        visible: root.note !== ""
        textFormat: Text.PlainText
        text: root.note
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }
  }
}
