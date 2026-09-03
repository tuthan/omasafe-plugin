// ViewModel.js — the one normaliser for the OmaSafe panel (doc 03, 05 §5, T2.1).
//
// `build(input)` turns the raw CLI reports the collectors store into one plain
// object the views bind to, so no delegate walks a raw report and no view calls a
// data function. It is pure: no QML access, closed-enum labels come from Labels.js
// and times from Time.js. It strips `file_digests` from inventory/status before
// returning them. Glyph *keys* (not resolved glyphs) are returned so the views pick
// the Nerd/ASCII column with the live font family; relation marks and text are
// plain and returned as-is.
.pragma library
.import "Labels.js" as Labels
.import "Time.js" as Time
.import "Glyphs.js" as Glyphs

// ---- small helpers ------------------------------------------------------------

function _arr(v) { return Array.isArray(v) ? v : [] }
function _str(v) { return String(v === null || v === undefined ? "" : v) }
function _commit7(v) { var s = _str(v); return s === "" ? "" : s.slice(0, 7) }

function _severityRank(v) {
  return Labels.severityRank(v)
}

// classification → the ui-glyph key the PluginRow / hero uses.
function classGlyphKey(classification) {
  switch (_str(classification)) {
    case "Git-managed":  return "git-checkout"
    case "built-in":     return "installed-no-git"
    case "cloned/local": return "installed-no-git"
    default:             return "unsupported"
  }
}

// A shallow copy of a plugin/status object with `file_digests` removed (never used
// by any view; large and noisy — 05 §5).
function _stripDigests(obj) {
  if (!obj || typeof obj !== "object") return obj
  var out = {}
  for (var k in obj) if (k !== "file_digests") out[k] = obj[k]
  return out
}

// ---- capability occurrence counts (analysis.capabilities[] by class) ----------

function _capCounts(analysis) {
  var counts = {}
  if (!analysis) return counts
  var caps = _arr(analysis.capabilities)
  for (var i = 0; i < caps.length; i++) {
    var cls = _str(caps[i].capability)
    if (cls === "") continue
    counts[cls] = (counts[cls] || 0) + 1
  }
  return counts
}

// Occurrences of one rule id in a plugin's analysis (capabilities source_rule_id +
// findings rule_id) — the LOCAL HITS / Baseline inversion (03 §7.1).
function _ruleOccurrences(analysis, ruleId) {
  if (!analysis) return 0
  var n = 0
  var caps = _arr(analysis.capabilities)
  for (var i = 0; i < caps.length; i++)
    if (_str(caps[i].source_rule_id) === ruleId) n++
  var fs = _arr(analysis.findings)
  for (var j = 0; j < fs.length; j++)
    if (_str(fs[j].rule_id) === ruleId) n++
  return n
}

// ---- plugins (Overview list + detail base) ------------------------------------

function _limitsText(analysis) {
  if (!analysis) return ""
  var n = _arr(analysis.coverage_limitations).length
  return n > 0 ? " · " + n + " limits" : ""
}
function _lexicalText(analysis) {
  return (analysis && (analysis.parser === null || analysis.parser === undefined))
    ? " · text match only" : ""
}

function _changedFileCount(status) {
  if (!status) return 0
  if (Array.isArray(status.changed_files)) return status.changed_files.length
  return Number(status.changed_file_count || 0)
}

function _marketplaceByPlugin(inv, id) {
  var m = _arr(inv.marketplace)
  for (var i = 0; i < m.length; i++) if (_str(m[i].plugin_id) === id) return m[i]
  return null
}

function buildPlugins(input) {
  var inv = input.inventory || {}
  var plugins = _arr(inv.plugins).filter(function(p) { return _str(p.classification) !== "backup" })
  var statusById = input.statusById || {}
  var analysisById = input.analysisById || {}
  var checking = _arr(input.checkingIds)
  var alerted = {}
  var alertSeverityById = {}
  var alerts = _arr(input.alerts)
  for (var a = 0; a < alerts.length; a++) {
    var alertId = _str(alerts[a].plugin_id)
    alerted[alertId] = true
    var alertTier = Labels.severityTier(alerts[a].severity)
    if (!alertSeverityById[alertId] || Labels.severityRank(alertTier) > Labels.severityRank(alertSeverityById[alertId]))
      alertSeverityById[alertId] = alertTier
  }
  var scanMeta = input.scanMeta || {}
  var scanHasResult = scanMeta.hasResult === true

  var out = []
  for (var i = 0; i < plugins.length; i++) {
    var p = _stripDigests(plugins[i])
    var id = _str(p.id)
    var status = statusById[id] || null
    var analysis = analysisById[id] || null
    var analyzed = !!analysis
    var isChecking = !status && checking.indexOf(id) >= 0

    var trustWord, trustLong, trustGlyphKey = "", trustBold = false
    if (status) {
      var nFiles = _changedFileCount(status)
      trustWord = Labels.trustShort(status.state, status.reason, nFiles)
      trustLong = Labels.trustState(status.state, status.reason, nFiles)
      if (_str(status.state) === "changed") { trustGlyphKey = "alert"; trustBold = true }
    } else if (isChecking) {
      trustWord = "checking…"; trustLong = "Checking baseline…"
    } else {
      trustWord = "unavailable"; trustLong = "Baseline status unavailable"
    }

    var counts = _capCounts(analysis)
    var countText = analyzed ? Labels.reviewCount(analysis.findings ? _arr(analysis.findings).length : 0)
      : (isChecking ? "checking…" : "not analyzed")

    var marketplace = _marketplaceByPlugin(inv, id)
    // Staleness wins over a remembered alert tier: the alert row keeps its
    // severity, while the plugin health marker makes the data age explicit.
    var healthState = scanMeta.stale === true ? "stale" : (alertSeverityById[id] || "")
    if (healthState === "") {
      if (scanHasResult && status && _str(status.state) === "unchanged") healthState = "healthy"
      else healthState = "unknown"
    }
    var healthLabel = healthState === "healthy" ? "No active alerts" :
      (healthState === "stale" ? "Showing a cached scan result" :
        (alertSeverityById[id] ? "Highest alert severity: " + Labels.severity(alertSeverityById[id]) :
          "Plugin status unavailable"))
    out.push({
      id: id,
      raw: p,
      marketplace: marketplace,
      claim: (marketplace && marketplace.registry_claim) ? marketplace.registry_claim : null,
      classification: _str(p.classification),
      classGlyphKey: classGlyphKey(p.classification),
      kinds: _arr(p.kinds),
      contentFileCount: Number(p.content_file_count || 0),
      firstParty: (p.first_party === true || p.first_party === false) ? p.first_party : null,
      state: status ? _str(status.state) : "",
      trustWord: trustWord,
      trustLong: trustLong,
      trustGlyphKey: trustGlyphKey,
      trustBold: trustBold,
      analyzed: analyzed,
      counts: counts,
      reviewCount: analyzed ? _arr(analysis.findings).length : 0,
      countText: countText,
      limitsText: _limitsText(analysis),
      lexicalText: _lexicalText(analysis),
      parserNull: analyzed && (analysis.parser === null || analysis.parser === undefined),
      coverageLimitCount: analyzed ? _arr(analysis.coverage_limitations).length : 0,
      alerted: alerted[id] === true,
      healthState: healthState,
      healthLabel: healthLabel
    })
  }

  // Order: alerted desc, analyzed desc, id ascending (03 §4.1).
  out.sort(function(x, y) {
    if (x.alerted !== y.alerted) return x.alerted ? -1 : 1
    if (x.analyzed !== y.analyzed) return x.analyzed ? -1 : 1
    return x.id < y.id ? -1 : (x.id > y.id ? 1 : 0)
  })
  return out
}

// Backup rows for the Overview backups toggle (doc 03 §4.1). Kept out of `plugins`
// so they never pollute the finder index or the rules LOCAL HITS inversion.
function buildBackups(input) {
  var inv = input.inventory || {}
  var backups = _arr(inv.plugins).filter(function(p) { return _str(p.classification) === "backup" })
  var out = []
  for (var i = 0; i < backups.length; i++) {
    out.push({
      id: _str(backups[i].id),
      classGlyphKey: "backup",
      trustWord: "Backup copy (not scanned)",
      trustLong: "",
      trustGlyphKey: "",
      trustBold: false,
      analyzed: false,
      counts: {},
      countText: "",
      limitsText: "",
      lexicalText: "",
      healthState: "unknown",
      healthLabel: "Backup copy is not scanned",
      isBackup: true
    })
  }
  return out
}

// ---- alerts -------------------------------------------------------------------

function buildAlerts(input, pluginsById) {
  var alerts = _arr(input.alerts)
  var scanMeta = input.scanMeta || {}
  var now = input.nowMs
  var out = []
  for (var i = 0; i < alerts.length; i++) {
    var a = alerts[i]
    var pid = _str(a.plugin_id)
    var kindLabel = Labels.alertKind(a.kind)
    if (_str(a.kind) === "finding-regression" && _str(a.rule || a.rule_id) !== "")
      kindLabel = kindLabel + ": " + _str(a.rule || a.rule_id)
    var when = _str(a.generated_at) !== "" ? a.generated_at : scanMeta.generatedAt
    var rel = Time.relative(when, now)
    var subtitle = pid + " · reported " + (rel !== "" ? rel : "unavailable")
    if (a.post_change === true) subtitle += " · plugin changed"
    out.push({
      pluginId: pid,
      kindLabel: kindLabel,
      subtitle: subtitle,
      severity: Labels.severity(a.severity),
      severityLevel: Labels.severityTier(a.severity),
      urgent: Labels.alertIsUrgent(a.severity),
      severityRank: _severityRank(a.severity),
      isNew: a.new === true,
      pseudo: !pluginsById[pid]
    })
  }
  // highest severity first, then new before acknowledged, then plugin id.
  out.sort(function(x, y) {
    if (x.severityRank !== y.severityRank) return y.severityRank - x.severityRank
    if (x.isNew !== y.isNew) return x.isNew ? -1 : 1
    return x.pluginId < y.pluginId ? -1 : (x.pluginId > y.pluginId ? 1 : 0)
  })
  return out
}

// ---- sources ------------------------------------------------------------------

function buildSources(input) {
  var inv = input.inventory || {}
  var stale = inv.marketplace_stale === true
  var schedule = input.schedule || null
  var overrides = input.overrides ? _arr(input.overrides.overrides) : []

  var scheduleLabel, scheduleSub = "", scheduleAction = ""
  if (!schedule) {
    scheduleLabel = "Scheduled scan · loading…"
  } else if (schedule.installed === false) {
    scheduleLabel = "Scheduled scan · not installed"; scheduleAction = "Install"
  } else {
    scheduleLabel = "Scheduled scan · " + Labels.scheduleStatus(schedule.policy)
    var lke = schedule.last_known_execution
    if (lke && lke.service_finished_at !== undefined && lke.service_finished_at !== null) {
      scheduleSub = "Last run " + (Time.relative(lke.service_finished_at, input.nowMs) || "unavailable")
        + " · exit " + _str(lke.service_exit_code)
    } else {
      scheduleSub = "Last run unavailable"
    }
    scheduleAction = "Reinstall"
  }

  return {
    cliVersion: _str(input.cliVersion),
    snapshotCommit7: _commit7(inv.marketplace_repository_commit),
    snapshotAgeText: Time.age(inv.marketplace_age_seconds, stale),
    snapshotSourceText: Labels.marketplaceSource(inv.marketplace_source),
    snapshotStale: stale,
    snapshotRetrievedAt: _str(inv.marketplace_retrieved_at),
    scheduleLabel: scheduleLabel,
    scheduleSub: scheduleSub,
    scheduleAction: scheduleAction,
    scheduleMetadataInconsistent: schedule ? (schedule.metadata_consistent === false) : false,
    scheduleMetadataError: schedule ? _str(schedule.metadata_error) : "",
    overrideCount: overrides.length,
    overrides: overrides
  }
}

// ---- rules (catalog + LOCAL HITS inversion) -----------------------------------

function buildRules(input, plugins) {
  var rl = input.rulesList || null
  var analysisById = input.analysisById || {}
  var analyzedCount = 0
  for (var p = 0; p < plugins.length; p++) if (plugins[p].analyzed) analyzedCount++

  var rules = rl ? _arr(rl.rules) : []
  var out = []
  for (var i = 0; i < rules.length; i++) {
    var r = rules[i]
    var id = _str(r.id)
    var hits = []
    var hitPlugins = 0, hitOccurrences = 0, notAnalyzed = []
    for (var j = 0; j < plugins.length; j++) {
      var pl = plugins[j]
      if (!pl.analyzed) { notAnalyzed.push(pl.id); continue }
      var occ = _ruleOccurrences(analysisById[pl.id], id)
      if (occ > 0) {
        hitPlugins++; hitOccurrences += occ
        hits.push({ pluginId: pl.id, occurrences: occ,
          limitsText: pl.limitsText, lexicalText: pl.lexicalText })
      }
    }
    hits.sort(function(x, y) { return y.occurrences - x.occurrences })
    out.push({
      id: id,
      title: _str(r.title),
      summary: _str(r.summary),
      capability: _str(r.capability),
      classGlyphKey: _str(r.capability),
      language: _str(r.language),
      severity: Labels.severity(r.default_severity),
      surfaceAnchor: _str(r.surface_anchor),
      reviewGuidance: _str(r.review_guidance),
      hits: hits,
      notAnalyzed: notAnalyzed,
      hitPluginCount: hitPlugins,
      hitOccurrenceCount: hitOccurrences,
      // "<k> PLUGINS · <n>" (sheet header) or "–" until any analysis exists.
      hitText: analyzedCount === 0 ? "–" : (hitPlugins + " PLUGINS · " + hitOccurrences),
      // The catalog row's right-aligned count: occurrences, or "–" before analysis
      // (03 §7.1: never 0 until at least one plugin is analyzed).
      rowHitText: analyzedCount === 0 ? "–" : _str(hitOccurrences)
      ,severityLevel: Labels.severityTier(r.default_severity),
      noLocalHits: analyzedCount > 0 && analyzedCount === plugins.length && hitOccurrences === 0,
      analysisComplete: analyzedCount === plugins.length
    })
  }
  // capability class then id.
  out.sort(function(x, y) {
    var cx = Glyphs.capabilityOrder.indexOf(x.capability)
    var cy = Glyphs.capabilityOrder.indexOf(y.capability)
    if (cx !== cy) return (cx < 0 ? 99 : cx) - (cy < 0 ? 99 : cy)
    return x.id < y.id ? -1 : (x.id > y.id ? 1 : 0)
  })
  return {
    rules: out,
    catalogVersion: rl ? _str(rl.rule_catalog_version) : "",
    count: out.length,
    analyzedCount: analyzedCount
  }
}

// ---- Baseline V3 coverage table ----------------------------------------------

function buildBaseline(input, plugins, analyzedCount) {
  var cov = input.coverage || null
  if (!cov) return { available: false, rows: [], partialCount: 0, notCoveredCount: 0 }
  var entries = _arr(cov.coverage)
  var notCovered = _arr(cov.not_covered).map(_str)
  var analysisById = input.analysisById || {}

  // group by externalId (in first-seen order).
  var groups = {}, order = []
  for (var i = 0; i < entries.length; i++) {
    var e = entries[i]
    var xid = _str(e.externalId)
    if (!groups[xid]) { groups[xid] = []; order.push(xid) }
    groups[xid].push(e)
  }

  function observedText(ruleId) {
    if (analyzedCount === 0) return "–"
    var k = 0
    for (var j = 0; j < plugins.length; j++) {
      if (!plugins[j].analyzed) continue
      if (_ruleOccurrences(analysisById[plugins[j].id], ruleId) > 0) k++
    }
    return k > 0 ? "observed in " + k + " analyzed plugins"
                 : "not observed in " + analyzedCount + " analyzed plugins"
  }

  var rows = [], partialCount = 0
  for (var o = 0; o < order.length; o++) {
    var xid2 = order[o]
    var grp = groups[xid2]
    var relation = _str(grp[0].relation)
    var relWord = Labels.relation(relation)
    var mark = relation === "structural-equivalent" ? "=" : (relation === "partial-overlap" ? "≈" : "")
    var covered = relation !== "not-covered"
    if (relation === "partial-overlap" || relation === "structural-equivalent") partialCount++

    var ruleIds = [], hasCapability = false, note = ""
    for (var g = 0; g < grp.length; g++) {
      if (_str(grp[g].omaRuleId) !== "" && ruleIds.indexOf(_str(grp[g].omaRuleId)) < 0)
        ruleIds.push(_str(grp[g].omaRuleId))
      if (_str(grp[g].omaCapability) !== "") hasCapability = true
      if (_str(grp[g].note) !== "") note = _str(grp[g].note)
    }

    var line2
    if (!covered) line2 = "Not covered by OmaSafe"
    else if (ruleIds.length > 0) line2 = (ruleIds.length === 1 ? "1 OmaSafe rule" : ruleIds.length + " OmaSafe rules") + " · " + relWord
    else if (hasCapability) line2 = Labels.capability(_str(grp[0].omaCapability)) + " (class) · " + relWord
    else line2 = "Inventory behaviour only (see note) · " + relWord

    var covering = []
    for (var c = 0; c < ruleIds.length; c++)
      covering.push({ ruleId: ruleIds[c], observedText: observedText(ruleIds[c]) })

    rows.push({
      externalId: xid2,
      relationMark: mark,
      relationWord: relWord,
      covered: covered,
      line2: line2,
      coveringRules: covering,
      note: note,
      dim: !covered
    })
  }

  var name = _str(cov.external_ruleset_name)
  var version = _str(cov.external_ruleset_version)
  return {
    available: true,
    rows: rows,
    partialCount: partialCount,
    notCoveredCount: notCovered.length,
    mapVersion: _str(cov.map_version),
    verifiedCommit7: _commit7(cov.verified_at_commit),
    headerLine: name + " v" + version + " · map " + _str(cov.map_version)
      + " · checked against marketplace commit " + _commit7(cov.verified_at_commit),
    headerSentence: "Relations are coverage claims about rules; no plugin is checked against Baseline V3 here.",
    notCoveredFooter: notCovered.length > 0 ? "Not covered by OmaSafe: " + notCovered.join(" · ") : ""
  }
}

// ---- finder index -------------------------------------------------------------

function buildFinder(input, plugins, rulesBundle) {
  var cov = input.coverage || null
  var rules = rulesBundle.rules

  var pluginEntries = plugins.map(function(p) { return { id: p.id, _k: p.id.toLowerCase() } })

  // classes: 17 catalog classes with rule count and observing analyzed-plugin count.
  var classEntries = []
  var order = Glyphs.capabilityOrder
  for (var i = 0; i < order.length; i++) {
    var cls = order[i]
    var ruleCount = 0
    for (var r = 0; r < rules.length; r++) if (rules[r].capability === cls) ruleCount++
    var pluginCount = 0
    for (var p = 0; p < plugins.length; p++) if (plugins[p].analyzed && Number(plugins[p].counts[cls] || 0) > 0) pluginCount++
    classEntries.push({ key: cls, name: Labels.capability(cls), ruleCount: ruleCount, pluginCount: pluginCount, _k: cls.toLowerCase() })
  }

  // rules: match on id + title only (NOT capability — a class result covers it).
  var ruleEntries = rules.map(function(rr) {
    return { id: rr.id, title: rr.title, capability: rr.capability, language: rr.language,
      severity: rr.severity, classGlyphKey: rr.classGlyphKey,
      _k: (rr.id + " " + rr.title).toLowerCase() }
  })

  // baseline ids (covered) + not-covered ids.
  var baseEntries = []
  if (cov) {
    var seen = {}
    var entries = _arr(cov.coverage)
    for (var b = 0; b < entries.length; b++) {
      var xid = _str(entries[b].externalId)
      if (xid !== "" && !seen[xid]) { seen[xid] = true
        var rel = _str(entries[b].relation)
        baseEntries.push({ externalId: xid, relationMark: rel === "structural-equivalent" ? "=" : (rel === "partial-overlap" ? "≈" : ""), _k: xid.toLowerCase() }) }
    }
    var nc = _arr(cov.not_covered)
    for (var n = 0; n < nc.length; n++) {
      var ncid = _str(nc[n])
      if (ncid !== "" && !seen[ncid]) { seen[ncid] = true
        baseEntries.push({ externalId: ncid, relationMark: "", _k: ncid.toLowerCase() }) }
    }
  }

  return { plugins: pluginEntries, classes: classEntries, rules: ruleEntries, baseline: baseEntries }
}

// Pure search over a finder index (called per keystroke by FinderResultsView).
// Case-insensitive substring; groups with no match are omitted (03 §8).
function search(index, text) {
  var q = _str(text).toLowerCase()
  if (index === null || index === undefined) return { plugins: [], classes: [], rules: [], baseline: [], empty: true }
  function f(list) { return _arr(list).filter(function(e) { return e._k.indexOf(q) >= 0 }) }
  var plugins = q === "" ? [] : f(index.plugins)
  var classes = q === "" ? [] : f(index.classes)
  var rules = q === "" ? [] : f(index.rules)
  var baseline = q === "" ? [] : f(index.baseline)
  return {
    plugins: plugins, classes: classes, rules: rules, baseline: baseline,
    empty: q !== "" && plugins.length === 0 && classes.length === 0 && rules.length === 0 && baseline.length === 0
  }
}

// ---- the root build -----------------------------------------------------------

function build(input) {
  input = input || {}
  var plugins = buildPlugins(input)
  var pluginsById = {}
  for (var i = 0; i < plugins.length; i++) pluginsById[plugins[i].id] = plugins[i]

  var analyzedCount = 0
  for (var a = 0; a < plugins.length; a++) if (plugins[a].analyzed) analyzedCount++

  var inv = input.inventory || {}
  var liveCount = _arr(inv.plugins).filter(function(p) { return _str(p.classification) !== "backup" }).length
  var backupCount = _arr(inv.plugins).filter(function(p) { return _str(p.classification) === "backup" }).length

  var rulesBundle = buildRules(input, plugins)
  var baseline = buildBaseline(input, plugins, analyzedCount)
  var finder = buildFinder(input, plugins, rulesBundle)

  return {
    plugins: plugins,
    pluginsById: pluginsById,
    backups: buildBackups(input),
    analyzedCount: analyzedCount,
    liveCount: liveCount,
    backupCount: backupCount,
    alerts: buildAlerts(input, pluginsById),
    outstanding: Number((input.scanMeta || {}).outstanding || 0),
    sources: buildSources(input),
    rules: rulesBundle.rules,
    ruleCatalogVersion: rulesBundle.catalogVersion,
    ruleCount: rulesBundle.count,
    baseline: baseline,
    finder: finder,
    // inventory-level coverage limitations, for the under-hero NoticeRow.
    inventoryLimitations: (inv.coverage && _arr(inv.coverage.limitations)) || []
  }
}

// ---- Trust Flow input (doc 04 §3.2, §4.1) -------------------------------------
// flowInput(input, scope, filters) turns the raw store into the slice FlowLayout.js
// consumes: per-plugin byClass evidence, class/rule/baseline aggregates and the
// derived edges. Pure; walks raw analyses (capabilities[] + findings[]) once. No CLI
// call and no analysis is started here — `analysis` is a state word from the caller's
// analysisStateById, never re-derived (P11: analyze on a/A only).

function _confBackedInc(rec, confidence) {
  if (_str(confidence) === "ast-backed") rec.parserBacked++
  else rec.lexicalOnly++            // lexical-fallback or null: no parser support
}

// One plugin's per-class evidence aggregation from its raw analysis.
function _pluginByClass(analysis) {
  var byClass = {}
  function rec(cls) {
    if (!byClass[cls]) byClass[cls] = { n: 0, review: 0, files: {}, parserBacked: 0,
      lexicalOnly: 0, rules: {} }
    return byClass[cls]
  }
  var caps = _arr(analysis && analysis.capabilities)
  for (var i = 0; i < caps.length; i++) {
    var c = caps[i], cls = _str(c.capability)
    if (cls === "") continue
    var r = rec(cls)
    r.n++
    r.files[_str(c.relative_path)] = true
    _confBackedInc(r, c.confidence)
    var srid = _str(c.source_rule_id)
    if (srid !== "") r.rules[srid] = true
  }
  var fs = _arr(analysis && analysis.findings)
  for (var j = 0; j < fs.length; j++) {
    var f = fs[j], fcls = _str(f.capability)
    if (fcls === "") continue
    var rf = rec(fcls)
    rf.review++
    _confBackedInc(rf, f.confidence)
    var frid = _str(f.rule_id)
    if (frid !== "") rf.rules[frid] = true
  }
  return byClass
}

function flowInput(input) {
  input = input || {}
  var scope = input.scope || { kind: "all" }
  var filters = input.filters || { backups: false }
  var inv = input.inventory || {}
  var analysisById = input.analysisById || {}
  var stateById = input.analysisStateById || {}
  var statusById = input.statusById || {}
  var scanStale = input.scanStale === true
  var scanHasResult = input.scanHasResult === true
  var enforcementById = input.enforcementById || {}
  var cov = input.coverage || null
  var rl = input.rulesList || null

  // catalog facts for rule nodes.
  var catalog = {}
  var catRules = rl ? _arr(rl.rules) : []
  for (var ci = 0; ci < catRules.length; ci++) catalog[_str(catRules[ci].id)] = catRules[ci]

  // alerts naming a plugin (outstanding count per id).
  var outstandingById = {}
  var outstandingSeverityById = {}
  var alerts = _arr(input.alerts)
  for (var a = 0; a < alerts.length; a++) {
    var apid = _str(alerts[a].plugin_id)
    if (apid !== "") outstandingById[apid] = (outstandingById[apid] || 0) + 1
    var alertTier = Labels.severityTier(alerts[a].severity)
    if (apid !== "" && (!outstandingSeverityById[apid] ||
        Labels.severityRank(alertTier) > Labels.severityRank(outstandingSeverityById[apid])))
      outstandingSeverityById[apid] = alertTier
  }

  var live = _arr(inv.plugins).filter(function(p) { return _str(p.classification) !== "backup" })
  var atPlugin = scope.kind === "plugin" && _str(scope.id) !== ""
  var drawn = atPlugin ? live.filter(function(p) { return _str(p.id) === _str(scope.id) }) : live

  // --- per-plugin flow records + aggregation maps ---
  var classAgg = {}, ruleAgg = {}, edgeCR = {}, edgePC = []
  var plugins = []
  var lexicalOnlyCount = 0

  function classA(cls) {
    if (!classAgg[cls]) classAgg[cls] = { id: cls, occurrences: 0, reviewItems: 0,
      plugins: {}, parserBacked: 0, lexicalOnly: 0, severity: "unknown" }
    return classAgg[cls]
  }
  function ruleA(rid) {
    if (!ruleAgg[rid]) ruleAgg[rid] = { id: rid, occurrences: 0, reviewItems: 0, plugins: {}, severity: "unknown" }
    return ruleAgg[rid]
  }
  function crA(cls, rid) {
    var k = cls + "|" + rid
    if (!edgeCR[k]) edgeCR[k] = { cls: cls, rid: rid, occ: 0, review: 0, parserBacked: 0, lexicalOnly: 0 }
    return edgeCR[k]
  }

  for (var p = 0; p < drawn.length; p++) {
    var pl = _stripDigests(drawn[p])
    var id = _str(pl.id)
    var analysis = analysisById[id] || null
    var state = _str(stateById[id]) || (analysis ? "analyzed" : "not analyzed")
    var analyzed = state === "analyzed" && !!analysis
    var status = statusById[id] || null
    var enf = enforcementById[id] || null
    var block = !!(enf && enf.decision && _str(enf.decision.outcome) === "block")

    var byClass = analyzed ? _pluginByClass(analysis) : {}
    var occurrences = 0, reviewItems = 0
    var classKeys = []
    for (var cls in byClass) {
      var bc = byClass[cls]
      occurrences += bc.n
      reviewItems += bc.review
      classKeys.push(cls)
      // plugin → class edge (weight = occurrences, or review items for a review-only class)
      var w = bc.n > 0 ? bc.n : bc.review
      edgePC.push({ from: ["plugin", id], to: ["class", cls], w: w,
        support: { parserBacked: bc.parserBacked, lexicalOnly: bc.lexicalOnly } })
      // class + rule aggregation
      var ca = classA(cls)
      ca.occurrences += bc.n; ca.reviewItems += bc.review
      ca.parserBacked += bc.parserBacked; ca.lexicalOnly += bc.lexicalOnly
      ca.plugins[id] = true
      // convert byClass rules into (class,rule) edge contributions below via caps/findings
    }
    // (class,rule) contributions read from the raw arrays for precise per-rule support
    if (analyzed) {
      var caps = _arr(analysis.capabilities)
      for (var q = 0; q < caps.length; q++) {
        var cc = caps[q], ccls = _str(cc.capability), crid = _str(cc.source_rule_id)
        if (ccls === "" || crid === "") continue
        var capTier = Labels.severityTier(catalog[crid] && catalog[crid].default_severity)
        var capClass = classA(ccls)
        if (Labels.severityRank(capTier) > Labels.severityRank(capClass.severity)) capClass.severity = capTier
        var cr = crA(ccls, crid); cr.occ++; _confBackedInc(cr, cc.confidence)
        var ra = ruleA(crid); ra.occurrences++; ra.plugins[id] = true
        if (Labels.severityRank(capTier) > Labels.severityRank(ra.severity)) ra.severity = capTier
      }
      var fs2 = _arr(analysis.findings)
      for (var r2 = 0; r2 < fs2.length; r2++) {
        var ff = fs2[r2], fcls2 = _str(ff.capability), frid2 = _str(ff.rule_id)
        if (frid2 === "") continue
        var findingTier = Labels.severityTier(ff.severity || (catalog[frid2] && catalog[frid2].default_severity))
        var findingRule = ruleA(frid2)
        if (Labels.severityRank(findingTier) > Labels.severityRank(findingRule.severity)) findingRule.severity = findingTier
        if (fcls2 !== "") { var cr2 = crA(fcls2, frid2); cr2.review++; _confBackedInc(cr2, ff.confidence) }
        if (fcls2 !== "") {
          var findingClass = classA(fcls2)
          if (Labels.severityRank(findingTier) > Labels.severityRank(findingClass.severity)) findingClass.severity = findingTier
        }
        var ra2 = ruleA(frid2); ra2.reviewItems++; ra2.plugins[id] = true
        if (Labels.severityRank(findingTier) > Labels.severityRank(ra2.severity)) ra2.severity = findingTier
      }
      if (analysis.parser === null || analysis.parser === undefined) lexicalOnlyCount++
    }

    plugins.push({
      id: id, classification: _str(pl.classification), analysis: state,
      occurrences: occurrences, classes: classKeys.length, reviewItems: reviewItems,
      limits: analyzed ? _arr(analysis.coverage_limitations).length : 0,
      outstanding: outstandingById[id] || 0,
      trust: status ? _str(status.state) : "", trustReason: status ? _str(status.reason) : "",
      block: block, byClass: byClass,
      // A stale scan is shown as stale even when its cached alert list had a
      // previous severity; the alert rows still retain their individual tiers.
      riskLevel: scanStale ? "stale" : (outstandingSeverityById[id] ||
        (scanHasResult && status && status.state === "unchanged" ? "healthy" : "unknown"))
    })
  }

  // optional backups as faint edgeless rows (b filter, scope all only)
  if (!atPlugin && filters.backups) {
    var backups = _arr(inv.plugins).filter(function(x) { return _str(x.classification) === "backup" })
    for (var b2 = 0; b2 < backups.length; b2++)
      plugins.push({ id: _str(backups[b2].id), classification: "backup", analysis: "not scanned",
        occurrences: 0, classes: 0, reviewItems: 0, limits: 0, outstanding: 0,
        trust: "", trustReason: "", block: false, faint: true, byClass: {} })
  }

  // --- class nodes ---
  var classes = []
  for (var clk in classAgg) {
    var cg = classAgg[clk]
    classes.push({ id: cg.id, name: Labels.capability(cg.id), occurrences: cg.occurrences,
      reviewItems: cg.reviewItems, plugins: Object.keys(cg.plugins).length,
      parserBacked: cg.parserBacked, lexicalOnly: cg.lexicalOnly, severity: cg.severity,
      riskLevel: cg.severity })
  }

  // --- rule nodes + class → rule edges ---
  var rules = []
  for (var rk in ruleAgg) {
    var rg = ruleAgg[rk]
    var cat = catalog[rg.id] || {}
    rules.push({ id: rg.id, title: _str(cat.title), severity: Labels.severity(cat.default_severity),
      language: _str(cat.language), occurrences: rg.occurrences, reviewItems: rg.reviewItems,
      hits: rg.occurrences + rg.reviewItems, plugins: Object.keys(rg.plugins).length,
      riskLevel: rg.severity !== "unknown" ? rg.severity : Labels.severityTier(cat.default_severity) })
  }
  var classRuleEdges = []
  for (var ek in edgeCR) {
    var eg = edgeCR[ek]
    classRuleEdges.push({ from: ["class", eg.cls], to: ["rule", eg.rid], w: eg.occ + eg.review,
      support: { parserBacked: eg.parserBacked, lexicalOnly: eg.lexicalOnly } })
  }

  // --- baseline nodes (map order) + rule → baseline edges ---
  var analyzedCount = 0
  for (var ac = 0; ac < plugins.length; ac++)
    if (plugins[ac].analysis === "analyzed") analyzedCount++

  var baseline = [], ruleBaselineEdges = []
  var ruleSet = {}
  for (var rs = 0; rs < rules.length; rs++) ruleSet[rules[rs].id] = true
  var classSet = {}
  for (var cs = 0; cs < classes.length; cs++) classSet[classes[cs].id] = true

  if (analyzedCount === 0) {
    baseline.push({ sentinel: true })
  } else if (cov) {
    var groups = {}, order = []
    var entries = _arr(cov.coverage)
    for (var g = 0; g < entries.length; g++) {
      var xid = _str(entries[g].externalId)
      if (xid === "") continue
      if (!groups[xid]) { groups[xid] = []; order.push(xid) }
      groups[xid].push(entries[g])
    }
    var nc = _arr(cov.not_covered).map(_str)
    for (var n2 = 0; n2 < nc.length; n2++)
      if (nc[n2] !== "" && !groups[nc[n2]]) { groups[nc[n2]] = [{ externalId: nc[n2], relation: "not-covered" }]; order.push(nc[n2]) }

    for (var o = 0; o < order.length; o++) {
      var oid = order[o], grp = groups[oid]
      var relation = _str(grp[0].relation)
      var viaRules = [], viaClasses = [], note = ""
      for (var gi = 0; gi < grp.length; gi++) {
        var orid = _str(grp[gi].omaRuleId)
        if (orid !== "" && viaRules.indexOf(orid) < 0) viaRules.push(orid)
        var ocap = _str(grp[gi].omaCapability)
        if (ocap !== "" && viaClasses.indexOf(ocap) < 0) viaClasses.push(ocap)
        if (_str(grp[gi].note) !== "") note = _str(grp[gi].note)
      }
      // Z1: keep only ids reachable from the scope plugin (a drawn rule or class).
      if (atPlugin) {
        var reachable = false
        for (var vr = 0; vr < viaRules.length; vr++) if (ruleSet[viaRules[vr]]) reachable = true
        for (var vc = 0; vc < viaClasses.length; vc++) if (classSet[viaClasses[vc]]) reachable = true
        if (!reachable) continue
      }
      baseline.push({ id: oid, relation: relation, viaRules: viaRules, viaClasses: viaClasses, note: note })
      // rule → baseline edges (only for drawn rules)
      for (var vr2 = 0; vr2 < viaRules.length; vr2++) {
        if (!ruleSet[viaRules[vr2]]) continue
        ruleBaselineEdges.push({ from: ["rule", viaRules[vr2]], to: ["baseline", oid], w: 1,
          coverageRelation: relation, dashed: relation === "partial-overlap" })
      }
    }
  } else {
    baseline.push({ sentinel: true })
  }

  var edges = edgePC.concat(classRuleEdges).concat(ruleBaselineEdges)
  return {
    scope: scope, filters: filters, lexicalOnlyCount: lexicalOnlyCount,
    plugins: plugins, classes: classes, rules: rules, baseline: baseline, edges: edges
  }
}
