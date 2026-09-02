import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import Quickshell.Io

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
  property bool scheduleConfirming: false
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
  property bool trustSettled: false
  property bool showPluginPicker: false
  property bool trustConfirming: false
  property bool untrustConfirming: false
  property string trustOperation: ""
  property bool reviewUpdateConfirming: false
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
  property bool enableConfirming: false
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
  property string analysisStdout: ""
  property string analysisStderr: ""
  property bool analysisSettled: false
  readonly property int v02OutputCharCap: 2 * 1024 * 1024
  property string expandedFindingKey: ""
  property string ruleExplanation: ""
  property string ruleExplanationKey: ""
  property bool ruleExplanationLoading: false
  property bool analysisDetailsExpanded: false
  property string ruleExplanationStdout: ""
  property string ruleExplanationStderr: ""
  property bool ruleExplanationSettled: false
  property var ruleExplanationCache: ({})
  property int selectionRequestId: 0
  property int analysisRequestId: 0

  readonly property var tabs: [
    { key: "overview", label: "Overview" },
    { key: "findings", label: "Findings" },
    { key: "plugins", label: "Plugins" },
    { key: "catalog", label: "Catalog" }
  ]
  property int activeIndex: 0
  readonly property string activeTabKey: root.tabs[root.activeIndex].key
  readonly property bool operationRunning: trustProcess.running || reviewUpdateProcess.running ||
    enableProcess.running || scheduleInstallProcess.running
  readonly property bool navigationLocked: root.operationRunning || root.trustConfirming ||
    root.untrustConfirming || root.reviewUpdateConfirming || root.enableConfirming ||
    root.scheduleConfirming

  onSelectedPluginIdChanged: {
    if (root.opened && root.activeTabKey === "findings") Qt.callLater(root.ensureAnalysis)
  }

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property color warningColor: hostWidget ? hostWidget.warningColor : "#e5a50a"
  readonly property var alerts: hostWidget ? hostWidget.alerts : []
  readonly property string statusLevel: hostWidget ? hostWidget.statusLevel : "unknown"

  readonly property bool cliVerified: root.hostWidget
    ? root.hostWidget.cliVerified === true : false

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
    return Color.muted
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

  function enforcementSummaryFor(id) {
    var entries = root.enforcementSummary && root.enforcementSummary.decisions || []
    for (var i = 0; i < entries.length; i++) {
      if (String(entries[i].plugin_id || "") === String(id || "")) return entries[i]
    }
    return null
  }

  function enforcementEnum(value, allowed) {
    var text = String(value || "")
    return allowed.indexOf(text) >= 0 ? text : "unsupported"
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
    var relation = String(value || "")
    return ["structural-equivalent", "partial-overlap", "not-covered"].indexOf(relation) >= 0
      ? relation : "unsupported"
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
    var status = String(value || "")
    return ["active", "expired"].indexOf(status) >= 0 ? status : "unsupported"
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
    Qt.callLater(function() {
      if (activeFlick) activeFlick.contentY = 0
    })
    if (root.opened && root.activeTabKey === "findings") root.ensureAnalysis()
    if (root.opened && root.activeTabKey === "findings") root.ensureCoverage()
  }

  function switchTabBy(delta) {
    if (root.navigationLocked) return
    root.setActive((root.activeIndex + delta + root.tabs.length) % root.tabs.length)
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

  function trustSelectedPlugin() {
    var plugin = root.selectedPlugin()
    if (!plugin || !root.canTrustSelectedPlugin()) return
    var args = ["plugins", "trust", plugin.id, "--yes", "--note", "trusted from OmaSafe panel"]
    if (plugin.head) args.push("--expected-head", plugin.head)
    if (plugin.tree) args.push("--expected-tree", plugin.tree)
    if (plugin.content_digest) args.push("--expected-digest", plugin.content_digest)
    root.trustError = ""
    root.trustOutput = ""
    root.trustSettled = false
    root.trustOperation = "trust"
    trustKill.stop()
    trustTimeout.restart()
    trustProcess.command = root.cliCommand(args)
    trustProcess.running = true
  }

  function untrustSelectedPlugin() {
    if (!root.selectedPlugin() || !root.canUntrustSelectedPlugin()) return
    root.trustError = ""
    root.trustOutput = ""
    root.trustSettled = false
    root.trustOperation = "untrust"
    trustKill.stop()
    trustTimeout.restart()
    trustProcess.command = root.cliCommand([
      "plugins", "review", root.selectedPluginId,
      "--action", "untrust",
      "--reason", "untrusted from OmaSafe panel",
      "--yes"
    ])
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
    if (root.reviewUpdateConfirming && id !== root.reviewUpdatePluginId) {
      root.reviewUpdateConfirming = false
      root.reviewUpdateError = "Reviewed update cancelled because the selected plugin changed."
    }
    if (root.enableConfirming && id !== root.enablePluginId) {
      root.enableConfirming = false
      root.enableError = "Enable cancelled because the selected plugin changed."
    }
    root.selectedPluginId = id || ""
    root.showPluginPicker = false
    root.trustConfirming = false
    root.untrustConfirming = false
    root.statusReport = null
    root.diffReport = null
    root.enforcementDecision = null
    root.enforcementError = ""
    root.enforcementLoading = false
    root.enforcementDetailsExpanded = false
    root.selectedError = ""
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
    if (alert) root.setActive(1)
  }

  function open() {
    root.panelError = ""
    root.controller.show()
    root.loadInventory()
    root.loadScheduleStatus()
    root.loadOverrides()
    if (root.activeTabKey === "findings") Qt.callLater(root.ensureAnalysis)
    if (root.activeTabKey === "findings") Qt.callLater(root.ensureCoverage)
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
    root.scheduleConfirming = true
  }

  function runScheduleInstall() {
    if (!root.scheduleConfirming || !root.cliVerified || root.operationRunning) return
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

  function loadOverrides() {
    if (!root.cliVerified || overrideProcess.running) return
    root.overrideLoading = true
    root.overrideError = ""
    overrideProcess.startRequest()
  }

  function refreshEnforcementStatus() {
    var plugin = root.selectedPlugin()
    if (!plugin || !root.cliVerified) return
    root.enforcementDecision = null
    root.enforcementError = ""
    root.enforcementLoading = true
    root.launchProcess(enforcementStatusProcess,
      root.cliCommand(["plugins", "enforcement-status", plugin.id, "--format", "json"]),
      root.selectionRequestId, plugin.id)
  }

  function close() {
    root.clearAnalysisCache()
    analysisProcess.nextPluginId = ""
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
    analysisProcess.startFor(plugin.id, root.analysisRequestId)
  }

  function analysisPolicyKeyFor(report) {
    return root.analysisPolicyIdentityKey(report)
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

  function findingKey(finding) {
    return String(finding.rule_id || "rule") + ":" + String(finding.relative_path || "") + ":" +
      String(finding.line || "")
  }

  function explainRule(ruleId) {
    var id = String(ruleId || "")
    if (id === "") return
    root.expandedFindingKey = id
    var cacheKey = (root.hostWidget ? root.hostWidget.cliVersion : "") + ":" + id
    if (root.ruleExplanationCache[cacheKey] !== undefined) {
      root.ruleExplanationKey = cacheKey
      root.ruleExplanation = root.ruleExplanationCache[cacheKey]
      root.ruleExplanationLoading = false
      return
    }
    root.ruleExplanationKey = cacheKey
    root.ruleExplanation = ""
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
    root.reviewUpdateConfirming = true
  }

  function beginEnable() {
    if (!root.enableEligible() || root.operationRunning) return
    root.enablePluginId = root.selectedPluginId
    root.enablePolicyChoice = "advisory"
    root.enableError = ""
    root.enableMessage = ""
    root.enableSettled = false
    root.enableConfirming = true
  }

  function applyEnableResult(output, pluginId) {
    try {
      var report = JSON.parse(output)
      if (String(report.schema || "") !== "omasafe.report.v1" ||
          !report.result || !report.result.decision)
        return false
      var decision = report.result.decision
      if (String(decision.schema || "") !== "omasafe.enforcement.v1") return false
      if (String(report.result.plugin_id || pluginId) !== pluginId) return false
      root.enforcementDecision = decision
      root.enforcementError = ""
      return true
    } catch (error) {
      return false
    }
  }

  function runEnable() {
    var target = root.pluginById(root.enablePluginId)
    var targetStillExact = target && root.selectedPluginId === root.enablePluginId &&
      root.enableEligible() && !enableProcess.running
    if (!root.enableConfirming || !targetStillExact) {
      if (root.enableConfirming && !targetStillExact)
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
    enableProcess.command = root.cliCommand([
      "plugins", "enable", root.enablePluginId,
      "--policy", root.enablePolicyChoice, "--format", "json"
    ])
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
    if (!root.reviewUpdateConfirming || root.reviewUpdateCommit === "" || !targetStillExact) {
      if (root.reviewUpdateConfirming && !targetStillExact)
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
    contentHeight: fittedContentHeight(tabShell.implicitHeight, Style.space(600))

    Flickable {
      id: panelFlick
      visible: false
      anchors.fill: parent
      contentWidth: width
      contentHeight: 0
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      Component {
        id: legacyContent

        Column {
        id: content
        width: panelFlick.width
        spacing: Style.space(12)

        Item {
          width: parent.width
          implicitHeight: summary.implicitHeight

          Row {
            id: summary
            width: parent.width
            spacing: Style.space(10)

            OmaSafeStatusIcon {
              id: summaryIcon
              anchors.verticalCenter: parent.verticalCenter
              level: root.statusLevel
              warningColor: root.warningColor
              criticalColor: root.bar ? root.bar.urgent : Color.urgent
              implicitWidth: Style.space(24)
              implicitHeight: Style.space(24)
              width: implicitWidth
              height: implicitHeight
            }

            Column {
              width: parent.width - summaryIcon.width - summary.spacing
              spacing: Style.space(2)

              Text {
                text: root.statusTitle()
                textFormat: Text.PlainText
                color: root.statusColor(root.statusLevel)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                width: parent.width
                text: root.statusMessage()
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          implicitHeight: summaryStats.implicitHeight + Style.space(14)
          radius: Style.cornerRadius
          color: Util.alpha(root.contentForeground, 0.05)
          border.width: 1
          border.color: Util.alpha(root.contentForeground, 0.20)

          Row {
            id: summaryStats
            anchors.centerIn: parent
            spacing: Style.space(18)

            Column {
              spacing: Style.space(2)
              Text {
                text: root.visiblePlugins().length
                textFormat: Text.PlainText
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                text: "INSTALLED"
                textFormat: Text.PlainText
                color: Util.alpha(root.contentForeground, 0.64)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
            }

            Column {
              spacing: Style.space(2)
              Text {
                text: root.checkingPluginStatuses ? "…" : root.trustedPluginCount()
                textFormat: Text.PlainText
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                text: "TRUSTED"
                textFormat: Text.PlainText
                color: Util.alpha(root.contentForeground, 0.64)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
            }

            Column {
              spacing: Style.space(2)
              Text {
                text: root.checkingPluginStatuses ? "…" : root.outstandingReviewCount()
                textFormat: Text.PlainText
                color: root.warningColor
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                text: "REVIEW"
                textFormat: Text.PlainText
                color: Util.alpha(root.contentForeground, 0.64)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
            }

            Column {
              spacing: Style.space(2)
              Text {
                text: root.checkingPluginStatuses ? "…" : root.untrustedPluginCount()
                textFormat: Text.PlainText
                color: root.statusColor("unknown")
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                text: "UNTRUSTED"
                textFormat: Text.PlainText
                color: Util.alpha(root.contentForeground, 0.64)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
            }
          }
        }

        Text {
          width: parent.width
          text: "Trusted means the current source exactly matches a recorded baseline."
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: Util.alpha(root.contentForeground, 0.58)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.inventoryReport !== null

          Text {
            text: "MARKETPLACE SNAPSHOT"
            textFormat: Text.PlainText
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }

          Rectangle {
            width: parent.width
            implicitHeight: snapshotDetails.implicitHeight + Style.space(14)
            radius: Style.cornerRadius
            color: Util.alpha(root.statusColor(root.snapshotIntegrityLevel()), 0.08)
            border.width: 1
            border.color: Util.alpha(root.statusColor(root.snapshotIntegrityLevel()), 0.42)

            Column {
              id: snapshotDetails
              anchors.fill: parent
              anchors.margins: Style.space(7)
              spacing: Style.space(3)

              Text {
                width: parent.width
                text: root.snapshotIntegrityLabel()
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.statusColor(root.snapshotIntegrityLevel())
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Text {
                width: parent.width
                text: root.inventoryReport
                  ? "Catalog commit: " + root.shortDigest(root.snapshotCommit()) +
                    "\nRetrieved: " + (root.inventoryReport.marketplace_retrieved_at || "unavailable") +
                    (root.inventoryReport.marketplace_stale ? " (stale)" : "")
                  : ""
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                text: "Snapshot verification binds cached catalog bytes to the official pinned commit; it does not verify a Git commit signature."
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: Util.alpha(root.contentForeground, 0.62)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Button {
                width: parent.width
                text: marketplaceRefreshProcess.running ? "Updating catalog…" : "Update catalog"
                tooltipText: "Resolve the official marketplace main branch to an exact commit, then fetch and verify that pinned snapshot."
                enabled: root.cliVerified && !marketplaceRefreshProcess.running
                bordered: true
                focusable: true
                foreground: root.contentForeground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.updateMarketplace()
              }

              Text {
                width: parent.width
                visible: root.marketplaceRefreshMessage !== "" ||
                  root.marketplaceRefreshError !== ""
                text: root.marketplaceRefreshError || root.marketplaceRefreshMessage
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.marketplaceRefreshError !== ""
                  ? root.warningColor : root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }
            }
          }
        }

        Text {
          visible: root.panelError !== ""
          width: parent.width
          text: root.panelError
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: root.statusColor("critical")
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.alerts.length > 0

          Text {
            text: "FINDINGS"
            textFormat: Text.PlainText
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }

          Repeater {
            model: root.alerts

            Rectangle {
              required property var modelData
              readonly property color severityColor: root.statusColor(root.alertLevel(modelData))
              readonly property bool selected: root.selectedPluginId === modelData.plugin_id
              width: parent.width
              implicitHeight: finding.implicitHeight + Style.space(14)
              radius: Style.cornerRadius
              clip: true
              // Findings are the actionable items — always tinted by severity so
              // they stand out from the passive detail cards, brighter when selected.
              color: Util.alpha(severityColor, selected ? 0.18 : 0.08)
              border.width: 1
              border.color: selected ? severityColor : Util.alpha(severityColor, 0.35)

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Style.space(3)
                color: parent.severityColor
              }

              Column {
                id: finding
                anchors.fill: parent
                anchors.margins: Style.space(7)
                anchors.leftMargin: Style.space(11)
                spacing: Style.space(3)

                Row {
                  spacing: Style.space(6)

                  Rectangle {
                    width: Style.space(14)
                    height: width
                    radius: width / 2
                    color: root.statusColor(root.alertLevel(modelData))
                    Text {
                      anchors.centerIn: parent
                      text: "!"
                      textFormat: Text.PlainText
                      color: Color.background
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                  }

                  Text {
                    text: root.alertLabel(modelData)
                    textFormat: Text.PlainText
                    color: root.statusColor(root.alertLevel(modelData))
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }
                }

                Text {
                  width: parent.width
                  text: modelData.plugin_id + " · " + modelData.message
                  textFormat: Text.PlainText
                  wrapMode: Text.WordWrap
                  color: root.contentForeground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectPlugin(modelData.plugin_id, modelData)
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.inventoryReport !== null

          Text {
            text: "SELECTED PLUGIN"
            textFormat: Text.PlainText
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }

          Rectangle {
            width: parent.width
            implicitHeight: details.implicitHeight + Style.space(14)
            radius: Style.cornerRadius
            color: Util.alpha(root.contentForeground, 0.05)
            border.width: 1
            border.color: Util.alpha(root.contentForeground, 0.20)

            Column {
              id: details
              anchors.fill: parent
              anchors.margins: Style.space(7)
              spacing: Style.space(5)

              Text {
                width: parent.width
                text: root.selectedPluginId || "No installed plugin selected"
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.body
                font.bold: true
              }

              Text {
                width: parent.width
                visible: root.pluginById(root.selectedPluginId) !== null
                text: {
                  var plugin = root.pluginById(root.selectedPluginId)
                  return plugin ? "Classification: " + plugin.classification +
                    "\nDigest: " + root.shortDigest(plugin.content_digest) +
                    "\nCoverage: " + ((plugin.limitations || []).join(", ") || "complete") : ""
                }
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                visible: root.statusReport !== null
                text: root.statusReport ? "Baseline: " + (root.statusReport.trusted
                  ? root.shortDigest(root.statusReport.trusted.content_digest) : "not established") +
                  "\nCurrent state: " + root.statusReport.state : ""
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                visible: root.marketplaceByPlugin(root.selectedPluginId) !== null
                text: {
                  var marketplace = root.marketplaceByPlugin(root.selectedPluginId)
                  var claim = root.marketplaceClaim(marketplace)
                  return marketplace ? "Marketplace listing: " + marketplace.status +
                    "\nListing verification: " + root.listingVerificationLabel(marketplace) +
                    "\nCommit comparison: " + root.installedCommitLabel(marketplace) +
                    "\nValidated commit: " + root.shortDigest(claim && claim.listing_validated_commit) +
                    "\nUpstream commit: " + root.shortDigest(claim && claim.upstream_observed_commit) +
                    "\nUpstream state: " + root.upstreamCommitLabel(marketplace) : ""
                }
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: {
                  var marketplace = root.marketplaceByPlugin(root.selectedPluginId)
                  if (root.installedCommitLevel(marketplace) === "warning" ||
                      root.listingVerificationLevel(marketplace) === "warning" ||
                      root.upstreamCommitLevel(marketplace) === "warning")
                    return root.warningColor
                  return root.contentForeground
                }
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                visible: root.marketplaceByPlugin(root.selectedPluginId) !== null
                text: "Marketplace verification is a claim from this catalog snapshot, not an OmaSafe safety verdict."
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: Util.alpha(root.contentForeground, 0.62)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                visible: root.diffReport !== null
                text: root.diffReport ? "Changed files: " +
                  ((root.diffReport.changed_files || []).slice(0, 5).join(", ") || "none") +
                  ((root.diffReport.changed_files || []).length > 5
                    ? " +" + ((root.diffReport.changed_files || []).length - 5) + " more" : "") : ""
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                visible: root.selectedError !== ""
                text: root.selectedError
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: root.warningColor
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Rectangle {
                width: parent.width
                visible: root.canTrustSelectedPlugin() || root.canUntrustSelectedPlugin()
                implicitHeight: trustControls.implicitHeight + Style.space(18)
                radius: Style.cornerRadius
                // Distinct inset panel so the trust actions read as a control
                // surface, separate from the read-only identity above.
                color: Util.alpha(Color.accent, 0.06)
                border.width: 1
                border.color: Util.alpha(Color.accent, 0.30)

                Column {
                  id: trustControls
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: Style.space(9)
                  spacing: Style.space(7)

                  Text {
                    text: "TRUST CONTROLS"
                    textFormat: Text.PlainText
                    color: Color.accent
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    font.letterSpacing: 1
                  }

                  Row {
                    width: parent.width
                    spacing: Style.space(8)

                    Button {
                      visible: root.canTrustSelectedPlugin()
                      width: root.canTrustSelectedPlugin() && root.canUntrustSelectedPlugin()
                        ? (parent.width - parent.spacing) / 2 : parent.width
                      text: trustProcess.running && root.trustOperation === "trust"
                        ? "Recording…"
                        : (root.statusReport && root.statusReport.trusted
                          ? "Replace baseline" : "Trust current source")
                      tooltipText: "Record this exact source identity as the plugin's trust baseline."
                      enabled: !trustProcess.running
                      focusable: true
                      background: Color.accent
                      foreground: Color.background
                      accent: Color.accent
                      fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                      onClicked: {
                        root.trustError = ""
                        root.untrustConfirming = false
                        root.trustConfirming = true
                      }
                    }

                    Button {
                      visible: root.canUntrustSelectedPlugin()
                      width: root.canTrustSelectedPlugin()
                        ? (parent.width - parent.spacing) / 2 : parent.width
                      text: trustProcess.running && root.trustOperation === "untrust"
                        ? "Removing…" : "Untrust"
                      tooltipText: "Remove this plugin's active trust baseline."
                      enabled: !trustProcess.running
                      bordered: true
                      focusable: true
                      background: Util.alpha(root.warningColor, 0.14)
                      foreground: root.warningColor
                      accent: root.warningColor
                      fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                      onClicked: {
                        root.trustError = ""
                        root.trustConfirming = false
                        root.untrustConfirming = true
                      }
                    }
                  }
                }
              }

              Button {
                text: root.showPluginPicker ? "Hide plugin list" : "Select another plugin"
                tooltipText: "Choose another installed, non-backup plugin."
                onClicked: root.showPluginPicker = !root.showPluginPicker
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.showPluginPicker

          Text {
            text: "INSTALLED PLUGINS"
            textFormat: Text.PlainText
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }

          Repeater {
            model: root.visiblePlugins()

            Rectangle {
              required property var modelData
              width: parent.width
              implicitHeight: pluginRow.implicitHeight + Style.space(14)
              radius: Style.cornerRadius
              color: root.selectedPluginId === modelData.id
                ? Util.alpha(root.statusColor(root.pluginStatusLevel(modelData)), 0.14) : "transparent"
              border.width: 1
              border.color: root.selectedPluginId === modelData.id
                ? root.statusColor(root.pluginStatusLevel(modelData)) : Util.alpha(root.contentForeground, 0.20)

              Row {
                id: pluginRow
                anchors.fill: parent
                anchors.margins: Style.space(7)
                spacing: Style.space(7)

                OmaSafeStatusIcon {
                  anchors.verticalCenter: parent.verticalCenter
                  level: root.pluginStatusLevel(modelData)
                  warningColor: root.warningColor
                  criticalColor: root.bar ? root.bar.urgent : Color.urgent
                }

                Column {
                  width: parent.width - Style.space(30)
                  spacing: Style.space(1)

                  Text {
                    width: parent.width
                    text: modelData.id
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.contentForeground
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    width: parent.width
                    text: root.pluginStatusLabel(modelData)
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Util.alpha(root.contentForeground, 0.68)
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectPlugin(modelData.id, null)
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          visible: root.trustConfirming
          implicitHeight: trustConfirmation.implicitHeight + Style.space(14)
          radius: Style.cornerRadius
          color: Util.alpha(root.warningColor, 0.12)
          border.width: 1
          border.color: root.warningColor

          Column {
            id: trustConfirmation
            anchors.fill: parent
            anchors.margins: Style.space(7)
            spacing: Style.space(8)

            Text {
              text: root.statusReport && root.statusReport.trusted
                ? "REPLACE TRUST BASELINE?" : "TRUST CURRENT IDENTITY?"
              textFormat: Text.PlainText
              color: root.warningColor
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
            }

            Text {
              width: parent.width
              text: "This records the exact current source identity for " + root.selectedPluginId + "."
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              color: root.contentForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              width: parent.width
              text: {
                var plugin = root.selectedPlugin()
                return plugin ? "Commit: " + (plugin.head || "unavailable") +
                  "\nTree: " + (plugin.tree || "unavailable") +
                  "\nDigest: " + (plugin.content_digest || "unavailable") : ""
              }
              textFormat: Text.PlainText
              wrapMode: Text.WrapAnywhere
              color: Util.alpha(root.contentForeground, 0.78)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              width: parent.width
              text: "Trusting this identity does not establish that the plugin is safe."
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              color: root.warningColor
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }

            Row {
              spacing: Style.space(8)

              Button {
                text: "Cancel"
                enabled: !trustProcess.running
                bordered: true
                focusable: true
                foreground: root.contentForeground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.trustConfirming = false
              }

              Button {
                text: trustProcess.running ? "Recording…" : "Trust this identity"
                enabled: !trustProcess.running
                focusable: true
                background: Color.accent
                foreground: Color.background
                accent: Color.accent
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.trustSelectedPlugin()
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          visible: root.untrustConfirming
          implicitHeight: untrustConfirmation.implicitHeight + Style.space(14)
          radius: Style.cornerRadius
          color: Util.alpha(root.warningColor, 0.14)
          border.width: 1
          border.color: root.warningColor

          Column {
            id: untrustConfirmation
            anchors.fill: parent
            anchors.margins: Style.space(9)
            spacing: Style.space(8)

            Text {
              text: "REMOVE TRUST BASELINE?"
              textFormat: Text.PlainText
              color: root.warningColor
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
            }

            Text {
              width: parent.width
              text: "OmaSafe will stop treating " + root.selectedPluginId +
                " as trusted. Its previous trust record stays in history, but the plugin will need a new explicit trust decision."
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              color: root.contentForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }

            Row {
              spacing: Style.space(8)

              Button {
                text: "Keep baseline"
                enabled: !trustProcess.running
                bordered: true
                focusable: true
                foreground: root.contentForeground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.untrustConfirming = false
              }

              Button {
                text: trustProcess.running && root.trustOperation === "untrust"
                  ? "Removing…" : "Untrust plugin"
                enabled: !trustProcess.running
                focusable: true
                background: root.warningColor
                foreground: Color.background
                accent: root.warningColor
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: root.untrustSelectedPlugin()
              }
            }
          }
        }

        Text {
          width: parent.width
          visible: root.inventoryReport && root.inventoryReport.non_builtin_bar_replaces_bar
          text: "A third-party full-bar plugin replaces the OmaSafe bar widget. CLI and desktop notifications remain available."
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: root.warningColor
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Button {
          text: root.statusLevel === "checking" ? "Scanning…" : "Run scan"
          // Disabled until a compatible CLI is resolved: a missing or
          // version-incompatible binary cannot produce a trustworthy scan.
          enabled: root.hostWidget && root.statusLevel !== "checking" &&
            root.hostWidget.cliPath !== "" && root.hostWidget.cliCompatible
          focusable: true
          background: Color.accent
          foreground: Color.background
          accent: Color.accent
          width: parent.width
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: if (root.hostWidget) root.hostWidget.runScan()
        }

        Button {
          text: root.showCompliantPlugins ? "Hide baselined plugins" : "Show baselined plugins"
          tooltipText: "Show installed plugins whose trusted source identity exactly matches the current source."
          bordered: true
          focusable: true
          width: parent.width
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: {
            root.showCompliantPlugins = !root.showCompliantPlugins
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.showCompliantPlugins

          Text {
            text: "BASELINED & UNCHANGED"
            textFormat: Text.PlainText
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }

          Text {
            width: parent.width
            text: root.checkingPluginStatuses
              ? "Checking installed plugin baselines…"
              : (root.baselinedUnchangedPlugins().length > 0
                ? "These plugins match a recorded trust baseline with complete coverage."
                : "No installed plugins currently meet this condition.")
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: Util.alpha(root.contentForeground, 0.72)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }

          Repeater {
            model: root.baselinedUnchangedPlugins()

            Rectangle {
              required property var modelData
              width: parent.width
              implicitHeight: Style.space(28)
              radius: Style.cornerRadius
              color: Util.alpha(root.contentForeground, 0.05)
              border.width: 1
              border.color: Util.alpha(root.contentForeground, 0.20)

              Row {
                anchors.fill: parent
                anchors.margins: Style.space(7)
                spacing: Style.space(6)

                OmaSafeStatusIcon {
                  anchors.verticalCenter: parent.verticalCenter
                  level: "normal"
                  warningColor: root.warningColor
                  criticalColor: root.bar ? root.bar.urgent : Color.urgent
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - Style.space(28)
                  text: modelData.id
                  textFormat: Text.PlainText
                  elide: Text.ElideRight
                  color: root.contentForeground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }

        Text {
          width: parent.width
          text: "OmaSafe reports changes and coverage limits. It does not declare plugins safe."
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: Util.alpha(root.contentForeground, 0.64)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  PanelKeyCatcher {
    id: keyCatcher
    anchors.fill: parent

    onMoveRequested: function(dx, dy) {
      if (dx !== 0) root.switchTabBy(dx > 0 ? 1 : -1)
    }
    onCloseRequested: root.close()
    onTabRequested: function(direction) {
      if (root.bar && typeof root.bar.switchPanelFrom === "function")
        root.bar.switchPanelFrom(root.hostWidget || root, direction)
    }
    onTextKey: function(t) {
      if (t === "1") root.setActive(0)
      else if (t === "2") root.setActive(1)
      else if (t === "3") root.setActive(2)
      else if (t === "4") root.setActive(3)
      else if (t === "r" || t === "R") {
        if (root.hostWidget) root.hostWidget.runScan()
      }
    }

    Column {
      id: tabShell
      width: parent.width
      spacing: Style.space(8)

      Row {
        width: parent.width
        spacing: Style.space(3)

        Repeater {
          model: root.tabs

          Item {
            required property var modelData
            required property int index
            width: (parent.width - scanHeaderButton.width - Style.space(12)) / 4
            height: Style.space(28)

            Text {
              anchors.centerIn: parent
              width: parent.width
              text: modelData.label + (modelData.key === "findings"
                ? " (" + root.outstandingReviewCount() + ")" : "")
              textFormat: Text.PlainText
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
              color: index === root.activeIndex ? root.contentForeground :
                Util.alpha(root.contentForeground, 0.58)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: index === root.activeIndex
            }

            Rectangle {
              anchors.bottom: parent.bottom
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width - Style.space(12)
              height: Style.spacing.hairline
              color: root.contentForeground
              visible: index === root.activeIndex
            }

            MouseArea {
              anchors.fill: parent
              enabled: !root.navigationLocked
              cursorShape: Qt.PointingHandCursor
              onClicked: root.setActive(index)
            }
          }
        }

        Button {
          id: scanHeaderButton
          width: Style.space(64)
          text: root.statusLevel === "checking" ? "Scan…" : "Scan"
          tooltipText: "Run scan (R)"
          enabled: root.hostWidget && root.hostWidget.cliVerified &&
            root.statusLevel !== "checking"
          focusable: true
          background: Color.accent
          foreground: Color.background
          accent: Color.accent
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: if (root.hostWidget) root.hostWidget.runScan()
        }
      }

      Item {
        width: parent.width
        height: statusIdentity.implicitHeight

        Row {
          id: statusIdentity
          width: parent.width
          spacing: Style.space(8)

          OmaSafeStatusIcon {
            anchors.verticalCenter: parent.verticalCenter
            level: root.statusLevel
            count: root.outstandingReviewCount()
            warningColor: root.warningColor
            criticalColor: root.bar ? root.bar.urgent : Color.urgent
          }

          Column {
            width: parent.width - Style.space(24)
            spacing: Style.space(2)

            Text {
              text: root.statusTitle()
              color: root.statusColor(root.statusLevel)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Text {
              width: parent.width
              text: root.statusMessage()
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              color: root.contentForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }
      }

      Flickable {
        id: activeFlick
        width: parent.width
        height: Math.min(Style.space(480), Math.max(Style.space(120), activeContent.implicitHeight))
        contentWidth: width
        contentHeight: activeContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Loader {
          id: activeLoader
          width: parent.width
          sourceComponent: root.activeTabKey === "overview" ? overviewTabComponent
            : (root.activeTabKey === "findings" ? findingsTabComponent
              : (root.activeTabKey === "plugins" ? pluginsTabComponent : catalogTabComponent))
        }

        Item {
          id: activeContent
          width: parent.width
          implicitHeight: activeLoader.item ? activeLoader.item.implicitHeight : 0
        }
      }
    }

    // Confirmation stays outside the Loader. Tab switching is disabled while an
    // operation is running, and the target identity is held in root properties.
    Rectangle {
      anchors.fill: parent
      visible: root.trustConfirming || root.untrustConfirming || root.reviewUpdateConfirming ||
        root.enableConfirming || root.scheduleConfirming
      color: Util.alpha(Color.background, 0.94)
      border.width: 1
      border.color: root.warningColor
      z: 20

      Column {
        anchors.centerIn: parent
        width: parent.width - Style.space(28)
        spacing: Style.space(8)

        Text {
          width: parent.width
          text: root.scheduleConfirming ? "INSTALL SCHEDULE?" :
            (root.reviewUpdateConfirming ? "REVIEW UPDATE?" :
            (root.enableConfirming ? "ENABLE PLUGIN?" :
            (root.trustConfirming
              ? (root.statusReport && root.statusReport.trusted ? "REPLACE TRUST BASELINE?" : "TRUST CURRENT IDENTITY?")
              : "REMOVE TRUST BASELINE?")))
          color: root.warningColor
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Text {
          width: parent.width
          text: root.scheduleConfirming
            ? "Install or replace the CLI-owned daily scan timer with " + root.scheduleInstallLabel() +
              " policy. The timer remains report-only; hardened policy adds analysis to the scan."
            : (root.reviewUpdateConfirming
              ? "Update " + root.selectedPluginId + " at the verified commit below and trust the result.\nPolicy: " + root.reviewUpdatePolicyChoice
              : (root.enableConfirming
                ? "Enable " + root.selectedPluginId + " through the CLI-owned " + root.enablePolicyChoice +
                  " gate. Hardened policy may refuse the transition."
              : (root.trustConfirming
                ? "Record the exact current source identity for " + root.selectedPluginId + "."
                : "Remove the active trust baseline for " + root.selectedPluginId + ".")))
          textFormat: Text.PlainText
          wrapMode: Text.WrapAnywhere
          color: root.contentForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.trustConfirming || root.untrustConfirming || root.reviewUpdateConfirming ||
            root.enableConfirming
          width: parent.width
          text: {
            var plugin = root.selectedPlugin()
            if ((root.trustConfirming || root.reviewUpdateConfirming || root.enableConfirming) && plugin) {
              if (root.reviewUpdateConfirming)
                return "Expected commit: " + root.reviewUpdateCommit +
                  "\nCurrent digest: " + (plugin.content_digest || "unavailable")
              return "Commit: " + (plugin.head || "unavailable") +
                "\nTree: " + (plugin.tree || "unavailable") +
                "\nDigest: " + (plugin.content_digest || "unavailable")
            }
            return root.statusReport && root.statusReport.trusted
              ? "Baseline digest: " + (root.statusReport.trusted.content_digest || "unavailable")
              : "Baseline identity unavailable"
          }
          textFormat: Text.PlainText
          wrapMode: Text.WrapAnywhere
          color: Util.alpha(root.contentForeground, 0.78)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          width: parent.width
          visible: root.reviewUpdateError !== "" || root.enableError !== "" || root.trustError !== "" ||
            root.scheduleInstallError !== ""
          text: root.reviewUpdateError || root.enableError || root.trustError || root.scheduleInstallError
          textFormat: Text.PlainText
          wrapMode: Text.WrapAnywhere
          color: root.warningColor
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Row {
          visible: root.reviewUpdateConfirming || root.enableConfirming
          spacing: Style.space(6)

          Button {
            text: (root.reviewUpdateConfirming ? root.reviewUpdatePolicyChoice : root.enablePolicyChoice) === "advisory"
              ? "✓ Advisory" : "Advisory"
            enabled: !root.operationRunning
            bordered: true
            focusable: true
            foreground: root.contentForeground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: {
              if (root.reviewUpdateConfirming) root.reviewUpdatePolicyChoice = "advisory"
              else root.enablePolicyChoice = "advisory"
            }
          }

          Button {
            text: (root.reviewUpdateConfirming ? root.reviewUpdatePolicyChoice : root.enablePolicyChoice) === "hardened"
              ? "✓ Hardened" : "Hardened"
            enabled: !root.operationRunning
            bordered: true
            focusable: true
            foreground: root.warningColor
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: {
              if (root.reviewUpdateConfirming) root.reviewUpdatePolicyChoice = "hardened"
              else root.enablePolicyChoice = "hardened"
            }
          }
        }

        Row {
          spacing: Style.space(8)

          Button {
            text: "Cancel"
            enabled: !root.operationRunning
            bordered: true
            focusable: true
            foreground: root.contentForeground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: {
              root.trustConfirming = false
              root.untrustConfirming = false
              root.reviewUpdateConfirming = false
              root.enableConfirming = false
              root.scheduleConfirming = false
            }
          }

          Button {
            text: root.operationRunning ? "Working…" :
              (root.scheduleConfirming ? "Install schedule" :
                (root.reviewUpdateConfirming ? "Review update" :
                  (root.enableConfirming ? "Enable plugin" :
                    (root.trustConfirming ? "Trust identity" : "Untrust plugin"))))
            enabled: !root.operationRunning
            focusable: true
            background: root.warningColor
            foreground: Color.background
            accent: root.warningColor
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: {
              if (root.scheduleConfirming) root.runScheduleInstall()
              else if (root.reviewUpdateConfirming) root.runReviewUpdate()
              else if (root.enableConfirming) root.runEnable()
              else if (root.trustConfirming) root.trustSelectedPlugin()
              else root.untrustSelectedPlugin()
            }
          }
        }
      }
    }
  }
  }

  Component {
    id: overviewTabComponent

    Column {
      width: activeFlick.width
      spacing: Style.space(9)

      Rectangle {
        width: parent.width
        implicitHeight: overviewStats.implicitHeight + Style.space(14)
        radius: Style.cornerRadius
        color: Util.alpha(root.contentForeground, 0.05)
        border.width: 1
        border.color: Util.alpha(root.contentForeground, 0.20)

        Row {
          id: overviewStats
          anchors.centerIn: parent
          spacing: Style.space(15)
          Repeater {
            model: [
              { value: root.visiblePlugins().length, label: "INSTALLED", color: root.contentForeground },
              { value: root.checkingPluginStatuses ? "…" : root.trustedPluginCount(), label: "TRUSTED", color: root.contentForeground },
              { value: root.outstandingReviewCount(), label: "REVIEW", color: root.warningColor },
              { value: root.checkingPluginStatuses ? "…" : root.untrustedPluginCount(), label: "UNTRUSTED", color: root.statusColor("unknown") }
            ]
            delegate: Column {
              required property var modelData
              spacing: Style.space(2)
              Text {
                text: modelData.value
                color: modelData.color
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                text: modelData.label
                color: Util.alpha(root.contentForeground, 0.64)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
              }
            }
          }
        }
      }

      Text {
        visible: root.inventoryReport === null
        width: parent.width
        text: root.cliVerified ? "Loading installed plugin state…" :
          "Inventory is unavailable until a compatible omasafe-cli is verified."
        color: root.contentForeground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Text {
        visible: root.panelError !== ""
        width: parent.width
        text: root.panelError
        textFormat: Text.PlainText
        wrapMode: Text.WrapAnywhere
        color: root.statusColor("critical")
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        visible: root.inventoryReport && root.inventoryReport.non_builtin_bar_replaces_bar
        width: parent.width
        text: "A third-party full-bar plugin replaces the OmaSafe bar widget. CLI and desktop notifications remain available."
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        color: root.warningColor
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Rectangle {
        width: parent.width
        implicitHeight: protectionStatus.implicitHeight + Style.space(14)
        radius: Style.cornerRadius
        color: Util.alpha(root.contentForeground, 0.05)
        border.width: 1
        border.color: Util.alpha(root.contentForeground, 0.20)

        Column {
          id: protectionStatus
          anchors.fill: parent
          anchors.margins: Style.space(7)
          spacing: Style.space(3)

          Text {
            text: "PROTECTION STATUS"
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }
          Text {
            width: parent.width
            text: {
              var summary = root.enforcementSummaryFor(root.selectedPluginId)
              return "Last scan: " + root.lastScanAt() +
                "\nCLI: " + (root.cliVerified ? root.hostWidget.cliVersion : "unavailable") +
                "\nAnalysis: " + root.analysisFreshnessLabel() +
                "\nScheduled scan: " + root.schedulePolicyLabel() +
                "\nSchedule unit: " + root.shortDigest(root.scheduleReport && root.scheduleReport.unit_identity) +
                "\nLast scheduled execution: " + root.scheduleExecutionLabel() +
                "\nHardened gate: " + root.protectionGateLabel() +
                "\nLast decision: " + root.enforcementOutcomeLabel(summary)
            }
            color: root.cliVerified ? root.contentForeground : root.warningColor
            wrapMode: Text.WrapAnywhere
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            visible: root.enforcementSummary && root.enforcementSummary.available === false
            width: parent.width
            text: root.enforcementSummary && root.enforcementSummary.error
              ? String(root.enforcementSummary.error) : "Last enforcement decisions unavailable."
            color: root.warningColor
            wrapMode: Text.WrapAnywhere
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            width: parent.width
            text: "Scheduled scans report findings only; hardened policy adds analysis and does not retroactively disable an already-running plugin."
            color: Util.alpha(root.contentForeground, 0.64)
            wrapMode: Text.WordWrap
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Row {
            spacing: Style.space(6)
            Button {
              text: root.scheduleReport && root.scheduleReport.installed === true &&
                root.schedulePolicyLabel() === "advisory" ? "Reinstall advisory schedule" :
                "Install advisory schedule"
              enabled: root.cliVerified && !root.operationRunning && !root.scheduleLoading
              bordered: true
              focusable: true
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              onClicked: root.beginScheduleInstall("advisory")
            }
            Button {
              text: root.scheduleReport && root.scheduleReport.installed === true &&
                root.schedulePolicyLabel() === "hardened" ? "Reinstall hardened schedule" :
                "Install hardened schedule"
              enabled: root.cliVerified && !root.operationRunning && !root.scheduleLoading
              bordered: true
              focusable: true
              foreground: root.warningColor
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              onClicked: root.beginScheduleInstall("hardened")
            }
          }
          Text {
            visible: root.scheduleInstallMessage !== "" || root.scheduleInstallError !== ""
            width: parent.width
            text: root.scheduleInstallError || root.scheduleInstallMessage
            color: root.scheduleInstallError !== "" ? root.warningColor : root.contentForeground
            wrapMode: Text.WrapAnywhere
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }

      Text {
        width: parent.width
        text: "OmaSafe reports changes and coverage limits. It does not declare plugins safe."
        color: Util.alpha(root.contentForeground, 0.64)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }

  Component {
    id: findingsTabComponent

    Column {
      width: activeFlick.width
      spacing: Style.space(8)

      Text {
        visible: root.alerts.length === 0
        width: parent.width
        text: !root.cliVerified ? "Findings are unavailable until a compatible omasafe-cli is verified." :
          (root.statusLevel === "checking" ? "Waiting for scan results…" :
            "No outstanding scan alerts. Analysis findings are shown for the selected plugin.")
        color: root.contentForeground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Text {
        visible: root.hostWidget && root.hostWidget.scanResultsStale && root.alerts.length > 0
        width: parent.width
        text: "The displayed alerts are from the last successful scan and are stale until a new scan completes."
        color: root.warningColor
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Repeater {
        model: root.alerts
        delegate: Rectangle {
          required property var modelData
          width: parent.width
          implicitHeight: alertCard.implicitHeight + Style.space(14)
          radius: Style.cornerRadius
          color: Util.alpha(root.statusColor(root.alertLevel(modelData)),
            root.selectedPluginId === modelData.plugin_id ? 0.18 : 0.08)
          border.width: 1
          border.color: root.selectedPluginId === modelData.plugin_id
            ? root.statusColor(root.alertLevel(modelData)) : Util.alpha(root.contentForeground, 0.20)

          Column {
            id: alertCard
            anchors.fill: parent
            anchors.margins: Style.space(7)
            spacing: Style.space(3)
            Text {
              text: root.alertLabel(modelData) + " · " + String(modelData.severity || "warning").toUpperCase()
              color: root.statusColor(root.alertLevel(modelData))
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              width: parent.width
              text: (modelData.plugin_id || "System") + (modelData.message ? " · " + modelData.message : "")
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              color: root.contentForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
          MouseArea {
            anchors.fill: parent
            enabled: !root.navigationLocked
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (modelData.plugin_id) root.selectPlugin(modelData.plugin_id, modelData)
            }
          }
        }
      }

      Text {
        visible: root.selectedPlugin() === null
        width: parent.width
        text: "Select an installed plugin from Plugins, or select a plugin alert above."
        color: Util.alpha(root.contentForeground, 0.70)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Column {
        visible: root.selectedPlugin() !== null
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "ANALYSIS · " + root.selectedPluginId
          color: root.contentForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Text {
          visible: root.analysisLoading
          text: "Running lexical and structural analysis…"
          color: Util.alpha(root.contentForeground, 0.70)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.analysisError !== ""
          width: parent.width
          text: root.analysisError
          color: root.warningColor
          wrapMode: Text.WrapAnywhere
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.analysisReport !== null
          width: parent.width
          text: root.analysisCoverageLabel()
          color: root.statusColor(root.analysisCoverageLevel())
          wrapMode: Text.WrapAnywhere
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Text {
          visible: root.analysisReport && root.analysisReport.parser === null
          width: parent.width
          text: "Lexical mode: parser support is unavailable for this build; findings may have reduced structural coverage."
          color: root.warningColor
          wrapMode: Text.WordWrap
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.analysisReport && (root.analysisReport.coverage_limitations || []).length > 0
          width: parent.width
          text: root.analysisReport ? "Coverage limitations:\n• " +
            (root.analysisReport.coverage_limitations || []).join("\n• ") : ""
          color: root.warningColor
          wrapMode: Text.WordWrap
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.analysisReport && (root.analysisReport.capabilities || []).length > 0
          width: parent.width
          text: root.analysisReport ? "Observed capabilities: " +
            (root.analysisReport.capabilities || []).map(function(item) {
              return typeof item === "string" ? item : (item.capability || JSON.stringify(item))
            }).join(", ") : ""
          color: root.contentForeground
          wrapMode: Text.WrapAnywhere
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.analysisReport && (root.analysisReport.invocation_edges || []).length > 0
          text: root.analysisReport ? "Invocation edges: " +
            (root.analysisReport.invocation_edges || []).length : ""
          color: Util.alpha(root.contentForeground, 0.72)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.analysisReport && (root.analysisReport.findings || []).length === 0 && !root.analysisLoading
          text: "No findings reported for this plugin."
          color: root.contentForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Repeater {
          model: root.analysisReport ? (root.analysisReport.findings || []) : []
          delegate: Rectangle {
            required property var modelData
            width: parent.width
            implicitHeight: findingCard.implicitHeight + Style.space(12)
            radius: Style.cornerRadius
            color: Util.alpha(root.statusColor(root.analysisSeverityLevel(modelData.severity)), 0.07)
            border.width: 1
            border.color: Util.alpha(root.contentForeground, 0.20)
            Column {
              id: findingCard
              anchors.fill: parent
              anchors.margins: Style.space(6)
              spacing: Style.space(3)
              Text {
                text: String(modelData.rule_id || "finding") + " · " + String(modelData.severity || "warning")
                color: root.statusColor(root.analysisSeverityLevel(modelData.severity))
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }
              Text {
                width: parent.width
                text: (modelData.relative_path || "unknown file") +
                  (modelData.line !== undefined ? ":" + modelData.line : "") +
                  (modelData.evidence ? "\n" + modelData.evidence : "")
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }
              Text {
                visible: modelData.explanation || modelData.review_guidance || modelData.capability
                width: parent.width
                text: [modelData.explanation, modelData.review_guidance,
                  modelData.capability ? "Capability: " + modelData.capability : ""].filter(Boolean).join("\n")
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                color: Util.alpha(root.contentForeground, 0.78)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }
              Button {
                text: root.expandedFindingKey === String(modelData.rule_id || "")
                  ? "Hide rule explanation" : "Explain rule"
                bordered: true
                focusable: true
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                onClicked: {
                  if (root.expandedFindingKey === String(modelData.rule_id || "")) root.expandedFindingKey = ""
                  else root.explainRule(modelData.rule_id)
                }
              }
              Text {
                visible: root.expandedFindingKey === String(modelData.rule_id || "")
                width: parent.width
                text: root.ruleExplanationLoading ? "Loading rule catalog entry…" : root.ruleExplanation
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
                color: root.contentForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }
            }
          }
        }

        Button {
          visible: root.analysisReport !== null
          text: root.analysisDetailsExpanded ? "Hide provenance" : "Show provenance"
          bordered: true
          focusable: true
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: root.analysisDetailsExpanded = !root.analysisDetailsExpanded
        }

        Text {
          visible: root.analysisDetailsExpanded && root.analysisReport !== null
          width: parent.width
          text: root.analysisReport ? "Provenance:\n" + JSON.stringify({
            policy_identity: root.analysisReport.policy_identity,
            analysis_fingerprint: root.analysisReport.analysis_fingerprint,
            equivalence: root.analysisReport.equivalence,
            parser: root.analysisReport.parser
          }, null, 2) : ""
          textFormat: Text.PlainText
          wrapMode: Text.WrapAnywhere
          color: Util.alpha(root.contentForeground, 0.72)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Rectangle {
          width: parent.width
          implicitHeight: coverageCard.implicitHeight + Style.space(14)
          radius: Style.cornerRadius
          color: Util.alpha(root.statusColor(root.coverageReport === null ? "unknown" : "normal"), 0.06)
          border.width: 1
          border.color: Util.alpha(root.contentForeground, 0.20)
          Column {
            id: coverageCard
            anchors.fill: parent
            anchors.margins: Style.space(7)
            spacing: Style.space(4)
            Text {
              text: "BASELINE V3 COVERAGE"
              color: Util.alpha(root.contentForeground, 0.64)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
            }
            Text {
              visible: root.coverageLoading
              text: "Loading CLI-owned coverage map…"
              color: Util.alpha(root.contentForeground, 0.72)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              visible: !root.coverageLoading && root.coverageError !== ""
              width: parent.width
              text: root.coverageError
              color: root.warningColor
              wrapMode: Text.WrapAnywhere
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              visible: !root.coverageLoading && root.coverageError === "" &&
                root.coverageReport === null
              width: parent.width
              text: "Coverage map is unavailable until a compatible omasafe-cli is verified."
              color: root.contentForeground
              wrapMode: Text.WordWrap
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              visible: !root.coverageLoading && root.coverageError === "" &&
                root.coverageReport !== null
              width: parent.width
              text: root.coverageReport
                ? "External baseline: " + String(root.coverageReport.external_ruleset_name || "unavailable") +
                  " v" + String(root.coverageReport.external_ruleset_version || "?") +
                  "\nMap: " + String(root.coverageReport.map_version || "unavailable") +
                  " · verified commit " + root.shortDigest(root.coverageReport.verified_at_commit) +
                  "\nRelations are coverage claims only; partial overlap and not-covered are not equivalence."
                : ""
              color: root.contentForeground
              wrapMode: Text.WordWrap
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Button {
              visible: root.coverageReport !== null
              text: root.coverageDetailsExpanded ? "Hide coverage relations" : "Show coverage relations"
              bordered: true
              focusable: true
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              onClicked: root.coverageDetailsExpanded = !root.coverageDetailsExpanded
            }
            Repeater {
              model: root.coverageDetailsExpanded && root.coverageReport
                ? (root.coverageReport.coverage || []).slice(0, 64) : []
              delegate: Rectangle {
                required property var modelData
                width: parent.width
                implicitHeight: relationDetails.implicitHeight + Style.space(8)
                radius: Style.cornerRadius
                color: Util.alpha(root.statusColor(root.coverageRelationLevel(modelData.relation)), 0.05)
                border.width: 1
                border.color: Util.alpha(root.contentForeground, 0.15)
                Column {
                  id: relationDetails
                  anchors.fill: parent
                  anchors.margins: Style.space(4)
                  spacing: Style.space(2)
                  Text {
                    width: parent.width
                    text: String(modelData.externalId || "external id") + " · " +
                      root.coverageRelation(modelData.relation)
                    color: root.statusColor(root.coverageRelationLevel(modelData.relation))
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                  Text {
                    width: parent.width
                    text: "OmaSafe mapping: " + root.coverageOwner(modelData) +
                      "\n" + String(modelData.note || "No mapping note supplied.")
                    color: root.contentForeground
                    wrapMode: Text.WrapAnywhere
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                  }
                }
              }
            }
            Text {
              visible: root.coverageDetailsExpanded && root.coverageReport !== null &&
                (root.coverageReport.coverage || []).length > 64
              text: "Showing first 64 coverage relations."
              color: Util.alpha(root.contentForeground, 0.64)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              visible: root.coverageDetailsExpanded && root.coverageReport !== null &&
                (root.coverageReport.not_covered || []).length > 0
              width: parent.width
              text: root.coverageReport ? "Not covered by OmaSafe: " +
                root.coverageReport.not_covered.slice(0, 32).join(", ") : ""
              color: root.warningColor
              wrapMode: Text.WrapAnywhere
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        Button {
          visible: root.selectedPlugin() !== null
          text: "Open plugin controls"
          bordered: true
          focusable: true
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: root.setActive(2)
        }
      }
    }

  }

  Component {
    id: pluginsTabComponent

    Column {
      width: activeFlick.width
      spacing: Style.space(7)

      Text {
        visible: root.visiblePlugins().length === 0
        text: !root.cliVerified ? "Installed plugins are unavailable until a compatible omasafe-cli is verified." :
          (root.inventoryReport === null ? "Loading installed plugins…" : "No installed plugins.")
        color: root.contentForeground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Repeater {
        model: root.visiblePlugins()
        delegate: Rectangle {
          required property var modelData
          width: parent.width
          implicitHeight: pluginItem.implicitHeight + Style.space(12)
          radius: Style.cornerRadius
          color: root.selectedPluginId === modelData.id
            ? Util.alpha(root.statusColor(root.pluginStatusLevel(modelData)), 0.14) : "transparent"
          border.width: 1
          border.color: root.selectedPluginId === modelData.id
            ? root.statusColor(root.pluginStatusLevel(modelData)) : Util.alpha(root.contentForeground, 0.20)
          Column {
            id: pluginItem
            anchors.fill: parent
            anchors.margins: Style.space(6)
            spacing: Style.space(2)
            Text {
              text: modelData.id
              color: root.contentForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              text: root.pluginStatusLabel(modelData)
              color: Util.alpha(root.contentForeground, 0.70)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
          MouseArea {
            anchors.fill: parent
            enabled: !root.navigationLocked
            cursorShape: Qt.PointingHandCursor
            onClicked: root.selectPlugin(modelData.id, null)
          }
        }
      }

      Rectangle {
        width: parent.width
        implicitHeight: overrideCard.implicitHeight + Style.space(14)
        radius: Style.cornerRadius
        color: Util.alpha(root.contentForeground, 0.05)
        border.width: 1
        border.color: Util.alpha(root.contentForeground, 0.20)
        Column {
          id: overrideCard
          anchors.fill: parent
          anchors.margins: Style.space(7)
          spacing: Style.space(4)
          Text {
            text: "ENFORCEMENT OVERRIDES"
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }
          Text {
            visible: root.overrideLoading
            text: "Loading CLI-owned override records…"
            color: Util.alpha(root.contentForeground, 0.72)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            visible: !root.overrideLoading && root.overrideError !== ""
            width: parent.width
            text: root.overrideError
            color: root.warningColor
            wrapMode: Text.WrapAnywhere
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            visible: !root.overrideLoading && root.overrideError === "" &&
              root.overrideReport !== null && (root.overrideReport.overrides || []).length === 0
            text: "No override records are available. The panel cannot create overrides."
            color: root.contentForeground
            wrapMode: Text.WordWrap
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Button {
            visible: root.overrideReport !== null && (root.overrideReport.overrides || []).length > 0
            text: root.overrideDetailsExpanded ? "Hide override records" : "Show override records"
            bordered: true
            focusable: true
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: root.overrideDetailsExpanded = !root.overrideDetailsExpanded
          }
          Repeater {
            model: root.overrideDetailsExpanded && root.overrideReport
              ? (root.overrideReport.overrides || []).slice(0, 32) : []
            delegate: Rectangle {
              required property var modelData
              width: parent.width
              implicitHeight: overrideDetails.implicitHeight + Style.space(8)
              radius: Style.cornerRadius
              color: Util.alpha(root.statusColor(root.overrideStatusLevel(modelData.status)), 0.05)
              border.width: 1
              border.color: Util.alpha(root.contentForeground, 0.15)
              Column {
                id: overrideDetails
                anchors.fill: parent
                anchors.margins: Style.space(4)
                spacing: Style.space(2)
                Text {
                  width: parent.width
                  text: String(modelData.binding && modelData.binding.plugin_id || "unknown plugin") +
                    " · " + root.overrideStatus(modelData.status)
                  color: root.statusColor(root.overrideStatusLevel(modelData.status))
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
                Text {
                  width: parent.width
                  text: modelData.binding
                    ? "Rules: " + root.enforcementList(modelData.binding.rule_ids, 16) +
                      "\nCommit: " + root.enforcementJson(modelData.binding.commit) +
                      "\nCreated: " + root.enforcementJson(modelData.binding.created_at) +
                      "\nExpires: " + root.enforcementJson(modelData.binding.expires_at) +
                      "\nReason: " + root.enforcementJson(modelData.binding.reason) +
                      "\nCoverage limitations: " + root.enforcementList(
                        modelData.binding.coverage_limitations, 8) : "Binding unavailable"
                  color: root.contentForeground
                  wrapMode: Text.WrapAnywhere
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
          Text {
            visible: root.overrideDetailsExpanded && root.overrideReport !== null &&
              (root.overrideReport.overrides || []).length > 32
            text: "Showing first 32 override records."
            color: Util.alpha(root.contentForeground, 0.64)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            visible: root.overrideReport !== null && (root.overrideReport.overrides || []).length > 0
            width: parent.width
            text: "Override validity and expiry are evaluated by the CLI; this view is read-only."
            color: Util.alpha(root.contentForeground, 0.64)
            wrapMode: Text.WordWrap
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }

      Column {
        visible: root.selectedPlugin() !== null
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "SELECTED PLUGIN · " + root.selectedPluginId
          color: root.contentForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }
        Text {
          width: parent.width
          text: {
            var p = root.selectedPlugin()
            return p ? "Classification: " + p.classification +
              "\nDigest: " + root.shortDigest(p.content_digest) +
              "\nCoverage: " + ((p.limitations || []).join(", ") || "complete") : ""
          }
          color: root.contentForeground
          wrapMode: Text.WordWrap
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
        Text {
          visible: root.statusReport !== null
          width: parent.width
          text: root.statusReport ? "Baseline: " + (root.statusReport.trusted
            ? root.shortDigest(root.statusReport.trusted.content_digest) : "not established") +
            "\nCurrent state: " + root.statusReport.state : ""
          color: root.contentForeground
          wrapMode: Text.WordWrap
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
        Rectangle {
          width: parent.width
          implicitHeight: enforcementDetails.implicitHeight + Style.space(14)
          radius: Style.cornerRadius
          color: Util.alpha(root.statusColor(root.enforcementDecisionLevel(root.enforcementDecision)), 0.08)
          border.width: 1
          border.color: Util.alpha(root.statusColor(root.enforcementDecisionLevel(root.enforcementDecision)), 0.42)
          Column {
            id: enforcementDetails
            anchors.fill: parent
            anchors.margins: Style.space(7)
            spacing: Style.space(3)
            Text {
              text: "ENFORCEMENT DECISION"
              color: Util.alpha(root.contentForeground, 0.64)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
            }
            Text {
              visible: root.enforcementLoading
              text: "Loading CLI-owned decision…"
              color: Util.alpha(root.contentForeground, 0.72)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              visible: !root.enforcementLoading && root.enforcementError !== ""
              width: parent.width
              text: root.enforcementError
              color: root.warningColor
              wrapMode: Text.WrapAnywhere
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              visible: !root.enforcementLoading && root.enforcementError === "" &&
                root.enforcementDecision === null
              text: "No enforcement decision recorded."
              color: root.contentForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              visible: !root.enforcementLoading && root.enforcementError === "" &&
                root.enforcementDecision !== null
              width: parent.width
              text: root.enforcementDecision
                ? "Evaluation: " + root.enforcementEnum(root.enforcementDecision.evaluation_state,
                    ["evaluated", "not-evaluated"]) +
                  "\nOutcome: " + root.enforcementOutcomeLabel(root.enforcementDecision) +
                  "\nEvaluated at: " + String(root.enforcementDecision.evaluated_at || "unavailable") +
                  (root.enforcementDecision.reason_codes && root.enforcementDecision.reason_codes.length > 0
                    ? "\nWhy: " + root.enforcementDecision.reason_codes.slice(0, 16).join(", ") : "") +
                  (root.enforcementDecision.blocking_rule_ids && root.enforcementDecision.blocking_rule_ids.length > 0
                    ? "\nBlocking rules: " + root.enforcementDecision.blocking_rule_ids.slice(0, 16).join(", ") : "") : ""
              color: root.statusColor(root.enforcementDecisionLevel(root.enforcementDecision))
              wrapMode: Text.WrapAnywhere
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Button {
              visible: !root.enforcementLoading && root.enforcementError === "" &&
                root.enforcementDecision !== null
              text: root.enforcementDetailsExpanded ? "Hide decision details" : "Show decision details"
              bordered: true
              focusable: true
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              onClicked: root.enforcementDetailsExpanded = !root.enforcementDetailsExpanded
            }
            Text {
              visible: root.enforcementDetailsExpanded && root.enforcementDecision !== null
              width: parent.width
              text: root.enforcementDecision
                ? "Coverage: " + root.enforcementCoverage(root.enforcementDecision) +
                  "\nCoverage limitations: " + root.enforcementList(
                    root.enforcementDecision.coverage_limitations, 8) +
                  "\nCommit: " + root.enforcementJson(root.enforcementDecision.commit) +
                  "\nTree: " + root.enforcementJson(root.enforcementDecision.tree) +
                  "\nContent digest: " + root.enforcementJson(root.enforcementDecision.content_digest) +
                  "\nAnalyzer identity: " + root.enforcementJson(
                    root.enforcementDecision.analyzer_policy_identity) +
                  "\nEnforcement policy identity: " + root.enforcementJson(
                    root.enforcementDecision.enforcement_policy_identity) +
                  "\nOverride binding: " + root.enforcementJson(
                    root.enforcementDecision.override_binding) +
                  "\nAudit event: " + root.enforcementJson(root.enforcementDecision.audit_event_id) +
                  "\nNative install interposed: " +
                    (root.enforcementDecision.native_install_not_interposed === true
                      ? "no (residual boundary)" : root.enforcementDecision.native_install_not_interposed === false
                        ? "yes" : "unsupported") : ""
              color: root.contentForeground
              wrapMode: Text.WrapAnywhere
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              visible: root.enforcementDecision !== null &&
                root.enforcementRecoveryGuidance(root.enforcementDecision) !== ""
              width: parent.width
              text: root.enforcementRecoveryGuidance(root.enforcementDecision)
              color: root.warningColor
              wrapMode: Text.WrapAnywhere
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }
        Text {
          visible: root.diffReport !== null
          width: parent.width
          text: root.diffReport ? "Changed files: " +
            ((root.diffReport.changed_files || []).slice(0, 5).join(", ") || "none") : ""
          color: root.contentForeground
          wrapMode: Text.WordWrap
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
        Text {
          visible: root.selectedError !== ""
          text: root.selectedError
          color: root.warningColor
          wrapMode: Text.WrapAnywhere
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Row {
          spacing: Style.space(7)
          Button {
            visible: root.canTrustSelectedPlugin()
            text: root.statusReport && root.statusReport.trusted ? "Replace baseline" : "Trust source"
            enabled: !root.operationRunning
            focusable: true
            background: Color.accent
            foreground: Color.background
            accent: Color.accent
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: {
              root.trustError = ""
              root.untrustConfirming = false
              root.reviewUpdateConfirming = false
              root.trustConfirming = true
            }
          }
          Button {
            visible: root.canUntrustSelectedPlugin()
            text: "Untrust"
            enabled: !root.operationRunning
            bordered: true
            focusable: true
            foreground: root.warningColor
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: {
              root.trustError = ""
              root.trustConfirming = false
              root.reviewUpdateConfirming = false
              root.untrustConfirming = true
            }
          }
        }

        Button {
          visible: root.enableEligible()
          text: "Enable inactive plugin"
          tooltipText: "Run the CLI-owned enable preflight; hardened policy may block before mutation."
          enabled: !root.operationRunning
          bordered: true
          focusable: true
          foreground: root.warningColor
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: root.beginEnable()
        }

        Button {
          text: root.updateEligible() ? "Review update" : "Reviewed update unavailable"
          tooltipText: "Update only at the exact upstream commit claimed by the marketplace snapshot."
          enabled: root.updateEligible() && !root.operationRunning
          bordered: true
          focusable: true
          foreground: root.warningColor
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: root.beginReviewUpdate()
        }
        Text {
          visible: root.reviewUpdateMessage !== "" || root.reviewUpdateError !== ""
          width: parent.width
          text: root.reviewUpdateError || root.reviewUpdateMessage
          color: root.reviewUpdateError !== "" ? root.warningColor : root.contentForeground
          wrapMode: Text.WrapAnywhere
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  Component {
    id: catalogTabComponent

    Column {
      width: activeFlick.width
      spacing: Style.space(8)

      Text {
        text: "MARKETPLACE SNAPSHOT"
        color: Util.alpha(root.contentForeground, 0.64)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1
      }
      Text {
        visible: !root.cliVerified
        width: parent.width
        text: "Catalog is unavailable until a compatible omasafe-cli is verified."
        color: root.contentForeground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
      Text {
        visible: root.panelError !== ""
        width: parent.width
        text: root.panelError
        color: root.warningColor
        wrapMode: Text.WrapAnywhere
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
      Rectangle {
        width: parent.width
        implicitHeight: catalogDetails.implicitHeight + Style.space(14)
        radius: Style.cornerRadius
        color: Util.alpha(root.statusColor(root.snapshotIntegrityLevel()), 0.08)
        border.width: 1
        border.color: Util.alpha(root.statusColor(root.snapshotIntegrityLevel()), 0.42)
        Column {
          id: catalogDetails
          anchors.fill: parent
          anchors.margins: Style.space(7)
          spacing: Style.space(4)
          Text {
            text: root.snapshotIntegrityLabel()
            color: root.statusColor(root.snapshotIntegrityLevel())
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            width: parent.width
            text: root.inventoryReport ? "Catalog commit: " + root.shortDigest(root.snapshotCommit()) +
              "\nAge: " + (root.inventoryReport.marketplace_age_seconds === undefined
                ? "unavailable" : root.inventoryReport.marketplace_age_seconds + " seconds") +
              (root.inventoryReport.marketplace_stale ? " (stale)" : "") : "Loading catalog snapshot…"
            color: root.contentForeground
            wrapMode: Text.WrapAnywhere
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            width: parent.width
            text: "Marketplace verification is a catalog claim, not an OmaSafe safety verdict."
            color: Util.alpha(root.contentForeground, 0.68)
            wrapMode: Text.WordWrap
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Button {
            width: parent.width
            text: marketplaceRefreshProcess.running ? "Updating catalog…" : "Update catalog"
            enabled: root.cliVerified && !marketplaceRefreshProcess.running
            bordered: true
            focusable: true
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: root.updateMarketplace()
          }
          Text {
            visible: root.marketplaceRefreshMessage !== "" || root.marketplaceRefreshError !== ""
            width: parent.width
            text: root.marketplaceRefreshError || root.marketplaceRefreshMessage
            color: root.marketplaceRefreshError !== "" ? root.warningColor : root.contentForeground
            wrapMode: Text.WrapAnywhere
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }

      Column {
        visible: root.marketplaceBackupCount() > 0
        width: parent.width
        spacing: Style.space(5)

        Button {
          width: parent.width
          text: root.showPluginBackups ? "Hide plugin backups" :
            "Show plugin backups (" + root.marketplaceBackupCount() + ")"
          bordered: true
          focusable: true
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onClicked: root.showPluginBackups = !root.showPluginBackups
        }

        Text {
          visible: root.showPluginBackups
          width: parent.width
          text: "Backups are retained plugin copies and are excluded from normal plugin controls."
          color: Util.alpha(root.contentForeground, 0.68)
          wrapMode: Text.WordWrap
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

      }

      Text {
        visible: root.marketplaceListings().length === 0
        text: root.marketplaceBackupCount() > 0
          ? "No non-backup marketplace listings were returned for the installed plugins."
          : "No marketplace listings were returned for the installed plugins."
        color: root.contentForeground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
      Repeater {
        model: root.marketplaceListings()
        delegate: Rectangle {
          required property var modelData
          width: parent.width
          implicitHeight: listing.implicitHeight + Style.space(12)
          radius: Style.cornerRadius
          color: Util.alpha(root.contentForeground, 0.05)
          border.width: 1
          border.color: Util.alpha(root.contentForeground, 0.20)
          Column {
            id: listing
            anchors.fill: parent
            anchors.margins: Style.space(6)
            spacing: Style.space(2)
            Text {
              text: modelData.plugin_id || "Unknown listing"
              color: root.contentForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              width: parent.width
              text: {
                var claim = root.marketplaceClaim(modelData)
                return "Status: " + (modelData.status || "unavailable") +
                  "\nReason: " + (modelData.reason || "unavailable") +
                  "\nListing verification: " + root.listingVerificationLabel(modelData) +
                  "\nCommit comparison: " + root.installedCommitLabel(modelData) +
                  "\nValidated commit: " + root.shortDigest(claim && claim.listing_validated_commit) +
                  "\nUpstream commit: " + root.shortDigest(claim && claim.upstream_observed_commit) +
                  "\nUpstream state: " + root.upstreamCommitLabel(modelData) +
                  "\nRegistry commit: " + root.shortDigest(claim && claim.registry_commit) +
                  (claim && claim.registry_repository ? "\nRegistry repository: " + claim.registry_repository : "")
              }
              color: root.listingVerificationLevel(modelData) === "warning" ||
                root.installedCommitLevel(modelData) === "warning" ||
                root.upstreamCommitLevel(modelData) === "warning"
                ? root.warningColor : root.contentForeground
              wrapMode: Text.WrapAnywhere
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              width: parent.width
              text: modelData.disclaimer || "Marketplace data is a claim from this snapshot."
              color: Util.alpha(root.contentForeground, 0.68)
              wrapMode: Text.WordWrap
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
          MouseArea {
            anchors.fill: parent
            enabled: !root.navigationLocked
            cursorShape: Qt.PointingHandCursor
            onClicked: if (modelData.plugin_id) root.selectPlugin(modelData.plugin_id, null)
          }
        }
      }
    }
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
        if (root.activeTabKey === "findings") root.ensureCoverage()
      }
    }
    function onCliVersionChanged() {
      // Analysis and rule explanations are versioned CLI output. A new binary
      // must not reuse a report produced by the previous analyzer/policy.
      root.clearAnalysisCache()
      root.coverageReport = null
      root.coverageCliVersion = ""
      root.coverageDetailsExpanded = false
      root.ruleExplanationCache = ({})
      root.ruleExplanation = ""
      root.ruleExplanationKey = ""
      root.ruleExplanationLoading = false
    }
    function onAlertsChanged() {
      root.clearAnalysisCache()
      root.refreshEnforcementStatus()
      if (root.opened && root.activeTabKey === "findings") root.ensureAnalysis()
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
          root.scheduleConfirming = false
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
          root.scheduleConfirming = false
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
          root.scheduleConfirming = false
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
      root.scheduleConfirming = false
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
          analysisTimeout.stop()
          root.terminateBoundedProcess(analysisProcess)
        }
      }
    }
    onExited: function(exitCode) {
      root.stopBoundedProcessTimers(analysisProcess, analysisTimeout)
      if (!root.analysisSettled) {
        root.analysisSettled = true
        var stderr = String(root.analysisStderr || "").trim()
        if (analysisProcess.pluginId === root.selectedPluginId &&
            analysisProcess.requestId === root.analysisRequestId) {
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
              root.analysisReport = analysis
              root.analysisCoverageStates = coverageStates
              root.analysisPolicyKey = root.analysisPolicyKeyFor(analysis)
              root.cacheAnalysis(analysisProcess.pluginId,
                root.analysisDigestFor(root.selectedPlugin()), analysis, coverageStates)
              root.analysisError = ""
            } catch (error) {
              root.analysisReport = null
              root.analysisError = stderr || "CLI returned an invalid analysis report."
            }
          } else {
            root.analysisReport = null
            root.analysisError = stderr || "Analysis failed with exit status " + exitCode + "."
          }
          root.analysisLoading = false
        }
      }
      root.analysisStdout = ""
      root.analysisStderr = ""
      if (analysisProcess.nextPluginId !== "") {
        var nextPlugin = analysisProcess.nextPluginId
        var nextRequest = analysisProcess.nextRequestId
        analysisProcess.nextPluginId = ""
        analysisProcess.startFor(nextPlugin, nextRequest)
      }
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
      command = root.cliCommand(["rules", "explain", id])
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
          var text = String(root.ruleExplanationStdout || "").trim()
          if (exitCode === 0) {
            try {
              var report = JSON.parse(text)
              text = report.result && (report.result.explanation || report.result.text)
                ? (report.result.explanation || report.result.text) : JSON.stringify(report.result || report, null, 2)
            } catch (error) {
              // The CLI may return a human-readable explanation rather than JSON.
            }
            root.ruleExplanation = text || "No explanation was returned."
            var next = ({})
            for (var key in root.ruleExplanationCache) next[key] = root.ruleExplanationCache[key]
            next[ruleExplanationProcess.cacheKey] = root.ruleExplanation
            root.ruleExplanationCache = next
          } else {
            root.ruleExplanation = String(root.ruleExplanationStderr || "").trim() ||
              "Rule explanation failed with exit status " + exitCode + "."
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
        var resultApplied = root.applyEnableResult(enableProcess.stdoutBuffer,
          enableProcess.pluginId)
        if (exitCode === 0) {
          root.enableConfirming = false
          root.enableError = ""
          root.enableMessage = "Enabled " + enableProcess.pluginId + " with " +
            enableProcess.policy + " policy."
          root.inventoryReloadPending = root.inventoryReloadPending || inventoryProcess.running
          if (!inventoryProcess.running) {
            root.nextInventoryCatalogOnly = false
            inventoryProcess.running = true
          }
          if (root.hostWidget) root.hostWidget.runScan()
        } else {
          var decision = root.enforcementDecision
          var reasons = decision && decision.reason_codes && decision.reason_codes.length > 0
            ? "Reasons: " + decision.reason_codes.slice(0, 16).join(", ") : ""
          root.enableError = stderr || reasons ||
            "Enable was refused or failed with exit status " + exitCode + "."
          if (!resultApplied && root.enforcementDecision === null)
            root.enforcementError = "Enable decision is unavailable."
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
          root.reviewUpdateConfirming = false
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
          root.reviewUpdateConfirming = false
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
        root.reviewUpdateConfirming = false
        root.reviewUpdateError = ""
        root.reviewUpdateMessage = "Reviewed update completed at " + reviewUpdateProcess.commit + "."
        root.clearAnalysisCache()
        root.inventoryReloadPending = root.inventoryReloadPending || inventoryProcess.running
        if (!inventoryProcess.running) {
          root.nextInventoryCatalogOnly = false
          inventoryProcess.running = true
        }
        if (root.hostWidget) root.hostWidget.runScan()
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
      root.reviewUpdateConfirming = false
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
    command: root.cliCommand([])
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.trustSettled) return
        root.trustOutput = (root.trustOutput + String(chunk)).slice(0, root.v02OutputCharCap + 1)
        if (root.trustOutput.length > root.v02OutputCharCap) {
          root.trustSettled = true
          root.trustError = "Trust operation output exceeded the configured output cap."
          root.trustConfirming = false
          root.untrustConfirming = false
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
          root.trustConfirming = false
          root.untrustConfirming = false
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
        root.trustConfirming = false
        root.untrustConfirming = false
        root.panelError = ""
        root.clearAnalysisCache()
        root.selectPlugin(root.selectedPluginId, root.selectedAlert())
        root.refreshPluginStatuses()
        if (root.hostWidget) root.hostWidget.runScan()
      } else {
        root.panelError = root.trustError || (root.trustOperation === "untrust"
          ? "Trust baseline could not be removed."
          : "Trust baseline could not be recorded.")
      }
      root.trustConfirming = false
      root.untrustConfirming = false
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
      root.trustConfirming = false
      root.untrustConfirming = false
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
