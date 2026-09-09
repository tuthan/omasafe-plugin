# 08 — Glanceability: dashboard research and the OmaSafe chart contract

Research note for the Posture and Source Scan surfaces. It audits what those two tabs render today against a
real `omasafe.posture.v1` report and a real `omasafe.report.v1` review report captured on this machine, reviews
how other security and system dashboards solve the same problem, and derives the encoding contract and the
component set that [`09`/`v0.3.1-plan`](../v0.3.1-plan.md) implements.

It is subordinate to [`02 — design principles`](02-design-principles.md). Where the two disagree, `02` wins;
where this document extends `02` (new glyphs, chart encodings, tier-colour ownership) the extension is written
out explicitly in §6 and §9 so it can be folded back into `02`.

Versions: omasafe-cli `0.3.0` · plugin `0.4.0` · Omarchy `4.0.2-1` · Qt `6.11.2` · JetBrainsMono Nerd Font.

## Contents

1. [Method and measurements](#1-method-and-measurements)
2. [Audit: what the two new tabs do to a reader](#2-audit-what-the-two-new-tabs-do-to-a-reader)
3. [Reference dashboards: what to take, what to refuse](#3-reference-dashboards-what-to-take-what-to-refuse)
4. [The OmaSafe chart contract](#4-the-omasafe-chart-contract)
5. [Proposed surfaces](#5-proposed-surfaces)
6. [Glyph additions](#6-glyph-additions)
7. [What OmaSafe must never draw](#7-what-omasafe-must-never-draw)
8. [Data availability](#8-data-availability)
9. [Open decisions](#9-open-decisions)
10. [Sources](#10-sources)

---

## 1 Method and measurements

Everything below is measured against live output from the installed CLI, not from fixtures:

```sh
omasafe-cli --version                                     # omasafe-cli 0.3.0
omasafe-cli posture export --format json                  # 12,852 bytes, 18 checks
omasafe-cli scan-plugin --path . --report-profile review --format json   # 140,109 bytes
XDG_STATE_HOME=$tmp omasafe-cli posture export --format json             # status: not_yet_run
```

**What the `--path` capture is and is not.** It exercises the analyzer, so every `review_summary`,
`analysis.*` and `payload_inventory` figure quoted below is real. It is **not** a Source Scan report: `--path`
emits `target.source: "local-directory"` and **no `acquisition` block**, and `Candidate.build()` rejects it
twice over — `model/Candidate.js:390` fails on the missing acquisition, and `:418` requires `target.source` to be
one of `resolved-git-request · pinned-revision · marketplace-listing`. It is therefore valid evidence for the
*shape and distribution* of a review report and unusable as a `CandidateView` fixture. An exact-commit Git
capture is required for that, and the plan makes it a T5 prerequisite:

```sh
omasafe-cli scan-plugin --git https://github.com/OWNER/REPO.git --revision <40-hex> \
  --report-profile review --format json
```

**Posture report shape.** Top-level keys `schema · status? · check_catalog_version · generated_at ·
result_age_seconds · host · tools · checks · coverage · last_observed_post_update_hook`. On this host: 18
checks, catalog v1, 12 declared tools (11 available, `arch-audit` missing), coverage
`complete 14 · incomplete 2 · errors 0 · not_applicable 2` and 5 distinct coverage limitations.

State distribution on this host, which is the distribution the UI has to make readable:

| State | Count | Checks |
|---|---|---|
| `pass` | 6 | `encryption.root_luks` `execution.path` `host.context` `kernel.restart` `packages.keyring` `updates.omarchy` |
| `informational` | 7 | `boot.secure_boot` `firewall.configuration` `firewall.service` `network.listeners` `packages.foreign` `persistence.selected` `updates.post_update_hook` |
| `regression` | 1 | `updates.repository` |
| `incomplete` | 2 | `firewall.effective` `vulnerabilities.arch_audit` |
| `not_applicable` | 2 | `packages.integrity` `ssh.configuration` |
| `error` | 0 | — |

**Source Scan report shape.** `result.review_summary` already carries `severity_counts`, `rule_counts`,
`findings{total,emitted,omitted,suppressed,active,by_rule,by_severity}`, `capabilities{…}`,
`coverage{assessment, payload_states, gap_total, by_reason, language_model_gaps, …}`, `max_severity`,
`presentation_collections` and `presentation_complete`. On this repository: 33 findings, all `medium`, all from
one rule; 72 capability uses across 3 classes; coverage `partial` with payload states
`analyzed 23 · partial 1 · unsupported 24 · unreferenced 18 · truncated 0 · skipped 0` over 66 entries.

`model/Candidate.js` already normalises **every one of those fields** (`severityCounts`, `ruleCounts`,
`coverage.payloadStates`, `presentationCollections`, …). `views/CandidateView.qml` currently reads two of them.

**Unexposed CLI state — and a trap in it.** `~/.local/state/omasafe/posture-state.json` holds a
`previous_states` map and `coverage_episodes[].started_at` (when a coverage gap first opened). Neither reaches
`posture export`.

`previous_states` **is not the previous states.** `omasafe-posture::update_state()`
(`crates/omasafe-posture/src/lib.rs:579`) does `state.previous_states.insert(check.id, check.state)` — the
displaced prior value is bound to a local `prior` used only for notification suppression, and the map is
overwritten with the **current** states before the file is written. So the persisted map always equals the state
of the report that produced it. Exporting it verbatim would make `previous_state == state` for every check and
silently render zero change marks forever, which is worse than showing nothing: an absent mark would read as
"nothing changed". The value the panel needs exists at `update_state()` time and is thrown away; capturing it is
a CLI change, not an export change — see §8 C1.

`coverage_episodes[].started_at` has no such problem; it is genuine first-seen data. It is, however, serialised
as a bare unix-seconds **string** (`"1788872597"`) beside an RFC-3339 `last_seen_at` in the same object.

---

## 2 Audit: what the two new tabs do to a reader

### 2.1 Posture — correct, honest, and unreadable at a glance

`views/PostureView.qml` renders a header, four notice rows, a six-row host `InfoGrid`, then a flat `Repeater`
over `report.checks` in the CLI's own order, which is alphabetical by check id. Each check emits a title row plus
a `State:/Evidence:` block, an optional limitation line and an optional next-step line.

| Finding | Evidence | Consequence |
|---|---|---|
| **A1 · No overview layer.** The tab opens on check #1 of 18. | ≈90 rendered text lines; the compact panel body is ≈420 px tall at base 12, so the tab is ≈3 panel-heights of scroll. | The reader must scroll the whole report to learn what it says. Shneiderman's "overview first, zoom and filter, details on demand" is inverted into "details only". |
| **A2 · Attention items are buried by alphabet.** | The single `regression` (`updates.repository`) is item **17 of 18**. Both `incomplete` checks are #5 and #18. | The three things worth acting on are the three the reader is least likely to reach. |
| **A3 · The header prints the wrong axis.** | `SectionHeaderRow.value` = `coverageText()` = `14 COMPLETE · 2 INCOMPLETE · 2 N/A`. | `complete` here means *observation succeeded*, and includes the regression. A reader scanning the header reads "14 fine". This is the closest thing in the panel to an accidental verdict and it contradicts GR1. |
| **A4 · Coverage gaps are disconnected from their cause.** | `vulnerabilities.arch_audit` is `incomplete` because `tools[]` reports `arch-audit` unavailable. The tab renders the check and never renders `tools[]`. | The reader sees an unexplained gap instead of a one-command fix. |
| **A5 · No disclosure control on evidence.** | `network.listeners` joins 9 evidence strings into one wrapped line (~200 characters, ≈4 wrapped lines) and always renders it. | One noisy check dominates the tab. |
| **A6 · No cursor.** | `sectionCount("posture")` returns `1`; `sectionIsHorizontal` lists `posture`. | `j`/`k` skip the whole tab. 18 rows exist and none is reachable, focusable or copyable. P12 ("one cursor, a fixed key grammar") does not hold here. |
| **A7 · Nothing shows change.** | The report has no delta and the panel computes none. | "Did anything change since the last scan?" — the primary reason to re-run a posture scan — is unanswerable in the UI, although the CLI has the answer on disk. |

### 2.2 Source Scan — the summary exists in the model and never reaches the screen

| Finding | Evidence | Consequence |
|---|---|---|
| **B1 · No result summary band.** | The result column goes straight from the commit line to `FINDINGS` and then lists 33 finding blocks. `review_summary.severity_counts`, `rule_counts` and `coverage.payload_states` are normalised and unused. | The reader learns "33 findings" and then reads 33 near-identical blocks to discover they are one rule. |
| **B2 · "Is this one problem or 33?" is unanswerable.** | `rule_counts = { oma.qml.out-of-tree-reference: 33 }`. | The single most review-shortening fact in the report is not rendered. |
| **B3 · The real coverage story is a comma list.** | Only **23 of 66** payload entries were analysed; 24 are `unsupported` and 18 `unreferenced`. This renders as `Coverage states: analyzed: 23 · partial: 1 · …` in `bodySmall` dim, below findings, capabilities and the install command. | The strongest argument against trusting an empty finding list is placed where nobody reads it. |
| **B4 · Omission notices are a wall.** | Up to five separate `NoticeRow`s (`presentation incomplete`, `findings omitted`, `findings hidden`, `capabilities hidden`, `edges/gaps hidden`) plus a bare `Evidence observations omitted: N` line. | Each is individually correct; together they read as boilerplate and get skipped. This is exactly the failure Grype documents in [issue #1312](https://github.com/anchore/grype/issues/1312): a summary whose parts do not visibly reconcile stops being read. |
| **B5 · Candidates and installed plugins are read differently.** | An installed plugin shows a 17-cell `CapabilityStrip`; a candidate shows a flat text list of `capability · path · detail`. | The reviewer cannot compare "what this candidate can do" with "what my installed plugins do" using the same visual. |
| **B6 · No cursor.** | `sectionCount("source-scan")` returns `1`. | Same as A6: 33 findings, no keyboard reach. |

### 2.3 Cross-cutting

- **C1 · The tabs carry no counts.** `Overview · Analysis · Rules · Posture · Source Scan`. Nothing tells the
  reader which tab has something in it, so the only way to find work is to visit all five.
- **C2 · Posture never reaches the bar.** `BarWidget.alertCount` is the plugin-alert count only. A `regression`
  can sit unseen indefinitely; README already records this as the deferred M7 indicator.
- **C3 · Two tier-colour owners are emerging.** `02 §2.3` names `SemanticMark.qml` the sole owner of semantic
  tier colours. Any bar or strip needs the same palette, so either it duplicates the ladder or the ladder moves.

### 2.4 The older tabs, re-read under the new rules

Overview, Plugin detail, Rules and Analysis were written before D7 and the chart contract existed. Re-reading
them against those rules finds one latent defect of the same class, one live disclosure gap, and three
asymmetries where a candidate and an installed plugin now show the same data two different ways.

| Finding | Evidence | Status |
|---|---|---|
| **E1 · The completeness guard is missing on the installed path.** `ViewModel._capCounts()` (`model/ViewModel.js:46`), `_ruleOccurrences()` (`:60`) and `_pluginByClass()` (`:620`) group `analysis.capabilities[]` and `analysis.findings[]` without ever consulting `report_profile.omissions`. Consumers that render an absent class as `·` — "analyzed, none observed" — are `CapabilityStrip` on **every Overview row**, `MatrixGrid` cells (`Panel.qml:2177–2178`), and the Flow CAPABILITIES layer. | **Latent, not live.** `plugins analyze` uses `canonical-full-v1` with `serialized_byte_limit: null`; on this host every `omitted` is `0` and `sizing_recovery.applied` is `false`. `ViewModel.js` applies no display cap of its own (its only `slice` is `_commit7`). So the counts are complete today. | Fix cheaply now: the guard is absent, the failure is silent, and it fails toward "clean". The candidate path is being fixed by D7 in the same release; leaving the installed path unguarded makes the asymmetry the bug. |
| **E2 · Rules can print a green check from absent data.** `RuleRow.qml:105–108` renders `SemanticMark level: "healthy"` — the panel's only green mark on that tab — when `noLocalHits && analysisComplete`. `noLocalHits` is computed from `_ruleOccurrences()` over the same arrays, and **`analysisComplete` means only "every installed plugin has been analyzed"** (`ViewModel.js:398`), not "the analysis payload is complete". `buildBaseline().observedText()` (`:435–442`) prints "not observed in N analyzed plugins" from the same basis. | Latent for the same reason as E1, and the highest-consequence instance: a positive claim, in green, from data that could be missing. | The two conditions must be separated and both required. |
| **E3 · Plugin detail truncates changed files silently.** `PluginDetailView.qml:227` renders `changed_files.slice(0, 5)`. The section header prints the true total (`N FILES`), but nothing marks entries 6+ as hidden. | **Live today.** | The candidate view discloses every display cap; the installed view does not. Same rule, one line. |
| **E4 · Coverage states are prose here and a bar there.** `Panel.analysisCoverageLabel()` (`:715–731`) joins `analyzed · partial · unsupported · skipped · truncated · unreferenced` into one dim string; §5.4 gives a candidate the identical data as a `MeterBar`. | Live asymmetry. | Same numbers, same words, one presentation. |
| **E5 · Findings-by-rule exists only for candidates.** §5.4's `BY RULE` answers "one rule or 33?"; the installed detail view lists findings flat with no rule rollup, although `review_summary.rule_counts` is present in the `plugins analyze` report. | Live asymmetry. | Reuse `RankedBars`. |
| **E6 · Baseline V3 is a part-to-whole in prose.** `RulesView.baselineSummary()` renders `N SAME CHECKS · N PARTIAL · N NO CHECKS` over the ~45-rule catalog. | Live. | n > 24, so CH2 says length bar, with the existing counts line kept verbatim. |

**Blast radius of the T9 glyph change is small, and verified.** Only nine `SemanticMark.level` bindings exist
across `components/`, `views/` and `graph/`. Of the variable ones, `PluginRow.healthState` resolves to
`stale · healthy · unknown · <severity>` (`ViewModel.js:143–147`) and `ClassRow`/`FlowNode.riskLevel` to
`stale · <severity>` (`:776`, `:797`, `:808`) — **none can be `incomplete`**. Re-pointing the `incomplete` tier
at its own glyph therefore changes no existing surface; it only stops the new posture strip from drawing
severity `high`'s mark for "we could not look".

---

## 3 Reference dashboards: what to take, what to refuse

### 3.1 Refuse: the single score

[Lynis](https://linux-audit.com/lynis/lynis-hardening-index/) prints a 0–100 hardening index; its own
documentation has to add that "a high Lynis score does not mean a server is secure — it means the configuration
follows common best practices". A comparative study found the index barely moves across hardening levels
(63.08 → 64.92) while OpenSCAP over the same systems moved 39.73 → 71.82 — a scale that does not discriminate is
worse than no scale. 1Password's Watchtower score shows the other failure mode: users report the same score for
years despite real remediation, and the number differs by 40 points between the web and desktop clients, so
the community reads it as "an arbitrary metric designed for you to feel good". Design agencies working in this
space now describe the single risk gauge as "the archaic gasoline gauge style of Cyber Risk Score".

**Taken:** nothing. This validates GR1 and P1 from the outside: OmaSafe's refusal to score is not an omission,
it is the differentiator. Say so once, in the tab, in words.

### 3.2 Take: four result states, never three

[OpenSCAP/XCCDF](https://www.redhat.com/en/blog/center-internet-security-cis-compliance-red-hat-enterprise-linux-using-openscap)
reports `pass · fail · notchecked · notapplicable` as first-class, equally-rendered outcomes. OmaSafe's six
states (`pass · informational · attention · regression · incomplete · error · not_applicable`) are the same idea
with more resolution.

**Taken:** `incomplete` and `not_applicable` get their own marks, their own counts and their own place in the
summary — never folded into a "remaining" bucket, never coloured like `pass`. This is GR3 rendered.

### 3.3 Take: the unit chart, for small n

The waffle/unit chart literature is unambiguous for exactly OmaSafe's cardinality: "because a waffle chart maps
each percent to a countable square, readers can verify a result like 38% vs 34% by counting, whereas a pie
forces them to judge two nearly identical angles", and unit charts avoid the sliver problem entirely when each
cell is one item. With **18 checks**, one cell per check is countable, exact, and needs no proportion judgement
at all.

**Taken:** the posture check strip (§5.1) is a unit chart — and it is the idiom the panel already uses. The
17-cell `CapabilityStrip` is a unit chart in everything but name: fixed catalog order, one cell per class,
position carries identity. Extending that idiom to posture costs the reader nothing to learn.

### 3.4 Take: length, ranked; refuse angle, area, saturation

Cleveland & McGill's ranking — position on a common scale > length > angle/slope > area > volume/saturation >
hue — is the reason `02 §2.4` already bans hue-alone and opacity ramps. Position judgements were measured
1.4–2.5× more accurate than length and ~2× more accurate than angle.

**Taken:** every OmaSafe chart is a unit chart (position) or a segmented length bar. No pie, no donut, no gauge,
no bubble, no saturation ramp. Where a bar is used, the exact count is printed adjacent, so the bar is a shape
aid and the number is the datum (P1).

### 3.5 Take: discrete-state rendering, and its honest degenerate case

Grafana's [State timeline](https://grafana.com/docs/grafana/latest/visualizations/panels-visualizations/visualizations/state-timeline/)
and [Status history](https://grafana.com/docs/grafana/latest/visualizations/panels-visualizations/visualizations/status-history/)
panels exist because discrete states over time are not a line chart: region length is duration, and consecutive
equal values may or may not be merged.

**Taken, with a limit.** OmaSafe retains **one** posture observation on disk, and — once C1 lands — one prior
state word per check. That is a delta, not a series: a timeline would be two cells wide and would imply a history
the product does not keep. In 0.3.1 the delta is
rendered as one mark plus the words "changed from `informational`" on the affected row (§5.3). A real state
timeline is a 0.4 item and requires the CLI to retain N reports (§8, C4).

### 3.6 Take: the reconciliation line

Grype [issue #1312](https://github.com/anchore/grype/issues/1312) is the canonical write-up of OmaSafe's B4:
users ask "what is this trying to tell me? what is this hiding?" about a severity summary at least weekly,
and the fix the maintainers converge on is that **the sum of the parts must visibly equal the total in the final
output**. GitHub's code scanning UI reaches the same place from the other side: it groups related paths under one
alert so the count means something, and its 2026 changelog work was a *unified* filter bar rather than more
per-surface controls.

**Taken:** the five omission notices collapse into one arithmetic line that always adds up (§5.5); a `NoticeRow`
appears only when a term is non-zero, and then one, not four.

### 3.7 Take: monospace density discipline

The [Monospace TUI design standard](https://github.com/coreyt/monospace-design-tui) prescribes two rules OmaSafe
already half-holds: "Color MUST NOT be the sole indicator of any state or meaning" — every colour paired with a
text label, a typographic attribute, or a symbol — and a closed spacing scale with intermediate values
forbidden. btop is the density reference: CPU, memory, disk, network and processes in one screen using block and
braille cells.

**Taken:** the colour rule is already `02 §2.4`; the new components must not break it. The block-cell technique
is **verified available** (U+2581–U+2588, U+258F–U+2588, U+2591–U+2593 and the braille range are all present in
`JetBrainsMonoNerdFont-Regular.ttf`) but is **not adopted** — see §9 D2.

### 3.8 Take: overview first, and F-shaped scanning

Shneiderman's mantra ("overview first, zoom and filter, then details-on-demand") and NN/g's dashboard work
(users abandon dashboards that are slow to read; scanning is F-shaped — a horizontal sweep across the top, then
down the left) both put the summary in the top band and the identity column on the left.

**Taken:** both new tabs get a fixed top summary band, and both leave the leftmost column to identity (state
mark, then check title / rule id), never to a number.

---

## 4 The OmaSafe chart contract

Extends `02 §2.4`. A chart in this panel is a **shape aid attached to printed numbers**, never a substitute
for them.

| Rule | Statement |
|---|---|
| **CH1 — Numbers first** | Every chart is adjacent to a line that prints each category's exact count. Remove the chart and the reader loses speed, never information. |
| **CH2 — Unit chart when n ≤ 24, length bar above it** | One cell per item while items are countable at a glance; a segmented length bar once they are not. Never both for the same data in the same band. |
| **CH3 — Position and length only** | Permitted channels: cell position in a fixed order, segment length along a common baseline, rank order in a sorted list. Forbidden: angle, area, radius, saturation, opacity, blur, 3-D. |
| **CH4 — Colour is the third channel, never the first** | Every segment and every cell carries a word (in the legend or the row it links to) and a glyph. Colour comes from the semantic tier ladder and adds nothing that the word and glyph do not already say. |
| **CH5 — The parts reconcile, visibly** | Segment counts sum to the printed total. Where the report omits or the UI caps, the omitted term is a named part of the same line, not a separate notice. |
| **CH6 — A minimum segment is disclosed, not hidden** | A non-zero category is never invisible: minimum segment width `Style.space(2)`. Because that breaks strict proportionality at the small end, CH1's printed counts are the datum and the bar is explicitly labelled as an aid. |
| **CH7 — Zero and absent are different marks** | `0` prints as `0` in a legend of a chart that ran. Not observed prints `–`. Observed-and-none prints `·`. A chart that could not be computed renders the word `unavailable` and no bar. |
| **CH8 — Fixed order, or explicit order** | A unit strip is always in a CLI-owned catalog order so a cell position means the same thing on every host and every run. A bar is always in attention order (`error → regression → incomplete → attention → informational → pass → not applicable`) and the order is stated in the header. |
| **CH9 — No chart implies a verdict** | No chart is titled with a judgement, has a target line, a threshold zone, a "good" direction, or an aggregate. Section titles are nouns: `STATES`, `COVERAGE`, `BY RULE`. |
| **CH10 — Charts cost no motion** | Charts are static geometry. No animated draw-in, no transition on data change beyond the existing 60/120 ms colour behaviours. Nothing animates while the panel is closed (P11). |

---

## 5 Proposed surfaces

Wireframes are at base 12 in the compact 420-unit panel. ASCII stands in for Nerd glyphs.

### 5.1 Posture summary band — unit strip + two counts + causal tools line

```
HOST POSTURE                                     CATALOG V1 · 18 CHECKS
  i  v  v  i  %  i  v  v  i  i  _  v  i  _  v  i  !  %
  1 regression · 2 incomplete · 7 informational · 6 pass · 2 not applicable
  Observation completed for 14 of 18 checks. 2 incomplete, 2 not applicable.
  Report 7 minutes old · arch 7.1.9-arch1-2 · Omarchy 4.0.2-1
  Tools 11 of 12 observed · arch-audit unavailable, 1 check left incomplete
```

- One cell per check, **in catalog order** (CH8), so cell 17 is always `updates.repository`. `check_catalog_version`
  pins the order; a check absent from the running catalog renders `–` (CH7).
- Each cell is the state glyph in its tier colour; the cell's tooltip is `<title> · <STATE>`; Enter or click moves
  the cursor to that check's row and scrolls it into view.
- The counts line is in attention order (CH8), and it is the **state** axis. The coverage sentence is the
  **observation** axis, written as a sentence precisely so it cannot be mistaken for a health tally — this is the
  direct fix for A3.
- The tools line is the fix for A4: it states the count, names the missing tool, and states the consequence in
  the same sentence.

### 5.2 Posture body — attention first, then grouped and collapsed

```
NEEDS ATTENTION                                                        3
!  REGRESSION   Repository package updates
   47 package updates are available
   Next step  Review and apply pending updates.
%  INCOMPLETE   Effective firewall policy                     open 6 days
   Not observed  runtime firewall policy was denied or unavailable to the
                 unprivileged scan
   Next step  Run the posture scan as the supported user session.
%  INCOMPLETE   Known official package vulnerabilities        open 6 days
   Not observed  required tool arch-audit was unavailable
   Next step  Install arch-audit and re-run.              [Copy command]

OBSERVED                                                              15
  FIREWALL  2
    i  Firewall configuration                              2 observations
    i  Firewall service state                              1 observation
  PACKAGES  3
    i  Foreign package inventory                     13 foreign packages
    _  Pacman package integrity metadata                 not applicable
    v  Pacman keyring state
  UPDATES  2
    v  Omarchy update availability
    i  Last observed post-update hook                     not verified
  …
```

- **Attention set** = `error · regression · incomplete · attention`, expanded, with evidence and next step
  visible. Everything else collapses to one line, grouped by the domain prefix of the check id (`firewall`,
  `packages`, `updates`, …), Enter to expand.
- Collapsed rows carry a right-aligned **one-fact summary** derived from the check's first evidence string, so the
  collapsed state is still evidence and not a bare state word.
- `open 6 days` needs CLI field C2 (§8); until it lands the slot renders nothing rather than a guess.
- This takes the tab from ≈90 lines to ≈35 collapsed, with the three actionable items above the fold.

### 5.3 Posture change marks (CLI-gated)

On any check whose state differs from the prior state the CLI reports (C1 — **not** today's `previous_states`
map, see §1), the row gains a delta mark and the words:

```
!  REGRESSION   Repository package updates          d changed from pass
```

No arrow, no trend line, no colour direction — `informational → pass` is not "up". One mark, one sentence, and
the previous state named. Renders only when the CLI supplies it; absent field means absent mark, never "no
change" (GR3).

### 5.4 Source Scan result band

```
SOURCE SCAN RESULT                        7ab19c4 · REVIEW PROFILE · FRESH
github.com/OWNER/REPO
commit 7ab19c4e2f7d… · scan-only · nothing was installed or enabled

FINDINGS  33
[################################################################]
0 critical · 0 high · 33 medium · 0 low · 0 info
33 shown · 0 omitted by the scanner · 0 hidden by the display cap · 0 suppressed

BY RULE
oma.qml.out-of-tree-reference   [##############################]   33

CAPABILITIES  72 uses · 3 classes · 2 files
PX  ·  ·  ·  ·  ·  ·  TM  CB  ·  ·  ·  ·  ·  ·  ·  ·
persistence-scheduling 47 · process-execution 22 · clipboard-access 3

COVERAGE  partial · 66 payload entries
[## analyzed 23 ##][# 1][##### unsupported 24 #####][### unref 18 ###]
23 analyzed · 1 partial · 0 truncated · 0 skipped · 24 unsupported · 18 unreferenced
1 coverage gap (dataflow-statement-limit) · 1 limitation
```

- **Severity bar** — segmented length bar over the five tiers in attention order, exact counts printed beneath
  including the zeros (CH5, CH7). This is the fix for B1.
- **By rule** — ranked horizontal bars, top 5 by count, `+N more rules` when truncated. Fix for B2; it turns
  "33 findings" into "one rule, 33 times", which is a different review.
- **Capabilities** — a 17-cell strip in the same catalog order, so a candidate and an installed plugin are read
  the same way (fix for B5). It is built on the new `UnitStrip`, **not** on `CapabilityStrip`, because the
  candidate's capability list is not guaranteed complete: `analysis.capabilities[]` is scanner-selected and
  capped again in the model, and `CapabilityStrip` renders every absent class as `·` — "analyzed and not
  observed". Under omission that is a false negative in the one direction GR3 forbids. The rule is:

  | Capability data | Absent cell | Counts line |
  |---|---|---|
  | `omitted == 0` and display cap not hit | `·` (observed, none) | exact counts |
  | anything omitted or capped | `–` (no data) | counts prefixed `at least`, and the header reads `CAPABILITIES · PARTIAL` |
  | capability collection unavailable | whole strip replaced by the word `unavailable` | no counts |

  An omission `NoticeRow` does not fix this on its own: the strip is read before the prose, and 17 cells of `·`
  say "clean" louder than a sentence says "incomplete". C5 (§8) removes the partial case entirely by giving the
  panel a complete per-class aggregate.
- **Coverage bar** — segments from `payload_states` over `totals.entries`. Fix for B3: it makes "23 of 66
  analysed" the second thing the reader sees rather than the last.
- The band is **above** findings, so the F-shaped first sweep lands on it.

### 5.5 One reconciliation line

Replaces the five omission notices. Always printed, per collection:

```
33 shown · 0 omitted by the scanner · 0 hidden by the display cap · 0 suppressed
```

A `NoticeRow` is raised only when a term is non-zero, and one covers all collections:

```
?  This report omits evidence: 4 findings omitted by the scanner and 2 capabilities
   hidden by the display limit. An empty list is not a safety conclusion.
```

The existing "presentation incomplete" and "install command withheld" behaviours are unchanged — this is a
presentation collapse, not a relaxation of any boundary.

### 5.6 Cursor and keyboard

Both tabs get real cursor sections so P12 holds:

A section's count is its number of **selectable targets**, not its number of rows on screen —
`moveCursorH()` (`Panel.qml:1040–1042`) clamps `selectedIndex` to `sectionCount() - 1`, so a horizontal section
declaring `1` pins the cursor on its first cell and makes every later cell unreachable.

| Section | Count | Notes |
|---|---|---|
| `posture-strip` | one per check (18 on this host) | horizontal; `h`/`l` walks cells, Enter jumps to the check |
| `posture-attention` | one per attention check | |
| `posture-groups` | one per domain group | Enter expands |
| `posture-checks` | one per expanded check | |
| `scan-summary` | one per enabled copy action | horizontal |
| `scan-findings` | one per displayed finding | Enter expands evidence steps |

No new keys. `r` already runs the tab's scan; `/` (finder) is extended to filter posture checks by title/state
and scan findings by rule/path.

### 5.7 Tab chips carry counts

```
[ Overview 2 ] [ Analysis ] [ Rules ] [ Posture 3 ] [ Source Scan · ]
```

Counts use the existing placeholder vocabulary verbatim (`02 §2.4`): a digit when observed, `·` when observed
and none, `–` when not run or unavailable. Posture's count is the size of the **same attention set §5.2
renders** — `error · regression · incomplete · attention` — read from the view-model rather than recomputed, so
the chip and `NEEDS ATTENTION` cannot disagree. It is a count of items to look at, not a health score. A chip
with no count is a tab with no collector, never a clean tab.

### 5.8 Bar widget

`alertCount` stays the plugin-alert count — it is a published contract and a second number in a bar slot is
noise. The shield tooltip gains one line:

```
OmaSafe: 2 alerts to review
Host posture: 1 regression, 2 incomplete (7 minutes old)
```

Whether posture ever enters the bar *count* is decision D3 (§9), deferred out of 0.3.1.

### 5.9 New components

| File | Purpose | Notes |
|---|---|---|
| `components/UnitStrip.qml` | Fixed-order unit/waffle strip: `cells: [{ key, glyph, level, label, tooltip }]`, fixed `cellW`, wraps to a second row when `cells × cellW > width`. | New. `CapabilityStrip.qml` keeps its structure in 0.3.1 and the two merge later (§9 D4); its only change is the `complete` property E1 requires. |
| `components/MeterBar.qml` | Segmented length bar: `segments: [{ key, count, level, label }]`, `total`, min segment `Style.space(2)`, `BorderSurface` track at `Style.cornerRadius`. Emits nothing; the legend is a sibling. | New. Implements CH5/CH6. |
| `components/RankedBars.qml` | Sorted `{label, count}` rows with a length bar and printed count, `maxRows` + `+N more`. | New. Used by BY RULE and, later, by top-files. |
| `model/Tiers.js` | Pure module owning the semantic tier colour ladder and its dark/light variants. | `SemanticMark.qml` and both new chart components read it. Amends `02 §2.3`'s "SemanticMark is the sole owner" — see D1. |
| `model/Posture.js` | Pure view-model for `omasafe.posture.v1`: catalog ordering, state counts, attention partition, domain grouping, strip cells, tool→check linkage, age words. | Mirrors `model/ViewModel.js` / `model/Candidate.js`. Testable with `scripts/posture-test.js`. |

### 5.10 Aligning the older tabs

The four components above are built for Posture and Source Scan; three of the six findings in §2.4 are closed by
pointing an existing surface at one of them. Nothing here needs new CLI data.

| Surface | Change | Component |
|---|---|---|
| `ViewModel.js` capability and rule-occurrence derivations (E1, E2) | One `analysisComplete` verdict computed once from `report_profile.omissions`, carried on the plugin object beside `analyzed`, and consumed by every count. `analyzed` answers "did we analyse it"; the new flag answers "is what we got complete". | — |
| Overview `CapabilityStrip`, `MatrixGrid` cells, Flow CAPABILITIES layer (E1) | Under incomplete data, absent positions render `–` not `·`, exactly as D7 rules for the candidate strip. `MatrixGrid` gains a third cell state for the same reason: `digit` · `·` · `–`, where `–` now covers both "not analyzed" and "analysed, completeness unknown". | — |
| `RuleRow` green check and Baseline `observedText()` (E2) | The green mark additionally requires payload completeness. Where it is not established the row keeps its count and drops the mark — a rule with no observed hits reads `0` in `dim`, never a green "No local hits". | — |
| Plugin detail changed-files list (E3) | `+N more changed files` under the fifth row. | — |
| Plugin detail coverage states (E4) | `analysisCoverageLabel()`'s six states become a bar plus the same counts line the candidate gets. | `MeterBar` |
| Plugin detail review items (E5) | A `BY RULE` block above the flat finding list, from `review_summary.rule_counts`. | `RankedBars` |
| Rules Baseline V3 summary (E6) | `baselineSummary()`'s three counts become a bar; the existing text line stays as the legend. | `MeterBar` |

**Where not to add a chart.** Restraint is part of the contract, and this is the release where the temptation is
highest:

- **Overview alerts** — a handful of rows. Per CH2 the list *is* the unit chart; a severity bar over four alerts
  adds a shape and no information.
- **`MatrixGrid`** — already the right answer. Digits are exact and position-encoded; adding a colour ramp behind
  them would import the heatmap CH3 bans and `02 §2.4` already refused.
- **The Flow graph** — already position- and length-encoded (column position, edge thickness by bucket). No
  additional chart belongs in it.
- **The hero** — no sparkline, no ring, no count beyond what `02` already specifies. The hero states one thing.

---

## 6 Glyph additions

Two new UI glyphs, verified today by **codepoint and glyph name** against
`/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf` with fontTools, per the `02 §2.7` rule that presence
alone is not enough:

| Meaning | Glyph name | Codepoint | ASCII | Why not an existing mark |
|---|---|---|---|---|
| Incomplete observation / open coverage gap | `md-progress_question` | U+F1522 | `%` | `SemanticMark` currently maps `incomplete` to the **alert** glyph, the same mark as severity `high`. In a unit strip, where the state word is not on the cell, "we could not look" and "high severity" become indistinguishable. A progress ring carrying a question is the honest shape. |
| Not applicable | `md-minus_circle_outline` | U+F0377 | `_` | `hollow` (U+F0766) is pinned by `02 §2.7` to "not analyzed / unavailable, Flow only", and "the check does not apply to this host" is a different fact from "we did not observe". |

One optional glyph, needed only when CLI field C1 lands:

| Meaning | Glyph name | Codepoint | ASCII | Notes |
|---|---|---|---|---|
| Changed since the previous report | `md-delta` | U+F01C2 | `d` | Direction is carried by the sentence ("changed from `pass`"), never by the mark. `md-trending_up`/`_down` are deliberately **not** used: there is no ordering in which `informational → pass` is "up". |

Also verified present and available if ever needed: `md-toolbox_outline` U+F09AD, `md-progress_alert` U+F0CBC,
`md-alert_circle_outline` U+F05D6, `md-history` U+F02DA, U+2581–U+2588 block elements, U+2591–U+2593 shades,
U+2800–U+28FF braille, U+2500-range box drawing. Of these only the two additions above are adopted.

`02 §2.7`'s constraint that no ASCII character carries two meanings holds: `%` and `_` are unused in the current
table.

---

## 7 What OmaSafe must never draw

Written down so a later contributor does not have to re-derive it from §3.1:

1. **A score, index, grade, percentage-healthy, or letter.** Not for the host, not for a plugin, not for a
   candidate. §3.1 is the evidence that scores in this category either mislead or stop moving.
2. **A gauge, speedometer, dial, or traffic light.** Angle plus hue, the two weakest channels, expressing an
   aggregate that GR1 forbids anyway.
3. **A pie or donut.** Angle judgement, and it invites "percentage secure".
4. **A saturation or opacity heatmap.** `02 §2.4` already bans the value channel; the Matrix lens prints digits
   for exactly this reason.
5. **A trend line, sparkline, or timeline over data the CLI does not retain.** Two observations are a delta, not
   a trend. Drawing a slope from one prior state word would fabricate history.
6. **A progress bar for coverage that reads as completion.** Coverage segments are labelled with their state
   words (`analyzed`, `unsupported`, `unreferenced`); no segment is ever "done" green and no bar ever "fills".
7. **Any chart of a suppressed, omitted, or capped set drawn as if complete.** CH5 is not optional.

---

## 8 Data availability

| # | Fact | Source today | Needed for | Ask |
|---|---|---|---|---|
| — | states, evidence, limitations, next steps, coverage rollup | `posture export` | §5.1 §5.2 | none — ships in 0.3.1 |
| — | `tools[]` availability, name, path, version | `posture export` | §5.1 tools line | none |
| — | `check_catalog_version` | `posture export` | §5.1 strip order | none |
| — | `result_age_seconds`, `generated_at`, `host` | `posture export` | §5.1 | none |
| — | `severity_counts`, `rule_counts`, `payload_states`, `presentation_collections` | `scan-plugin --report-profile review` | §5.4 §5.5 | none — already in `model/Candidate.js` |
| **C1** | previous state per check | **Does not exist in a persisted form.** `update_state()` computes it as the local `prior` and discards it, overwriting `previous_states` with the current states (§1) | §5.3 change marks | *CLI change, not an export change:* capture the displaced prior per check **before** the `insert`, persist it (e.g. `prior_states`, written from the same loop that already binds `prior`), and export it as `checks[].previous_state` (nullable). Exporting today's `previous_states` map would suppress every change mark |
| **C2** | how long a coverage gap has been open | `posture-state.json → coverage_episodes[].started_at` (on disk, **not exported**; a bare unix-seconds string beside an RFC-3339 `last_seen_at` in the same object) | §5.2 `open 6 days` | add `checks[].gap_open_since` as RFC-3339 and/or `gap_open_seconds`; fix the `started_at` serialisation while there |
| **C3** | stable strip index per check | derivable in QML from `check_catalog_version` + sorted id | §5.1 | *optional* — `checks[].catalog_index` would make position CLI-owned rather than QML-inferred. QML fallback ships either way |
| **C4** | N previous reports | not retained | a real state timeline (§3.5) | **out of scope for 0.3.1.** Requires a retention policy, a size bound, and a privacy review of what a posture history contains |
| **C5** | complete per-class capability counts | **not available.** `analysis.capabilities[]` is a scanner-*selected* list (`presentation_collections.capabilities.omitted`) and is capped again at `MAX_ITEMS` in `model/Candidate.js`. `review_summary.capabilities` carries only `{total, emitted, omitted}` | §5.4 candidate capability strip | add `review_summary.capabilities.by_class: { <class>: {total, emitted, omitted} }`, mirroring the `findings.by_rule` block that already exists. Until then the strip must mark absent classes `–`, never `·` — see §5.4 and D7 |

The plugin must not read `~/.local/state/omasafe/` directly — the README boundary ("QML never walks or writes
the cache directory") applies to the state directory for the same reasons. C1 and C2 are CLI asks, not
shortcuts.

---

## 9 Open decisions

| # | Decision | Recommendation |
|---|---|---|
| **D1** | `02 §2.3` names `SemanticMark.qml` the sole owner of semantic tier colours. Charts need the same ladder. | Move the ladder to `model/Tiers.js`; `SemanticMark` becomes the sole *row* renderer and the first consumer. Amend `02 §2.3` in the same commit. The alternative — passing colours in as properties from every call site — reintroduces the per-call-site colour sprawl Phase 1 removed. |
| **D2** | Block-element cells (U+2581–U+2588) are available and are what btop uses. Adopt for bars? | **No.** `Rectangle` segments scale with `Style.space()`, honour `Style.cornerRadius`, and survive a non-Nerd fallback family; block cells quantise to the character advance and would need a third ASCII column. Keep glyphs for identity, geometry for magnitude. |
| **D3** | Does host posture enter `BarWidget.alertCount`? | **Not in 0.3.1.** Tooltip line only (§5.8). A combined count changes a published contract and a two-number bar slot is a bar-design decision, not a panel one. Revisit with M7. |
| **D4** | `UnitStrip` vs the existing `CapabilityStrip`. | Ship `UnitStrip` new and defer the **structural merge** to 0.3.2, once `UnitStrip` has live miles — the capability strip is on every Overview row and regressing it to save one file is a bad trade. **One change to `CapabilityStrip` is in scope and required**: E1 needs a `complete` property (default `false`) that switches unobserved positions from `·` to `–`. That is a correctness property on the existing component, not the merge, and refusing it would leave the installed strip drawing omission as absence while the candidate strip refuses to — the asymmetry D7 exists to prevent. |
| **D5** | Release numbering. Manifest is `0.4.0` (Phase 5); the CHANGELOG's `[Unreleased] — v0.2.x` headings track the *CLI* line; the CLI is `0.3.0`. "0.3.1" is ambiguous. | Read "0.3.1" as **the v0.3.1 release line**: plugin work paired with `omasafe-cli 0.3.1`. Bump `manifest.json` to **`0.5.0`** (new user-visible surfaces, no breaking change) and title the CHANGELOG section `[Unreleased] — v0.3.1 glanceability`. Confirm before the release commit. |
| **D8** | E1/E2 are latent, not live: `plugins analyze` cannot truncate today (`serialized_byte_limit: null`). Fix now, or record and wait? | **Fix now, in `ViewModel.js`.** The guard is a single derived flag consumed by counts that already exist, it is the same guard D7 adds on the candidate side, and the failure mode is a silent green mark. Recording it as a known gap means shipping a release whose two halves disagree about whether missing data may be drawn as `·`. The cost is a day; the cost of discovering it later is a false clean. |
| **D9** | Should the alignment work land inside 0.3.1, or as a 0.3.2 follow-up? | **E1–E3 in 0.3.1** — they are correctness, and E1/E2 share their fix with D7. **E4–E6 in 0.3.1 if the schedule holds, otherwise 0.3.2** — they are consistency, they add no new data, and each is a component swap that can be cut without leaving a half-built surface. |
| **D7** | The candidate capability strip has no complete per-class aggregate (C5). Show it anyway, or withhold it? | **Show it, marked.** Absent cells become `–` and the header reads `PARTIAL` whenever anything was omitted or capped (§5.4). Withholding the strip loses the candidate↔installed comparison that motivates B5, and `–` is already the panel's word for "no data". This also settles D4 for this surface: the candidate strip is `UnitStrip`, and `CapabilityStrip` keeps its exact-data contract untouched. |
| **D6** | Domain grouping key. | Derive from the check id prefix before the first `.` in QML (`firewall.effective → FIREWALL`). It is stable, CLI-owned data and needs no new field. If the CLI later adds an explicit `domain`, prefer it. |

---

## 10 Sources

Read or run for this note, 2026-09-08.

**Measured locally** — `omasafe-cli 0.3.0` (`posture export`, `posture digest`, `scan-plugin --path`
with `--report-profile review` — see the caveat in §1 — `provenance`, `paths`),
`~/.local/state/omasafe/posture-state.json`, `omasafe-posture::update_state()` at
`crates/omasafe-posture/src/lib.rs:575–619`, and a fontTools pass over
`/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf`.

**Scores and why not**
- [Lynis hardening index — Linux Audit](https://linux-audit.com/lynis/lynis-hardening-index/)
- [Watchtower Score not increased by MFA, passkeys or better passwords — 1Password Community](https://www.1password.community/discussions/1password/watchtower-score-not-increased-by-mfa-passkeys-or-better-passwords/18185)
- [Cybersecurity UI/UX design portfolio — The Skins Factory](https://www.theskinsfactory.com/ux-design-portfolio-for-cybersecurity)

**Result states and compliance reporting**
- [CIS compliance in RHEL using OpenSCAP — Red Hat](https://www.redhat.com/en/blog/center-internet-security-cis-compliance-red-hat-enterprise-linux-using-openscap)
- [How to Scan RHEL Systems Against the CIS Benchmark with OpenSCAP — OneUptime](https://oneuptime.com/blog/post/2026-03-04-scan-rhel-9-cis-benchmark-openscap/view)

**Encoding and chart choice**
- [Graphical perception — learn the fundamentals first (Cleveland & McGill ranking) — FlowingData](https://flowingdata.com/2010/03/20/graphical-perception-learn-the-fundamentals-first/)
- [Cleveland & McGill, *An experiment in graphical perception* (PDF)](http://snoid.sv.vt.edu/~npolys/projects/safas/science.pdf)
- [Waffle charts are an underused alternative to pie charts — Better Posters](http://betterposters.blogspot.com/2024/12/waffle-charts-are-underused-alternative.html)
- [Waffle chart vs dot plot vs pie chart — nandeshwar.info](https://nandeshwar.info/data-visualization/waffle-chart-vs-dot-plot-vs-pie-charts/)
- [Alternatives to pie charts — data.europa.eu visualisation guide](https://data.europa.eu/apps/data-visualisation-guide/alternatives-to-pie-charts)

**Discrete state over time**
- [State timeline — Grafana docs](https://grafana.com/docs/grafana/latest/visualizations/panels-visualizations/visualizations/state-timeline/)
- [Status history — Grafana docs](https://grafana.com/docs/grafana/latest/visualizations/panels-visualizations/visualizations/status-history/)

**Summary arithmetic and triage surfaces**
- [The summary by severity is confusing — anchore/grype issue #1312](https://github.com/anchore/grype/issues/1312)
- [About code scanning alerts — GitHub Docs](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/about-code-scanning-alerts)
- [Rule insights dashboard and unified filter bar — GitHub Changelog](https://github.blog/changelog/2026-04-16-rule-insights-dashboard-and-unified-filter-bar/)

**Density, glanceability, disclosure**
- [Monospace Design TUI — design standard](https://github.com/coreyt/monospace-design-tui)
- [Shneiderman, *The Eyes Have It: A Task by Data Type Taxonomy for Information Visualizations* (PDF)](https://www.mat.ucsb.edu/~g.legrady/academic/courses/11w259/schneiderman.pdf)
- [From Good to Great in Dashboard Design — Smashing Magazine](https://www.smashingmagazine.com/2021/11/dashboard-design-research-decluttering-data-viz/)
- [Cybersecurity Dashboard UI/UX Design: A Practical Guide — Aufait UX](https://www.aufaitux.com/blog/cybersecurity-dashboard-ui-ux-design/)
