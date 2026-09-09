#!/usr/bin/env node
// Node regression test for the pure posture view-model. Every ordering, grouping,
// count and sentence the Posture tab renders is decided in model/Posture.js
// precisely so it is reachable from here rather than only from a running shell.
//
// It runs against two captured real reports — `posture-v1.json` (this host, steady
// state) and `posture-two-run.json` (the second of two scans with one observable
// condition changed between them) — and against synthetic reports only for shapes this
// host cannot produce: a zero-check catalog, a forty-check catalog, and an unknown
// state word.
'use strict'

const fs = require('fs')
const vm = require('vm')
const path = require('path')

const root = path.join(__dirname, '..')
const source = fs.readFileSync(path.join(root, 'model/Posture.js'), 'utf8')
  .replace(/^\s*\.pragma\s+library\s*$/gm, '')
const sandbox = { Array, JSON, Number, Object, String, Math, Date, isFinite, console }
vm.createContext(sandbox)
vm.runInContext(source, sandbox, { filename: 'model/Posture.js' })

let checked = 0
function ok(condition, message) {
  checked++
  if (!condition) throw new Error('FAIL: ' + message)
}
function eq(actual, expected, message) {
  checked++
  if (actual !== expected)
    throw new Error('FAIL: ' + message + '\n  expected: ' + JSON.stringify(expected) +
      '\n  actual:   ' + JSON.stringify(actual))
}

function fixture(name) {
  return JSON.parse(fs.readFileSync(path.join(root, 'docs/design/fixtures', name), 'utf8'))
}

// -------------------------------------------------- the module is really pure
{
  // Strip comments before asserting purity, so prose about QML does not read as QML.
  const code = source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '')
  ok(!/^\s*import\s/m.test(code), 'Posture.js must have no QML import')
  ok(!/\bStyle\s*\./.test(code), 'Posture.js must not reference Style')
  ok(!/\bColor\s*\./.test(code), 'Posture.js must not reference Color')
  ok(!/\bQt\s*\./.test(code), 'Posture.js must not reference Qt')
}

// --------------------------------------------------- the captured real report
const real = sandbox.build(fixture('posture-v1.json'))
{
  ok(real.available, 'the captured report must build as available')
  eq(real.notYetRun, false, 'the captured report is not `not_yet_run`')
  eq(real.catalogVersion, 1, 'catalog version')
  eq(real.checkTotal, 18, 'the captured host reports 18 checks')

  // The distribution this host reports under omasafe-cli 0.3.1. Pending package and
  // Omarchy updates are `attention` now, not `regression` (CLI v0.3.1 D1): nothing
  // about the host got worse, it is behind.
  const counts = {}
  real.stateCounts.forEach(row => { counts[row.key] = row.count })
  eq(counts.pass, 5, 'pass count')
  eq(counts.informational, 7, 'informational count')
  eq(counts.regression, 0, 'no check reports a regression on this host')
  eq(counts.incomplete, 2, 'incomplete count')
  eq(counts.not_applicable, 2, 'not_applicable count')
  eq(counts.error, 0, 'error count')
  eq(counts.attention, 2, 'the two pending-update checks')
  eq(counts.unsupported, undefined, '`unsupported` is absent when it did not occur')

  // CH5: the parts reconcile to the total, and the printed line carries every term.
  const summed = real.stateCounts.reduce((n, row) => n + row.count, 0)
  eq(summed, real.checkTotal, 'state counts must sum to the check total')
  real.stateCounts.forEach(row => {
    ok(real.stateCountsText.indexOf(row.count + ' ' + row.label) >= 0,
      'the counts line must print `' + row.count + ' ' + row.label + '` (CH1/CH7)')
  })

  // CH8: attention order, exactly.
  eq(real.stateCounts.map(r => r.key).join(','),
    'error,regression,incomplete,attention,informational,pass,not_applicable',
    'state counts must be in attention order')

  // A3: the observation axis is a sentence, and the old count strip is gone.
  eq(real.coverageSentence,
    'Observation completed for 14 of 18 checks. 2 incomplete, 2 not applicable.',
    'coverage sentence')
  ok(real.coverageSentence.indexOf('14 COMPLETE') < 0, 'the string `14 COMPLETE` must not appear')

  // A4: the tools line names the missing tool AND its consequence.
  eq(real.tools.observed, 11, 'tools observed')
  eq(real.tools.total, 12, 'tools total')
  eq(real.tools.missing.join(','), 'arch-audit', 'the missing tool is named')
  eq(real.tools.impactedChecks, 1, 'one check is attributed to the missing tool')
  eq(real.tools.sentence,
    'Tools 11 of 12 observed · arch-audit unavailable, 1 check incomplete',
    'tools sentence')
  const audit = real.checks.find(c => c.id === 'vulnerabilities.arch_audit')
  eq(audit.missingDependencies.join(','), 'arch-audit', 'arch_audit is attributed to arch-audit')
  const firewall = real.checks.find(c => c.id === 'firewall.effective')
  eq(firewall.missingDependencies.length, 0,
    'a check whose declared tool IS available is not attributed to a missing tool')

  // A2: the items worth acting on are first, not scattered through an alphabet.
  eq(real.attention.length, 4, 'two incomplete + two pending-update checks')
  eq(real.attention.map(c => c.id).join(','),
    'firewall.effective,vulnerabilities.arch_audit,updates.omarchy,updates.repository',
    'attention order is exact: incomplete before attention, then id ascending')

  // Grouping and the strip.
  eq(real.groups.map(g => g.label).join(','),
    'BOOT,ENCRYPTION,EXECUTION,FIREWALL,HOST,KERNEL,NETWORK,PACKAGES,PERSISTENCE,SSH,UPDATES',
    'domains are the id prefix, upper-cased, sorted')
  eq(real.groups.reduce((n, g) => n + g.count, 0) + real.attention.length, 18,
    'every check is in exactly one of attention or a domain group')
  eq(real.groups.reduce((n, g) => n + g.count, 0), 14, 'fourteen checks sit under OBSERVED')
  // The strip follows the CLI's own catalog order now that 0.3.1 exports
  // `catalog_index`. That order is deliberate and NOT alphabetical, which is the whole
  // reason the field exists: sorted by id, cell 0 would be `boot.secure_boot`.
  eq(real.strip.length, 18, 'the strip has one cell per check')
  eq(real.strip[0].key, 'host.context', 'strip cell 0 is the catalog\'s first check')
  eq(real.strip[1].key, 'updates.repository', 'catalog order puts updates second')
  eq(real.strip[17].key, 'updates.post_update_hook', 'strip cell 17 is the catalog\'s last')
  ok(real.strip.map(c => c.key).join(',') !==
     real.checks.map(c => c.id).slice().sort().join(','),
    'catalog order differs from id order, or catalog_index bought nothing')
  eq(real.strip[1].tooltip, 'Repository package updates · ATTENTION', 'strip tooltip')

  // T9: every state in the attention set draws its own mark. `incomplete` in
  // particular must not draw severity high's `alert`, which is what it did before.
  eq(real.checks.find(c => c.id === 'firewall.effective').glyphKey, 'incomplete', 'incomplete glyph')
  eq(real.checks.find(c => c.id === 'updates.repository').glyphKey, 'medium', 'attention glyph')
  eq(sandbox.stateGlyphKey('regression'), 'alert', 'regression still maps to the alert mark')
  const attentionGlyphs = new Set(['error', 'regression', 'incomplete', 'attention']
    .map(sandbox.stateGlyphKey))
  eq(attentionGlyphs.size, 4, 'the four attention states draw four different marks')
  eq(real.checks.find(c => c.id === 'packages.integrity').glyphKey, 'not-applicable',
    'not_applicable glyph')

  // The collapsed row keeps a fact, not just a state word.
  eq(real.checks.find(c => c.id === 'packages.foreign').evidenceSummary,
    '13 foreign package(s) reported', 'one-fact summary from the first evidence string')
  eq(real.checks.find(c => c.id === 'firewall.effective').evidenceSummary, '',
    'a check with no evidence contributes no summary rather than a placeholder')

  eq(real.limitations.length, 5, 'the five overall coverage limitations are carried')
  eq(real.stale, real.ageSeconds >= 86400, 'stale is the 24 h threshold on the reported age')
}

// ------------------------------------------------------------- catalog order
// A strip cell position must mean the same check on every host and every run.
{
  // Whatever order the CLI emitted the array in, the strip comes back the same.
  const shuffled = fixture('posture-v1.json')
  shuffled.checks = shuffled.checks.slice().reverse()
  eq(sandbox.build(shuffled).strip.map(c => c.key).join(','),
    real.strip.map(c => c.key).join(','),
    'catalog order is stable regardless of emitted array order')
}
{
  // The CLI-supplied index wins over sorted id. Assigning it in reverse array order
  // must reverse the strip, which also proves the index is doing the ordering rather
  // than the array position happening to agree with it.
  const indexed = fixture('posture-v1.json')
  const byArray = indexed.checks.map(c => c.id)
  indexed.checks.forEach((c, i) => { c.catalog_index = indexed.checks.length - 1 - i })
  eq(sandbox.build(indexed).strip.map(c => c.key).join(','),
    byArray.slice().reverse().join(','),
    'a complete catalog_index defines the strip order')
}
{
  // ...but only when EVERY check carries one. A partial index would interleave two
  // orderings and move strip cells between runs, so it is ignored entirely.
  const partial = fixture('posture-v1.json')
  delete partial.checks[0].catalog_index
  eq(sandbox.build(partial).strip.map(c => c.key).join(','),
    partial.checks.map(c => c.id).slice().sort().join(','),
    'a partial catalog_index falls back to sorted id, wholesale')
}
{
  // A 0.3.0 report carries no index at all and must still build, in id order.
  const legacy = fixture('posture-v1.json')
  legacy.checks.forEach(c => { delete c.catalog_index })
  const model = sandbox.build(legacy)
  eq(model.strip.length, 18, 'a report with no catalog_index still builds')
  eq(model.strip.map(c => c.key).join(','),
    legacy.checks.map(c => c.id).slice().sort().join(','),
    'and falls back to sorted id')
}

// ------------------------------------------------------------------ not_yet_run
{
  const model = sandbox.build(fixture('posture-not-yet-run.json'))
  eq(model.notYetRun, true, 'not_yet_run is detected')
  eq(model.available, false, 'not_yet_run is not available')
  eq(model.strip.length, 0, 'not_yet_run renders no strip')
  eq(model.groups.length, 0, 'not_yet_run renders no groups')
  eq(model.attention.length, 0, 'not_yet_run renders no attention items')
  eq(model.stateCounts.length, 0, 'not_yet_run renders no counts')
  eq(model.coverageSentence, null, 'not_yet_run has no coverage sentence')
  eq(sandbox.chipSuffix(model), '–', 'not_yet_run yields `–`, never `0` and never a bare chip')
}

// ------------------------------------------------------------------ the chip
// The chip and the NEEDS ATTENTION section read the same array, so they cannot
// disagree in any fixture.
{
  eq(sandbox.chipSuffix(real), '4', 'the captured report yields `Posture 4`')
  eq(String(real.attention.length), sandbox.chipSuffix(real), 'chip equals the attention count')

  const clean = fixture('posture-v1.json')
  clean.checks.forEach(c => { c.state = 'pass' })
  clean.coverage = { complete: 18, incomplete: 0, errors: 0, not_applicable: 0, limitations: [] }
  const cleanModel = sandbox.build(clean)
  eq(sandbox.chipSuffix(cleanModel), '·', 'a run with an empty attention set yields `·`')
  eq(cleanModel.coverageSentence, 'Observation completed for 18 of 18 checks.',
    'a fully observed report has no trailing clause')

  // The trap this assertion exists for: `attention` is a routine-looking word and
  // must still reach the chip.
  const oneAttention = fixture('posture-v1.json')
  oneAttention.checks.forEach(c => { c.state = 'pass' })
  oneAttention.checks[3].state = 'attention'
  eq(sandbox.chipSuffix(sandbox.build(oneAttention)), '1',
    'a report whose only non-routine check is `attention` yields `Posture 1`, not `·`')

  eq(sandbox.chipSuffix(null), '–', 'a null model yields `–`')
}

// --------------------------------------------------------- an unknown state word
{
  const odd = fixture('posture-v1.json')
  odd.checks[0].state = 'quantum-entangled'
  const model = sandbox.build(odd)
  const row = model.stateCounts.find(r => r.key === 'unsupported')
  ok(row && row.count === 1, 'an unknown state maps to `unsupported` and is counted')
  eq(model.stateCounts.reduce((n, r) => n + r.count, 0), 18,
    'an unknown state is never dropped from the total')
  eq(model.checks.find(c => c.id === 'boot.secure_boot').stateWord, 'UNSUPPORTED',
    'an unknown state prints the unsupported word')
  ok(model.attention.some(c => c.id === 'boot.secure_boot'),
    'an unsupported state is in the attention set — the panel cannot rank what it cannot read')
}

// ----------------------------------------------------------- 0 and 40 checks
{
  const none = fixture('posture-v1.json')
  none.checks = []
  none.coverage = { complete: 0, incomplete: 0, errors: 0, not_applicable: 0, limitations: [] }
  const model = sandbox.build(none)
  eq(model.strip.length, 0, 'a zero-check report builds with an empty strip')
  eq(model.attention.length, 0, 'a zero-check report has no attention items')
  eq(model.coverageSentence, 'Observation completed for 0 of 0 checks.', 'zero-check sentence')

  const many = fixture('posture-v1.json')
  many.checks = Array.from({ length: 40 }, (_, i) => ({
    id: 'domain' + String(i % 5) + '.check' + String(i).padStart(2, '0'),
    title: 'Check ' + i, state: i % 7 === 0 ? 'incomplete' : 'pass',
    evidence: ['fact ' + i], limitations: [], dependencies: [], next_step: ''
  }))
  const wide = sandbox.build(many)
  eq(wide.strip.length, 40, 'a forty-check catalog builds')
  eq(wide.groups.length, 5, 'forty checks group into five domains')
  eq(wide.attention.length + wide.groups.reduce((n, g) => n + g.count, 0), 40,
    'forty checks are partitioned exactly once')
}

// -------------------------------------------------- T10 change and gap-age marks
//
// These now run against REAL captures. `omasafe-cli 0.3.1` exports `previous_state`
// and `gap_open_since`; `posture-two-run.json` is the second of two scans with one
// observable condition changed between them (a world-writable directory on PATH,
// which `execution.path` reads).
{
  // The steady-state capture: two scans a moment apart, nothing changed. EVERY check
  // reports a previous_state equal to its state and therefore renders NO mark.
  //
  // This is the shape the `previous_states` export bug produces for every check, and
  // on this fixture it is also the correct answer — which is exactly why it can never
  // be the only case tested. The two-run capture below is what tells them apart.
  eq(real.checks.filter(c => sandbox.changedFrom(c) !== '').length, 0,
    'a steady-state report renders no delta marks at all')
  ok(real.checks.every(c => c.previousState !== null),
    'and it does carry the field, so "no marks" is a finding and not an absence')

  const twoRun = sandbox.build(fixture('posture-two-run.json'))
  const deltas = twoRun.checks.filter(c => sandbox.changedFrom(c) !== '')
  eq(deltas.length, 1, 'the two-run capture renders EXACTLY ONE delta mark')
  eq(deltas[0].id, 'execution.path', 'and it is the check whose condition changed')
  eq(sandbox.changedFrom(deltas[0]), 'changed from pass', 'naming the previous state')
  eq(deltas[0].state, 'regression', 'a world-writable PATH entry is a real regression')
  eq(twoRun.checks.filter(c => c.previousState === c.state).length, 17,
    'the other seventeen carry previous_state === state and stay silent')

  // A first observation is null — a different claim from "unchanged" — and renders
  // nothing either.
  const first = fixture('posture-two-run.json')
  first.checks.forEach(c => { c.previous_state = null })
  const firstModel = sandbox.build(first)
  ok(firstModel.checks.every(c => c.previousState === null),
    'a first observation carries null, not the current state')
  eq(firstModel.checks.filter(c => sandbox.changedFrom(c) !== '').length, 0,
    'and renders nothing, never "new"')

  // gap_open_since, from the real capture.
  const gapped = real.checks.filter(c => c.gapOpenSince !== null)
  eq(gapped.length, 2, 'the two incomplete checks carry a gap start')
  ok(gapped.every(c => c.state === 'incomplete'),
    'and only checks in a coverage gap carry one')
  ok(gapped.every(c => /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(c.gapOpenSince)),
    'the CLI emits RFC-3339, not the bare unix seconds it used to store')
  ok(gapped.every(c => sandbox.gapAgeText(c) !== ''), 'and each renders an age')
  eq(sandbox.gapAgeText(real.checks.find(c => c.id === 'execution.path')), '',
    'a check with no gap renders nothing')
  eq(sandbox.gapAgeText({ gapOpenSince: 'not-a-timestamp' }), '',
    'an unparseable gap start renders nothing rather than a guess')
  eq(sandbox.gapAgeText({ gapOpenSince: null }), '', 'and so does an absent one')

  // Six days back, to pin the wording rather than depend on the capture's age.
  const opened = new Date(Date.now() - 6 * 86400000).toISOString().replace(/\.\d+Z$/, 'Z')
  eq(sandbox.gapAgeText({ gapOpenSince: opened }), 'open 6 days', 'six days reads `open 6 days`')

  // Compatibility: a 0.3.0 report has neither field and must render exactly as it did.
  const legacy = fixture('posture-v1.json')
  legacy.checks.forEach(c => { delete c.previous_state; delete c.gap_open_since })
  const legacyModel = sandbox.build(legacy)
  ok(legacyModel.checks.every(c => c.previousState === null && c.gapOpenSince === null),
    'a 0.3.0 report yields null for both fields')
  eq(legacyModel.checks.filter(c => sandbox.changedFrom(c) !== '').length, 0,
    'and renders no delta marks — never "no change", never an empty slot')
  eq(legacyModel.attention.length, real.attention.length,
    'and is otherwise identical to the 0.3.1 report')
}

// -------------------------------------------------------------- never infer
{
  const noCoverage = fixture('posture-v1.json')
  delete noCoverage.coverage
  const model = sandbox.build(noCoverage)
  eq(model.coverageSentence, null,
    'a report with no coverage block yields null, never a reconstructed sentence')
  eq(model.limitations.length, 0, 'no coverage block means no limitations')
  eq(model.checkTotal, 18, 'the checks still build without a coverage block')

  const noTools = fixture('posture-v1.json')
  delete noTools.tools
  const toolless = sandbox.build(noTools)
  eq(toolless.tools.sentence, '', 'no tools block yields no tools sentence')
  eq(toolless.tools.impactedChecks, 0, 'no tools block attributes nothing')

  // Unknown availability is not unavailability.
  const unknownTool = fixture('posture-v1.json')
  unknownTool.tools = unknownTool.tools.map(t => (t.name === 'arch-audit' ? { name: t.name } : t))
  const unknownModel = sandbox.build(unknownTool)
  eq(unknownModel.tools.missing.length, 0, 'a tool with no stated availability is not "missing"')
  eq(unknownModel.tools.observed, 11, 'and it is not counted as observed either')
  eq(unknownModel.tools.total, 12, 'but it still counts toward the declared total')

  eq(sandbox.build(null).available, false, 'a null report builds as unavailable')
  eq(sandbox.build({ schema: 'something.else.v1' }).available, false, 'a foreign schema is rejected')
}

// ------------------------------------------------------------- display safety
{
  const nasty = fixture('posture-v1.json')
  nasty.checks[0].evidence = ['a\r\nb\t‎‏  ']
  eq(sandbox.build(nasty).checks.find(c => c.id === 'boot.secure_boot').evidence[0],
    'a\\r\\nb\\t\\u{200e}\\u{200f}\\u{2028}\\u{2029}',
    'evidence escaping neutralizes line and directional controls')
}

// ------------------------------------------------------------- bar tooltip line
{
  ok(sandbox.barTooltipLine(real).indexOf('Host posture: 2 incomplete, 2 attention') === 0,
    'the bar tooltip uses the same words as the tab')
  eq(sandbox.barTooltipLine(sandbox.build(fixture('posture-not-yet-run.json'))),
    'Host posture: no scan has completed yet', 'not_yet_run tooltip line')
  eq(sandbox.barTooltipLine(null), '', 'a null model contributes no tooltip line')
}

// -------------------------------------------------- T7 cursor index spaces
//
// A section's count is its number of SELECTABLE TARGETS, not its number of rows on
// screen: moveCursorH() clamps selectedIndex to sectionCount() - 1, so a horizontal
// section declaring 1 pins the cursor on its first cell and makes every later cell
// unreachable. These assert the counts themselves rather than trusting a manual walk.
{
  // sectionCount("posture-strip") on this host.
  eq(real.strip.length, 18,
    'sectionCount("posture-strip") must be the number of selectable cells, 18 on this host')
  eq(real.attention.length, 4, 'sectionCount("posture-attention") on this host')

  // sectionCount("posture-observed") over the FLATTENED list: eleven domain headers
  // plus the fifteen checks under them.
  const rows = sandbox.observedRows(real, {})
  eq(rows.length, 11 + 14, 'sectionCount("posture-observed") counts headers AND checks')
  eq(rows.filter(r => r.kind === 'group').length, 11, 'one row per domain header')
  eq(rows.filter(r => r.kind === 'check').length, 14, 'one row per visible check')

  // Render order: every check row follows its own domain's header, never another's.
  let domain = null
  rows.forEach(row => {
    if (row.kind === 'group') { domain = row.domain; return }
    eq(row.check.domain, domain, 'a check row must follow its own domain header')
  })

  // Every row is reachable by its identity, and no two share an index.
  const seen = {}
  rows.forEach((row, i) => {
    const found = sandbox.rowIndex(rows, row.kind, row.kind === 'group' ? row.domain : row.id)
    eq(found, i, 'rowIndex must return the row\'s own position')
    ok(!seen[found], 'no two rows share a cursor index')
    seen[found] = true
  })

  // Collapsing a domain removes exactly its checks from the index space — the reason
  // this list, and not the model's groups, is what sectionCount counts.
  const packages = rows.filter(r => r.kind === 'check' && r.check.domain === 'PACKAGES').length
  const collapsed = sandbox.observedRows(real, { PACKAGES: true })
  eq(collapsed.length, rows.length - packages,
    'collapsing PACKAGES removes exactly its ' + packages + ' checks')
  eq(collapsed.filter(r => r.kind === 'group').length, 11, 'a collapsed domain keeps its header')
  eq(sandbox.rowIndex(collapsed, 'check', 'packages.keyring'), -1,
    'a check under a collapsed domain is not in the index space')
  eq(rows.filter(r => r.kind === 'check').length + real.attention.length, 18,
    'attention plus observed accounts for every check exactly once')

  eq(sandbox.observedRows(null, {}).length, 0, 'a null model has no rows')
  eq(sandbox.observedRows(sandbox.build(fixture('posture-not-yet-run.json')), {}).length, 0,
    'not_yet_run has no rows')
}

// -------------------------------------------------- T7 copy actions
{
  // The panel copies the backticked span the report printed, verbatim, and never
  // synthesises a command the CLI did not suggest.
  eq(sandbox.commandInStep('Run `omarchy update` after reviewing.'), 'omarchy update',
    'a backticked span is extracted verbatim')
  eq(sandbox.commandInStep('Install the official `arch-audit` package and retry.'), 'arch-audit',
    'a bare identifier is extracted as itself, not expanded into an install line')
  eq(sandbox.commandInStep('Review the root-device layout before changing settings.'), '',
    'a next step with no command yields no action')

  const actions = sandbox.copyActions(real)
  // Two, not four: `firewall.effective`'s next step names no command, and
  // `updates.repository` and `updates.omarchy` name the SAME one — two buttons
  // copying the same string is a row of noise, not a second affordance.
  eq(actions.length, 2, 'sectionCount("posture-actions") on this host')
  eq(actions.map(a => a.value).join(' | '), 'arch-audit | omarchy update',
    'copy actions are the attention set\'s commands, in attention order, deduped')
  eq(actions.map(a => a.checkId).join(' | '),
    'vulnerabilities.arch_audit | updates.omarchy', 'and they carry their check id')
  eq(actions[1].label, 'Copy command', 'a span with an argument is a command')
  eq(actions[0].label, 'Copy tool name', 'a bare identifier is a name, and says so')
  ok(actions[0].tooltip.indexOf('OmaSafe never runs it') >= 0,
    'the tooltip states that the panel never runs the command')
  eq(sandbox.copyActions(null).length, 0, 'a null model offers no copy actions')
}

// -------------------------------------------------- T7 finder
{
  eq(sandbox.search(real, '').length, 0, 'an empty query matches nothing')
  eq(sandbox.search(null, 'arch').length, 0, 'a null model matches nothing')
  const byTool = sandbox.search(real, 'arch-audit')
  ok(byTool.some(c => c.id === 'vulnerabilities.arch_audit'),
    'a finder query matches a check through its evidence and next step')
  const byState = sandbox.search(real, 'incomplete')
  ok(byState.length >= 2 && byState.slice(0, 2).every(c => c.state === 'incomplete'),
    'a state word finds both incomplete checks first')
  eq(byState[0].id, 'firewall.effective', 'finder results are in attention order')
  ok(sandbox.search(real, 'firewall').length >= 3, 'an id prefix matches its whole domain')
  ok(sandbox.search(real, 'ZZZZ-no-such-thing').length === 0, 'a non-matching query finds nothing')
  ok(sandbox.search(real, 'e').length <= 6, 'finder results are capped at six')
}

// -------------------------------------------------- T8 chip and bar tooltip
{
  // The chip vocabulary is 02 §2.4's, verbatim. `–` and `·` are different claims and
  // `0` is not one of the three.
  eq(sandbox.chipSuffix(sandbox.build(fixture('posture-not-yet-run.json'))), '–',
    'not_yet_run yields `–`, never `Posture 0` and never a bare `Posture`')
  eq(sandbox.chipSuffix(real), '4',
    'the captured report (2 incomplete + 2 attention) yields `Posture 4`')

  const clean = fixture('posture-v1.json')
  clean.checks.forEach(c => { c.state = 'pass' })
  eq(sandbox.chipSuffix(sandbox.build(clean)), '·', 'a run with an empty attention set yields `·`')

  // The trap: `attention` is a routine-looking word and must still reach the chip.
  const oneAttention = fixture('posture-v1.json')
  oneAttention.checks.forEach(c => { c.state = 'pass' })
  oneAttention.checks[0].state = 'attention'
  const oneModel = sandbox.build(oneAttention)
  eq(sandbox.chipSuffix(oneModel), '1',
    'a report whose only non-routine check is `attention` yields `Posture 1`, not `·`')
  eq(String(oneModel.attention.length), sandbox.chipSuffix(oneModel),
    'the chip count and NEEDS ATTENTION show the same number')

  // An error state is the loudest, and it counts too.
  const errored = fixture('posture-v1.json')
  errored.checks.forEach(c => { c.state = 'pass' })
  errored.checks[0].state = 'error'
  errored.checks[1].state = 'error'
  eq(sandbox.chipSuffix(sandbox.build(errored)), '2', 'errors reach the chip')

  // The bar tooltip line uses the tab's words and never carries a verdict.
  const tip = sandbox.barTooltipLine(real)
  ok(/^Host posture: 2 incomplete, 2 attention \(.+ old\)$/.test(tip),
    'the bar tooltip uses the tab\'s own words and its age: ' + tip)
  ok(tip.indexOf('secure') < 0 && tip.indexOf('safe') < 0 && tip.indexOf('%') < 0,
    'the bar tooltip carries no verdict, grade or percentage')
  ok(sandbox.barTooltipLine(sandbox.build(clean)).indexOf('nothing needs attention') >= 0,
    'a clean run says so in words, with its age')
  eq(sandbox.barTooltipLine(sandbox.build(fixture('posture-not-yet-run.json'))),
    'Host posture: no scan has completed yet',
    'not_yet_run says no scan has completed, never "clean"')
  eq(sandbox.barTooltipLine(null), '', 'no report contributes no line at all')
}

console.log('posture model: ok (' + checked + ' assertions)')
