// Labels.js — the one closed-enum → label map for the OmaSafe panel (doc 02 §3.4,
// §3.3). Every enum gate and its label text lives here so no view re-implements it.
//
// Fail-closed rule (GR3): an enum value outside its closed list returns
// "unsupported" (quoting the raw value) and is still counted by the caller — it is
// never dropped. A missing value renders "unavailable". A pure JS module: it never
// calls into QML, so gate/level helpers take their inputs as parameters.
.pragma library

// ---- the closed-enum primitive -------------------------------------------------

// value if it is a member of `allowed`, else "unsupported". The single gate every
// other function is built on.
function gate(value, allowed) {
  var text = String(value === null || value === undefined ? "" : value)
  return allowed.indexOf(text) >= 0 ? text : "unsupported"
}

function _quote(value) { return '"' + String(value === null || value === undefined ? "" : value) + '"' }

// ---- classification (doc 02 §3.4) ---------------------------------------------

function classification(value, classificationReason) {
  switch (String(value || "")) {
    case "Git-managed":  return "Git checkout"
    case "built-in":     return "Installed without git"
    case "cloned/local": return "Installed without git (local copy)"
    case "backup":       return "Backup copy (not scanned)"
    case "unscannable":  return "Unscannable: " + String(classificationReason || "")
    default:             return "Unsupported classification: " + _quote(value)
  }
}

// first_party is its own fact line, never folded into classification.
function firstParty(value) {
  if (value === true) return "First-party: yes"
  if (value === false) return "First-party: no"
  return "First-party: not stated"
}

// ---- marketplace / catalog (doc 02 §3.4, P2) ----------------------------------

function marketplaceStatus(status) {
  switch (String(status || "")) {
    case "listed":            return "Listed in catalog snapshot"
    case "installed-differs": return "Listed; installed commit is not the listed commit"
    case "unlisted":          return "Not in catalog snapshot"
    case "conflict":          return "Catalog entry not matched: installed repository conflicts with the listing or is unavailable"
    case "incomplete":        return "Catalog entry incomplete"
    default:                  return "Unsupported catalog status: " + _quote(status)
  }
}

function marketplaceStatusShort(status) {
  switch (String(status || "")) {
    case "listed":            return "Listed in snapshot"
    case "installed-differs": return "Listed; not at listed commit"
    case "unlisted":          return "Not in snapshot"
    case "conflict":          return "Catalog entry not matched"
    case "incomplete":        return "Catalog entry incomplete"
    default:                  return "Unsupported catalog status: " + _quote(status)
  }
}

// registry_claim.verification_status — always prefixed "Catalog says:", and only
// this field is (P2). Never a bare enum word.
function verificationStatus(value) {
  if (value === null || value === undefined) return "Catalog says: not stated"
  switch (String(value)) {
    case "verified":   return "Catalog says: verified"
    case "unverified": return "Catalog says: unverified"
    default:           return "Catalog says: " + _quote(value)
  }
}

function upstreamMoved(value) {
  if (value === true) return "Upstream has moved past the validated commit"
  if (value === false) return "Upstream still at the validated commit"
  return "Upstream movement not stated"
}

function installedMatchesListing(value) {
  if (value === true) return "Installed commit is the listed commit"
  if (value === false) return "Installed commit is not the listed commit"
  return "Listing commit not stated"
}

function marketplaceSource(value) {
  switch (String(value || "")) {
    case "pinned-fetch":     return "pinned fetch, snapshot integrity verified"
    case "unverified-cache": return "cached snapshot, not re-verified"
    case "local-file":       return "local catalog file"
    default:                 return "snapshot unavailable"
  }
}

// ---- trust baseline (doc 02 §3.3, §3.2) ---------------------------------------
// The trust state is the CLI comparison; "matches"/"differs" are reserved words
// (never used in a marketplace label). `state` is plugins-status `state`; `reason`
// disambiguates the two untrusted forms; `nFiles` is the changed-file count.

function _revoked(reason) {
  return String(reason || "").toLowerCase().indexOf("revok") >= 0
}

// Long form (detail sheet).
function trustState(state, reason, nFiles) {
  switch (String(state || "")) {
    case "untrusted":
      return _revoked(reason)
        ? "Baseline revoked; record a new one to resume drift reports"
        : "No trust baseline recorded"
    case "unchanged": return "Installed source matches the baseline you recorded"
    case "partial":   return "Matches the baseline; coverage is limited (see COVERAGE)"
    case "changed":   return "Installed source differs from the baseline · " + Number(nFiles || 0) + " files changed"
    default:          return "Baseline status unavailable: " + String(reason || "")
  }
}

// Short form (plugin row / bar).
function trustShort(state, reason, nFiles) {
  switch (String(state || "")) {
    case "untrusted": return _revoked(reason) ? "baseline revoked" : "no baseline"
    case "unchanged": return "matches baseline"
    case "partial":   return "matches · coverage limited"
    case "changed":   return "differs · " + Number(nFiles || 0) + " files"
    default:          return "unavailable"
  }
}

// ---- capability class names / kinds / counts ----------------------------------

// Human name of a capability class (doc 03 §5.2, the strip tooltip and ClassRow).
// The catalog keys are hyphen-joined; the readable name is the words. Glyphs.js
// owns the glyph and the catalog order; this owns the words only.
function capability(cls) {
  var s = String(cls || "")
  if (s === "") return "unsupported"
  return s.replace(/-/g, " ")
}

// Plugin kind for the hero meta (kit uppercases). Hyphen-joined → words.
function kind(value) {
  var s = String(value || "")
  return s === "" ? "" : s.replace(/-/g, " ")
}

// Review-item count, short form (plugin row / LOCAL HITS): `1 item` / `<n> items`
// (tooltip word: review items). The long form `<n> review items` is the
// detail-sheet header only.
function reviewCount(n) {
  var v = Number(n || 0)
  return v === 1 ? "1 item" : v + " items"
}

function reviewCountLong(n) {
  var v = Number(n || 0)
  return v === 1 ? "1 review item" : v + " review items"
}

// Occurrence count, long form (class rows, LOCAL HITS second line).
function occurrences(n) {
  var v = Number(n || 0)
  return v === 1 ? "1 occurrence" : v + " occurrences"
}

// ---- coverage / analysis evidence (doc 02 §3.4) -------------------------------

function coverageState(value) {
  switch (String(value || "")) {
    case "analyzed":     return "analyzed"
    case "partial":      return "partially analyzed"
    case "skipped":      return "skipped"
    case "truncated":    return "truncated"
    case "unsupported":  return "not analyzable"
    case "unreferenced": return "nothing observed"
    default:             return "unsupported"
  }
}

// confidence: names the evidence source, never "high"/"low".
function confidence(value) {
  if (value === null || value === undefined) return "no parser"
  switch (String(value)) {
    case "ast-backed":        return "parser-backed"
    case "lexical-fallback":  return "text match only"
    default:                  return "unsupported"
  }
}

// severity: the word, else unsupported (a rule default or an alert severity).
function severity(value) {
  return gate(String(value || "").toLowerCase(),
    ["info", "low", "medium", "high", "critical", "warning", "error"])
}

// relation (coverage map): the sentence, never a bare enum.
function relation(value) {
  switch (String(value || "")) {
    case "structural-equivalent": return "Equivalent check"
    case "partial-overlap":       return "Partially covered"
    case "not-covered":           return "Not covered by OmaSafe"
    default:                      return "Unsupported relation: " + _quote(value)
  }
}

// ---- enforcement (doc 02 §3.4, 03 §5.4) ---------------------------------------

// header right value, uppercased by the caller.
function evaluationState(value) {
  return gate(value, ["evaluated", "not-evaluated"])
}

// The two-sentence empty state when decision is null (never "allowed").
var enforcementNull = "No decision has been recorded. A decision exists only after a gated enable or reviewed update."

// A recorded decision's outcome line. reasonCodes is the array of reason codes.
function enforcementOutcome(outcome, basis, reasonCodes, expiresAt) {
  var o = gate(outcome, ["allow", "block"])
  if (o === "block") {
    var codes = (reasonCodes || []).map(function(c) { return String(c).replace(/-/g, " ") }).join(" · ")
    return "Blocked: " + codes
  }
  if (o === "allow") {
    var b = gate(basis, ["policy", "override"])
    if (b === "override") return "Allowed by override · expires " + String(expiresAt || "")
    if (b === "policy") return "Allowed by policy"
    return "Allowed by policy"
  }
  return "unsupported"
}

// ---- policy definition lines (sheet ButtonGroup, doc 02 §3.7, 03 §10) ---------
// Named exactly as the sheet references them; never interchanged.

// enable and review update.
function enforcementPolicy() {
  return "Advisory reports and proceeds; hardened may refuse."
}

// schedule (both policies report only).
function schedulePolicy() {
  return "Advisory runs scan --notify --only-new; hardened adds --include-analysis. Both report only."
}

// ---- schedule status row (doc 02 §3.4) ----------------------------------------

function scheduleStatus(policy) {
  switch (gate(policy, ["advisory", "hardened"])) {
    case "advisory": return "Advisory: daily drift scan, reports only"
    case "hardened": return "Hardened: daily drift scan with analysis, reports only"
    default:         return "unsupported"
  }
}

// enable/refusal renders EnableResult.policy verbatim.
function enforcementPolicyStatus(value) {
  return gate(value, ["advisory", "hardened"])
}

// ---- scan alert kinds (doc 02 §3.3, alertKind) --------------------------------

function alertKind(kind) {
  switch (String(kind || "")) {
    case "source-drift":            return "Source differs from baseline"
    case "missing-plugin":          return "Recorded plugin is missing"
    case "lost-coverage":           return "Coverage lost"
    case "bar-replacement":         return "Third-party bar replaces the OmaSafe widget"
    case "provenance-conflict":     return "Repository conflicts with catalog"
    case "new-capability":          return "New capability class observed"
    case "finding-regression":      return "New review item"
    case "analyzer-policy-update":  return "Analyzer policy changed; re-evaluated"
    case "analyzer-improvement":    return "Results changed under unchanged source"
    case "fingerprint-instability": return "Analysis was not deterministic; review required"
    default:                        return "Unsupported alert kind: " + _quote(kind)
  }
}

// alert row urgent only for critical/error severity.
function alertIsUrgent(sev) {
  var s = String(sev || "").toLowerCase()
  return s === "critical" || s === "error"
}

// ---- override status (doc, existing gate) -------------------------------------

function overrideStatus(value) {
  return gate(value, ["active", "expired"])
}

// ---- limitation codes (doc 02 §3.4, four grammars) ----------------------------
// The parser tests the known-code prefixes of grammars (2), (3) and (4) first and
// falls back to the file grammar (1) only for an unknown kind, because a
// <code>:<value> code read under (1) would print its value as a file name.

// (3) bare codes with no file segment — known analysis-limit codes, verbatim.
var _bareCodes = [
  "analysis_time_budget_exhausted", "time_budget_exhausted", "file_limit_exceeded",
  "aggregate_byte_limit_reached", "tree_depth_limit_exceeded",
  "directory_entry_limit_exceeded", "symlink_target_truncated",
  "staged-script-analysis-budget-exhausted"
]

// (1) file-grammar kind labels, grouped per file. `sink-reference-rejected` carries a
// sub-classifier (absolute / remote / unsupported-scheme / missing-local-target); the
// CLI emits it singular (omasafe-analyzer/src/detect.rs:338), and missing-local-target
// reads as its own phrase, matching the design output
// `5 sink references rejected (absolute) · 8 missing local target`.
function _fileKindLabel(kind, sub) {
  switch (kind) {
    case "sink-reference-rejected":
      return sub === "missing-local-target"
        ? "missing local target"
        : "sink references rejected" + (sub ? " (" + sub + ")" : "")
    case "dataflow-assignment-depth-limit":
      return "dataflow depth limit reached"
    default:
      return String(kind || "").replace(/-/g, " ")
  }
}

// Parse one code into { group, text }. group ∈ {"analysis", "suppressions",
// "truncation", "file", "unsupported"}; file entries also carry { file }.
function parseLimitation(code) {
  var raw = String(code || "")

  // (2) truncation marker.
  if (raw.indexOf("sink-reference-rejections-truncated:") === 0) {
    var n = raw.slice("sink-reference-rejections-truncated:".length)
    return { group: "truncation", text: n + " further sink-reference rejections not listed" }
  }

  // (3) bare known codes.
  if (_bareCodes.indexOf(raw) >= 0) {
    return { group: "analysis", text: raw }
  }

  // (4) <code>:<value> suppression / equivalence codes (value may contain colons).
  if (raw.indexOf("suppressions-unreadable:") === 0) {
    return { group: "suppressions", text: "Suppressions unreadable: " + raw.slice("suppressions-unreadable:".length) }
  }
  if (raw.indexOf("suppression-reconfirmation-required:") === 0) {
    return { group: "suppressions", text: raw.slice("suppression-reconfirmation-required:".length) + " suppressions need reconfirmation" }
  }
  if (raw.indexOf("equivalence-map-stale:") === 0) {
    return { group: "suppressions", text: "Equivalence map stale: " + raw.slice("equivalence-map-stale:".length) }
  }

  // (1) file grammar: kind[:sub]:file[:line[:target]]. Grouped by file then kind.
  var parts = raw.split(":")
  if (parts.length >= 2) {
    // sink-reference-rejected:<sub>:<file>:<line>:<target> — the sub is a
    // classifier, the file is parts[2] (never the sub). Any other kind has the
    // file at parts[1].
    var kind = parts[0]
    var idx = 1
    var sub = ""
    if (kind === "sink-reference-rejected" && parts.length >= 3) {
      sub = parts[1]; idx = 2
    }
    var file = parts[idx] || ""
    if (file !== "") {
      return { group: "file", file: file, text: _fileKindLabel(kind, sub) }
    }
  }

  // Anything else: verbatim + unsupported limitation.
  return { group: "unsupported", text: raw + " (unsupported limitation)" }
}

// Group a codes array into display lines (doc 02 §3.4). File-grammar entries group
// by file, joining their kind labels with " · "; the bare/known groups render under
// their own heading. Returns an array of strings.
function groupLimitations(codes) {
  if (!Array.isArray(codes)) return ["Coverage unavailable"]
  var files = {}        // file -> { counts: {label:n}, order: [label] }
  var fileOrder = []
  var analysis = []
  var suppressions = []
  var truncation = []
  var unsupported = []
  for (var i = 0; i < codes.length; i++) {
    var p = parseLimitation(codes[i])
    if (p.group === "file") {
      if (!files[p.file]) { files[p.file] = { counts: {}, order: [] }; fileOrder.push(p.file) }
      var fg = files[p.file]
      if (fg.counts[p.text] === undefined) { fg.counts[p.text] = 0; fg.order.push(p.text) }
      fg.counts[p.text]++
    } else if (p.group === "analysis") { analysis.push(p.text) }
    else if (p.group === "suppressions") { suppressions.push(p.text) }
    else if (p.group === "truncation") { truncation.push(p.text) }
    else { unsupported.push(p.text) }
  }
  var lines = []
  for (var f = 0; f < fileOrder.length; f++) {
    var g = files[fileOrder[f]]
    var segs = []
    for (var l = 0; l < g.order.length; l++)
      segs.push(g.counts[g.order[l]] + " " + g.order[l])
    lines.push(fileOrder[f] + " · " + segs.join(" · "))
  }
  for (var t = 0; t < truncation.length; t++) lines.push(truncation[t])
  if (analysis.length > 0) lines.push("Analysis limits · " + analysis.join(" · "))
  if (suppressions.length > 0) lines.push("Suppressions and equivalence map · " + suppressions.join(" · "))
  for (var u = 0; u < unsupported.length; u++) lines.push(unsupported[u])
  return lines
}
