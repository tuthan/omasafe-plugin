import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../components"

// Persistent-in-session v0.2.2 Plugin Source Scan surface. The input remains one text value;
// the CLI owns its finite grammar and this view never extracts or executes it.
Column {
  id: root

  property var panel: null
  readonly property var candidate: panel ? panel.candidateModel : null
  readonly property string rf: Style.font.resolvedFamily
  readonly property bool inputActiveFocus: requestInput.activeFocus

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(12)

  function col(name) { return panel ? panel[name] : Color.foreground }

  Connections {
    target: root.panel
    function onCandidateInputChanged() {
      if (root.panel && requestInput.text !== root.panel.candidateInput)
        requestInput.text = root.panel.candidateInput
    }
  }

  SectionHeaderRow {
    text: "PLUGIN SOURCE SCAN"
    value: panel && panel.candidateState !== "idle" ? String(panel.candidateState).toUpperCase() : ""
    foreground: root.col("dimHeader")
    valueColor: root.col("dimHeader")
    fontFamily: root.col("fontFamily")
  }

  Text {
    width: parent.width - Style.space(18)
    x: Style.space(10)
    textFormat: Text.PlainText
    text: "Manually scan a public GitHub plugin source before installation. OmaSafe resolves one exact commit and analyzes raw objects; it does not install or enable the plugin."
    color: root.col("dim")
    font.family: root.col("fontFamily")
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  TextArea {
    id: requestInput
    width: parent.width
    height: Math.max(Style.space(74), implicitHeight)
    placeholderText: "GitHub URL or copied install command\nomarchy plugin add https://github.com/OWNER/REPO.git --enable"
    wrapMode: TextEdit.WrapAnywhere
    selectByMouse: true
    persistentSelection: true
    color: root.col("fg")
    selectionColor: root.col("selectedFill")
    selectedTextColor: root.col("fg")
    font.family: root.col("fontFamily")
    font.pixelSize: Style.font.bodySmall
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) {
        if (root.panel) root.panel.leaveSourceScan()
        event.accepted = true
      } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
        event.accepted = true
      }
    }
    onTextChanged: if (root.panel && root.panel.candidateInput !== text) root.panel.candidateInput = text
    Component.onCompleted: {
      text = root.panel ? root.panel.candidateInput : ""
      forceActiveFocus()
    }
  }

  Text {
    width: parent.width - Style.space(18)
    x: Style.space(10)
    visible: requestInput.length > 4096
    textFormat: Text.PlainText
    text: "Input is over 4,096 characters; the CLI byte limit is authoritative and will reject it."
    color: root.col("dim")
    font.family: root.col("fontFamily")
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  Row {
    spacing: Style.space(8)

    Button {
      text: "Scan source"
      bordered: true
      enabled: root.panel && root.panel.candidateCanRun && requestInput.text.trim() !== ""
      foreground: enabled ? root.col("fg") : root.col("faint")
      fontFamily: root.col("fontFamily")
      tooltipText: "Resolve and scan this plugin source without installing it"
      onClicked: if (root.panel) root.panel.runCandidate()
    }

    Button {
      visible: root.panel && root.panel.candidateProcessRunning
      text: "Cancel"
      bordered: true
      enabled: visible
      foreground: enabled ? root.col("fg") : root.col("faint")
      fontFamily: root.col("fontFamily")
      tooltipText: "Cancel source scan"
      onClicked: if (root.panel) root.panel.cancelCandidate()
    }
  }

  NoticeRow {
    width: parent.width
    visible: root.panel && root.panel.candidateState === "idle"
    reason: "none"
    text: "Paste one GitHub repository URL or one plain omarchy plugin add/install command."
    foreground: root.col("fg")
    dim: root.col("dim")
    fontFamily: root.col("fontFamily")
    resolvedFamily: root.rf
  }

  NoticeRow {
    width: parent.width
    visible: root.panel && ["resolving", "fetching", "analyzing"].indexOf(root.panel.candidateState) >= 0
    reason: "loading"
    text: root.panel ? root.panel.candidateProgressText() : "Scanning plugin source…"
    foreground: root.col("fg")
    dim: root.col("dim")
    fontFamily: root.col("fontFamily")
    resolvedFamily: root.rf
  }

  NoticeRow {
    width: parent.width
    visible: root.panel && root.panel.candidateState === "unavailable"
    reason: "unavailable"
    cliFailure: true
    text: root.panel ? root.panel.candidateError : "Source scan unavailable."
    foreground: root.col("fg")
    dim: root.col("dim")
    urgent: root.col("urgent")
    fontFamily: root.col("fontFamily")
    resolvedFamily: root.rf
  }

  NoticeRow {
    width: parent.width
    visible: root.panel && root.panel.candidateState === "cancelled"
    reason: "unsupported"
    text: "Source scan cancelled; no result was retained."
    foreground: root.col("fg")
    dim: root.col("dim")
    fontFamily: root.col("fontFamily")
    resolvedFamily: root.rf
  }

  Column {
    id: resultColumn
    width: parent.width
    visible: !!root.candidate && root.candidate.ok === true
    spacing: Style.space(8)

    SectionHeaderRow {
      text: "SOURCE SCAN RESULT"
      value: root.candidate ? root.candidate.target.revision : ""
      foreground: root.col("dimHeader")
      valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      textFormat: Text.PlainText
      text: root.candidate ? ((root.candidate.target.url || root.candidate.acquisition.effectiveRepositoryUrl) +
        "\ncommit " + root.candidate.target.revision) : ""
      color: root.col("fg")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.body
      wrapMode: Text.WrapAnywhere
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      textFormat: Text.PlainText
      text: "Scan-only · installation performed: false · no plugin was installed or enabled"
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.candidate && root.candidate.reviewSummary
      textFormat: Text.PlainText
      text: root.candidate && root.candidate.reviewSummary
        ? ("Analysis freshness: " + (root.candidate.freshness || "unknown") +
          (root.candidate.reviewSummary.analysisProducedAt !== ""
            ? " · produced " + root.candidate.reviewSummary.analysisProducedAt : "")) : ""
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.candidate && root.candidate.reviewSummary &&
        root.candidate.reviewSummary.untrustedDataNotice !== ""
      textFormat: Text.PlainText
      text: root.candidate ? root.candidate.reviewSummary.untrustedDataNotice : ""
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    NoticeRow {
      width: parent.width
      visible: root.candidate && root.candidate.reviewSummary && !root.candidate.presentationComplete
      reason: "unsupported"
      text: "The scanner marked this presentation incomplete; omitted or shortened evidence is disclosed below."
      foreground: root.col("fg")
      dim: root.col("dim")
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.candidate && root.candidate.analysis.evidenceObservationsOmitted > 0
      textFormat: Text.PlainText
      text: root.candidate
        ? ("Evidence observations omitted: " + root.candidate.analysis.evidenceObservationsOmitted) : ""
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    NoticeRow {
      width: parent.width
      visible: root.candidate && root.candidate.installCommand !== ""
      reason: "none"
      text: "No high or critical findings were reported under complete finding coverage. Manual review is still required."
      foreground: root.col("fg")
      dim: root.col("dim")
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
    }

    Row {
      width: parent.width
      spacing: Style.space(8)
      visible: root.candidate && root.candidate.installCommand !== ""
      Button {
        text: "Copy install command"
        bordered: true
        enabled: root.candidate && root.candidate.installCommand !== ""
        foreground: enabled ? root.col("fg") : root.col("faint")
        fontFamily: root.col("fontFamily")
        tooltipText: "Copy the suggested command; installation remains a separate manual decision"
        onClicked: if (root.panel) root.panel.copyValue(root.candidate.installCommand)
      }
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.candidate && root.candidate.installCommand !== ""
      textFormat: Text.PlainText
      text: root.candidate ? root.candidate.installCommand : ""
      color: root.col("fg")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WrapAnywhere
    }

    NoticeRow {
      width: parent.width
      visible: root.candidate && root.candidate.installCommand === "" &&
        root.candidate.installCommandReason !== ""
      reason: "unsupported"
      text: root.candidate ? root.candidate.installCommandReason : ""
      foreground: root.col("fg")
      dim: root.col("dim")
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      textFormat: Text.PlainText
      text: root.candidate ? ("Integrity: resolved exact " + root.candidate.acquisition.integrityAlgorithm +
        " · cache: " + root.candidate.acquisition.cacheResult +
        " · network used: " + (root.candidate.acquisition.networkUsed ? "yes" : "no")) : ""
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.candidate && root.candidate.listedRepository !== ""
      textFormat: Text.PlainText
      text: root.candidate ? "Marketplace listed repository: " + root.candidate.listedRepository : ""
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WrapAnywhere
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.candidate && root.candidate.marketplace
      textFormat: Text.PlainText
      text: root.candidate && root.candidate.marketplace
        ? ("Marketplace claim: " + (root.candidate.marketplace.verificationStatus || "unverified") +
          (root.candidate.marketplace.listingCommit !== ""
            ? " · listing commit " + root.candidate.marketplace.listingCommit : "")) : ""
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Row {
      width: parent.width
      spacing: Style.space(8)
      Button {
        text: "Copy exact rescan command"
        bordered: true
        enabled: root.candidate && root.candidate.rescanCommand !== ""
        foreground: enabled ? root.col("fg") : root.col("faint")
        fontFamily: root.col("fontFamily")
        tooltipText: "Copy the immutable Git rescan command"
        onClicked: if (root.panel) root.panel.copyCandidateCommand()
      }
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.candidate && root.candidate.rescanCommand !== ""
      textFormat: Text.PlainText
      text: root.candidate ? root.candidate.rescanCommand : ""
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.caption
      wrapMode: Text.WrapAnywhere
    }

    SectionHeaderRow {
      text: "FINDINGS"
      value: root.candidate ? (root.candidate.analysis.findingsTotal +
        (root.candidate.analysis.findingsOmitted > 0 ? " · " + root.candidate.analysis.findingsOmitted + " omitted" : "") +
        (root.candidate.analysis.findingsDisplayOmitted > 0 ? " · " + root.candidate.analysis.findingsDisplayOmitted + " hidden in UI" : "")) : ""
      foreground: root.col("dimHeader")
      valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    NoticeRow {
      width: parent.width
      visible: root.candidate && root.candidate.analysis.findingsTotal === 0 &&
        root.candidate.analysis.findingsOmitted === 0
      reason: "none"
      text: "No active findings under this scan's reported coverage."
      foreground: root.col("fg")
      dim: root.col("dim")
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
    }

    NoticeRow {
      width: parent.width
      visible: root.candidate && root.candidate.analysis.findingsOmitted > 0
      reason: "unsupported"
      text: "Some findings were omitted from the compact report; no empty-finding conclusion is available."
      foreground: root.col("fg")
      dim: root.col("dim")
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
    }

    NoticeRow {
      width: parent.width
      visible: root.candidate && root.candidate.analysis.findingsDisplayOmitted > 0
      reason: "unsupported"
      text: "Some findings are hidden by the UI display limit; the emitted report still contains the complete selected set."
      foreground: root.col("fg")
      dim: root.col("dim")
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
    }

    Repeater {
      model: root.candidate ? root.candidate.analysis.findings : []
      delegate: Column {
        required property var modelData
        width: resultColumn.width - Style.space(18)
        x: Style.space(10)
        spacing: Style.space(2)
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: String(modelData.severity || "unknown").toUpperCase() + " · " + modelData.title
          color: root.col("fg")
          font.family: root.col("fontFamily")
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: modelData.ruleId + " · " + (modelData.displayRelativePath || modelData.relativePath) +
            (modelData.line !== "" ? ":" + modelData.line : "")
          color: root.col("dim")
          font.family: root.col("fontFamily")
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WrapAnywhere
        }
        Text {
          width: parent.width
          visible: modelData.analysisMethod !== "" || modelData.occurrenceId !== ""
          textFormat: Text.PlainText
          text: (modelData.analysisMethod !== "" ? "Method: " + modelData.analysisMethod : "") +
            (modelData.occurrenceId !== "" ?
              (modelData.analysisMethod !== "" ? " · occurrence " : "Occurrence ") + modelData.occurrenceId : "")
          color: root.col("dim")
          font.family: root.col("fontFamily")
          font.pixelSize: Style.font.caption
          wrapMode: Text.WrapAnywhere
        }
        Text {
          width: parent.width
          visible: modelData.evidence !== ""
          textFormat: Text.PlainText
          text: "Evidence\n" + modelData.evidence
          color: root.col("dim")
          font.family: root.col("fontFamily")
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WrapAnywhere
        }
        Text {
          width: parent.width
          visible: modelData.behaviorContext
          textFormat: Text.PlainText
          text: modelData.behaviorContext
            ? ("Behavior: " + (modelData.behaviorContext.connection || "unresolved") +
              " · source " + (modelData.behaviorContext.sourceClass || "unknown") +
              " · sink " + (modelData.behaviorContext.sinkKind || "unknown") +
              " · trigger " + (modelData.behaviorContext.trigger || "unknown")) : ""
          color: root.col("dim")
          font.family: root.col("fontFamily")
          font.pixelSize: Style.font.caption
          wrapMode: Text.WrapAnywhere
        }
        Repeater {
          model: modelData.evidenceSteps || []
          delegate: Text {
            required property var modelData
            width: resultColumn.width - Style.space(28)
            x: Style.space(20)
            textFormat: Text.PlainText
            text: "Step " + (modelData.role || "observation") + " · " +
              (modelData.displayRelativePath || modelData.relativePath || "") +
              (modelData.line !== "" ? ":" + modelData.line : "") +
              (modelData.detail !== "" ? " · " + modelData.detail : "")
            color: root.col("dim")
            font.family: root.col("fontFamily")
            font.pixelSize: Style.font.caption
            wrapMode: Text.WrapAnywhere
          }
        }
      }
    }

    SectionHeaderRow {
      text: "CAPABILITIES"
      value: root.candidate ? (root.candidate.analysis.capabilitiesTotal +
        (root.candidate.analysis.capabilitiesOmitted > 0 ? " · " + root.candidate.analysis.capabilitiesOmitted + " omitted" : "") +
        (root.candidate.analysis.capabilitiesDisplayOmitted > 0 ? " · " + root.candidate.analysis.capabilitiesDisplayOmitted + " hidden in UI" : "")) : ""
      foreground: root.col("dimHeader")
      valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    NoticeRow {
      width: parent.width
      visible: root.candidate && root.candidate.analysis.capabilitiesDisplayOmitted > 0
      reason: "unsupported"
      text: "Some capabilities are hidden by the UI display limit; review the emitted count in the report."
      foreground: root.col("fg")
      dim: root.col("dim")
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
    }

    Repeater {
      model: root.candidate ? root.candidate.analysis.capabilities : []
      delegate: Text {
        required property var modelData
        width: resultColumn.width - Style.space(18)
        x: Style.space(10)
        textFormat: Text.PlainText
        text: modelData.capability + " · " + modelData.relativePath +
          (modelData.detail !== "" ? " · " + modelData.detail : "")
        color: root.col("dim")
        font.family: root.col("fontFamily")
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WrapAnywhere
      }
    }

    SectionHeaderRow {
      text: "COVERAGE AND LIMITATIONS"
      value: root.candidate ? (root.candidate.analysis.edgesTotal + " invocation edges" +
        (root.candidate.analysis.edgesDisplayOmitted > 0
          ? " · " + root.candidate.analysis.edgesDisplayOmitted + " hidden in UI" : "") +
        (root.candidate.analysis.coverageGapsTotal > 0
          ? " · " + root.candidate.analysis.coverageGapsTotal + " gaps" : "") +
        (root.candidate.analysis.coverageGapsOmitted > 0
          ? " · " + root.candidate.analysis.coverageGapsOmitted + " gaps omitted" : "") +
        (root.candidate.analysis.coverageGapsDisplayOmitted > 0
          ? " · " + root.candidate.analysis.coverageGapsDisplayOmitted + " gaps hidden in UI" : "")) : ""
      foreground: root.col("dimHeader")
      valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    NoticeRow {
      width: parent.width
      visible: root.candidate && (root.candidate.analysis.edgesDisplayOmitted > 0 ||
        root.candidate.analysis.coverageGapsDisplayOmitted > 0)
      reason: "unsupported"
      text: root.candidate ? (root.candidate.analysis.edgesDisplayOmitted > 0 &&
        root.candidate.analysis.coverageGapsDisplayOmitted > 0
        ? "Some invocation edges and coverage gaps are hidden by the UI display limit."
        : (root.candidate.analysis.edgesDisplayOmitted > 0
          ? "Some invocation edges are hidden by the UI display limit."
          : "Some coverage gaps are hidden by the UI display limit.")) : ""
      foreground: root.col("fg")
      dim: root.col("dim")
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.candidate && Object.keys(root.candidate.analysis.coverageStates).length > 0
      textFormat: Text.PlainText
      text: {
        if (!root.candidate) return ""
        var values = []
        var states = root.candidate.analysis.coverageStates
        for (var key in states) values.push(key + ": " + states[key])
        return "Coverage states: " + values.join(" · ")
      }
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Repeater {
      model: root.candidate ? root.candidate.analysis.limitations : []
      delegate: Text {
        required property var modelData
        width: resultColumn.width - Style.space(18)
        x: Style.space(10)
        textFormat: Text.PlainText
        text: "Limitation: " + modelData
        color: root.col("dim")
        font.family: root.col("fontFamily")
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WrapAnywhere
      }
    }

    Repeater {
      model: root.candidate ? root.candidate.analysis.coverageGaps : []
      delegate: Text {
        required property var modelData
        width: resultColumn.width - Style.space(18)
        x: Style.space(10)
        textFormat: Text.PlainText
        text: "Coverage gap: " + (modelData.reason || "unclassified") +
          (modelData.language !== "" ? " · " + modelData.language : "") +
          (modelData.impact !== "" ? " · " + modelData.impact : "") +
          (modelData.displayRelativePath || modelData.relativePath
            ? " · " + (modelData.displayRelativePath || modelData.relativePath) : "") +
          (modelData.line !== "" ? ":" + modelData.line : "") +
          (modelData.detail !== "" ? " · " + modelData.detail : "")
        color: root.col("dim")
        font.family: root.col("fontFamily")
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WrapAnywhere
      }
    }
  }
}
