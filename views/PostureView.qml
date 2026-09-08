import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../components"

// Host posture is evidence about this machine, not a clean/safe verdict. The
// report's state words and coverage limitations remain visible beside every
// check so incomplete observation cannot render as a healthy result.
Column {
  id: root

  property var panel: null
  readonly property var report: panel ? panel.postureReport : null
  readonly property string rf: Style.font.resolvedFamily
  readonly property int staleAfterSeconds: 86400

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(10)

  function col(name) { return panel ? panel[name] : Color.foreground }
  function stateLevel(state) {
    switch (String(state || "").toLowerCase()) {
    case "pass": return "pass"
    case "regression": return "high"
    case "attention": return "medium"
    case "informational": return "info"
    case "incomplete": return "incomplete"
    case "error": return "critical"
    case "not_applicable": return "unknown"
    default: return "unknown"
    }
  }
  function resultAgeSeconds() {
    if (!root.report || root.report.result_age_seconds === undefined) return -1
    var age = Number(root.report.result_age_seconds)
    return isFinite(age) && age >= 0 ? Math.floor(age) : -1
  }
  function ageText() {
    var age = root.resultAgeSeconds()
    if (age < 0) return "not reported"
    if (age < 60) return "less than 1 minute"
    if (age < 3600) return Math.floor(age / 60) + " minutes"
    if (age < 86400) return Math.floor(age / 3600) + " hours"
    return Math.floor(age / 86400) + " days"
  }
  function stateText(state) { return String(state || "unknown").replace("_", " ").toUpperCase() }
  function coverageText() {
    if (!root.report || !root.report.coverage) return ""
    var c = root.report.coverage
    var parts = []
    if (Number(c.complete || 0) > 0) parts.push(Number(c.complete) + " COMPLETE")
    if (Number(c.incomplete || 0) > 0) parts.push(Number(c.incomplete) + " INCOMPLETE")
    if (Number(c.errors || 0) > 0) parts.push(Number(c.errors) + " ERROR")
    if (Number(c.not_applicable || 0) > 0) parts.push(Number(c.not_applicable) + " N/A")
    return parts.join(" · ")
  }
  function hostRows() {
    var h = root.report && root.report.host ? root.report.host : {}
    return [
      { label: "OS", value: String(h.os || "unknown") },
      { label: "ARCH", value: String(h.arch || "unknown") },
      { label: "OMARCHY", value: String(h.omarchy_version || h.omarchy_path || "not observed") },
      { label: "KERNEL", value: String(h.kernel || "not observed") },
      { label: "GENERATED", value: String(root.report ? root.report.generated_at || "" : "") },
      { label: "AGE", value: root.ageText() }
    ]
  }

  NoticeRow {
    width: parent.width
    visible: !root.panel || !root.panel.cliVerified
    reason: "unavailable"
    text: "Host posture is unavailable until omasafe-cli 0.3.0 or newer is verified."
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }

  SectionHeaderRow {
    text: "HOST POSTURE"
    value: root.report && root.report.status === "not_yet_run" ? "NOT YET RUN" : root.coverageText()
    foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
    fontFamily: root.col("fontFamily")
  }

  Text {
    width: parent.width - Style.space(18); x: Style.space(10)
    textFormat: Text.PlainText
    text: "OmaSafe observations about this host. A pass is limited to the checks and tools observed at the report time; incomplete and error states remain open coverage gaps."
    color: root.col("dim")
    font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  Row {
    spacing: Style.space(8)
    Button {
      text: "Run posture scan"
      bordered: true
      enabled: root.panel && root.panel.cliVerified && !root.panel.postureLoading
      foreground: enabled ? root.col("fg") : root.col("faint")
      fontFamily: root.col("fontFamily")
      tooltipText: "Collect a current host posture report"
      onClicked: if (root.panel) root.panel.runPostureScan()
    }
    Button {
      visible: root.panel && root.panel.postureLoading
      text: "Collecting…"
      bordered: true
      enabled: false
      foreground: root.col("faint")
      fontFamily: root.col("fontFamily")
    }
  }

  NoticeRow {
    width: parent.width
    visible: root.panel && root.panel.postureLoading
    reason: "loading"
    text: "Collecting bounded host observations…"
    foreground: root.col("fg"); dim: root.col("dim")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }
  NoticeRow {
    width: parent.width
    visible: root.panel && root.panel.postureError !== ""
    reason: "unavailable"; cliFailure: true
    text: root.panel ? root.panel.postureError : "Host posture is unavailable."
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }
  NoticeRow {
    width: parent.width
    visible: root.report && root.report.status === "not_yet_run" && !(root.panel && root.panel.postureLoading)
    reason: "unsupported"
    text: "No posture scan has completed yet. Run a scan to establish the first observation; this is not a clean result."
    foreground: root.col("fg"); dim: root.col("dim")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }
  NoticeRow {
    width: parent.width
    visible: root.report && root.report.status !== "not_yet_run" && root.resultAgeSeconds() >= root.staleAfterSeconds
    reason: "stale"
    text: "This posture report is stale (" + root.ageText() + "); run a scan for current observations."
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }

  Column {
    width: parent.width
    visible: !!root.report && root.report.status !== "not_yet_run"
    spacing: Style.space(10)

    InfoGrid {
      width: parent.width
      rows: root.hostRows()
      foreground: root.col("fg"); labelColor: root.col("dim")
      fontFamily: root.col("fontFamily")
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: root.report && root.report.last_observed_post_update_hook
      textFormat: Text.PlainText
      text: root.report && root.report.last_observed_post_update_hook
        ? "Last observed post-update hook: " + root.report.last_observed_post_update_hook : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    SectionHeaderRow {
      text: "CHECKS"
      value: root.report ? String((root.report.checks || []).length) : "0"
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    Repeater {
      id: checks
      width: parent.width
      model: root.report && Array.isArray(root.report.checks) ? root.report.checks : []
      delegate: Column {
        required property var modelData
        width: checks.width
        spacing: Style.space(4)

        Row {
          width: parent.width
          spacing: Style.space(7)
          SemanticMark {
            level: root.stateLevel(modelData.state)
            labelOverride: root.stateText(modelData.state)
            showLabel: true
            foreground: root.col("fg"); dim: root.col("dim")
            fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
          }
          Text {
            width: parent.width - Style.space(36)
            textFormat: Text.PlainText
            text: String(modelData.title || modelData.id || "Unnamed check")
            color: root.col("fg")
            font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
            anchors.verticalCenter: parent.verticalCenter
          }
        }
        Text {
          width: parent.width - Style.space(30); x: Style.space(30)
          textFormat: Text.PlainText
          text: "State: " + root.stateText(modelData.state) +
            (modelData.evidence && modelData.evidence.length
              ? "\nEvidence: " + modelData.evidence.join("; ") : "\nEvidence: none recorded")
          color: root.col("dim")
          font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width - Style.space(30); x: Style.space(30)
          visible: modelData.limitations && modelData.limitations.length > 0
          textFormat: Text.PlainText
          text: "Coverage limitation: " + (modelData.limitations || []).join("; ")
          color: root.col("dim")
          font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width - Style.space(30); x: Style.space(30)
          visible: !!modelData.next_step
          textFormat: Text.PlainText
          text: "Next step: " + String(modelData.next_step || "")
          color: root.col("dim")
          font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }
    }

    NoticeRow {
      width: parent.width
      visible: root.report && root.report.coverage && root.report.coverage.limitations &&
        root.report.coverage.limitations.length > 0
      reason: "unsupported"
      text: root.report && root.report.coverage
        ? "Overall coverage limitations: " + root.report.coverage.limitations.join("; ") : ""
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }
  }
}
