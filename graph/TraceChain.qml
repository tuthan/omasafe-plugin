import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../components"
import "../model/Labels.js" as Labels

// TraceChain — the Z2 Trace body (doc 04 §9.4, T3.11): the three-line chain, the
// EVIDENCE list (path:line · detail · confidence) — both class-filtered — then the
// plugin-wide FILE EDGES rows and grouped COVERAGE LIMITS. The last two carry a
// `· PLUGIN-WIDE` suffix because they are the plugin's call graph and coverage gaps, not
// this class path's (T4.0); labelling them "on this path" would overclaim specificity.
// The map note is NOT shown here (only in the Baseline V3 coverage table). Verdict-free.
Column {
  id: root

  property var panel: null
  readonly property var trace: panel ? panel.flowTraceData() : ({ available: false })
  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily
  property color fg: Color.foreground
  property color dimColor: fg
  property color dimHeaderColor: fg

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(6)

  function hdr(text, value) { return text }

  // ---- the chain (plugin -N- class · rule mark baseline · via class list) ------
  Repeater {
    model: root.trace.available ? root.trace.chainLines
      : [ root.trace.pluginId + " › " + root.trace.className ]
    delegate: Text {
      required property var modelData
      required property int index
      width: root.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: modelData
      elide: Text.ElideRight
      color: index === 0 ? root.fg : root.dimColor
      font.family: root.fontFamily
      font.pixelSize: index === 0 ? Style.font.body : Style.font.bodySmall
    }
  }

  NoticeRow {
    width: parent.width
    visible: !root.trace.available
    reason: "none"
    text: "Not analyzed. Analyze the plugin (a) to trace this path."
    foreground: root.fg; dim: root.dimColor
    fontFamily: root.fontFamily; resolvedFamily: root.resolvedFamily
  }

  // ---- EVIDENCE ----------------------------------------------------------------
  SectionHeaderRow {
    visible: root.trace.available
    text: "EVIDENCE"
    value: root.trace.available ? (root.trace.evidenceCount + " ROWS") : ""
    foreground: root.dimHeaderColor; valueColor: root.dimHeaderColor
    fontFamily: root.fontFamily
  }
  ListView {
    id: evidence
    visible: root.trace.available
    width: parent.width
    height: Math.min(contentHeight, Style.space(200))
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
    model: root.trace.available ? root.trace.evidence : []
    delegate: Row {
      required property var modelData
      width: evidence.width
      spacing: Style.space(8)
      leftPadding: Style.space(10)
      Text {
        width: evidence.width * 0.45
        textFormat: Text.PlainText; text: modelData.line; elide: Text.ElideMiddle
        color: root.fg; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
      }
      Text {
        width: evidence.width * 0.25
        textFormat: Text.PlainText; text: modelData.detail; elide: Text.ElideRight
        color: root.dimColor; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
      }
      Text {
        textFormat: Text.PlainText; text: modelData.confidence
        color: root.dimColor; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
      }
    }
  }

  // ---- FILE EDGES · PLUGIN-WIDE -------------------------------------------------
  SectionHeaderRow {
    visible: root.trace.available && root.trace.edges.length > 0
    text: "FILE EDGES · PLUGIN-WIDE"
    value: root.trace.available ? String(root.trace.edgeCount) : ""
    foreground: root.dimHeaderColor; valueColor: root.dimHeaderColor
    fontFamily: root.fontFamily
  }
  Repeater {
    model: (root.trace.available ? root.trace.edges : [])
    delegate: EdgeRow {
      required property var modelData
      width: root.width
      text: modelData.line + " ─▶ " + modelData.target
        + (modelData.state && modelData.state !== "analyzed" ? " · " + Labels.coverageState(modelData.state) : "")
      tooltipText: modelData.line
      dim: root.dimColor
      fontFamily: root.fontFamily
    }
  }

  // ---- COVERAGE LIMITS · PLUGIN-WIDE --------------------------------------------
  SectionHeaderRow {
    visible: root.trace.available && root.trace.limitCount > 0
    text: "COVERAGE LIMITS · PLUGIN-WIDE"
    value: root.trace.available ? String(root.trace.limitCount) : ""
    foreground: root.dimHeaderColor; valueColor: root.dimHeaderColor
    fontFamily: root.fontFamily
  }
  Repeater {
    model: (root.trace.available ? root.trace.limits : [])
    delegate: Text {
      required property var modelData
      width: root.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText; text: modelData; wrapMode: Text.WordWrap
      color: root.dimColor; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
    }
  }
}
