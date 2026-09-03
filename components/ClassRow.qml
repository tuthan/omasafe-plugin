import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// One CAPABILITIES OBSERVED row (doc 03 §5.2): class glyph · capability name ·
// `<n> sites · <m> files` · expand chevron. Expanded (one class at a time, the view
// owns that), it opens a Column of site rows `path:line · detail · <confidence word>`
// (bodySmall) with a `+N more` sub-row. Presentational; the view supplies the site
// strings already limited to the shown count and owns the cursor.
CursorSurface {
  id: root

  property string glyph: ""
  property string name: ""
  property string sitesText: ""        // "16 sites · 2 files"
  property bool expanded: false
  property var sites: []               // array of already-formatted site strings
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
        id: sitesTextItem
        anchors.right: chevron.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.sitesText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        id: nameText
        anchors.left: glyphText.right
        anchors.leftMargin: Style.space(8)
        anchors.right: sitesTextItem.left
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

    // Expanded site list.
    Column {
      width: parent.width
      visible: root.expanded
      spacing: Style.space(1)

      Repeater {
        model: root.expanded ? root.sites : []
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
}
