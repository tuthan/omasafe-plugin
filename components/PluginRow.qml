import QtQuick
import qs.Commons
import qs.Ui

// One PLUGINS row (doc 02 §2.8, 03 §4.1). Line 1: classification glyph · id
// (ElideMiddle) · right-aligned trust word (bodySmall; the alert glyph + bold for
// `differs`). Line 2: the 17-glyph CapabilityStrip (width-capped) · right-aligned
// count with the dim ` · <n> limits` / ` · text match only` suffixes (GR4). No
// trailing chevron: Enter / l opens the detail sheet. Presentational; the view owns
// the cursor and opens on activation.
CursorSurface {
  id: root

  property string classGlyph: ""
  property string pluginId: ""
  property string trustWord: ""
  property string trustGlyph: ""       // "" or the alert glyph for `differs`
  property bool trustBold: false
  property string trustTooltip: ""

  property bool analyzed: false
  property var counts: ({})
  property string countText: ""        // "5 items" / "not analyzed" / "checking…"
  property string limitsText: ""       // " · 13 limits" or ""
  property string lexicalText: ""      // " · text match only" or ""

  property color dim: Color.foreground
  property color urgentColor: Color.urgent
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  signal openRequested()

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

    // Line 1: glyph · id · trust word.
    Item {
      width: parent.width
      height: Math.max(idText.implicitHeight, trustRow.implicitHeight)

      Text {
        id: classGlyphText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(22)
        textFormat: Text.PlainText
        text: root.classGlyph
        horizontalAlignment: Text.AlignHCenter
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
      }

      Text {
        id: idText
        anchors.left: classGlyphText.right
        anchors.leftMargin: Style.space(8)
        anchors.right: trustRow.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.pluginId
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideMiddle
      }

      Row {
        id: trustRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(4)

        Text {
          visible: root.trustGlyph !== ""
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.trustGlyph
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.trustWord
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: root.trustBold
        }
      }
    }

    // Line 2: capability strip · count with coverage suffixes.
    Item {
      width: parent.width
      height: Math.max(strip.implicitHeight, countRow.implicitHeight)

      CapabilityStrip {
        id: strip
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Style.space(190))
        analyzed: root.analyzed
        counts: root.counts
        rowHasCursor: root.hasCursor
        foreground: root.foreground
        fontFamily: root.fontFamily
        resolvedFamily: root.resolvedFamily
      }

      Row {
        id: countRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.countText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          visible: root.limitsText !== ""
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.limitsText
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          visible: root.lexicalText !== ""
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.lexicalText
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }

  PanelToolTip {
    visible: root.hasCursor && root.trustTooltip !== ""
    text: root.trustTooltip
    fontFamily: root.fontFamily
  }
}
