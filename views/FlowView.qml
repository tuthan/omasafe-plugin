import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../components"
import "../graph"

// Flow view (doc 04 §6, §9, §10.1): the section header (TRUST FLOW · scope · counts),
// a breadcrumb at Z1/Z2, the lens ButtonGroup with the ? legend in its right slot, the
// graph body (TrustFlow), and the fixed InspectorStrip. All Flow state — layout,
// cursor, depth, lens, queue — lives on panel (the root); this view is a thin
// presenter that binds to it and pushes back its body width and row budget.
Column {
  id: root

  property var panel: null
  readonly property var vm: panel ? panel.vm : null
  readonly property string rf: Style.font.resolvedFamily
  readonly property real rowH: Style.spacing.popupRowHeight

  function col(name) { return panel ? panel[name] : Color.foreground }
  readonly property bool cliVerified: panel && panel.cliVerified

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(10)

  // Push the graph body width and the row budget back to the root, which owns the
  // layout (§10.1). openW and maxRows are derived from these.
  Binding { target: root.panel; property: "flowBodyWidth"; value: root.width; when: !!root.panel }
  Binding {
    target: root.panel; property: "flowMaxRows"; when: !!root.panel
    value: {
      if (!root.panel) return 10
      var fixed = Style.space(20) + Style.space(12)      // section header + gap
        + Style.space(34) + Style.space(12)              // lens row + gap
        + Style.space(84) + Style.space(12)              // inspector (separator + 4 lines) + gap
      if (root.panel.flowDepth >= 1) fixed += Style.space(20) + Style.space(10)   // breadcrumb
      if (subtitle.visible) fixed += subtitle.implicitHeight + Style.space(6)     // legend line (T4.1)
      if (incompleteNotice.visible) fixed += Style.space(20) + Style.space(12)    // incomplete callout
      if (lexicalNotice.visible) fixed += Style.space(20) + Style.space(12)
      var avail = root.panel.flowViewportHeightMax - fixed
      return Math.max(1, Math.floor(avail / root.rowH))
    }
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

  // ---- section header ----------------------------------------------------------
  SectionHeaderRow {
    visible: root.cliVerified
    text: panel ? panel.flowHeaderText() : "ANALYSIS PATHS"
    value: panel ? panel.flowHeaderValue() : ""
    foreground: root.col("dimHeader"); valueColor: root.col("dimHeader")
    fontFamily: root.col("fontFamily")
  }

  // ---- plain-language legend under the heading (T4.1) --------------------------
  // Names the four stages in order so the PL / CA / RU / BA rails read as a chain, not
  // an unexplained abbreviation. Hidden in Trace (its own chain replaces it).
  Text {
    id: subtitle
    width: parent.width
    visible: root.cliVerified && (!panel || panel.flowLens !== "trace")
    text: panel ? panel.flowSubtitle() : ""
    textFormat: Text.PlainText
    wrapMode: Text.WordWrap
    color: root.col("dim")
    font.family: root.col("fontFamily")
    font.pixelSize: Style.font.bodySmall
  }

  // ---- incomplete-analysis callout (T4.1) --------------------------------------
  // Absent paths are unanalyzed plugins, not absent capabilities; say so persistently.
  NoticeRow {
    id: incompleteNotice
    width: parent.width
    visible: root.cliVerified && panel && panel.flowLens !== "trace" && panel.flowIncompleteText() !== ""
    reason: "none"
    text: panel ? panel.flowIncompleteText() : ""
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }

  // ---- lexical-only notice (persistent while parser == null in scope) -----------
  NoticeRow {
    id: lexicalNotice
    width: parent.width
    visible: root.cliVerified && panel && panel.flowLayoutObj
      && panel.buildFlowInputData().lexicalOnlyCount > 0
    reason: "unsupported"
    text: {
      var n = (panel && panel.flowLayoutObj) ? panel.buildFlowInputData().lexicalOnlyCount : 0
      return n + " analyzed plugins used lexical-only analysis; affected edges are dashed."
    }
    foreground: root.col("fg"); dim: root.col("dim"); urgent: root.col("urgent")
    fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
  }

  // ---- lens row: [Graph] [Matrix] on the left, ? legend on the right -----------
  Item {
    width: parent.width
    height: Style.space(34)
    visible: root.cliVerified && (!panel || panel.flowLens !== "trace")

    ButtonGroup {
      id: lensChips
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      options: [{ value: "graph", label: "Graph" }, { value: "matrix", label: "Matrix" }]
      value: panel ? (panel.flowLens === "matrix" ? "matrix" : "graph") : "graph"
      focusable: false
      cursorIndex: (panel && panel.cursorActive && panel.focusSection === "lens")
        ? panel.selectedIndex : -1
      fontSize: Style.font.bodySmall
      foreground: root.col("fg"); fontFamily: root.col("fontFamily")
      onChanged: function(v) { if (panel) { panel.flowLens = v; panel.rebuildFlow() } }
      onHovered: function(index, isHovered) { if (isHovered && panel) panel.hoverCursor("lens", 0) }
    }

    PanelActionButton {
      id: legendButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      iconText: "?"
      tooltipText: "Legend"
      foreground: root.col("dim"); hoverColor: root.col("fg")
      fontFamily: root.col("fontFamily")
      onClicked: if (panel) panel.flowLegendVisible = !panel.flowLegendVisible
    }

    // The ? legend (doc 04 T3.12): one PanelToolTip listing glyphs, edge styles, keys.
    PanelToolTip {
      parent: legendButton
      visible: panel && panel.flowLegendVisible
      text: panel ? panel.flowLegendText() : ""
      fontFamily: root.col("fontFamily")
      delay: 0
      x: -width + legendButton.width
      y: legendButton.height + Style.space(4)
    }
  }

  // ---- breadcrumb at Z1 / Z2 (the way back) ------------------------------------
  Breadcrumb {
    width: parent.width
    visible: root.cliVerified && panel && (panel.flowDepth >= 1 || panel.flowLens === "trace")
    label: (panel && panel.flowLens === "trace" && panel.flowTracePlugin !== "")
      ? (panel.flowTracePlugin + " › " + panel.flowTraceClass)
      : "All plugins"
    foreground: root.col("fg"); dim: root.col("dim")
    fontFamily: root.col("fontFamily")
    onBackRequested: if (panel) panel.popDepth()
  }

  // ---- the lens body: graph (TrustFlow) · matrix (MatrixGrid) · trace (TraceChain)
  Loader {
    id: lensBody
    width: parent.width
    visible: root.cliVerified
    active: root.cliVerified
    sourceComponent: (panel && panel.flowLens === "matrix") ? matrixComp
      : ((panel && panel.flowLens === "trace") ? traceComp : graphComp)
    height: {
      if (!panel) return Style.space(120)
      if (panel.flowLens === "graph")
        return (panel.flowGeometry.rows * root.rowH) + (panel.flowGeometry.headerH || Style.space(20))
      return item ? item.implicitHeight : Style.space(120)
    }
  }

  Component {
    id: matrixComp
    MatrixGrid {
      panel: root.panel
      model: root.panel ? root.panel.flowMatrixModel() : ({ columns: [], rows: [] })
      cursorRow: root.panel ? root.panel.selectedIndex : -1
      cursorCol: root.panel ? root.panel.flowMatrixCol : -1
      focused: root.panel && root.panel.cursorActive && root.panel.focusSection === "matrix"
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
      fg: root.col("fg"); dimColor: root.col("dim"); dimHeaderColor: root.col("dimHeader")
      urgentColor: root.col("urgent")
    }
  }

  Component {
    id: traceComp
    TraceChain {
      panel: root.panel
      fontFamily: root.col("fontFamily"); resolvedFamily: root.rf
      fg: root.col("fg"); dimColor: root.col("dim"); dimHeaderColor: root.col("dimHeader")
    }
  }

  Component {
    id: graphComp
    Item {
    id: graphBody
    // The Loader sizes this item; TrustFlow fills it.
    TrustFlow {
      id: trustFlow
      anchors.fill: parent
      nodes: panel ? panel.flowNodes : [[], [], [], []]
      geometry: panel ? panel.flowGeometry : ({ headerH: 0, rowH: 0, rows: 0, cols: [] })
      paths: panel ? panel.flowPaths : ({})
      hotKeys: panel ? panel.flowHotKeys : ({})
      focusSection: panel ? panel.focusSection : ""
      selectedIndex: panel ? panel.selectedIndex : -1
      pinnedKey: panel ? panel.flowPinnedKey : ""
      fontFamily: root.col("fontFamily")
      resolvedFamily: root.rf
      fg: root.col("fg")
      urgentColor: root.col("urgent")
      dimColor: root.col("dim")
      faintColor: root.col("faint")
      dimHeaderColor: root.col("dimHeader")
      onCursorRequested: function(c, i) { if (panel) panel.hoverCursor("col-" + c, i) }
      onActivated: function(c, i) {
        if (!panel) return
        panel.cursorActive = true; panel.focusSection = "col-" + c; panel.selectedIndex = i
        panel.flowCol = c; panel.activateCursor()
      }
      onWheelRequested: function(c, steps) {
        if (!panel) return
        var offs = panel.flowOffsets.slice()
        offs[c] = Math.max(0, (offs[c] || 0) + steps)
        panel.flowOffsets = offs
        panel.relayoutFlow()
      }
    }
    }
  }

  // ---- inspector strip ---------------------------------------------------------
  InspectorStrip {
    width: parent.width
    visible: root.cliVerified
    facts: panel ? panel.flowInspectorFacts() : ({ title: "", lines: [], action: "", actionEnabled: false })
    actionHasCursor: panel && panel.cursorActive && panel.focusSection === "inspector-actions"
    fontFamily: root.col("fontFamily")
    fg: root.col("fg")
    dim: root.col("dim")
    onActionClicked: if (panel) panel.flowInspectorAction()
  }
}
