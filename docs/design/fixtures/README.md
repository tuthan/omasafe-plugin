# Fixtures

Captured from `omasafe-cli 0.3.1` on the development host on 2026-09-09, and read by
`scripts/*-test.js` and `scripts/harness/`. They are evidence, not test data invented to
fit an assertion: every number the v0.3.1 tests assert is the analyzer's or the posture
collector's own.

| File | Captured with | Notes |
|---|---|---|
| `posture-v1.json` | `omasafe-cli posture export --format json` | 18 checks, catalog v1, 12 tools (arch-audit missing), coverage `complete 14 · incomplete 2 · errors 0 · not_applicable 2`. Steady state: two scans a moment apart, so every check carries `previous_state == state` and the tab renders no delta marks. |
| `posture-two-run.json` | two `posture scan` runs against an isolated `XDG_STATE_HOME`, with a world-writable directory placed on `PATH` between them | **The T10 acceptance.** `execution.path` reads the real `PATH`, so this is a genuine observable change on real hardware, not a fixture edit. Exactly one check reports a differing `previous_state` (`execution.path: pass → regression`); the other 17 carry `previous_state == state`. That discrimination is precisely what exporting `posture-state.json → previous_states` would have destroyed. |
| `posture-not-yet-run.json` | the same, with `XDG_STATE_HOME` pointed at an empty dir | `status: not_yet_run`, no checks. |
| `candidate-git-review.json` | `scan-plugin --git https://github.com/tuthan/omasafe-plugin.git --revision 1316286681f0536288331f4e2dedd91fd5e8b1cd --report-profile review` | The exact-commit Source Scan capture. `target.source: pinned-revision` with an `acquisition` block, so `Candidate.build()` accepts it. |
| `candidate-path-review.json` | `scan-plugin --path . --report-profile review` | Exercises the analyzer against the working tree, but is **not** a Source Scan report: it emits `target.source: local-directory` and no `acquisition` block, and `Candidate.build()` rejects it. Valid for the derivations only; the test grafts its `review_summary` onto a valid envelope. |
| `installed-analyze.json` | `plugins analyze io.github.tuthan.omasafe` | The `full` profile: `canonical-full-v1`, every `omitted` 0, `sizing_recovery.applied` false. This is what the T12 no-change case is asserted against, and it carries the 0.3.1 `capabilities.by_class` block. |

## Synthetic fixtures

These two are **hand-built**, not captured, and are named accordingly. They exist because
the shapes they carry cannot be produced by the installed CLI.

| File | Why it is synthetic |
|---|---|
| `candidate-partial-capabilities-synthetic.json` | The `candidate-git-review` capture with `capabilities.omitted` raised to 7. `scan-plugin` on this repository omits nothing, so the PARTIAL capability strip — every unobserved position `–`, counts prefixed `at least` — has no real report to render from. |

**A synthetic fixture is never sufficient acceptance on its own.** T10's synthetic
fixture was retired once `omasafe-cli 0.3.1` could produce the real thing:
`posture-two-run.json` replaces it. The reason still stands — a fixture where every
check has `previous_state == state` is exactly what the `previous_states` export bug
produces, so "no delta marks" only means something beside a capture that does produce
one. See `../../../omasafe-docs/Plugin/v0.3.1-plan.md` §5 and `../../../omasafe-docs/Cli/plans/v0.3.1.md`.

## Re-capturing

```sh
omasafe-cli posture scan --format json >/dev/null   # twice, so previous_state is populated
omasafe-cli posture export --format json > posture-v1.json
tmp=$(mktemp -d); XDG_STATE_HOME=$tmp omasafe-cli posture export --format json > posture-not-yet-run.json
omasafe-cli scan-plugin --path . --report-profile review --format json > candidate-path-review.json
omasafe-cli scan-plugin --git <URL> --revision <40-hex> --report-profile review --format json > candidate-git-review.json
omasafe-cli plugins analyze <PLUGIN_ID> --format json --cached > installed-analyze.json
```

The tests assert reconciliations (parts summing to their totals) rather than constants
wherever a re-capture would legitimately move a number.
