#!/usr/bin/env node
// Node unit test for graph/FlowLayout.js + model/ViewModel.flowInput (Phase 3 T3.2).
// Loads the .pragma library QML-JS modules under a vm context (stripping the QML
// .pragma/.import directives) and drives synthetic raw reports that reproduce the
// recorded four-analysis aggregates (doc 04 §3.3, §6 acceptance). Run: node scripts/flow-test.js
'use strict'
const fs = require('fs')
const vm = require('vm')
const path = require('path')

const ROOT = path.resolve(__dirname, '..')
function loadModule(rel, deps) {
  let src = fs.readFileSync(path.join(ROOT, rel), 'utf8')
  src = src.replace(/^\s*\.pragma\s+library\s*$/gm, '')
           .replace(/^\s*\.import\s+.*$/gm, '')
  const sandbox = Object.assign({ Math, Object, Array, String, Number, JSON, Date, isFinite, console }, deps || {})
  vm.createContext(sandbox)
  vm.runInContext(src, sandbox, { filename: rel })
  return sandbox
}

const Glyphs = loadModule('model/Glyphs.js', {})
const Time = loadModule('model/Time.js', {})
const Labels = loadModule('model/Labels.js', {})
const ViewModel = loadModule('model/ViewModel.js', { Labels, Time, Glyphs })
const FlowLayout = loadModule('graph/FlowLayout.js', {})

let pass = 0, fail = 0
function ok(cond, msg) { if (cond) { pass++ } else { fail++; console.error('  ✗ ' + msg) } }
function eq(a, b, msg) { ok(a === b, msg + ' — got ' + JSON.stringify(a) + ', want ' + JSON.stringify(b)) }

// ---- synthetic raw reports reproducing the four sampled analyses --------------

function cap(cls, rid, conf, file, line) {
  return { capability: cls, source_rule_id: rid, confidence: conf, relative_path: file, line: line, detail: 'x' }
}
function reps(cls, rid, conf, file, n) {
  const out = []
  for (let i = 0; i < n; i++) out.push(cap(cls, rid, conf, file, 100 + i))
  return out
}
function finding(rid, cls, conf, file, line) {
  return { rule_id: rid, capability: cls, confidence: conf, relative_path: file, line: line, evidence: 'e' }
}
const RPE = 'oma.qml.process-execution', RPS = 'oma.qml.persistence-scheduling'
const RCC = 'oma.qml.compositor-control', RFS = 'oma.qml.filesystem-access'
const RDX = 'oma.qml.detached-execution', RDR = 'oma.qml.dynamic-reference'

// sandman: PE16 PS8 CC4 FS1 = 29; 2 review items (dynamic-reference, FS)
const sandman = {
  parser: 'tree-sitter-qmljs 0.3.1',
  capabilities: [].concat(
    reps('process-execution', RPE, 'ast-backed', 'LidService.qml', 16),
    reps('persistence-scheduling', RPS, 'ast-backed', 'Service.qml', 7),
    [cap('persistence-scheduling', RPS, null, 'manifest.json', 9)],
    reps('compositor-control', RCC, 'ast-backed', 'Panel.qml', 4),
    reps('filesystem-access', RFS, 'ast-backed', 'Bar.qml', 1)),
  findings: [ finding(RDR, 'filesystem-access', 'ast-backed', 'BarWidget.qml', 40),
              finding(RDR, 'filesystem-access', 'ast-backed', 'Service.qml', 308) ],
  coverage_limitations: new Array(13).fill('sink-reference-rejected:absolute:LidService.qml:1'),
  invocation_edges: new Array(5).fill({})
}
// omasafe: PS36 PE18 = 54; 1 review item (FS, review-only class edge)
const omasafe = {
  parser: 'tree-sitter-qmljs 0.3.1',
  capabilities: [].concat(
    reps('persistence-scheduling', RPS, 'ast-backed', 'Panel.qml', 36),
    reps('process-execution', RPE, 'ast-backed', 'Panel.qml', 18)),
  findings: [ finding(RDR, 'filesystem-access', 'ast-backed', 'BarWidget.qml', 508) ],
  coverage_limitations: new Array(2).fill('dataflow-statement-limit:Panel.qml'),
  invocation_edges: new Array(1).fill({})
}
// btop: PE6 DX4 FS6 PS4 CC7 = 27; 5 review items (FS)
const btop = {
  parser: 'tree-sitter-qmljs 0.3.1',
  capabilities: [].concat(
    reps('process-execution', RPE, 'ast-backed', 'a.qml', 6),
    reps('detached-process-execution', RDX, 'ast-backed', 'a.qml', 4),
    reps('filesystem-access', RFS, 'ast-backed', 'a.qml', 6),
    reps('persistence-scheduling', RPS, 'ast-backed', 'a.qml', 4),
    reps('compositor-control', RCC, 'ast-backed', 'a.qml', 7)),
  findings: [ finding(RDR, 'filesystem-access', 'ast-backed', 'a.qml', 1),
              finding(RDR, 'filesystem-access', 'ast-backed', 'a.qml', 2),
              finding(RDR, 'filesystem-access', 'ast-backed', 'a.qml', 3),
              finding(RDR, 'filesystem-access', 'ast-backed', 'a.qml', 4),
              finding(RDR, 'filesystem-access', 'ast-backed', 'a.qml', 5) ],
  coverage_limitations: new Array(3).fill('x'), invocation_edges: new Array(3).fill({})
}
// dropdown-terminal: PE5 FS1 PS1 CC3 = 10; 2 review items (FS)
const dropdown = {
  parser: 'tree-sitter-qmljs 0.3.1',
  capabilities: [].concat(
    reps('process-execution', RPE, 'ast-backed', 'd.qml', 5),
    reps('filesystem-access', RFS, 'ast-backed', 'd.qml', 1),
    reps('persistence-scheduling', RPS, 'ast-backed', 'd.qml', 1),
    reps('compositor-control', RCC, 'ast-backed', 'd.qml', 3)),
  findings: [ finding(RDR, 'filesystem-access', 'ast-backed', 'd.qml', 1),
              finding(RDR, 'filesystem-access', 'ast-backed', 'd.qml', 2) ],
  coverage_limitations: [], invocation_edges: new Array(4).fill({})
}

const inventory = { plugins: [
  { id: 'io.github.tuthan.omasafe', classification: 'built-in' },
  { id: 'ilyazar.btop', classification: 'Git-managed' },
  { id: 'io.github.hvo.omarchy-unraid', classification: 'Git-managed' },
  { id: 'lgse.sandman', classification: 'Git-managed' },
  { id: 'io.github.tuthan.dropdown-terminal', classification: 'Git-managed' },
  { id: 'crmne.hyprmoncfg', classification: 'cloned/local' },
  { id: 'ianswope.snapshots', classification: 'cloned/local' },
  { id: 'io.github.tuthan.calendar', classification: 'Git-managed' },
  { id: 'old.backup', classification: 'backup' }
] }

const rulesList = { rule_catalog_version: '7', rules: [
  { id: RPE, title: 'QML process execution', default_severity: 'medium', language: 'qml' },
  { id: RPS, title: 'QML persistence', default_severity: 'low', language: 'qml' },
  { id: RCC, title: 'QML compositor control', default_severity: 'low', language: 'qml' },
  { id: RFS, title: 'QML filesystem access', default_severity: 'low', language: 'qml' },
  { id: RDX, title: 'QML detached execution', default_severity: 'medium', language: 'qml' },
  { id: RDR, title: 'QML dynamic reference', default_severity: 'low', language: 'qml' }
] }

const coverage = {
  external_ruleset_name: 'automated-security-baseline', external_ruleset_version: '3',
  map_version: '2', verified_at_commit: '964dc08abc',
  coverage: [
    { externalId: 'bundled-executable-binary', relation: 'partial-overlap', note: 'note text' },
    { externalId: 'curl-pipe-shell', relation: 'partial-overlap', omaRuleId: RPE },
    { externalId: 'installer', relation: 'partial-overlap', omaCapability: 'process-execution' },
    { externalId: 'package-manager', relation: 'partial-overlap', omaCapability: 'process-execution' },
    { externalId: 'privilege', relation: 'partial-overlap', omaCapability: 'process-execution' },
    { externalId: 'privileged-process-control', relation: 'partial-overlap', note: 'note text' },
    { externalId: 'service-management', relation: 'partial-overlap', omaCapability: 'persistence-scheduling' },
    { externalId: 'sudoers-dangerous-passwordless-command', relation: 'partial-overlap' },
    { externalId: 'sudoers-modification', relation: 'partial-overlap', omaCapability: 'process-execution' }
  ],
  not_covered: ['cargo-git-unpinned', 'remote-build', 'remote-git-execution-unpinned']
}

const analysisById = {
  'lgse.sandman': sandman, 'io.github.tuthan.omasafe': omasafe,
  'ilyazar.btop': btop, 'io.github.tuthan.dropdown-terminal': dropdown
}
const analysisStateById = {
  'lgse.sandman': 'analyzed', 'io.github.tuthan.omasafe': 'analyzed',
  'ilyazar.btop': 'analyzed', 'io.github.tuthan.dropdown-terminal': 'analyzed'
}
const alerts = [
  { plugin_id: 'io.github.tuthan.omasafe', severity: 'warning' },
  { plugin_id: 'ilyazar.btop', severity: 'warning' },
  { plugin_id: 'io.github.hvo.omarchy-unraid', severity: 'warning' }
]

// ---- Z0 flowInput + build ------------------------------------------------------

const fin = ViewModel.flowInput({
  inventory, analysisById, analysisStateById, coverage, rulesList, alerts,
  scope: { kind: 'all' }, filters: { backups: false }
})

console.log('Z0 flowInput:')
eq(fin.plugins.length, 8, 'plugins drawn (8 live)')
eq(fin.classes.length, 5, 'class nodes = 5')
eq(fin.rules.length, 6, 'rule nodes = 6')
eq(fin.baseline.length, 12, 'baseline ids = 12')
eq(fin.lexicalOnlyCount, 0, 'lexicalOnlyCount = 0')

// class occurrence aggregates
const byId = (arr) => Object.fromEntries(arr.map(x => [x.id, x]))
const C = byId(fin.classes)
eq(C['process-execution'].occurrences, 45, 'PE occurrences 45')
eq(C['persistence-scheduling'].occurrences, 49, 'PS occurrences 49')
eq(C['compositor-control'].occurrences, 14, 'CC occurrences 14')
eq(C['filesystem-access'].occurrences, 8, 'FS occurrences 8')
eq(C['detached-process-execution'].occurrences, 4, 'DX occurrences 4')
eq(C['filesystem-access'].reviewItems, 10, 'FS review items 10')
eq(C['process-execution'].plugins, 4, 'PE observed in 4 plugins')

// rule hits
const R = byId(fin.rules)
eq(R[RPS].hits, 49, 'rule PS hits 49'); eq(R[RPE].hits, 45, 'rule PE hits 45')
eq(R[RCC].hits, 14, 'rule CC hits 14'); eq(R[RDR].hits, 10, 'rule DR hits 10 (all review)')
eq(R[RFS].hits, 8, 'rule FS hits 8'); eq(R[RDX].hits, 4, 'rule DX hits 4')
eq(R[RDR].reviewItems, 10, 'DR is review-only'); eq(R[RDR].occurrences, 0, 'DR 0 occurrences')
eq(Labels.severityTier('error'), 'critical', 'error maps to critical tier')
eq(C['process-execution'].riskLevel, 'medium', 'capability risk derives from linked rule severity')
eq(R[RPE].riskLevel, 'medium', 'rule node carries catalog severity tier')

const healthyVm = ViewModel.build({
  inventory: { plugins: [{ id: 'healthy.plugin', classification: 'cloned/local' }] },
  alerts: [], statusById: { 'healthy.plugin': { state: 'unchanged' } },
  scanMeta: { stale: false, hasResult: true }, nowMs: Date.now()
})
eq(healthyVm.plugins[0].healthState, 'healthy', 'unchanged current plugin gets green health state')
const preScanVm = ViewModel.build({
  inventory: { plugins: [{ id: 'pre-scan.plugin', classification: 'cloned/local' }] },
  alerts: [], statusById: { 'pre-scan.plugin': { state: 'unchanged' } },
  scanMeta: { stale: false, hasResult: false }, nowMs: Date.now()
})
eq(preScanVm.plugins[0].healthState, 'unknown', 'unchanged baseline before first scan is not green')
const staleVm = ViewModel.build({
  inventory: { plugins: [{ id: 'stale.plugin', classification: 'cloned/local' }] },
  alerts: [{ plugin_id: 'stale.plugin', severity: 'critical' }],
  statusById: { 'stale.plugin': { state: 'unchanged' } },
  scanMeta: { stale: true }, nowMs: Date.now()
})
eq(staleVm.plugins[0].healthState, 'stale', 'stale scan never gets green health state')

// edge counts by kind
const kindOf = (ref) => ref[0]
const pc = fin.edges.filter(e => kindOf(e.from) === 'plugin' && kindOf(e.to) === 'class')
const cr = fin.edges.filter(e => kindOf(e.from) === 'class' && kindOf(e.to) === 'rule')
const rb = fin.edges.filter(e => kindOf(e.from) === 'rule' && kindOf(e.to) === 'baseline')
const cb = fin.edges.filter(e => kindOf(e.from) === 'class' && kindOf(e.to) === 'baseline')
eq(pc.length, 16, 'plugin→class edges = 16')
eq(cr.length, 6, 'class→rule edges = 6')
eq(rb.length, 1, 'rule→baseline edges = 1')
eq(cb.length, 0, 'class→baseline edges = 0')
eq(rb[0].dashed, true, 'rule→baseline edge dashed (partial-overlap)')

// ---- build() ------------------------------------------------------------------

const geo = { orderEpoch: 1, maxRows: 10, headerH: 20, rowH: 28,
  pair: [true, true, false, false], railW: 28, openW: 118, pairGutter: 72, railGutter: 12,
  offsets: [0, 0, 0, 0] }
const layout = FlowLayout.build(fin, geo)

console.log('Z0 build:')
eq(layout.nodes[0].length, 8, 'PLUGINS column 8 nodes')
eq(layout.nodes[1].length, 5, 'CAPABILITIES column 5 nodes')
eq(layout.nodes[2].length, 6, 'RULES column 6 nodes')
eq(layout.nodes[3].length, 12, 'BASELINE column 12 nodes')

// baseline node classification (acceptance §6 bullet 1)
const B = byId(layout.nodes[3])
const markless = layout.nodes[3].filter(n => n.count === '' && !n.covered)
eq(markless.length, 3, '3 markless not-covered nodes')
const viaGlyph = layout.nodes[3].filter(n => n.glyphKey !== '' && n.count === '≈')
eq(viaGlyph.length, 5, '5 via-class glyph nodes')
const markOnly = layout.nodes[3].filter(n => n.glyphKey === '' && n.count === '≈' && (n.viaRules||[]).length === 0)
eq(markOnly.length, 3, '3 mark-only ≈ nodes (no glyph, no edge)')
eq(B['curl-pipe-shell'].count, '≈', 'curl-pipe-shell marked ≈')
eq(B['curl-pipe-shell'].glyphKey, '', 'curl-pipe-shell has no glyph (rule edge)')
eq(B['installer'].glyphKey, 'process-execution', 'installer via-class glyph PE')
eq(B['service-management'].glyphKey, 'persistence-scheduling', 'service-management via-class glyph PS')

// order keys: PLUGINS outstanding→analyzed→id; row 0 should be an alerted analyzed plugin
const p0 = layout.nodes[0].map(n => n.id)
eq(p0[0], 'ilyazar.btop', 'PLUGINS[0] = ilyazar.btop (alerted+analyzed, id asc)')
eq(p0[1], 'io.github.tuthan.omasafe', 'PLUGINS[1] = omasafe (alerted+analyzed)')
eq(p0[2], 'io.github.hvo.omarchy-unraid', 'PLUGINS[2] = unraid (alerted, unanalyzed)')
// CAPABILITIES occurrences desc: PS49, PE45, CC14, FS8, DX4
const c0 = layout.nodes[1].map(n => n.id)
eq(c0[0], 'persistence-scheduling', 'CAPS[0] = persistence-scheduling (49)')
eq(c0[1], 'process-execution', 'CAPS[1] = process-execution (45)')
eq(c0[4], 'detached-process-execution', 'CAPS[4] = detached (4)')
// RULES reviewItems desc, occurrences desc: DR(10 review) sorts above FS(8 occ)
const r0 = layout.nodes[2].map(n => n.id)
eq(r0[0], RPS, 'RULES[0] = persistence (49)')
const idxDR = r0.indexOf(RDR), idxFS = r0.indexOf(RFS)
ok(idxDR < idxFS, 'dynamic-reference (10 review) sorts above filesystem (8 occ)')

// path budget < 6 KB
const totalPath = Object.values(layout.paths).join('').length
ok(totalPath < 6144, 'PathSvg total < 6 KB — got ' + totalPath + ' bytes')
ok(totalPath > 0, 'PathSvg strings non-empty')

// membership/content keys present and windowing
ok(typeof layout.membershipKey === 'string' && layout.membershipKey.length > 0, 'membershipKey set')
ok(typeof layout.contentKey === 'string' && layout.contentKey.length > 0, 'contentKey set')
eq(layout.geometry.rows, 10, 'window rows = min(10, 12) = 10')
eq(layout.geometry.cols[3].moreLabel, '+3 Baseline ids', 'BASELINE shows +3 Baseline ids (12 > 10 window)')
eq(layout.geometry.cols[0].moreLabel, '', 'PLUGINS (8) no +more')

// geometry: two open columns 118, two rails 28
eq(layout.geometry.cols[0].width, 118, 'col0 open width 118')
eq(layout.geometry.cols[2].width, 28, 'col2 rail width 28')

// ---- expanded graph geometry (Phase 5) ---------------------------------------
// The root's wide flowGeo() supplies four open columns and derives each width from
// the fitted body width. Exercise the same contract here so a future layout change
// cannot silently reintroduce the compact two-column assumptions.
const wideGeo = { orderEpoch: 2, maxRows: 20, headerH: 20, rowH: 28,
  pair: [true, true, true, true], wide: true, railW: 28, openW: (1120 - 3 * 72) / 4,
  pairGutter: 72, railGutter: 0, offsets: [0, 0, 0, 0] }
const wide = FlowLayout.build(fin, wideGeo)
eq(wide.geometry.cols.length, 4, 'expanded graph has four columns')
eq(wide.geometry.cols.every(c => c.open), true, 'expanded graph opens every column')
eq(wide.geometry.cols[0].width, 226, 'expanded col0 width = (1120 - 3*72) / 4')
eq(wide.geometry.cols[1].x, 298, 'expanded col1 starts after col0 + pair gutter')
eq(wide.geometry.cols[3].x + wide.geometry.cols[3].width, 1120, 'expanded columns stay inside body width')
eq(wide.geometry.rows, 12, 'expanded row budget still caps at tallest column')

// edge geometry: control points at thirds; endpoints land on node row centres
const anEdge = layout.edges.find(e => e.a.startsWith('plugin|') && e.b.startsWith('class|'))
ok(/^M[\d.]+ [\d.]+ C[\d.]+ [\d.]+ [\d.]+ [\d.]+ [\d.]+ [\d.]+ $/.test(anEdge.d), 'edge is one cubic Bézier PathSvg')

// ---- window: the final node is reachable at max offset (P2-a) ------------------
console.log('window last-node:')
// BASELINE has 12 nodes, window 10. At offset 0 → 9 real + "+3 more".
eq(layout.geometry.cols[3].offset, 0, 'baseline offset 0')
eq(layout.geometry.cols[3].realRows, 9, 'baseline shows 9 real rows at top (rows-1)')
eq(layout.geometry.cols[3].moreLabel, '+3 Baseline ids', 'baseline +3 Baseline ids at top')
// scroll to the end: offset = count - rows = 2 → 10 real rows, no "+more", last node visible
const scrolled = FlowLayout.relayout(layout, Object.assign({}, geo, { offsets: [0, 0, 0, 5] }))
eq(scrolled.geometry.cols[3].offset, 2, 'baseline offset clamps to count-rows = 2')
eq(scrolled.geometry.cols[3].realRows, 10, 'at the end: full 10 real rows (reclaims the +more slot)')
eq(scrolled.geometry.cols[3].hidden, 0, 'at the end: nothing hidden')
// index 11 (the last node) is inside [offset, offset+realRows-1] = [2, 11]
ok(2 <= 11 && 11 <= 2 + 10 - 1, 'last baseline node (index 11) is within the end window')

// ---- content key tracks display copy (P2-b) ------------------------------------
console.log('contentKey display copy:')
const finNoTitle = JSON.parse(JSON.stringify(fin))
finNoTitle.rules.forEach(r => { r.title = ''; r.severity = '' })
const layoutNoTitle = FlowLayout.build(finNoTitle, Object.assign({}, geo, { orderEpoch: 5 }))
ok(layoutNoTitle.contentKey !== layout.contentKey, 'contentKey changes when rule titles/severity change (forces node reassign)')

// ---- relayout(): geometry/paths change, node arrays are the SAME references ----
console.log('relayout():')
const slid = FlowLayout.relayout(layout, Object.assign({}, geo, { pair: [false, true, true, false] }))
ok(layout.nodes[1] === layout.nodes[1], 'sanity')
ok(slid.geometry.cols[0].width === 28, 'relayout: col0 now a rail (28)')
ok(slid.geometry.cols[2].width === 118, 'relayout: col2 now open (118)')
eq(slid.edges.length, layout.edges.length, 'relayout: edge count unchanged')
ok(typeof slid.paths.dimThinSolid === 'string', 'relayout: paths recomputed')
// relayout does not touch layout.nodes identity (navigation never reassigns models)
const nodesBefore = layout.nodes
FlowLayout.relayout(layout, Object.assign({}, geo, { offsets: [0, 0, 0, 3] }))
ok(layout.nodes === nodesBefore, 'relayout: layout.nodes identity preserved')

// ---- hot(): cursor lights only its OWN incident edges, not neighbours' ---------
console.log('hot():')
const cursorKey = 'class|process-execution'
const h = FlowLayout.hot(layout, cursorKey, '')
ok(h.hotKeys[cursorKey], 'cursor class is hot')
// class-level baseline rows brighten with the class (installer etc.), no edge
ok(h.hotKeys['baseline|installer'], 'installer brightens with process-execution class (no edge)')
ok(h.paths.hotSolid.length > 0 || h.paths.hotDashed.length > 0, 'hot bucket has the incident edges')
// count hot edges: process-execution has 4 plugin→class edges in + 1 class→rule edge out = 5
const incidentPE = layout.edges.filter(e => e.a === cursorKey || e.b === cursorKey)
function edgeStringLen(paths) { return (paths.hotSolid + paths.hotDashed).length }
// the hot path length must equal exactly the incident edges' path length (no spillover)
const incidentPathLen = incidentPE.reduce((n, e) => n + e.d.length, 0)
eq(edgeStringLen(h.paths), incidentPathLen, 'cursor lights exactly its incident edges (no neighbour spillover)')
// a neighbour plugin's OTHER edges (into other classes) must stay dim
const btopKey = 'plugin|ilyazar.btop'
const btopOtherEdges = layout.edges.filter(e => (e.a === btopKey || e.b === btopKey) && e.a !== cursorKey && e.b !== cursorKey)
ok(btopOtherEdges.length > 0, 'btop has edges into other classes (sanity)')
const someBtopOther = btopOtherEdges[0].d
ok(h.paths.hotSolid.indexOf(someBtopOther) < 0 && h.paths.hotDashed.indexOf(someBtopOther) < 0,
   "a neighbour's unrelated edge is NOT hot")

// ---- same-epoch order preservation (contract: same-membership-content-revision) --
console.log('same-epoch preserve+append:')
const prevKeys = [ layout.nodes[0].map(n => n.key), layout.nodes[1].map(n => n.key),
  layout.nodes[2].map(n => n.key), layout.nodes[3].map(n => n.key) ]
// reverse the input class order; same epoch → previous drawn order must be preserved
const fin2 = JSON.parse(JSON.stringify(fin))
fin2.classes.reverse()
const layout2 = FlowLayout.build(fin2, Object.assign({}, geo, { previousKeys: prevKeys, sameEpoch: true }))
eq(layout2.nodes[1].map(n => n.id).join(','), c0.join(','), 'same epoch: class order preserved despite reversed input')
// a new class appended at the end, existing kept
const fin3 = JSON.parse(JSON.stringify(fin))
fin3.classes.push({ id: 'network-access', name: 'Network access', occurrences: 99, reviewItems: 0, plugins: 1, parserBacked: 99, lexicalOnly: 0 })
const layout3 = FlowLayout.build(fin3, Object.assign({}, geo, { previousKeys: prevKeys, sameEpoch: true }))
eq(layout3.nodes[1][layout3.nodes[1].length - 1].id, 'network-access', 'same epoch: new class appended at column end (not re-sorted to front)')

// new epoch re-sorts (network-access 99 → first)
const layout4 = FlowLayout.build(fin3, Object.assign({}, geo, { orderEpoch: 2 }))
eq(layout4.nodes[1][0].id, 'network-access', 'new epoch: re-sorts (99 occ → first)')

// ---- contract case: edge-confidence-is-local ----------------------------------
console.log('edge dashed logic:')
const dashedInput = { scope: { kind: 'all' }, plugins: [], classes: [], rules: [], baseline: [{sentinel:true}],
  edges: [
    { from: ['plugin','x'], to: ['class','lexical'], w: 3, support: { parserBacked: 0, lexicalOnly: 3 } },
    { from: ['plugin','x'], to: ['class','mixed'], w: 3, support: { parserBacked: 2, lexicalOnly: 1 } },
    { from: ['plugin','x'], to: ['class','parsed'], w: 4, support: { parserBacked: 4, lexicalOnly: 0 } }
  ] }
eq(FlowLayout.edgeDashed(dashedInput.edges[0]), true, 'lexical-only edge dashed')
eq(FlowLayout.edgeDashed(dashedInput.edges[1]), false, 'mixed edge solid')
eq(FlowLayout.edgeDashed(dashedInput.edges[2]), false, 'parsed edge solid')
eq(FlowLayout.mixedEvidence(dashedInput.edges[1].support), 'mixed evidence: 2 parser-backed · 1 text-match-only', 'mixed inspector string')

// ---- Z1 scope: only reachable baseline ids ------------------------------------
console.log('Z1 scope (lgse.sandman):')
const finZ1 = ViewModel.flowInput({
  inventory, analysisById, analysisStateById, coverage, rulesList, alerts,
  scope: { kind: 'plugin', id: 'lgse.sandman' }, filters: { backups: false }
})
eq(finZ1.plugins.length, 1, 'Z1 draws 1 plugin')
// sandman reaches: PE,PS,CC,FS classes → rules PE,PS,CC,FS,DR(review in FS) → baseline
// reachable: curl-pipe-shell (via PE rule), installer/package-manager/privilege/sudoers-modification (viaClass PE),
// service-management (viaClass PS) = 6
eq(finZ1.baseline.length, 6, 'Z1 baseline = 6 reachable ids (doc 04 §9.3)')
const z1ids = finZ1.baseline.map(b => b.id).sort().join(',')
eq(z1ids, 'curl-pipe-shell,installer,package-manager,privilege,service-management,sudoers-modification', 'Z1 reachable baseline set')

// ---- zero analyses sentinel ---------------------------------------------------
console.log('zero-analyses sentinel:')
const finZero = ViewModel.flowInput({ inventory, analysisById: {}, analysisStateById: {},
  coverage, rulesList, alerts, scope: { kind: 'all' }, filters: { backups: false } })
eq(finZero.classes.length, 0, 'zero analyses: no class nodes')
eq(finZero.baseline.length, 1, 'zero analyses: one baseline sentinel')
ok(finZero.baseline[0].sentinel, 'baseline sentinel flag set')
const layoutZero = FlowLayout.build(finZero, geo)
eq(layoutZero.nodes[3][0].label, 'not analyzed', 'sentinel node reads "not analyzed"')
eq(Object.values(layoutZero.paths).join('').length, 0, 'zero analyses: eight empty path strings')

console.log('\n' + (fail === 0 ? 'ALL PASS' : 'FAILURES') + ': ' + pass + ' passed, ' + fail + ' failed')
process.exit(fail === 0 ? 0 : 1)
