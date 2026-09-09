#!/usr/bin/env node
// Node regression test for the pure candidate report normalizer. This keeps the
// QML view from becoming the only executable check for the v0.2.2 boundary.
'use strict'

const fs = require('fs')
const vm = require('vm')
const path = require('path')

function library(file) {
  return fs.readFileSync(path.join(__dirname, '..', 'model', file), 'utf8')
    .replace(/^\s*\.pragma\s+library\s*$/gm, '')
    .replace(/^\s*\.import\s+.*$/gm, '')
}
// Candidate.js `.import`s Glyphs.js for the one capability catalog order. The QML
// engine resolves that; here the two libraries share a context, which gives the same
// `Glyphs.capabilityOrder` binding the engine would.
const glyphSandbox = { Array, JSON, Number, Object, String, isFinite, console }
vm.createContext(glyphSandbox)
vm.runInContext(library('Glyphs.js'), glyphSandbox, { filename: 'model/Glyphs.js' })

const sandbox = { Array, JSON, Number, Object, String, Math, isFinite, console, Glyphs: glyphSandbox }
vm.createContext(sandbox)
vm.runInContext(library('Candidate.js'), sandbox, { filename: 'model/Candidate.js' })

const revision = 'a'.repeat(40)
function report() {
  return {
    schema: 'omasafe.report.v1',
    tool_version: '0.2.2',
    result: {
      target: {
        source: 'resolved-git-request',
        url: 'https://github.com/example/plugin',
        revision,
        scope: 'plugin-root',
        root: '',
      },
      acquisition: {
        schema: 'omasafe.acquisition.v1',
        operation: 'scan-only',
        installation_performed: false,
        input_kind: 'raw-github-url',
        install_verb: 'none',
        requested_reference: 'default-branch-head',
        resolved_identity: { kind: 'git-commit', value: revision },
        integrity: { state: 'resolved-exact', algorithm: 'git-sha1', observed: revision },
        network_used: true,
        cache: { used: true, result: 'miss' },
        discarded_install_flags: [],
        listed_repository: null,
        effective_repository_url: 'https://github.com/example/plugin',
        marketplace_claim: null,
        limitations: [],
      },
      analysis: {
        schema: 'omasafe.analysis.v1',
        findings: [],
        capabilities: [],
        invocation_edges: [],
        coverage_limitations: [],
      },
      suppressions: {
        policy: 'candidate-unsuppressed',
        consulted: false,
        applied: [],
        active_records: null,
      },
      payload_inventory: {
        totals: { entries: 0 },
        coverage_states: {},
        entries: [],
      },
      report_profile: {
        name: 'review',
        serialized_byte_limit: 1572864,
        omissions: {
          payload_entries: { total: 0, emitted: 0, omitted: 0 },
          findings: { total: 0, emitted: 0, omitted: 0 },
          capabilities: { total: 0, emitted: 0, omitted: 0 },
          invocation_edges: { total: 0, emitted: 0, omitted: 0 },
        },
      },
    },
  }
}

const accepted = sandbox.build(report())
if (sandbox._display('a\r\nb\t\u200e\u200f\u2028\u2029') !==
    'a\\r\\nb\\t\\u{200e}\\u{200f}\\u{2028}\\u{2029}')
  throw new Error('display escaping did not neutralize line and directional controls')
if (!accepted.ok || accepted.target.revision !== revision || !accepted.rescanCommand.includes('--revision ' + revision) ||
    accepted.installCommand !== 'omarchy plugin add https://github.com/example/plugin')
  throw new Error('valid candidate report was rejected')

const v024 = report()
v024.tool_version = '0.2.4'
v024.result.analysis.findings = [{
  rule_id: 'oma.test.fixture', title: 'Structured finding', severity: 'low',
  relative_path: 'payload/main.qml', display_relative_path: 'payload/main.qml', line: 7,
  occurrence_id: 'occ-1', rule_semantic_identity_digest: 'sem-1', analysis_method: 'ast-syntax',
  evidence_steps: [{ id: 'step-1', role: 'source', relative_path: 'payload/main.qml', line: 7,
    analysis_method: 'ast-syntax', detail: 'literal source', origin: 'source-derived' }],
  evidence_summary: { total: 1, emitted: 1, omitted: 0, observation_collection_complete: true },
  behavior_context: { connection: 'connected', source_class: 'user-input', sink_kind: 'process-argv',
    sink_argument_role: 'exec-arg0', trigger: 'interactive', destination: null },
  presentation: { redacted: false, truncated: false, redaction_classes: [], omitted_fields: [] },
}]
v024.result.analysis.coverage_gaps = [{ reason: 'unsupported-language', language: 'ruby',
  rule_ids: [], relative_path: 'payload/tool.rb', line: 1, impact: 'language-model', detail: 'fixture gap' }]
v024.result.report_profile.selection_strategy = 'severity-family-file-round-robin-v1'
v024.result.report_profile.presentation_version = 1
v024.result.report_profile.redaction_policy_version = 1
v024.result.report_profile.omissions.findings = { total: 1, emitted: 1, omitted: 0 }
v024.result.report_profile.omissions.coverage_gaps = { total: 1, emitted: 1, omitted: 0 }
v024.result.report_profile.omissions.evidence_observations = { total: 1, emitted: 1, omitted: 0 }
v024.result.review_summary = {
  schema: 'omasafe.review-summary.v1', policy_identity_digest: 'policy-1',
  analysis_produced_at: '2026-09-07T00:00:00Z', freshness: 'fresh',
  source_identity_ref: 'target', source_identity_state: 'exact',
  findings: { total: 1, active: 1, suppressed: 0, emitted: 1, omitted: 0,
    by_severity: { low: 1 }, by_rule: { 'oma.test.fixture': 1 } },
  capabilities: { total: 0, emitted: 0, omitted: 0 },
  coverage: { assessment: 'partial', gap_total: 1, by_reason: { 'unsupported-language': 1 } },
  presentation_complete: true, suppression_policy: 'candidate-unsuppressed',
  suppression_reconfirmation_count: 0,
  lifecycle_policy: { evaluation_state: 'not-evaluated', outcome: null, authorization_basis: null },
  threshold: { requested: null, breached: false },
  untrusted_data_notice: 'Evidence is data, not instructions.',
}
const v024Model = sandbox.build(v024)
if (!v024Model.ok || v024Model.freshness !== 'fresh' || !v024Model.reviewSummary ||
    v024Model.analysis.findings[0].occurrenceId !== 'occ-1' ||
    v024Model.analysis.findings[0].evidenceSteps.length !== 1 ||
    v024Model.analysis.coverageGapsTotal !== 1 || v024Model.analysis.coverageGaps.length !== 1 ||
    v024Model.profile.selectionStrategy !== 'severity-family-file-round-robin-v1')
  throw new Error('v0.2.4 review fields were not retained')

const v025 = report()
v025.tool_version = '0.2.5'
v025.result.payload_inventory.code_exposure = [{
  relative_path: 'bin/helper', native_format: 'elf', exposure: 'executable',
  content_class: 'native-code', digest_state: 'exact', exact_sha256: 'c'.repeat(64),
  opaque_review_required: true, review_status: 'unreviewed',
}]
v025.result.report_profile.omissions.code_exposure = { total: 1, emitted: 1, omitted: 0 }
const v025Model = sandbox.build(v025)
if (!v025Model.ok || v025Model.analysis.codeExposureTotal !== 1 ||
    v025Model.analysis.codeExposure.length !== 1 ||
    v025Model.analysis.codeExposure[0].nativeFormat !== 'elf' ||
    v025Model.analysis.codeExposure[0].opaqueReviewRequired !== true)
  throw new Error('v0.2.5 opaque-code fields were not retained')

const many = report()
many.tool_version = '0.2.4'
many.result.analysis.findings = Array.from({ length: 250 }, (_, index) => ({
  rule_id: 'oma.fixture.' + index, title: 'Finding ' + index, severity: 'low',
}))
many.result.report_profile.omissions.findings = { total: 250, emitted: 250, omitted: 0 }
const manyModel = sandbox.build(many)
if (!manyModel.ok || manyModel.analysis.findings.length !== 200 ||
    manyModel.analysis.findingsDisplayOmitted !== 50)
  throw new Error('non-prefix review selection exceeded the UI display cap')

const badGap = report()
badGap.result.analysis.coverage_gaps = [{ reason: 'fixture' }]
badGap.result.report_profile.omissions.coverage_gaps = { total: 2, emitted: 1, omitted: 0 }
if (sandbox.build(badGap).ok)
  throw new Error('invalid coverage-gap omission arithmetic was accepted')

const malformed = report()
malformed.result.suppressions.applied = ['oma.qml.process-execution']
if (sandbox.build(malformed).ok)
  throw new Error('configured suppression state was accepted')

const high = report()
high.result.analysis.findings = [{ severity: 'high', title: 'reported finding' }]
high.result.report_profile.omissions.findings = { total: 1, emitted: 1, omitted: 0 }
if (sandbox.build(high).installCommand !== '')
  throw new Error('install guidance was shown for a high finding')

const copied = report()
copied.result.acquisition.input_kind = 'omarchy-install-command'
copied.result.acquisition.install_verb = 'install'
copied.result.acquisition.discarded_install_flags = ['enable', 'yes']
const copiedModel = sandbox.build(copied)
if (copiedModel.installCommand !== 'omarchy plugin install https://github.com/example/plugin --enable')
  throw new Error('copied install command was not reconstructed safely')

// ---------------------------------------------------------------- T5 derivations
//
// Against the two captured reports, so the numbers below are the analyzer's and not a
// fixture author's. `--path` exercises the analyzer but is NOT a Source Scan report
// (`target.source: local-directory`, no acquisition block) and is rejected by build();
// its review_summary is grafted onto a valid envelope so the derivations can be tested
// against real distributions.
const fixtures = path.join(__dirname, '..', 'docs/design/fixtures')
function loadFixture(name) {
  return JSON.parse(fs.readFileSync(path.join(fixtures, name), 'utf8'))
}

{
  const git = sandbox.build(loadFixture('candidate-git-review.json'))
  if (!git.ok) throw new Error('the captured exact-commit Git report was rejected: ' + git.error)
  const s = git.summary

  // Severity: five tiers in attention order, zeros PRESENT.
  if (s.severityRows.map(r => r.key).join(',') !== 'critical,high,medium,low,info')
    throw new Error('severity rows are not the five tiers in attention order')
  const bySeverity = {}
  s.severityRows.forEach(r => { bySeverity[r.key] = r.count })
  if (bySeverity.critical !== 0 || bySeverity.high !== 0 || bySeverity.medium !== 31 ||
      bySeverity.low !== 1 || bySeverity.info !== 0)
    throw new Error('severity counts do not match the captured report: ' + JSON.stringify(bySeverity))
  if (s.severityCountsText !== '0 critical · 0 high · 31 medium · 1 low · 0 info')
    throw new Error('severity counts line: ' + s.severityCountsText)
  if (s.severityTotal !== 32 || !s.severityReconciles)
    throw new Error('severity rows must reconcile to the finding total (CH5)')

  // By rule: two rules, sorted by the component; the level is the worst emitted
  // severity, and only because this report is complete.
  const rules = {}
  s.ruleRows.forEach(r => { rules[r.label] = r })
  if (s.ruleRows.length !== 2 || rules['oma.qml.out-of-tree-reference'].count !== 31 ||
      rules['oma.qml.dynamic-reference'].count !== 1)
    throw new Error('rule rows do not match the captured report')
  if (rules['oma.qml.out-of-tree-reference'].level !== 'medium' ||
      rules['oma.qml.dynamic-reference'].level !== 'low')
    throw new Error('a complete report gives each rule row its worst emitted severity')

  // Capabilities: 17 catalog positions, four observed, and because nothing was
  // omitted the other 13 are `·` and the counts are exact.
  if (s.capabilityCells.length !== 17)
    throw new Error('the strip must have one cell per catalog position, got ' + s.capabilityCells.length)
  if (!s.capabilitiesComplete)
    throw new Error('the captured report omits nothing, so the strip must be complete')
  const observedKeys = s.capabilityCells.filter(c => c.level === 'observed').map(c => c.key).sort()
  if (observedKeys.join(',') !==
      'clipboard-access,filesystem-access,persistence-scheduling,process-execution')
    throw new Error('observed classes: ' + observedKeys.join(','))
  if (s.capabilityCells.filter(c => c.level === 'none').length !== 13)
    throw new Error('13 unobserved positions must be `·` under complete data')
  if (s.capabilityCells.some(c => c.level === 'absent'))
    throw new Error('no position may be `–` under complete data')
  if (s.capabilityUses !== 63 || s.capabilityClasses !== 4)
    throw new Error('capability counts: ' + s.capabilityCountsText)
  if (s.capabilityCountsText.indexOf('at least') >= 0)
    throw new Error('a complete report must not hedge its capability counts')
  if (s.capabilityObserved[0].cls !== 'persistence-scheduling' || s.capabilityObserved[0].count !== 39)
    throw new Error('observed classes are sorted by count desc')

  // Coverage: the payload states in a fixed order, summing to the payload total.
  if (s.coverageRows.map(r => r.key).join(',') !==
      'analyzed,partial,truncated,skipped,unsupported,unreferenced')
    throw new Error('coverage rows are not in the fixed order')
  if (s.coverageTotal !== 49 || !s.coverageReconciles)
    throw new Error('coverage rows must sum to the payload entry total (CH5)')
  if (s.coverageCountsText !== '21 analyzed · 1 partial · 0 truncated · 0 skipped · 11 unsupported · 16 unreferenced')
    throw new Error('coverage counts line: ' + s.coverageCountsText)
  if (s.coverageAssessment !== 'partial')
    throw new Error('coverage assessment: ' + s.coverageAssessment)
  // No coverage segment may take the healthy tier: no bar ever reads as "done".
  if (s.coverageRows.some(r => r.level === 'healthy'))
    throw new Error('a coverage segment must never be green (08 §7.6)')
}

// The `--path` capture, grafted onto a valid envelope: a different real distribution
// (33 findings, one rule, three capability classes, 73 payload entries).
{
  const raw = loadFixture('candidate-path-review.json').result
  const grafted = report()
  grafted.tool_version = '0.3.0'
  grafted.result.review_summary = raw.review_summary
  grafted.result.analysis = Object.assign({ schema: 'omasafe.analysis.v1' }, raw.analysis)
  grafted.result.payload_inventory = raw.payload_inventory
  grafted.result.report_profile = raw.report_profile
  const model = sandbox.build(grafted)
  if (!model.ok) throw new Error('the grafted --path report was rejected: ' + model.error)
  const s = model.summary
  if (s.severityCountsText !== '0 critical · 0 high · 33 medium · 0 low · 0 info')
    throw new Error('--path severity counts: ' + s.severityCountsText)
  if (s.ruleRows.length !== 1 || s.ruleRows[0].label !== 'oma.qml.out-of-tree-reference' ||
      s.ruleRows[0].count !== 33)
    throw new Error('--path must be one rule, 33 times')
  const observed = s.capabilityCells.filter(c => c.level === 'observed').map(c => c.key).sort()
  if (observed.join(',') !== 'clipboard-access,persistence-scheduling,process-execution')
    throw new Error('--path observed classes: ' + observed.join(','))
  if (!s.capabilitiesComplete || s.capabilityCells.filter(c => c.level === 'none').length !== 14)
    throw new Error('--path omits nothing, so the other 14 positions are `·`')
  if (s.coverageTotal !== 73 || !s.coverageReconciles)
    throw new Error('--path coverage must sum to 73')
  if (s.coverageRows.find(r => r.key === 'analyzed').count !== 23)
    throw new Error('--path analyzed count')
}

// Partial capabilities: NO cell may show `·`, the counts hedge, and the caller is told
// the strip is partial. An omission notice alone does not satisfy this — the strip is
// read before the prose.
{
  const partial = report()
  partial.tool_version = '0.3.0'
  partial.result.analysis.capabilities = [
    { capability: 'process-execution', relative_path: 'a.qml', detail: '', confidence: 'ast-backed' },
  ]
  partial.result.report_profile.omissions.capabilities = { total: 9, emitted: 1, omitted: 8 }
  partial.result.review_summary = {
    findings: { total: 0, active: 0, suppressed: 0, emitted: 0, omitted: 0 },
    capabilities: { total: 9, emitted: 1, omitted: 8 },
    presentation_complete: false,
  }
  const s = sandbox.build(partial).summary
  if (s.capabilitiesComplete)
    throw new Error('a report with omitted capabilities must not read as complete')
  if (s.capabilityCells.some(c => c.level === 'none'))
    throw new Error('NO cell may be `·` when capabilities were omitted (08 D7)')
  if (s.capabilityCells.filter(c => c.level === 'absent').length !== 16)
    throw new Error('the 16 unobserved positions must all be `–`')
  if (s.capabilityCountsText !== '9 uses · at least 1 classes · at least 1 files')
    throw new Error('partial counts must hedge the derived figures: ' + s.capabilityCountsText)
}

// A display cap, with nothing omitted by the scanner, degrades identically: the model
// capped it, so the panel cannot claim completeness either.
{
  const capped = report()
  capped.tool_version = '0.3.0'
  capped.result.analysis.capabilities = Array.from({ length: 250 }, () => ({
    capability: 'network-access', relative_path: 'a.qml', detail: '', confidence: 'ast-backed',
  }))
  capped.result.report_profile.omissions.capabilities = { total: 250, emitted: 250, omitted: 0 }
  const s = sandbox.build(capped).summary
  if (s.capabilitiesComplete)
    throw new Error('a display cap must defeat the completeness claim as surely as an omission')
  if (s.capabilityCells.some(c => c.level === 'none'))
    throw new Error('no `·` under a display cap')
}

// An observed class the catalog does not know is counted at the end, never dropped.
{
  const odd = report()
  odd.tool_version = '0.3.0'
  odd.result.analysis.capabilities = [
    { capability: 'quantum-tunnelling', relative_path: 'a.qml', detail: '', confidence: 'ast-backed' },
  ]
  odd.result.report_profile.omissions.capabilities = { total: 1, emitted: 1, omitted: 0 }
  const s = sandbox.build(odd).summary
  if (s.capabilityCells.length !== 18 || !s.capabilityCells[17].unknown)
    throw new Error('an unknown capability class must get its own trailing cell')
  if (s.capabilityClasses !== 1)
    throw new Error('an unknown class still counts toward the class count')
}

// Under omission a rule row carries NO tier colour: the emitted set could understate
// the severity, and understating severity is the direction GR3 forbids.
{
  const short = report()
  short.tool_version = '0.3.0'
  short.result.analysis.findings = [{ rule_id: 'oma.x', title: 't', severity: 'low' }]
  short.result.report_profile.omissions.findings = { total: 9, emitted: 1, omitted: 8 }
  short.result.review_summary = {
    findings: { total: 9, active: 9, suppressed: 0, emitted: 1, omitted: 8, by_rule: { 'oma.x': 9 } },
    capabilities: { total: 0, emitted: 0, omitted: 0 },
  }
  const s = sandbox.build(short).summary
  if (s.ruleRows.length !== 1 || s.ruleRows[0].level !== '')
    throw new Error('an incomplete finding set must leave rule rows untiered')
}

// A measured zero keeps its zeros and is NOT "unavailable".
{
  const empty = sandbox.build(report()).summary
  if (empty.severityCountsText !== '0 critical · 0 high · 0 medium · 0 low · 0 info')
    throw new Error('an empty scan prints its zeros: ' + empty.severityCountsText)
  if (empty.severityTotal !== 0 || !empty.severityReconciles)
    throw new Error('an empty scan still reconciles')
}

// No review_summary at all: coverage is unavailable, and the view must say the word
// rather than draw an empty bar that reads as "nothing to cover".
{
  const bare = sandbox.build(report()).summary
  if (bare.coverageAvailable)
    throw new Error('coverage without a review summary must be unavailable, not empty')
}

// ------------------------------------------------------------- T6 reconciliation
{
  const git = sandbox.build(loadFixture('candidate-git-review.json'))
  const r = git.summary.reconciliation

  // The complete case: zero omission notices, and four lines that each sum to their
  // own total.
  if (git.summary.reconciliationNotice !== '')
    throw new Error('a complete report must raise no omission notice: ' + git.summary.reconciliationNotice)
  for (const name of ['findings', 'capabilities', 'edges', 'coverageGaps']) {
    const c = r[name]
    if (!c.reconciles)
      throw new Error(name + ' must reconcile: ' + JSON.stringify(c))
    if (c.shown + c.omitted + c.hidden !== c.total)
      throw new Error(name + ' parts do not sum to the total')
    if (!c.complete)
      throw new Error(name + ' should be complete in the captured report')
  }
  if (r.findings.text !== '32 shown · 0 omitted by the scanner · 0 hidden by the display cap · 0 suppressed')
    throw new Error('findings reconciliation line: ' + r.findings.text)
  if (r.capabilities.text !== '63 shown · 0 omitted by the scanner · 0 hidden by the display cap')
    throw new Error('capabilities reconciliation line: ' + r.capabilities.text)
  // Suppression is a named term on findings only, and it sits OUTSIDE the sum.
  if (r.capabilities.text.indexOf('suppressed') >= 0)
    throw new Error('only findings carry a suppression term')
}

// A non-zero term in two different collections raises exactly ONE notice, naming both.
{
  const mixed = report()
  mixed.tool_version = '0.3.0'
  mixed.result.analysis.findings = Array.from({ length: 6 }, (_, i) => ({
    rule_id: 'oma.x', title: 't' + i, severity: 'low',
  }))
  mixed.result.report_profile.omissions.findings = { total: 10, emitted: 6, omitted: 4 }
  mixed.result.analysis.capabilities = [
    { capability: 'network-access', relative_path: 'a.qml', detail: '', confidence: 'ast-backed' },
  ]
  mixed.result.report_profile.omissions.capabilities = { total: 1, emitted: 1, omitted: 0 }
  mixed.result.review_summary = {
    findings: { total: 10, active: 10, suppressed: 0, emitted: 6, omitted: 4 },
    capabilities: { total: 1, emitted: 1, omitted: 0 },
  }
  const s = sandbox.build(mixed).summary
  if (s.reconciliation.findings.omitted !== 4 || s.reconciliation.findings.shown !== 6)
    throw new Error('findings reconciliation under omission: ' + s.reconciliation.findings.text)
  if (s.reconciliationNotice.indexOf('4 findings omitted by the scanner') < 0)
    throw new Error('the notice must name the omitted findings: ' + s.reconciliationNotice)
  if (s.reconciliationNotice.indexOf('An empty list is not a safety conclusion.') < 0)
    throw new Error('the notice must keep its conclusion sentence')
  if ((s.reconciliationNotice.match(/This report omits evidence/g) || []).length !== 1)
    throw new Error('exactly one notice covers every collection')
}

// A display cap and a scanner omission in two different collections, named together
// in one sentence — the §5.5 example.
{
  const both = report()
  both.tool_version = '0.3.0'
  both.result.analysis.findings = Array.from({ length: 6 }, (_, i) => ({
    rule_id: 'oma.x', title: 't' + i, severity: 'low',
  }))
  both.result.report_profile.omissions.findings = { total: 10, emitted: 6, omitted: 4 }
  both.result.analysis.capabilities = Array.from({ length: 202 }, () => ({
    capability: 'network-access', relative_path: 'a.qml', detail: '', confidence: 'ast-backed',
  }))
  both.result.report_profile.omissions.capabilities = { total: 202, emitted: 202, omitted: 0 }
  both.result.review_summary = {
    findings: { total: 10, active: 10, suppressed: 0, emitted: 6, omitted: 4 },
    capabilities: { total: 202, emitted: 202, omitted: 0 },
  }
  const s = sandbox.build(both).summary
  if (s.reconciliation.capabilities.hidden !== 2)
    throw new Error('the model capped 2 capabilities and must say so')
  if (s.reconciliationNotice.indexOf('4 findings omitted by the scanner') < 0 ||
      s.reconciliationNotice.indexOf('2 capabilities hidden by the display limit') < 0)
    throw new Error('one notice must name both terms: ' + s.reconciliationNotice)
  if (s.reconciliationNotice.indexOf(' and ') < 0)
    throw new Error('two terms are joined with "and", not a bare list')
  // Even under omission, every line still adds up to its own total.
  for (const name of ['findings', 'capabilities']) {
    if (!s.reconciliation[name].reconciles)
      throw new Error(name + ' must still reconcile under omission')
  }
}

// Evidence observations were a bare dangling line; they are a named term now.
{
  const evidence = report()
  evidence.tool_version = '0.3.0'
  evidence.result.report_profile.omissions.evidence_observations = { total: 9, emitted: 6, omitted: 3 }
  const s = sandbox.build(evidence).summary
  if (s.reconciliationNotice.indexOf('3 evidence observations omitted by the scanner') < 0)
    throw new Error('omitted evidence observations must be a term of the notice')
}

// -------------------------------------------------- T7 cursor and finder
{
  const git = sandbox.build(loadFixture('candidate-git-review.json'))

  // sectionCount("scan-findings") is the number of emitted findings, each of which is
  // a cursor row. There were 32 on screen and none reachable from the keyboard.
  if (git.analysis.findings.length !== 32)
    throw new Error('sectionCount("scan-findings") on the captured report')

  // sectionCount("scan-summary") counts the ENABLED copy actions, so `l` reaches the
  // last one. This report has 31 medium + 1 low and complete finding coverage, so the
  // install command is offered and there are two.
  const actions = sandbox.copyActions(git)
  if (actions.length !== 2)
    throw new Error('sectionCount("scan-summary"): ' + JSON.stringify(actions.map(a => a.key)))
  if (actions[0].key !== 'rescan' || actions[1].key !== 'install')
    throw new Error('the rescan command comes first; it is always available')
  if (actions[1].value !== git.installCommand)
    throw new Error('the install action copies exactly the model\'s install command')

  // The section follows the install command's visibility rule rather than restating
  // it: a high finding withholds the command, and the action disappears with it.
  const high = report()
  high.result.analysis.findings = [{ severity: 'high', title: 'reported finding' }]
  high.result.report_profile.omissions.findings = { total: 1, emitted: 1, omitted: 0 }
  const withheld = sandbox.build(high)
  if (withheld.installCommand !== '')
    throw new Error('a high finding must still withhold the install command')
  const withheldActions = sandbox.copyActions(withheld)
  if (withheldActions.length !== 1 || withheldActions[0].key !== 'rescan')
    throw new Error('a withheld install command must not appear as a copy action')
  if (sandbox.copyActions(null).length !== 0 || sandbox.copyActions({ ok: false }).length !== 0)
    throw new Error('a failed or absent model offers no copy actions')

  // Finder: rule id, title and path all match, and the emitted index comes back
  // because it IS the finding's identity in the cursor's index space.
  if (sandbox.searchFindings(git, '').length !== 0)
    throw new Error('an empty query matches nothing')
  if (sandbox.searchFindings(null, 'qml').length !== 0)
    throw new Error('a null model matches nothing')
  const byRule = sandbox.searchFindings(git, 'dynamic-reference')
  if (byRule.length !== 1 || byRule[0].finding.ruleId !== 'oma.qml.dynamic-reference')
    throw new Error('a rule id must match')
  if (git.analysis.findings[byRule[0].index].ruleId !== byRule[0].finding.ruleId)
    throw new Error('the returned index must address the same finding in the emitted list')
  if (sandbox.searchFindings(git, 'components/AlertRow').length === 0)
    throw new Error('a path must match')
  if (sandbox.searchFindings(git, 'oma.').length > 6)
    throw new Error('finder results are capped at six')
  if (sandbox.searchFindings(git, 'ZZZZ-no-such-thing').length !== 0)
    throw new Error('a non-matching query finds nothing')
}

// ------------------------------------------------- T13 E4: shared coverage rows
//
// The installed detail sheet renders the same six payload states through the same
// derivation, so "an installed plugin and a candidate read identically" is literal
// rather than a convention two files agree on.
{
  const installed = JSON.parse(fs.readFileSync(
    path.join(fixtures, 'installed-analyze.json'), 'utf8')).result
  const states = installed.payload_inventory.coverage_states
  const rows = sandbox.coverageRows(states, installed.payload_inventory.totals.entries)
  if (rows.rows.map(r => r.key).join(',') !==
      'analyzed,partial,truncated,skipped,unsupported,unreferenced')
    throw new Error('the installed path uses the candidate\'s fixed order')
  // Asserted as a reconciliation, not a constant: this fixture is re-captured from
  // the working tree and its payload count legitimately moves as the repo grows.
  if (rows.total !== installed.payload_inventory.totals.entries || !rows.reconciles)
    throw new Error('the installed coverage rows must sum to the payload entry total')
  if (!/^\d+ analyzed · \d+ partial · \d+ truncated · \d+ skipped · \d+ unsupported · \d+ unreferenced$/
      .test(rows.countsText))
    throw new Error('installed counts line shape: ' + rows.countsText)
  if (rows.rows.find(r => r.key === 'analyzed').count !== states.analyzed)
    throw new Error('the analyzed row carries the report\'s own figure')
  if (rows.rows.some(r => r.level === 'healthy'))
    throw new Error('no installed coverage segment may be green either')

  // Passing 0 as the total means "use the segments' own sum" — the Baseline bar's
  // contract, where the legend is three counts and not a catalog total.
  const selfTotal = sandbox.coverageRows({ analyzed: 3, unsupported: 1 }, 0)
  if (selfTotal.total !== 4 || !selfTotal.reconciles)
    throw new Error('a zero total falls back to the segments\' own sum')

  if (sandbox.coverageRows(null, 10) !== null)
    throw new Error('absent states yield null, so the caller says `unavailable` rather than drawing an empty bar')

  // An unknown state is counted at the end rather than dropped, so the bar still
  // reconciles with a total that includes it.
  const odd = sandbox.coverageRows({ analyzed: 2, quantum: 3 }, 5)
  if (!odd.reconciles || odd.rows[odd.rows.length - 1].key !== 'other' ||
      odd.rows[odd.rows.length - 1].count !== 3)
    throw new Error('an unknown coverage state is counted as `other`, never dropped')
}

// ------------------------------------------------- C5: per-class capability counts
//
// `omasafe-cli 0.3.1` exports `review_summary.capabilities.by_class`, mirroring
// `findings.by_rule`. Its per-class `total` is taken from the pre-selection set, so it
// stays exact however much of `analysis.capabilities[]` the report profile drops —
// which is what lets a strip cell distinguish "not observed" from "selected away".
{
  const installed = JSON.parse(fs.readFileSync(
    path.join(fixtures, 'installed-analyze.json'), 'utf8')).result
  const byClass = installed.review_summary.capabilities.by_class
  if (!byClass || typeof byClass !== 'object')
    throw new Error('the 0.3.1 report must carry capabilities.by_class')
  const summed = Object.values(byClass).reduce((n, row) => n + row.total, 0)
  if (summed !== installed.review_summary.capabilities.total)
    throw new Error('by_class totals must sum to the capability total: ' + summed)
  for (const [cls, row] of Object.entries(byClass)) {
    if (row.emitted + row.omitted !== row.total)
      throw new Error('by_class[' + cls + '] must reconcile: ' + JSON.stringify(row))
  }
  // Every class the emitted array mentions has a row, and the row's total is at least
  // what was emitted — the direction that matters, since total is the pre-selection
  // figure and emitted is what survived.
  const emittedClasses = new Set(installed.analysis.capabilities.map(c => c.capability))
  for (const cls of emittedClasses) {
    if (!byClass[cls]) throw new Error('by_class is missing an observed class: ' + cls)
    const count = installed.analysis.capabilities.filter(c => c.capability === cls).length
    if (byClass[cls].total < count)
      throw new Error('by_class[' + cls + '].total is below what was emitted')
  }
}

// -------------------------------------- C5 consumer: by_class drives the strip
//
// The producer test above checks the report's arithmetic. These check that the panel
// USES it — the aggregate exists precisely so a strip cell can distinguish "this class
// was not observed" from "this class's instances were selected away", and normalization
// discarding it made that distinction unavailable.
function partialReport(byClass) {
  const raw = loadFixture('candidate-git-review.json')
  const res = raw.result
  // A valid report declaring 63 uses across four classes with EVERY occurrence
  // selected away by the scanner.
  res.analysis.capabilities = []
  res.report_profile.omissions.capabilities = { total: 63, emitted: 0, omitted: 63 }
  res.review_summary.capabilities = { total: 63, emitted: 0, omitted: 63 }
  if (byClass) res.review_summary.capabilities.by_class = byClass
  res.review_summary.presentation_complete = false
  return raw
}
const exactByClass = {
  'persistence-scheduling': { total: 39, emitted: 0, omitted: 39 },
  'process-execution': { total: 20, emitted: 0, omitted: 20 },
  'clipboard-access': { total: 3, emitted: 0, omitted: 3 },
  'filesystem-access': { total: 1, emitted: 0, omitted: 1 },
}

{
  const s = sandbox.build(partialReport(exactByClass)).summary
  // Before the aggregate was consumed this read "63 uses · at least 0 classes" with all
  // seventeen cells `–`, despite the report carrying exact class totals.
  if (s.capabilityCountsText !== '63 uses · 4 classes · at least 0 files')
    throw new Error('by_class must make the class axis exact: ' + s.capabilityCountsText)
  if (!s.capabilityClassesExact || !s.capabilitiesComplete)
    throw new Error('a validated aggregate settles the strip on its own')
  const observed = s.capabilityCells.filter(c => c.level === 'observed').map(c => c.key).sort()
  if (observed.join(',') !==
      'clipboard-access,filesystem-access,persistence-scheduling,process-execution')
    throw new Error('cells come from the aggregate, not from emitted occurrences: ' + observed)
  if (s.capabilityCells.filter(c => c.level === 'none').length !== 13)
    throw new Error('a class the aggregate reports as absent has EARNED its `·`')
  if (s.capabilityCells.some(c => c.level === 'absent'))
    throw new Error('no cell may be `–` when the aggregate is exact')
  if (s.capabilityObserved[0].cls !== 'persistence-scheduling' ||
      s.capabilityObserved[0].count !== 39)
    throw new Error('observed counts come from the aggregate totals')
  // `files` is still emitted-derived and must NOT borrow the aggregate's exactness.
  if (s.capabilityFiles !== 0 || s.capabilityCountsText.indexOf('at least 0 files') < 0)
    throw new Error('the file axis stays a lower bound: it has no aggregate')
}

// An aggregate that does not reconcile is DISCARDED, not half-believed. Each of these
// must fall back to the pessimistic presentation the panel had before C5.
for (const [label, byClass] of [
  ['a row whose counters contradict',
    Object.assign({}, exactByClass, { 'process-execution': { total: 20, emitted: 5, omitted: 2 } })],
  ['a row missing its omitted counter',
    Object.assign({}, exactByClass, { 'process-execution': { total: 20, emitted: 20 } })],
  ['rows that do not sum to the collection total',
    { 'process-execution': { total: 20, emitted: 0, omitted: 20 } }],
  ['a row that is not an object', Object.assign({}, exactByClass, { 'process-execution': 20 })],
  ['an empty aggregate', {}],
  ['no aggregate at all (a 0.3.0 report)', null],
]) {
  const s = sandbox.build(partialReport(byClass)).summary
  if (s.capabilityClassesExact)
    throw new Error(label + ': must not be trusted')
  if (s.capabilitiesComplete)
    throw new Error(label + ': must fall back to PARTIAL')
  if (s.capabilityCells.filter(c => c.level === 'absent').length !== 17)
    throw new Error(label + ': every unobserved position falls back to `–`')
  if (s.capabilityCountsText !== '63 uses · at least 0 classes · at least 0 files')
    throw new Error(label + ': counts hedge again — ' + s.capabilityCountsText)
}

{
  // A class the aggregate reports as present-but-zero is not observed, and its cell is
  // `·` rather than a zero-count "observed" mark.
  const zeroed = Object.assign({}, exactByClass, {
    'network-access': { total: 0, emitted: 0, omitted: 0 },
  })
  const s = sandbox.build(partialReport(zeroed)).summary
  const cell = s.capabilityCells.find(c => c.key === 'network-access')
  if (!cell || cell.level !== 'none')
    throw new Error('a zero-total class is `·`, not observed')
  if (s.capabilityObserved.some(o => o.cls === 'network-access'))
    throw new Error('and it is absent from the observed list')
}

{
  // The captured 0.3.1 report omits nothing, so the aggregate and the emitted
  // occurrences agree — and the presentation is unchanged from before C5.
  const git = sandbox.build(loadFixture('candidate-git-review.json'))
  const s = git.summary
  if (!git.reviewSummary.capabilities.byClass)
    throw new Error('the 0.3.1 capture carries by_class through normalization')
  if (!s.capabilitiesComplete || !s.capabilityClassesExact)
    throw new Error('a complete report is exact on both counts')
  if (s.capabilityCountsText.indexOf('at least') >= 0)
    throw new Error('and hedges nothing: ' + s.capabilityCountsText)
  const fromAggregate = Object.entries(git.reviewSummary.capabilities.byClass)
    .filter(([, row]) => row.total > 0).map(([cls]) => cls).sort()
  const fromCells = s.capabilityCells.filter(c => c.level === 'observed').map(c => c.key).sort()
  if (fromAggregate.join(',') !== fromCells.join(','))
    throw new Error('the aggregate and the emitted occurrences must agree here')
}

console.log('candidate model: ok')
