import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../components"
import "../model/Glyphs.js" as Glyphs
import "../model/Labels.js" as Labels

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

    // ---- result band (doc 08 §5.4) ---------------------------------------------
    //
    // Above the install command and above the 32 finding blocks, so the reader's
    // first sweep lands on the distribution rather than on an action. Every chart
    // here has its exact counts printed immediately beneath it: delete the chart and
    // the reader loses speed, never information (CH1).

    SectionHeaderRow {
      text: "FINDINGS"
      value: root.candidate ? String(root.candidate.summary.severityTotal) : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    MeterBar {
      width: parent.width - Style.space(18); x: Style.space(10)
      segments: root.candidate ? root.candidate.summary.severityRows : []
      total: root.candidate ? root.candidate.summary.severityTotal : 0
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily")
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: root.candidate ? root.candidate.summary.severityCountsText : ""
      color: root.col("fg")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    // The parts reconcile, visibly, and the line prints whether or not a term is
    // non-zero (CH5) — a summary whose parts only sometimes add up stops being read.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: root.candidate ? root.candidate.summary.reconciliation.findings.text : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    // The severity rows account for every finding only when each one carried a
    // severity the panel recognises. Where they do not, say so rather than let the
    // bar quietly come up short of its own header.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: root.candidate && !root.candidate.summary.severityReconciles
      textFormat: Text.PlainText
      text: "Some findings carry a severity this panel does not recognise; the bar is short of the total."
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    // "33 findings" and "one rule, 33 times" are different reviews. This is the block
    // that tells them apart.
    SectionHeaderRow {
      text: "BY RULE"
      value: root.candidate ? String(root.candidate.summary.ruleRows.length) : ""
      visible: root.candidate && root.candidate.summary.ruleRows.length > 0
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    RankedBars {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: root.candidate && root.candidate.summary.ruleRows.length > 0
      rows: root.candidate ? root.candidate.summary.ruleRows : []
      total: root.candidate ? root.candidate.summary.ruleTotal : 0
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily")
    }

    // The same 17-cell catalog strip an installed plugin shows, so a candidate and an
    // installed plugin are read the same way — but built on UnitStrip, not
    // CapabilityStrip, because a candidate's capability list is not guaranteed
    // complete and `·` is a claim that has to be earned.
    SectionHeaderRow {
      text: "CAPABILITIES"
      value: root.candidate
        ? (root.candidate.summary.capabilityCountsText +
           (root.candidate.summary.capabilitiesComplete ? "" : " · PARTIAL")) : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    UnitStrip {
      width: parent.width - Style.space(18); x: Style.space(10)
      cells: {
        var out = []
        var cells = root.candidate ? root.candidate.summary.capabilityCells : []
        for (var i = 0; i < cells.length; i++) {
          var name = Labels.capability(cells[i].key)
          out.push({
            key: cells[i].key,
            glyph: Glyphs.cap(cells[i].key, root.rf),
            level: cells[i].level,
            tooltip: cells[i].level === "observed"
              ? name + " · " + cells[i].count + (cells[i].count === 1 ? " use" : " uses")
              : (cells[i].level === "none" ? name + " · none observed" : name + " · no data")
          })
        }
        return out
      }
      foreground: root.col("fg"); dim: root.col("dim"); accent: Color.accent
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: root.candidate && root.candidate.summary.capabilityObserved.length > 0
      textFormat: Text.PlainText
      text: {
        if (!root.candidate) return ""
        var parts = []
        var observed = root.candidate.summary.capabilityObserved
        for (var i = 0; i < observed.length; i++)
          parts.push(Labels.capability(observed[i].cls) + " " + observed[i].count)
        return parts.join(" · ")
      }
      color: root.col("fg")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    // The parts reconcile, visibly, and the line prints whether or not a term is
    // non-zero (CH5) — a summary whose parts only sometimes add up stops being read.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: root.candidate ? root.candidate.summary.reconciliation.capabilities.text : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    NoticeRow {
      width: parent.width
      visible: root.candidate && root.candidate.summary.capabilityObserved.length === 0 &&
        root.candidate.summary.capabilitiesComplete
      reason: "none"
      text: "No capability uses were observed under this scan's reported coverage."
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    // 23 of 66 payload entries analysed is the strongest argument against trusting an
    // empty finding list, so it is the second thing the reader sees, not the last.
    SectionHeaderRow {
      text: "COVERAGE"
      value: root.candidate && root.candidate.summary.coverageAvailable
        ? ((root.candidate.summary.coverageAssessment !== ""
            ? root.candidate.summary.coverageAssessment.toUpperCase() + " · " : "") +
           root.candidate.summary.coverageTotal + " PAYLOAD ENTRIES")
        : "UNAVAILABLE"
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    MeterBar {
      width: parent.width - Style.space(18); x: Style.space(10)
      available: root.candidate && root.candidate.summary.coverageAvailable
      segments: root.candidate ? root.candidate.summary.coverageRows : []
      total: root.candidate ? root.candidate.summary.coverageTotal : 0
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily")
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: root.candidate && root.candidate.summary.coverageAvailable
        ? root.candidate.summary.coverageCountsText
        : "unavailable — this report carries no payload coverage summary."
      color: root.col("fg")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: root.candidate && root.candidate.summary.coverageAvailable &&
        !root.candidate.summary.coverageReconciles
      textFormat: Text.PlainText
      text: "The coverage states do not sum to the payload entry total; the bar is incomplete."
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: root.candidate
        ? (root.candidate.analysis.coverageGapsTotal +
           (root.candidate.analysis.coverageGapsTotal === 1 ? " coverage gap · " : " coverage gaps · ") +
           root.candidate.analysis.limitations.length +
           (root.candidate.analysis.limitations.length === 1 ? " limitation" : " limitations")) : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    // ONE notice for every collection, raised only when a term is non-zero. The
    // per-collection arithmetic above is printed always; this says what it means.
    NoticeRow {
      width: parent.width
      visible: root.candidate && root.candidate.summary.reconciliationNotice !== ""
      reason: "unsupported"
      text: root.candidate ? root.candidate.summary.reconciliationNotice : ""
      foreground: root.col("fg")
      dim: root.col("dim")
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
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
      text: "FINDING DETAIL"
      value: root.candidate ? String(root.candidate.analysis.findings.length) : ""
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
      text: "CAPABILITY USES"
      value: root.candidate ? String(root.candidate.analysis.capabilities.length) : ""
      foreground: root.col("dimHeader")
      valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
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
      value: root.candidate
        ? (root.candidate.analysis.edgesTotal + " EDGES · " +
           root.candidate.analysis.coverageGapsTotal + " GAPS") : ""
      foreground: root.col("dimHeader")
      valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }


    // The parts reconcile, visibly, and the line prints whether or not a term is
    // non-zero (CH5) — a summary whose parts only sometimes add up stops being read.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: root.candidate ? "Invocation edges — " + root.candidate.summary.reconciliation.edges.text : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    // The parts reconcile, visibly, and the line prints whether or not a term is
    // non-zero (CH5) — a summary whose parts only sometimes add up stops being read.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      textFormat: Text.PlainText
      text: root.candidate ? "Coverage gaps — " + root.candidate.summary.reconciliation.coverageGaps.text : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    SectionHeaderRow {
      text: "OPAQUE EXECUTABLES"
      value: root.candidate ? String(root.candidate.analysis.codeExposureTotal) : ""
      visible: root.candidate && root.candidate.analysis.codeExposureTotal > 0
      foreground: root.col("dimHeader")
      valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    Text {
      width: parent.width - Style.space(18)
      x: Style.space(10)
      visible: root.candidate && root.candidate.analysis.codeExposureTotal > 0
      textFormat: Text.PlainText
      text: "Opaque executable files are not behaviorally analyzed. Review status is evidence for the exact file digest, not a safety verdict."
      color: root.col("dim")
      font.family: root.col("fontFamily")
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Repeater {
      model: root.candidate ? root.candidate.analysis.codeExposure : []
      delegate: Text {
        required property var modelData
        width: resultColumn.width - Style.space(18)
        x: Style.space(10)
        textFormat: Text.PlainText
        text: String(modelData.relativePath || "unavailable") + " · " +
          String(modelData.nativeFormat || "opaque-executable") + " · " +
          String(modelData.exposure || "unknown") + " · review " +
          String(modelData.reviewStatus || "unreviewed") + " · " +
          (modelData.exactSha256 !== ""
            ? "sha256 " + String(modelData.exactSha256).slice(0, 16) + "…"
            : String(modelData.digestState || "unavailable"))
        color: root.col("dim")
        font.family: root.col("fontFamily")
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WrapAnywhere
      }
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
