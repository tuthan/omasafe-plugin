import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import Quickshell.Io
import "model/Labels.js" as Labels
import "model/Glyphs.js" as Glyphs
import "model/Time.js" as Time
import "model/ViewModel.js" as ViewModel
import "graph/FlowLayout.js" as FlowLayout
import "components"
import "views"
import "graph"

Panel {
  id: root
  moduleName: "io.github.tuthan.omasafe"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var inventoryReport: null
  property var enforcementSummary: null
  property var enforcementDecision: null
  property bool enforcementLoading: false
  property string enforcementError: ""
  property string enforcementStdout: ""
  property string enforcementStderr: ""
  property bool enforcementSettled: false
  property bool enforcementDetailsExpanded: false
  property var scheduleReport: null
  property bool scheduleLoading: false
  property string scheduleError: ""
  property string scheduleStdout: ""
  property string scheduleStderr: ""
  property bool scheduleSettled: false
  property string schedulePolicyChoice: "advisory"
  property string scheduleInstallError: ""
  property string scheduleInstallMessage: ""
  property string scheduleInstallStdout: ""
  property string scheduleInstallStderr: ""
  property bool scheduleInstallSettled: false
  property var coverageReport: null
  property bool coverageLoading: false
  property string coverageError: ""
  property string coverageStdout: ""
  property string coverageStderr: ""
  property bool coverageSettled: false
  property bool coverageDetailsExpanded: false
  property string coverageCliVersion: ""
  // rules list (Phase 2 T2.9 collector); cached per CLI version like coverageReport.
  property var rulesListReport: null
  property bool rulesListLoading: false
  property string rulesListError: ""
  property string rulesListStdout: ""
  property string rulesListStderr: ""
  property string rulesListCliVersion: ""
  property var overrideReport: null
  property bool overrideLoading: false
  property string overrideError: ""
  property string overrideStdout: ""
  property string overrideStderr: ""
  property bool overrideSettled: false
  property bool overrideDetailsExpanded: false
  property var statusReport: null
  property var diffReport: null
  property string panelError: ""
  property string marketplaceRefreshError: ""
  property string marketplaceRefreshMessage: ""
  property bool marketplaceRefreshSettled: false
  // A successful catalog refresh must be followed by an inventory reload before
  // its success is shown. These coordinate that hand-off across the async
  // inventory process so the reload is never dropped when inventory is busy.
  property bool marketplaceRefreshAwaitingInventory: false
  property bool inventoryReloadPending: false
  property int inventoryGeneration: 0
  property int refreshInventoryGeneration: 0
  // Marks the single inventory run started by a catalog refresh, so only that run
  // may skip the per-plugin status sweep. Consumed by applyInventory; a concurrent
  // normal-open reload never inherits it.
  property bool nextInventoryCatalogOnly: false
  // CLI stdout from a refresh, held until the reload applies so a success line is
  // never shown before the catalog it describes is loaded.
  property string pendingRefreshMessage: ""
  property string selectedError: ""
  property string selectedPluginId: ""
  property bool showCompliantPlugins: false
  property bool showPluginBackups: false
  property bool checkingPluginStatuses: false
  property var pluginStatuses: ({})
  property var statusQueue: []
  property int statusSweepGeneration: 0
  // Identity fingerprint of the installed plugin set, so a catalog-only inventory
  // reload can skip the O(N) per-plugin status sweep when nothing was installed,
  // removed, or changed on disk.
  property string installedSignature: ""
  property string trustError: ""
  property string trustOutput: ""
  // Positive result line for the last completed trust/untrust, keyed on the CLI's own
  // words and naming the identity that was authorized (T0.18-pinned). "" renders nothing.
  property string mutationMessage: ""
  property bool trustSettled: false
  property bool showPluginPicker: false
  property string trustOperation: ""
  property string reviewUpdatePluginId: ""
  property string reviewUpdateDigest: ""
  property string reviewUpdateCommit: ""
  property string reviewUpdatePolicyChoice: "advisory"
  property string reviewUpdateError: ""
  property string reviewUpdateMessage: ""
  property bool reviewUpdateSettled: false
  property bool reviewUpdateTerminating: false
  property string reviewUpdateStdout: ""
  property string reviewUpdateStderr: ""
  property string enablePluginId: ""
  property string enablePolicyChoice: "advisory"
  property string enableError: ""
  property string enableMessage: ""
  property bool enableSettled: false
  property string enableStdout: ""
  property string enableStderr: ""
  property var analysisReport: null
  property var analysisCoverageStates: null
  property string analysisPluginId: ""
  property string analysisDigest: ""
  property string analysisCliVersion: ""
  property string analysisPolicyKey: ""
  property string analysisError: ""
  property bool analysisLoading: false
  property var analysisCache: ({})
  // Root analysis queue (doc 04 §10.1, T3.8): `a`/`A` in Flow and the detail sheet's
  // Analyze button push ids here; one Process at a time drains them. analysisStateById
  // holds analyzing/unavailable per id (analyzed/not analyzed come from the cache).
  property var analysisQueue: []
  property int analysisSweepGeneration: 0
  property var analysisStateById: ({})
  property string analysisStdout: ""
  property string analysisStderr: ""
  property bool analysisSettled: false
  readonly property int v02OutputCharCap: 2 * 1024 * 1024
  property string expandedFindingKey: ""
  property string ruleExplanation: ""
  // The structured `rules explain` result (carries external_equivalences for the rule
  // sheet's BASELINE V3 relations); the rule's text fields come from the rules-list vm.
  property var ruleExplanationResult: null
  property string ruleExplanationError: ""
  property string ruleExplanationKey: ""
  property bool ruleExplanationLoading: false
  property bool analysisDetailsExpanded: false
  property string ruleExplanationStdout: ""
  property string ruleExplanationStderr: ""
  property bool ruleExplanationSettled: false
  property var ruleExplanationCache: ({})
  property int selectionRequestId: 0
  property int analysisRequestId: 0

  // The single pending confirmation. "" means none is open; otherwise it names the
  // one action the open confirmation authorizes, and the only action its confirm
  // button may run. Confirmations never stack: a request arriving while one is open
  // is dropped.
  readonly property var pendingActions: ["record", "replace", "remove", "enable", "review-update", "schedule"]

  // Capability classes in catalog order (02 §2.7, rules catalog v7). Grouped capability
  // output sorts by this ranking so a class's position means the same on every plugin;
  // classes absent from the catalog follow, in the order first seen.
  readonly property var capabilityCatalogOrder: [
    "process-execution", "detached-process-execution", "filesystem-access",
    "sensitive-path", "input-injection", "screen-capture", "network-access",
    "persistence-scheduling", "clipboard-access", "compositor-control",
    "polkit-agent-ui", "session-lock-surface", "pam-authentication",
    "dynamic-code-execution", "shell-ipc-inventory", "replaces-bar-context",
    "bundled-binary"
  ]
  property string pendingAction: ""
  readonly property bool baselineWritePending: root.pendingAction === "record" ||
    root.pendingAction === "replace"

  // Facts the open confirmation authorizes. Written once by the begin* openers, read
  // by the overlay and by argv, cleared with the pending action. Never re-derived.
  property string authorizedPluginId: ""
  property string authorizedHead: ""
  property string authorizedTree: ""
  property string authorizedDigest: ""
  property string authorizedBaselineDigest: ""

  // Phase 2 IA: the four tabs collapse to views. Milestone 2a ships Overview (plus
  // its plugin detail sheet at depth 1); 2b adds Rules at key 3. Flow (key 2) is
  // hidden until Phase 3, so no digit ever changes meaning.
  readonly property var tabs: [
    { key: "overview", label: "Overview" },
    { key: "flow", label: "Flow" },
    { key: "rules", label: "Rules" }
  ]
  // The view chips' options (value = tab key). One chip per view.
  readonly property var viewOptions: root.tabs.map(function(t) {
    return { value: t.key, label: t.label }
  })
  property int activeIndex: 0
  readonly property string activeTabKey: root.tabs[root.activeIndex].key
  readonly property bool operationRunning: trustProcess.running || reviewUpdateProcess.running ||
    enableProcess.running || scheduleInstallProcess.running
  readonly property bool navigationLocked: root.operationRunning || root.pendingAction !== ""
  readonly property bool scanAvailable: root.cliVerified &&
    root.statusLevel !== "checking" && !root.navigationLocked

  // First CLI release implementing the expected-identity contracts for Enable and
  // Remove (05 §10). Empty means the capability does not exist yet; no version is
  // guessed before the release does. Distinct from cliVersionRequireIdentity, which
  // asserts the binary's --version identity, not mutation contracts (T0.17).
  readonly property string cliMinIdentityMutations: ""
  readonly property bool identitySafeMutations: {
    if (root.cliMinIdentityMutations === "" || !root.hostWidget) return false
    var have = root.hostWidget.parseVersion(root.hostWidget.cliVersion)
    var need = root.hostWidget.parseVersion(root.cliMinIdentityMutations)
    return !!have && !!need && root.hostWidget.compareVersion(have, need) >= 0
  }

  onSelectedPluginIdChanged: {
    // Analysis for the detail sheet is fetched by openPlugin(); nothing to do here.
  }

  // A scan / analysis / collector update that shrinks a section must never leave the
  // cursor out of range (doc 03 §13, T1.8/T2.7). The vm binding recomputes on every
  // report change, so clamp here after it settles.
  onVmChanged: { Qt.callLater(root.clampCursor); if (root.activeTabKey === "flow") Qt.callLater(root.rebuildFlow) }
  // Rule catalog and coverage map feed the RULES / BASELINE layers; rebuild Flow when
  // they arrive (they load lazily on Flow / Rules entry).
  onCoverageReportChanged: if (root.activeTabKey === "flow") Qt.callLater(root.rebuildFlow)
  onRulesListReportChanged: if (root.activeTabKey === "flow") Qt.callLater(root.rebuildFlow)
  onAnalysisStateByIdChanged: if (root.activeTabKey === "flow") Qt.callLater(root.rebuildFlow)
  // FlowView pushes the body width and row budget on mount; rebuildFlow bails until the
  // width is known, so the first populated build happens here (the graph would otherwise
  // stay empty until the next data event).
  onFlowBodyWidthChanged: if (root.activeTabKey === "flow") Qt.callLater(root.rebuildFlow)
  onFlowMaxRowsChanged: if (root.activeTabKey === "flow") Qt.callLater(root.rebuildFlow)

  // A confirmation is never left armed behind a closed panel: whatever closes it — Esc,
  // the bar button, a popout switch, the compositor — drops the pending action. The
  // cursor is hidden on open until the first key or hover (doc 03 §13).
  onOpenedChanged: {
    if (!root.opened) {
      root.clearPendingAction(); root.overviewDepth = 0
      // A closed panel drops the analysis sweep: bump the generation so a stale
      // in-flight result never chains, and clear the queue (doc 04 §10.1).
      root.analysisSweepGeneration++
      root.analysisQueue = []
    } else { root.cursorActive = false; root.focusSection = "hero"; root.selectedIndex = 0 }
  }

  // Colour and type declared once on the root (doc 02 §2.3, §2.1, 05 §4); nothing
  // else in the redesigned chrome contains a colour expression or a font family.
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  // dimStep(k): an opaque mix of fg toward the theme background (the opaque palette
  // value), k=0 is fg, k=1 is background. Not Qt.darker, which only lowers lightness
  // and so inverts the hierarchy on light themes (doc 02 §2.3).
  function dimStep(k) {
    var b = Color.background
    return Qt.rgba(fg.r * (1 - k) + b.r * k, fg.g * (1 - k) + b.g * k, fg.b * (1 - k) + b.b * k, 1)
  }
  readonly property color dimHeader: dimStep(0.25)   // section headers, header right value
  readonly property color dim: dimStep(0.33)         // secondary lines, unavailable, notices
  readonly property color faint: dimStep(0.55)       // disabled glyphs, non-neighbour graph nodes
  readonly property color hoverFill: Style.hoverFillFor(fg, Color.accent)
  readonly property color selectedFill: Style.selectedFillFor(fg, Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Kept as an alias while the four tab bodies (Phase 2) still read these names;
  // both resolve to the same colour as the new tokens above. warningColor is now
  // the urgent token — there is no warning hue (doc 02 P9) — so the transitional
  // tab bodies drop the amber literal without their own rewrite.
  readonly property color contentForeground: root.fg
  readonly property color warningColor: root.urgent
  readonly property var alerts: hostWidget ? hostWidget.alerts : []
  readonly property string statusLevel: hostWidget ? hostWidget.statusLevel : "unknown"

  readonly property bool cliVerified: root.hostWidget
    ? root.hostWidget.cliVerified === true : false

  // One normalised view model (doc 03, 05 §5, T2.1). A binding over every report the
  // views read, so a reassigned inventory/status/analysis/coverage/rules/schedule/
  // override report rebuilds it; no view walks a raw report or calls a data function.
  // ViewModel.build() is pure and tolerates null inputs, so this is safe before the
  // first collector returns. buildVm() resolves each plugin's cached analysis through
  // the existing cache-validity check (the analysis cache KEY stays invariant).
  readonly property var vm: root.buildVm()

  // Central authorization for every operational CLI command (inventory, status,
  // diff, trust, untrust, marketplace refresh). Until the CLI is resolved and its
  // version verified, this yields a non-executable command so no launcher can run
  // or trust an unverified binary even if it forgets to check first.
  function cliCommand(args) {
    return (root.hostWidget && root.hostWidget.cliVerified)
      ? root.hostWidget.cliCommand(args)
      : ["/usr/bin/false"]
  }

  // Every bounded CLI process follows the same two-phase shutdown: SIGTERM
  // gives the CLI a chance to clean up, then the per-process kill timer sends
  // SIGKILL to anything that remains. The timer is stopped on every exit and
  // before reuse so a late escalation can never affect a later request.
  function terminateBoundedProcess(process) {
    if (!process.running) {
      if (process.killTimer) process.killTimer.stop()
      return
    }
    process.signal(15)
    if (process.killTimer) process.killTimer.restart()
  }

  function stopBoundedProcessTimers(process, timeout) {
    timeout.stop()
    if (process.killTimer) process.killTimer.stop()
  }

  function statusColor(level) {
    if (level === "critical") return root.bar ? root.bar.urgent : Color.urgent
    if (level === "warning") return root.warningColor
    if (level === "normal") return root.contentForeground
    return root.dim
  }

  function statusTitle() {
    if (root.statusLevel === "checking") return "Scanning"
    if (!root.hostWidget) return "Scan status unavailable"
    if (root.hostWidget.scanState === "ready") return "Ready to scan"
    if (root.hostWidget.scanState === "missing-cli") return "omasafe-cli not found"
    if (root.hostWidget.scanState === "incompatible-cli") return "omasafe-cli incompatible"
    if (root.hostWidget.scanState === "unavailable") return "Scan unavailable"
    if (root.statusLevel === "critical") return "Critical finding"
    if (root.statusLevel === "warning") return "Review needed"
    if (root.statusLevel === "normal") return "No outstanding changes"
    return "Scan status unavailable"
  }

  function statusMessage() {
    if (!root.hostWidget) return "Waiting for the OmaSafe widget."
    if (root.hostWidget.scanState === "missing-cli")
      return "Install omasafe-cli, then restart Omarchy Shell."
    if (root.hostWidget.scanState === "incompatible-cli")
      return root.hostWidget.cliError ||
        "The resolved omasafe-cli is not a compatible version; scans are disabled."
    if (root.hostWidget.scanState === "unavailable")
      return root.hostWidget.cliError || "The latest scan could not be completed."
    if (root.hostWidget.scanState === "ready")
      return "Click Run scan to inspect the installed plugin state."
    if (root.statusLevel === "checking") return "Reading installed plugin state…"
    if (root.statusLevel === "critical") return "A confirmed critical finding needs immediate review."
    if (root.statusLevel === "warning")
      return root.hostWidget.outstandingCount + " item(s) need review" +
        (root.hostWidget.newCount > 0 ? "; " + root.hostWidget.newCount + " new" : "") + "."
    return "The latest scan found no outstanding changes."
  }

  function lastScanAt() {
    return root.hostWidget && root.hostWidget.lastScanAt
      ? String(root.hostWidget.lastScanAt) : "unavailable"
  }

  // ---- hero state (doc 03 §3) ---------------------------------------------------
  // The shield shape follows a scan RESULT existing, never dim alone (GR3): a scan
  // that failed shows the outline shield and never the quiet/attention headline.

  readonly property string scanState: root.hostWidget ? String(root.hostWidget.scanState || "") : ""
  readonly property bool checking: root.statusLevel === "checking"
  // The two states a fresh result sets (BarWidget applyScan).
  readonly property bool hasScanResult: root.scanState === "quiet" || root.scanState === "attention"
  // A failed scan that still holds an earlier result beside it.
  readonly property bool earlierResultKept: root.hostWidget
    ? (root.hostWidget.scanResultsStale === true && String(root.hostWidget.lastScanAt || "") !== "")
    : false

  function heroTitle() {
    if (!root.hostWidget) return "Scan status unavailable"
    if (root.checking) return "Scanning…"
    if (root.scanState === "missing-cli") return "omasafe-cli not found"
    if (root.scanState === "incompatible-cli") return "omasafe-cli incompatible"
    if (root.scanState === "unavailable") return "Scan unavailable"
    if (root.scanState === "ready") return "Ready to scan"
    var n = Number(root.hostWidget.outstandingCount || 0)
    if (n === 0) return "No outstanding alerts"
    var critical = String(root.hostWidget.highestSeverity || "").toLowerCase() === "critical"
    if (critical) return n === 1 ? "1 critical alert to review" : n + " critical alerts to review"
    return n === 1 ? "1 alert to review" : n + " alerts to review"
  }

  // Kit uppercases the meta; fragments are ` · `-joined (doc 03 §3.3).
  function heroMeta() {
    if (!root.hostWidget) return "Waiting for the OmaSafe widget"
    if (root.scanState === "missing-cli") return "Install omasafe-cli, then restart the shell"
    if (root.scanState === "incompatible-cli")
      return String(root.hostWidget.cliVersion || "") + " found · " +
        String(root.hostWidget.cliVersionMin || "") + " or newer required"
    var frags = []
    var plugins = root.visiblePlugins().length
    if (plugins > 0) frags.push(plugins + " plugins")
    if (root.scanState === "unavailable") {
      frags.push("last scan failed")
      if (root.earlierResultKept) {
        var rel = Time.relative(root.hostWidget.lastScanAt)
        var n = Number(root.hostWidget.outstandingCount || 0)
        if (n > 0) frags.push("showing " + n + " alerts from " + rel)
        else frags.push("earlier result: no alerts · " + rel)
      } else {
        frags.push("no earlier results")
      }
      return frags.join(" · ")
    }
    if (root.checking) { frags.push("reading installed state"); return frags.join(" · ") }
    if (root.scanState === "ready") return frags.join(" · ")
    if (root.scanState === "attention" && Number(root.hostWidget.newCount || 0) > 0)
      frags.push(Number(root.hostWidget.newCount) + " new")
    var scanned = Time.relative(root.hostWidget.lastScanAt)
    if (scanned !== "") frags.push("scanned " + scanned)
    return frags.join(" · ")
  }

  // The detail pill shows only "unavailable", and only when the CLI is not usable
  // (doc 03 §3: detail = cliVerified ? "" : "unavailable"). The CLI version lives in
  // the SOURCES row, never the hero.
  function heroDetail() {
    return root.cliVerified ? "" : "unavailable"
  }

  function heroIconOpacity() {
    if (!root.hostWidget) return 0.5
    if (root.scanState === "unavailable" || root.scanState === "missing-cli" ||
        root.scanState === "incompatible-cli") return 0.5
    return 1.0
  }

  // Status line under the hero: the verbatim CLI failure in urgent, else the stale-
  // scan sentence in dim, else hidden (doc 03 §3, §9).
  readonly property string scanErrorText: {
    var e = String((root.hostWidget && root.hostWidget.cliError) || root.panelError || "")
    var failed = root.scanState === "unavailable" || root.scanState === "missing-cli" ||
      root.scanState === "incompatible-cli" || !root.hostWidget
    return failed ? e : ""
  }
  function scanStatusLineText() {
    if (root.scanErrorText !== "") return root.scanErrorText
    if (root.earlierResultKept)
      return "Results are from the last successful scan " +
        Time.relative(root.hostWidget.lastScanAt) + "."
    return ""
  }
  readonly property bool scanStatusLineUrgent: root.scanErrorText !== ""

  // Inventory-level coverage limitations, re-homed from the T0.15 plain Text into a
  // NoticeRow (doc 03 §9). Empty in the fixture (coverage.limitations: []).
  readonly property var inventoryLimitations: {
    var coverage = root.inventoryReport && root.inventoryReport.coverage
    return coverage && Array.isArray(coverage.limitations) ? coverage.limitations : []
  }
  // Marketplace snapshot staleness (the CLI's flag; the panel keeps no threshold).
  readonly property bool marketplaceStale: !!(root.inventoryReport && root.inventoryReport.marketplace_stale === true)

  function enforcementSummaryFor(id) {
    var entries = root.enforcementSummary && root.enforcementSummary.decisions || []
    for (var i = 0; i < entries.length; i++) {
      if (String(entries[i].plugin_id || "") === String(id || "")) return entries[i]
    }
    return null
  }

  // Delegates to the one closed-enum gate in model/Labels.js (T1.1). Kept as a
  // thin wrapper so the untouched tab bodies keep calling root.enforcementEnum;
  // Phase 2 moves each consumer onto Labels directly and deletes this.
  function enforcementEnum(value, allowed) {
    return Labels.gate(value, allowed)
  }

  function enforcementDecisionIsSupported(decision) {
    if (!decision || typeof decision !== "object") return false
    if (!Object.prototype.hasOwnProperty.call(decision, "evaluation_state") ||
        !Object.prototype.hasOwnProperty.call(decision, "outcome") ||
        !Object.prototype.hasOwnProperty.call(decision, "authorization_basis")) return false
    var evaluation = root.enforcementEnum(decision.evaluation_state,
      ["evaluated", "not-evaluated"])
    var outcome = root.enforcementEnum(decision.outcome, ["allow", "block"])
    var basis = decision.authorization_basis === null ||
      decision.authorization_basis === undefined
      ? null : root.enforcementEnum(decision.authorization_basis, ["policy", "override"])
    return evaluation !== "unsupported" && outcome !== "unsupported" &&
      (basis === null || basis !== "unsupported")
  }

  function enforcementOutcomeLabel(decision) {
    if (!decision) return "No decision recorded"
    if (!root.enforcementDecisionIsSupported(decision))
      return "Unsupported by this plugin version"
    var evaluation = root.enforcementEnum(decision.evaluation_state,
      ["evaluated", "not-evaluated"])
    var outcome = root.enforcementEnum(decision.outcome, ["allow", "block"])
    // `null` is a valid contract value for a decision with no authorization
    // basis. Unknown non-null values remain fail-closed and explicit.
    var basis = decision.authorization_basis === null ||
      decision.authorization_basis === undefined
      ? "none" : root.enforcementEnum(decision.authorization_basis, ["policy", "override"])
    return (evaluation === "not-evaluated" ? "not evaluated; " : "") +
      outcome + " via " + basis
  }

  function enforcementDecisionLevel(decision) {
    if (!decision) return "unknown"
    if (!root.enforcementDecisionIsSupported(decision)) return "unknown"
    if (root.enforcementEnum(decision.evaluation_state,
        ["evaluated", "not-evaluated"]) === "not-evaluated") return "unknown"
    var outcome = root.enforcementEnum(decision.outcome, ["allow", "block"])
    if (outcome === "block") return "critical"
    if (decision.authorization_basis === "override") return "warning"
    return "normal"
  }

  function enforcementRecoveryGuidance(decision) {
    if (!decision || root.enforcementEnum(decision.outcome, ["allow", "block"]) !== "block")
      return ""
    var pluginId = String(decision.plugin_id || root.selectedPluginId || "")
    var operation = String(decision.operation || "operation")
    return "CLI blocked " + operation + ". Recovery remains CLI-owned; inspect the persisted decision with:\n" +
      "omasafe-cli plugins enforcement-status " + pluginId + " --format json"
  }

  function enforcementJson(value) {
    if (value === null || value === undefined) return "unavailable"
    var rendered = ""
    try {
      rendered = typeof value === "object" ? JSON.stringify(value) : String(value)
    } catch (error) {
      rendered = "unavailable"
    }
    return String(rendered || "unavailable").slice(0, 1024)
  }

  function enforcementList(value, limit) {
    if (!Array.isArray(value) || value.length === 0) return "none"
    var shown = value.slice(0, limit).map(function(item) { return String(item) }).join(", ")
    return shown + (value.length > limit ? " … +" + (value.length - limit) + " more" : "")
  }

  function enforcementCoverage(decision) {
    var counts = decision && decision.coverage_counts || {}
    var keys = Object.keys(counts).sort()
    if (keys.length === 0) return "unavailable"
    return keys.map(function(key) { return key + "=" + String(counts[key]) }).join(", ")
  }

  function coverageRelation(value) {
    return Labels.gate(value, ["structural-equivalent", "partial-overlap", "not-covered"])
  }

  function coverageRelationLevel(value) {
    var relation = root.coverageRelation(value)
    if (relation === "structural-equivalent") return "normal"
    if (relation === "partial-overlap" || relation === "not-covered") return "warning"
    return "unknown"
  }

  function coverageOwner(entry) {
    if (!entry) return "no OmaSafe mapping"
    return String(entry.omaRuleId || entry.omaCapability || "no OmaSafe mapping")
  }

  function overrideStatus(value) {
    return Labels.overrideStatus(value)
  }

  function overrideStatusLevel(value) {
    var status = root.overrideStatus(value)
    return status === "active" || status === "expired" ? "warning" : "unknown"
  }

  function schedulePolicyLabel() {
    if (root.scheduleLoading) return "checking…"
    if (root.scheduleError !== "") return "unavailable"
    if (!root.scheduleReport || root.scheduleReport.installed !== true) return "not installed"
    var policy = root.enforcementEnum(root.scheduleReport.policy, ["advisory", "hardened"])
    return policy === "unsupported" ? "unsupported" : policy
  }

  function scheduleExecutionLabel() {
    if (root.scheduleLoading) return "checking…"
    if (root.scheduleError !== "") return "unavailable"
    var execution = root.scheduleReport && root.scheduleReport.last_known_execution
    if (!execution) return root.scheduleReport && root.scheduleReport.installed === true
      ? "unavailable" : "not installed"
    if (execution.available !== true) return "unavailable"
    var state = String(execution.service_sub_state || execution.service_active_state || "unknown")
    var exitCode = execution.service_exit_code === null || execution.service_exit_code === undefined
      ? "unknown" : String(execution.service_exit_code)
    var finished = String(execution.service_finished_at || "not recorded")
    return state + " · exit " + exitCode + " · " + finished
  }

  function scheduleInstallLabel() {
    return root.schedulePolicyChoice === "hardened" ? "hardened" : "advisory"
  }

  function protectionGateLabel() {
    if (!root.cliVerified) return "unavailable until a compatible CLI is verified"
    return "available for OmaSafe-controlled enable/update operations"
  }

  function alertLevel(alert) {
    return alert && ["critical", "error"].indexOf(String(alert.severity || "").toLowerCase()) >= 0
      ? "critical" : "warning"
  }

  function alertLabel(alert) {
    var kind = String(alert && alert.kind || "finding").replace(/-/g, " ")
    return kind.charAt(0).toUpperCase() + kind.slice(1)
  }

  function analysisSeverityLevel(severity) {
    var level = String(severity || "").toLowerCase()
    if (level === "critical") return "critical"
    if (level === "high" || level === "medium") return "warning"
    if (level === "low" || level === "info") return "normal"
    return "unknown"
  }

  function analysisPolicyIdentityKey(report) {
    if (!report || report.policy_identity === undefined || report.policy_identity === null)
      return ""
    try {
      return JSON.stringify(report.policy_identity)
    } catch (error) {
      return ""
    }
  }

  function analysisCoverageLabel() {
    var states = root.analysisCoverageStates
    if (!states || typeof states !== "object") return "Coverage: unavailable"
    var order = [
      { key: "analyzed", label: "Analyzed/complete" },
      { key: "partial", label: "Partial" },
      { key: "unsupported", label: "Unsupported" },
      { key: "skipped", label: "Skipped" },
      { key: "truncated", label: "Truncated" },
      { key: "unreferenced", label: "Unreferenced" }
    ]
    var values = []
    for (var i = 0; i < order.length; i++) {
      if (states[order[i].key] !== undefined)
        values.push(order[i].label + ": " + String(states[order[i].key]))
    }
    return values.length > 0 ? "Coverage: " + values.join(" · ") : "Coverage: unavailable"
  }

  function analysisCoverageLevel() {
    var states = root.analysisCoverageStates
    if (!states || typeof states !== "object") return "unknown"
    return ["partial", "unsupported", "skipped", "truncated"].some(function(key) {
      return Number(states[key] || 0) > 0
    }) || (root.analysisReport && (root.analysisReport.coverage_limitations || []).length > 0)
      ? "warning" : "normal"
  }

  function analysisFreshnessLabel() {
    if (!root.cliVerified) return "unavailable until a compatible CLI is verified"
    if (root.analysisLoading) return "loading for selected plugin"
    if (!root.analysisReport) return "not loaded (open Findings)"
    if (root.analysisPluginId !== root.selectedPluginId) return "stale selection"
    var plugin = root.selectedPlugin()
    if (!plugin || root.analysisDigestFor(plugin) !== root.analysisDigest)
      return "stale source identity"
    var cliVersion = String(root.hostWidget && root.hostWidget.cliVersion || "")
    if (root.analysisCliVersion !== cliVersion) return "stale CLI version"
    return "loaded for " + root.analysisPluginId + " · " +
      root.shortDigest(root.analysisReport.analysis_fingerprint)
  }

  function pluginById(id) {
    var plugins = root.inventoryReport && root.inventoryReport.plugins || []
    for (var i = 0; i < plugins.length; i++) {
      if (plugins[i].id === id) return plugins[i]
    }
    return null
  }

  function visiblePlugins() {
    var plugins = root.inventoryReport && root.inventoryReport.plugins || []
    return plugins.filter(function(plugin) { return plugin.classification !== "backup" })
  }

  function marketplaceListings() {
    var listings = root.inventoryReport && root.inventoryReport.marketplace || []
    return listings.filter(function(listing) {
      var id = String(listing.plugin_id || "")
      return root.showPluginBackups || id.charAt(0) !== "."
    })
  }

  function marketplaceBackupCount() {
    var listings = root.inventoryReport && root.inventoryReport.marketplace || []
    return listings.filter(function(listing) {
      return String(listing.plugin_id || "").charAt(0) === "."
    }).length
  }

  // Fingerprint of installed identities (id + source digest). Per-plugin trust
  // status depends only on these, not on the marketplace catalog, so an unchanged
  // signature means a catalog refresh cannot have changed any plugin's status.
  function computeInstalledSignature() {
    var parts = root.visiblePlugins().map(function(plugin) {
      return String(plugin.id) + ":" +
        String(plugin.content_digest || plugin.head || plugin.tree || "")
    })
    parts.sort()
    return parts.join("|")
  }

  function statusForPlugin(id) {
    return root.pluginStatuses[id] || null
  }

  function baselinedUnchangedPlugins() {
    return root.visiblePlugins().filter(function(plugin) {
      var status = root.statusForPlugin(plugin.id)
      return status && status.state === "unchanged"
    })
  }

  function trustedPluginCount() {
    return root.visiblePlugins().filter(function(plugin) {
      var status = root.statusForPlugin(plugin.id)
      return status && status.state === "unchanged"
    }).length
  }

  function outstandingReviewCount() {
    // Keep the summary tile aligned with the header, which is driven by the
    // CLI's outstanding finding count. A finding may be system-level (for
    // example marketplace coverage) and therefore have no changed/partial
    // plugin status to count here.
    return root.hostWidget ? Number(root.hostWidget.outstandingCount || 0) : 0
  }

  function untrustedPluginCount() {
    return root.visiblePlugins().filter(function(plugin) {
      var status = root.statusForPlugin(plugin.id)
      return status && status.state === "untrusted"
    }).length
  }

  function selectedPlugin() {
    return root.pluginById(root.selectedPluginId)
  }

  function setActive(index) {
    if (root.navigationLocked) return
    root.activeIndex = Math.max(0, Math.min(root.tabs.length - 1, Number(index)))
    // A view switch (or the current view's digit) pops to depth 0, clears any return
    // frame and the finder, and resets the cursor (doc 03 §13). Data arrival never
    // does this; an explicit key does.
    root.overviewDepth = 0
    root.returnFrame = null
    root.finderActive = false
    root.cursorActive = false
    root.focusSection = "hero"
    root.selectedIndex = 0
    Qt.callLater(function() {
      if (activeFlick) activeFlick.contentY = 0
    })
    if (root.opened && root.activeTabKey === "rules") { root.ensureRulesList(); root.ensureCoverage() }
    if (root.opened && root.activeTabKey === "flow") {
      // Flow needs the rule catalog and the coverage map for the RULES / BASELINE
      // layers (T2.9 caches). Enter Z0 fresh; a new orderEpoch re-sorts (§4.1 step 2).
      root.ensureRulesList(); root.ensureCoverage()
      root.enterFlowZ0()
    }
  }

  function switchTabBy(delta) {
    if (root.navigationLocked) return
    root.setActive((root.activeIndex + delta + root.tabs.length) % root.tabs.length)
  }

  // The view chips address views by key; setActive() already gates on
  // navigationLocked, so the chips and the digit keys share one gate (doc 03 §3).
  function setViewByKey(key) {
    for (var i = 0; i < root.tabs.length; i++) {
      if (root.tabs[i].key === String(key)) { root.setActive(i); return }
    }
  }

  // ---- cursor model (dev-gallery template, doc 03 §13, 05 §4) --------------------
  // One cursor over the shell targets. cursorActive is false on open; the first key
  // move or real pointer motion reveals the highlight. This phase's section list is
  // `hero → views` only; Phase 2 appends the per-view sections when the rows exist.
  property bool cursorActive: false
  property string focusSection: "hero"
  property int selectedIndex: 0
  // The cursor's section list for the current view and depth (doc 03 §13). Sections
  // with zero rows are skipped so j/k never lands on an empty section.
  readonly property var visibleSections: root.computeVisibleSections()

  function computeVisibleSections() {
    // The finder owns the whole body while open: one result section.
    if (root.finderActive) return ["results"]
    var out = ["hero", "views"]
    var candidates
    if (root.activeTabKey === "flow") {
      // hero → views → lens → the one column the cursor sits in → inspector-actions
      // (doc 04 §6.2). Only the cursor's own column is a section, so j/k walks its
      // rows and never crosses columns — h/l does that (flowMoveCursorH). The Matrix
      // lens replaces the column with a 2-D grid; the Trace body is informational.
      if (!root.cliVerified) return out
      if (root.flowLens === "trace") return out
      out.push("lens")
      if (root.flowLens === "matrix") {
        if (root.sectionCount("matrix") > 0) out.push("matrix")
      } else {
        if (root.sectionCount("col-" + root.flowCol) > 0) out.push("col-" + root.flowCol)
      }
      if (root.sectionCount("inspector-actions") > 0) out.push("inspector-actions")
      return out
    }
    if (root.activeTabKey === "rules")
      candidates = ["rules", "baseline"]
    else if (root.overviewDepth >= 1)
      candidates = ["trust", "trust-actions", "review", "classes", "coverage",
        "claim-actions", "enforcement", "provenance"]
    else
      candidates = ["alerts", "plugins", "backups-toggle", "sources"]
    for (var i = 0; i < candidates.length; i++)
      if (root.sectionCount(candidates[i]) > 0) out.push(candidates[i])
    return out
  }

  function sectionCount(section) {
    var a = root.analysisReport
    switch (section) {
      case "hero":           return 1          // the scan Button
      case "views":          return root.tabs.length
      case "alerts":         return root.cliVerified && root.vm ? root.vm.alerts.length : 0
      case "plugins":        return root.cliVerified && root.vm
        ? (root.vm.plugins.length + (root.showPluginBackups ? root.vm.backups.length : 0)) : 0
      case "backups-toggle": return (root.vm && root.vm.backupCount > 0) ? 1 : 0
      case "sources":        return root.cliVerified ? 4 : 0
      case "trust":          return root.trustIdentityRows().length
      case "trust-actions":  return root.trustActionModel().length
      case "review":         return a ? (a.findings ? a.findings.length : 0)
        : ((!root.analysisLoading && root.analysisError === "") ? 1 : 0)  // the Analyze button
      case "classes":        return a ? root.capabilityGroupCount() : 0
      case "coverage":       return (a && a.invocation_edges && a.invocation_edges.length > 0) ? 1 : 0
      case "claim-actions":  return root.claimActionModel().length
      case "enforcement":    return root.enforcementActionModel().length
      case "provenance":     return a ? 1 : 0
      case "rules":          return root.cliVerified && root.vm ? root.vm.rules.length : 0
      case "baseline":       return (root.vm && root.vm.baseline && root.vm.baseline.available)
        ? root.vm.baseline.rows.length : 0
      case "results":        return root.finderResultCount()
      case "lens":           return 1
      case "matrix":         return root.flowMatrixRows().length
      case "inspector-actions":
        return (root.flowInspectorFacts().action !== "") ? 1 : 0
    }
    if (section.indexOf("col-") === 0) {
      var ci = Number(section.slice(4))
      return (root.flowNodes[ci] ? root.flowNodes[ci].length : 0)
    }
    return 0
  }
  function sectionIsHorizontal(section) {
    return section === "views" || section === "trust-actions"
      || section === "claim-actions" || section === "enforcement"
      || section === "lens" || section === "inspector-actions"
  }
  function sectionFirstIndex(section) { return 0 }
  function sectionLastIndex(section) { return Math.max(0, root.sectionCount(section) - 1) }

  function moveCursor(delta) {
    var sections = root.visibleSections
    var sIdx = sections.indexOf(root.focusSection)
    if (sIdx < 0) {
      root.focusSection = sections[0]
      root.selectedIndex = root.sectionFirstIndex(root.focusSection)
      return
    }
    // Single-row / horizontal sections: j/k crosses to the next section.
    if (root.sectionIsHorizontal(root.focusSection) || root.sectionCount(root.focusSection) <= 1) {
      if (delta > 0 && sIdx < sections.length - 1) {
        root.focusSection = sections[sIdx + 1]
        root.selectedIndex = root.sectionFirstIndex(root.focusSection)
      } else if (delta < 0 && sIdx > 0) {
        root.focusSection = sections[sIdx - 1]
        root.selectedIndex = root.sectionLastIndex(root.focusSection)
      }
      return
    }
    // Vertical multi-row section: walk within, then cross at boundaries.
    var next = root.selectedIndex + delta
    if (next < 0) {
      if (sIdx > 0) {
        root.focusSection = sections[sIdx - 1]
        root.selectedIndex = root.sectionLastIndex(root.focusSection)
      }
    } else if (next >= root.sectionCount(root.focusSection)) {
      if (sIdx < sections.length - 1) {
        root.focusSection = sections[sIdx + 1]
        root.selectedIndex = root.sectionFirstIndex(root.focusSection)
      }
    } else {
      root.selectedIndex = next
    }
  }

  function moveCursorH(delta) {
    // Flow columns cross with h/l, landing on the nearest connected node (doc 04 §6.2).
    if (root.activeTabKey === "flow" && root.focusSection.indexOf("col-") === 0)
      return root.flowMoveCursorH(delta)
    // Matrix: h/l walks the cell cursor from the row label (-1) across the columns.
    if (root.activeTabKey === "flow" && root.focusSection === "matrix") {
      var mcols = root.flowMatrixColumns().length
      root.flowMatrixCol = Math.max(-1, Math.min(mcols - 1, root.flowMatrixCol + delta))
      return
    }
    // In a vertical section, l on a plugin row opens it and h pops one depth level
    // (doc 03 §13); horizontal sections walk their buttons.
    if (!root.sectionIsHorizontal(root.focusSection)) {
      if (delta > 0 && root.focusSection === "plugins" && root.vm
          && root.selectedIndex < root.vm.plugins.length) {
        root.openPlugin(root.vm.plugins[root.selectedIndex].id)
      } else if (delta > 0 && root.focusSection === "review") {
        // l on an expanded review item opens its rule (doc 03 §5.2/§13).
        var a = root.analysisReport
        var f = a && a.findings ? a.findings[root.selectedIndex] : null
        if (f && root.expandedFindingKey === root.findingKey(f)) root.openRuleFromReview(String(f.rule_id || ""))
      } else if (delta > 0 && root.focusSection === "classes") {
        // l on an expanded class reveals the rest of its sites (+N more).
        var g = root.capabilityGroups()
        if (g[root.selectedIndex] && root.expandedClass === g[root.selectedIndex].cls)
          root.classShowAll = g[root.selectedIndex].cls
      } else if (delta > 0 && root.focusSection === "rules" && root.vm
          && root.selectedIndex < root.vm.rules.length) {
        // l opens a rule's sheet the same as Enter (expand).
        root.expandRule(root.vm.rules[root.selectedIndex].id)
      } else if (delta < 0 && (root.returnFrame !== null || root.overviewDepth >= 1)) {
        // h in a vertical section pops the return frame first, then depth (doc 03 §13).
        root.popDepth()
      }
      return
    }
    var max = root.sectionCount(root.focusSection) - 1
    var next = root.selectedIndex + delta
    root.selectedIndex = next < 0 ? 0 : (next > max ? max : next)
  }

  function activateCursor() {
    var s = root.focusSection
    var i = root.selectedIndex
    // Flow: Enter on a node pins/opens (§6.1); the lens and inspector Button are their
    // own horizontal sections.
    if (root.activeTabKey === "flow") {
      if (s.indexOf("col-") === 0) { root.flowActivateNode(); return }
      if (s === "matrix") { root.flowMatrixActivate(); return }
      if (s === "lens") { root.flowActivateLens(); return }
      if (s === "inspector-actions") { root.flowInspectorAction(); return }
    }
    switch (s) {
      case "hero":
        if (root.scanAvailable && root.hostWidget) root.hostWidget.runScan()
        return
      case "views":
        if (i >= 0 && i < root.tabs.length) root.setViewByKey(root.tabs[i].key)
        return
      case "alerts": {
        var al = root.vm && root.vm.alerts[i]
        if (al && !al.pseudo) root.openPluginFromAlert(al.pluginId)
        return
      }
      case "plugins":
        if (root.vm && i < root.vm.plugins.length) root.openPlugin(root.vm.plugins[i].id)
        return
      case "backups-toggle": root.toggleBackups(); return
      case "sources":        root.activateSource(i); return
      case "trust":          root.copyIdentityRow(i); return
      case "trust-actions":  root.trustActionTriggered(i); return
      case "review":         root.activateReview(i); return
      case "classes":        root.toggleClassByIndex(i); return
      case "coverage":       root.toggleCoverageFileRefs(); return
      case "claim-actions":  root.claimActionTriggered(i); return
      case "enforcement":    root.enforcementActionTriggered(i); return
      case "provenance":     root.toggleProvenance(); return
      case "rules":
        if (root.vm && i >= 0 && i < root.vm.rules.length) root.expandRule(root.vm.rules[i].id)
        return
      case "baseline":
        if (root.vm && root.vm.baseline && i >= 0 && i < root.vm.baseline.rows.length)
          root.toggleBaseline(root.vm.baseline.rows[i].externalId)
        return
      case "results":        root.openFinderResult(i); return
    }
  }

  // Called after every model change so a rescan that shrinks a list can never leave
  // the cursor out of range (doc 03 §13).
  function clampCursor() {
    var sections = root.visibleSections
    if (sections.indexOf(root.focusSection) < 0) {
      root.focusSection = sections[0]
      root.selectedIndex = root.sectionFirstIndex(root.focusSection)
      return
    }
    if (root.selectedIndex < 0) root.selectedIndex = 0
    var max = root.sectionLastIndex(root.focusSection)
    if (root.selectedIndex > max) root.selectedIndex = max
  }

  // Scrolls the body Flickable so a cursor target is visible. Phase 1's targets
  // (hero, chips) live in the fixed column and are always visible, so this only acts
  // on items inside activeFlick; Phase 2 wires it to the scrolling view rows.
  function ensureCursorVisible(item) {
    if (!item || !activeFlick) return
    var content = activeFlick.contentItem
    if (!content) return
    var pt = item.mapToItem(content, 0, 0)
    if (pt.y < 0) return   // above the viewport: a fixed-column target, never scrolled
    var top = pt.y
    var bottom = top + (item.height || 0)
    var margin = Style.space(12)
    if (top < activeFlick.contentY + margin)
      activeFlick.contentY = Math.max(0, top - margin)
    else if (bottom > activeFlick.contentY + activeFlick.height - margin)
      activeFlick.contentY = bottom + margin - activeFlick.height
  }

  // Reveal the cursor on first keyboard motion (audio/Panel.qml:664 idiom).
  function revealCursor() {
    if (!root.cursorActive) { root.cursorActive = true; return true }
    return false
  }
  // Mouse hover lands the cursor on a target (kit buttons emit hovered()); no row
  // reads containsMouse (Ui/CursorSurface.qml contract).
  function hoverCursor(section, index) {
    root.cursorActive = true
    root.focusSection = section
    root.selectedIndex = index
    if (root.activeTabKey === "flow") root.afterCursorMove()
  }

  // ---- Phase 2 view depth, expansion state and the view API --------------------
  // The Overview stack: 0 = plugin list, 1 = detail sheet (doc 03 §5, §13). Data
  // arrival never changes depth or cursor.
  property int overviewDepth: 0
  property string expandedClass: ""
  property string classShowAll: ""
  property bool coverageFileRefsExpanded: false
  property bool provenanceExpanded: false
  property int catalogElapsed: 0
  readonly property bool catalogUpdating: marketplaceRefreshProcess.running

  // Rules view + finder + the one cross-view return frame (doc 03 §7, §8, §13).
  property string expandedRuleId: ""
  property string expandedBaselineId: ""
  property bool finderActive: false
  property string finderText: ""
  // { view, depth, cursor:{section,index} } pushed by a cross-view jump; popped by
  // h / - / the breadcrumb before the current view's own stack. Only one is held.
  property var returnFrame: null
  // The view/cursor to restore when the finder is dismissed without opening a result.
  property var finderOrigin: null

  // ---- Phase 3 Trust Flow state (doc 04 §6.2, §10.1) ---------------------------
  // Scope, depth and lens are owned here (the root); FlowView is a thin presenter.
  property var flowScope: ({ kind: "all", id: "" })   // {kind:"all"} | {kind:"plugin",id}
  property int flowDepth: 0                            // 0 Z0 · 1 Z1 · 2 Z2
  property string flowLens: "matrix"                   // graph | matrix | trace — Z0 opens on Matrix (T4.1)
  property bool flowMatrixAllClasses: false            // c toggle (5 observed ↔ all 17)
  property int flowOrderEpoch: 0                        // frozen while open (§4.1 step 2)
  property bool flowSameEpoch: false                   // set true after the first build of an epoch
  property var flowOffsets: [0, 0, 0, 0]               // per-column window offset (geometry only)
  property var flowPair: [true, true, false, false]    // which two adjacent columns are open
  property int flowCol: 0                               // the column the cursor sits in
  property real flowBodyWidth: 0                        // pushed by FlowView (the graph item width)
  property int flowMaxRows: 10                          // pushed by FlowView from the body height
  readonly property real flowViewportHeight: activeFlick ? activeFlick.height : 0
  // The row budget must come from the height the body CAN reach, not the height it
  // currently occupies. Deriving flowMaxRows from activeFlick.height alone is circular:
  // the graph body is `rows * rowH`, the panel is content-sized (fittedContentHeight,
  // §PopupCard), so a short graph keeps the panel short, which keeps rows small — the
  // window collapses to one row. This mirrors the activeFlick.height formula but against
  // the card's maximum (availableCardHeight, capped at the same 560), so rows is stable;
  // FlowLayout still caps geometry.rows at the tallest column's node count, so a small
  // graph never leaves empty space.
  readonly property real flowViewportHeightMax: {
    if (!panel) return flowViewportHeight
    var card = panel.availableCardHeight > 0 ? Math.min(panel.availableCardHeight, Style.space(560)) : Style.space(560)
    var inner = card - panel.verticalContentInset - fixedColumn.height - Style.space(12)
    return Math.max(Style.space(60), Math.max(flowViewportHeight, inner))
  }
  // Three properties, three reassignment cadences (§3.2): TrustFlow binds to these.
  property var flowLayoutObj: null                     // last full FlowLayout.build result
  property var flowNodes: [[], [], [], []]             // reassigned on membership/content change only
  property var flowGeometry: ({ headerH: 0, rowH: 0, rows: 0, cols: [] })  // every slide / offset move
  property var flowPaths: ({})                         // every build() and hot()
  property var flowHotKeys: ({})
  property string flowMembershipKey: ""
  property string flowContentKey: ""
  property var flowPrevKeys: null
  property string flowPinnedKey: ""                    // pinned node (current), inspector locks
  property bool flowLegendVisible: false               // ? legend PanelToolTip (T3.12)
  property int flowMatrixCol: -1                        // Matrix cell cursor: -1 = row label
  property string flowTracePlugin: ""                  // Z2 trace: the plugin and its class
  property string flowTraceClass: ""
  property string flowTraceReturnLens: "graph"         // the lens to restore when the trace pops

  // The legend (doc 04 §5): glyphs, edge styles and keys in use. Every phrase is from
  // 02 §2.7 / §3.6; none contains "safe", "clean", bare "verified" or "risk".
  function flowLegendText() {
    return "Plugin → observed capability → detecting rule → Baseline V3\n" +
      "solid = parser-backed · dashed = text match only\n" +
      "edges show the cursor's one hop or the pinned path, not the whole weave\n" +
      "thin ≤ 3 · medium 4–9 · thick ≥ 10 occurrences\n" +
      "digits = occurrences · RULES digits = local hits (occurrences + review items)\n" +
      "= equivalent check · ≈ partially covered\n" +
      "class glyph on a BASELINE row = covered at class level\n" +
      "no mark, dim = not covered by OmaSafe · 󰝦 not analyzed\n" +
      "bold = outstanding alert · 󰂭 blocked by policy\n" +
      "j k h l move · scroll a column (wheel / j k) to reveal +N more · Enter pin/open · x unpin · t trace · a analyze · m matrix"
  }

  // Enter a plugin's detail sheet (depth 1). Cursor hidden until the first move.
  function openPlugin(id) {
    if (!id) return
    root.selectPlugin(id, null)
    root.overviewDepth = 1
    root.cursorActive = false
    root.focusSection = "trust"
    root.selectedIndex = 0
    root.expandedClass = ""
    root.classShowAll = ""
    root.coverageFileRefsExpanded = false
    root.provenanceExpanded = false
    Qt.callLater(root.hydrateAnalysis)
    Qt.callLater(function() { if (activeFlick) activeFlick.contentY = 0 })
  }

  function openPluginFromAlert(pluginId) {
    if (root.pluginById(pluginId)) root.openPlugin(pluginId)
  }

  // Open a plugin's detail sheet from a LOCAL HITS row in the Rules view: this crosses
  // views, so push a return frame and switch to Overview first (doc 03 §13).
  function openPluginFromRule(pluginId) {
    if (!root.pluginById(pluginId)) return
    root.pushReturnFrame()
    root._selectTab("overview")
    root.openPlugin(pluginId)
  }

  // Pop one depth level. A cross-view return frame is consumed first (doc 03 §13),
  // then the current view's own depth stack.
  function popDepth() {
    if (root.returnFrame) return root.popReturnFrame()
    if (root.activeTabKey === "flow" && (root.flowDepth >= 1 || root.flowLens === "trace")) {
      root.flowPopDepth(); return true
    }
    if (root.activeTabKey === "overview" && root.overviewDepth >= 1) {
      var id = root.selectedPluginId
      root.overviewDepth = 0
      root.focusSection = "plugins"
      root.selectedIndex = 0
      if (root.vm && root.vm.plugins) {
        for (var i = 0; i < root.vm.plugins.length; i++)
          if (root.vm.plugins[i].id === id) { root.selectedIndex = i; break }
      }
      root.cursorActive = true
      Qt.callLater(function() { if (activeFlick) activeFlick.contentY = 0 })
      Qt.callLater(root.clampCursor)
      return true
    }
    return false
  }

  function toggleBackups() {
    root.showPluginBackups = !root.showPluginBackups
    Qt.callLater(root.clampCursor)
  }
  function toggleOverrides() { root.overrideDetailsExpanded = !root.overrideDetailsExpanded }
  function updateCatalog() { if (!root.navigationLocked) root.updateMarketplace() }
  function beginSchedule() { root.beginScheduleInstall(root.schedulePolicyChoice || "advisory") }
  function analyzeSelected() { root.ensureAnalysis() }

  function activateSource(i) {
    if (i === 1) root.updateCatalog()
    else if (i === 2) root.beginSchedule()
    else if (i === 3) root.toggleOverrides()
  }

  // Copy a value to the clipboard through the argv wl-copy helper (no shell
  // interpolation of the value — 05 §9).
  function copyValue(v) {
    var s = String(v || "")
    if (s === "") return
    Util.execArgv(["wl-copy", "--", s])
  }
  function copyIdentityRow(i) {
    var rows = root.trustIdentityRows()
    if (i >= 0 && i < rows.length && rows[i].copyable) root.copyValue(rows[i].value)
  }

  // Review-item / class / coverage / provenance expansion (one open at a time).
  function toggleFinding(key) {
    root.expandedFindingKey = (root.expandedFindingKey === key ? "" : String(key))
  }
  function toggleClass(cls) {
    if (root.expandedClass === cls) { root.expandedClass = ""; root.classShowAll = "" }
    else { root.expandedClass = String(cls); root.classShowAll = "" }
  }
  function toggleClassByIndex(i) {
    var g = root.capabilityGroups()
    if (i >= 0 && i < g.length) root.toggleClass(g[i].cls)
  }
  function toggleCoverageFileRefs() { root.coverageFileRefsExpanded = !root.coverageFileRefsExpanded }
  function toggleProvenance() { root.provenanceExpanded = !root.provenanceExpanded }

  function activateReview(i) {
    var a = root.analysisReport
    if (!a || !a.findings || a.findings.length === 0) { root.analyzeSelected(); return }
    if (i >= 0 && i < a.findings.length) root.toggleFinding(root.findingKey(a.findings[i]))
  }

  // Open a rule from a review item or a Baseline covering-rule row: push a cross-view
  // return frame, switch to the Rules view and expand that rule's sheet (doc 03 §13).
  function openRuleFromReview(ruleId) {
    if (String(ruleId || "") === "") return
    root.pushReturnFrame()
    root.goToRule(String(ruleId))
  }

  // ---- Trust Flow: layout, cursor, queue and lenses (doc 04 §4, §6, §10) -------

  // Numeric geometry for FlowLayout (§4.3). openW clamps so the focus pair never
  // collapses on a very narrow popup; columns snap (no Behavior on widths).
  function flowGeo(sameEpoch) {
    var railW = Style.space(28), pairGutter = Style.space(72), railGutter = Style.space(12)
    var w = root.flowBodyWidth
    var openW = (w - 2 * railW - pairGutter - 2 * railGutter) / 2
    return {
      orderEpoch: root.flowOrderEpoch, sameEpoch: sameEpoch === true, previousKeys: root.flowPrevKeys,
      maxRows: Math.max(1, root.flowMaxRows), headerH: Style.space(20), rowH: Style.spacing.popupRowHeight,
      pair: root.flowPair, railW: railW, openW: Math.max(Style.space(40), openW),
      pairGutter: pairGutter, railGutter: railGutter, offsets: root.flowOffsets
    }
  }

  // per-live-plugin analysis state word for the graph (§8): analyzing / unavailable
  // are held in analysisStateById; analyzed / not analyzed come from the cache.
  function flowAnalysisStateMap() {
    var m = ({})
    var plugins = (root.inventoryReport && root.inventoryReport.plugins) || []
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i]
      if (p.classification === "backup") continue
      var s = root.analysisStateById[p.id]
      if (s === "analyzing" || s === "unavailable") { m[p.id] = s; continue }
      m[p.id] = root.resolvedAnalysisFor(p) ? "analyzed" : "not analyzed"
    }
    return m
  }

  function buildFlowInputData() {
    var plugins = (root.inventoryReport && root.inventoryReport.plugins) || []
    var analysisById = ({})
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i]
      if (p.classification === "backup") continue
      analysisById[p.id] = root.resolvedAnalysisFor(p)
    }
    var enf = ({})
    if (root.selectedPluginId && root.enforcementDecision !== undefined && root.enforcementDecision !== null)
      enf[root.selectedPluginId] = { decision: root.enforcementDecision }
    return ViewModel.flowInput({
      inventory: root.inventoryReport, analysisById: analysisById,
      analysisStateById: root.flowAnalysisStateMap(), statusById: root.pluginStatuses,
      enforcementById: enf, alerts: root.alerts, coverage: root.coverageReport,
      rulesList: root.rulesListReport, scope: root.flowScope,
      filters: { backups: root.showPluginBackups }
    })
  }

  // Full build: reassign `flowNodes` only when membership or content changed (§3.2).
  function rebuildFlow() {
    if (root.activeTabKey !== "flow" || !root.cliVerified || root.flowBodyWidth <= 0) return
    var input = root.buildFlowInputData()
    var layout = FlowLayout.build(input, root.flowGeo(root.flowSameEpoch))
    root.flowLayoutObj = layout
    if (layout.membershipKey !== root.flowMembershipKey || layout.contentKey !== root.flowContentKey) {
      root.flowNodes = layout.nodes
      root.flowMembershipKey = layout.membershipKey
      root.flowContentKey = layout.contentKey
    }
    root.flowGeometry = layout.geometry
    var pk = []
    for (var c = 0; c < layout.nodes.length; c++) {
      var ks = []
      for (var n = 0; n < layout.nodes[c].length; n++) ks.push(layout.nodes[c][n].key)
      pk.push(ks)
    }
    root.flowPrevKeys = pk
    root.flowSameEpoch = true            // subsequent rebuilds this epoch preserve order
    root.clampFlowCursor()
    root.recomputeFlowHot()
  }

  // Navigation: geometry + edges + paths only; TrustFlow.nodes is never reassigned.
  function relayoutFlow() {
    if (!root.flowLayoutObj) return
    var r = FlowLayout.relayout(root.flowLayoutObj, root.flowGeo(true))
    root.flowLayoutObj.edges = r.edges
    root.flowLayoutObj.byNode = r.byNode
    root.flowLayoutObj.keyPos = r.keyPos
    root.flowGeometry = r.geometry
    root.recomputeFlowHot()
  }

  function recomputeFlowHot() {
    if (!root.flowLayoutObj) { root.flowPaths = ({}); root.flowHotKeys = ({}); return }
    var h = FlowLayout.hot(root.flowLayoutObj, root.flowCursorKey(), root.flowPinnedKey)
    root.flowPaths = h.paths
    root.flowHotKeys = h.hotKeys
  }

  function flowCursorKey() {
    if (root.focusSection.indexOf("col-") !== 0) return ""
    var col = Number(root.focusSection.slice(4))
    var nodes = root.flowNodes[col]
    return (nodes && nodes[root.selectedIndex]) ? nodes[root.selectedIndex].key : ""
  }

  function clampFlowCursor() {
    if (root.focusSection.indexOf("col-") !== 0) return
    var col = Number(root.focusSection.slice(4))
    var nodes = root.flowNodes[col] || []
    if (root.selectedIndex < 0) root.selectedIndex = 0
    if (root.selectedIndex > nodes.length - 1) root.selectedIndex = Math.max(0, nodes.length - 1)
  }

  // h / l across columns: land on the nearest node connected to the previous cursor
  // node (a hot edge always survives); a rail slides open; h at the left edge pops.
  function flowMoveCursorH(delta) {
    var col = Number(root.focusSection.slice(4))
    var next = col + delta
    if (next < 0) { if (root.flowDepth > 0) root.flowPopDepth(); return }
    if (next > 3) return
    var nodes = root.flowNodes
    if (!nodes[next] || nodes[next].length === 0) return
    var fromKey = (nodes[col] && nodes[col][root.selectedIndex]) ? nodes[col][root.selectedIndex].key : ""
    var connected = root.flowNearestConnected(fromKey, next)
    root.flowCol = next
    root.focusSection = "col-" + next
    root.selectedIndex = connected >= 0 ? connected : Math.min(root.selectedIndex, nodes[next].length - 1)
    root.flowEnsurePairOpen(next)
    root.flowEnsureCursorVisible()
    root.recomputeFlowHot()
  }

  function flowNearestConnected(fromKey, targetCol) {
    var lay = root.flowLayoutObj
    if (!lay || fromKey === "") return -1
    var inc = lay.byNode[fromKey] || []
    var targets = ({})
    for (var i = 0; i < inc.length; i++) {
      var e = lay.edges[inc[i]]
      targets[e.a === fromKey ? e.b : e.a] = true
    }
    var nodes = root.flowNodes[targetCol] || []
    for (var j = 0; j < nodes.length; j++) if (targets[nodes[j].key]) return j
    return -1
  }

  // Slide the focus pair so `col` is open, keeping the side the cursor came from.
  function flowEnsurePairOpen(col) {
    if (root.flowPair[col] === true) return
    var p
    if (col >= 3) p = 2
    else if (col <= 0) p = 0
    else p = (root.flowPair[col - 1] === true) ? col : (col - 1)
    if (p > 2) p = 2
    if (p < 0) p = 0
    var np = [false, false, false, false]; np[p] = true; np[p + 1] = true
    root.flowPair = np
    root.relayoutFlow()
  }

  function flowEnsureCursorVisible() {
    var col = root.flowCol
    var gcol = root.flowGeometry.cols && root.flowGeometry.cols[col]
    if (!gcol) return
    var rows = root.flowGeometry.rows
    var band = gcol.realRows || rows
    var offset = gcol.offset || 0
    var idx = root.selectedIndex
    if (idx < offset) offset = idx
    else if (idx >= offset + band) offset = idx - band + 1
    var maxOffset = Math.max(0, (gcol.count || 0) - rows)   // last `rows` nodes fill the window
    var offs = root.flowOffsets.slice()
    offs[col] = Math.max(0, Math.min(offset, maxOffset))
    root.flowOffsets = offs
    root.relayoutFlow()
  }

  // Called after every cursor move (keyboard or hover) while in Flow.
  function afterCursorMove() {
    if (root.activeTabKey !== "flow" || !root.flowLayoutObj) return
    if (root.focusSection.indexOf("col-") === 0) {
      root.flowCol = Number(root.focusSection.slice(4))
      root.flowEnsureCursorVisible()
    }
    root.recomputeFlowHot()
  }

  // Enter on a node: unpinned → pin; pinned → open per node kind (§6.1 table).
  function flowActivateNode() {
    var key = root.flowCursorKey()
    if (key === "") return
    if (root.flowPinnedKey !== key) { root.flowPinnedKey = key; root.recomputeFlowHot(); return }
    var sep = key.indexOf("|")
    var kind = key.slice(0, sep), id = key.slice(sep + 1)
    if (kind === "plugin") { if (root.flowDepth === 0) root.openFlowPlugin(id); else root.openPluginFromFlow(id) }
    else if (kind === "class") {
      if (root.flowDepth === 0) {
        // Pinned class → Matrix lens, cursor on that class's column (§6.1).
        root.flowLens = "matrix"
        var cols = root.flowMatrixColumns()
        root.flowMatrixCol = Math.max(0, cols.indexOf(id))
        root.focusSection = "matrix"; root.selectedIndex = 0; root.cursorActive = true
        root.rebuildFlow()
      } else { root.flowTraceClass = id; root.flowTracePlugin = root.flowScope.id; root.openFlowTrace() }
    }
    else if (kind === "rule") {
      // Z0: rule sheet (§6.1). Z1: Z2 trace of the scope plugin × the rule's class.
      if (root.flowDepth >= 1) {
        var clsForRule = root.flowClassForRule(key)
        if (clsForRule !== "") {
          root.flowTracePlugin = root.flowScope.id; root.flowTraceClass = clsForRule; root.openFlowTrace()
        } else root.openRuleFromFlow(id)
      } else root.openRuleFromFlow(id)
    }
    else if (kind === "baseline") root.openBaselineFromFlow(id)
  }

  // The class a rule hangs off (the class → rule edge), for tracing a rule node.
  function flowClassForRule(ruleKey) {
    var lay = root.flowLayoutObj
    if (!lay) return ""
    var inc = lay.byNode[ruleKey] || []
    for (var i = 0; i < inc.length; i++) {
      var e = lay.edges[inc[i]]
      var other = e.a === ruleKey ? e.b : e.a
      if (other.indexOf("class|") === 0) return other.slice("class|".length)
    }
    return ""
  }
  // Is there a direct edge between two node keys (e.g. a plugin → class edge)?
  function flowEdgeExists(aKey, bKey) {
    var lay = root.flowLayoutObj
    if (!lay) return false
    var inc = lay.byNode[aKey] || []
    for (var i = 0; i < inc.length; i++) {
      var e = lay.edges[inc[i]]
      if ((e.a === aKey && e.b === bKey) || (e.a === bKey && e.b === aKey)) return true
    }
    return false
  }

  function flowActivateLens() {
    root.flowLens = root.selectedIndex === 1 ? "matrix" : "graph"
    root.rebuildFlow()
  }

  function flowInspectorAction() {
    // the inspector Button is always read-only navigation (Open / Trace / Analyze)
    if (root.flowLens === "matrix") { root.flowMatrixActivate(); return }
    if (root.flowLens === "trace") return
    var facts = root.flowInspectorFacts()
    if (facts.actionKind === "analyze") root.flowAnalyzeCursor()
    else if (facts.actionKind === "open" || facts.actionKind === "trace") root.flowActivateOpen()
  }
  // force the open branch of flowActivateNode regardless of pin state (the inspector
  // Button acts on the cursor node directly).
  function flowActivateOpen() {
    var key = root.flowCursorKey()
    if (key === "") return
    root.flowPinnedKey = key
    root.flowActivateNode()
  }

  // Z1: one plugin's reach. Fresh epoch, default pair CAPABILITIES | RULES (§9.3).
  function openFlowPlugin(id) {
    if (!id) return
    root.flowScope = { kind: "plugin", id: String(id) }
    root.flowDepth = 1
    root.flowLens = "graph"
    root.flowPinnedKey = ""
    root.flowPair = [false, true, true, false]
    root.flowOffsets = [0, 0, 0, 0]
    root.flowOrderEpoch++
    root.flowSameEpoch = false
    root.flowCol = 0
    root.cursorActive = false
    root.focusSection = "col-0"
    root.selectedIndex = 0
    root.rebuildFlow()
  }

  // Enter on a pinned plugin at Z1 → the Overview detail sheet (cross-view).
  function openPluginFromFlow(id) {
    if (!root.pluginById(id)) return
    root.pushReturnFrame()
    root._selectTab("overview")
    root.openPlugin(id)
  }
  function openRuleFromFlow(id) {
    if (String(id || "") === "") return
    root.pushReturnFrame()
    root.goToRule(String(id))
  }
  function openBaselineFromFlow(xid) {
    if (String(xid || "") === "") return
    root.pushReturnFrame()
    root.goToBaselineRow(String(xid))
  }
  function openFlowTrace() {
    // Z2 trace of the plugin × class (T3.11 renders the body). Trace is a lens overlay;
    // popping restores the lens it was opened from (graph or matrix), not a depth level.
    if (root.flowLens !== "trace") root.flowTraceReturnLens = root.flowLens
    root.flowLens = "trace"
    root.cursorActive = false
    root.focusSection = "hero"
    root.rebuildFlow()
  }

  // `2` from an Overview plugin detail sheet: switch to Flow and open Z1 scoped to that
  // plugin (doc 04 §6.1), rather than resetting to Z0 the way the chip does.
  function openFlowForPlugin(id) {
    if (root.navigationLocked) return
    if (!id) { root.setViewByKey("flow"); return }
    root._selectTab("flow")
    root.overviewDepth = 0
    root.returnFrame = null
    root.finderActive = false
    root.ensureRulesList(); root.ensureCoverage()
    root.openFlowPlugin(id)
    Qt.callLater(function() { if (activeFlick) activeFlick.contentY = 0 })
  }

  // Enter the Flow view at Z0 with the cursor still hidden (setActive left it on hero).
  function enterFlowZ0() {
    root.flowScope = { kind: "all", id: "" }
    root.flowDepth = 0
    root.flowLens = "matrix"          // Z0/all plugins opens on the readable Matrix (T4.1)
    root.flowMatrixAllClasses = false
    root.flowPinnedKey = ""
    root.flowPair = [true, true, false, false]
    root.flowOffsets = [0, 0, 0, 0]
    root.flowCol = 0
    root.flowOrderEpoch++
    root.flowSameEpoch = false
    root.rebuildFlow()
  }

  function flowPopToZ0() {
    root.flowScope = { kind: "all", id: "" }
    root.flowDepth = 0
    root.flowLens = "matrix"          // returning to all plugins lands on Matrix (T4.1)
    root.flowPinnedKey = ""
    root.flowPair = [true, true, false, false]
    root.flowOffsets = [0, 0, 0, 0]
    root.flowOrderEpoch++
    root.flowSameEpoch = false
    root.flowCol = 0
    root.focusSection = "col-0"
    root.selectedIndex = 0
    root.cursorActive = true
    root.rebuildFlow()
  }
  function flowPopDepth() {
    if (root.flowLens === "trace") {
      // restore the lens the trace was opened from (graph at Z1, or matrix at Z0/Z1)
      root.flowLens = root.flowTraceReturnLens || "graph"
      root.cursorActive = true
      root.rebuildFlow(); return
    }
    if (root.flowDepth >= 1) root.flowPopToZ0()
  }

  // ---- analysis queue (doc 04 §10.1, T3.8) — one Process, sequential ------------
  function setAnalysisState(id, state) {
    var m = ({})
    for (var k in root.analysisStateById) m[k] = root.analysisStateById[k]
    m[id] = state
    root.analysisStateById = m
  }
  function startNextAnalysis() {
    if (analysisProcess.running) return
    if (root.analysisQueue.length === 0) return
    var q = root.analysisQueue.slice()
    var id = q.shift()
    root.analysisQueue = q
    var plugin = root.pluginById(id)
    if (!plugin) { root.startNextAnalysis(); return }
    root.setAnalysisState(id, "analyzing")
    root.analysisRequestId++
    analysisProcess.sweepGeneration = root.analysisSweepGeneration
    analysisProcess.startFor(id, root.analysisRequestId)
  }
  function flowEnqueueAnalysis(id) {
    if (!id || !root.cliVerified) return
    var plugin = root.pluginById(id)
    if (!plugin || root.resolvedAnalysisFor(plugin)) return
    if (root.analysisStateById[id] === "analyzing" || root.analysisQueue.indexOf(id) >= 0) return
    root.analysisQueue = root.analysisQueue.concat([String(id)])
    root.startNextAnalysis()
  }
  // `a`: queue the cursor plugin. Never changes the selection (§6.1).
  function flowAnalyzeCursor() {
    var key = root.flowCursorKey()
    if (key.indexOf("plugin|") !== 0) return
    root.flowEnqueueAnalysis(key.slice("plugin|".length))
  }
  // `A`: queue every live plugin whose analysis cache misses.
  function flowAnalyzeAll() {
    var plugins = (root.inventoryReport && root.inventoryReport.plugins) || []
    var q = root.analysisQueue.slice()
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i]
      if (p.classification === "backup") continue
      if (root.resolvedAnalysisFor(p)) continue
      if (root.analysisStateById[p.id] === "analyzing" || q.indexOf(p.id) >= 0) continue
      q.push(p.id)
    }
    root.analysisQueue = q
    root.startNextAnalysis()
  }
  // `x`: unpin; while a sweep runs, also drop the rest of the queue (the running
  // process finishes; nothing is mutated).
  function flowUnpinOrCancel() {
    if (root.analysisQueue.length > 0) { root.analysisSweepGeneration++; root.analysisQueue = [] }
    if (root.flowPinnedKey !== "") { root.flowPinnedKey = ""; root.recomputeFlowHot() }
  }
  // `t`: Z2 for the current plugin × class (doc 04 §6.1). In Matrix it traces the
  // cursor cell; at Z1 it traces the scope plugin × the cursor class.
  function flowTrace() {
    if (root.flowLens === "matrix") {
      var rows = root.flowMatrixRows()
      var cols = root.flowMatrixColumns()
      if (root.selectedIndex >= 0 && root.selectedIndex < rows.length && root.flowMatrixCol >= 0
          && root.flowMatrixCol < cols.length && rows[root.selectedIndex].analyzed) {
        root.flowTracePlugin = rows[root.selectedIndex].id
        root.flowTraceClass = cols[root.flowMatrixCol]
        root.openFlowTrace()
      }
      return
    }
    var key = root.flowCursorKey()
    if (root.flowScope.kind === "plugin") {
      // Z1: scope plugin × cursor class, or × the rule's class.
      if (key.indexOf("class|") === 0) {
        root.flowTracePlugin = root.flowScope.id
        root.flowTraceClass = key.slice("class|".length)
        root.openFlowTrace()
      } else if (key.indexOf("rule|") === 0) {
        var c1 = root.flowClassForRule(key)
        if (c1 !== "") { root.flowTracePlugin = root.flowScope.id; root.flowTraceClass = c1; root.openFlowTrace() }
      }
      return
    }
    // Z0: a plugin must be pinned and the cursor on a connected class or rule (§6.1).
    if (root.flowPinnedKey.indexOf("plugin|") === 0) {
      var pid = root.flowPinnedKey.slice("plugin|".length)
      var cls = ""
      if (key.indexOf("class|") === 0 && root.flowEdgeExists(root.flowPinnedKey, key)) cls = key.slice("class|".length)
      else if (key.indexOf("rule|") === 0) {
        var c2 = root.flowClassForRule(key)
        if (c2 !== "" && root.flowEdgeExists(root.flowPinnedKey, "class|" + c2)) cls = c2
      }
      if (cls !== "") { root.flowTracePlugin = pid; root.flowTraceClass = cls; root.openFlowTrace() }
    }
  }
  function flowToggleLens() {
    root.flowLens = root.flowLens === "matrix" ? "graph" : "matrix"
    root.rebuildFlow()
  }
  function flowToggleMatrixClasses() {
    if (root.flowLens !== "matrix") return
    root.flowMatrixAllClasses = !root.flowMatrixAllClasses
  }

  // ---- Flow header value + inspector facts (§5, §7, §9) -------------------------
  function flowHeaderText() {
    if (root.flowLens === "trace") return "TRACE"
    return root.flowScope.kind === "plugin"
      ? "ANALYSIS PATHS · " + root.flowScope.id : "ANALYSIS PATHS · ALL PLUGINS"
  }
  // The plain-language legend under the heading (T4.1): names the four stages in order
  // so PL / CA / RU / BA rails are never an unexplained abbreviation. Not shown in Trace.
  function flowSubtitle() {
    return "Plugin → observed capability → detecting rule → Baseline V3 mapping"
  }
  // The persistent, honest incomplete-analysis callout (T4.1): absent paths are unanalyzed
  // plugins, not absent capabilities. Empty string when every live plugin is analyzed.
  function flowIncompleteText() {
    if (!root.vm) return ""
    var analyzed = root.vm.analyzedCount, live = root.vm.liveCount
    if (live <= 0 || analyzed >= live) return ""
    return analyzed + " of " + live + " plugins analyzed — paths are incomplete. Press A to analyze the rest."
  }
  function flowHeaderValue() {
    if (root.flowLens === "trace" || !root.vm) return ""
    if (root.flowScope.kind === "plugin") {
      // Z1 header value is the scope plugin's occurrence count (§9.3: "29 OCCURRENCES").
      var pn = (root.flowNodes[0] && root.flowNodes[0][0]) ? root.flowNodes[0][0] : null
      return (pn && pn.analyzed) ? (pn.occurrences + " OCCURRENCES") : ""
    }
    var analyzed = root.vm.analyzedCount, live = root.vm.liveCount
    var v = analyzed + " OF " + live + " ANALYZED"
    if (root.flowLens === "matrix") {
      var shown = root.flowMatrixAllClasses ? 17 : ((root.flowLayoutObj && root.flowLayoutObj.nodes[1]) ? root.flowLayoutObj.nodes[1].length : 0)
      v += " · " + shown + " OF 17 CLASSES (c)"
    }
    if (root.showPluginBackups && root.vm.backupCount > 0) v += " · SHOWING " + root.vm.backupCount + " BACKUPS (NOT SCANNED)"
    else if (root.vm.backupCount > 0) v += " · HIDING " + root.vm.backupCount + " BACKUPS"
    return v
  }

  // The four-line InspectorStrip for the cursor node (§9). Returns
  // { title, lines[], action, actionEnabled, actionKind }.
  // The inspector is never blank (T4.1): before the first cursor move it says what a
  // selection reveals, plus the edge / cell vocabulary. Verdict-free.
  function flowInspectorDefault() {
    if (root.flowLens === "matrix")
      return { title: "", lines: [
          "Rows are plugins · columns are capability classes.",
          "Move onto a cell, then t to trace what was observed.",
          "digit = occurrences · · = none observed · – = not analyzed" ],
        action: "", actionEnabled: false, actionKind: "" }
    return { title: "", lines: [
        "Move onto a plugin to see the capabilities it uses,",
        "the rules that found them, and its Baseline V3 map.",
        "solid = parser-backed · dashed = text match only" ],
      action: "", actionEnabled: false, actionKind: "" }
  }
  function flowInspectorFacts() {
    var empty = root.flowInspectorDefault()
    if (root.flowLens === "matrix") return root.flowMatrixInspector()
    if (root.flowLens === "trace") return root.flowTraceInspector()
    var key = root.flowCursorKey()
    if (key === "" || !root.flowLayoutObj) return empty
    var col = Number(root.focusSection.slice(4))
    var node = root.flowNodes[col] ? root.flowNodes[col][root.selectedIndex] : null
    if (!node) return empty
    var sep = key.indexOf("|"), kind = key.slice(0, sep), id = key.slice(sep + 1)
    if (kind === "plugin") return root.flowInspectPlugin(id, node)
    if (kind === "class") return root.flowInspectClass(id, node)
    if (kind === "rule") return root.flowInspectRule(id, node)
    if (kind === "baseline") return root.flowInspectBaseline(id, node)
    return empty
  }
  function flowInspectPlugin(id, node) {
    var p = root.vm ? root.vm.pluginsById[id] : null
    var state = root.analysisStateById[id]
    var qpos = root.analysisQueue.indexOf(id)
    var lines = []
    if (state === "analyzing") lines.push("Loading analysis…")
    else if (qpos >= 0) lines.push("Queued (" + (qpos + 1) + " ahead)")
    else if (node.hollow) lines.push("Not analyzed. Press a or Analyze; A analyzes all.")
    else lines.push(node.occurrences + " occurrences · " + node.classes + " classes"
      + (node.reviewItems > 0 ? " · " + Labels.reviewCount(node.reviewItems) : "")
      + (node.limits > 0 ? " · " + node.limits + " limits" : ""))
    if (p) {
      lines.push(p.trustLong || "Baseline status unavailable")
      lines.push(root.flowMarketplaceLine(id))
    }
    var canAnalyze = !node.analyzed && state !== "analyzing"
    return { title: id, lines: lines.slice(0, 3),
      action: canAnalyze ? "Analyze (a)" : "Open (Enter)",
      actionEnabled: canAnalyze ? (root.cliVerified && !root.navigationLocked) : true,
      actionKind: canAnalyze ? "analyze" : "open" }
  }
  function flowMarketplaceLine(id) {
    var mk = root.marketplaceByPlugin(id)
    if (!mk) return "Catalog entry not matched · Catalog says: not stated"
    var claim = root.marketplaceClaim(mk)
    var verif = claim ? String(claim.verification_status || "unverified") : "not stated"
    return Labels.marketplaceStatusShort(mk.status) + " · Catalog says: " + verif
  }
  function flowInspectClass(id, node) {
    var lines = [node.occurrences + " occurrences in " + node.plugins + " plugins"
      + (node.reviewItems > 0 ? " · " + Labels.reviewCount(node.reviewItems) : " · no review items")]
    lines.push(Labels.capability(id))
    return { title: Labels.capability(id), lines: lines,
      action: root.flowDepth === 0 ? "Matrix (m)" : "Trace (t)", actionEnabled: true,
      actionKind: root.flowDepth === 0 ? "open" : "trace" }
  }
  function flowInspectRule(id, node) {
    var occ = node.occurrences, rev = node.reviewItems
    var split = "LOCAL HITS " + node.plugins + " plugins · " + Labels.occurrences(occ)
      + " · " + (rev > 0 ? Labels.reviewCount(rev) : "no review items")
    return { title: id, lines: [
        (node.title || "") + (node.severity ? " · catalog severity " + node.severity : ""),
        split ],
      action: "Open rule (Enter)", actionEnabled: true, actionKind: "open" }
  }
  function flowInspectBaseline(id, node) {
    var line = node.covered
      ? ((node.viaRules && node.viaRules.length > 0)
          ? (Labels.relation(node.relation) + " · via rule " + node.viaRules[0])
          : ((node.viaClasses && node.viaClasses.length > 0)
              ? ("via class " + Labels.capability(node.viaClasses[0]) + " · " + Labels.relation(node.relation))
              : (Labels.relation(node.relation))))
      : "Not covered by OmaSafe"
    return { title: id, lines: [line], action: "Open coverage row (Enter)",
      actionEnabled: true, actionKind: "open" }
  }

  // ---- Matrix lens (doc 04 §9.5, T3.10) ----------------------------------------
  // Columns are the observed classes in CATALOG order by default (a column means the
  // same class on every row), or all 17 on `c`.
  function flowObservedClasses() {
    var present = ({})
    var input = root.buildFlowInputData()
    for (var i = 0; i < input.classes.length; i++) present[input.classes[i].id] = true
    var out = []
    for (var j = 0; j < Glyphs.capabilityOrder.length; j++)
      if (present[Glyphs.capabilityOrder[j]]) out.push(Glyphs.capabilityOrder[j])
    return out
  }
  function flowMatrixColumns() {
    return root.flowMatrixAllClasses ? Glyphs.capabilityOrder : root.flowObservedClasses()
  }
  function flowMatrixRows() {
    if (!root.vm) return []
    var rows = root.vm.plugins.slice()
    if (root.showPluginBackups) rows = rows.concat(root.vm.backups)
    if (root.flowScope.kind === "plugin")
      rows = rows.filter(function(p) { return p.id === root.flowScope.id })
    return rows
  }
  // The full grid model FlowView's MatrixGrid binds to.
  function flowMatrixModel() {
    var cols = root.flowMatrixColumns()
    var rows = root.flowMatrixRows()
    var out = []
    for (var i = 0; i < rows.length; i++) {
      var p = rows[i]
      var cells = []
      for (var c = 0; c < cols.length; c++) {
        var cls = cols[c]
        if (!p.analyzed) cells.push("–")
        else { var n = Number((p.counts || {})[cls] || 0); cells.push(n > 0 ? String(n) : "·") }
      }
      out.push({ id: p.id, bold: p.alerted === true, analyzed: p.analyzed === true, cells: cells })
    }
    return { columns: cols, rows: out }
  }
  function flowMatrixActivate() {
    var rows = root.flowMatrixRows()
    if (root.selectedIndex < 0 || root.selectedIndex >= rows.length) return
    var rowp = rows[root.selectedIndex]
    if (root.flowMatrixCol < 0) { root.openFlowPlugin(rowp.id); return }   // row label → Z1
    // A `–` cell (unanalyzed plugin) stays in Matrix and shows the inspector hint
    // (doc 04 §9.5) — it has no path to trace.
    if (!rowp.analyzed) return
    var cols = root.flowMatrixColumns()
    if (root.flowMatrixCol < cols.length) {
      root.flowTracePlugin = rowp.id; root.flowTraceClass = cols[root.flowMatrixCol]
      root.openFlowTrace()                                            // cell → Z2
    }
  }
  function flowMatrixInspector() {
    var rows = root.flowMatrixRows()
    var p = (root.selectedIndex >= 0 && root.selectedIndex < rows.length) ? rows[root.selectedIndex] : null
    if (!p) return root.flowInspectorDefault()
    var cols = root.flowMatrixColumns()
    if (root.flowMatrixCol < 0 || root.flowMatrixCol >= cols.length) {
      return { title: p.id, lines: [p.trustLong || ""], action: "Open (Enter)",
        actionEnabled: true, actionKind: "open" }
    }
    var cls = cols[root.flowMatrixCol]
    var n = p.analyzed ? Number((p.counts || {})[cls] || 0) : -1
    var l1 = !p.analyzed ? "not analyzed"
      : (n > 0 ? Labels.occurrences(n) + " · no review items" : "nothing observed")
    return { title: p.id + " × " + Labels.capability(cls), lines: [l1, p.trustLong || ""],
      action: "Trace (t)", actionEnabled: p.analyzed && n > 0, actionKind: "trace" }
  }

  // ---- Z2 Trace (doc 04 §9.4, T3.11) -------------------------------------------
  // Chain, EVIDENCE rows, FILE EDGES and COVERAGE LIMITS for the traced plugin × class.
  function flowTraceData() {
    var pid = root.flowTracePlugin !== "" ? root.flowTracePlugin
      : (root.flowScope.kind === "plugin" ? root.flowScope.id : "")
    var cls = root.flowTraceClass
    var plugin = root.pluginById(pid)
    var analysis = plugin ? root.resolvedAnalysisFor(plugin) : null
    if (!analysis) return { available: false, pluginId: pid, className: cls }
    // EVIDENCE = this class's occurrence sites AND its review items (a class reached
    // only through findings still has evidence, doc 04 §9.4).
    var caps = (analysis.capabilities || []).filter(function(c) { return String(c.capability || "") === cls })
    var finds = (analysis.findings || []).filter(function(f) { return String(f.capability || "") === cls })
    var evidence = caps.map(function(c) {
      return { line: String(c.relative_path || "") + ":" + String(c.line || ""),
        detail: String(c.detail || ""), confidence: Labels.confidence(c.confidence) }
    }).concat(finds.map(function(f) {
      return { line: String(f.relative_path || "") + ":" + String(f.line || ""),
        detail: "review item", confidence: Labels.confidence(f.confidence) }
    }))
    // the covering rule(s) for this class in this plugin (occurrences + findings)
    var ruleSet = ({})
    for (var i = 0; i < caps.length; i++)
      if (String(caps[i].source_rule_id || "") !== "") ruleSet[String(caps[i].source_rule_id)] = true
    for (var fi = 0; fi < finds.length; fi++)
      if (String(finds[fi].rule_id || "") !== "") ruleSet[String(finds[fi].rule_id)] = true
    var rules = Object.keys(ruleSet)

    // Baseline V3 relations on THIS path: rows whose omaRuleId is a covering rule
    // (rule → baseline chain), and rows whose omaCapability is this class (class-level).
    var cov = root.coverageReport
    var covRows = (cov && cov.coverage) ? cov.coverage : []
    var baselineRelations = [], viaClassIds = []
    for (var r = 0; r < covRows.length; r++) {
      var row = covRows[r]
      var rel = String(row.relation || "")
      var mark = rel === "structural-equivalent" ? "=" : (rel === "partial-overlap" ? "≈" : "")
      if (String(row.omaRuleId || "") !== "" && ruleSet[String(row.omaRuleId)])
        baselineRelations.push({ rule: String(row.omaRuleId), mark: mark, externalId: String(row.externalId || "") })
      if (String(row.omaCapability || "") === cls && String(row.omaRuleId || "") === "" && String(row.externalId || "") !== "")
        viaClassIds.push(String(row.externalId))
    }

    // FILE EDGES (the call graph) and COVERAGE LIMITS are plugin-level, not class-filtered:
    // TraceChain labels both sections plugin-wide so they never claim to be this path's
    // edges/limits (T4.0). Filtering them to a capability class would invent a relationship
    // the analysis does not carry.
    var edges = (analysis.invocation_edges || []).map(function(e) {
      return { line: String(e.relative_path || e.source || "") + ":" + String(e.line || ""),
        target: String(e.target || e.target_path || ""), state: String(e.coverage_state || e.target_coverage_state || "") }
    })
    var limits = Labels.groupLimitations(analysis.coverage_limitations || [])

    var occ = caps.length
    // chain lines (doc 04 §9.4): plugin -N- class ; - rule mark baseline ; via class list
    var chainLines = [ pid + " ─" + occ + "─ " + Labels.capability(cls) ]
    for (var b = 0; b < baselineRelations.length; b++)
      chainLines.push("─ " + baselineRelations[b].rule + " " + baselineRelations[b].mark + " " + baselineRelations[b].externalId)
    if (viaClassIds.length > 0)
      chainLines.push("via class " + Labels.capability(cls) + ": " + viaClassIds.join(" · "))

    return {
      available: true, pluginId: pid, className: cls,
      chain: chainLines.join("\n"), chainLines: chainLines,
      rule: rules.length > 0 ? rules[0] : "", rules: rules,
      baselineRelations: baselineRelations, viaClassIds: viaClassIds,
      evidence: evidence, edges: edges, limits: limits,
      evidenceCount: evidence.length, edgeCount: edges.length,
      limitCount: (analysis.coverage_limitations || []).length
    }
  }
  function flowTraceInspector() {
    var t = root.flowTraceData()
    if (!t.available) return { title: t.pluginId + " × " + t.className, lines: ["not analyzed"],
      action: "", actionEnabled: false, actionKind: "" }
    return { title: t.pluginId + " × " + Labels.capability(t.className),
      lines: [ t.evidenceCount + " occurrence sites", (t.rule ? "Rule " + t.rule : ""),
        "Presence in source, not permission or intent." ],
      action: "", actionEnabled: false, actionKind: "" }
  }

  // ---- detail-sheet data: capabilities, trust, claim, enforcement, provenance --

  function capabilityGroups() {
    var a = root.analysisReport
    if (!a || !a.capabilities) return []
    var by = ({}), order = []
    for (var i = 0; i < a.capabilities.length; i++) {
      var cls = String(a.capabilities[i].capability || "")
      if (cls === "") continue
      if (by[cls] === undefined) { by[cls] = 0; order.push(cls) }
      by[cls]++
    }
    var out = []
    for (var j = 0; j < order.length; j++) out.push({ cls: order[j], count: by[order[j]] })
    out.sort(function(x, y) { return y.count - x.count })
    return out
  }
  function capabilityGroupCount() { return root.capabilityGroups().length }

  function trustIdentityRows() {
    var c = root.statusReport && root.statusReport.current
    if (!c) return []
    return [
      { label: "Head",   value: c.head ? String(c.head) : "unavailable",             mono: true, copyable: !!c.head },
      { label: "Tree",   value: c.tree ? String(c.tree) : "unavailable",             mono: true, copyable: !!c.tree },
      { label: "Digest", value: c.content_digest ? String(c.content_digest) : "unavailable", mono: true, copyable: !!c.content_digest }
    ]
  }

  function trustActionModel() {
    var st = root.statusReport ? String(root.statusReport.state) : ""
    if (st === "") return []
    var digest = root.statusReport && root.statusReport.current
      ? String(root.statusReport.current.content_digest || "") : ""
    var hasBaseline = !!(root.statusReport && root.statusReport.trusted)
    var removeEnabled = hasBaseline && root.identitySafeMutations
    var list = []
    if (st === "untrusted") list.push({ label: "Record baseline", enabled: digest !== "", tooltip: "Record baseline" })
    else if (st === "changed") list.push({ label: "Replace baseline", enabled: digest !== "", tooltip: "Replace baseline" })
    list.push({ label: "Remove baseline", enabled: removeEnabled,
      tooltip: removeEnabled ? "Remove baseline" : "Remove baseline needs a recorded baseline and a CLI that can verify its digest" })
    return list
  }
  function trustCondition() {
    var hasBaseline = !!(root.statusReport && root.statusReport.trusted)
    if (!hasBaseline) return "needs a recorded baseline"
    if (!root.identitySafeMutations) return "Remove baseline needs a CLI that can verify its digest"
    return ""
  }
  function trustActionTriggered(i) {
    var m = root.trustActionModel()
    if (i < 0 || i >= m.length || !m[i].enabled) return
    if (String(m[i].label).indexOf("Remove") === 0) root.beginRemove()
    else root.beginTrust()
  }

  function _ageShort(seconds, stale) {
    var s = Math.max(0, Math.round(Number(seconds) || 0))
    var t
    if (s < 3600) t = Math.floor(s / 60) + " MIN"
    else if (s < 86400) t = Math.floor(s / 3600) + " H"
    else t = Math.floor(s / 86400) + " DAYS"
    return t + (stale ? " · STALE" : "")
  }
  function claimHeaderValue() {
    var inv = root.inventoryReport
    if (!inv) return ""
    var c7 = String(inv.marketplace_repository_commit || "").slice(0, 7)
    return ("CATALOG " + c7 + " · " + root._ageShort(inv.marketplace_age_seconds, inv.marketplace_stale === true))
  }
  function claimRows() {
    var sel = root.vm && root.vm.pluginsById ? root.vm.pluginsById[root.selectedPluginId] : null
    var m = sel ? sel.marketplace : null
    if (!m) return ["Catalog snapshot unavailable"]
    var claim = sel.claim
    var stale = root.inventoryReport && root.inventoryReport.marketplace_stale === true
    var rows = [Labels.marketplaceStatus(m.status)]
    if (String(m.status) === "conflict") {
      if (m.reason) rows.push(String(m.reason))
      if (sel.raw && (sel.raw.repository === null || sel.raw.repository === undefined))
        rows.push("Installed repository: unavailable (no git remote)")
    }
    var ver = Labels.verificationStatus(claim ? claim.verification_status : null)
    if (!(stale && ver.indexOf("verified") >= 0)) rows.push(ver)
    rows.push(Labels.installedMatchesListing(claim ? claim.installed_matches_listing : null))
    rows.push(Labels.upstreamMoved(claim ? claim.upstream_moved : null))
    if (m.disclaimer) rows.push(String(m.disclaimer))
    if (m.reason && String(m.status) !== "conflict") rows.push(String(m.reason))
    return rows
  }
  function claimActionModel() {
    var elig = root.updateEligible()
    return [{ label: "Review update", enabled: elig, tooltip: elig ? "Review update" : "Review update unavailable" }]
  }
  function claimCondition() {
    if (root.updateEligible()) return ""
    var m = root.marketplaceByPlugin(root.selectedPluginId)
    var claim = root.marketplaceClaim(m)
    if (!m || ["listed", "installed-differs"].indexOf(String(m.status)) < 0)
      return "needs catalog status listed (at or off the listed commit)"
    var st = root.statusReport ? String(root.statusReport.state) : ""
    if (!(root.statusReport && root.statusReport.trusted && ["unchanged", "clean", "acknowledged"].indexOf(st) >= 0))
      return "needs a matching baseline (" + (root.statusReport ? Labels.trustShort(root.statusReport.state, root.statusReport.reason, 0) : "unavailable") + ")"
    if (!(claim && String(claim.upstream_observed_commit || "") !== ""))
      return "needs an upstream commit claimed by the catalog"
    return "needs an analysis of the installed source (press a)"
  }
  function claimActionTriggered(i) { root.beginReviewUpdate() }

  function enforcementHeaderValue() {
    var d = root.enforcementDecision
    if (root.enforcementLoading && d === null) return ""
    if (d === null) return "NO DECISION"
    return Labels.evaluationState(d.evaluation_state).replace(/-/g, " ").toUpperCase()
  }
  function enforcementRows() {
    var d = root.enforcementDecision
    if (root.enforcementLoading && d === null) return ["Loading decision…"]
    if (root.enforcementError !== "" && d === null) return ["Decision unavailable: " + root.enforcementError + "."]
    if (d === null) return [Labels.enforcementNull]
    var rows = []
    rows.push(Labels.enforcementOutcome(d.outcome, d.authorization_basis, d.reason_codes,
      d.override_binding ? d.override_binding.expires_at : ""))
    rows.push(String(d.operation || "") + " · " + String(d.evaluated_at || ""))
    return rows
  }
  function enforcementActionModel() {
    var elig = root.enableEligible() && root.identitySafeMutations
    return [{ label: "Enable", enabled: elig, tooltip: elig ? "Enable" : "Enable unavailable" }]
  }
  function enforcementCondition() {
    if (root.enableEligible() && root.identitySafeMutations) return ""
    if (!root.enableEligible()) return "Enable applies only to plugins that are disabled and inactive."
    return "Enable needs a CLI that can verify the displayed source identity."
  }
  function enforcementActionTriggered(i) { root.beginEnable() }

  // Format a provenance value: scalars verbatim, objects as `k: v · k: v` (never
  // [object Object]), null/empty as "unavailable".
  function _provValue(v) {
    if (v === null || v === undefined || v === "") return "unavailable"
    if (typeof v === "object") {
      if (Array.isArray(v)) return v.map(function(x) { return String(x) }).join(", ")
      var parts = []
      for (var k in v) parts.push(k + ": " + String(v[k]))
      return parts.length > 0 ? parts.join(" · ") : "unavailable"
    }
    return String(v)
  }
  function provenanceRows() {
    var a = root.analysisReport
    if (!a) return []
    var pid = a.policy_identity || {}
    var eq = a.equivalence || {}
    var parser = a.parser || {}
    var d = root.enforcementDecision
    function row(label, value, mono, copyable) {
      return { label: label, value: root._provValue(value),
        mono: mono === true, copyable: copyable === true && value !== null && value !== undefined && value !== "" }
    }
    var rows = [
      row("Analysis fingerprint", a.analysis_fingerprint, true, true),
      row("Analyzer version", pid.analyzer_version, false, false),
      row("Rule catalog", pid.rule_catalog_version, false, false),
      row("Rule catalog fingerprint", pid.rule_catalog_fingerprint, true, true),
      row("Severity table", pid.severity_table_version, false, false),
      row("Parser versions", pid.parser_versions, false, false),
      row("Limits fingerprint", pid.limits_fingerprint, true, true),
      row("Equivalence map version", pid.equivalence_map_version, false, false),
      row("Supported surface", pid.supported_surface_version, false, false),
      row("Parser", parser, false, false),
      row("Equivalence", eq, false, false)
    ]
    if (d) {
      // A hash shown as one; never interpreted as a mode (doc 03 §5.4).
      rows.push(row("Enforcement policy fingerprint", d.enforcement_policy_identity, true, true))
      rows.push(row("Audit event id", d.audit_event_id, false, true))
    }
    return rows
  }

  // ---- Rules view: expansion and cross-view jumps ------------------------------

  function expandRule(id) {
    if (root.expandedRuleId === String(id)) { root.expandedRuleId = ""; return }
    root.expandedRuleId = String(id)
    root.explainRule(id)   // fetch external_equivalences for the sheet
  }
  function toggleBaseline(externalId) {
    root.expandedBaselineId = (root.expandedBaselineId === String(externalId) ? "" : String(externalId))
  }
  function jumpToBaseline(externalId) {
    root.expandedBaselineId = String(externalId)
    root.focusSection = "baseline"
    root.cursorActive = true
    if (root.vm && root.vm.baseline && root.vm.baseline.rows) {
      for (var i = 0; i < root.vm.baseline.rows.length; i++)
        if (root.vm.baseline.rows[i].externalId === String(externalId)) { root.selectedIndex = i; break }
    }
  }

  function _selectTab(key) {
    for (var i = 0; i < root.tabs.length; i++)
      if (root.tabs[i].key === key) { root.activeIndex = i; return }
  }

  // Switch to the Rules view (without clearing a return frame, unlike setActive) and
  // expand a rule's sheet with the cursor on that row.
  function goToRule(id) {
    root._selectTab("rules")
    root.overviewDepth = 0
    root.finderActive = false
    root.ensureRulesList()
    root.ensureCoverage()
    root.expandedRuleId = String(id)
    root.explainRule(id)
    root.focusSection = "rules"
    root.selectedIndex = 0
    root.cursorActive = true
    if (root.vm && root.vm.rules) {
      for (var i = 0; i < root.vm.rules.length; i++)
        if (root.vm.rules[i].id === String(id)) { root.selectedIndex = i; break }
    }
    Qt.callLater(function() { if (activeFlick) activeFlick.contentY = 0 })
  }

  function goToBaselineRow(externalId) {
    root._selectTab("rules")
    root.overviewDepth = 0
    root.finderActive = false
    root.ensureRulesList()
    root.ensureCoverage()
    root.jumpToBaseline(externalId)
    Qt.callLater(function() { if (activeFlick) activeFlick.contentY = 0 })
  }

  // ---- the cross-view return frame (doc 03 §13) --------------------------------

  function pushReturnFrame() {
    root.returnFrame = {
      tabKey: root.activeTabKey, depth: root.overviewDepth,
      section: root.focusSection, index: root.selectedIndex, pluginId: root.selectedPluginId
    }
  }
  function popReturnFrame() {
    var f = root.returnFrame
    if (!f) return false
    root.returnFrame = null
    root._selectTab(f.tabKey)
    root.overviewDepth = Number(f.depth || 0)
    root.expandedRuleId = ""
    root.finderActive = false
    root.focusSection = f.section
    root.selectedIndex = Number(f.index || 0)
    root.cursorActive = true
    Qt.callLater(root.clampCursor)
    return true
  }

  // ---- finder (doc 03 §8) ------------------------------------------------------

  function showFinder() {
    if (root.navigationLocked) return
    root.finderOrigin = {
      tabKey: root.activeTabKey, depth: root.overviewDepth,
      section: root.focusSection, index: root.selectedIndex, pluginId: root.selectedPluginId
    }
    root.ensureRulesList()   // the finder index needs the rule catalog
    root.ensureCoverage()
    root.finderActive = true
    if (finderField) finderField.text = ""
    root.finderText = ""
    root.focusSection = "results"
    root.selectedIndex = 0
    root.cursorActive = false
    Qt.callLater(function() { if (finderField) finderField.forceActiveFocus() })
  }

  function hideFinder() {
    var o = root.finderOrigin
    root.finderActive = false
    if (finderField) finderField.text = ""
    root.finderText = ""
    root.finderOrigin = null
    if (o) { root._selectTab(o.tabKey); root.overviewDepth = Number(o.depth || 0)
      root.focusSection = o.section; root.selectedIndex = Number(o.index || 0) }
    Qt.callLater(function() { if (keyCatcher) keyCatcher.forceActiveFocus() })
    Qt.callLater(root.clampCursor)
  }

  // The flat result list in cursor order: plugins → classes → rules → baseline.
  function finderFlat() {
    if (!root.vm || !root.vm.finder) return []
    var res = ViewModel.search(root.vm.finder, root.finderText)
    var out = []
    var i
    for (i = 0; i < res.plugins.length; i++) out.push({ kind: "plugin", id: res.plugins[i].id })
    for (i = 0; i < res.classes.length; i++) out.push({ kind: "class", key: res.classes[i].key })
    for (i = 0; i < res.rules.length; i++) out.push({ kind: "rule", id: res.rules[i].id })
    for (i = 0; i < res.baseline.length; i++) out.push({ kind: "baseline", externalId: res.baseline[i].externalId })
    return out
  }
  function finderResultCount() { return root.finderFlat().length }
  function moveFinderResult(delta) {
    var n = root.finderResultCount()
    if (n === 0) return
    root.cursorActive = true
    var next = root.selectedIndex + delta
    root.selectedIndex = next < 0 ? 0 : (next >= n ? n - 1 : next)
  }

  // Open a finder result: push the origin as a return frame, then navigate. A class
  // result targets the Flow Matrix, which arrives in Phase 3 — until then it only
  // dismisses the finder.
  function openFinderResult(flat) {
    var list = root.finderFlat()
    if (flat < 0 || flat >= list.length) return
    var r = list[flat]
    var origin = root.finderOrigin
    root.finderOrigin = null
    if (r.kind === "plugin") { root.returnFrame = origin; root._selectTab("overview"); root.openPlugin(r.id) }
    else if (r.kind === "rule") { root.returnFrame = origin; root.goToRule(r.id) }
    else if (r.kind === "baseline") { root.returnFrame = origin; root.goToBaselineRow(r.externalId) }
    else { root.finderActive = false; root.finderText = "" }   // class: Flow (Phase 3)
    Qt.callLater(function() { if (keyCatcher) keyCatcher.forceActiveFocus() })
  }

  function pluginStatusLabel(plugin) {
    var status = root.statusForPlugin(plugin.id)
    if (!status) return "Checking baseline…"
    if (status.state === "unchanged") return "Baselined & unchanged"
    if (status.state === "untrusted") return "No trust baseline"
    if (status.state === "partial") return "Partial coverage"
    if (status.state === "changed") return "Source changed"
    return "Status unavailable"
  }

  function pluginStatusLevel(plugin) {
    var status = root.statusForPlugin(plugin.id)
    if (!status || status.state === "untrusted") return "unknown"
    if (status.state === "unchanged") return "normal"
    return "warning"
  }

  function canTrustSelectedPlugin() {
    var plugin = root.selectedPlugin()
    return root.cliVerified && plugin && plugin.classification !== "backup" && !!plugin.content_digest
  }

  function canUntrustSelectedPlugin() {
    return root.cliVerified && root.statusReport && root.statusReport.trusted !== null &&
      root.statusReport.trusted !== undefined
  }

  // Returns false when a request is dropped, so no caller assumes its action is armed.
  function requestConfirmation(action) {
    if (root.pendingActions.indexOf(String(action)) < 0) return false
    if (root.pendingAction !== "" || root.operationRunning) return false
    root.pendingAction = String(action)
    return true
  }

  function clearAuthorizedTarget() {
    root.authorizedPluginId = ""
    root.authorizedHead = ""
    root.authorizedTree = ""
    root.authorizedDigest = ""
    root.authorizedBaselineDigest = ""
  }

  function clearPendingAction() {
    root.pendingAction = ""
    root.clearAuthorizedTarget()
  }

  // The confirm button's only entry point. One switch, no if-order.
  function runPendingAction() {
    if (root.pendingAction === "schedule") root.runScheduleInstall()
    else if (root.pendingAction === "review-update") root.runReviewUpdate()
    else if (root.pendingAction === "enable") root.runEnable()
    else if (root.baselineWritePending) root.trustSelectedPlugin()
    else if (root.pendingAction === "remove") root.untrustSelectedPlugin()
  }

  // ---- ConfirmSheet content (doc 03 §10, 02 §3.7) -------------------------------
  // Each sheet's title, body, verb, destructive flag, policy and — the point of GR6
  // — its action-specific identity rows come from the PINNED authorization facts
  // (T0.18), never re-derived from whatever is selected at confirm time.

  function _fact(v) { return String(v || "") !== "" ? String(v) : "unavailable" }

  function sheetTitle() {
    switch (root.pendingAction) {
      case "record":        return "Record trust baseline?"
      case "replace":       return "Replace trust baseline?"
      case "remove":        return "Remove trust baseline?"
      case "enable":        return "Enable plugin?"
      case "review-update": return "Update at the catalog-claimed commit?"
      case "schedule":      return "Install scheduled scan?"
    }
    return ""
  }

  function sheetBody() {
    switch (root.pendingAction) {
      case "record":
        return "OmaSafe will store this identity and report drift from it in future scans. It does not establish that the plugin is safe. Nothing is executed."
      case "replace":
        return "The previous baseline is superseded by this identity; drift is measured from it. It does not establish that the plugin is safe. Nothing is executed."
      case "remove":
        return "Future scans report this plugin as having no baseline. The plugin keeps running. Nothing is executed."
      case "enable":
        return "The CLI checks this exact source before enabling it and may refuse under hardened policy. A decision is recorded either way."
      case "review-update":
        return "The CLI updates " + root.selectedPluginId + " only if upstream still matches the commit the catalog snapshot claims, re-analyzes it, and records the result as the baseline. The commit is a catalog claim; the CLI verifies it before anything changes."
      case "schedule":
        return "Installs or replaces omasafe-scan.timer / omasafe-scan.service with " +
          root.scheduleInstallLabel() + " policy. Scheduled scans report only; hardened adds analysis and does not disable a running plugin. No plugin identity is involved."
    }
    return ""
  }

  function sheetConfirmLabel() {
    switch (root.pendingAction) {
      case "record":        return "Record"
      case "replace":       return "Replace"
      case "remove":        return "Remove"
      case "enable":        return "Enable"
      case "review-update": return "Update"
      case "schedule":      return "Install"
    }
    return "Confirm"
  }

  function sheetDestructive() {
    return root.pendingAction === "remove" || root.pendingAction === "enable" ||
      root.pendingAction === "review-update"
  }

  function sheetShowPolicy() {
    return root.pendingAction === "enable" || root.pendingAction === "review-update" ||
      root.pendingAction === "schedule"
  }

  function sheetPolicyValue() {
    if (root.pendingAction === "enable") return root.enablePolicyChoice
    if (root.pendingAction === "review-update") return root.reviewUpdatePolicyChoice
    if (root.pendingAction === "schedule") return root.scheduleInstallLabel()
    return "advisory"
  }

  function sheetPolicyDefinition() {
    return root.pendingAction === "schedule" ? Labels.schedulePolicy() : Labels.enforcementPolicy()
  }

  function _catalogCommit7() {
    var c = root.inventoryReport ? String(root.inventoryReport.marketplace_repository_commit || "") : ""
    return c.slice(0, 7)
  }

  function sheetInfoRows() {
    var rows = []
    if (root.pendingAction === "schedule") {
      var argv = "omasafe-cli scan --notify --only-new" +
        (root.scheduleInstallLabel() === "hardened" ? " --include-analysis" : "")
      rows.push({ label: "Unit", value: "omasafe-scan.timer · omasafe-scan.service" })
      rows.push({ label: "ExecStart", value: argv, mono: true })
      return rows
    }
    if (root.pendingAction === "remove") {
      rows.push({ label: "Plugin", value: root.authorizedPluginId })
      rows.push({ label: "Recorded baseline digest", value: root._fact(root.authorizedBaselineDigest), mono: true })
      return rows
    }
    if (root.pendingAction === "review-update") {
      var rvp = root.selectedPlugin()
      rows.push({ label: "Plugin", value: root.selectedPluginId })
      rows.push({ label: "Expected commit", value: root._fact(root.reviewUpdateCommit), mono: true })
      rows.push({ label: "", value: "Claimed by catalog snapshot " + root._catalogCommit7() })
      rows.push({ label: "Installed now", value: "" })
      rows.push({ label: "Current tree", value: root._fact(rvp && rvp.tree), mono: true })
      rows.push({ label: "Current digest", value: root._fact(rvp && rvp.content_digest), mono: true })
      return rows
    }
    if (root.pendingAction === "enable") {
      var ep = root.selectedPlugin()
      rows.push({ label: "Plugin", value: root.enablePluginId })
      rows.push({ label: "Head", value: root._fact(ep && ep.head), mono: true })
      rows.push({ label: "Tree", value: root._fact(ep && ep.tree), mono: true })
      rows.push({ label: "Digest", value: root._fact(ep && ep.content_digest), mono: true })
      return rows
    }
    // record / replace: the pinned identity (T0.18).
    rows.push({ label: "Plugin", value: root.authorizedPluginId })
    rows.push({ label: "Head", value: root._fact(root.authorizedHead), mono: true })
    rows.push({ label: "Tree", value: root._fact(root.authorizedTree), mono: true })
    rows.push({ label: "Digest", value: root._fact(root.authorizedDigest), mono: true })
    if (root.pendingAction === "replace")
      rows.push({ label: "Recorded", value: root._fact(root.authorizedBaselineDigest), mono: true })
    return rows
  }

  // Route a policy chip change to the pending action's own choice property.
  function setSheetPolicy(value) {
    if (root.pendingAction === "enable") root.enablePolicyChoice = value
    else if (root.pendingAction === "review-update") root.reviewUpdatePolicyChoice = value
    else if (root.pendingAction === "schedule") root.schedulePolicyChoice = value
  }

  // Opens the trust/replace confirmation and pins the exact identity it authorizes,
  // so the values that reach argv are the values the user was shown (T0.18).
  function beginTrust() {
    var plugin = root.selectedPlugin()
    if (!plugin || !root.canTrustSelectedPlugin()) return
    var replacing = !!(root.statusReport && root.statusReport.trusted)
    if (!root.requestConfirmation(replacing ? "replace" : "record")) return
    root.trustError = ""
    root.mutationMessage = ""
    root.authorizedPluginId = plugin.id
    root.authorizedHead = String(plugin.head || "")
    root.authorizedTree = String(plugin.tree || "")
    root.authorizedDigest = String(plugin.content_digest || "")
    root.authorizedBaselineDigest = replacing && root.statusReport.trusted
      ? String(root.statusReport.trusted.content_digest || "") : ""
  }

  function beginRemove() {
    if (!root.canUntrustSelectedPlugin()) return
    if (!root.requestConfirmation("remove")) return
    root.trustError = ""
    root.mutationMessage = ""
    root.authorizedPluginId = root.selectedPluginId
    root.authorizedBaselineDigest = root.statusReport && root.statusReport.trusted
      ? String(root.statusReport.trusted.content_digest || "") : ""
  }

  function trustSelectedPlugin() {
    if (!root.baselineWritePending || root.authorizedDigest === "") return
    var plugin = root.pluginById(root.authorizedPluginId)
    var stillExact = plugin && root.selectedPluginId === root.authorizedPluginId &&
      String(plugin.content_digest || "") === root.authorizedDigest &&
      String(plugin.head || "") === root.authorizedHead &&
      String(plugin.tree || "") === root.authorizedTree
    if (!stillExact) {
      var cancelledId = root.authorizedPluginId
      root.clearPendingAction()
      // selectedError, not panelError: this path runs from the Plugins tab, which does
      // not render panelError. Capture the id before clearing (P2).
      root.selectedError = "Cancelled: " + cancelledId + " changed since the confirmation opened."
      return
    }
    var args = ["plugins", "trust", root.authorizedPluginId, "--yes",
                "--note", "trusted from OmaSafe panel"]
    if (root.authorizedHead !== "") args.push("--expected-head", root.authorizedHead)
    if (root.authorizedTree !== "") args.push("--expected-tree", root.authorizedTree)
    args.push("--expected-digest", root.authorizedDigest)
    root.trustError = ""
    root.trustOutput = ""
    root.trustSettled = false
    root.trustOperation = "trust"
    // Copy the pinned facts onto the process so a mid-run clearPendingAction() (Esc,
    // panel close, popout switch) cannot blank or mislabel the completion line (P1).
    trustProcess.action = root.pendingAction
    trustProcess.mutatedPluginId = root.authorizedPluginId
    trustProcess.mutatedDigest = root.authorizedDigest
    trustKill.stop()
    trustTimeout.restart()
    trustProcess.command = root.cliCommand(args)
    trustProcess.running = true
  }

  function untrustSelectedPlugin() {
    if (root.pendingAction !== "remove") return
    var currentTrusted = root.statusReport && root.statusReport.trusted
      ? String(root.statusReport.trusted.content_digest || "") : ""
    var stillExact = root.canUntrustSelectedPlugin() &&
      root.selectedPluginId === root.authorizedPluginId &&
      currentTrusted === root.authorizedBaselineDigest
    if (!stillExact) {
      var cancelledId = root.authorizedPluginId
      root.clearPendingAction()
      root.selectedError = "Cancelled: " + cancelledId + " changed since the confirmation opened."
      return
    }
    root.trustError = ""
    root.trustOutput = ""
    root.trustSettled = false
    root.trustOperation = "untrust"
    trustProcess.action = "remove"
    trustProcess.mutatedPluginId = root.authorizedPluginId
    trustProcess.mutatedDigest = ""
    trustKill.stop()
    trustTimeout.restart()
    // Target contract (05 §10): the CLI compares the recorded baseline digest before
    // removing it. Gated off until a CLI release implements it (identitySafeMutations).
    var removeArgs = [
      "plugins", "review", root.selectedPluginId,
      "--action", "untrust",
      "--reason", "untrusted from OmaSafe panel"
    ]
    if (root.authorizedBaselineDigest !== "")
      removeArgs.push("--expected-trusted-digest", root.authorizedBaselineDigest)
    removeArgs.push("--yes")
    trustProcess.command = root.cliCommand(removeArgs)
    trustProcess.running = true
  }

  function refreshPluginStatuses() {
    root.statusSweepGeneration++
    root.pluginStatuses = ({})
    root.statusQueue = root.visiblePlugins().map(function(plugin) { return plugin.id })
    root.checkingPluginStatuses = root.statusQueue.length > 0
    root.runNextPluginStatus()
  }

  function runNextPluginStatus() {
    if (listStatusProcess.running) return
    if (root.statusQueue.length === 0) {
      root.checkingPluginStatuses = false
      return
    }
    var queue = root.statusQueue.slice()
    var pluginId = queue.shift()
    root.statusQueue = queue
    listStatusProcess.pluginId = pluginId
    listStatusProcess.generation = root.statusSweepGeneration
    listStatusProcess.receivedReport = false
    listStatusProcess.command = root.cliCommand(["plugins", "status", pluginId, "--format", "json"])
    listStatusProcess.prepare()
    listStatusProcess.running = true
  }

  function recordPluginStatus(id, status) {
    var next = ({})
    for (var key in root.pluginStatuses) next[key] = root.pluginStatuses[key]
    next[id] = status
    root.pluginStatuses = next
  }

  function applyListedPluginStatus(id, output, generation) {
    if (generation !== root.statusSweepGeneration) return
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1" || !report.result)
        throw new Error("unsupported status report")
      root.recordPluginStatus(id, report.result || { state: "unavailable" })
    } catch (error) {
      root.recordPluginStatus(id, { state: "unavailable" })
    }
  }

  function marketplaceByPlugin(id) {
    var entries = root.inventoryReport && root.inventoryReport.marketplace || []
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].plugin_id === id) return entries[i]
    }
    return null
  }

  function marketplaceClaim(marketplace) {
    return marketplace && marketplace.registry_claim
      ? marketplace.registry_claim : null
  }

  function snapshotClaim() {
    var entries = root.inventoryReport && root.inventoryReport.marketplace || []
    for (var i = 0; i < entries.length; i++) {
      var claim = root.marketplaceClaim(entries[i])
      if (claim) return claim
    }
    return null
  }

  function snapshotIntegrityLabel() {
    var source = root.inventoryReport
      ? String(root.inventoryReport.marketplace_source || "") : ""
    var explicit = root.inventoryReport
      ? root.inventoryReport.marketplace_snapshot_verified : undefined
    if (explicit === true || (explicit === undefined && source === "pinned-fetch"))
      return "Verified against pinned catalog commit"
    if (source === "unverified-cache") return "Unverified cached snapshot"
    if (source === "local-file") return "Local catalog file (not cache-verified)"
    return "Marketplace snapshot unavailable"
  }

  function snapshotIntegrityLevel() {
    var source = root.inventoryReport
      ? String(root.inventoryReport.marketplace_source || "") : ""
    var explicit = root.inventoryReport
      ? root.inventoryReport.marketplace_snapshot_verified : undefined
    if (explicit === true || (explicit === undefined && source === "pinned-fetch"))
      return "normal"
    if (source === "unverified-cache" || source === "local-file") return "warning"
    return "unknown"
  }

  function snapshotCommit() {
    if (root.inventoryReport && root.inventoryReport.marketplace_repository_commit)
      return root.inventoryReport.marketplace_repository_commit
    var claim = root.snapshotClaim()
    return claim ? claim.registry_commit : null
  }

  function updateMarketplace() {
    if (!root.hostWidget || !root.hostWidget.cliVerified ||
        marketplaceRefreshProcess.running) return
    root.catalogElapsed = 0
    root.marketplaceRefreshError = ""
    root.marketplaceRefreshMessage = ""
    root.marketplaceRefreshAwaitingInventory = false
    root.inventoryReloadPending = false
    root.marketplaceRefreshSettled = false
    root.pendingRefreshMessage = ""
    marketplaceRefreshKill.stop()
    marketplaceRefreshTimeout.restart()
    marketplaceRefreshProcess.running = true
  }

  // Reload inventory after a catalog refresh, queuing if a reload is already in
  // flight so the required post-refresh reload is never dropped. The catalog-only
  // marker is applied to the run this actually starts (here or when the queue is
  // drained), never to an unrelated reload already running.
  function reloadInventoryForRefresh() {
    if (inventoryProcess.running) {
      root.inventoryReloadPending = true
    } else {
      root.nextInventoryCatalogOnly = true
      inventoryProcess.running = true
    }
  }

  function listingVerificationLabel(marketplace) {
    var claim = root.marketplaceClaim(marketplace)
    var status = claim ? String(claim.verification_status || "").toLowerCase() : ""
    if (status === "verified") return "Verified by marketplace"
    if (status === "unverified") return "Not verified by marketplace"
    return "Marketplace verification unavailable"
  }

  function listingVerificationLevel(marketplace) {
    var claim = root.marketplaceClaim(marketplace)
    var status = claim ? String(claim.verification_status || "").toLowerCase() : ""
    if (status === "verified") return "normal"
    if (status === "unverified") return "warning"
    return "unknown"
  }

  function installedCommitLabel(marketplace) {
    var claim = root.marketplaceClaim(marketplace)
    if (!claim || claim.installed_matches_listing === null ||
        claim.installed_matches_listing === undefined)
      return "Installed/validated commit comparison unavailable"
    return claim.installed_matches_listing
      ? "Installed commit matches validated commit"
      : "Installed commit differs from validated commit"
  }

  function installedCommitLevel(marketplace) {
    var claim = root.marketplaceClaim(marketplace)
    if (!claim || claim.installed_matches_listing === null ||
        claim.installed_matches_listing === undefined) return "unknown"
    return claim.installed_matches_listing ? "normal" : "warning"
  }

  function upstreamCommitLabel(marketplace) {
    var claim = root.marketplaceClaim(marketplace)
    if (!claim || claim.upstream_moved === null || claim.upstream_moved === undefined)
      return "Upstream comparison unavailable"
    return claim.upstream_moved
      ? "Upstream moved past validated commit"
      : "Upstream still matches validated commit"
  }

  function upstreamCommitLevel(marketplace) {
    var claim = root.marketplaceClaim(marketplace)
    if (!claim || claim.upstream_moved === null || claim.upstream_moved === undefined)
      return "unknown"
    return claim.upstream_moved ? "warning" : "normal"
  }

  function selectedAlert() {
    for (var i = 0; i < root.alerts.length; i++) {
      if (root.alerts[i].plugin_id === root.selectedPluginId) return root.alerts[i]
    }
    return null
  }

  function shortDigest(value) {
    value = String(value || "")
    return value.length > 18 ? value.slice(0, 16) + "…" : (value || "unavailable")
  }

  // Set a process's command and start it. If it is already running for a prior
  // selection, request the new command instead and let onExited relaunch it, so
  // rapid re-selection never drops the latest request.
  function launchProcess(process, command, requestId, pluginId) {
    if (process.running) {
      process.nextCommand = command
      process.nextRequestId = requestId || 0
      process.nextPluginId = pluginId || ""
      root.terminateBoundedProcess(process)
    } else {
      process.nextCommand = null
      process.nextRequestId = 0
      process.nextPluginId = ""
      process.requestId = requestId || 0
      process.pluginId = pluginId || ""
      process.command = command
      if (typeof process.prepare === "function") process.prepare()
      if (process.killTimer) process.killTimer.stop()
      process.running = true
    }
  }

  function selectPlugin(id, alert) {
    if (root.pendingAction === "review-update" && id !== root.reviewUpdatePluginId) {
      root.clearPendingAction()
      root.reviewUpdateError = "Reviewed update cancelled because the selected plugin changed."
    }
    if (root.pendingAction === "enable" && id !== root.enablePluginId) {
      root.clearPendingAction()
      root.enableError = "Enable cancelled because the selected plugin changed."
    }
    root.selectedPluginId = id || ""
    root.showPluginPicker = false
    if (root.baselineWritePending || root.pendingAction === "remove") root.clearPendingAction()
    root.statusReport = null
    root.diffReport = null
    root.enforcementDecision = null
    root.enforcementError = ""
    root.enforcementLoading = false
    root.enforcementDetailsExpanded = false
    root.selectedError = ""
    root.mutationMessage = ""
    root.analysisReport = null
    root.analysisCoverageStates = null
    root.analysisPluginId = ""
    root.analysisDigest = ""
    root.analysisCliVersion = ""
    root.analysisPolicyKey = ""
    root.analysisError = ""
    root.analysisLoading = false
    root.analysisDetailsExpanded = false
    root.expandedFindingKey = ""
    root.selectionRequestId++
    var requestId = root.selectionRequestId
    var plugin = root.pluginById(root.selectedPluginId)
    if (plugin) {
      root.enforcementLoading = root.cliVerified
      root.launchProcess(statusProcess,
        root.cliCommand(["plugins", "status", plugin.id, "--format", "json"]),
        requestId, plugin.id)
      root.launchProcess(enforcementStatusProcess,
        root.cliCommand(["plugins", "enforcement-status", plugin.id, "--format", "json"]),
        requestId, plugin.id)
    }
    if (plugin && alert && alert.kind === "source-drift") {
      root.launchProcess(diffProcess,
        root.cliCommand(["plugins", "diff", plugin.id, "--format", "json"]),
        requestId, plugin.id)
    }
  }

  function open() {
    root.panelError = ""
    root.controller.show()
    root.loadInventory()
    root.loadScheduleStatus()
    root.loadOverrides()
    if (root.activeTabKey === "rules") { root.ensureRulesList(); Qt.callLater(root.ensureCoverage) }
  }

  // Only load once the CLI is verified. If the panel is opened during the brief
  // startup verification window, it waits and the cliVerified watcher below loads
  // as soon as the probe passes, rather than firing inventory at an unverified
  // (or non-executable) binary.
  function loadInventory() {
    if (!root.cliVerified) {
      root.panelError = "omasafe-cli is not verified yet; the panel loads once the version check passes."
      return
    }
    root.panelError = ""
    if (!inventoryProcess.running) inventoryProcess.running = true
  }

  function loadScheduleStatus() {
    if (!root.cliVerified || scheduleStatusProcess.running) return
    root.scheduleLoading = true
    root.scheduleError = ""
    scheduleStatusProcess.startRequest()
  }

  function beginScheduleInstall(policy) {
    if (!root.cliVerified || root.operationRunning) return
    var selected = String(policy || "")
    if (["advisory", "hardened"].indexOf(selected) < 0) return
    root.schedulePolicyChoice = selected
    root.scheduleInstallError = ""
    root.scheduleInstallMessage = ""
    root.scheduleInstallSettled = false
    if (!root.requestConfirmation("schedule")) return
  }

  function runScheduleInstall() {
    if (root.pendingAction !== "schedule" || !root.cliVerified || root.operationRunning) return
    var policy = root.scheduleInstallLabel()
    root.scheduleInstallError = ""
    root.scheduleInstallMessage = ""
    root.scheduleInstallStdout = ""
    root.scheduleInstallStderr = ""
    root.scheduleInstallSettled = false
    scheduleInstallProcess.policy = policy
    scheduleInstallProcess.settled = false
    scheduleInstallKill.stop()
    scheduleInstallProcess.command = root.cliCommand(["schedule", "install", "--policy", policy])
    scheduleInstallTimeout.restart()
    scheduleInstallProcess.running = true
  }

  function ensureCoverage() {
    if (!root.cliVerified || root.coverageLoading) return
    var cliVersion = String(root.hostWidget && root.hostWidget.cliVersion || "")
    if (root.coverageReport !== null && root.coverageCliVersion === cliVersion) return
    if (root.coverageCliVersion !== cliVersion) {
      root.coverageReport = null
      root.coverageDetailsExpanded = false
    }
    root.coverageCliVersion = cliVersion
    root.coverageLoading = true
    root.coverageError = ""
    coverageProcess.startRequest()
  }

  // Fetch the rule catalog once per CLI version (T2.9 collector); cached like
  // coverageReport. A no-op until the plugin needs the Rules view or the finder.
  function ensureRulesList() {
    if (!root.cliVerified || root.rulesListLoading) return
    var cliVersion = String(root.hostWidget && root.hostWidget.cliVersion || "")
    if (root.rulesListReport !== null && root.rulesListCliVersion === cliVersion) return
    if (root.rulesListCliVersion !== cliVersion) root.rulesListReport = null
    root.rulesListCliVersion = cliVersion
    root.rulesListLoading = true
    root.rulesListError = ""
    rulesListProcess.startRequest()
  }

  function loadOverrides() {
    if (!root.cliVerified || overrideProcess.running) return
    root.overrideLoading = true
    root.overrideError = ""
    overrideProcess.startRequest()
  }

  function refreshEnforcementStatus() {
    var plugin = root.selectedPlugin()
    if (!plugin || !root.cliVerified) return
    // Do not blank a known decision on a periodic refresh: only show the loading
    // string when there is nothing to show yet (A21). A failed refresh still clears
    // the decision in enforcementStatusProcess.onExited, so nothing goes stale.
    root.enforcementError = ""
    root.enforcementLoading = root.enforcementDecision === null
    root.launchProcess(enforcementStatusProcess,
      root.cliCommand(["plugins", "enforcement-status", plugin.id, "--format", "json"]),
      root.selectionRequestId, plugin.id)
  }

  function close() {
    root.clearPendingAction()
    root.overviewDepth = 0
    analysisProcess.nextPluginId = ""
    analysisProcess.nextRequestId = 0
    ruleExplanationProcess.nextRuleId = ""
    root.coverageReport = null
    root.coverageCliVersion = ""
    root.coverageDetailsExpanded = false
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function applyInventory(output, catalogOnly) {
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1" ||
          !report.result || !Array.isArray(report.result.plugins))
        throw new Error("unsupported inventory report")
      root.inventoryReport = report.result || {}
      root.enforcementSummary = root.inventoryReport.enforcement_summary || null
      root.panelError = ""
      var signature = root.computeInstalledSignature()
      var identitiesChanged = signature !== root.installedSignature
      root.installedSignature = signature
      if (identitiesChanged) root.clearAnalysisCache()
      // Skip the per-plugin status sweep ONLY on the reload started by a catalog
      // refresh, with an unchanged installed set and a valid selection: marketplace
      // claims come from the new inventoryReport, and trust status cannot have
      // changed. Any other path (a normal open) must refresh statuses, since the
      // trust baseline is mutable independently of installed source and may be stale.
      if (catalogOnly && !identitiesChanged &&
          root.selectedPluginId !== "" && root.pluginById(root.selectedPluginId))
        return
      var plugins = root.visiblePlugins()
      var initialAlert = root.alerts.length > 0 ? root.alerts[0] : null
      var initialId = initialAlert ? initialAlert.plugin_id : (plugins.length > 0 ? plugins[0].id : "")
      var initialPlugin = root.pluginById(initialId)
      if ((!initialPlugin || initialPlugin.classification === "backup") && plugins.length > 0)
        initialId = plugins[0].id
      root.selectPlugin(initialId, initialAlert)
      root.refreshPluginStatuses()
      // selectPlugin clears the display slot but the cache now survives (T0.16). When
      // a detail sheet is open, rehydrate its analysis from cache rather than leaving
      // it blank (P2); the Overview list reads the cache through vm without a fetch.
      if (root.opened && root.overviewDepth >= 1) Qt.callLater(root.hydrateAnalysis)
    } catch (error) {
      root.inventoryReport = null
      root.enforcementSummary = null
      root.panelError = "CLI returned an invalid inventory report"
    }
  }

  function applyStatus(output, pluginId, requestId) {
    if (pluginId !== root.selectedPluginId || requestId !== root.selectionRequestId) return
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1" || !report.result)
        throw new Error("unsupported status report")
      root.statusReport = report.result || {}
      root.selectedError = ""
      // WHAT CHANGED is fetched only in the `changed` state (doc 03 §5.1). Normal
      // detail navigation passes no alert, so fetch the diff here when the CLI
      // reports the source has changed and no diff is loaded yet.
      if (String(root.statusReport.state) === "changed" && root.diffReport === null
          && root.cliVerified) {
        root.launchProcess(diffProcess,
          root.cliCommand(["plugins", "diff", pluginId, "--format", "json"]),
          requestId, pluginId)
      }
    } catch (error) {
      root.statusReport = null
      root.selectedError = "Status for this plugin is unavailable."
    }
  }

  function applyEnforcementStatus(output, pluginId, requestId) {
    if (pluginId !== root.selectedPluginId || requestId !== root.selectionRequestId) return
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1")
        throw new Error("unsupported report envelope")
      if (!report.result || !Object.prototype.hasOwnProperty.call(report.result, "decision"))
        throw new Error("missing enforcement decision")
      var decision = report.result ? report.result.decision : null
      if (decision !== null && (typeof decision !== "object" ||
          String(decision.schema || "") !== "omasafe.enforcement.v1"))
        throw new Error("unsupported enforcement decision")
      root.enforcementDecision = decision
      root.enforcementError = ""
    } catch (error) {
      root.enforcementDecision = null
      root.enforcementError = "Enforcement decision is unavailable."
    }
  }

  function applyScheduleStatus(output) {
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1")
        throw new Error("unsupported report envelope")
      var result = report.result || {}
      if (String(result.schema || "") !== "omasafe.schedule.v1")
        throw new Error("unsupported schedule status")
      root.scheduleReport = result
      root.scheduleError = ""
    } catch (error) {
      root.scheduleReport = null
      root.scheduleError = "Schedule status is unavailable."
    }
  }

  function applyRulesList(output) {
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1")
        throw new Error("unsupported report envelope")
      var result = report.result || {}
      if (!Array.isArray(result.rules)) throw new Error("unsupported rules list report")
      root.rulesListReport = result
      root.rulesListError = ""
    } catch (error) {
      root.rulesListReport = null
      root.rulesListError = "Rule catalog is unavailable."
    }
  }

  function applyCoverage(output) {
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1")
        throw new Error("unsupported report envelope")
      var result = report.result || {}
      if (!Array.isArray(result.coverage) || result.map_version === undefined)
        throw new Error("unsupported coverage report")
      root.coverageReport = result
      root.coverageError = ""
    } catch (error) {
      root.coverageReport = null
      root.coverageError = "Rule coverage is unavailable."
    }
  }

  function applyOverrides(output) {
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1")
        throw new Error("unsupported report envelope")
      var result = report.result || {}
      if (!Array.isArray(result.overrides)) throw new Error("unsupported override report")
      root.overrideReport = result
      root.overrideError = ""
    } catch (error) {
      root.overrideReport = null
      root.overrideError = "Override status is unavailable."
    }
  }

  function applyDiff(output, pluginId, requestId) {
    if (pluginId !== root.selectedPluginId || requestId !== root.selectionRequestId) return
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1" || !report.result)
        throw new Error("unsupported diff report")
      root.diffReport = report.result || {}
    } catch (error) {
      root.diffReport = null
      root.selectedError = "Source diff for this plugin is unavailable."
    }
  }

  function analysisDigestFor(plugin) {
    return plugin ? String(plugin.content_digest || plugin.head || plugin.tree || "") : ""
  }

  function ensureAnalysis() {
    var plugin = root.selectedPlugin()
    if (!plugin || !root.cliVerified) return
    var digest = root.analysisDigestFor(plugin)
    var cliVersion = String(root.hostWidget && root.hostWidget.cliVersion || "")
    if (root.analysisPluginId === plugin.id && root.analysisDigest === digest &&
        root.analysisCliVersion === cliVersion &&
        (root.analysisReport !== null || root.analysisLoading)) return
    var cached = root.analysisCache[plugin.id]
    if (cached && cached.digest === digest && cached.cliVersion === cliVersion &&
        cached.policyKey !== undefined &&
        cached.policyKey === root.analysisPolicyKeyFor(cached.report)) {
      root.analysisPluginId = plugin.id
      root.analysisDigest = digest
      root.analysisCliVersion = cliVersion
      root.analysisPolicyKey = cached.policyKey
      root.analysisReport = cached.report
      root.analysisCoverageStates = cached.coverageStates || null
      root.analysisError = ""
      root.analysisLoading = false
      return
    }
    root.analysisRequestId++
    root.analysisPluginId = plugin.id
    root.analysisDigest = digest
    root.analysisCliVersion = cliVersion
    root.analysisPolicyKey = ""
    root.analysisReport = null
    root.analysisCoverageStates = null
    root.analysisError = ""
    root.analysisLoading = true
    root.setAnalysisState(plugin.id, "analyzing")
    analysisProcess.sweepGeneration = root.analysisSweepGeneration
    analysisProcess.startFor(plugin.id, root.analysisRequestId)
  }

  function analysisPolicyKeyFor(report) {
    return root.analysisPolicyIdentityKey(report)
  }

  // Populate the analysis display slot from a VALID cache entry only — never starts a
  // process. Called on opening a detail sheet so a previously-analyzed plugin shows its
  // cached results while an un-analyzed one keeps the explicit "not analyzed" state
  // until the user presses a / Analyze (doc 03 §5.2, P11: analysis runs on a/A only).
  function hydrateAnalysis() {
    var plugin = root.selectedPlugin()
    if (!plugin) return
    var report = root.resolvedAnalysisFor(plugin)
    if (!report) return
    var cached = root.analysisCache[plugin.id]
    root.analysisPluginId = plugin.id
    root.analysisDigest = root.analysisDigestFor(plugin)
    root.analysisCliVersion = String(root.hostWidget && root.hostWidget.cliVersion || "")
    root.analysisPolicyKey = root.analysisPolicyKeyFor(report)
    root.analysisReport = report
    root.analysisCoverageStates = (cached && cached.coverageStates) || null
    root.analysisError = ""
    root.analysisLoading = false
  }

  // After a trust / enable / review-update mutation: re-fetch the selected plugin's
  // status (trust word → checking… until it returns, 02 §3.2) and enforcement decision
  // and the per-plugin status map, WITHOUT wiping the analysis cache or its display and
  // WITHOUT an automatic scan (doc 03 §5.5, T2.14).
  function refreshSelectedAfterMutation() {
    var plugin = root.selectedPlugin()
    if (!plugin || !root.cliVerified) return
    root.selectionRequestId++
    var requestId = root.selectionRequestId
    root.statusReport = null
    root.diffReport = null
    root.selectedError = ""
    root.launchProcess(statusProcess,
      root.cliCommand(["plugins", "status", plugin.id, "--format", "json"]),
      requestId, plugin.id)
    root.launchProcess(enforcementStatusProcess,
      root.cliCommand(["plugins", "enforcement-status", plugin.id, "--format", "json"]),
      requestId, plugin.id)
    root.refreshPluginStatuses()
    root.hydrateAnalysis()
  }

  // The mutation success / failure line for the detail sheet, keyed on the CLI's own
  // words (doc 03 §5.5, T2.14: "success line in place"). Errors win over messages.
  function detailStatusLine() {
    if (root.selectedError !== "") return root.selectedError
    if (root.trustError !== "") return root.trustError
    if (root.enableError !== "") return root.enableError
    if (root.reviewUpdateError !== "") return root.reviewUpdateError
    if (root.panelError !== "") return root.panelError
    if (root.mutationMessage !== "") return root.mutationMessage
    if (root.enableMessage !== "") return root.enableMessage
    if (root.reviewUpdateMessage !== "") return root.reviewUpdateMessage
    return ""
  }
  function detailStatusIsError() {
    return root.selectedError !== "" || root.trustError !== "" || root.enableError !== ""
      || root.reviewUpdateError !== "" || root.panelError !== ""
  }

  // The schedule / catalog line for the Overview SOURCES section.
  function sourcesStatusLine() {
    if (root.scheduleInstallError !== "") return root.scheduleInstallError
    if (root.marketplaceRefreshError !== "") return root.marketplaceRefreshError
    if (root.scheduleInstallMessage !== "") return root.scheduleInstallMessage
    if (root.marketplaceRefreshMessage !== "") return root.marketplaceRefreshMessage
    return ""
  }
  function sourcesStatusIsError() {
    return root.scheduleInstallError !== "" || root.marketplaceRefreshError !== ""
  }

  function cacheAnalysis(id, digest, report, coverageStates) {
    var next = ({})
    for (var key in root.analysisCache) next[key] = root.analysisCache[key]
    next[id] = {
      digest: digest,
      cliVersion: String(root.hostWidget && root.hostWidget.cliVersion || ""),
      policyKey: root.analysisPolicyKeyFor(report),
      report: report,
      coverageStates: coverageStates || null
    }
    root.analysisCache = next
  }

  function clearAnalysisCache() {
    root.analysisRequestId++
    // A CLI version / gate change invalidates every in-flight run: bump the sweep
    // generation and drop the queue so no old-context output is cached (doc 04 §10.1).
    root.analysisSweepGeneration++
    root.analysisQueue = []
    root.analysisStateById = ({})
    root.analysisLoading = false
    root.analysisCache = ({})
    root.analysisReport = null
    root.analysisCoverageStates = null
    root.analysisPluginId = ""
    root.analysisDigest = ""
    root.analysisCliVersion = ""
    root.analysisPolicyKey = ""
    root.analysisError = ""
    root.analysisDetailsExpanded = false
  }

  // Drop only the named plugins' cached analyses. The cache key already misses on a
  // changed digest, CLI version or analyzer policy; these two alert kinds are the cases
  // where the key can still match but the analysis is no longer trustworthy (T0.16).
  function dropAnalysisCacheFor(ids) {
    if (!ids || ids.length === 0) return
    var next = ({})
    for (var key in root.analysisCache)
      if (ids.indexOf(key) < 0) next[key] = root.analysisCache[key]
    root.analysisCache = next
    if (ids.indexOf(root.analysisPluginId) >= 0) {
      root.analysisRequestId++
      root.analysisPluginId = ""
      root.analysisDigest = ""
      root.analysisCliVersion = ""
      root.analysisPolicyKey = ""
      root.analysisReport = null
      root.analysisCoverageStates = null
      root.analysisLoading = false
      root.analysisDetailsExpanded = false
    }
  }

  function findingKey(finding) {
    return String(finding.rule_id || "rule") + ":" + String(finding.relative_path || "") + ":" +
      String(finding.line || "")
  }

  // The cached analysis report for a plugin, or null when there is none valid — the
  // same validity check ensureAnalysis() uses (digest + CLI version + analyzer policy
  // key), so a stale-policy or moved-digest cache hit is treated as not analyzed.
  function resolvedAnalysisFor(plugin) {
    if (!plugin) return null
    var cached = root.analysisCache[plugin.id]
    if (!cached) return null
    var digest = root.analysisDigestFor(plugin)
    var cliVersion = String(root.hostWidget && root.hostWidget.cliVersion || "")
    if (cached.digest === digest && cached.cliVersion === cliVersion &&
        cached.policyKey !== undefined &&
        cached.policyKey === root.analysisPolicyKeyFor(cached.report))
      return cached.report
    return null
  }

  // Assemble the ViewModel input from the collectors and normalise it (T2.1). Called
  // by the `vm` binding; reads only reactive root state so a report reassignment
  // recomputes it.
  function buildVm() {
    var inv = root.inventoryReport
    var plugins = (inv && inv.plugins) || []
    var analysisById = ({})
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i]
      if (p.classification === "backup") continue
      analysisById[p.id] = root.resolvedAnalysisFor(p)
    }
    return ViewModel.build({
      inventory: inv,
      alerts: root.alerts,
      scanMeta: {
        outstanding: root.hostWidget ? Number(root.hostWidget.outstandingCount || 0) : 0,
        "new": root.hostWidget ? Number(root.hostWidget.newCount || 0) : 0,
        highestSeverity: root.hostWidget ? String(root.hostWidget.highestSeverity || "") : "",
        generatedAt: root.hostWidget ? String(root.hostWidget.lastScanAt || "") : ""
      },
      statusById: root.pluginStatuses,
      checkingIds: root.statusQueue,
      analysisById: analysisById,
      coverage: root.coverageReport,
      rulesList: root.rulesListReport,
      schedule: root.scheduleReport,
      overrides: root.overrideReport,
      cliVersion: root.hostWidget ? String(root.hostWidget.cliVersion || "") : "",
      nowMs: Date.now()
    })
  }

  function explainRule(ruleId) {
    var id = String(ruleId || "")
    if (id === "") return
    var cacheKey = (root.hostWidget ? root.hostWidget.cliVersion : "") + ":" + id
    if (root.ruleExplanationCache[cacheKey] !== undefined) {
      root.ruleExplanationKey = cacheKey
      root.ruleExplanationResult = root.ruleExplanationCache[cacheKey]
      root.ruleExplanationError = ""
      root.ruleExplanationLoading = false
      return
    }
    root.ruleExplanationKey = cacheKey
    root.ruleExplanationResult = null
    root.ruleExplanationError = ""
    root.ruleExplanationLoading = true
    ruleExplanationProcess.startFor(id, cacheKey)
  }

  function updateEligible() {
    var plugin = root.selectedPlugin()
    var marketplace = root.marketplaceByPlugin(root.selectedPluginId)
    var claim = root.marketplaceClaim(marketplace)
    var baselineState = root.statusReport && root.statusReport.state
    var baselineOk = root.statusReport && root.statusReport.trusted &&
      ["unchanged", "clean", "acknowledged"].indexOf(baselineState) >= 0
    var digest = root.analysisDigestFor(plugin)
    return !!plugin && !!marketplace && ["listed", "installed-differs"].indexOf(marketplace.status) >= 0 &&
      !!claim && String(claim.upstream_observed_commit || "") !== "" &&
      digest !== "" && baselineOk
  }

  function enableEligible() {
    var plugin = root.selectedPlugin()
    return root.cliVerified && !!plugin && plugin.classification !== "backup" &&
      plugin.enabled === false && plugin.active === false
  }

  function beginReviewUpdate() {
    var marketplace = root.marketplaceByPlugin(root.selectedPluginId)
    var claim = root.marketplaceClaim(marketplace)
    if (!root.updateEligible() || !claim) return
    root.reviewUpdatePluginId = root.selectedPluginId
    root.reviewUpdateDigest = root.analysisDigestFor(root.selectedPlugin())
    root.reviewUpdateCommit = String(claim.upstream_observed_commit)
    root.reviewUpdatePolicyChoice = "advisory"
    root.reviewUpdateError = ""
    root.reviewUpdateMessage = ""
    root.reviewUpdateSettled = false
    root.reviewUpdateTerminating = false
    if (!root.requestConfirmation("review-update")) return
  }

  function beginEnable() {
    if (!root.enableEligible() || root.operationRunning) return
    var plugin = root.selectedPlugin()
    root.enablePluginId = root.selectedPluginId
    root.enablePolicyChoice = "advisory"
    root.enableError = ""
    root.enableMessage = ""
    root.enableSettled = false
    if (!root.requestConfirmation("enable")) return
    // Pin the displayed identity so the CLI compares this exact source (05 §10).
    root.authorizedPluginId = plugin ? String(plugin.id) : root.selectedPluginId
    root.authorizedHead = plugin ? String(plugin.head || "") : ""
    root.authorizedTree = plugin ? String(plugin.tree || "") : ""
    root.authorizedDigest = plugin ? String(plugin.content_digest || "") : ""
  }

  // Parse a `plugins enable --format json` report, store the decision, and return the
  // result object (carrying `enabled` and `policy`) or null. A positive success line is
  // keyed on `result.enabled === true`, never on exit status alone (02 §3.3).
  function applyEnableResult(output, pluginId) {
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1" ||
          !report.result || !report.result.decision)
        return null
      var decision = report.result.decision
      if (String(decision.schema || "") !== "omasafe.enforcement.v1") return null
      if (String(report.result.plugin_id || pluginId) !== pluginId) return null
      root.enforcementDecision = decision
      root.enforcementError = ""
      return report.result
    } catch (error) {
      return null
    }
  }

  function runEnable() {
    var target = root.pluginById(root.enablePluginId)
    var targetStillExact = target && root.selectedPluginId === root.enablePluginId &&
      root.enableEligible() && !enableProcess.running
    if (root.pendingAction !== "enable" || !targetStillExact) {
      if (root.pendingAction === "enable" && !targetStillExact)
        root.enableError = "Enable target changed; confirmation is no longer valid."
      return
    }
    root.enableError = ""
    root.enableMessage = ""
    root.enableSettled = false
    root.enableStdout = ""
    root.enableStderr = ""
    enableProcess.pluginId = root.enablePluginId
    enableProcess.policy = root.enablePolicyChoice
    // Target contract (05 §10): the CLI compares this exact identity before enabling;
    // digest is mandatory, git fields passed when present. Gated off until a CLI
    // release implements it (identitySafeMutations), so these never run on 0.2.1.
    var enableArgs = ["plugins", "enable", root.enablePluginId, "--policy", root.enablePolicyChoice]
    if (root.authorizedHead !== "") enableArgs.push("--expected-head", root.authorizedHead)
    if (root.authorizedTree !== "") enableArgs.push("--expected-tree", root.authorizedTree)
    enableArgs.push("--expected-digest", root.authorizedDigest, "--format", "json")
    enableProcess.command = root.cliCommand(enableArgs)
    enableKill.stop()
    enableTimeout.restart()
    enableProcess.running = true
  }

  function runReviewUpdate() {
    var target = root.pluginById(root.reviewUpdatePluginId)
    var targetMarketplace = root.marketplaceByPlugin(root.reviewUpdatePluginId)
    var targetClaim = root.marketplaceClaim(targetMarketplace)
    var targetStillExact = target && root.selectedPluginId === root.reviewUpdatePluginId &&
      root.analysisDigestFor(target) === root.reviewUpdateDigest && targetClaim &&
      String(targetClaim.upstream_observed_commit || "") === root.reviewUpdateCommit &&
      root.updateEligible() && !reviewUpdateProcess.running
    if (root.pendingAction !== "review-update" || root.reviewUpdateCommit === "" || !targetStillExact) {
      if (root.pendingAction === "review-update" && !targetStillExact)
        root.reviewUpdateError = "Reviewed update target changed; confirmation is no longer valid."
      return
    }
    root.reviewUpdateError = ""
    root.reviewUpdateMessage = ""
    root.reviewUpdateSettled = false
    root.reviewUpdateTerminating = false
    root.reviewUpdateStdout = ""
    root.reviewUpdateStderr = ""
    reviewUpdateKill.stop()
    reviewUpdateProcess.pluginId = root.reviewUpdatePluginId
    reviewUpdateProcess.commit = root.reviewUpdateCommit
    reviewUpdateProcess.command = root.cliCommand([
      "plugins", "review-update", root.reviewUpdatePluginId,
      "--expected-commit", root.reviewUpdateCommit,
      "--policy", root.reviewUpdatePolicyChoice, "--yes"
    ])
    reviewUpdateTimeout.restart()
    reviewUpdateProcess.running = true
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    contentWidth: fittedContentWidth(Style.space(420))
    focusTarget: keyCatcher
    // A fixed column (hero · status line · notices · view chips) over a body that
    // always scrolls (doc 03 §3). The inner space(480) and outer space(600) caps
    // collapse into one space(560).
    contentHeight: fittedContentHeight(fixedColumn.implicitHeight + Style.space(12) +
      activeContent.implicitHeight, Style.space(560))

  PanelKeyCatcher {
    id: keyCatcher
    anchors.fill: parent
    // While the sheet is open, or the finder holds focus, every key goes there
    // (doc 03 §10 invariant 1, §8). The sheet handles Esc → canceled(); the finder
    // handles Esc → hideFinder().
    blocked: sheet.opened || (finderField && finderField.activeFocus)

    // One cursor over hero → views (doc 03 §13). The first move only reveals the
    // highlight; thereafter j/k walk sections and h/l walk within a horizontal one.
    onMoveRequested: function(dx, dy) {
      if (root.revealCursor()) { root.afterCursorMove(); return }
      if (dy !== 0) root.moveCursor(dy)
      else if (dx !== 0) root.moveCursorH(dx)
      root.afterCursorMove()
    }
    onActivateRequested: if (root.cursorActive) root.activateCursor()
    onCloseRequested: {
      if (root.pendingAction !== "") root.clearPendingAction()
      else root.close()
    }
    onTabRequested: function(direction) {
      if (root.bar && typeof root.bar.switchPanelFrom === "function")
        root.bar.switchPanelFrom(root.hostWidget || root, direction)
    }
    onTextKey: function(t) {
      // Digits and letters share the navigationLocked gate (doc 03 §13). Views are
      // addressed by key: 1 → Overview, 2 → Flow, 3 → Rules. No digit changed meaning
      // for an existing view.
      if (root.navigationLocked) return
      var inFlow = root.activeTabKey === "flow"
      if (t === "1") root.setViewByKey("overview")
      else if (t === "2") {
        if (inFlow) root.flowPopToZ0()
        else if (root.activeTabKey === "overview" && root.overviewDepth >= 1)
          root.openFlowForPlugin(root.selectedPluginId)     // detail sheet → Flow Z1 (§6.1)
        else root.setViewByKey("flow")
      }
      else if (t === "3") root.setViewByKey("rules")
      else if (t === "-") root.popDepth()
      else if (t === "/") root.showFinder()
      else if (t === "b") { root.toggleBackups(); if (inFlow) root.rebuildFlow() }
      else if (t === "a") { if (inFlow) root.flowAnalyzeCursor(); else root.analyzeSelected() }
      else if (t === "A") { if (inFlow) root.flowAnalyzeAll() }
      else if (t === "x") { if (inFlow) root.flowUnpinOrCancel() }
      else if (t === "m") { if (inFlow) root.flowToggleLens() }
      else if (t === "c") { if (inFlow) root.flowToggleMatrixClasses() }
      else if (t === "t") { if (inFlow) root.flowTrace() }
      else if (t === "?") { if (inFlow) root.flowLegendVisible = !root.flowLegendVisible }
      else if (t === "r" || t === "R") {
        if (root.scanAvailable && root.hostWidget) root.hostWidget.runScan()
      }
    }

    Column {
      id: shellColumn
      anchors.fill: parent
      spacing: Style.space(12)

      Column {
        id: fixedColumn
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          id: hero
          width: parent.width
          foreground: root.fg
          fontFamily: root.fontFamily
          iconSize: Style.font.display
          title: root.heroTitle()
          meta: root.heroMeta()
          detail: root.heroDetail()
          iconOpacity: root.heroIconOpacity()

          iconComponent: Component {
            OmaSafeShield {
              iconSize: Style.font.display
              filled: root.hasScanResult
              foreground: root.fg
              dimColor: root.dim
              urgent: root.urgent
              fontFamily: root.fontFamily
              resolvedFamily: Style.font.resolvedFamily
            }
          }

          trailingControl: Component {
            Button {
              iconText: Glyphs.ui_("rescan", Style.font.resolvedFamily)
              iconSpinning: root.checking
              tooltipText: "Run scan (r)"
              enabled: root.scanAvailable
              hasCursor: root.cursorActive && root.focusSection === "hero" && root.selectedIndex === 0
              foreground: root.fg
              fontFamily: root.fontFamily
              onClicked: if (root.hostWidget) root.hostWidget.runScan()
              onHovered: function(isHovered) { if (isHovered) root.hoverCursor("hero", 0) }
            }
          }
        }

        // Status line: verbatim CLI failure in urgent, else the stale-scan sentence
        // in dim, else hidden (the tailscale/Panel.qml:500–509 idiom).
        Text {
          id: statusLine
          width: parent.width
          visible: text !== ""
          text: root.scanStatusLineText()
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: root.scanStatusLineUrgent ? root.urgent : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        NoticeRow {
          visible: !root.cliVerified
          width: parent.width
          reason: "unavailable"
          text: "Plugins, review items, rules and the trust flow are unavailable until omasafe-cli " +
            (root.hostWidget ? root.hostWidget.cliVersionMin : "0.2.1") + " or newer is found on PATH."
          foreground: root.fg
          dim: root.dim
          urgent: root.urgent
          fontFamily: root.fontFamily
          resolvedFamily: Style.font.resolvedFamily
        }

        NoticeRow {
          visible: root.marketplaceStale
          width: parent.width
          reason: "stale"
          text: "Catalog snapshot " +
            Time.age(root.inventoryReport ? root.inventoryReport.marketplace_age_seconds : 0, true) + "."
          foreground: root.fg
          dim: root.dim
          urgent: root.urgent
          fontFamily: root.fontFamily
          resolvedFamily: Style.font.resolvedFamily
        }

        NoticeRow {
          visible: !!root.analysisReport && root.analysisReport.parser === null
          width: parent.width
          reason: "lexical-only"
          text: "Lexical-only analysis (no QML parser). Review items are text matches."
          foreground: root.fg
          dim: root.dim
          urgent: root.urgent
          fontFamily: root.fontFamily
          resolvedFamily: Style.font.resolvedFamily
        }

        NoticeRow {
          visible: root.inventoryLimitations.length > 0
          width: parent.width
          reason: "unsupported"
          text: "Coverage limits reported for the installed set: " +
            Labels.groupLimitations(root.inventoryLimitations).join(" · ")
          foreground: root.fg
          dim: root.dim
          urgent: root.urgent
          fontFamily: root.fontFamily
          resolvedFamily: Style.font.resolvedFamily
        }

        ButtonGroup {
          id: viewChips
          width: parent.width
          options: root.viewOptions
          value: root.activeTabKey
          focusable: false
          cursorIndex: (root.cursorActive && root.focusSection === "views") ? root.selectedIndex : -1
          fontSize: Style.font.bodySmall
          foreground: root.fg
          fontFamily: root.fontFamily
          onChanged: function(v) { root.setViewByKey(v) }
          onHovered: function(index, isHovered) { if (isHovered) root.hoverCursor("views", index) }
        }

        // The finder input, shown and focused by `/` (doc 03 §8). keyCatcher.blocked
        // follows its activeFocus.
        FinderField {
          id: finderField
          width: parent.width
          visible: root.finderActive
          foreground: root.fg
          font.family: root.fontFamily
          onTextChanged: root.finderText = text
          onSubmitted: root.openFinderResult(root.selectedIndex)
          onDismissed: root.hideFinder()
          onMoveResult: function(d) { root.moveFinderResult(d) }
        }

        // The depth breadcrumb, shown at depth ≥ 1 or while a return frame is held
        // (doc 03 §8, §13).
        Breadcrumb {
          width: parent.width
          visible: !root.finderActive && (root.overviewDepth >= 1 || root.returnFrame !== null)
          label: root.returnFrame && String(root.returnFrame.pluginId || "") !== ""
            ? root.returnFrame.pluginId : "All plugins"
          foreground: root.fg
          dim: root.dim
          fontFamily: root.fontFamily
          onBackRequested: root.popDepth()
        }
      }

      Flickable {
        id: activeFlick
        width: parent.width
        height: Math.max(Style.space(60), keyCatcher.height - fixedColumn.height - Style.space(12))
        contentWidth: width
        contentHeight: activeContent.implicitHeight
        clip: true
        // Gated on the sheet only, not navigationLocked: the panel must stay
        // scrollable through the up-to-60 s CLI calls (doc 03 §3).
        interactive: !sheet.opened
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Loader {
          id: activeLoader
          width: parent.width
          // The finder overlays the body; otherwise Overview (list or detail sheet)
          // or the Rules view.
          sourceComponent: root.finderActive ? finderResultsComponent
            : (root.activeTabKey === "flow" ? flowComponent
              : (root.activeTabKey === "rules" ? rulesComponent
                : (root.overviewDepth >= 1 ? pluginDetailComponent : overviewComponent)))

          Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
          }
        }

        Item {
          id: activeContent
          width: parent.width
          implicitHeight: activeLoader.item ? activeLoader.item.implicitHeight : 0
        }
      }
    }

    // The confirmation sheet (T1.9): a sibling of the Flickable at z: 20 outside the
    // view Loader. It keeps the kit ConfirmDialog contract and enforces the nine
    // no-bypass invariants (doc 03 §10). The identity rows are the PINNED T0.18
    // facts; runPendingAction() copies those into argv, never re-derived at click.
    ConfirmSheet {
      id: sheet
      anchors.fill: parent
      opened: root.pendingAction !== ""
      title: root.sheetTitle()
      body: root.sheetBody()
      infoRows: root.sheetInfoRows()
      labelWidth: Style.space(88)
      showPolicy: root.sheetShowPolicy()
      policyValue: root.sheetPolicyValue()
      policyDefinition: root.sheetPolicyDefinition()
      confirmLabel: root.sheetConfirmLabel()
      destructive: root.sheetDestructive()
      busy: root.operationRunning
      foreground: root.fg
      dim: root.dim
      urgent: root.urgent
      fontFamily: root.fontFamily
      returnFocusItem: keyCatcher
      onCanceled: root.clearPendingAction()
      onConfirmed: root.runPendingAction()
      onPolicyChanged: function(value) { root.setSheetPolicy(value) }
    }
  }
  }

  // The active view: Overview (with its plugin detail sheet at depth 1). Each view
  // is a file in views/ that binds to this panel through `panel: root` (doc 05 §9).
  Component {
    id: overviewComponent
    OverviewView { panel: root }
  }

  Component {
    id: pluginDetailComponent
    PluginDetailView { panel: root }
  }

  Component {
    id: rulesComponent
    RulesView { panel: root }
  }

  Component {
    id: flowComponent
    FlowView { panel: root }
  }

  Component {
    id: finderResultsComponent
    FinderResultsView { panel: root }
  }

  // Inline "Updating catalog… <n> s" counter. Gated on opened && the refresh running,
  // so it never ticks while closed or idle (doc 02 §2.6 / P11).
  Timer {
    interval: 1000
    repeat: true
    running: root.opened && marketplaceRefreshProcess.running
    onTriggered: root.catalogElapsed++
  }

  Connections {
    target: root.hostWidget
    // Load a panel that was opened before the CLI finished verifying, as soon as
    // it becomes verified.
    function onCliVerifiedChanged() {
      if (root.opened && root.cliVerified) {
        if (root.inventoryReport === null) root.loadInventory()
        root.loadScheduleStatus()
        root.loadOverrides()
        if (root.activeTabKey === "rules") { root.ensureRulesList(); root.ensureCoverage() }
      } else if (!root.cliVerified) {
        // CLI gate loss: discard any in-flight analysis and the queue (doc 04 §10.1).
        root.analysisSweepGeneration++
        root.analysisQueue = []
        root.analysisStateById = ({})
      }
    }
    function onCliVersionChanged() {
      // Analysis and rule explanations are versioned CLI output. A new binary
      // must not reuse a report produced by the previous analyzer/policy.
      root.clearAnalysisCache()
      root.coverageReport = null
      root.coverageCliVersion = ""
      root.coverageDetailsExpanded = false
      root.rulesListReport = null
      root.rulesListCliVersion = ""
      root.ruleExplanationCache = ({})
      root.ruleExplanation = ""
      root.ruleExplanationResult = null
      root.ruleExplanationError = ""
      root.ruleExplanationKey = ""
      root.ruleExplanationLoading = false
    }
    function onAlertsChanged() {
      // A scan whose alerts change no longer clears the whole cache: drop only the
      // plugins whose analysis these two alert kinds invalidate (T0.16).
      var stale = []
      var current = root.alerts || []
      for (var i = 0; i < current.length; i++) {
        var kind = String(current[i].kind || "")
        if (kind === "analyzer-policy-update" || kind === "source-drift") {
          var pid = String(current[i].plugin_id || "")
          if (pid !== "" && stale.indexOf(pid) < 0) stale.push(pid)
        }
      }
      root.dropAnalysisCacheFor(stale)
      root.refreshEnforcementStatus()
      // Re-fetch the open detail sheet's analysis if its cache was just dropped; the
      // Overview list reflects the drop through vm without a fetch (doc 03 §13).
      if (root.opened && root.overviewDepth >= 1) root.hydrateAnalysis()
    }
  }

  Process {
    id: inventoryProcess
    property var killTimer: inventoryKill
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    property bool catalogOnly: false
    property int runGeneration: 0
    property bool parsedSuccessfully: false
    command: root.cliCommand(["plugins", "inventory", "--format", "json"])
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (inventoryProcess.settled) return
        inventoryProcess.stdoutBuffer = (inventoryProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (inventoryProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          inventoryProcess.settled = true
          root.panelError = "Inventory output exceeded the configured output cap."
          inventoryTimeout.stop()
          root.terminateBoundedProcess(inventoryProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (inventoryProcess.settled) return
        inventoryProcess.stderrBuffer = (inventoryProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (inventoryProcess.stderrBuffer.length > root.v02OutputCharCap) {
          inventoryProcess.settled = true
          root.panelError = "Inventory error output exceeded the configured output cap."
          inventoryTimeout.stop()
          root.terminateBoundedProcess(inventoryProcess)
        }
      }
    }
    onRunningChanged: if (inventoryProcess.running) {
      inventoryKill.stop()
      inventoryProcess.catalogOnly = root.nextInventoryCatalogOnly
      root.nextInventoryCatalogOnly = false
      root.inventoryGeneration++
      inventoryProcess.runGeneration = root.inventoryGeneration
      inventoryProcess.parsedSuccessfully = false
      if (inventoryProcess.catalogOnly)
        root.refreshInventoryGeneration = inventoryProcess.runGeneration
      inventoryProcess.stdoutBuffer = ""
      inventoryProcess.stderrBuffer = ""
      inventoryProcess.settled = false
      inventoryTimeout.restart()
    }
    onExited: function(exitCode) {
      root.stopBoundedProcessTimers(inventoryProcess, inventoryTimeout)
      if (!inventoryProcess.settled) {
        inventoryProcess.settled = true
        var error = String(inventoryProcess.stderrBuffer || "").trim()
        if (exitCode === 0) {
          root.applyInventory(inventoryProcess.stdoutBuffer, inventoryProcess.catalogOnly)
          inventoryProcess.parsedSuccessfully = root.inventoryReport !== null
        } else {
          root.inventoryReport = null
          root.panelError = error || "Plugin inventory failed with exit status " + exitCode + "."
        }
      }
      // Drain a queued reload first: the applied inventory may be the pre-refresh
      // one, so run the refreshed reload before publishing any refresh success.
      if (root.inventoryReloadPending) {
        root.inventoryReloadPending = false
        root.nextInventoryCatalogOnly = true
        if (!inventoryProcess.running) inventoryProcess.running = true
        return
      }
      // The refreshed catalog is now applied; publish the held success message,
      // but only if the reload actually produced a valid inventory (a failed
      // reload leaves panelError to explain the problem instead).
      if (root.marketplaceRefreshAwaitingInventory &&
          root.refreshInventoryGeneration === inventoryProcess.runGeneration) {
        root.marketplaceRefreshAwaitingInventory = false
        if (inventoryProcess.parsedSuccessfully && root.marketplaceRefreshError === "" &&
            root.inventoryReport !== null)
          root.marketplaceRefreshMessage =
            root.pendingRefreshMessage !== "" ? root.pendingRefreshMessage
                                               : "Marketplace catalog updated."
        else if (!inventoryProcess.parsedSuccessfully && root.marketplaceRefreshError === "")
          root.marketplaceRefreshError = root.panelError ||
            "Marketplace catalog refreshed, but the inventory reload failed."
      root.pendingRefreshMessage = ""
      }
    }
  }

  Timer {
    id: inventoryTimeout
    interval: 30000
    repeat: false
    onTriggered: {
      if (inventoryProcess.settled) return
      inventoryProcess.settled = true
      root.panelError = "Plugin inventory timed out after 30 seconds."
      root.terminateBoundedProcess(inventoryProcess)
    }
  }

  Timer {
    id: inventoryKill
    interval: 3000
    repeat: false
    onTriggered: if (inventoryProcess.running) inventoryProcess.signal(9)
  }

  Process {
    id: marketplaceRefreshProcess
    property var killTimer: marketplaceRefreshKill
    command: root.cliCommand(["marketplace", "refresh", "--latest"])
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.marketplaceRefreshSettled) return
        root.pendingRefreshMessage += String(chunk)
        if (root.pendingRefreshMessage.length > root.v02OutputCharCap) {
          root.marketplaceRefreshSettled = true
          root.marketplaceRefreshError = "Marketplace update output exceeded the configured output cap."
          marketplaceRefreshTimeout.stop()
          root.terminateBoundedProcess(marketplaceRefreshProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.marketplaceRefreshSettled) return
        root.marketplaceRefreshError += String(chunk)
        if (root.marketplaceRefreshError.length > root.v02OutputCharCap) {
          root.marketplaceRefreshSettled = true
          root.marketplaceRefreshError = "Marketplace update error output exceeded the configured output cap."
          marketplaceRefreshTimeout.stop()
          root.terminateBoundedProcess(marketplaceRefreshProcess)
        }
      }
    }
    onExited: function(exitCode) {
      root.stopBoundedProcessTimers(marketplaceRefreshProcess, marketplaceRefreshTimeout)
      if (root.marketplaceRefreshSettled) return
      root.marketplaceRefreshSettled = true
      if (exitCode === 0) {
        root.marketplaceRefreshError = ""
        // Hold the success message until the refreshed inventory has actually
        // been applied (published from inventoryProcess.onExited).
        root.marketplaceRefreshMessage = ""
        root.marketplaceRefreshAwaitingInventory = true
        root.reloadInventoryForRefresh()
      } else if (root.marketplaceRefreshError === "") {
        root.marketplaceRefreshError =
          "Marketplace update failed. Check the network connection and CLI version."
      }
    }
  }

  Timer {
    id: marketplaceRefreshTimeout
    interval: 60000
    repeat: false
    onTriggered: {
      if (marketplaceRefreshProcess.running) {
        root.marketplaceRefreshSettled = true
        root.marketplaceRefreshError = "Marketplace update timed out after 60 seconds."
        root.terminateBoundedProcess(marketplaceRefreshProcess)
      }
    }
  }

  Timer {
    id: marketplaceRefreshKill
    interval: 3000
    repeat: false
    onTriggered: if (marketplaceRefreshProcess.running) marketplaceRefreshProcess.signal(9)
  }

  Process {
    id: statusProcess
    property var killTimer: statusKill
    property var nextCommand: null
    property int requestId: 0
    property int nextRequestId: 0
    property string pluginId: ""
    property string nextPluginId: ""
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    function prepare() {
      stdoutBuffer = ""
      stderrBuffer = ""
      settled = false
      statusKill.stop()
      statusTimeout.restart()
    }
    command: root.cliCommand(["plugins", "status", "", "--format", "json"])
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (statusProcess.settled) return
        statusProcess.stdoutBuffer = (statusProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (statusProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          statusProcess.settled = true
          if (statusProcess.requestId === root.selectionRequestId)
            root.selectedError = "Status output exceeded the configured output cap."
          statusTimeout.stop()
          root.terminateBoundedProcess(statusProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (statusProcess.settled) return
        statusProcess.stderrBuffer = (statusProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (statusProcess.stderrBuffer.length > root.v02OutputCharCap) {
          statusProcess.settled = true
          if (statusProcess.requestId === root.selectionRequestId)
            root.selectedError = "Status error output exceeded the configured output cap."
          statusTimeout.stop()
          root.terminateBoundedProcess(statusProcess)
        }
      }
    }
    onExited: {
      root.stopBoundedProcessTimers(statusProcess, statusTimeout)
      if (!statusProcess.settled) {
        statusProcess.settled = true
        if (statusProcess.pluginId === root.selectedPluginId &&
            statusProcess.requestId === root.selectionRequestId) {
          if (statusProcess.stderrBuffer.trim() !== "") root.selectedError = statusProcess.stderrBuffer.trim()
          else root.applyStatus(statusProcess.stdoutBuffer, statusProcess.pluginId, statusProcess.requestId)
        }
      }
      if (statusProcess.nextCommand) {
        var command = statusProcess.nextCommand
        var requestId = statusProcess.nextRequestId
        var pluginId = statusProcess.nextPluginId
        statusProcess.nextCommand = null
        root.launchProcess(statusProcess, command, requestId, pluginId)
      }
    }
  }

  Process {
    id: diffProcess
    property var killTimer: diffKill
    property var nextCommand: null
    property int requestId: 0
    property int nextRequestId: 0
    property string pluginId: ""
    property string nextPluginId: ""
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    function prepare() {
      stdoutBuffer = ""
      stderrBuffer = ""
      settled = false
      diffKill.stop()
      diffTimeout.restart()
    }
    command: root.cliCommand(["plugins", "diff", "", "--format", "json"])
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (diffProcess.settled) return
        diffProcess.stdoutBuffer = (diffProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (diffProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          diffProcess.settled = true
          if (diffProcess.requestId === root.selectionRequestId)
            root.selectedError = "Diff output exceeded the configured output cap."
          diffTimeout.stop()
          root.terminateBoundedProcess(diffProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (diffProcess.settled) return
        diffProcess.stderrBuffer = (diffProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (diffProcess.stderrBuffer.length > root.v02OutputCharCap) {
          diffProcess.settled = true
          if (diffProcess.requestId === root.selectionRequestId)
            root.selectedError = "Diff error output exceeded the configured output cap."
          diffTimeout.stop()
          root.terminateBoundedProcess(diffProcess)
        }
      }
    }
    onExited: {
      root.stopBoundedProcessTimers(diffProcess, diffTimeout)
      if (!diffProcess.settled) {
        diffProcess.settled = true
        if (diffProcess.pluginId === root.selectedPluginId &&
            diffProcess.requestId === root.selectionRequestId) {
          if (diffProcess.stderrBuffer.trim() !== "") root.selectedError = diffProcess.stderrBuffer.trim()
          else root.applyDiff(diffProcess.stdoutBuffer, diffProcess.pluginId, diffProcess.requestId)
        }
      }
      if (diffProcess.nextCommand) {
        var command = diffProcess.nextCommand
        var requestId = diffProcess.nextRequestId
        var pluginId = diffProcess.nextPluginId
        diffProcess.nextCommand = null
        root.launchProcess(diffProcess, command, requestId, pluginId)
      }
    }
  }

  Timer {
    id: statusTimeout
    interval: 30000
    repeat: false
    onTriggered: {
      if (statusProcess.settled) return
      statusProcess.settled = true
      if (statusProcess.requestId === root.selectionRequestId)
        root.selectedError = "Plugin status timed out after 30 seconds."
      root.terminateBoundedProcess(statusProcess)
    }
  }

  Timer {
    id: diffTimeout
    interval: 30000
    repeat: false
    onTriggered: {
      if (diffProcess.settled) return
      diffProcess.settled = true
      if (diffProcess.requestId === root.selectionRequestId)
        root.selectedError = "Plugin diff timed out after 30 seconds."
      root.terminateBoundedProcess(diffProcess)
    }
  }

  Timer {
    id: statusKill
    interval: 3000
    repeat: false
    onTriggered: if (statusProcess.running) statusProcess.signal(9)
  }

  Timer {
    id: diffKill
    interval: 3000
    repeat: false
    onTriggered: if (diffProcess.running) diffProcess.signal(9)
  }

  Process {
    id: listStatusProcess
    property var killTimer: listStatusKill
    property string pluginId: ""
    property int generation: 0
    property bool receivedReport: false
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    function prepare() {
      stdoutBuffer = ""
      stderrBuffer = ""
      settled = false
      listStatusKill.stop()
      listStatusTimeout.restart()
    }
    command: root.cliCommand(["plugins", "status", "", "--format", "json"])
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (listStatusProcess.settled) return
        listStatusProcess.stdoutBuffer = (listStatusProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (listStatusProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          listStatusProcess.settled = true
          listStatusTimeout.stop()
          root.terminateBoundedProcess(listStatusProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (listStatusProcess.settled) return
        listStatusProcess.stderrBuffer = (listStatusProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (listStatusProcess.stderrBuffer.length > root.v02OutputCharCap) {
          listStatusProcess.settled = true
          if (listStatusProcess.generation === root.statusSweepGeneration)
            root.recordPluginStatus(listStatusProcess.pluginId, { state: "unavailable" })
          listStatusTimeout.stop()
          root.terminateBoundedProcess(listStatusProcess)
        }
      }
    }
    onExited: {
      root.stopBoundedProcessTimers(listStatusProcess, listStatusTimeout)
      if (!listStatusProcess.settled) {
        listStatusProcess.settled = true
        if (listStatusProcess.generation === root.statusSweepGeneration) {
          if (exitCode === 0) {
            listStatusProcess.receivedReport = true
            root.applyListedPluginStatus(listStatusProcess.pluginId,
              listStatusProcess.stdoutBuffer, listStatusProcess.generation)
          } else {
            root.recordPluginStatus(listStatusProcess.pluginId, { state: "unavailable" })
          }
        }
      }
      Qt.callLater(root.runNextPluginStatus)
    }
  }

  Timer {
    id: listStatusTimeout
    interval: 30000
    repeat: false
    onTriggered: {
      if (listStatusProcess.settled) return
      listStatusProcess.settled = true
      if (listStatusProcess.generation === root.statusSweepGeneration)
        root.recordPluginStatus(listStatusProcess.pluginId, { state: "unavailable" })
      root.terminateBoundedProcess(listStatusProcess)
    }
  }

  Process {
    id: enforcementStatusProcess
    property var killTimer: enforcementStatusKill
    property var nextCommand: null
    property int requestId: 0
    property int nextRequestId: 0
    property string pluginId: ""
    property string nextPluginId: ""
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    function prepare() {
      stdoutBuffer = ""
      stderrBuffer = ""
      settled = false
      enforcementStatusKill.stop()
      enforcementStatusTimeout.restart()
    }
    command: root.cliCommand(["plugins", "enforcement-status", "", "--format", "json"])
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (enforcementStatusProcess.settled) return
        enforcementStatusProcess.stdoutBuffer =
          (enforcementStatusProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (enforcementStatusProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          enforcementStatusProcess.settled = true
          if (enforcementStatusProcess.requestId === root.selectionRequestId)
            root.enforcementError = "Enforcement status output exceeded the configured output cap."
          root.enforcementLoading = false
          enforcementStatusTimeout.stop()
          root.terminateBoundedProcess(enforcementStatusProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (enforcementStatusProcess.settled) return
        enforcementStatusProcess.stderrBuffer =
          (enforcementStatusProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (enforcementStatusProcess.stderrBuffer.length > root.v02OutputCharCap) {
          enforcementStatusProcess.settled = true
          if (enforcementStatusProcess.requestId === root.selectionRequestId)
            root.enforcementError = "Enforcement status error output exceeded the configured output cap."
          root.enforcementLoading = false
          enforcementStatusTimeout.stop()
          root.terminateBoundedProcess(enforcementStatusProcess)
        }
      }
    }
    onExited: {
      root.stopBoundedProcessTimers(enforcementStatusProcess, enforcementStatusTimeout)
      if (!enforcementStatusProcess.settled) {
        enforcementStatusProcess.settled = true
        if (enforcementStatusProcess.pluginId === root.selectedPluginId &&
            enforcementStatusProcess.requestId === root.selectionRequestId) {
          if (exitCode === 0)
            root.applyEnforcementStatus(enforcementStatusProcess.stdoutBuffer,
              enforcementStatusProcess.pluginId, enforcementStatusProcess.requestId)
          else {
            root.enforcementDecision = null
            root.enforcementError = "Enforcement status is unavailable."
          }
          root.enforcementLoading = false
        }
      }
      if (enforcementStatusProcess.nextCommand) {
        var command = enforcementStatusProcess.nextCommand
        var requestId = enforcementStatusProcess.nextRequestId
        var pluginId = enforcementStatusProcess.nextPluginId
        enforcementStatusProcess.nextCommand = null
        root.launchProcess(enforcementStatusProcess, command, requestId, pluginId)
      }
    }
  }

  Timer {
    id: enforcementStatusTimeout
    interval: 30000
    repeat: false
    onTriggered: {
      if (enforcementStatusProcess.settled) return
      enforcementStatusProcess.settled = true
      if (enforcementStatusProcess.requestId === root.selectionRequestId) {
        root.enforcementLoading = false
        root.enforcementError = "Enforcement status timed out after 30 seconds."
      }
      root.terminateBoundedProcess(enforcementStatusProcess)
    }
  }

  Timer {
    id: listStatusKill
    interval: 3000
    repeat: false
    onTriggered: if (listStatusProcess.running) listStatusProcess.signal(9)
  }

  Timer {
    id: enforcementStatusKill
    interval: 3000
    repeat: false
    onTriggered: if (enforcementStatusProcess.running) enforcementStatusProcess.signal(9)
  }

  Process {
    id: scheduleStatusProcess
    property var killTimer: scheduleStatusKill
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    function startRequest() {
      if (running) return
      stdoutBuffer = ""
      stderrBuffer = ""
      settled = false
      root.scheduleLoading = true
      scheduleStatusKill.stop()
      scheduleStatusTimeout.restart()
      command = root.cliCommand(["schedule", "status", "--format", "json"])
      running = true
    }
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (scheduleStatusProcess.settled) return
        scheduleStatusProcess.stdoutBuffer =
          (scheduleStatusProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (scheduleStatusProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          scheduleStatusProcess.settled = true
          root.scheduleLoading = false
          root.scheduleError = "Schedule status output exceeded the configured output cap."
          scheduleStatusTimeout.stop()
          root.terminateBoundedProcess(scheduleStatusProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (scheduleStatusProcess.settled) return
        scheduleStatusProcess.stderrBuffer =
          (scheduleStatusProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (scheduleStatusProcess.stderrBuffer.length > root.v02OutputCharCap) {
          scheduleStatusProcess.settled = true
          root.scheduleLoading = false
          root.scheduleError = "Schedule status error output exceeded the configured output cap."
          scheduleStatusTimeout.stop()
          root.terminateBoundedProcess(scheduleStatusProcess)
        }
      }
    }
    onExited: {
      root.stopBoundedProcessTimers(scheduleStatusProcess, scheduleStatusTimeout)
      if (!scheduleStatusProcess.settled) {
        scheduleStatusProcess.settled = true
        if (exitCode === 0) root.applyScheduleStatus(scheduleStatusProcess.stdoutBuffer)
        else {
          root.scheduleReport = null
          root.scheduleError = "Schedule status is unavailable."
        }
        root.scheduleLoading = false
      }
      scheduleStatusProcess.stdoutBuffer = ""
      scheduleStatusProcess.stderrBuffer = ""
    }
  }

  Timer {
    id: scheduleStatusTimeout
    interval: 15000
    repeat: false
    onTriggered: {
      if (scheduleStatusProcess.settled) return
      scheduleStatusProcess.settled = true
      root.scheduleLoading = false
      root.scheduleError = "Schedule status timed out after 15 seconds."
      root.terminateBoundedProcess(scheduleStatusProcess)
    }
  }

  Timer {
    id: scheduleStatusKill
    interval: 3000
    repeat: false
    onTriggered: if (scheduleStatusProcess.running) scheduleStatusProcess.signal(9)
  }

  Process {
    id: scheduleInstallProcess
    property var killTimer: scheduleInstallKill
    property string policy: "advisory"
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (scheduleInstallProcess.settled) return
        scheduleInstallProcess.stdoutBuffer =
          (scheduleInstallProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (scheduleInstallProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          scheduleInstallProcess.settled = true
          root.scheduleInstallError = "Schedule install output exceeded the configured output cap."
          root.clearPendingAction()
          scheduleInstallTimeout.stop()
          root.terminateBoundedProcess(scheduleInstallProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (scheduleInstallProcess.settled) return
        scheduleInstallProcess.stderrBuffer =
          (scheduleInstallProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (scheduleInstallProcess.stderrBuffer.length > root.v02OutputCharCap) {
          scheduleInstallProcess.settled = true
          root.scheduleInstallError = "Schedule install error output exceeded the configured output cap."
          root.clearPendingAction()
          scheduleInstallTimeout.stop()
          root.terminateBoundedProcess(scheduleInstallProcess)
        }
      }
    }
    onExited: function(exitCode) {
      root.stopBoundedProcessTimers(scheduleInstallProcess, scheduleInstallTimeout)
      if (!scheduleInstallProcess.settled) {
        scheduleInstallProcess.settled = true
        if (exitCode === 0) {
          root.clearPendingAction()
          root.scheduleInstallError = ""
          root.scheduleInstallMessage = "Installed " + scheduleInstallProcess.policy +
            " report-only schedule."
          root.scheduleReport = null
          root.loadScheduleStatus()
        } else {
          root.scheduleInstallError = String(scheduleInstallProcess.stderrBuffer || "").trim() ||
            "Schedule installation failed."
          root.scheduleLoading = false
        }
      }
      root.scheduleInstallStdout = scheduleInstallProcess.stdoutBuffer
      root.scheduleInstallStderr = scheduleInstallProcess.stderrBuffer
      scheduleInstallProcess.stdoutBuffer = ""
      scheduleInstallProcess.stderrBuffer = ""
    }
  }

  Timer {
    id: scheduleInstallTimeout
    interval: 30000
    repeat: false
    onTriggered: {
      if (scheduleInstallProcess.settled) return
      scheduleInstallProcess.settled = true
      root.scheduleInstallError = "Schedule installation timed out after 30 seconds."
      root.clearPendingAction()
      root.terminateBoundedProcess(scheduleInstallProcess)
    }
  }

  Timer {
    id: scheduleInstallKill
    interval: 3000
    repeat: false
    onTriggered: if (scheduleInstallProcess.running) scheduleInstallProcess.signal(9)
  }

  Process {
    id: coverageProcess
    property var killTimer: coverageKill
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    function startRequest() {
      if (running) return
      stdoutBuffer = ""
      stderrBuffer = ""
      settled = false
      root.coverageLoading = true
      coverageKill.stop()
      coverageTimeout.restart()
      command = root.cliCommand(["rules", "coverage", "--format", "json"])
      running = true
    }
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (coverageProcess.settled) return
        coverageProcess.stdoutBuffer =
          (coverageProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (coverageProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          coverageProcess.settled = true
          root.coverageLoading = false
          root.coverageError = "Coverage output exceeded the configured output cap."
          coverageTimeout.stop()
          root.terminateBoundedProcess(coverageProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (coverageProcess.settled) return
        coverageProcess.stderrBuffer =
          (coverageProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (coverageProcess.stderrBuffer.length > root.v02OutputCharCap) {
          coverageProcess.settled = true
          root.coverageLoading = false
          root.coverageError = "Coverage error output exceeded the configured output cap."
          coverageTimeout.stop()
          root.terminateBoundedProcess(coverageProcess)
        }
      }
    }
    onExited: {
      root.stopBoundedProcessTimers(coverageProcess, coverageTimeout)
      if (!coverageProcess.settled) {
        coverageProcess.settled = true
        if (exitCode === 0) root.applyCoverage(coverageProcess.stdoutBuffer)
        else {
          root.coverageReport = null
          root.coverageError = "Rule coverage is unavailable."
        }
        root.coverageLoading = false
      }
      coverageProcess.stdoutBuffer = ""
      coverageProcess.stderrBuffer = ""
    }
  }

  Timer {
    id: coverageTimeout
    interval: 15000
    repeat: false
    onTriggered: {
      if (coverageProcess.settled) return
      coverageProcess.settled = true
      root.coverageLoading = false
      root.coverageError = "Rule coverage timed out after 15 seconds."
      root.terminateBoundedProcess(coverageProcess)
    }
  }

  Timer {
    id: coverageKill
    interval: 3000
    repeat: false
    onTriggered: if (coverageProcess.running) coverageProcess.signal(9)
  }

  // The 16th bounded collector (decision 4): `rules list --format json`, cloned from
  // coverageProcess verbatim — 15 s timeout, 3 s kill, 2 MiB cap, SplitParser per
  // stream, first-terminal latch, cached per CLI version. Measured 4 ms / 25 KB.
  Process {
    id: rulesListProcess
    property var killTimer: rulesListKill
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    function startRequest() {
      if (running) return
      stdoutBuffer = ""
      stderrBuffer = ""
      settled = false
      root.rulesListLoading = true
      rulesListKill.stop()
      rulesListTimeout.restart()
      command = root.cliCommand(["rules", "list", "--format", "json"])
      running = true
    }
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (rulesListProcess.settled) return
        rulesListProcess.stdoutBuffer =
          (rulesListProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (rulesListProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          rulesListProcess.settled = true
          root.rulesListLoading = false
          root.rulesListError = "Rule catalog output exceeded the configured output cap."
          rulesListTimeout.stop()
          root.terminateBoundedProcess(rulesListProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (rulesListProcess.settled) return
        rulesListProcess.stderrBuffer =
          (rulesListProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (rulesListProcess.stderrBuffer.length > root.v02OutputCharCap) {
          rulesListProcess.settled = true
          root.rulesListLoading = false
          root.rulesListError = "Rule catalog error output exceeded the configured output cap."
          rulesListTimeout.stop()
          root.terminateBoundedProcess(rulesListProcess)
        }
      }
    }
    onExited: {
      root.stopBoundedProcessTimers(rulesListProcess, rulesListTimeout)
      if (!rulesListProcess.settled) {
        rulesListProcess.settled = true
        if (exitCode === 0) root.applyRulesList(rulesListProcess.stdoutBuffer)
        else {
          root.rulesListReport = null
          root.rulesListError = "Rule catalog is unavailable."
        }
        root.rulesListLoading = false
      }
      rulesListProcess.stdoutBuffer = ""
      rulesListProcess.stderrBuffer = ""
    }
  }

  Timer {
    id: rulesListTimeout
    interval: 15000
    repeat: false
    onTriggered: {
      if (rulesListProcess.settled) return
      rulesListProcess.settled = true
      root.rulesListLoading = false
      root.rulesListError = "Rule catalog timed out after 15 seconds."
      root.terminateBoundedProcess(rulesListProcess)
    }
  }

  Timer {
    id: rulesListKill
    interval: 3000
    repeat: false
    onTriggered: if (rulesListProcess.running) rulesListProcess.signal(9)
  }

  Process {
    id: overrideProcess
    property var killTimer: overrideKill
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    function startRequest() {
      if (running) return
      stdoutBuffer = ""
      stderrBuffer = ""
      settled = false
      root.overrideLoading = true
      overrideKill.stop()
      overrideTimeout.restart()
      command = root.cliCommand(["plugins", "override", "list", "--format", "json"])
      running = true
    }
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (overrideProcess.settled) return
        overrideProcess.stdoutBuffer =
          (overrideProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (overrideProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          overrideProcess.settled = true
          root.overrideLoading = false
          root.overrideError = "Override status output exceeded the configured output cap."
          overrideTimeout.stop()
          root.terminateBoundedProcess(overrideProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (overrideProcess.settled) return
        overrideProcess.stderrBuffer =
          (overrideProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (overrideProcess.stderrBuffer.length > root.v02OutputCharCap) {
          overrideProcess.settled = true
          root.overrideLoading = false
          root.overrideError = "Override status error output exceeded the configured output cap."
          overrideTimeout.stop()
          root.terminateBoundedProcess(overrideProcess)
        }
      }
    }
    onExited: {
      root.stopBoundedProcessTimers(overrideProcess, overrideTimeout)
      if (!overrideProcess.settled) {
        overrideProcess.settled = true
        if (exitCode === 0) root.applyOverrides(overrideProcess.stdoutBuffer)
        else {
          root.overrideReport = null
          root.overrideError = "Override status is unavailable."
        }
        root.overrideLoading = false
      }
      overrideProcess.stdoutBuffer = ""
      overrideProcess.stderrBuffer = ""
    }
  }

  Timer {
    id: overrideTimeout
    interval: 15000
    repeat: false
    onTriggered: {
      if (overrideProcess.settled) return
      overrideProcess.settled = true
      root.overrideLoading = false
      root.overrideError = "Override status timed out after 15 seconds."
      root.terminateBoundedProcess(overrideProcess)
    }
  }

  Timer {
    id: overrideKill
    interval: 3000
    repeat: false
    onTriggered: if (overrideProcess.running) overrideProcess.signal(9)
  }

  // Override validity and enforcement decisions remain CLI-owned. Periodic
  // read-only refresh keeps an expired binding from remaining visible as the
  // current decision while the panel stays open; this timer never evaluates
  // expiry or authorizes an operation locally.
  Timer {
    id: enforcementRefreshTimer
    interval: 60000
    repeat: true
    running: root.opened && root.cliVerified
    onTriggered: {
      root.refreshEnforcementStatus()
      root.loadOverrides()
    }
  }

  Process {
    id: analysisProcess
    property var killTimer: analysisKill
    property string pluginId: ""
    property int requestId: 0
    property string nextPluginId: ""
    property int nextRequestId: 0
    property int sweepGeneration: 0     // the analysisSweepGeneration this run belongs to
    function startFor(id, request) {
      if (running) {
        nextPluginId = id
        nextRequestId = request
        root.terminateBoundedProcess(analysisProcess)
        return
      }
      pluginId = id
      requestId = request
      root.analysisStdout = ""
      root.analysisStderr = ""
      root.analysisSettled = false
      analysisKill.stop()
      analysisTimeout.restart()
      command = root.cliCommand(["plugins", "analyze", id, "--format", "json"])
      running = true
    }
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.analysisSettled) return
        root.analysisStdout = (root.analysisStdout + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (root.analysisStdout.length > root.v02OutputCharCap) {
          root.analysisSettled = true
          root.analysisLoading = false
          root.analysisError = "Analysis output exceeded the configured output cap."
          if (analysisProcess.pluginId !== "") root.setAnalysisState(analysisProcess.pluginId, "unavailable")
          analysisTimeout.stop()
          root.terminateBoundedProcess(analysisProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.analysisSettled) return
        root.analysisStderr = (root.analysisStderr + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (root.analysisStderr.length > root.v02OutputCharCap) {
          root.analysisSettled = true
          root.analysisLoading = false
          root.analysisError = "Analysis error output exceeded the configured output cap."
          if (analysisProcess.pluginId !== "") root.setAnalysisState(analysisProcess.pluginId, "unavailable")
          analysisTimeout.stop()
          root.terminateBoundedProcess(analysisProcess)
        }
      }
    }
    onExited: function(exitCode) {
      root.stopBoundedProcessTimers(analysisProcess, analysisTimeout)
      var pid = analysisProcess.pluginId
      // Discard a result from a stale context: the panel closed, the CLI version/gate
      // changed, or `x` dropped the sweep — all bump analysisSweepGeneration (doc 04
      // §10.1). Caching it would stamp old output with the CURRENT CLI version.
      var stale = analysisProcess.sweepGeneration !== root.analysisSweepGeneration
      if (!root.analysisSettled && stale) {
        root.analysisSettled = true
        root.analysisStdout = ""; root.analysisStderr = ""
        // Drop any deferred preempt too (T4.0): its generation is gone, so a stale
        // selected-plugin request must not survive to be chained by a later, current
        // completion. Every non-stale exit already consumes or clears these slots, so
        // clearing here is the one path that otherwise leaks a request across runs.
        analysisProcess.nextPluginId = ""
        analysisProcess.nextRequestId = 0
        return   // no apply, no cache, no state, no chain (the queue was cleared)
      }
      if (!root.analysisSettled) {
        root.analysisSettled = true
        var stderr = String(root.analysisStderr || "").trim()
        // A queue run (§10.1) caches and records state for its own plugin regardless
        // of the current selection; the display slots update only when it is selected.
        var isSelected = (pid === root.selectedPluginId && analysisProcess.requestId === root.analysisRequestId)
        var plugin = root.pluginById(pid)
        if (exitCode === 0 || exitCode === 4) {
          try {
            var report = JSON.parse(root.analysisStdout)
            if (String(report.schema || "") !== "omasafe.report.v1" ||
                !report.result || report.result.analysis === undefined ||
                !report.result.analysis ||
                String(report.result.analysis.schema || "") !== "omasafe.analysis.v1")
              throw new Error("missing result.analysis")
            var analysis = report.result.analysis || {}
            var coverageStates = report.result.payload_inventory
              ? report.result.payload_inventory.coverage_states : null
            if (plugin) root.cacheAnalysis(pid, root.analysisDigestFor(plugin), analysis, coverageStates)
            root.setAnalysisState(pid, "analyzed")
            if (isSelected) {
              root.analysisReport = analysis
              root.analysisCoverageStates = coverageStates
              root.analysisPolicyKey = root.analysisPolicyKeyFor(analysis)
              root.analysisError = ""
              root.analysisLoading = false
            }
          } catch (error) {
            root.setAnalysisState(pid, "unavailable")
            if (isSelected) {
              root.analysisReport = null
              root.analysisError = stderr || "CLI returned an invalid analysis report."
              root.analysisLoading = false
            }
          }
        } else {
          root.setAnalysisState(pid, "unavailable")
          if (isSelected) {
            root.analysisReport = null
            root.analysisError = stderr || "Analysis failed with exit status " + exitCode + "."
            root.analysisLoading = false
          }
        }
      }
      root.analysisStdout = ""
      root.analysisStderr = ""
      // Chain: a selected-path preempt (nextPluginId) wins; otherwise drain the queue,
      // but only if this run's generation is still current (x / close bumps it).
      if (analysisProcess.nextPluginId !== "") {
        var nextPlugin = analysisProcess.nextPluginId
        var nextRequest = analysisProcess.nextRequestId
        analysisProcess.nextPluginId = ""
        analysisProcess.startFor(nextPlugin, nextRequest)
      } else if (analysisProcess.sweepGeneration === root.analysisSweepGeneration) {
        root.startNextAnalysis()
      }
      if (root.activeTabKey === "flow") Qt.callLater(root.rebuildFlow)
    }
  }

  Timer {
    id: analysisTimeout
    interval: 30000
    repeat: false
    onTriggered: {
      if (root.analysisSettled) return
      root.analysisSettled = true
      root.analysisLoading = false
      root.analysisError = "Plugin analysis timed out after 30 seconds."
      if (analysisProcess.pluginId !== "") root.setAnalysisState(analysisProcess.pluginId, "unavailable")
      root.terminateBoundedProcess(analysisProcess)
    }
  }

  Timer {
    id: analysisKill
    interval: 3000
    repeat: false
    onTriggered: if (analysisProcess.running) analysisProcess.signal(9)
  }

  Process {
    id: ruleExplanationProcess
    property var killTimer: ruleExplanationKill
    property string ruleId: ""
    property string cacheKey: ""
    property string nextRuleId: ""
    property string nextCacheKey: ""
    function startFor(id, key) {
      if (running) {
        nextRuleId = id
        nextCacheKey = key
        root.terminateBoundedProcess(ruleExplanationProcess)
        return
      }
      ruleId = id
      cacheKey = key
      root.ruleExplanationStdout = ""
      root.ruleExplanationStderr = ""
      root.ruleExplanationSettled = false
      ruleExplanationKill.stop()
      ruleExplanationTimeout.restart()
      command = root.cliCommand(["rules", "explain", id, "--format", "json"])
      running = true
    }
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.ruleExplanationSettled) return
        root.ruleExplanationStdout = (root.ruleExplanationStdout + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (root.ruleExplanationStdout.length > root.v02OutputCharCap) {
          root.ruleExplanationSettled = true
          root.ruleExplanationLoading = false
          root.ruleExplanation = "Rule explanation exceeded the configured output cap."
          ruleExplanationTimeout.stop()
          root.terminateBoundedProcess(ruleExplanationProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.ruleExplanationSettled) return
        root.ruleExplanationStderr = (root.ruleExplanationStderr + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (root.ruleExplanationStderr.length > root.v02OutputCharCap) {
          root.ruleExplanationSettled = true
          root.ruleExplanationLoading = false
          root.ruleExplanation = "Rule explanation error output exceeded the configured output cap."
          ruleExplanationTimeout.stop()
          root.terminateBoundedProcess(ruleExplanationProcess)
        }
      }
    }
    onExited: function(exitCode) {
      root.stopBoundedProcessTimers(ruleExplanationProcess, ruleExplanationTimeout)
      if (!root.ruleExplanationSettled) {
        root.ruleExplanationSettled = true
        if (ruleExplanationProcess.cacheKey === root.ruleExplanationKey) {
          var stderrLine = String(root.ruleExplanationStderr || "").trim().split("\n")[0]
          var result = null
          if (exitCode === 0) {
            try {
              var report = JSON.parse(String(root.ruleExplanationStdout || "").trim())
              if (String(report.schema) === "omasafe.report.v1" && report.result && report.result.rule)
                result = report.result
            } catch (error) {
              result = null
            }
          }
          if (result) {
            // Store the whole result: the rule sheet's BASELINE V3 relations come from
            // result.external_equivalences, its text fields from the rules-list vm.
            root.ruleExplanationResult = result
            root.ruleExplanationError = ""
            var next = ({})
            for (var key in root.ruleExplanationCache) next[key] = root.ruleExplanationCache[key]
            next[ruleExplanationProcess.cacheKey] = result
            root.ruleExplanationCache = next
          } else {
            root.ruleExplanationResult = null
            root.ruleExplanationError =
              (stderrLine || (exitCode === 0 ? "unexpected rule report" : "exit status " + exitCode))
          }
          root.ruleExplanationLoading = false
        }
      }
      root.ruleExplanationStdout = ""
      root.ruleExplanationStderr = ""
      if (ruleExplanationProcess.nextRuleId !== "") {
        var nextRule = ruleExplanationProcess.nextRuleId
        var nextKey = ruleExplanationProcess.nextCacheKey
        ruleExplanationProcess.nextRuleId = ""
        ruleExplanationProcess.startFor(nextRule, nextKey)
      }
    }
  }

  Timer {
    id: ruleExplanationTimeout
    interval: 15000
    repeat: false
    onTriggered: {
      if (root.ruleExplanationSettled) return
      root.ruleExplanationSettled = true
      root.ruleExplanationLoading = false
      root.ruleExplanation = "Rule explanation timed out after 15 seconds."
      root.terminateBoundedProcess(ruleExplanationProcess)
    }
  }

  Timer {
    id: ruleExplanationKill
    interval: 3000
    repeat: false
    onTriggered: if (ruleExplanationProcess.running) ruleExplanationProcess.signal(9)
  }

  Process {
    id: enableProcess
    property var killTimer: enableKill
    property string pluginId: ""
    property string policy: "advisory"
    property string stdoutBuffer: ""
    property string stderrBuffer: ""
    property bool settled: false
    command: root.cliCommand([])
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (enableProcess.settled) return
        enableProcess.stdoutBuffer =
          (enableProcess.stdoutBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (enableProcess.stdoutBuffer.length > root.v02OutputCharCap) {
          enableProcess.settled = true
          root.enableError = "Enable output exceeded the configured output cap."
          enableTimeout.stop()
          root.terminateBoundedProcess(enableProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (enableProcess.settled) return
        enableProcess.stderrBuffer =
          (enableProcess.stderrBuffer + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (enableProcess.stderrBuffer.length > root.v02OutputCharCap) {
          enableProcess.settled = true
          root.enableError = "Enable error output exceeded the configured output cap."
          enableTimeout.stop()
          root.terminateBoundedProcess(enableProcess)
        }
      }
    }
    onExited: function(exitCode) {
      root.stopBoundedProcessTimers(enableProcess, enableTimeout)
      if (!enableProcess.settled) {
        enableProcess.settled = true
        var stderr = String(enableProcess.stderrBuffer || "").trim()
        var result = root.applyEnableResult(enableProcess.stdoutBuffer,
          enableProcess.pluginId)
        // Success requires the CLI's own `enabled: true`; a hardened block or a failed
        // postcondition returns `enabled: false` on exit 0 or 1 (main.rs:2345/2374/2449).
        if (result && result.enabled === true) {
          root.clearPendingAction()
          root.enableError = ""
          root.enableMessage = enableProcess.pluginId + " enabled (" +
            String(result.policy || enableProcess.policy) + ")."
          // Re-fetch inventory (enabled/active) and ENFORCEMENT; never an auto scan.
          root.inventoryReloadPending = root.inventoryReloadPending || inventoryProcess.running
          if (!inventoryProcess.running) {
            root.nextInventoryCatalogOnly = false
            inventoryProcess.running = true
          }
        } else {
          var decision = root.enforcementDecision
          var reasons = decision && decision.reason_codes && decision.reason_codes.length > 0
            ? decision.reason_codes.map(function(c) { return String(c).replace(/-/g, " ") }).slice(0, 16).join(", ")
            : ""
          root.enableMessage = ""
          root.enableError = (result && result.enabled === false)
            ? ("Enable refused (" + enableProcess.policy + "): " + (reasons || stderr || "no reason reported") + ".")
            : (stderr || "Enable was refused or failed with exit status " + exitCode + ".")
          if (result === null && root.enforcementDecision === null)
            root.enforcementError = "Enable decision is unavailable."
          root.clearPendingAction()
        }
      }
      root.enableStdout = enableProcess.stdoutBuffer
      root.enableStderr = enableProcess.stderrBuffer
      enableProcess.stdoutBuffer = ""
      enableProcess.stderrBuffer = ""
    }
  }

  Timer {
    id: enableTimeout
    interval: 60000
    repeat: false
    onTriggered: {
      if (enableProcess.settled) return
      enableProcess.settled = true
      root.enableError = "Enable timed out; the CLI may still be completing recovery."
      root.terminateBoundedProcess(enableProcess)
    }
  }

  Timer {
    id: enableKill
    interval: 3000
    repeat: false
    onTriggered: if (enableProcess.running) enableProcess.signal(9)
  }

  Process {
    id: reviewUpdateProcess
    property var killTimer: reviewUpdateKill
    property string pluginId: ""
    property string commit: ""
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.reviewUpdateSettled) return
        root.reviewUpdateStdout += String(chunk)
        if (root.reviewUpdateStdout.length > root.v02OutputCharCap) {
          root.reviewUpdateSettled = true
          root.reviewUpdateError = "Reviewed update output exceeded the configured output cap."
          root.clearPendingAction()
          reviewUpdateTimeout.stop()
          root.terminateBoundedProcess(reviewUpdateProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.reviewUpdateSettled) return
        root.reviewUpdateStderr += String(chunk)
        if (root.reviewUpdateStderr.length > root.v02OutputCharCap) {
          root.reviewUpdateSettled = true
          root.reviewUpdateError = "Reviewed update error output exceeded the configured output cap."
          root.clearPendingAction()
          reviewUpdateTimeout.stop()
          root.terminateBoundedProcess(reviewUpdateProcess)
        }
      }
    }
    onExited: function(exitCode) {
      root.stopBoundedProcessTimers(reviewUpdateProcess, reviewUpdateTimeout)
      if (root.reviewUpdateSettled) return
      root.reviewUpdateSettled = true
      var stderr = String(root.reviewUpdateStderr || "").trim()
      if (root.reviewUpdateTerminating || exitCode === 130) {
        root.reviewUpdateMessage = ""
        root.reviewUpdateError = stderr ||
          "Update interrupted; the plugin may be disabled. Follow the CLI recovery steps."
      } else if (exitCode === 0) {
        root.clearPendingAction()
        root.reviewUpdateError = ""
        // Key the line on the CLI's own words, never on exit 0 alone (02 §3.3): only
        // "Reviewed update complete" is a real update; "Already at pinned commit" is
        // an exit-0 no-op (main.rs:1201/2100). No automatic scan (T2.14).
        var out = String(root.reviewUpdateStdout || "")
        var c7 = String(reviewUpdateProcess.commit || "").slice(0, 7)
        if (out.indexOf("Reviewed update complete") >= 0)
          root.reviewUpdateMessage = reviewUpdateProcess.pluginId + " updated to " + c7 + " and baseline recorded."
        else if (out.indexOf("Already at pinned commit") >= 0)
          root.reviewUpdateMessage = "Already at the claimed commit; nothing was updated."
        else
          root.reviewUpdateMessage = "Review update finished; TRUST BASELINE and ENFORCEMENT re-fetched."
        root.inventoryReloadPending = root.inventoryReloadPending || inventoryProcess.running
        if (!inventoryProcess.running) {
          root.nextInventoryCatalogOnly = false
          inventoryProcess.running = true
        }
        // Re-fetch the selected plugin's status/enforcement so the trust word and
        // decision reflect the update, without wiping the analysis display.
        root.refreshSelectedAfterMutation()
      } else if (exitCode === 130) {
        root.reviewUpdateError = stderr || "Update interrupted. The plugin was left disabled; follow the CLI recovery steps."
      } else {
        root.reviewUpdateError = stderr || "Reviewed update was refused or failed."
      }
    }
  }

  Timer {
    id: reviewUpdateTimeout
    interval: 60000
    repeat: false
    onTriggered: {
      if (root.reviewUpdateSettled) return
      root.reviewUpdateTerminating = true
      root.reviewUpdateMessage = "Stopping reviewed update after timeout…"
      root.reviewUpdateSettled = true
      root.clearPendingAction()
      root.reviewUpdateError = "Reviewed update timed out; the plugin may be disabled. Follow the CLI recovery steps."
      if (reviewUpdateProcess.running) {
        root.terminateBoundedProcess(reviewUpdateProcess)
      }
    }
  }

  Timer {
    id: reviewUpdateKill
    interval: 3000
    repeat: false
    onTriggered: if (reviewUpdateProcess.running) reviewUpdateProcess.signal(9)
  }

  Process {
    id: trustProcess
    property var killTimer: trustKill
    // Pinned facts for the completion line, copied at launch so they survive a mid-run
    // clearPendingAction() that would blank root.authorized* / root.pendingAction (P1).
    property string action: ""
    property string mutatedPluginId: ""
    property string mutatedDigest: ""
    command: root.cliCommand([])
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.trustSettled) return
        root.trustOutput = (root.trustOutput + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (root.trustOutput.length > root.v02OutputCharCap) {
          root.trustSettled = true
          root.trustError = "Trust operation output exceeded the configured output cap."
          root.clearPendingAction()
          root.trustOperation = ""
          trustTimeout.stop()
          root.terminateBoundedProcess(trustProcess)
        }
      }
    }
    stderr: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.trustSettled) return
        root.trustError = (root.trustError + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (root.trustError.length > root.v02OutputCharCap) {
          root.trustSettled = true
          root.trustError = "Trust operation error output exceeded the configured output cap."
          root.clearPendingAction()
          root.trustOperation = ""
          trustTimeout.stop()
          root.terminateBoundedProcess(trustProcess)
        }
      }
    }
    onExited: function(exitCode) {
      root.stopBoundedProcessTimers(trustProcess, trustTimeout)
      if (root.trustSettled) return
      root.trustSettled = true
      if (exitCode === 0) {
        // Name the result from the CLI's own words and the pinned identity, before
        // clearPendingAction()/selectPlugin() drop the authorized facts (T0.8/GR3).
        var stdout = String(root.trustOutput || "")
        var mutatedId = String(trustProcess.mutatedPluginId || "")
        var shortDigest = String(trustProcess.mutatedDigest || "").slice(0, 12)
        var wasReplace = trustProcess.action === "replace"
        var message = ""
        if (stdout.indexOf("Trusted identity recorded") >= 0)
          message = (wasReplace ? "Baseline replaced for " : "Baseline recorded for ") +
            mutatedId + " at digest " + shortDigest + "."
        else if (stdout.indexOf("Review decision recorded") >= 0)
          message = "Baseline removed for " + mutatedId + "."
        root.clearPendingAction()
        root.panelError = ""
        root.mutationMessage = message
        // Re-fetch status/enforcement (trust word → checking… until it returns);
        // no view change, no cache wipe, no automatic scan (doc 03 §5.5, T2.14).
        root.refreshSelectedAfterMutation()
      } else {
        root.panelError = root.trustError || (root.trustOperation === "untrust"
          ? "Trust baseline could not be removed."
          : "Trust baseline could not be recorded.")
      }
      root.clearPendingAction()
      root.trustOperation = ""
    }
  }

  Timer {
    id: trustTimeout
    interval: 30000
    repeat: false
    onTriggered: {
      if (root.trustSettled) return
      root.trustSettled = true
      root.trustError = "Trust operation timed out after 30 seconds."
      root.clearPendingAction()
      root.trustOperation = ""
      root.terminateBoundedProcess(trustProcess)
    }
  }

  Timer {
    id: trustKill
    interval: 3000
    repeat: false
    onTriggered: if (trustProcess.running) trustProcess.signal(9)
  }
}
