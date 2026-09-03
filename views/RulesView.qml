import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../components"
import "../model/Glyphs.js" as Glyphs
import "../model/Labels.js" as Labels

// Rules view (doc 03 §7): RULE CATALOG over a capped ListView of RuleRows that expand
// into the rule sheet, and the BASELINE V3 COVERAGE table of RelationRows. Binds to
// panel.vm; the expanded rule's `rules explain` relations come from panel.ruleExplanation.
Column {
  id: root

  property var panel: null
  readonly property var vm: panel ? panel.vm : null
  readonly property string rf: Style.font.resolvedFamily

  PointerMoveGate { id: gate; referenceItem: root }

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(12)

  readonly property bool cliVerified: panel && panel.cliVerified
  function col(name) { return panel ? panel[name] : Color.foreground }
  function has(section, index) {
    return panel && panel.cursorActive && panel.focusSection === section && panel.selectedIndex === index
  }

  // Map the currently-explained rule's external_equivalences into RelationRow data.
  function relationsFor(ruleId) {
    if (!panel || panel.expandedRuleId !== ruleId) return []
    var ex = panel.ruleExplanationResult && panel.ruleExplanationResult.external_equivalences
      ? panel.ruleExplanationResult.external_equivalences : []
    var out = []
    for (var i = 0; i < ex.length; i++) {
      var rel = String(ex[i].relation || "")
      out.push({
        mark: rel === "structural-equivalent" ? "=" : (rel === "partial-overlap" ? "≈" : ""),
        externalId: String(ex[i].externalId || ""),
        relationWord: Labels.relation(ex[i].relation)
      })
    }
    return out
  }

  // ---- CLI unavailable ---------------------------------------------------------
  NoticeRow {
    width: parent.width
    visible: !root.cliVerified
    reason: "unavailable"
    text: "Plugins, review items, rules and the trust flow are unavailable until omasafe-cli 0.2.1 or newer is found on PATH."
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }

  // ---- RULE CATALOG ------------------------------------------------------------
  Column {
    width: parent.width
    visible: root.cliVerified
    spacing: Style.space(6)

    SectionHeaderRow {
      text: "RULE CATALOG"
      value: (panel && panel.rulesListReport && root.vm)
        ? ("V" + root.vm.ruleCatalogVersion + " · " + root.vm.ruleCount + " RULES") : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    NoticeRow {
      width: parent.width
      visible: panel && panel.rulesListLoading && (!root.vm || root.vm.ruleCount === 0)
      reason: "loading"; text: "Loading rules…"
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }
    NoticeRow {
      width: parent.width
      visible: panel && panel.rulesListError !== "" && (!root.vm || root.vm.ruleCount === 0)
      reason: "unavailable"; cliFailure: true
      text: "Rules unavailable: " + (panel ? panel.rulesListError : "") + "."
      foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    ListView {
      id: rulesList
      width: parent.width
      height: Math.min(contentHeight, Style.space(400))
      interactive: contentHeight > height
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      currentIndex: (panel && panel.focusSection === "rules") ? panel.selectedIndex : -1
      onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      model: root.vm ? root.vm.rules : []
      delegate: RuleRow {
        required property var modelData
        required property int index
        width: rulesList.width
        glyph: Glyphs.cap(modelData.capability, root.rf)
        title: modelData.title
        idLine: modelData.id + " · " + modelData.language + " · " + modelData.severity
        severity: modelData.severityLevel
        noLocalHits: modelData.noLocalHits
        analysisComplete: modelData.analysisComplete
        rowHitText: modelData.rowHitText
        expanded: panel && panel.expandedRuleId === modelData.id
        summary: modelData.summary
        anchorText: modelData.surfaceAnchor
        reviewGuidance: modelData.reviewGuidance
        localHitsHeader: modelData.hitText
        hits: {
          var arr = []
          for (var i = 0; i < modelData.hits.length; i++) {
            var h = modelData.hits[i]
            arr.push({ pluginId: h.pluginId, occLine: Labels.occurrences(h.occurrences) + h.limitsText + h.lexicalText })
          }
          return arr
        }
        notAnalyzed: modelData.notAnalyzed
        relationsLoading: panel && panel.expandedRuleId === modelData.id && panel.ruleExplanationLoading
        relationsError: (panel && panel.expandedRuleId === modelData.id) ? panel.ruleExplanationError : ""
        baselineHeader: (panel && panel.expandedRuleId === modelData.id && root.vm)
          ? (root.relationsFor(modelData.id).length + " ROWS · MAP " + root.vm.baseline.mapVersion) : ""
        relations: root.relationsFor(modelData.id)
        hasCursor: root.has("rules", index)
        foreground: root.col("fg"); dim: root.col("dim")
        fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
        onToggleRequested: if (panel) panel.expandRule(modelData.id)
        onOpenHit: function(pid) { if (panel) panel.openPluginFromRule(pid) }
        onOpenRelation: function(xid) { if (panel) panel.jumpToBaseline(xid) }
        MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
          onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("rules", index) } }
      }
    }
  }

  // ---- BASELINE V3 COVERAGE ----------------------------------------------------
  Column {
    id: baselineSection
    width: parent.width
    visible: root.cliVerified
    spacing: Style.space(6)
    readonly property var b: root.vm ? root.vm.baseline : null

    SectionHeaderRow {
      text: "BASELINE V3 COVERAGE"
      value: (baselineSection.b && baselineSection.b.available)
        ? (baselineSection.b.partialCount + " PARTIAL · " + baselineSection.b.notCoveredCount + " NOT COVERED") : ""
      foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
      fontFamily: root.col("fontFamily")
    }

    NoticeRow {
      width: parent.width
      visible: panel && panel.coverageLoading && !(baselineSection.b && baselineSection.b.available)
      reason: "loading"; text: "Loading coverage map…"
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }
    NoticeRow {
      width: parent.width
      visible: panel && panel.coverageError !== "" && !(baselineSection.b && baselineSection.b.available)
      reason: "unavailable"; cliFailure: true
      text: "Coverage map unavailable: " + (panel ? panel.coverageError : "") + "."
      foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
    }

    // Attribution header lines.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: baselineSection.b && baselineSection.b.available
      textFormat: Text.PlainText
      text: baselineSection.b ? baselineSection.b.headerLine : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: baselineSection.b && baselineSection.b.available
      textFormat: Text.PlainText
      text: baselineSection.b ? baselineSection.b.headerSentence : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Repeater {
      model: (baselineSection.b && baselineSection.b.available) ? baselineSection.b.rows : []
      delegate: RelationRow {
        required property var modelData
        required property int index
        width: parent.width
        mark: modelData.relationMark
        externalId: modelData.externalId
        line2: modelData.line2
        covered: modelData.covered
        expanded: panel && panel.expandedBaselineId === modelData.externalId
        coveringRules: modelData.coveringRules
        note: modelData.note
        hasCursor: root.has("baseline", index)
        foreground: root.col("fg"); dim: root.col("dim")
        fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
        onToggleRequested: if (panel) panel.toggleBaseline(modelData.externalId)
        onOpenRule: function(rid) { if (panel) panel.openRuleFromReview(rid) }
        onHasCursorChanged: if (hasCursor && panel) panel.ensureCursorVisible(this)
        MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
          onPositionChanged: function(mouse) { if (gate.moved(this, mouse) && panel) panel.hoverCursor("baseline", index) } }
      }
    }

    // Not-covered footer.
    Text {
      width: parent.width - Style.space(18); x: Style.space(10)
      visible: baselineSection.b && baselineSection.b.available && baselineSection.b.notCoveredFooter !== ""
      textFormat: Text.PlainText
      text: baselineSection.b ? baselineSection.b.notCoveredFooter : ""
      color: root.col("dim")
      font.family: root.col("fontFamily"); font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
  }
}
