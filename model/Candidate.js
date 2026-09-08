// Candidate.js — pure normalisation for the persistent-in-session v0.2.2 source scan view.
//
// The CLI owns parsing, acquisition, analysis, and policy. This module only
// accepts the versioned scan-only report, bounds target-derived display text,
// and turns it into view data. It never executes a command or infers safety.
.pragma library

var MAX_TEXT = 2048
var MAX_ITEMS = 200
var MAX_EMITTED = 1024

function _arr(value) { return Array.isArray(value) ? value : [] }
function _obj(value) { return value && typeof value === "object" && !Array.isArray(value) ? value : null }
function _str(value) { return String(value === null || value === undefined ? "" : value) }
function _escapeDisplayControl(value) {
  return "\\u{" + value.charCodeAt(0).toString(16) + "}"
}
function _display(value, limit) {
  var text = _str(value)
  // Text.PlainText protects the view from markup; replace terminal/bidi controls
  // as well so evidence cannot create invisible or stateful display text.
  text = text.replace(/[\r\n]/g, function(value) {
    return value === "\r" ? "\\r" : "\\n"
  }).replace(/\t/g, "\\t")
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f\u0080-\u009f]/g, _escapeDisplayControl)
    .replace(/[\u061c\u200e\u200f\u2028\u2029\u202a-\u202e\u2066-\u2069]/g, _escapeDisplayControl)
  return text.slice(0, limit || MAX_TEXT)
}
function _commit(value) {
  var text = _str(value)
  return /^(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})$/.test(text) ? text : ""
}
function _version(value) {
  var match = /^(\d+)\.(\d+)(?:\.(\d+))?$/.exec(_str(value).trim())
  return match ? [Number(match[1]), Number(match[2]), Number(match[3] || 0)] : null
}
function _atLeast(value, minimum) {
  var parsed = _version(value)
  if (!parsed) return false
  for (var i = 0; i < 3; i++) {
    if (parsed[i] !== minimum[i]) return parsed[i] > minimum[i]
  }
  return true
}
function _count(value) {
  return typeof value === "number" && isFinite(value) && value >= 0 && Math.floor(value) === value
    ? value : null
}
function _safeUrl(value) {
  var text = _str(value)
  return /^https:\/\/[^\s/?#@]+(?:\/[^\s?#]*)?$/.test(text) &&
    !/[\u0000-\u001f\u007f\u0080-\u009f\u061c\u200e\u200f\u2028\u2029\u202a-\u202e\u2066-\u2069]/.test(text) ? text : ""
}
function _suggestedInstallCommand(acquisition, url) {
  var verb = acquisition.install_verb === "install" ? "install" : "add"
  var command = "omarchy plugin " + verb + " " + url
  var flags = _arr(acquisition.discarded_install_flags)
  if (flags.indexOf("enable") >= 0) command += " --enable"
  return command
}
function _failure(error) { return { ok: false, error: _display(error, MAX_TEXT) } }

function _omission(omissions, name) {
  var value = omissions ? _obj(omissions[name]) : null
  if (!value) return null
  var total = _count(value.total), emitted = _count(value.emitted), omitted = _count(value.omitted)
  if (total === null || emitted === null || omitted === null || emitted + omitted !== total) return null
  return { total: total, emitted: emitted, omitted: omitted }
}

function _countOr(value, fallback) {
  var count = _count(value)
  return count === null ? fallback : count
}

function _mapCounts(value) {
  var source = _obj(value), out = {}
  if (!source) return out
  for (var key in source) {
    var count = _count(source[key])
    if (count !== null) out[_display(key, 128)] = count
  }
  return out
}

function _mapRows(value) {
  var source = _obj(value), out = {}
  if (!source) return out
  for (var key in source) {
    var row = _obj(source[key])
    if (row) {
      var total = _count(row.total), active = _count(row.active), suppressed = _count(row.suppressed)
      var emitted = _count(row.emitted), omitted = _count(row.omitted)
      if (total !== null && emitted !== null && omitted !== null) {
        out[_display(key, 256)] = {
          ruleId: _display(row.rule_id || key, 256),
          total: total,
          active: active === null ? 0 : active,
          suppressed: suppressed === null ? 0 : suppressed,
          emitted: emitted,
          omitted: omitted
        }
      }
    } else {
      var count = _count(source[key])
      if (count !== null) out[_display(key, 256)] = count
    }
  }
  return out
}

function _evidenceSummary(value) {
  var summary = _obj(value)
  if (!summary) return null
  var total = _count(summary.total), emitted = _count(summary.emitted), omitted = _count(summary.omitted)
  if (total === null || emitted === null || omitted === null || emitted + omitted !== total) return null
  return {
    total: total,
    emitted: emitted,
    omitted: omitted,
    observationCollectionComplete: summary.observation_collection_complete === true
  }
}

function _evidenceStep(value) {
  var step = _obj(value) || {}
  return {
    id: _display(step.id, 128),
    role: _display(step.role, 32),
    relativePath: _display(step.relative_path, 1024),
    displayRelativePath: _display(step.display_relative_path || step.relative_path, 1024),
    line: _count(step.line) === null ? "" : String(step.line),
    column: _count(step.column) === null ? "" : String(step.column),
    analysisMethod: _display(step.analysis_method, 64),
    detail: _display(step.detail, 512),
    origin: _display(step.origin, 32),
    redacted: step.redacted === true,
    truncated: step.truncated === true
  }
}

function _destination(value) {
  var destination = _obj(value)
  if (!destination) return null
  return {
    scheme: _display(destination.scheme, 32),
    host: _display(destination.host, 256),
    port: _count(destination.port) === null ? "" : String(destination.port),
    pathDisplay: _display(destination.path_display, 512),
    dynamic: destination.dynamic === true,
    redacted: destination.redacted === true
  }
}

function _behaviorContext(value) {
  var context = _obj(value)
  if (!context) return null
  return {
    connection: _display(context.connection, 32),
    sourceClass: _display(context.source_class, 64),
    sinkKind: _display(context.sink_kind, 64),
    sinkArgumentRole: _display(context.sink_argument_role, 128),
    trigger: _display(context.trigger, 32),
    destination: _destination(context.destination)
  }
}

function _presentation(value) {
  var presentation = _obj(value)
  if (!presentation) return null
  return {
    redacted: presentation.redacted === true,
    truncated: presentation.truncated === true,
    redactionClasses: _arr(presentation.redaction_classes).slice(0, 16).map(function(item) {
      return _display(item, 64)
    }),
    omittedFields: _arr(presentation.omitted_fields).slice(0, 16).map(function(item) {
      return _display(item, 128)
    })
  }
}

function _finding(value) {
  var finding = _obj(value) || {}
  return {
    occurrenceId: _display(finding.occurrence_id, 128),
    ruleSemanticIdentityDigest: _display(finding.rule_semantic_identity_digest, 128),
    analysisMethod: _display(finding.analysis_method, 64),
    ruleId: _display(finding.rule_id, 512),
    title: _display(finding.title, 1024),
    severity: _display(finding.severity, 32),
    relativePath: _display(finding.relative_path, 1024),
    displayRelativePath: _display(finding.display_relative_path || finding.relative_path, 1024),
    line: _count(finding.line) === null ? "" : String(finding.line),
    evidence: _display(finding.evidence, MAX_TEXT),
    confidence: _display(finding.confidence, 64),
    explanation: _display(finding.explanation, MAX_TEXT),
    reviewGuidance: _display(finding.review_guidance, MAX_TEXT),
    evidenceSteps: _arr(finding.evidence_steps).slice(0, 8).map(_evidenceStep),
    evidenceSummary: _evidenceSummary(finding.evidence_summary),
    behaviorContext: _behaviorContext(finding.behavior_context),
    presentation: _presentation(finding.presentation)
  }
}

function _summaryCounts(value, includeActive) {
  var counts = _obj(value) || {}
  var out = {
    total: _countOr(counts.total, 0),
    emitted: _countOr(counts.emitted, 0),
    omitted: _countOr(counts.omitted, 0)
  }
  if (includeActive) {
    out.active = _countOr(counts.active, out.emitted + out.omitted)
    out.suppressed = _countOr(counts.suppressed, Math.max(0, out.total - out.active))
    out.bySeverity = _mapRows(counts.by_severity)
    out.byRule = _mapRows(counts.by_rule)
  }
  return out
}

function _coverageSummary(value) {
  var coverage = _obj(value)
  if (!coverage) return null
  return {
    assessment: _display(coverage.assessment, 64),
    payloadStates: _mapCounts(coverage.payload_states),
    gapTotal: _countOr(coverage.gap_total, 0),
    byReason: _mapCounts(coverage.by_reason),
    executableOrLoadGaps: _countOr(coverage.executable_or_load_gaps, 0),
    languageModelGaps: _countOr(coverage.language_model_gaps, 0),
    inertMetadataEntries: _countOr(coverage.inert_metadata_entries, 0),
    externalBaseline: _obj(coverage.external_baseline) ? {
      mapIdentity: _display(coverage.external_baseline.map_identity, 128),
      verificationCommit: _commit(coverage.external_baseline.verification_commit),
      freshness: _display(coverage.external_baseline.freshness, 64),
      notCovered: _arr(coverage.external_baseline.not_covered).slice(0, MAX_ITEMS).map(function(item) {
        return _display(item, 128)
      }),
      partialOverlap: _arr(coverage.external_baseline.partial_overlap).slice(0, MAX_ITEMS).map(function(item) {
        return _display(item, 128)
      })
    } : null
  }
}

function _reviewSummary(value) {
  var summary = _obj(value)
  if (!summary) return null
  var threshold = _obj(summary.threshold)
  var lifecycle = _obj(summary.lifecycle_policy)
  return {
    schema: _display(summary.schema, 64),
    version: _count(summary.version),
    policyIdentityDigest: _display(summary.policy_identity_digest, 128),
    analysisProducedAt: _display(summary.analysis_produced_at, 64),
    freshness: _display(summary.freshness, 64),
    sourceIdentityRef: _display(summary.source_identity_ref, 32),
    sourceIdentityState: _display(summary.source_identity_state, 32),
    findings: _summaryCounts(summary.findings, true),
    capabilities: _summaryCounts(summary.capabilities, false),
    findingsBeforeSuppression: _countOr(summary.findings_before_suppression, 0),
    severityCounts: _mapCounts(summary.severity_counts),
    ruleCounts: _mapCounts(summary.rule_counts),
    coverageGaps: _summaryCounts(summary.coverage_gaps, false),
    coverage: _coverageSummary(summary.coverage),
    maxSeverity: _display(summary.max_severity, 32),
    thresholdBreached: summary.threshold_breached === true,
    presentationComplete: summary.presentation_complete === true,
    complete: summary.complete === true,
    presentationCollections: _obj(summary.presentation_collections) ? _mapRows(summary.presentation_collections) : {},
    suppressionPolicy: _display(summary.suppression_policy, 128),
    suppressionReconfirmationCount: _countOr(summary.suppression_reconfirmation_count, 0),
    lifecyclePolicy: lifecycle ? {
      evaluationState: _display(lifecycle.evaluation_state, 32),
      outcome: lifecycle.outcome === null ? null : _display(lifecycle.outcome, 32),
      authorizationBasis: lifecycle.authorization_basis === null ? null : _display(lifecycle.authorization_basis, 32)
    } : null,
    threshold: threshold ? {
      requested: threshold.requested === null ? null : _display(threshold.requested, 32),
      breached: threshold.breached === true
    } : null,
    untrustedDataNotice: _display(summary.untrusted_data_notice, MAX_TEXT)
  }
}

function _summaryMatches(value, omission, requireActive) {
  var counts = _obj(value)
  if (!counts) return true
  var total = _count(counts.total), emitted = _count(counts.emitted), omitted = _count(counts.omitted)
  if (total === null || emitted === null || omitted === null ||
      emitted !== omission.emitted || omitted !== omission.omitted)
    return false
  if (requireActive) {
    var active = _count(counts.active), suppressed = _count(counts.suppressed)
    if (active === null || suppressed === null || active !== omission.total ||
        active + suppressed !== total || active !== emitted + omitted)
      return false
  } else if (total !== omission.total) {
    return false
  }
  return true
}

function _coverageGap(value) {
  var gap = _obj(value) || {}
  return {
    reason: _display(gap.reason, 128),
    language: _display(gap.language, 64),
    ruleIds: _arr(gap.rule_ids).slice(0, 32).map(function(item) { return _display(item, 128) }),
    relativePath: _display(gap.relative_path, 1024),
    displayRelativePath: _display(gap.display_relative_path || gap.relative_path, 1024),
    line: _count(gap.line) === null ? "" : String(gap.line),
    impact: _display(gap.impact, 64),
    detail: _display(gap.detail, MAX_TEXT)
  }
}

function _parsers(value) {
  var source = _obj(value), out = {}
  if (!source) return out
  var languages = 0
  for (var language in source) {
    if (languages++ >= 32) break
    var parser = _obj(source[language]) || {}
    out[_display(language, 64)] = {
      method: _display(parser.method, 64),
      grammar: _display(parser.grammar, 128),
      grammarVersion: _display(parser.grammar_version, 64),
      runtimeVersion: _display(parser.runtime_version, 64)
    }
  }
  return out
}

function _capability(value) {
  var capability = _obj(value) || {}
  return {
    capability: _display(capability.capability, 128),
    relativePath: _display(capability.relative_path, 1024),
    detail: _display(capability.detail, MAX_TEXT),
    confidence: _display(capability.confidence, 64)
  }
}

function _edge(value) {
  var edge = _obj(value) || {}
  return {
    fromPath: _display(edge.from_path, 1024),
    targetPath: _display(edge.target_path, 1024),
    kind: _display(edge.kind, 128)
  }
}

function _sha256(value) {
  var text = _str(value)
  return /^[0-9a-f]{64}$/.test(text) ? text : ""
}

function _codeExposure(value) {
  var entries = _arr(value), out = []
  for (var i = 0; i < Math.min(entries.length, MAX_ITEMS); i++) {
    var entry = _obj(entries[i])
    if (!entry) continue
    out.push({
      relativePath: _display(entry.relative_path, 1024),
      nativeFormat: _display(entry.native_format || "opaque-executable", 128),
      exposure: _display(entry.exposure || "unknown", 128),
      contentClass: _display(entry.content_class || "unknown", 128),
      digestState: _display(entry.digest_state || "unavailable", 64),
      exactSha256: _sha256(entry.exact_sha256),
      opaqueReviewRequired: entry.opaque_review_required === true,
      reviewStatus: _display(entry.review_status || "unreviewed", 128)
    })
  }
  return out
}

function build(report) {
  var top = _obj(report)
  if (!top || top.schema !== "omasafe.report.v1" || !_atLeast(top.tool_version, [0, 2, 2]))
    return _failure("unsupported candidate report or CLI version")

  var result = _obj(top.result), target = result && _obj(result.target)
  var acquisition = result && _obj(result.acquisition)
  var analysis = result && _obj(result.analysis)
  var suppressions = result && _obj(result.suppressions)
  var profile = result && _obj(result.report_profile)
  var payload = result && _obj(result.payload_inventory)
  if (!result || !target || !acquisition || !analysis || !suppressions || !profile || !payload)
    return _failure("candidate report is missing a required section")
  if (acquisition.schema !== "omasafe.acquisition.v1" || acquisition.operation !== "scan-only" ||
      acquisition.installation_performed !== false)
    return _failure("candidate report is not scan-only")
  if (["raw-github-url", "omarchy-install-command", "exact-git", "marketplace-id"].indexOf(acquisition.input_kind) < 0 ||
      ["none", "add", "install"].indexOf(acquisition.install_verb) < 0)
    return _failure("candidate report has an unsupported input kind")
  if (suppressions.policy !== "candidate-unsuppressed" || suppressions.consulted !== false ||
      !Array.isArray(suppressions.applied) || suppressions.applied.length !== 0 ||
      suppressions.active_records !== null)
    return _failure("candidate suppression policy is not explicit")

  var revision = _commit(acquisition.resolved_identity && acquisition.resolved_identity.value)
  var observed = acquisition.integrity && acquisition.integrity.observed
  var algorithm = revision.length === 64 ? "git-sha256" : "git-sha1"
  if (!revision || !_obj(acquisition.resolved_identity) || acquisition.resolved_identity.kind !== "git-commit" ||
      !_obj(acquisition.integrity) || acquisition.integrity.state !== "resolved-exact" ||
      acquisition.integrity.algorithm !== algorithm || observed !== revision)
    return _failure("candidate integrity does not match a full resolved commit")
  if (typeof acquisition.network_used !== "boolean" || !_obj(acquisition.cache) ||
      typeof acquisition.cache.used !== "boolean" ||
      ["not-used", "hit", "miss"].indexOf(acquisition.cache.result) < 0)
    return _failure("candidate acquisition facts are unsupported")
  if (!Array.isArray(acquisition.discarded_install_flags) ||
      acquisition.discarded_install_flags.some(function(flag) { return ["enable", "yes"].indexOf(flag) < 0 }))
    return _failure("candidate install flags are unsupported")
  if (_commit(target.revision) !== revision ||
      ["resolved-git-request", "pinned-revision", "marketplace-listing"].indexOf(target.source) < 0 ||
      target.scope !== "plugin-root")
    return _failure("candidate target is not bound to the resolved commit")
  if (analysis.schema !== "omasafe.analysis.v1" || !Array.isArray(analysis.findings) ||
      !Array.isArray(analysis.capabilities) || !Array.isArray(analysis.invocation_edges) ||
      !Array.isArray(analysis.coverage_limitations) ||
      ("coverage_gaps" in analysis && !Array.isArray(analysis.coverage_gaps)))
    return _failure("candidate analysis schema is unsupported")
  if (profile.name !== "review" || _count(profile.serialized_byte_limit) === null ||
      profile.serialized_byte_limit > 1572864)
    return _failure("candidate review profile is unsupported")
  if (("selection_strategy" in profile && ["canonical-full-v1", "severity-family-file-round-robin-v1"].indexOf(profile.selection_strategy) < 0) ||
      ("presentation_version" in profile && profile.presentation_version !== 1) ||
      ("redaction_policy_version" in profile && profile.redaction_policy_version !== 1))
    return _failure("candidate review presentation metadata is unsupported")

  var omissions = _obj(profile.omissions)
  var payloadOmission = _omission(omissions, "payload_entries")
  var findingOmission = _omission(omissions, "findings")
  var capabilityOmission = _omission(omissions, "capabilities")
  var edgeOmission = _omission(omissions, "invocation_edges")
  var coverageGapOmission = _omission(omissions, "coverage_gaps")
  var codeExposureOmission = _omission(omissions, "code_exposure")
  var evidenceObservationOmission = _omission(omissions, "evidence_observations")
  var coverageGapsInput = _arr(analysis.coverage_gaps)
  var codeExposureInput = _arr(payload.code_exposure)
  if (!coverageGapOmission) coverageGapOmission = { total: coverageGapsInput.length, emitted: coverageGapsInput.length, omitted: 0 }
  if (!codeExposureOmission) codeExposureOmission = { total: codeExposureInput.length, emitted: codeExposureInput.length, omitted: 0 }
  if (!evidenceObservationOmission) evidenceObservationOmission = { total: 0, emitted: 0, omitted: 0 }
  if (!payloadOmission || !findingOmission || !capabilityOmission || !edgeOmission ||
      (omissions && ("coverage_gaps" in omissions && !_omission(omissions, "coverage_gaps"))) ||
      (omissions && ("evidence_observations" in omissions && !_omission(omissions, "evidence_observations"))) ||
      (omissions && ("code_exposure" in omissions && !_omission(omissions, "code_exposure"))) ||
      !Array.isArray(payload.entries) || payload.entries.length !== 0 ||
      !_obj(payload.totals) || _count(payload.totals.entries) !== payloadOmission.total ||
      findingOmission.emitted > MAX_EMITTED || capabilityOmission.emitted > MAX_EMITTED ||
      edgeOmission.emitted > MAX_EMITTED || coverageGapOmission.emitted > MAX_EMITTED ||
      analysis.findings.length !== findingOmission.emitted ||
      analysis.capabilities.length !== capabilityOmission.emitted ||
      analysis.invocation_edges.length !== edgeOmission.emitted ||
      coverageGapsInput.length !== coverageGapOmission.emitted ||
      codeExposureInput.length !== codeExposureOmission.emitted)
    return _failure("candidate review profile omission data is invalid")
  var rawReviewSummary = _obj(result.review_summary)
  if (rawReviewSummary &&
      (!_summaryMatches(rawReviewSummary.findings, findingOmission, true) ||
       !_summaryMatches(rawReviewSummary.capabilities, capabilityOmission, false) ||
       ("suppression_policy" in rawReviewSummary && rawReviewSummary.suppression_policy !== suppressions.policy) ||
       (_obj(rawReviewSummary.findings) && _countOr(rawReviewSummary.findings.suppressed, 0) !== 0) ||
       ("presentation_complete" in rawReviewSummary && typeof rawReviewSummary.presentation_complete !== "boolean")))
    return _failure("candidate review summary counts are inconsistent")

  var effectiveUrl = _safeUrl(acquisition.effective_repository_url)
  if (!effectiveUrl) return _failure("candidate repository URL is unavailable")
  if (acquisition.input_kind === "marketplace-id" && !_obj(acquisition.marketplace_claim))
    return _failure("marketplace candidate attribution is unavailable")

  var findings = analysis.findings.slice(0, MAX_ITEMS).map(_finding)
  var capabilities = analysis.capabilities.slice(0, MAX_ITEMS).map(_capability)
  var edges = analysis.invocation_edges.slice(0, MAX_ITEMS).map(_edge)
  var coverageGaps = coverageGapsInput.slice(0, MAX_ITEMS).map(_coverageGap)
  var codeExposure = _codeExposure(codeExposureInput)
  var highCritical = false
  var classified = true
  for (var f = 0; f < analysis.findings.length; f++) {
    var severity = _str(analysis.findings[f] && analysis.findings[f].severity).toLowerCase()
    if (["info", "low", "medium", "high", "critical"].indexOf(severity) < 0) classified = false
    if (severity === "high" || severity === "critical") highCritical = true
  }
  var completeFindings = findingOmission.omitted === 0 && classified
  var installCommand = completeFindings && !highCritical
    ? _suggestedInstallCommand(acquisition, effectiveUrl) : ""
  var installCommandReason = findingOmission.omitted > 0
    ? "Suggested install command withheld because the compact report omits findings."
    : highCritical
      ? "Suggested install command withheld because high or critical findings were reported."
      : !classified
        ? "Suggested install command withheld because finding severity is incomplete."
        : "Suggested install command unavailable."
  var limitationTexts = analysis.coverage_limitations.slice(0, MAX_ITEMS).map(function(value) {
    return _display(value, MAX_TEXT)
  })
  var acquisitionLimitations = _arr(acquisition.limitations).slice(0, MAX_ITEMS).map(function(value) {
    return _display(value, MAX_TEXT)
  })
  for (var l = 0; l < acquisitionLimitations.length; l++) limitationTexts.push(acquisitionLimitations[l])

  var stateCounts = {}
  var states = _obj(payload.coverage_states) || {}
  for (var state in states) {
    var stateCount = _count(states[state])
    if (stateCount !== null) stateCounts[_display(state, 128)] = stateCount
  }

  var listed = acquisition.listed_repository === null || acquisition.listed_repository === undefined
    ? "" : _display(acquisition.listed_repository, 2048)
  var claim = _obj(acquisition.marketplace_claim)
  var marketplace = claim ? {
    verificationStatus: _display(claim.verification_status, 64),
    listingCommit: _commit(claim.listing_validated_commit),
    catalogCommit: _commit(claim.registry_commit),
    ageSeconds: _count(claim.age_seconds)
  } : null
  var policyKey = ""
  try { policyKey = JSON.stringify(analysis.policy_identity || {}) } catch (ignore) { policyKey = "" }
  policyKey = _display(policyKey, MAX_TEXT)
  var reviewSummary = _reviewSummary(result.review_summary)
  var presentationComplete = reviewSummary
    ? reviewSummary.presentationComplete
    : (findingOmission.omitted === 0 && capabilityOmission.omitted === 0 &&
      edgeOmission.omitted === 0 && coverageGapOmission.omitted === 0 &&
      codeExposureOmission.omitted === 0 && evidenceObservationOmission.omitted === 0)

  return {
    ok: true,
    toolVersion: _display(top.tool_version, 32),
    target: {
      source: _display(target.source, 64),
      id: _display(target.id, 512),
      url: _display(target.url, 2048),
      revision: revision,
      root: _display(target.root, 1024)
    },
    acquisition: {
      inputKind: _display(acquisition.input_kind, 64),
      installVerb: _display(acquisition.install_verb, 32),
      requestedReference: _display(acquisition.requested_reference, 128),
      discardedFlags: _arr(acquisition.discarded_install_flags).slice(0, 8).map(function(value) {
        return _display(value, 32)
      }),
      resolvedRevision: revision,
      integrityAlgorithm: algorithm,
      networkUsed: acquisition.network_used === true,
      cacheResult: _display(acquisition.cache && acquisition.cache.result, 32),
      listedRepository: listed,
      effectiveRepositoryUrl: effectiveUrl,
      marketplace: marketplace,
      installationPerformed: false
    },
    suppressions: { policy: "candidate-unsuppressed", consulted: false },
    analysis: {
      fingerprint: _display(analysis.analysis_fingerprint, 128),
      policyKey: policyKey,
      findings: findings,
      findingsTotal: findingOmission.total,
      findingsOmitted: findingOmission.omitted,
      findingsDisplayOmitted: Math.max(0, findingOmission.emitted - findings.length),
      capabilities: capabilities,
      capabilitiesTotal: capabilityOmission.total,
      capabilitiesOmitted: capabilityOmission.omitted,
      capabilitiesDisplayOmitted: Math.max(0, capabilityOmission.emitted - capabilities.length),
      edges: edges,
      edgesTotal: edgeOmission.total,
      edgesOmitted: edgeOmission.omitted,
      edgesDisplayOmitted: Math.max(0, edgeOmission.emitted - edges.length),
      coverageGaps: coverageGaps,
      coverageGapsTotal: coverageGapOmission.total,
      coverageGapsOmitted: coverageGapOmission.omitted,
      coverageGapsDisplayOmitted: Math.max(0, coverageGapOmission.emitted - coverageGaps.length),
      codeExposure: codeExposure,
      codeExposureTotal: codeExposureOmission.total,
      codeExposureOmitted: codeExposureOmission.omitted,
      codeExposureDisplayOmitted: Math.max(0, codeExposureOmission.emitted - codeExposure.length),
      evidenceObservationsTotal: evidenceObservationOmission.total,
      evidenceObservationsOmitted: evidenceObservationOmission.omitted,
      parsers: _parsers(analysis.parsers),
      coverageStates: stateCounts,
      limitations: limitationTexts
    },
    profile: {
      serializedByteLimit: profile.serialized_byte_limit,
      selectionStrategy: _display(profile.selection_strategy, 64),
      presentationVersion: _count(profile.presentation_version),
      redactionPolicyVersion: _count(profile.redaction_policy_version),
      sizingRecovery: _obj(profile.sizing_recovery) ? {
        applied: profile.sizing_recovery.applied === true,
        reason: _display(profile.sizing_recovery.reason, 128),
        retries: _countOr(profile.sizing_recovery.retries, 0)
      } : null,
      omissions: {
        payloadEntries: payloadOmission,
        findings: findingOmission,
        capabilities: capabilityOmission,
        edges: edgeOmission,
        coverageGaps: coverageGapOmission,
        codeExposure: codeExposureOmission,
        evidenceObservations: evidenceObservationOmission
      }
    },
    reviewSummary: reviewSummary,
    freshness: reviewSummary ? reviewSummary.freshness : "unknown",
    presentationComplete: presentationComplete,
    marketplace: marketplace,
    listedRepository: listed,
    installCommand: installCommand,
    installCommandReason: installCommandReason,
    highCriticalFindings: highCritical,
    rescanCommand: "omasafe-cli scan-plugin --git " + effectiveUrl + " --revision " + revision +
      " --report-profile review --format json",
    noActiveFindings: findingOmission.total === 0 && findingOmission.omitted === 0
  }
}
