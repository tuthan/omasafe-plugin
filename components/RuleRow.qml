import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

// One RULE CATALOG row that expands into the rule sheet inline (doc 03 §7.1). Header:
// capability-class glyph · title (body); `id · language · severity` (bodySmall) with a
// right-aligned local hit count that reads `–` (never 0) until a plugin is analyzed.
// Expanded: summary, Anchor, What to check, LOCAL HITS (every live plugin, unanalyzed
// as `not analyzed`), and the rule's BASELINE V3 relations from `rules explain`.
// Presentational; the view owns the cursor, the expansion and the explain fetch.
CursorSurface {
  id: root

  property string glyph: ""
  property string title: ""
  property string idLine: ""           // "oma.qml.process-execution · qml · medium"
  property string rowHitText: "–"
  property string severity: "unknown"
  property bool noLocalHits: false
  property bool analysisComplete: false

  property bool expanded: false
  property string summary: ""
  property string anchorText: ""
  property string reviewGuidance: ""
  property string localHitsHeader: "–"
  property var hits: []                // [{ pluginId, occLine }]
  property var notAnalyzed: []         // plugin ids listed as not analyzed
  property bool relationsLoading: false
  property string relationsError: ""
  property string baselineHeader: ""
  property var relations: []           // [{ mark, externalId, relationWord }]

  property color dim: Color.foreground
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily

  signal toggleRequested()
  signal openHit(string pluginId)
  signal openRelation(string externalId)

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
      height: Math.max(twoLine.implicitHeight, chevron.size)

      Text {
        id: glyphText
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: Style.space(1)
        width: Style.space(22)
        textFormat: Text.PlainText
        text: root.glyph
        horizontalAlignment: Text.AlignHCenter
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
      }

      Text {
        id: hitCount
        anchors.right: chevron.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: twoLine.verticalCenter
        textFormat: Text.PlainText
        text: root.rowHitText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      SemanticMark {
        id: severityMark
        anchors.right: hitCount.left
        anchors.rightMargin: Style.space(4)
        anchors.verticalCenter: hitCount.verticalCenter
        compact: true
        level: root.severity
        labelOverride: root.severity
        foreground: root.foreground
        dim: root.dim
        fontFamily: root.fontFamily
        resolvedFamily: root.resolvedFamily
      }

      SemanticMark {
        id: cleanMark
        anchors.right: severityMark.left
        anchors.rightMargin: Style.space(2)
        anchors.verticalCenter: severityMark.verticalCenter
        visible: root.noLocalHits && root.analysisComplete
        compact: true
        kind: "health"
        level: "healthy"
        labelOverride: "No local hits"
        foreground: root.foreground
        dim: root.dim
        fontFamily: root.fontFamily
        resolvedFamily: root.resolvedFamily
      }

      Column {
        id: twoLine
        anchors.left: glyphText.right
        anchors.leftMargin: Style.space(8)
        anchors.right: (cleanMark.visible ? cleanMark.left : severityMark.left)
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.title
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.idLine
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }
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

    // Rule sheet (expanded).
    Column {
      width: parent.width
      visible: root.expanded
      leftPadding: Style.space(30)
      spacing: Style.space(6)

      Text {
        width: parent.width - parent.leftPadding
        visible: root.summary !== ""
        textFormat: Text.PlainText
        text: root.summary
        color: root.foreground
        font.family: root.fontFamily; font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
      }
      Text {
        width: parent.width - parent.leftPadding
        visible: root.anchorText !== ""
        textFormat: Text.PlainText
        text: "Anchor  " + root.anchorText
        color: root.dim
        font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
      Text {
        width: parent.width - parent.leftPadding
        visible: root.reviewGuidance !== ""
        textFormat: Text.PlainText
        text: "What to check\n" + root.reviewGuidance
        color: root.foreground
        font.family: root.fontFamily; font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
      }

      // LOCAL HITS.
      Text {
        width: parent.width - parent.leftPadding
        textFormat: Text.PlainText
        text: "LOCAL HITS  " + root.localHitsHeader
        color: root.dim
        font.family: root.fontFamily; font.pixelSize: Style.font.caption
        font.bold: true
      }
      Repeater {
        model: root.expanded ? root.hits : []
        delegate: Column {
          required property var modelData
          width: parent.width - parent.leftPadding
          spacing: Style.space(1)
          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: String(modelData.pluginId)
            color: root.foreground
            font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: root.openHit(String(modelData.pluginId)) }
          }
          Text {
            width: parent.width; leftPadding: Style.space(8)
            textFormat: Text.PlainText
            text: String(modelData.occLine)
            color: root.dim
            font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
          }
        }
      }
      Text {
        width: parent.width - parent.leftPadding
        visible: root.expanded && root.notAnalyzed.length > 0
        textFormat: Text.PlainText
        text: "+" + root.notAnalyzed.length + " not analyzed"
        color: root.dim
        font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
      }

      // BASELINE V3 relations.
      Text {
        width: parent.width - parent.leftPadding
        visible: root.baselineHeader !== "" || root.relationsLoading || root.relationsError !== ""
        textFormat: Text.PlainText
        text: "BASELINE V3  " + root.baselineHeader
        color: root.dim
        font.family: root.fontFamily; font.pixelSize: Style.font.caption
        font.bold: true
      }
      Text {
        width: parent.width - parent.leftPadding
        visible: root.relationsLoading
        textFormat: Text.PlainText
        text: "Loading Baseline V3 relations…"
        color: root.dim
        font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
      }
      Text {
        width: parent.width - parent.leftPadding
        visible: root.relationsError !== ""
        textFormat: Text.PlainText
        text: "Baseline V3 relations unavailable: " + root.relationsError + "."
        color: root.dim
        font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
      Repeater {
        model: root.expanded ? root.relations : []
        delegate: Text {
          required property var modelData
          width: parent.width - parent.leftPadding
          textFormat: Text.PlainText
          text: (String(modelData.mark) !== "" ? String(modelData.mark) + " " : "") + String(modelData.externalId) + " · " + String(modelData.relationWord)
          color: root.foreground
          font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: root.openRelation(String(modelData.externalId)) }
        }
      }
    }
  }
}
