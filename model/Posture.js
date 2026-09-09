// Posture.js — pure view-model for `omasafe.posture.v1` (doc 08 §5.1, §5.2).
//
// Every ordering, grouping, count and sentence in the Posture tab is decided here,
// not in a QML binding, so all of it is reachable from `scripts/posture-test.js`.
// It mirrors `model/ViewModel.js` and `model/Candidate.js`: a pure module with no
// QML import and no `Style` / `Color` reference.
//
// The rules it owns:
//
//   Catalog order   `checks` sorted by id under a given `check_catalog_version`,
//                   or `catalog_index` where the CLI supplies it (08 C3). A strip
//                   cell position must mean the same check on every host and run.
//   Attention order error → regression → incomplete → attention → unsupported →
//                   informational → pass → not applicable.
//   Domain          the id prefix before the first `.`, upper-cased (08 D6).
//   Tool linkage    a check is attributed to a missing tool when a `dependencies[]`
//                   entry names a `tools[]` entry with `available: false`.
//
// **Never infer.** A missing field yields `null` and the view renders nothing —
// never a default, never a zero, never "no change". That is GR3 at the data layer,
// and it is why `coverageSentence` is null rather than reconstructed when the
// report carries no `coverage` block.
//
// `coverageSentence` is a SENTENCE and never a count strip. The old header read
// `14 COMPLETE · 2 INCOMPLETE · 2 N/A`, where `complete` means "observation
// succeeded" and includes the regression; a reader scanning that header reads
// "14 fine". Rendering the observation axis as prose is the deliberate fix.
.pragma library

var MAX_TEXT = 2048
var MAX_ITEMS = 256
var STALE_AFTER_SECONDS = 86400

function _arr(value) { return Array.isArray(value) ? value : [] }
function _obj(value) { return value && typeof value === "object" && !Array.isArray(value) ? value : null }
function _str(value) { return String(value === null || value === undefined ? "" : value) }
function _escapeDisplayControl(value) {
  return "\\u{" + value.charCodeAt(0).toString(16) + "}"
}

// Evidence is data, not instructions, and not markup. `Text.PlainText` covers markup;
// this covers the terminal and bidi controls that would otherwise let a package name
// or a path create invisible or stateful display text. Same treatment as Candidate.js.
function _display(value, limit) {
  var text = _str(value)
  text = text.replace(/[\r\n]/g, function(ch) { return ch === "\r" ? "\\r" : "\\n" })
    .replace(/\t/g, "\\t")
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f\u0080-\u009f]/g, _escapeDisplayControl)
    .replace(/[\u061c\u200e\u200f\u2028\u2029\u202a-\u202e\u2066-\u2069]/g, _escapeDisplayControl)
  return text.slice(0, limit || MAX_TEXT)
}

function _count(value) {
  return typeof value === "number" && isFinite(value) && value >= 0 && Math.floor(value) === value
    ? value : null
}

// ---------------------------------------------------------------- state ladder
//
// The order below IS the attention order. `unsupported` — a state word this panel
// does not recognise — sits at the tail of the attention block rather than among the
// routine states: the panel cannot rank what it cannot read, and GR3 forbids letting
// it sink into the collapsed body where it would read as routine. Doc 02 CH8's seven
// catalog states keep their relative order exactly.
var STATE_ORDER = [
  "error", "regression", "incomplete", "attention", "unsupported",
  "informational", "pass", "not_applicable"
]

// A state is "needs attention" when it is a fault, a change for the worse, a gap in
// observation, or a word the panel cannot interpret. This array is the ONE definition:
// the NEEDS ATTENTION section and the tab chip both read `build().attention`, so they
// cannot disagree.
var ATTENTION_STATES = ["error", "regression", "incomplete", "attention", "unsupported"]

var STATE_META = {
  "error":          { label: "error",          level: "critical",      glyph: "critical" },
  "regression":     { label: "regression",     level: "high",          glyph: "alert" },
  "incomplete":     { label: "incomplete",     level: "incomplete",    glyph: "incomplete" },
  "attention":      { label: "attention",      level: "medium",        glyph: "medium" },
  "unsupported":    { label: "unsupported",    level: "unknown",       glyph: "unsupported" },
  "informational":  { label: "informational",  level: "info",          glyph: "info" },
  "pass":           { label: "pass",           level: "healthy",       glyph: "healthy" },
  "not_applicable": { label: "not applicable", level: "not_applicable", glyph: "not-applicable" }
}

// An unrecognised state word is mapped to `unsupported` and COUNTED, never dropped
// (doc 02 §3.4). Dropping it would shrink the denominator and make the report look
// smaller than it is.
function normalizeState(state) {
  var key = _str(state).toLowerCase()
  return STATE_META[key] ? key : "unsupported"
}

function stateLabel(state) { return STATE_META[normalizeState(state)].label }
function stateLevel(state) { return STATE_META[normalizeState(state)].level }
function stateGlyphKey(state) { return STATE_META[normalizeState(state)].glyph }
function stateWord(state) { return stateLabel(state).toUpperCase() }
function isAttention(state) { return ATTENTION_STATES.indexOf(normalizeState(state)) >= 0 }

// ------------------------------------------------------------------- age words
//
// The wording is carried over verbatim from the view it replaces, so the stale
// notice reads exactly as it did before.
function ageText(seconds) {
  var age = _count(seconds)
  if (age === null) return "not reported"
  if (age < 60) return "less than 1 minute"
  if (age < 3600) return Math.floor(age / 60) + " minutes"
  if (age < 86400) return Math.floor(age / 3600) + " hours"
  return Math.floor(age / 86400) + " days"
}

function _plural(n, singular, plural) {
  return n + " " + (n === 1 ? singular : (plural || (singular + "s")))
}

// ---------------------------------------------------------------------- checks

function _domain(id) {
  var text = _str(id)
  var dot = text.indexOf(".")
  return (dot > 0 ? text.slice(0, dot) : text).toUpperCase()
}

// The collapsed row's right-aligned one-fact summary, so a collapsed check is still
// evidence and not a bare state word. It is the FIRST evidence string, bounded; a
// check with no evidence contributes nothing rather than a placeholder.
function _evidenceSummary(evidence) {
  if (!evidence.length) return ""
  return evidence[0].length > 64 ? evidence[0].slice(0, 63) + "…" : evidence[0]
}

function _check(raw, toolAvailability) {
  var value = _obj(raw) || {}
  var id = _display(value.id, 256)
  var state = normalizeState(value.state)
  var evidence = _arr(value.evidence).slice(0, MAX_ITEMS).map(function(item) {
    return _display(item, MAX_TEXT)
  })
  var limitations = _arr(value.limitations).slice(0, MAX_ITEMS).map(function(item) {
    return _display(item, MAX_TEXT)
  })
  var dependencies = _arr(value.dependencies).slice(0, 32).map(function(item) {
    return _display(item, 128)
  })
  var tool = _obj(value.tool)

  // Which of this check's declared dependencies were reported unavailable. A
  // dependency the report says nothing about is NOT counted as missing — absence of
  // a tools[] entry is absence of evidence, not evidence of absence.
  var missingDeps = []
  for (var i = 0; i < dependencies.length; i++) {
    if (toolAvailability[dependencies[i]] === false) missingDeps.push(dependencies[i])
  }

  return {
    id: id,
    domain: _domain(id),
    title: _display(value.title || id || "Unnamed check", 512),
    state: state,
    rawState: _display(value.state, 64),
    level: stateLevel(state),
    glyphKey: stateGlyphKey(state),
    stateWord: stateWord(state),
    stateLabel: stateLabel(state),
    attention: isAttention(state),
    evidence: evidence,
    evidenceSummary: _evidenceSummary(evidence),
    limitations: limitations,
    nextStep: _display(value.next_step, MAX_TEXT),
    observedAt: _display(value.observed_at, 64),
    toolName: tool ? _display(tool.name, 128) : "",
    toolAvailable: tool ? tool.available === true : null,
    dependencies: dependencies,
    missingDependencies: missingDeps,
    // Absent-safe CLI 0.3.1 fields (08 C1, C2). A missing field is null and the view
    // renders nothing — never "no change", never "new". See `changedFrom` below.
    previousState: (value.previous_state === null || value.previous_state === undefined)
      ? null : _display(value.previous_state, 64),
    gapOpenSince: (value.gap_open_since === null || value.gap_open_since === undefined)
      ? null : _display(value.gap_open_since, 64),
    catalogIndex: _count(value.catalog_index)
  }
}

// The delta sentence for a check, or "" when there is nothing to say. A previous
// state EQUAL to the current state yields "" — which is also what a CLI bug that
// exported today's `previous_states` map would produce for every check, so T10's
// acceptance requires a real two-run sequence and does not accept an all-equal
// fixture as a pass.
function changedFrom(check) {
  if (!check || check.previousState === null || check.previousState === "") return ""
  var previous = normalizeState(check.previousState)
  if (previous === check.state) return ""
  return "changed from " + stateLabel(previous)
}

// `open N days` for a check sitting in a coverage gap, or "" when the CLI did not
// say when the gap opened. Never a guess.
function gapAgeText(check, nowMs) {
  if (!check || !check.gapOpenSince) return ""
  var opened = Date.parse(check.gapOpenSince)
  if (isNaN(opened)) return ""
  var now = (nowMs === undefined) ? Date.now() : nowMs
  var days = Math.floor(Math.max(0, now - opened) / 86400000)
  if (days < 1) return "open today"
  return "open " + _plural(days, "day")
}

// -------------------------------------------------------------------- ordering

function _catalogOrder(checks) {
  // A CLI-supplied `catalog_index` is preferred, but only when EVERY check carries
  // one — a partial index would interleave two different orderings and silently move
  // strip cells between runs.
  var indexed = checks.length > 0
  for (var i = 0; i < checks.length; i++) {
    if (checks[i].catalogIndex === null) { indexed = false; break }
  }
  var ordered = checks.slice()
  ordered.sort(function(a, b) {
    if (indexed && a.catalogIndex !== b.catalogIndex) return a.catalogIndex - b.catalogIndex
    return a.id < b.id ? -1 : (a.id > b.id ? 1 : 0)
  })
  return ordered
}

function _attentionOrder(a, b) {
  var ra = STATE_ORDER.indexOf(a.state), rb = STATE_ORDER.indexOf(b.state)
  if (ra !== rb) return ra - rb
  return a.id < b.id ? -1 : (a.id > b.id ? 1 : 0)
}

// ----------------------------------------------------------------------- build

function _empty(extra) {
  var base = {
    ok: true,
    available: false,
    notYetRun: false,
    schema: "",
    catalogVersion: null,
    generatedAt: "",
    ageSeconds: null,
    ageText: "not reported",
    stale: false,
    lastObservedPostUpdateHook: "",
    host: [],
    checks: [],
    strip: [],
    stateCounts: [],
    stateCountsText: "",
    checkTotal: 0,
    coverage: null,
    coverageSentence: null,
    tools: null,
    attention: [],
    groups: [],
    limitations: []
  }
  for (var key in (extra || {})) base[key] = extra[key]
  return base
}

function build(report) {
  var top = _obj(report)
  if (!top || _str(top.schema).indexOf("omasafe.posture.v") !== 0) return _empty()
  if (top.status === "not_yet_run") {
    return _empty({ available: false, notYetRun: true, schema: _display(top.schema, 64) })
  }

  var toolsInput = _arr(top.tools).slice(0, MAX_ITEMS)
  var toolAvailability = {}
  var toolNames = [], missingTools = [], observedTools = 0
  for (var t = 0; t < toolsInput.length; t++) {
    var tool = _obj(toolsInput[t]) || {}
    var name = _display(tool.name, 128)
    if (name === "") continue
    toolNames.push(name)
    if (tool.available === true) { toolAvailability[name] = true; observedTools++ }
    else if (tool.available === false) { toolAvailability[name] = false; missingTools.push(name) }
    // A tool whose availability the report does not state is left OUT of the map, so
    // `_check` attributes nothing to it. Unknown is not unavailable.
  }

  var raw = _arr(top.checks).slice(0, MAX_ITEMS)
  var checks = []
  for (var c = 0; c < raw.length; c++) checks.push(_check(raw[c], toolAvailability))
  checks = _catalogOrder(checks)

  // Strip cells in catalog order (CH8) — cell position is identity.
  var strip = []
  for (var s = 0; s < checks.length; s++) {
    strip.push({
      key: checks[s].id,
      glyphKey: checks[s].glyphKey,
      level: checks[s].level,
      tooltip: checks[s].title + " · " + checks[s].stateWord,
      checkIndex: s
    })
  }

  // State counts in attention order (CH8). Every catalog state is emitted with its
  // count including zero, because a chart that ran prints its zeros (CH7).
  // `unsupported` is emitted only when it actually occurred — it is not a catalog
  // state, and "0 unsupported" would imply the panel expects one.
  var counts = {}
  for (var k = 0; k < checks.length; k++) counts[checks[k].state] = (counts[checks[k].state] || 0) + 1
  var stateCounts = [], printed = []
  for (var o = 0; o < STATE_ORDER.length; o++) {
    var key = STATE_ORDER[o]
    var n = counts[key] || 0
    if (key === "unsupported" && n === 0) continue
    stateCounts.push({ key: key, label: STATE_META[key].label, count: n, level: STATE_META[key].level })
    printed.push(n + " " + STATE_META[key].label)
  }

  // Attention set, then everything else grouped by domain.
  var attention = [], remaining = []
  for (var a = 0; a < checks.length; a++) {
    if (checks[a].attention) attention.push(checks[a]); else remaining.push(checks[a])
  }
  attention.sort(_attentionOrder)

  var byDomain = {}, domainOrder = []
  for (var r = 0; r < remaining.length; r++) {
    var domain = remaining[r].domain
    if (!byDomain[domain]) { byDomain[domain] = []; domainOrder.push(domain) }
    byDomain[domain].push(remaining[r])
  }
  domainOrder.sort()
  var groups = []
  for (var g = 0; g < domainOrder.length; g++) {
    groups.push({
      domain: domainOrder[g],
      label: domainOrder[g],
      count: byDomain[domainOrder[g]].length,
      checks: byDomain[domainOrder[g]]
    })
  }

  // The observation axis, as prose (the fix for A3). Null rather than reconstructed
  // when the report carries no coverage block: never infer.
  var coverageRaw = _obj(top.coverage)
  var coverage = null, coverageSentence = null
  if (coverageRaw) {
    coverage = {
      complete: _count(coverageRaw.complete),
      incomplete: _count(coverageRaw.incomplete),
      errors: _count(coverageRaw.errors),
      notApplicable: _count(coverageRaw.not_applicable)
    }
    if (coverage.complete !== null) {
      var tail = []
      if (coverage.incomplete) tail.push(coverage.incomplete + " incomplete")
      if (coverage.errors) tail.push(_plural(coverage.errors, "error"))
      if (coverage.notApplicable) tail.push(coverage.notApplicable + " not applicable")
      coverageSentence = "Observation completed for " + coverage.complete + " of " +
        checks.length + " checks." + (tail.length ? " " + tail.join(", ") + "." : "")
    }
  }

  // The tools line is the fix for A4: count, name, and CONSEQUENCE in one sentence,
  // so a coverage gap arrives with its cause rather than unexplained.
  var impacted = 0
  for (var m = 0; m < checks.length; m++) if (checks[m].missingDependencies.length > 0) impacted++
  var toolSentence = ""
  if (toolNames.length > 0) {
    toolSentence = "Tools " + observedTools + " of " + toolNames.length + " observed"
    if (missingTools.length > 0) {
      toolSentence += " · " + missingTools.join(", ") + " unavailable"
      if (impacted > 0) toolSentence += ", " + _plural(impacted, "check") + " incomplete"
    }
  }

  var host = _obj(top.host) || {}
  var ageSeconds = _count(top.result_age_seconds)

  return _empty({
    available: checks.length > 0 || coverage !== null,
    notYetRun: false,
    schema: _display(top.schema, 64),
    catalogVersion: _count(top.check_catalog_version),
    generatedAt: _display(top.generated_at, 64),
    ageSeconds: ageSeconds,
    ageText: ageText(ageSeconds),
    stale: ageSeconds !== null && ageSeconds >= STALE_AFTER_SECONDS,
    lastObservedPostUpdateHook: _display(top.last_observed_post_update_hook, 256),
    host: [
      { label: "OS", value: _display(host.os || "unknown", 128) },
      { label: "ARCH", value: _display(host.arch || "unknown", 128) },
      { label: "OMARCHY", value: _display(host.omarchy_version || host.omarchy_path || "not observed", 256) },
      { label: "KERNEL", value: _display(host.kernel || "not observed", 128) },
      { label: "GENERATED", value: _display(top.generated_at, 64) },
      { label: "AGE", value: ageText(ageSeconds) }
    ],
    checks: checks,
    strip: strip,
    stateCounts: stateCounts,
    stateCountsText: printed.join(" · "),
    checkTotal: checks.length,
    coverage: coverage,
    coverageSentence: coverageSentence,
    tools: {
      observed: observedTools,
      total: toolNames.length,
      missing: missingTools,
      impactedChecks: impacted,
      sentence: toolSentence
    },
    attention: attention,
    groups: groups,
    limitations: _arr(coverageRaw ? coverageRaw.limitations : []).slice(0, MAX_ITEMS)
      .map(function(item) { return _display(item, MAX_TEXT) })
  })
}

// The tab chip's suffix (doc 08 §5.7), from the SAME array the NEEDS ATTENTION
// section renders, so the two can never disagree:
//   `–`  not run, unavailable, or the CLI is unverified
//   `·`  ran, and nothing needs attention
//   `N`  the attention count
// A chip with no count is a tab with no collector, never a clean tab.
function chipSuffix(model) {
  if (!model || !model.available || model.notYetRun) return "–"
  return model.attention.length > 0 ? String(model.attention.length) : "·"
}

// The bar tooltip's second line (doc 08 §5.8), in the same words as the tab, or ""
// when there is nothing observed to report. `alertCount` is unchanged (08 D3).
function barTooltipLine(model) {
  if (!model) return ""
  if (model.notYetRun) return "Host posture: no scan has completed yet"
  if (!model.available) return ""
  if (model.attention.length === 0) {
    return "Host posture: nothing needs attention (" + model.ageText + " old)"
  }
  var counts = {}, order = []
  for (var i = 0; i < model.attention.length; i++) {
    var key = model.attention[i].state
    if (!counts[key]) { counts[key] = 0; order.push(key) }
    counts[key]++
  }
  var parts = []
  for (var o = 0; o < order.length; o++) parts.push(counts[order[o]] + " " + STATE_META[order[o]].label)
  return "Host posture: " + parts.join(", ") + " (" + model.ageText + " old)"
}
