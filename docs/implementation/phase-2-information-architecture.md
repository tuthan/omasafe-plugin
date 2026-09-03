# Phase 2 — information architecture

Four tabs become two views plus a plugin detail sheet, every fact is placed by authority, and every kit row is written
once. The four tab components (2584–3790) are deleted and their content is rebuilt on `CursorSurface` rows in
`views/*` and `components/*`; the cursor model gains its per-view sections; the finder and the depth stacks arrive.

Two milestones, each shippable: **2a** plugin list and detail, **2b** rules, coverage, finder and breadcrumb. The
Flow chip stays hidden until Phase 3 — the `ButtonGroup` options are `[Overview] [Rules]` bound to keys `1` and `3`,
and `2` is inert so no digit ever changes meaning. **No placeholder body ships.**

Effort M · 5–6 days. Risk: behavioural parity. Spec: [`03 §4`](../design/03-ui-overhaul-proposal.md) (Overview),
`03 §5` (detail sheet), `03 §7` (Rules), `03 §8` (finder, breadcrumb), `03 §11` (states matrix), `03 §13` (sections),
[`02 §3`](../design/02-design-principles.md) (every string), [`05 §5`](../design/05-implementation-roadmap.md).

## Contents

1. [Entry criteria](#1-entry-criteria)
2. [Task list](#2-task-list)
3. [Milestone 2a — plugins and detail](#3-milestone-2a--plugins-and-detail)
4. [Milestone 2b — rules, finder, depth](#4-milestone-2b--rules-finder-depth)
5. [Commit plan](#5-commit-plan)
6. [Acceptance](#6-acceptance)
7. [Risks](#7-risks)
8. [Sources](#8-sources)

## 1 Entry criteria

- Phase 1 merged: tokens, `Labels.js`, the three structural components, the shell, the cursor scaffold and
  `ConfirmSheet` all exist and pass their invariants.
- **Open decision 8 answered** (folder [README](README.md) §8): whether the 15 `Process` blocks stay in `Panel.qml`.
  The answer sets this phase's file layout, so it cannot be deferred past T2.1.
- **Open decision 4 answered**: whether a 16th bounded `Process` (`rulesListProcess`) is acceptable. Without it 39 of
  the 45 rules have no title, and the Rules view and the finder index both degrade.
- A parity list captured from the running Phase 1 build: every action reachable today, with the clicks it takes. This
  is the checklist T2.8 and T2.14 are measured against.

## 2 Task list

| Order | Task | Creates / modifies | Blocked by | Effort |
|---|---|---|---|---|
| 1 | [T2.1](#t21-modelviewmodeljs-and-the-vm-rebuild) `model/ViewModel.js` + `vm` | 1 file; `Panel.qml` `apply*` | decision 8 | 1 d |
| 2 | [T2.2](#t22-the-row-components) row components (7) | `components/*.qml` | T2.1 | 1 d |
| 3 | [T2.3](#t23-viewsoverviewviewqml) `views/OverviewView.qml` | 1 file; delete 2584–2770 | T2.2 | 4 h |
| 4 | [T2.4](#t24-viewsplugindetailviewqml) `views/PluginDetailView.qml` | 1 file; delete 2772–3590 | T2.2 | 1 d |
| 5 | [T2.5](#t25-sources-and-the-schedule-confirmation) SOURCES rows | `OverviewView.qml`; delete 3592–3790 | T2.3 | 4 h |
| 6 | [T2.6](#t26-the-authority-sections) three authority sections | `PluginDetailView.qml` | T2.4 | 4 h |
| 7 | [T2.7](#t27-per-view-cursor-sections-and-depth-stacks) cursor sections + depth | `Panel.qml` | T2.3, T2.4 | 4 h |
| 8 | [T2.8](#t28-2a-parity-gate) 2a parity gate | — | T2.1–T2.7 | 2 h |
| 9 | [T2.9](#t29-ruleslistprocess) `rulesListProcess` | `Panel.qml` | decision 4 | 2 h |
| 10 | [T2.10](#t210-viewsrulesviewqml-and-the-rule-sheet) `views/RulesView.qml` + rule sheet | 1 file; `components/RuleRow.qml` | T2.9 | 1 d |
| 11 | [T2.11](#t211-baseline-v3-coverage-table) Baseline V3 coverage table | `RulesView.qml`; `RelationRow.qml` | T2.10 | 4 h |
| 12 | [T2.12](#t212-finder) finder | `FinderField.qml`, `FinderResultsView.qml` | T2.10 | 1 d |
| 13 | [T2.13](#t213-breadcrumb-and-the-cross-view-return-frame) breadcrumb + return frame | `Breadcrumb.qml`; `Panel.qml` | T2.7 | 4 h |
| 14 | [T2.14](#t214-2b-parity-and-audit-script-gate) 2b parity + audit scripts | — | all | 3 h |

## 3 Milestone 2a — plugins and detail

### T2.1 `model/ViewModel.js` and the `vm` rebuild

**Goal.** Views bind to one normalised object, never to functions that walk raw reports.

**Change.** `ViewModel.build()` is called from every `apply*` and assigned to one root `vm`. It normalises inventory,
status, analysis, marketplace, enforcement, schedule, override and rules reports into the indexes the views need,
builds the finder index (T2.12), and **strips `file_digests`** from inventory and status reports before storing them.
Pure functions only; no QML access.

**Verify.** `grep -rn 'visiblePlugins()\|selectedPlugin()' views/ components/` is empty — bindings read `vm.*`. No
delegate contains a function-call binding and no `Repeater { model: someFunction() }` survives (`01` counted 12 + 18
of these; Phase 4 audits again).

### T2.2 The row components

**Goal.** One row grammar for every list in the panel.

**Files.** `components/ActionRow.qml`, `AlertRow.qml`, `PluginRow.qml`, `ClassRow.qml`, `EvidenceRow.qml`,
`EdgeRow.qml`, `SourceRow.qml`, plus `CapabilityStrip.qml` and `FactPill.qml`.

**Change.** Each is a `CursorSurface` with a `Style.space(22)` glyph column, two `Text` lines, and at most two
`PanelActionButton`s; expanding rows open a `Column` beneath. Insets and rhythm from `03 §3` and `02 §2.2`.
`CapabilityStrip` is one `Text` + `PanelToolTip` over the 17-glyph **fixed catalog order**. `FactPill` is a
`BorderSurface` + `bodySmall` `Text` + tooltip for severity and confidence words on an expanded review item — never
a disabled `Button`. `ActionRow` keeps ineligible verbs **visible**, dim, and naming the unmet condition
(`02 §3.5`); `updateEligible()` / `enableEligible()` (1183–1199) gain a return of that condition string.

The backups row is a `CursorSurface` holding a label `Text` and `ToggleSwitch { interactive: false; checked;
hasCursor }` (`Ui/ToggleSwitch.qml:34`; precedent `network/Panel.qml:1143`) — **not** the kit `Toggle` row, whose
54 px floor, `space(240)` width, `activeFocusOnTab` and 100 ms animation `03 §4.1` rejects.

**Verify.** No row reads `containsMouse`; no row contains a colour expression; a plugin row never wraps to a third
line at base 9 (the trust word abbreviates per `02 §density`).

### T2.3 `views/OverviewView.qml`

**Goal.** `ALERTS · PLUGINS · SOURCES`, one non-destructive next step per row, and the product disclaimer at the foot.

**Change.** Build the `03 §4.1` frame from `SectionHeaderRow` + the T2.2 rows; delete `overviewTabComponent`
(2584–2770). The quiet state is the same frame (`03 §4.2`); the unavailable, loading and error states are `03 §4.3`.
Plugin rows print ` · <n> limits` after the item count whenever `coverage_limitations.length > 0` and ` · text match
only` when `parser == null`. The footer carries the one product sentence verbatim: `OmaSafe reports changes and
coverage limits. It does not declare plugins safe.`

**Verify.** No count and no occurrence of the word "untrusted" appears on Overview; the PLUGINS footer definition
sentence is present; opening with 3 alerts shows `ALERTS | 3` as the first section with no evidence text visible
before an Enter.

### T2.4 `views/PluginDetailView.qml`

**Goal.** Seven visible sections plus one collapsed, disclosed one level at a time.

**Change.** Per `03 §5`: `TRUST BASELINE`, `WHAT CHANGED`, `REVIEW ITEMS`, `CAPABILITIES OBSERVED`, `COVERAGE` (with
the file references folded in under a collapsed `<n> file references` sub-row of `EdgeRow`s), `MARKETPLACE CLAIM`,
`ENFORCEMENT`, and `PROVENANCE` collapsed. Delete `findingsTabComponent` (2772–3184) and `pluginsTabComponent`
(3186–3590), re-homing their content here and in `RulesView` (Baseline V3).

Fields rendered for the first time in this phase, all present in the samples: `result.marketplace_source`,
`marketplace[].registry_claim.upstream_moved`, `analysis.invocation_edges[]` with the target file's coverage state
from `payload_inventory.coverage_states`, `findings[].confidence` as a word, `analysis.equivalence.*` in
`PROVENANCE`, and `rules explain`'s `result.external_equivalences[]` (rule sheet, 2b). Provenance is rendered
verbatim, never as `JSON.stringify` (`01` A13).

**Verify.** `COVERAGE | 13 LIMITS` for `lgse.sandman`, `COVERAGE | 2 LIMITS` for `io.github.tuthan.omasafe`, both
grouped by file then kind without expansion; `io.github.tuthan.dropdown-terminal` reads `COVERAGE | NO LIMITS
REPORTED`. Every review item carries its `confidence` as a word (`parser-backed` / `text match only`).

### T2.5 SOURCES and the schedule confirmation

**Change.** Rebuild the Catalog tab (3592–3790) as SOURCES rows on Overview: the marketplace snapshot row with its
commit and age, the CLI row (the only place the CLI version is printed), the schedule row, and Update catalog with
inline progress `Updating catalog… <n> s` and no confirmation (`02 P5`, `R20`). The schedule row's install action
opens the `schedule` `ConfirmSheet`, which shows both unit names and the exact effective `ExecStart` argv for the
chosen policy — both policies neutral chrome, because both are report-only.

**Verify.** A `marketplace_stale: true` fixture suppresses the word "verified" in the whole section. `conflict` with
`repository: null` renders `Catalog entry not matched: …` plus `Installed repository: unavailable (no git remote)`.

### T2.6 The authority sections

**Goal.** GR2 made structural: three sections, three authorities, never mixed in one row.

**Change.** `TRUST BASELINE` (no right-hand value), `MARKETPLACE CLAIM | CATALOG <commit7> · <age>`, and
`ENFORCEMENT | EVALUATED / NOT EVALUATED / NO DECISION`. A recorded decision carries no advisory/hardened mode
(`03 §5.4`); `decision: null` renders `No decision has been recorded`, never "allowed". Every
`registry_claim.verification_status` value starts with `Catalog says:`; the correlation `status` renders as its
`02 §3.4` sentence, never a bare enum word and never prefixed.

**Verify.** No row shows a catalog claim and a trust word together. `plugins enable` with `enabled: false` and a
block decision renders `Enable refused (<policy>): <reason codes>` and never `<id> enabled.`; the success line
requires `result.enabled === true`.

### T2.7 Per-view cursor sections and depth stacks

**Change.** Extend Phase 1's cursor model with the `03 §13` `visibleSections` lists for Overview and the plugin
detail sheet, per-view depth stacks, and `clampCursor` after every model change. Data arrival never changes view,
depth or cursor. `onAlertsChanged` (3808) stops reading `activeTabKey`.

**Verify.** Every row, action `Button` and `PanelActionButton` in Overview and the detail sheet is reachable with
`j`/`k`/`h`/`l` and activates with Enter; hover row A then press `j` — one highlight, on row B. Sections with zero
rows are skipped.

### T2.8 2a parity gate

**Change.** Nothing. Walk the parity list from the entry criteria: trust (record/replace), untrust (remove), enable,
review update, schedule install, update catalog, scan, explain rule, provenance, coverage relations, override
records and decision details are each reachable within two activations from Overview, and every ineligible verb is
visible, dim and names its unmet condition.

## 4 Milestone 2b — rules, finder, depth

### T2.9 `rulesListProcess`

**Change.** Clone `coverageProcess` (4511–4588 pre-Phase-2 numbering) verbatim for `rules list --format json`: 15 s
timeout, 3 s kill, 2 MiB cap, `SplitParser` per stream, cached per CLI version exactly like `coverageReport`.
Measured cost on this machine: 4 ms, 25 KB. It is the only new collector in the whole plan.

**Verify.** The bounded-process pattern is identical to its source, including the first-terminal latch and the
generation guard. Fetch policy: once per CLI version, never on view open.

### T2.10 `views/RulesView.qml` and the rule sheet

**Change.** `RULE CATALOG` over a `ListView` (45 rows) with `positionViewAtIndex(i, ListView.Contain)` for
`ensureCursorVisible`; `RuleRow` expands into the rule sheet inline (`03 §7.1`), which renders `rules explain`'s
named fields — including `result.external_equivalences[]` — through the Phase 0 JSON path (T0.12).

**Verify.** `LOCAL HITS` and rule-row counts show `–`, never `0`, until at least one plugin is analyzed; unanalyzed
plugins read `not analyzed` and never disappear.

### T2.11 Baseline V3 coverage table

**Change.** Per `03 §7.2`: header `automated-security-baseline v3 · map 2 · checked against marketplace commit
964dc08`; footer lists the three not-covered ids; the two rows with neither `omaRuleId` nor `omaCapability` read
`Inventory behaviour only (see note)` and the map `note` is rendered verbatim **only here**. No Baseline row carries
a plugin count — expanded covering rules print `observed in <k> analyzed plugins` / `not observed in <n> analyzed
plugins`.

**Verify.** The header string matches exactly; `verified_at_commit` is attributed to the map, not to OmaSafe.

### T2.12 Finder

**Change.** Per `03 §8`: `/` shows and focuses `FinderField` (kit `TextField`, `placeholderText: "plugin, capability,
rule or baseline id"`, `bodySmall`); `keyCatcher.blocked` follows `finder.activeFocus`. Matching is case-insensitive
substring over one prebuilt lowercase index of ≈ 85 strings — 8 plugin ids, 17 class names, 45 rule **ids + titles**
(not `capability`, which a class result already covers), 12 Baseline ids + 3 not-covered. Groups with no match are
not drawn. `FinderField.Keys.onPressed` accepts Tab/Backtab as a **no-op**, because an unaccepted Tab would bubble to
the blocked catcher and let Qt's focus chain move `activeFocus` to any `activeFocusOnTab` item, dropping
`finder.activeFocus` and un-blocking the catcher. Empty result: `No plugin, class, rule or baseline id matches
"<text>".`

**Verify.** `/` then `proc` against `rules-list.json` and `rules-coverage.json` yields exactly 2 classes
(`process-execution`, `detached-process-execution`), 3 rules (`oma.qml.process-execution`,
`oma.qml.detached-execution` by id and `oma.python.reverse-shell` by title), 1 Baseline id
(`privileged-process-control-from-shared-temp`) and **no** PLUGINS group. `Esc` in the finder clears it and does not
close the panel. `grep -rn activeFocusOnTab --include='*.qml' .` is empty.

### T2.13 Breadcrumb and the cross-view return frame

**Change.** `Breadcrumb` (`bodySmall`, `ElideMiddle` segments, `›` separators, leading back `PanelActionButton 󰅁`)
appears at depth ≥ 1 and reflects that view's stack. At depth 1 it renders the way back only (`󰅁 All plugins`) —
the hero already names the plugin two lines above. The full `›` path renders at depth ≥ 2.

The cross-view return rule of `03 §13`: `[Open rule]` in a review item, and a finder result opened from another
view, push one `returnFrame = { view, depth, cursor }` before calling `setView()`. While a frame exists in the
current view, `h` in a vertical section at depth 0, `-`, and the breadcrumb's back button pop **it** first, restoring
the recorded view, depth and cursor. Only one frame is held; `1 2 3` and `close()` clear it; Esc never pops a frame.

Test open decision 1 here: whether `Backspace` reaches `textKey` as `event.text === "\b"`. If it does not, bind only
`h`, `-` and the back button, and strike Backspace from the key map.

**Verify.** `1` while at depth 1 pops to depth 0. Opening a rule sheet from `lgse.sandman`'s detail sheet renders
`󰅁 lgse.sandman` as the way back, and `-` returns to that plugin's sheet with the cursor where it was.

### T2.14 2b parity and audit-script gate

**Change.** Nothing. Re-run the `01 §6` walkthrough scripts and record the results: (6.1) open with 3 alerts → the
hero reads `3 alerts to review`, the first section is `ALERTS | 3`, no evidence text is visible without an Enter;
(6.2) no count and no "untrusted" on Overview, PLUGINS footer definition present; (6.3) confirm Replace baseline →
success line in place, no view change, no analysis cache clear, no automatic scan.

## 5 Commit plan

One commit per task, in order, with two exceptions: T2.3 + T2.5 land together (deleting the Catalog tab without its
SOURCES replacement leaves Overview incomplete), and T2.10 + T2.11 land together (the Rules view has two sections and
one of them alone is not the view). Each commit keeps `qmllint` and `omarchy plugin validate .` at exit 0, and the
build stays usable: after T2.4 the panel has two views and no dead chip.

`manifest.json` `version` → `0.3.0` in the last commit of this phase: the four-tab IA is gone.

## 6 Acceptance

The full list is `05 §5`. The items most easily missed:

- [ ] Parity (T2.8) and the three audit scripts (T2.14) pass.
- [ ] `grep -rn 'visiblePlugins()\|selectedPlugin()' views/ components/` and
      `grep -rn activeFocusOnTab --include='*.qml' .` are both empty.
- [ ] Finder result for `proc` is exactly 2 / 3 / 1 with no PLUGINS group.
- [ ] `LOCAL HITS` and rule counts read `–`, never `0`, before any analysis.
- [ ] Baseline V3 header string exact; no Baseline row carries a plugin count.
- [ ] Plugin rows print ` · <n> limits` (sandman 13, btop 3, omasafe 2) and ` · text match only` when
      `parser == null`.
- [ ] RSS of `quickshell -n -p /usr/share/omarchy/shell` after opening both views and one detail sheet is under 2×
      the Phase 1 measurement taken the same way.
- [ ] Every row and action is keyboard-reachable with exactly one highlight on screen.

## 7 Risks

| Risk | Mitigation |
|---|---|
| Behavioural parity (medium) | the parity list is captured **before** the tabs are deleted, and T2.8 / T2.14 are gates, not reviews |
| A plugin row's second line overflows at base 9 | the trust word abbreviates (`02 §density`) and the capability strip stays |
| `Backspace` never reaches `textKey` | pre-decided fallback: `h` / `-` / back button only (open decision 1) |
| Deleting 1200 lines of tab bodies loses an undocumented behaviour | the parity list plus `03 §5.5`'s action table, which enumerates every action, its gate and its argv |
| Decision 4 refused, leaving 39 rules unnamed | the Rules view and finder index degrade to ids only; raise it before T2.9, not during |

## 8 Sources

- [`03 §4`](../design/03-ui-overhaul-proposal.md) Overview states, `03 §5` detail sheet and `03 §5.5` action table,
  `03 §7` Rules and Baseline V3, `03 §8` finder and breadcrumb, `03 §11` states matrix, `03 §12` task flows,
  `03 §13` sections and the return frame.
- [`02 §3.3`](../design/02-design-principles.md) status strings, `02 §3.4` enum labels, `02 §3.5` coverage and
  ineligible verbs, `02 §2.8` density.
- [`05 §5`](../design/05-implementation-roadmap.md) file lists, data dependencies, first-rendered fields and the
  phase acceptance list; `05 §9` component inventory; `05 §10` CLI matrix.
- [`01 §6`](../design/01-research-and-audit.md) walkthrough scripts; `01 §2.5` current actions and gates.
- Installed kit: `Ui/TextField.qml`, `Ui/ToggleSwitch.qml:34`, `Ui/PanelActionButton.qml`,
  `plugins/panels/network/Panel.qml:1143`.
