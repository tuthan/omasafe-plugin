import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// One CAPABILITIES OBSERVED row (doc 03 §5.2): class glyph · capability name ·
// `<n> uses · <m> files` · expand chevron. A use is one source-level capability
// reference emitted by the analyzer; files is the distinct-file count. Expanded
// (one class at a time, the view owns that), it opens source-location rows
// `path:line · detail · <confidence word>`
// (bodySmall) with a `+N more` sub-row. Presentational; the view supplies the source-use
// strings already limited to the shown count and owns the cursor.
CursorSurface {
  id: root

  property string glyph: ""
  property string name: ""
  property string usesText: ""         // "16 uses · 2 files"
  property string riskLevel: "unknown"
  property bool expanded: false
  property var uses: []                // array of already-formatted source-use strings
  property int moreCount: 0            // >0 → a "+N more" sub-row

  property color dim: Color.foreground
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  signal toggleRequested()
  signal moreRequested()

  width: parent ? parent.width : implicitWidth
  implicitHeight: content.implicitHeight + Style.spacing.rowPaddingX

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(8)
    spacing: Style.space(6)

    // Header line.
    Item {
      width: parent.width
      height: Math.max(nameText.implicitHeight, chevron.size)

      Text {
        id: glyphText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(22)
        textFormat: Text.PlainText
        text: root.glyph
        horizontalAlignment: Text.AlignHCenter
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
      }

      Text {
        id: usesTextItem
        anchors.right: chevron.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.usesText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      SemanticMark {
        id: riskMark
        anchors.right: usesTextItem.left
        anchors.rightMargin: Style.space(4)
        anchors.verticalCenter: usesTextItem.verticalCenter
        compact: true
        level: root.riskLevel
        labelOverride: "Highest linked rule severity"
        foreground: root.foreground
        dim: root.dim
        fontFamily: root.fontFamily
        resolvedFamily: root.resolvedFamily
      }

      Text {
        id: nameText
        anchors.left: glyphText.right
        anchors.leftMargin: Style.space(8)
        anchors.right: riskMark.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.name
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }

      PanelActionButton {
        id: chevron
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        iconText: Glyphs.ui_(root.expanded ? "collapse" : "expand", root.resolvedFamily)
        tooltipText: root.expanded ? "Collapse" : "Expand"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.toggleRequested()
      }
    }

    // Expanded source-use list.
    Column {
      width: parent.width
      visible: root.expanded
      spacing: Style.space(1)

      Repeater {
        model: root.expanded ? root.uses : []
        delegate: Text {
          required property var modelData
          width: parent.width
          leftPadding: Style.space(30)
          textFormat: Text.PlainText
          text: String(modelData)
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }
      }

      Text {
        visible: root.expanded && root.moreCount > 0
        width: parent.width
        leftPadding: Style.space(30)
        textFormat: Text.PlainText
        text: "+" + root.moreCount + " more"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.moreRequested()
        }
      }
    }
  }

  PanelToolTip {
    visible: root.hasCursor
    text: "Uses = source-level capability references found by the analyzer · files = distinct files containing them."
    fontFamily: root.fontFamily
  }
}
