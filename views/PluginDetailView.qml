import QtQuick
import qs.Commons
import qs.Ui
import "../components"
import "../model/Glyphs.js" as Glyphs
import "../model/Labels.js" as Labels

// Plugin detail sheet (doc 03 §5): TRUST BASELINE · WHAT CHANGED · REVIEW ITEMS ·
// CAPABILITIES OBSERVED · COVERAGE (file references folded in) · MARKETPLACE CLAIM ·
// ENFORCEMENT · PROVENANCE (collapsed), disclosed one level at a time. The authority
// sections and action eligibility come from `panel` helpers (where updateEligible /
// enableEligible live); the analysis sections are mapped here from analysisReport.
Column {
  id: root

  property var panel: null
  readonly property var vm: panel ? panel.vm : null
  readonly property string rf: Style.font.resolvedFamily

  // Filters synthetic hover churn from delegates reflowing under a stationary
  // pointer, so only real pointer motion moves the cursor (Ui/PointerMoveGate.qml).
  PointerMoveGate { id: gate; referenceItem: root }
  readonly property var plugin: (panel && vm && vm.pluginsById) ? vm.pluginsById[panel.selectedPluginId] : null
  readonly property var analysis: panel ? panel.analysisReport : null
  readonly property var status: panel ? panel.statusReport : null

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(12)

  function has(section, index) {
    return panel && panel.cursorActive && panel.focusSection === section && panel.selectedIndex === index
  }
  function col(name) { return panel ? panel[name] : Color.foreground }

  // ---- severity glyph for a review item ----------------------------------------
  function severityGlyphKey(sev) {
    switch (String(sev || "").toLowerCase()) {
      case "info":     return "info"
      case "low":      return "info"
      case "medium":   return "medium"
      case "high":     return "alert"
      case "critical": return "critical"
      default:         return ""   // unsupported: hollow marker / unavailable word
    }
  }
  function severityBold(sev) {
    var s = String(sev || "").toLowerCase()
    return s === "high" || s === "critical"
  }

  // Findings normally carry the catalog severity, but keep the marker useful if
  // an older CLI omits it: resolve the rule's declared default without inventing
  // a plugin verdict.
  function findingSeverity(finding) {
    var direct = String(finding && finding.severity || "").toLowerCase()
    if (direct !== "") return direct
    var rid = String(finding && finding.rule_id || "")
    var rules = root.vm ? root.vm.rules : []
    for (var i = 0; i < rules.length; i++)
      if (String(rules[i].id || "") === rid) return String(rules[i].severity || "")
    return ""
  }

  // Capabilities grouped by class, detected uses desc. Each capability record is
  // one source-level reference; fileCount remains the distinct-file count.
  function capabilityGroups() {
    if (!analysis || !analysis.capabilities) return []
    var by = {}
    var order = []
    for (var i = 0; i < analysis.capabilities.length; i++) {
      var c = analysis.capabilities[i]
      var cls = String(c.capability || "")
      if (cls === "") continue
      if (!by[cls]) { by[cls] = { cls: cls, uses: [], files: ({}) }; order.push(cls) }
      by[cls].uses.push(c)
      by[cls].files[String(c.relative_path || "")] = true
    }
    var out = []
    for (var j = 0; j < order.length; j++) {
      var g = by[order[j]]
      var nFiles = Object.keys(g.files).length
      var risk = "unknown"
      var rules = root.vm ? root.vm.rules : []
      for (var ri = 0; ri < rules.length; ri++) {
        if (String(rules[ri].capability || "") !== g.cls) continue
        if (Labels.severityRank(rules[ri].severity) > Labels.severityRank(risk))
          risk = Labels.severityTier(rules[ri].severity)
      }
      out.push({ cls: g.cls, uses: g.uses, useCount: g.uses.length, fileCount: nFiles, riskLevel: risk })
    }
    out.sort(function(a, b) { return b.useCount - a.useCount })
    return out
  }

  function useLine(use) {
    return String(use.relative_path || "") + ":" + String(use.line || "") + " · "
      + String(use.detail || "") + " · " + Labels.confidence(use.confidence)
  }

  // ---- mutation result / error line (doc 03 §5.5, T2.14) -----------------------
  NoticeRow {
    width: parent.width
    visible: panel && panel.detailStatusLine() !== ""
    reason: (panel && panel.detailStatusIsError()) ? "unavailable" : "none"
    cliFailure: panel && panel.detailStatusIsError()
    text: panel ? panel.detailStatusLine() : ""
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }

  // ---- TRUST BASELINE ----------------------------------------------------------
  Column {
    width: parent.width
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "TRUST BASELINE"
      foreground: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    NoticeRow {
      width: parent.width
      visible: !root.status
      reason: "loading"
      text: "Checking baseline…"
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: !!root.status
      textFormat: Text.PlainText
      text: root.status ? Labels.trustState(root.status.state, root.status.reason,
        (root.status.changed_files ? root.status.changed_files.length : 0)) : ""
      color: root.col("fg")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.body
      wrapMode: Text.WordWrap
    }

    InfoGrid {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: !!root.status && !!root.status.current
      rows: panel ? panel.trustIdentityRows() : []
      labelWidth: Style.space(72)
      foreground: root.col("fg"); labelColor: root.col("dim")
      fontFamily: root.col("fontFamily")
      onCopyRequested: function(v) { if (panel) panel.copyValue(v) }
    }

    ActionRow {
      width: parent.width
      actions: panel ? panel.trustActionModel() : []
      condition: panel ? panel.trustCondition() : ""
      cursorIndex: (panel && panel.focusSection === "trust-actions") ? panel.selectedIndex : -1
      foreground: root.col("fg"); faint: root.col("faint"); dim: root.col("dim")
      locked: panel && panel.navigationLocked
      fontFamily: root.col("fontFamily")
      onTriggered: function(i) { if (panel) panel.trustActionTriggered(i) }
      onHovered: function(i, h) { if (h && panel) panel.hoverCursor("trust-actions", i) }
    }
  }

  // ---- WHAT CHANGED (state == changed) -----------------------------------------
  Column {
    width: parent.width
    visible: !!root.status && String(root.status.state) === "changed"
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "WHAT CHANGED"
      value: (panel && panel.diffReport && panel.diffReport.changed_files)
        ? (panel.diffReport.changed_files.length + " FILES") : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    Repeater {
      model: (panel && panel.diffReport && panel.diffReport.changed_files)
        ? panel.diffReport.changed_files.slice(0, 5) : []
      delegate: Text {
        required property var modelData
        width: parent.width - Style.space(18); x: Style.space(10)
        textFormat: Text.PlainText
        text: String(modelData)
        color: root.col("dim")
        font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
        elide: Text.ElideMiddle
      }
    }
  }

  // ---- REVIEW ITEMS ------------------------------------------------------------
  // Always visible for a selected plugin so the explicit "not analyzed" state and its
  // Analyze button render even before any analysis (doc 03 §5.2, §11).
  Column {
    width: parent.width
    visible: !!root.plugin
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "REVIEW ITEMS"
      value: (root.analysis && root.analysis.findings) ? String(root.analysis.findings.length) : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    NoticeRow {
      width: parent.width
      visible: panel && panel.analysisLoading && !root.analysis
      reason: "loading"; text: "Loading analysis…"
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    NoticeRow {
      width: parent.width
      visible: !root.analysis && !(panel && panel.analysisLoading) && panel && panel.analysisError === ""
      reason: "none"; text: "Not analyzed. Press a or Analyze."
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    Button {
      x: Style.space(30)
      visible: !root.analysis && !(panel && panel.analysisLoading)
      text: "Analyze"; bordered: true
      enabled: panel && !panel.navigationLocked
      foreground: root.col("fg"); fontFamily: root.col("fontFamily")
      tooltipText: "Analyze (a)"
      onClicked: if (panel) panel.analyzeSelected()
    }

    NoticeRow {
      width: parent.width
      visible: panel && panel.analysisError !== "" && !root.analysis
      reason: "unavailable"; cliFailure: true
      text: "Analysis unavailable: " + (panel ? panel.analysisError : "") + "."
      foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    Repeater {
      model: (root.analysis && root.analysis.findings) ? root.analysis.findings : []
      delegate: EvidenceRow {
        required property var modelData
        required property int index
        width: parent.width
        severityGlyph: { var k = root.severityGlyphKey(root.findingSeverity(modelData)); return k !== "" ? Glyphs.ui_(k, root.rf) : "" }
        severityLevel: Labels.severityTier(root.findingSeverity(modelData))
        titleBold: root.severityBold(root.findingSeverity(modelData))
        title: String(modelData.title || "")
        subtitle: String(modelData.rule_id || "") + " · " + String(modelData.relative_path || "") + ":" + String(modelData.line || "")
        expanded: panel && panel.expandedFindingKey === (panel ? panel.findingKey(modelData) : "")
        severityWord: Labels.severity(root.findingSeverity(modelData)) + " · catalog severity"
        confidenceWord: Labels.confidence(modelData.confidence)
        evidenceText: String(modelData.evidence || "")
        explanation: String(modelData.explanation || "")
        reviewGuidance: String(modelData.review_guidance || "")
        hasCursor: root.has("review", index)
        foreground: root.col("fg"); dim: root.col("dim"); urgentColor: root.col("urgent")
        fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
        onToggleRequested: if (panel) panel.toggleFinding(panel.findingKey(modelData))
        onOpenRuleRequested: if (panel) panel.openRuleFromReview(String(modelData.rule_id || ""))
        onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
        MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
          onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("review", index) } }
      }
    }
  }

  // ---- CAPABILITIES OBSERVED ---------------------------------------------------
  Column {
    id: capsSection
    width: parent.width
    visible: !!root.analysis
    spacing: Style.space(6)
    readonly property var groups: root.capabilityGroups()

    SectionHeaderRow {
      text: "CAPABILITIES OBSERVED"
      value: capsSection.groups.length > 0
        ? ((root.analysis && root.analysis.capabilities ? root.analysis.capabilities.length : 0) + " · " + capsSection.groups.length + " CLASSES")
        : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    NoticeRow {
      width: parent.width
      visible: capsSection.groups.length === 0
      reason: "none"; text: "No capabilities observed in analyzed files."
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    Repeater {
      model: capsSection.groups
      delegate: ClassRow {
        required property var modelData
        required property int index
        width: parent.width
        glyph: Glyphs.cap(modelData.cls, root.rf)
        name: Labels.capability(modelData.cls)
        riskLevel: modelData.riskLevel
        usesText: modelData.useCount + (modelData.useCount === 1 ? " use · " : " uses · ") + modelData.fileCount + (modelData.fileCount === 1 ? " file" : " files")
        expanded: panel && panel.expandedClass === modelData.cls
        uses: {
          if (!(panel && panel.expandedClass === modelData.cls)) return []
          var show = panel.classShowAll === modelData.cls ? modelData.uses.length : Math.min(3, modelData.uses.length)
          var arr = []
          for (var i = 0; i < show; i++) arr.push(root.useLine(modelData.uses[i]))
          return arr
        }
        moreCount: (panel && panel.expandedClass === modelData.cls && panel.classShowAll !== modelData.cls)
          ? Math.max(0, modelData.uses.length - 3) : 0
        hasCursor: root.has("classes", index)
        foreground: root.col("fg"); dim: root.col("dim")
        fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
        onToggleRequested: if (panel) panel.toggleClass(modelData.cls)
        onMoreRequested: if (panel) panel.classShowAll = modelData.cls
        onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
        MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
          onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("classes", index) } }
      }
    }
  }

  // ---- COVERAGE ----------------------------------------------------------------
  Column {
    id: coverageSection
    width: parent.width
    visible: !!root.analysis
    spacing: Style.space(6)
    readonly property var limitLines: (root.analysis && root.analysis.coverage_limitations)
      ? Labels.groupLimitations(root.analysis.coverage_limitations) : []
    readonly property var edges: (root.analysis && root.analysis.invocation_edges) ? root.analysis.invocation_edges : []

    SectionHeaderRow {
      text: "COVERAGE"
      value: {
        if (!root.analysis) return ""
        if (!Array.isArray(root.analysis.coverage_limitations)) return ""
        var n = root.analysis.coverage_limitations.length
        return n > 0 ? (n + (n === 1 ? " LIMIT" : " LIMITS")) : "NO LIMITS REPORTED"
      }
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    // lexical-only notice, always first when parser == null.
    NoticeRow {
      width: parent.width
      visible: root.analysis && (root.analysis.parser === null || root.analysis.parser === undefined)
      reason: "lexical-only"
      text: "Lexical-only analysis (no QML parser). Review items are text matches."
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    Repeater {
      model: coverageSection.limitLines
      delegate: Text {
        required property var modelData
        width: parent.width - Style.space(38); x: Style.space(30)
        textFormat: Text.PlainText
        text: String(modelData)
        color: root.col("dim")
        font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }

    // File references sub-row (collapsed).
    SourceRow {
      width: parent.width
      visible: coverageSection.edges.length > 0
      label: coverageSection.edges.length + " file references"
      expandable: true
      expanded: panel && panel.coverageFileRefsExpanded
      hasCursor: root.has("coverage", 0)
      foreground: root.col("fg"); dim: root.col("dim"); faint: root.col("faint")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
      onToggleRequested: if (panel) panel.toggleCoverageFileRefs()
      onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
      MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
        onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("coverage", 0) } }
    }

    Repeater {
      model: (panel && panel.coverageFileRefsExpanded) ? coverageSection.edges : []
      delegate: EdgeRow {
        required property var modelData
        width: parent.width
        text: String(modelData.from_path || "") + " ─▶ " + String(modelData.target_path || "")
        tooltipText: String(modelData.from_path || "") + ":" + String(modelData.line || "")
        dim: root.col("dim")
        fontFamily: root.col("fontFamily")
      }
    }

    // Parser row.
    Text {
      width: parent.width - Style.space(38); x: Style.space(30)
      visible: !!root.analysis
      textFormat: Text.PlainText
      text: root.analysis && root.analysis.parser
        ? ("parser " + String(root.analysis.parser.grammar || root.analysis.parser) + " " + String(root.analysis.parser.grammar_version || ""))
        : "parser none"
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
    }
  }

  // ---- MARKETPLACE CLAIM -------------------------------------------------------
  Column {
    width: parent.width
    visible: !!root.plugin
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "MARKETPLACE CLAIM"
      value: panel ? panel.claimHeaderValue() : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    Repeater {
      model: panel ? panel.claimRows() : []
      delegate: Text {
        required property var modelData
        width: parent.width - Style.space(18); x: Style.space(10)
        textFormat: Text.PlainText
        text: String(modelData)
        color: root.col("fg")
        font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }

    ActionRow {
      width: parent.width
      actions: panel ? panel.claimActionModel() : []
      condition: panel ? panel.claimCondition() : ""
      cursorIndex: (panel && panel.focusSection === "claim-actions") ? panel.selectedIndex : -1
      foreground: root.col("fg"); faint: root.col("faint"); dim: root.col("dim")
      locked: panel && panel.navigationLocked
      fontFamily: root.col("fontFamily")
      onTriggered: function(i) { if (panel) panel.claimActionTriggered(i) }
      onHovered: function(i, h) { if (h && panel) panel.hoverCursor("claim-actions", i) }
    }
  }

  // ---- ENFORCEMENT -------------------------------------------------------------
  Column {
    width: parent.width
    visible: !!root.plugin
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "ENFORCEMENT"
      value: panel ? panel.enforcementHeaderValue() : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    Repeater {
      model: panel ? panel.enforcementRows() : []
      delegate: Text {
        required property var modelData
        width: parent.width - Style.space(18); x: Style.space(10)
        textFormat: Text.PlainText
        text: String(modelData)
        color: root.col("dim")
        font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }

    ActionRow {
      width: parent.width
      actions: panel ? panel.enforcementActionModel() : []
      condition: panel ? panel.enforcementCondition() : ""
      cursorIndex: (panel && panel.focusSection === "enforcement") ? panel.selectedIndex : -1
      foreground: root.col("fg"); faint: root.col("faint"); dim: root.col("dim")
      locked: panel && panel.navigationLocked
      fontFamily: root.col("fontFamily")
      onTriggered: function(i) { if (panel) panel.enforcementActionTriggered(i) }
      onHovered: function(i, h) { if (h && panel) panel.hoverCursor("enforcement", i) }
    }
  }

  // ---- PROVENANCE (collapsed) --------------------------------------------------
  Column {
    width: parent.width
    visible: !!root.analysis
    spacing: Style.space(6)

    SourceRow {
      width: parent.width
      label: "PROVENANCE"
      expandable: true
      expanded: panel && panel.provenanceExpanded
      hasCursor: root.has("provenance", 0)
      foreground: root.col("dimHeader"); dim: root.col("dim"); faint: root.col("faint")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
      onToggleRequested: if (panel) panel.toggleProvenance()
      onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
      MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
        onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("provenance", 0) } }
    }

    InfoGrid {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: panel && panel.provenanceExpanded
      rows: panel ? panel.provenanceRows() : []
      labelWidth: Style.space(88)
      foreground: root.col("fg"); labelColor: root.col("dim")
      fontFamily: root.col("fontFamily")
      onCopyRequested: function(v) { if (panel) panel.copyValue(v) }
    }
  }
}
