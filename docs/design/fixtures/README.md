# Fixtures

Captured from `omasafe-cli 0.3.0` on the development host on 2026-09-09, and read by
`scripts/*-test.js` and `scripts/harness/`. They are evidence, not test data invented to
fit an assertion: every number the v0.3.1 tests assert is the analyzer's or the posture
collector's own.

| File | Captured with | Notes |
|---|---|---|
| `posture-v1.json` | `omasafe-cli posture export --format json` | 18 checks, catalog v1, 12 tools (arch-audit missing), coverage `complete 14 · incomplete 2 · errors 0 · not_applicable 2`. |
| `posture-not-yet-run.json` | the same, with `XDG_STATE_HOME` pointed at an empty dir | `status: not_yet_run`, no checks. |
| `candidate-git-review.json` | `scan-plugin --git https://github.com/tuthan/omasafe-plugin.git --revision 1316286681f0536288331f4e2dedd91fd5e8b1cd --report-profile review` | The exact-commit Source Scan capture. `target.source: pinned-revision` with an `acquisition` block, so `Candidate.build()` accepts it. 32 findings, 2 rules, 63 capability uses, 49 payload entries. |
| `candidate-path-review.json` | `scan-plugin --path . --report-profile review` | Exercises the analyzer against the working tree, but is **not** a Source Scan report: it emits `target.source: local-directory` and no `acquisition` block, and `Candidate.build()` rejects it. Valid for the derivations only; the test grafts its `review_summary` onto a valid envelope. 33 findings, one rule, 73 payload entries. |
| `installed-analyze.json` | `plugins analyze io.github.tuthan.omasafe --cached` | The `full` profile: `canonical-full-v1`, every `omitted` 0, `sizing_recovery.applied` false. This is what the T12 no-change case is asserted against. |

## Synthetic fixtures

These two are **hand-built**, not captured, and are named accordingly. They exist because
the shapes they carry cannot be produced by the installed CLI.

| File | Why it is synthetic |
|---|---|
| `posture-cli031-synthetic.json` | Carries `checks[].previous_state` and `checks[].gap_open_since`, the two CLI 0.3.1 fields (doc 08 C1, C2). `omasafe-cli 0.3.0` emits **neither**, so the T10 change and gap-age marks cannot be rendered from a real capture yet. Every check's `previous_state` equals its `state` except `updates.repository`, so this fixture is also the all-equal trap detector: sixteen checks must render no delta mark and exactly one must. |
| `candidate-partial-capabilities-synthetic.json` | The `candidate-git-review` capture with `capabilities.omitted` raised to 7. `scan-plugin` on this repository omits nothing, so the PARTIAL capability strip — every unobserved position `–`, counts prefixed `at least` — has no real report to render from. |

**A synthetic fixture is never sufficient acceptance on its own.** T10 in particular does
not ship as verified until a real two-run sequence on a changed host produces at least
one delta mark: exporting today's `posture-state.json → previous_states` map would make
`previous_state == state` for every check, and this fixture would pass that bug
undetected. See `../../v0.3.1-plan.md` §5.

## Re-capturing

```sh
omasafe-cli posture export --format json > posture-v1.json
tmp=$(mktemp -d); XDG_STATE_HOME=$tmp omasafe-cli posture export --format json > posture-not-yet-run.json
omasafe-cli scan-plugin --path . --report-profile review --format json > candidate-path-review.json
omasafe-cli scan-plugin --git <URL> --revision <40-hex> --report-profile review --format json > candidate-git-review.json
omasafe-cli plugins analyze <PLUGIN_ID> --format json --cached > installed-analyze.json
```

The tests assert reconciliations (parts summing to their totals) rather than constants
wherever a re-capture would legitimately move a number.
