# Verification findings

Adversarial review record for the OmaSafe UI/UX overhaul documents (`README.md`, `01`–`05`). It lists every issue the review lenses raised in both rounds, the notes the per-file fixers and the round-1 consistency pass returned, and what remained open when the run stopped during the round-2 consistency pass. Section 8 is the post-finalization architecture/UX closure pass. This is a record, not a design document: binding decisions stay in [06-decision-record.md](06-decision-record.md) and the current deliverables it names.

Date 2026-09-02 · omasafe-cli 0.2.1 · plugin 0.2.1 · Omarchy 4.0.2 Quattro · Quickshell 0.3.1

## Contents

1. [Method](#1-method)
2. [Run status](#2-run-status)
3. [Summary](#3-summary)
4. [Findings by document](#4-findings-by-document)
5. [Reviewer notes](#5-reviewer-notes)
6. [Open items](#6-open-items)
7. [Sources and references](#7-sources-and-references)
8. [Post-finalization architecture review and closure](#8-post-finalization-architecture-review-and-closure)

## 1 Method

- Three independent design directions (A evidence-first, B graph-first, C keyboard-dense) were scored by three judges (end user, security-UX designer, QML engineer). All three ranked A > B > C; the decision record grafts B and C ideas into A.
- After the six documents were written, **round 1** ran six review lenses in parallel over all documents: `api-truth` (every QML/kit/token name exists in `/usr/share/omarchy/shell` and Qt 6), `data-truth` (every CLI command, field, enum and worked number matches `omasafe-cli` 0.2.1 output and `omasafe-report`), `ground-rules` (no verdicts or scores, catalog claims never conflated with trust, unavailable never clean, confirmations intact), `completeness` (the ask and cross-document consistency), `feasibility` (geometry at 420 units, rendering cost, `PanelKeyCatcher` integration, `Panel.qml` state model), `design-quality` (hierarchy, type, colour, copy, wireframe quality).
- One fixer per document applied the round-1 issues with surgical edits and reported declined or cross-file items; a cross-file consistency pass then reconciled names, links, states, keys and phase numbers across documents.
- **Round 2** re-ran `api-truth`, `data-truth`, `ground-rules` and `completeness`, followed by one fixer per document.
- Issues were de-duplicated on (file, location, issue) before fixing. Lens attribution below follows the launch order recorded in the run journal.

## 2 Run status

- Round 1: 6 lenses, 6 fixers and the consistency pass completed.
- Round 2: 4 lenses and 6 fixers completed (last fixer finished 19:59).
- Round-2 consistency pass: started 19:59, **interrupted at 20:05** on the maintainer's instruction after 14 edits (see [Open items](#6-open-items)). A second launch of the same pass (20:05–20:10) read files only and made no edits before it was stopped.
- The planned final polish pass (README index accuracy, TOC vs headings, link resolution, Mermaid validity, wireframe widths, version/date consistency) did **not** run. A mechanical subset of those checks was run by script instead; results are in [Open items](#6-open-items).

## 3 Summary

### 3.1 Issues by round and severity

| Round | Total | High | Medium | Low |
|---|---|---|---|---|
| Round 1 | 111 | 12 | 39 | 60 |
| Round 2 | 54 | 3 | 19 | 32 |
| **Both** | **165** | **15** | **58** | **92** |

### 3.2 Issues by lens

| Lens | Round 1 | Round 2 |
|---|---|---|
| api-truth | 18 | 11 |
| data-truth | 22 | 14 |
| ground-rules | 20 | 20 |
| completeness | 16 | 9 |
| feasibility | 19 | not run |
| design-quality | 16 | not run |

### 3.3 Issues by document

| Document | Round 1 | Round 2 | High (both) |
|---|---|---|---|
| [README.md](README.md) | 3 | 3 | 0 |
| [01-research-and-audit.md](01-research-and-audit.md) | 12 | 5 | 1 |
| [02-design-principles.md](02-design-principles.md) | 21 | 12 | 2 |
| [03-ui-overhaul-proposal.md](03-ui-overhaul-proposal.md) | 38 | 26 | 6 |
| [04-trust-graph-spec.md](04-trust-graph-spec.md) | 23 | 5 | 6 |
| [05-implementation-roadmap.md](05-implementation-roadmap.md) | 14 | 3 | 0 |

Round-2 counts are lower in every document except `03-ui-overhaul-proposal.md` and `02-design-principles.md`, where `ground-rules` raised most of the round-2 items after round-1 edits had introduced new wording.

## 4 Findings by document

Each entry: **severity** · round · lens · location. `Disposition` is not recorded per issue by the run; the per-file fixer notes in [Reviewer notes](#5-reviewer-notes) state what each fixer applied, declined, or deferred cross-file, so read the matching document and round there.

### 4.1 README.md

6 issues (round 1: 3, round 2: 3).

#### Medium (2)

**F001** · **medium** · round 1 · `data-truth` · at: GR2 "Every catalog string is prefixed 'Catalog says:'"; 02 P2 "Every catalog-derived value is prefixed `Catalog says:`" vs 02 §3.4 status labels (`Listed in catalog snapshot`…) and 03 §5.4; 04 §3.3 `Catalog says: listed, verified · snapshot …` and 04 §9.1 inspector `Catalog says: conflict`

- Issue: Three inconsistent rules for the one phrase that carries GR2. README/P2 say every catalog value is prefixed; Labels.js (02 §3.4) prefixes only `verification_status` and gives `status` full sentences without the prefix; 04 prefixes the raw `status` enum (`conflict`, `listed`) which Labels.js never emits as a bare word. An implementer following 04 ships `Catalog says: conflict`, which is not a label in the closed map.
- Proposed fix: One rule, written once in 02 §3.4 and referenced elsewhere: `Catalog says:` prefixes `verification_status` values only; `status` renders as its Labels.js sentence (short form for one-line contexts: `listed` → `Listed in snapshot`, `conflict` → `Conflicts with installed repo`, `installed-differs` → `Listed; commit differs`, `unlisted` → `Not in snapshot`). Inspector/Trace line = `<status short> · Catalog says: <verification> · snapshot <commit7>, <age>`. Amend README GR2 to 'every verification claim is prefixed', fix 04 §3.3 and §9.1.

**F002** · **medium** · round 2 · `ground-rules` · at: §Sources and references — "Decision record (binding names, grafts G1–G27, conflict resolutions R1–R24, consistency contract): .../scratchpad/decision-record.md"

- Issue: 01, 02 and 04 cite graft ids (G5, G6, G7, G8, G9, G10, G14, G18, G19, G21, G26, G27) and resolution ids (R12, R13, R20) as normative anchors (e.g. 04 §3.3 "grouped per G26", 01 A2 "(G7)", 01 A15 "(R12)"), but the decision record lives only in the session scratchpad and is not committed. The ask was "document it in files in the project"; a reader of docs/design/ cannot resolve any G/R reference.
- Proposed fix: Either commit the decision record as docs/design/06-decision-record.md and index it in README §Documents, or replace every G/R citation in 01–04 with the in-repo section that now carries the decision (e.g. G26 → 02 §3.4 limitation-code grammar, G7 → 03 §10 invariants 2 and 5, R13 → 03 §7.2 attribution rule).

#### Low (4)

**F003** · **low** · round 1 · `api-truth` · at: §Status and versions row 'Real data used in every example' and §Sources 'omasafe-cli usage line (subcommands plugins inventory|status|diff|analyze|enable|review-update|enforcement-status|override list …)'

- Issue: (a) Several worked examples do not match the samples (02 §2.8 omasafe drawn as Git checkout with a baseline; 02 §3.7 placeholder hashes; 03 §5.2 / 04 §9.4 evidence line numbers; 03 §8 invented rule titles; 04 limitation counts swapped), so the blanket claim is false until those are fixed. (b) The subcommand list omits `plugins trust` and `plugins review --action untrust`, the two mutating commands the panel actually invokes (Panel.qml:571, 594; docs/cli-surface.txt lines 7 and 10), while listing only read-side commands.
- Proposed fix: Soften to 'Real data used in the worked examples; verified against cli-samples/' after fixing the listed items, and add `plugins trust`, `plugins review` to the subcommand list.

**F004** · **low** · round 1 · `ground-rules` · at: Documents table: 03 row 'wireframes for Overview (attention / quiet / unavailable / loading / error) … and the ConfirmSheet variants'; 04 row 'five wireframes' and 'Size 600–1000 lines'

- Issue: 03 §4.2 (quiet) is prose only ('Same frame with hero…'), and only 2 of the 6 ConfirmSheet variants are drawn (record, review-update; remove/enable/schedule exist only as a table). 04 §9 has six wireframes (9.1–9.6), not five, and is 1006 lines.
- Proposed fix: Either add a quiet-state frame and at least the destructive 'remove' and the identity-less 'schedule' sheets to 03, or make the README describe what is drawn ('quiet described in prose; two ConfirmSheet variants drawn, four tabulated'); change 'five wireframes' to 'six' and the size to '600–1100'.

**F005** · **low** · round 2 · `api-truth` · at: §Design thesis (line 43: "one sentence in the CLI's own vocabulary that answers \"am I okay\"")

- Issue: The framing says the hero sentence answers a safety question ("am I okay"), while the ground rule is that the panel makes no safety judgment; the sentence `No outstanding alerts` answers only whether the last scan left anything outstanding. Reviewers and future copywriters reading the thesis may carry the framing into UI copy or tooltips.
- Proposed fix: Reword to: "one sentence in the CLI's own vocabulary that states what the last scan left outstanding (`No outstanding alerts`, `3 alerts to review`, `omasafe-cli not found`)", and, where the persona's question is quoted (01 §1, §3 A20), keep it explicitly as the user's question that the panel deliberately does not answer.

**F006** · **low** · round 2 · `completeness` · at: §Sources and references — "`plugins trust <id> --yes --expected-head/--expected-tree/--expected-digest` and `plugins review <id> --action untrust --yes` are the two mutating commands the current panel invokes (`Panel.qml:571`, `594`)"

- Issue: The current panel invokes six mutating commands, not two: `plugins enable` (Panel.qml:1261), `plugins review-update` (1292), `schedule install --policy` (910) and `marketplace refresh --latest` (3927) in addition to trust (571) and review untrust (593–597); 01 §2.4 and 05 §10 list all of them. Also the trust argv includes `--note "trusted from OmaSafe panel"` (571) and the untrust argv includes `--reason "untrusted from OmaSafe panel"` (596), omitted here.
- Proposed fix: Say "the six mutating commands the panel invokes" and cite 01 §2.4 / 05 §10, or list all six with their anchors.

### 4.2 01-research-and-audit.md

17 issues (round 1: 12, round 2: 5).

#### High (1)

**F007** · **high** · round 1 · `feasibility` · at: §2.7 item 5 ("cache … cleared on scan, inventory, trust and close" listed as preserved) vs §8.7 refresh table (invalidate only on key mismatch / analyzer-policy-update); 03 §4.1 `PLUGINS | 8 · 4 ANALYZED` on open; 04 §4.1 step 2 and §11 ("layout … stays at root", "reused on reopen"); 05 §1.1

- Issue: Panel.qml `close()` (947–949) calls `clearAnalysisCache()` first, and `onAlertsChanged` (3808) clears it after every scan whose alerts change — and the bar left-click runs a scan and opens (BW:530–535). As specified, every reopen starts with eight hollow Flow nodes, `– ` counts everywhere, and `A` must be pressed each open (8 bounded processes per open). The documents assume a warm cache across close ("4 ANALYZED" on open, "analyzed first" ordering, Rules LOCAL HITS) while also promising the current clearing policy is preserved.
- Proposed fix: Add a Phase 0 or 2 item that changes cache lifetime explicitly: keep `analysisCache` across `close()` (the key digest+tool_version+policy_identity already fails closed on staleness), clear on `onCliVersionChanged` only, and on `onAlertsChanged` drop only entries whose plugin carries an `analyzer-policy-update` / `source-drift` alert. Update 01 §2.7(5), 05 §1.1 and the 04 §11 idle-cost row; or, if the owner keeps clearing on close, state in 03/04 that Flow and LOCAL HITS start empty on every open.

#### Medium (5)

**F008** · **medium** · round 1 · `api-truth` · at: §8.3 Field dictionary, row `plugins analyze <id>` → Analysis, 'Limitation codes' list

- Issue: `staged-script-analysis-budget-exhausted` does not exist anywhere in the omasafe crates (grep over omasafe-analyzer/src and omasafe-cli/src returns nothing; only the `STAGED_CHAIN_TIME_BUDGET` constant exists). Codes the analyzer actually emits and the list omits: `analysis_time_budget_exhausted` (detect.rs:188,326), `sink-reference-rejections-truncated:<n>` (detect.rs:372, the MAX_SINK_REJECTIONS overflow disclosure the same doc cites in §8.6), `file_limit_exceeded`, `aggregate_byte_limit_reached`, `tree_depth_limit_exceeded`, `directory_entry_limit_exceeded`, `symlink_target_truncated` (ingest.rs). Note several are underscore-style with no file segment, so the `kind[:sub]:file[:line[:target]]` grammar in 02 §3.4 / 03 §5.3 will not parse them.
- Proposed fix: Replace the invented code with the real list above; state that underscore-style codes have no file segment and render verbatim as their own group (not 'unsupported limitation', since they are known codes).

**F009** · **medium** · round 1 · `api-truth` · at: §8.4 Real cardinalities, row 'Totals' ("only 4 of 17 classes and 6 of 45 rules fire locally")

- Issue: Five classes are observed across the four analyses: compositor-control, detached-process-execution (4 occurrences in ilyazar.btop, listed in the same table's btop row), filesystem-access, persistence-scheduling, process-execution. 04 §3.3 and §12 correctly say 5. The '6 of 45 rules' figure is correct (5 `source_rule_id` values + oma.qml.dynamic-reference).
- Proposed fix: "only 5 of 17 classes and 6 of 45 rules fire locally".

**F010** · **medium** · round 1 · `completeness` · at: §4 Visual kit gap table, row "Hover under reflow" ("`PointerMoveGate` ... `moved(item, mouse)` guard ... (`monitor/Panel.qml:55–62`)") and §9.4 ("`monitor/Panel.qml:55–62` shows why hover must pass through `PointerMoveGate.moved(item, mouse)`"), also A5 fix column

- Issue: Wrong precedent. `plugins/panels/monitor/Panel.qml` contains no `PointerMoveGate` and no `.moved(` call at all (grep is empty); lines 55–62 declare `cursorActive`, `textSizeStops` and `textSizePreviewIndex`. The only first-party users of `PointerMoveGate` are `plugins/clipboard/Clipboard.qml:192` and `plugins/menu/Menu.qml:876` (`pointerGate.moved(item, mouse)`). The component itself (`Ui/PointerMoveGate.qml:30 moved(item, mouse)`) and the `reset()`/`allowInitialSample()` API do exist.
- Proposed fix: Replace both citations with `plugins/clipboard/Clipboard.qml:192` / `plugins/menu/Menu.qml:876` as the first-party `pointerGate.moved(item, mouse)` idiom; keep `monitor/Panel.qml:55–59` only as the citation for `cursorActive` and `textSizeStops`.

**F011** · **medium** · round 2 · `completeness` · at: §8.3 Field dictionary, `plugins analyze` row — "`time_budget_exhausted` (no prefix) exists only in `omasafe-report/src/enforcement.rs` tests and is never emitted"; same omission in 02-design-principles.md §3.4 "limitation code" bare-code list and 03-ui-overhaul-proposal.md §5.3 bare-code list

- Issue: False. `omasafe-analyzer/src/ingest.rs:142, 294, 874` call `self.note("time_budget_exhausted")`; `note()` (ingest.rs:130–137) pushes into the walker's `limitations`, `finish()` (ingest.rs:148–156) writes them to `PayloadInventory.limitations`, and `plugins analyze` copies `inventory.limitations` into `analysis.coverage_limitations` (main.rs:5451). Because the three documents' bare-code lists omit `time_budget_exhausted`, the specified fallback ("anything else → verbatim + unsupported limitation") would label a real, known CLI code as unsupported.
- Proposed fix: Correct the sentence in 01 §8.3 (emitted by the ingest walker, lands in both `payload_inventory.limitations` and `coverage_limitations`) and add `time_budget_exhausted` to the known bare-code group in 02 §3.4, 03 §5.3 and the `Labels.js` limitation parser.

**F012** · **medium** · round 2 · `ground-rules` · at: §9.6 — "The held Enter that opened the sheet is swallowed by `swallowNextActivate` (G7)"; also 02 P5 Do: "`swallowNextActivate` on open" as the held-key protection

- Issue: 03 §10 invariant 2 and 05 §4 define `swallowNextActivate` narrowly as a same-event-loop-turn double-delivery guard and state it is "not the mechanism that stops a held key"; the held Enter is stopped inside `ConfirmSheet.Keys.onPressed` by dropping `isAutoRepeat` Return/Enter/Space plus a 300 ms non-repeat window. 01 §9.6 and 02 P5 attribute the GR6 no-bypass guarantee to the wrong mechanism, so an implementer following 01/02 alone would ship a bypassable sheet.
- Proposed fix: In 01 §9.6 and 02 P5 (Do and Review test) replace the swallowNextActivate sentence with a pointer to 03 §10 invariant 2: auto-repeat drop + 300 ms window in the sheet's Keys.onPressed; keep swallowNextActivate described as the double-delivery guard only.

#### Low (11)

**F013** · **low** · round 1 · `api-truth` · at: §8.4 Real cardinalities, row 'Coverage map (Baseline V3, map 2)' ("Rule-level rows 7 (`curl-pipe-shell` ×3, `sudoers-dangerous-passwordless-command` ×2, `sudoers-modification` ×1 …)")

- Issue: 3 + 2 + 1 = 6 rows carry `omaRuleId`, not 7. With the stated 4 class-level rows, 2 pointer-less partial-overlap rows and 3 not-covered rows the doc's split sums to 16, but rules-coverage.json has 15 rows.
- Proposed fix: "Rule-level rows 6 (…); class-level rows 4 …; 2 rows with no OmaSafe pointer; 3 not-covered" (6 + 4 + 2 + 3 = 15).

**F014** · **low** · round 1 · `completeness` · at: §2.4 table row "Review update" body column ("(2453)"); §3 A10 Where column ("2453; legacy 2042"); §2.6 range map verified anchors ("2453") — also 05 §2 ("'verified' copy 2453"), 05 §3 row 0.14 ("(2453)"), README

- Issue: Panel.qml:2453 is the schedule-install body text ("policy. The timer remains report-only; hardened policy adds analysis to the scan."). The review-update string "Update … at the verified commit below and trust the result" is at 2455.
- Proposed fix: Cite 2455 for the "verified commit" body across 01, 05 and README.

**F015** · **low** · round 1 · `completeness` · at: §4 Visual kit gap table row "Status icon `OmaSafeStatusIcon.qml`" ("`TailscaleIcon` pattern: glyph + `BorderSurface` badge"); also 03 §2 ("follows `TailscaleIcon.qml` (glyph plus an optional `BorderSurface` badge…)") and 05 §9 ("TailscaleIcon pattern")

- Issue: `plugins/panels/tailscale/TailscaleIcon.qml` draws no text glyph: it is a 3×3 grid of `Rectangle` dots via an inline `component Dot: Rectangle` (lines 26–34, 66–71) plus an optional crossed bar. Only the badge part is as described: `BorderSurface { radius: width / 2; color: badgeColor (Color.urgent); borderSpec: Border.flat(Color.popups.background, 1) }` with a "!" `Text` in `Color.background` (46–64). Note that badge `Text` uses a literal `font.pixelSize: Math.max(6, parent.height * 0.72)` (line 61), which the docs' own "no `font.pixelSize` literal" blocker forbids if copied verbatim. The shield-glyph precedent is `tailscale/Panel.qml:766–767` (`Text { text: "󰒃" }`), not TailscaleIcon.
- Proposed fix: Describe the reference as "`tailscale/Panel.qml:767` shield `Text` + the `TailscaleIcon.qml:46–64` badge `BorderSurface`" and state that the badge font size must be re-expressed as a `Style.font.*`/`Style.space()` token.

**F016** · **low** · round 1 · `completeness` · at: §4 Visual kit gap table row "Key:value blocks" ("`GridLayout` key:value (power `InfoLabel`/`InfoValue` 510–535, network 1224–1267)")

- Issue: `power/Panel.qml:510–535` is not a `GridLayout`: it defines `component InfoPair: Row` with `InfoLabel`/`InfoValue` `Text` components (bodySmall, label `opacity: 0.6`). Only `network/Panel.qml:1224` uses `GridLayout` (`columns: 4`). The proposed `GridLayout { columns: 2; columnSpacing: Style.space(20); rowSpacing: Style.spacing.labelGap }` is valid QML (requires `import QtQuick.Layouts`, which Panel.qml does not import today).
- Proposed fix: Cite power 510–535 as the `InfoLabel`/`InfoValue` type-role precedent and network 1224 as the `GridLayout` precedent; add `import QtQuick.Layouts` to the InfoGrid component note.

**F017** · **low** · round 1 · `completeness` · at: §6 closing paragraph ("`QtQuick.Shapes` with `Shape.CurveRenderer` (`Ui/BorderOverlay.qml:30, 51`") and §9.1 table ("`Ui/BorderOverlay.qml:30`")

- Issue: `preferredRendererType: Shape.CurveRenderer` is at `Ui/BorderOverlay.qml:28` (the `Shape {` opens at 26, `ShapePath {` at 30); `PathSvg { path: root._path }` at 51 is correct.
- Proposed fix: Change 30→28.

**F018** · **low** · round 1 · `completeness` · at: §5 T1 ("`Color.loadColors` (`Color.qml:135–168`)"), T14 ("`Color.qml:23`, `168`"), §9.1 "Theme reload" row ("`Color.qml:28, 170–171`")

- Issue: `loadColors` spans Color.qml:135–165 and the `muted` fallback is line 164 (02 §5 cites 135–165 and 164 correctly). Lines 170–171 are the `themeShellValues`/`userShellValues` declarations; the wholesale `shellValues` reassignment that re-evaluates bindings is `mergeShell()` at 204–209 (`shellValues = merged` 208).
- Proposed fix: Use 135–165, 164, and "`Color.qml:28` declaration, `mergeShell()` 204–209".

**F019** · **low** · round 1 · `feasibility` · at: §9.2 layout paragraph — "Two open columns fit … (≈ 146 units each at base 12, 110 at base 9)"; 05 §6 risk "openW ≈ 110 units at base 9"

- Issue: 04 §4.3 corrects these to 130 (base 12) and 96 (base 9) because the content holder is card − 2 × popupPadding − 2 × border; 01 and 05 still carry the card-width figures.
- Proposed fix: Replace with 130 / 96 in 01 §9.2 and 05 §6.

**F020** · **low** · round 1 · `ground-rules` · at: §6 'Quattro ethos principles' table numbered P1–P14 vs 02-design-principles.md intro 'Ethos principles from the Quattro research are cited as E1–E14' and 02 §1 design principles numbered P1–P12

- Issue: 01 labels the fourteen ethos principles P1–P14 while 02 labels the same set E1–E14 and reuses P1–P12 for the twelve design principles. A reader following 02's citations '(E2, G27)' cannot find E2 in 01, and 'P1' means two different things in the two documents.
- Proposed fix: Rename 01 §6 rows to E1–E14 and update the two cross-references in 01 (§6 intro, §10 table) accordingly.

**F021** · **low** · round 2 · `data-truth` · at: §2.1 Surface tree "Connections hostWidget (3792–3813)" and §2.6 range map row "3792–3813 | `Connections` to `hostWidget`" (also 05 §2 fate table "3792–3813")

- Issue: The `Connections { target: root.hostWidget }` block starts at Panel.qml:3784; 3788–3795 is `onCliVerifiedChanged` (inventory/schedule/override loads and `ensureCoverage`), which the range omits. 3796 (`onCliVersionChanged`) and 3808 (`onAlertsChanged`) are correct.
- Proposed fix: Change the range to 3784–3813 in 01 §2.1, §2.6 and 05 §2, and list `onCliVerifiedChanged` (3788) alongside the other two handlers.

**F022** · **low** · round 2 · `data-truth` · at: §5 Token misuse list, T12: "2295, 2335 | Magic sizes `Style.space(28)` tab height, `Style.space(64)` button width"

- Issue: Panel.qml:2295 is `required property var modelData`; the `height: Style.space(28)` is at 2298. 2335 (`width: Style.space(64)`) is correct.
- Proposed fix: Cite 2298 for the tab height.

**F023** · **low** · round 2 · `data-truth` · at: §4 Visual kit gap table, Destructive buttons row: "`PanelActionButton.hoverColor: urgent` for destructive row actions (network forget 1745 idiom)"

- Issue: network/Panel.qml:1745 is `color: row.forgetVisible ? root.bar.urgent : Qt.darker(root.bar.foreground, 1.4)` on the lock-indicator `Text` (1738–1748), not a `PanelActionButton.hoverColor` binding; the network panel never sets `hoverColor`. The property itself is real (Ui/PanelActionButton.qml:33, documented 6–9), so only the precedent is wrong.
- Proposed fix: Cite `Ui/PanelActionButton.qml:6–9, 33` for the urgent `hoverColor` mode and drop "network forget 1745 idiom", or cite network 1745 only as the urgent-tint-on-forget precedent for a `Text`.

### 4.3 02-design-principles.md

33 issues (round 1: 21, round 2: 12).

#### High (2)

**F024** · **high** · round 1 · `data-truth` · at: §3.7 confirmation template (`buttons 88 x 34`), §2.1 row "Confirm buttons | Style.font.caption" vs row "Row primary, notice text, button label… | Style.font.body"; also 03 §10 "buttons `Style.space(88) × Style.space(34)` with `Ui/ConfirmDialog.qml:96–130` chrome"

- Issue: The confirm labels overflow the kit button. Verified: `Ui/ConfirmDialog.qml:97–98` fixes `width: Style.space(88)`, and line 114 sets the label at `Style.font.caption`. JetBrains Mono advance is 0.6 em, so at base 12 `Record baseline` (15 chars) = 90 px, `Replace baseline` (16) = 96 px, `Remove baseline` (15) = 90 px — all wider than the 88-unit button, at every base size (both scale identically). The kit's own buttons carry `Cancel`/`Confirm`. The decision point of the whole product would ship with clipped verbs at 10 px, and 02 §2.1 contradicts itself (button label = body, confirm button = caption).
- Proposed fix: In `ConfirmSheet`: label at `Style.font.body` (the doc's own P7 rule for button labels), buttons sized to content with the kit minimum — `width: Math.max(Style.space(88), label.implicitWidth + Style.space(28)); height: Style.space(34)` — and confirm labels reduced to the verb, since the title already names the object: `Record` · `Replace` · `Remove` · `Enable` · `Update` · `Install`. Update the §3.7 table 'Confirm label' column, the two wireframes in 03 §10, the §2.1 'Confirm buttons' row to `Style.font.body`, and the README GR6 sentence.

**F025** · **high** · round 2 · `data-truth` · at: §2.7 Iconography, UI glyphs table: "shield, outline (no scan result …) | `󰦟` | F099F" — also 03 §1 Conventions `(s)`, 03 §2 Bar widget ("outline shield `󰦟` U+F099F (present in JetBrainsMonoNerdFont-Regular.ttf, re-checked with fontTools)"), 03 §3 hero glyph rule, 05 §9 OmaSafeShield row

- Issue: U+F099F is `md-set_top_box` in the installed JetBrainsMonoNerdFont-Regular.ttf (fontTools cmap glyph name), not an outline shield. The fontTools check only asserted presence, not identity, so the bar/hero glyph for every "no scan result" state (ready, CLI missing/incompatible, failed with nothing prior) would render a set-top-box icon.
- Proposed fix: Use `md-shield_outline` U+F0499 (`󰒙`); if the filled form should be its exact pair, use `md-shield` U+F0498 (`󰒘`) instead of `md-security` F0483, or keep F0483 and pair it with F0499. Update the glyph, codepoint and ASCII rows in 02 §2.7, the `(s)` convention in 03 §1, the code/table in 03 §2, the hero rule in 03 §3 and the 05 §9 inventory row; extend the fontTools acceptance check to assert glyph names (e.g. `cmap[0xF0499] == 'md-shield_outline'`), not just presence.

#### Medium (13)

**F026** · **medium** · round 1 · `api-truth` · at: §3.4 Enum labels, row 'limitation code' ("LidService.qml · 8 sink references rejected (absolute) · 5 missing local target")

- Issue: Same swap as 04: the sample has 5 `absolute` and 8 `missing-local-target` rejections for LidService.qml.
- Proposed fix: "LidService.qml · 5 sink references rejected (absolute) · 8 missing local target".

**F027** · **medium** · round 1 · `data-truth` · at: §2.7 text glyphs (`┄` not analyzed, `·` none observed), §2.8 density sample; 03 §4.1 plugin rows `┄┄┄ not analyzed`; 04 §9.5 Matrix (`–` not analyzed, `·` none observed); 04 §5 nodes (`󰝦` + `–`)

- Issue: One state — 'not analyzed' — has three marks across three views: `┄` in the Overview strip, `–` in the Matrix and node counts, hollow `󰝦` on nodes. The doc even flags `󰝦`'s dual meaning (low severity vs not analyzed). A user moving Overview → Flow → Matrix has to relearn the placeholder each time; this is the visual-language inconsistency between documents.
- Proposed fix: One placeholder vocabulary, stated once in 02 §2.4: `–` = not analyzed / no data (strip, matrix cell, node count, rule hit count, `exercised here`), `·` = analyzed and not observed, `unavailable` = the word. The Overview strip for an unanalyzed plugin prints a single `–` followed by `not analyzed`, not 17 `┄`. Delete `┄` from §2.7 and the §2.8 / 03 §4.1 samples. Reserve `󰝦` for the hollow plugin node in Flow only (see the severity-glyph fix).

**F028** · **medium** · round 1 · `data-truth` · at: §2.3 "Light themes accept the kit's `Qt.darker` trade (it darkens a dark foreground, raising contrast); … fidelity wins over a luminance guard"; 03 §14 Contrast; 05 §13 open question 3

- Issue: The entire hierarchy rests on three dim steps (`Qt.darker(fg, 1.4 / 1.5 / 2.0)`) because there is almost no size contrast (body 12 vs bodySmall 11). On `catppuccin-latte` (fg #4c4f69) and `white`, `Qt.darker` makes secondary text, headers and notices *heavier* than primary text, so the hierarchy inverts on every light theme. Verified: the kit has no luminance-aware helper (`grep -i 'isLight|luminance|lighter(' Commons/ Ui/` → nothing) and first-party panels share the defect. The docs acknowledge it but defer to Phase 4, after every screen has been built on the assumption.
- Proposed fix: Decide in Phase 1 and say so in 02 §2.3: define dim as an opaque mix toward the theme background rather than a darken — root `function dimStep(k) { var b = Color.background; return Qt.rgba(fg.r*(1-k)+b.r*k, fg.g*(1-k)+b.g*k, fg.b*(1-k)+b.b*k, 1) }` with `dimHeader = dimStep(0.25)`, `dim = dimStep(0.33)`, `faint = dimStep(0.55)`. It is opaque (no wallpaper bleed), works in both polarities, and matches `Qt.darker(fg,1.5)` closely on dark themes. Note the deliberate divergence from `PanelHero.dim` and add `catppuccin-latte` + `white` at base 9 to the Phase 1 (not Phase 4) acceptance screenshots.

**F029** · **medium** · round 1 · `data-truth` · at: §2.4 severity rows: `info`/`low`/`medium`/`high` → `󰋽` / `󰝦` / `󰝥` / `󰀦`; `critical` → `󰀦` in `urgent`; note "`󰝦` appears in two contexts"

- Issue: `high` and `critical` share the same triangle and differ only by hue — which P9 says may never carry meaning alone, and in `white` urgent is #2a2a2a ≈ foreground. `low` vs `medium` is an outline-vs-fill difference on a 10.5 px circle at base 9. And `󰝦` doubles as 'not analyzed' on nodes.
- Proposed fix: Distinct shapes per step, verified present in JetBrainsMonoNerdFont: info `󰋽` (F02FD) · low — no glyph, word only (matching the 'unavailable/unsupported: none' rule) · medium `󰝥` (F0765) · high `󰀦` (F0026) bold · critical `󰚌` alert-octagon (F068C) bold + urgent. This frees `󰝦` (F0766) to mean exactly one thing — a hollow, unanalyzed node — and lets critical survive hue removal by shape. Update 02 §2.7 glyph table (ASCII `O` for octagon), 03 §5.2, 04 §5.

**F030** · **medium** · round 1 · `design-quality` · at: §3.4 Enum labels, `schedule` row (line 542): `hardened` -> "Hardened: enable and update may be refused"; consumed by 03-ui-overhaul-proposal.md §4.4 schedule row (lines 304-306, `Labels.policy(policy)`). Contrast 02 §3.7 schedule sheet effect (line 615) "hardened adds analysis and does not disable a running plugin"

- Issue: Verified in omasafe-cli/src/main.rs:3424-3500 (`schedule_install`): the only effect of `--policy hardened` on the schedule is appending ` --include-analysis` to `ExecStart=… scan --notify --only-new`; `report_only` is always `true`. A scheduled hardened scan never refuses enable or update. The SOURCES row label states an effect the unit does not have, and the ConfirmSheet policy definition line (03 §10 template, line 787) is not specified for the schedule variant, so the review-update definition "Advisory reports and proceeds; hardened may refuse" would be reused. Confirmation must show exactly what is authorized (GR6, P5).
- Proposed fix: Schedule labels: `Advisory: daily drift scan, reports only` / `Hardened: daily drift scan with analysis, reports only`. ConfirmSheet(schedule) policy definition: `Advisory runs scan --notify --only-new; hardened adds --include-analysis. Both report only.` Keep the enforcement-policy definition ("hardened may refuse") for enable and review-update only; split `Labels.policy` into `schedulePolicy` and `enforcementPolicy`.

**F031** · **medium** · round 1 · `design-quality` · at: §3.4 marketplace `status` row (line 531): `conflict` -> "Catalog entry conflicts with the installed repository"; repeated in 03-ui-overhaul-proposal.md §5.4 (lines 510-511) and 04-trust-graph-spec.md §3.3 (line 211)

- Issue: Verified in omasafe-marketplace/src/lib.rs:367-371: `conflict` is emitted whenever the id matched but `matches` is empty, with reason "plugin ID matched, but repository identity conflicted OR WAS UNAVAILABLE". For `io.github.tuthan.omasafe` and `io.github.hvo.omarchy-unraid` (`repository: null`, `built-in`) the repository is unavailable, not conflicting. The label asserts a definite conflict on missing data, which GR3 forbids (missing renders unavailable, not as a stronger state).
- Proposed fix: Label: `Catalog entry not matched: installed repository conflicts with the listing or is unavailable`, followed by the CLI `reason` verbatim (already planned). When `plugin.repository == null` add the fact line `Installed repository: unavailable (no git remote)` so the reader sees which branch applies.

**F032** · **medium** · round 1 · `ground-rules` · at: §2.7 'Capability classes (fixed order, shared by CapabilityStrip, MatrixGrid and the Flow CAPABILITIES layer)' vs 04-trust-graph-spec.md §4.1 step 2 'Classes: occurrences desc, id asc' and §12 'Matrix default shows 5 columns in catalog order (PX TM WM FS DX)'

- Issue: Three inconsistent class orderings. 02's table (PX DX NW FS SP IN SC TM …) puts network-access 3rd, but the rules-list first-appearance order is PX DX FS SP IN SC NW TM CB WM PK LK PA DC IPC BAR BIN (verified in rules-list.json). 04 sorts the Flow CAPABILITIES layer by occurrences (contradicting 02's 'shared fixed order'), and 04 §12 calls 'PX TM WM FS DX' catalog order when it is occurrence-desc order.
- Proposed fix: Define 'catalog order' once in 02 §2.7 as the rules-list first-appearance order and renumber the table (NW becomes #7); state in 02 that the Flow CAPABILITIES layer uses occurrence order (barycentre-adjusted) while CapabilityStrip and MatrixGrid use catalog order; correct 04 §12 to 'PX DX FS TM WM' or relabel it as occurrence order.

**F033** · **medium** · round 1 · `ground-rules` · at: P7 'Anything read as data — ids, paths, line numbers, hashes, counts, … matrix digits — is bodySmall or larger' vs §2.1 type-roles row 'Hints, relative times, chip labels, footer, node counts, breadcrumb → Style.font.caption' and 04 §5 / §10.2 FlowNode 'count Text … font.pixelSize: Style.font.caption'

- Issue: Graph node counts (occurrences, review items) are data under P7's floor rule but are specified at caption size in 02 §2.1, 04 §5 and the FlowNode sketch. At base 9 that is 7.5 px for the one quantitative channel the graph has.
- Proposed fix: Move node counts to Style.font.bodySmall in 02 §2.1, 04 §5 and the FlowNode sketch (adjust the 'countW ≈ 3 chars' term in 04 §4.3 accordingly), or carve out an explicit exception in P7 with a reason.

**F034** · **medium** · round 2 · `api-truth` · at: §3.4 Enum labels: `registry_claim.installed_matches_listing` → "Installed commit matches the listing" / "Installed commit differs from the listing" (line 597) and marketplace `status` `installed-differs` → "Listed; installed commit differs from the listing" (line 594); rendered in 03-ui-overhaul-proposal.md §5.4 wireframe (line 619) and prose (line 651, 657)

- Issue: `matches` and `differs` are the reserved trust-comparison words (02 §3.2: "matches / differs from baseline"; §2.4 trust encodings; P2's review test names `matches`, `differs` as trust words and `listed` as a catalog word and requires that no row contain both). "Installed commit matches the listing" and "Listed; installed commit differs from the listing" put a trust word and a catalog word on one row inside MARKETPLACE CLAIM, so the section's own check fails, and a reader who has learned `differs` = source drift will read `installed-differs` as drift from the baseline — the conflation of catalog correlation with local trust that GR2 forbids.
- Proposed fix: Use distinct verbs for the catalog comparison: `installed_matches_listing` true → "Installed commit is the listed commit", false → "Installed commit is not the listed commit", null → "Listing commit not stated"; `installed-differs` → "Listed; installed commit is not the listed commit" (short form "Listed; not at listed commit"). Keep `matches`/`differs` exclusively for the TRUST BASELINE comparison and add the new strings to the P2 review-test word lists.

**F035** · **medium** · round 2 · `api-truth` · at: §3.3 Status strings, relative time paragraph (line 534–535: "`<n> days old (stale)` at ≥ 30 days or `marketplace_stale`"); 05-implementation-roadmap.md §9 component inventory `model/Time.js` (line 548: "relative time, ages, stale threshold")

- Issue: The panel is given its own 30-day staleness threshold in `Time.js` in addition to the CLI's `marketplace_stale`. The CLI already computes the flag (omasafe-cli/src/main.rs:4649: `marketplace_age_seconds > 30*24*60*60`) and it is the single source used everywhere else in the docs (02 §3.4, 03 §4.4, 03 §11, 04 §8) to suppress "verified". A panel-side threshold is the panel evaluating catalog-freshness policy itself; if the CLI's threshold changes, the two disagree and the panel would print `(stale)` or omit it on its own authority.
- Proposed fix: Key `(stale)` and the "verified"-suppression solely on `result.marketplace_stale`; delete "at ≥ 30 days" from 02 §3.3 and "stale threshold" from the `Time.js` responsibility in 05 §9 (Time.js formats ages; it decides nothing). Add to the P3 review test: `marketplace_stale: false` with `marketplace_age_seconds` = 40 days renders the age without `(stale)`.

**F036** · **medium** · round 2 · `completeness` · at: §3.4 Enum labels, "limitation code" row (three grammars); also 01-research-and-audit.md §8.3 `plugins analyze` row and 03-ui-overhaul-proposal.md §5.3 COVERAGE

- Issue: `plugins analyze` also appends coverage limitation codes that fit none of the three grammars: `suppressions-unreadable:<error text>` (main.rs:5404–5411), `suppression-reconfirmation-required:<n>` (main.rs:5457–5459) and `equivalence-map-stale:map-v<x>-observed-v<y>` (main.rs:5470–5473). Under the documented `kind[:sub]:file[:line[:target]]` parser the second segment would be read as a file name (`map-v3-observed-v4`, or the free-form error text, which may itself contain colons), and the codes would otherwise be tagged "unsupported limitation" although they are known CLI codes.
- Proposed fix: Add a fourth grammar for `<code>:<value>` codes with no file (`suppressions-unreadable`, `suppression-reconfirmation-required`, `equivalence-map-stale`) rendered as their own group with the value verbatim; list them in 01 §8.3 and 03 §5.3; make the parser match known kinds by prefix before falling back to the file grammar.

**F037** · **medium** · round 2 · `completeness` · at: §3.2 Vocabulary and §3.4 `classification` — "`built-in` → Installed without git (shell built-in)"; 01-research-and-audit.md §8.3 "`built-in` = no git ... and is not first-party"

- Issue: The gloss "(shell built-in)" asserts a fact the CLI did not assert for either fixture plugin: `io.github.hvo.omarchy-unraid` and `io.github.tuthan.omasafe` are `classification: built-in` with `first_party: false` (inventory.json), because omasafe-plugin-trust/src/lib.rs:354–359 assigns `built-in` when `first_party == Some(true)` OR `cloned_from == ""`. 01 §8.3's "is not first-party" is likewise a fixture observation, not a contract (a built-in plugin can be first-party). The label contradicts 02 §3.2's own rule that the parenthesis "states what the CLI asserted".
- Proposed fix: Label `built-in` as `Installed without git` (no parenthesis) and, if wanted, add a separate fact line from `first_party` (`First-party: yes / no / not stated`). Reword 01 §8.3 to "`first_party` may be true or false; both fixture plugins report false".

**F038** · **medium** · round 2 · `data-truth` · at: §2.7 Capability classes table: "16 | replaces-bar-context | `󱂢` | F10A2 | `BAR`" (also drawn in 04 §5 glyph list `… 󰌘 󱂢 󰍛`)

- Issue: U+F10A2 is `md-decimal_comma` in the installed font — a decimal-comma symbol, not a bar/dock glyph. The class strip, Matrix header and Flow node would show a comma for `replaces-bar-context`.
- Proposed fix: Pick a bar-shaped glyph that exists in the font: `md-dock_bottom` U+F10A9 (`󱂩`), `md-dock_top` U+F1513 (`󱔓`) or `md-page_layout_header` U+F06FC (`󰛼`); update 02 §2.7 row 16 and the 04 §5 glyph list, and add the name assertion to the fontTools check.

#### Low (18)

**F039** · **low** · round 1 · `api-truth` · at: §2.8 Density example ("[g ] io.github.tuthan.omasafe … matches baseline / PX · … TM … 1 review item")

- Issue: In inventory.json io.github.tuthan.omasafe is `classification: built-in` (repository/head/tree null) → glyph `p` / 'Installed without git', and status-io.github.tuthan.omasafe.json is `state: untrusted`, `reason: no trust baseline exists` → 'no baseline'. The strip and '1 review item' are correct. README claims every example uses the captured fixture.
- Proposed fix: "[p ] io.github.tuthan.omasafe … no baseline" (or switch the example to io.github.tuthan.dropdown-terminal, the only `unchanged` plugin).

**F040** · **low** · round 1 · `api-truth` · at: §3.7 Confirmation template wireframe ("Plugin lgse.sandman / Head 3f2a… / Tree 9c1f… / Digest d26a…")

- Issue: Placeholder hashes do not belong to lgse.sandman (head e8161c6e…, tree 4e5fab6d…, digest 59fdc825…); `d26a…` is ilyazar.btop's content_digest. 03 §10 shows the correct values.
- Proposed fix: Use e8161c6e… / 4e5fab6d… / 59fdc825… or label the values as placeholders.

**F041** · **low** · round 1 · `api-truth` · at: §3.4 Enum labels, rows `registry_claim.upstream_moved` ("true → Upstream has moved past the validated commit") and 03 §5.4 `installed_matches_listing` mapping

- Issue: Both fields are `Option<bool>` (omasafe-marketplace/src/lib.rs:85–86) and are null whenever `listing_validated_commit` or `upstream_observed_commit` is absent (lib.rs:387–398). The label tables define only true/false, so a null would fall through to a blank or to a false-looking 'Installed commit differs' — the fail-closed rule (GR3) requires an explicit word.
- Proposed fix: Add a null row for each: `upstream_moved: null` → "Upstream movement not stated"; `installed_matches_listing: null` → "Listing commit not stated".

**F042** · **low** · round 1 · `completeness` · at: §3.4 Enum labels, row "limitation code" ("`LidService.qml · 8 sink references rejected (absolute) · 5 missing local target`")

- Issue: Same inversion as 04: the fixture has 5 absolute and 8 missing-local-target codes.
- Proposed fix: Use `LidService.qml · 5 sink references rejected (absolute) · 8 missing local target` to match 01 §8.4 and 03 §5.3.

**F043** · **low** · round 1 · `completeness` · at: P6 Why ("re-implements the rest with 126 `Text`, 19 `Rectangle` and 6 `MouseArea`") and Statement of P6 / README ("4 of 30 primitives", "30 primitives")

- Issue: Counts disagree with the verified source: Panel.qml has 25 `Rectangle {` (01 §2.1 says 25, grep confirms), and `Ui/qmldir` exports 32 components (01 §1 says 32; README and 02 say 30).
- Proposed fix: Use 25 `Rectangle` and "4 of 32 exported `qs.Ui` components" in 02 and README.

**F044** · **low** · round 1 · `data-truth` · at: §3.3 Empty strings: `Not analyzed. Press a to analyze (about 0.2 s).`; repeated in 03 §5.2, §11 and 04 §5/§8

- Issue: A runtime promise in UI copy. The figure is a warm-cache measurement on one machine (126–182 ms); cold cache, a 10 000-file plugin or a slow disk makes the sentence false, and the `a` key is meaningless to a mouse user who is looking at an `[Analyze]` button.
- Proposed fix: `Not analyzed. Press a or Analyze.` (tooltip on the button: `Analyze (a)`). Remove the timing everywhere it is repeated (02 §3.3, 03 §5.2 and §11, 04 §5 and §8).

**F045** · **low** · round 1 · `data-truth` · at: §2.5 "pills only on the two disabled bordered `Button`s of an expanded review item"; 03 §5.2 "two pills (`Button { bordered: true; enabled: false; fontSize: Style.font.caption }`)"

- Issue: A disabled `Button` used as a label is a semantic misuse of the kit ('one component for every clickable thing'): it inherits disabled chrome (`PanelActionButton`-style faint ink), the cursor model must skip it, and it is one more caption-size use of data (`low · catalog severity`). The kit already has a non-interactive pill: `PanelHero`'s `detailPill` (`Ui/PanelHero.qml:67–87`, `BorderSurface` + `Border.controlSpec("normal")`, `body` bold dim).
- Proposed fix: Define `components/FactPill.qml` as that `BorderSurface` pattern (`implicitWidth: text + Style.space(10)`, `radius: Style.cornerRadius`, text `bodySmall`, `PanelToolTip` on `hasCursor` of the parent row) and use it for the severity and confidence pills. Update 02 §2.5 / §2.1 and 03 §5.2.

**F046** · **low** · round 1 · `design-quality` · at: §3.3 Success lines (line 520) `<id> enabled.`; 03-ui-overhaul-proposal.md §5.5 (lines 549-550) "Success lines render in place … from exit status"

- Issue: Verified in omasafe-cli/src/main.rs:2216-2221 and 2330-2480: `plugins enable --format json` prints `EnableResult { enabled: bool, decision }` and, under hardened block or a failed postcondition, prints `enabled: false` then returns Err (exit 1). Keying the success line on exit status alone is correct today but fragile; the design should bind the success/blocked line to `result.enabled` and `result.decision.outcome`, which are the CLI's own words, so a future exit-code change cannot render a block as `<id> enabled.` (GR3: never allow by default).
- Proposed fix: Success line only when `schema === omasafe.report.v1 && result.enabled === true`; otherwise render `Enable refused: <decision.reason_codes>` from the same JSON and re-fetch ENFORCEMENT. State this in 03 §5.5 and 05 Phase 1 acceptance.

**F047** · **low** · round 1 · `design-quality` · at: §3.4 Enum labels, `classification` row (line 530); 01-research-and-audit.md §8.3 (line 378) lists only `Git-managed`, `built-in`, `backup`, `unscannable`

- Issue: Verified in omasafe-plugin-trust/src/lib.rs:340-370: the non-git classification is `built-in` only when the shell reports `first_party == true` or `cloned_from == ""`; otherwise it is `cloned/local`, a real emitted value absent from the label table, so a legitimate plugin installed by copy would render `Unsupported classification: "cloned/local"`. Fail-closed, but it labels known CLI output as unsupported and the `built-in` label "Installed without git" describes the git fact rather than what the CLI asserts (shell first-party or no clone source).
- Proposed fix: Add `cloned/local` -> `Installed without git (local copy)` and keep `built-in` -> `Installed without git (shell built-in)`; add `unscannable` -> `Unscannable: <classification_reason>`; update 01 §8.3 to list all five values with the lib.rs anchor.

**F048** · **low** · round 1 · `design-quality` · at: P5 Don't (line 121): "a confirmation for Scan or Update catalog (read-only network work; inline progress instead)"; 03-ui-overhaul-proposal.md §4.1 SOURCES callout (lines 221-222) and §5.5 (line 546)

- Issue: `marketplace refresh --latest` (main.rs:4805 `fetch_pinned_catalog`) is the only network call and it rewrites the cached snapshot, which changes every MARKETPLACE CLAIM row, the SOURCES age line and the basis of `provenance-conflict` alerts. Calling it "read-only" misdescribes it; the design's actual decision (manual, unconfirmed, no accelerator, inline progress) is consistent with the brief, so the fix is wording plus one guard.
- Proposed fix: Reword to "non-destructive network fetch that replaces the local catalog snapshot; manual only, no letter key, inline progress". Keep it out of `textKey` handlers (already true) and gate the `PanelActionButton` on `!navigationLocked` like every other action so it cannot run under a sheet.

**F049** · **low** · round 1 · `ground-rules` · at: P6 Do: 'the only local composites are NoticeRow, SectionHeaderRow, InfoGrid, CapabilityStrip, ConfirmSheet and the graph/* items'

- Issue: Contradicts the component inventory in 05 §9 and the screens in 03, which add ActionRow, AlertRow, PluginRow, ClassRow, EvidenceRow, EdgeRow, SourceRow, RuleRow, RelationRow, Breadcrumb, FinderField, InspectorStrip (in components/, not graph/) and OmaSafeShield.
- Proposed fix: Rewrite the P6 sentence as 'the only local composites are those listed in 05 §9, each composed from kit parts' or enumerate the full list.

**F050** · **low** · round 1 · `ground-rules` · at: P1 Do: 'The bar badge is a count in foreground' vs P9 list of urgent uses ('the bar badge') and 03 §2 'the badge is the only urgent paint in the bar; the count is foreground text'

- Issue: 'Badge' is used for two different things: in P1 it is the foreground count, in P9 and 03 §2 it is the urgent BorderSurface circle for critical/error/block.
- Proposed fix: In P1 write 'The bar shows a count in foreground; the urgent badge appears only for critical/error or a block'.

**F051** · **low** · round 2 · `data-truth` · at: §2.2 Spacing rhythm, Confirm card row: "the kit's fixed `space(88)` at `ConfirmDialog.qml:97`" (03 §10 cites the same chrome range 96–130)

- Issue: `width: Style.space(88)` is at Ui/ConfirmDialog.qml:98; line 97 is blank and 96 is `readonly property bool destructive: index === 1`.
- Proposed fix: Cite `ConfirmDialog.qml:98` (width) and `:99` (height `Style.space(34)`).

**F052** · **low** · round 2 · `data-truth` · at: §2.7 Iconography, UI glyphs table: "backup copy | `󰁓` | F0053 | `b`"

- Issue: U+F0053 is `md-arrow_left_drop_circle_outline` in the installed font — a left-arrow-in-circle, not a backup/archive glyph. It exists, so it renders, but it does not carry the meaning the table assigns and would read as a "back" affordance next to the `󰅁` back chevron.
- Proposed fix: Use `md-backup_restore` U+F006F (`󰁯`) or `md-archive_outline` U+F120E (`󱈎`), and add the glyph-name assertion to the fontTools check.

**F053** · **low** · round 2 · `data-truth` · at: §2.2 Spacing rhythm: "Only `Style.space(n)` with n ∈ {1, 2, 6, 8, 10, 12, 18, 20, 22, 28, 32, 34, 72, 88, 370, 400, 420, 560} or a `Style.spacing.*` token."

- Issue: The closed set omits values the same document set binds elsewhere: `Style.space(4)` (02 §2.5 FactPill height inset, copied from PanelHero.qml:78), `space(3)` (04 §4.1 thick edge bucket, EdgeLayer sketch), `space(190)` (03 §4.1 strip cap), `space(600)` and `space(1080)` (04 §4.3 window), `space(14)` (05 §2 border math). The 02 §4 blocker ("no pixel literal … kit tokens or `Style.space(n)` only") is unaffected, but the enumerated set is not the one the docs use.
- Proposed fix: Either add 3, 4, 14, 190, 600, 1080 to the set or replace the enumeration with the rule ("any `Style.space(n)` or `Style.spacing.*`; no bare pixel literal").

**F054** · **low** · round 2 · `ground-rules` · at: §3.3 Trust rows — PLUGINS footer: "A baseline is the exact source identity you recorded. \"Matches\" and \"differs\" compare the installed files against it; neither is a safety judgment."

- Issue: 03 §4.1 wireframe and callout print a different sentence for the same footer: "Baseline = the exact source identity you recorded. Matches / differs is a comparison, not a judgment." 02 §3 is declared the single source of every status string and 05 Phase 2 acceptance checks for "the PLUGINS footer definition sentence".
- Proposed fix: Use one wording in both places; 02 §3.3 is the copy authority, so change 03 §4.1 (wireframe and callout) to the 02 sentence or update 02 to the shorter form.

**F055** · **low** · round 2 · `ground-rules` · at: §2.2 Spacing rhythm — "Only `Style.space(n)` with n ∈ {1, 2, 6, 8, 10, 12, 18, 20, 22, 28, 32, 34, 72, 88, 370, 400, 420, 560}"

- Issue: The closed set is violated by the documents themselves: 02 §2.4 uses `space(3)` (thick edge), 02 §2.5 `space(4)` (FactPill height pad), 02 P8 / 03 §4.1 `space(44)` (row-height ceiling), 03 §4.1 `Style.space(190)` (strip cap), 04 §4.3 and 05 §8 `Style.space(1080)` and `space(600)` (window). 04 §13 notes only the addition of 72.
- Proposed fix: Extend the set in 02 §2.2 to {…, 3, 4, 44, 190, 600, 1080} (marking 600/1080 as Phase 5 only) or reword the sentence as a preferred set rather than a closed one.

**F056** · **low** · round 2 · `ground-rules` · at: §2.7 Iconography — UI glyph table row "in flight `󰦖` F0996 `~`" and Text glyphs "ASCII fallback: `~` `->` `>` `.` `-`" (≈ → `~`)

- Issue: In the ASCII fallback (`Glyphs.js` when the font is not a Nerd Font) `~` is assigned twice: to the in-flight/analyzing glyph and to the partial-overlap relation mark `≈`. 04 §9 also uses `~` for ≈ in rails. A non-Nerd user would see the same character for "analyzing" and "partially covered".
- Proposed fix: Give the in-flight fallback a distinct character (e.g. `%` or `:`) and keep `~` for ≈, then update the Glyphs.js description.

### 4.4 03-ui-overhaul-proposal.md

64 issues (round 1: 38, round 2: 26).

#### High (6)

**F057** · **high** · round 1 · `data-truth` · at: §2 Bar widget — table row "`Text { font.pixelSize: Style.font.caption }` right of the glyph, `9+` cap" and the ASCII frame `(S) 3`

- Issue: The count-beside-glyph bar icon cannot be built as specified. `Ui/BarIconButton.qml` mounts `iconComponent` in a `Loader { anchors.fill }` over a 16-unit `opticalCanvas` inside `fixedWidth: slotSize` (`Style.bar.statusSlot` = 21). A 13-unit shield plus a gap plus a caption `9+` (~12 px) needs ~30 units. No first-party bar widget renders icon + text (`SystemUpdate.qml` is glyph-only in the same slot; `BarIndicator.qml:49` also fixes width to `statusSlot`), so there is no native precedent to lean on either. The doc's own audit (01 §4) says the current 13-unit disc with the digit inside was replaced 'by a dim bar icon plus badge', yet §2 draws the digit outside the slot.
- Proposed fix: Make the count a sibling of the button, not part of the icon: in `BarWidget.qml`, `Row { spacing: Style.space(2); BarIconButton { slotSize: Style.bar.statusSlot; iconComponent: OmaSafeShield {…} } Text { visible: count > 0; text: count > 9 ? "9+" : String(count); font.pixelSize: Style.font.caption; color: barForeground } }` with `root.implicitWidth = row.implicitWidth` (the `WidgetButton.implicitWidth` contract at `Ui/WidgetButton.qml:68` already lets the widget grow). State this explicitly in §2 and add the `Row` to 05 §9 component inventory under `BarWidget.qml`. Do not use a digit-in-badge: TailscaleIcon's badge is `max(7, 0.42·icon)` ≈ 7 px with a 5 px glyph — illegible.

**F058** · **high** · round 1 · `data-truth` · at: §2 Bar widget — table rows `ready` and `scanned, outstandingCount == 0`; row `checking`

- Issue: Two different states render identically: `ready` (CLI verified, never scanned) and `quiet` (scanned, 0 alerts) are both `󰒃` in `barForeground`, no count, no badge — only the tooltip differs. A never-scanned machine therefore looks exactly like a clean scan result, which is the GR3 failure the doc forbids elsewhere ('nothing ever defaults to clean'). Separately, `checking` swaps the shield for a rotating `󰑐`, so the widget loses its identity in the bar while scanning; no first-party icon changes silhouette to show busy (tailscale dims, `Button.iconSpinning` spins an icon *inside* a button).
- Proposed fix: Encode 'a scan result exists' in glyph shape, not colour: filled shield `󰒃` (U+F0483) only when a scan result exists (quiet / attention / critical / stale-with-earlier-results); outline shield `󰦟` (U+F099F, verified present in JetBrainsMonoNerdFont) for `ready`, `unavailable` with no prior result, `missing-cli`, `incompatible-cli` — dim additionally for the two CLI-failure states. `checking`: keep whichever shield applies and put `Behavior`-free `RotationAnimation` on a small `󰑐` drawn in the badge position (bottom-right, `fg`, no fill) — the shield never disappears. Add `󰦟` to 02 §2.7 UI glyph table with ASCII `s`, and mirror the same outline/filled rule on the hero glyph.

**F059** · **high** · round 1 · `design-quality` · at: §3 Panel shell, hero-state table rows "scan failed, earlier results" (line 124) and §11 States matrix, Hero/stale cell (line 894); also 02-design-principles.md §3.3 Status strings hero titles (lines 470-472)

- Issue: After a failed rescan the hero TITLE keeps the last-good count sentence and only the meta says LAST SCAN FAILED. The table only shows the attention case (`3 alerts to review`); by the same rule a quiet last result followed by a failed scan renders the headline `No outstanding alerts` from stale data. GR3 says stale/failed data renders unavailable, never clean. The bar widget already gets this right (§2: `unavailable` -> dim shield, count dimmed, never the quiet glyph); the hero contradicts it.
- Proposed fix: When `scanState == unavailable` the hero title is always `Scan unavailable` (or `Last scan failed`), `iconOpacity 0.5`, and the meta carries the stale facts: `SHOWING 3 ALERTS FROM 2 H AGO` / `EARLIER RESULT: NO ALERTS · 2 H AGO`. Add the quiet+failed row to the hero table and the states matrix; add an acceptance check in 05 Phase 1: with the shim failing `scan` after a quiet run, no screen prints `No outstanding alerts`.

**F060** · **high** · round 1 · `design-quality` · at: §7.2 Baseline V3 coverage table: `exercised here · 4 of 4 analyzed`, `– of 4` (lines 658-661, 683-684); same encoding in 04-trust-graph-spec.md §9.6 (lines 655-666, 672-675: `curl-pipe-shell 3 rules 4 of 4`, `sudoers-dangerous-passwordless-command 2 rules 0 of 4`) and §2.3 (line 126)

- Issue: `exercised here k of n analyzed` is computed by the panel from OmaSafe occurrences/findings and attached to a Baseline V3 external id. That is a panel-made claim about an external ruleset the CLI never evaluates locally (rules coverage is a rule-to-rule map, relation `partial-overlap`; equivalence.rs header: the map records overlap, not results). `4 of 4` under curl-pipe-shell reads as "4 plugins trigger the baseline's curl-pipe-shell check" although the occurrences are generic `Quickshell.Io.Process` sites, and `0 of 4` reads as a clean pass on rules whose language (shell/python) is only lexically covered. This contradicts the mandatory header sentence on the same screen ("no plugin is checked against Baseline V3 here") and violates GR1/GR3 (a zero on partial coverage rendered as clean).
- Proposed fix: Drop the per-baseline-id plugin counts. If a bridge to local data is wanted, phrase it strictly about OmaSafe rules: `covering OmaSafe rule oma.qml.process-execution observed in 4 analyzed plugins` inside the expanded row only, and `not observed in 4 analyzed plugins` instead of `0 of 4`; never place a count on the Baseline V3 row itself. Update 04 §12 acceptance (`curl-pipe-shell 3 rules · 4 of 4`, `0 of 4`) accordingly.

**F061** · **high** · round 2 · `api-truth` · at: §5.4 MARKETPLACE CLAIM, ENFORCEMENT, PROVENANCE, line 673–675: "the header right value is the policy word of `decision.enforcement_policy_identity`, uppercased → `ADVISORY` / `HARDENED`"; same header in 02-design-principles.md §P2 Do (line 55 `ENFORCEMENT | ADVISORY / HARDENED / NO DECISION`), README.md "The decision" (line 47) and 01-research-and-audit.md §6 divergence (c) (line 304)

- Issue: The proposed header derives the enforcement policy mode from a field that does not carry it. Verified in /home/hvo/Projects/omasafe/crates/omasafe-report/src/enforcement.rs:206–220 and 400: `EnforcementDecision.enforcement_policy_identity` is `self.identity()`, a 64-hex canonical fingerprint `String`, and the decision struct (378–404) has no `mode`/`policy` field; `plugins enforcement-status` (omasafe-cli/src/main.rs:4030–4045) returns only `history.latest(id)`. Only `EnableResult.policy` (main.rs:2216–2221) carries the mode, and only for the enable call in this session. Printing ADVISORY/HARDENED would therefore be the panel inferring policy on its own (ground rule: the panel never evaluates policy; every enum is rendered from a CLI field or as `unsupported`), and there is no closed enum to fail closed on.
- Proposed fix: Change the header right value to a field the decision actually carries: `ENFORCEMENT | EVALUATED` / `NOT EVALUATED` (from `evaluation_state`, via the existing `enforcementEnum` gate) or `ENFORCEMENT | NO DECISION`; keep the mode words only in the enable/review-update ConfirmSheet policy chooser and in the success/refusal line rendered from `EnableResult.policy`. Update 02 P2, README "The decision" and 01 §6 (c) to the same header. Add a CLI ask in 05 §12: persist `mode` (advisory/hardened) on `EnforcementDecision` so a future header can render it verbatim.

**F062** · **high** · round 2 · `completeness` · at: §5.4 MARKETPLACE CLAIM, ENFORCEMENT, PROVENANCE — "the header right value is the policy word of `decision.enforcement_policy_identity`, uppercased → `ADVISORY` / `HARDENED`"; also §5.4 wireframe `ENFORCEMENT | HARDENED`. Same assumption in 02-design-principles.md P2 "ENFORCEMENT | ADVISORY / HARDENED / NO DECISION", README.md "The decision" and 01-research-and-audit.md §6 divergence (c)

- Issue: `EnforcementDecision.enforcement_policy_identity` is a SHA-256 hex digest of the canonical enforcement policy (omasafe-report/src/enforcement.rs:206–226 `identity()` → `Sha256::digest(...)` hex), not a mode word. `EnforcementDecision` (enforcement.rs:381–404) has no `policy`/`mode` field and `plugins enforcement-status` (main.rs:4030) emits only `{plugin_id, decision}`. The advisory/hardened mode of a recorded decision is therefore data the CLI does not provide; the docs assume it without saying so. The only place the mode appears is `EnableResult.policy` in the `plugins enable --format json` response of the current session (main.rs:2216–2221).
- Proposed fix: Drop `ADVISORY` / `HARDENED` as the ENFORCEMENT header value. Use `NO DECISION` when `decision` is null and otherwise a value derived from fields that exist (e.g. `EVALUATED · <operation>` or `<outcome word>`), render `enforcement_policy_identity` only as a fingerprint in PROVENANCE, and add a CLI ask in 05 §12 for a `policy`/`mode` field on `EnforcementDecision`. Update 02 P2, README "The decision" and 01 §6 (c) to match.

#### Medium (22)

**F063** · **medium** · round 1 · `api-truth` · at: §5.4 MARKETPLACE CLAIM bullet 'Review update: when `updateEligible()` (1183) holds — `status` ∈ {listed, installed-differs}, trust `state` ∈ {unchanged, partial}, `registry_claim.upstream_observed_commit` present'; also §5.5 row 'Review update' and 02 §3.5 ineligible sentence

- Issue: Misdescribes the existing function. Panel.qml:1183–1194 accepts `baselineState` ∈ ["unchanged", "clean", "acknowledged"] (never `partial`) and additionally requires a cached analysis digest (`root.analysisDigestFor(plugin) !== ""`), which the panel later passes as `reviewUpdateDigest`. A `partial` plugin would be shown an eligible button the code refuses, and an unanalyzed listed/unchanged plugin would be shown eligible while the code hides the action; the ineligible-verb sentence never names the analysis requirement.
- Proposed fix: State the real conditions: status ∈ {listed, installed-differs} · trust state `unchanged` · a claimed `upstream_observed_commit` · a cached analysis for the current digest. Either add 'partial' to the code as a Phase 0/2 change (and say so) or drop it from the eligibility text; add "an analysis of the installed source (press a)" to the 'Review update needs:' sentence in 02 §3.5.

**F064** · **medium** · round 1 · `completeness` · at: §10 Confirmations, invariant 8 ("`targetStillExact` re-validates the pinned identity against the live inventory before the process starts (1219, 1241, kept)")

- Issue: Wrong anchors. Panel.qml:1219 is `root.enablePluginId = root.selectedPluginId` inside the confirm-opening function and 1241 is a closing brace. `targetStillExact` is computed in `runEnable()` at 1244/1246 and `runReviewUpdate()` at 1269/1273 (01 §2.4 and §2.7 cite these correctly).
- Proposed fix: Cite `runEnable` 1244–1246 and `runReviewUpdate` 1269–1273.

**F065** · **medium** · round 1 · `data-truth` · at: §4.1 PLUGINS footer (4-line baseline definition), §5.1 TRUST BASELINE (effect/caveat sentence + `Remove baseline needs a recorded baseline.` under the button), §10 ConfirmSheet body, §4.1 Overview footer; 02 §3.6 trust-word tooltip

- Issue: The same caveat ('does not establish that the plugin is safe') and the same definition ('a baseline is the exact source identity you recorded') are printed in five places on one path: PLUGINS footer, trust-word tooltip, under the Record button, in the sheet body, in the Overview footer. The top of every plugin detail sheet spends ~6 lines of prose before the first fact. Calm copy says a thing once, at the moment it matters; repetition reads as anxiety and trains skimming (the doc's own habituation citation).
- Proposed fix: Keep exactly two: the ConfirmSheet body (decision point) and the Overview footer (verbatim product sentence). PLUGINS footer becomes one caption line: `Baseline = the exact source identity you recorded. Matches / differs is a comparison, not a judgment.` TRUST BASELINE renders state line → identity grid → button row only; the effect sentence moves into the sheet. Ineligible verbs stay visible as dim disabled `Button`s whose `tooltipText` names the unmet condition (shown on `hasCursor`, so keyboard users get it) — the permanent sentence goes. Redraw §5.1 accordingly (saves 4 rows).

**F066** · **medium** · round 1 · `data-truth` · at: §5.2 header `REVIEW ITEMS | 2 · ALL LOW` (also "or `1 HIGH · 3 LOW`")

- Issue: `ALL LOW` is a severity roll-up in the header — a one-glance summary of quality, which P1 says headers must not carry ('counts describe evidence volume, never quality'). It reads as reassurance and is the closest thing to a grade in the whole proposal.
- Proposed fix: Header right value is the count only: `REVIEW ITEMS | 2`. If a breakdown is wanted, print counts by class in catalog-severity order with the word after the digit — `2 LOW`, `1 HIGH · 3 LOW` — never `ALL`. Rows carry the glyph + word as already specified.

**F067** · **medium** · round 1 · `data-truth` · at: §3 Panel shell hero table, `detail` column = `cli 0.2.1`; §4.1 SOURCES row `omasafe-cli 0.2.1`

- Issue: The hero pill spends the title row's prime slot on a version string. `PanelHero.detail` is used by no first-party panel (grep: only `plugins/menu/Menu.qml:540`), the version is an architecture fact the copy system otherwise bans from user-facing surfaces, it is duplicated in SOURCES, and the pill's `implicitWidth` is subtracted from the title (`Ui/PanelHero.qml:54`), forcing `ElideRight` on `1 critical alert to review` at base 9.
- Proposed fix: `detail: root.cliVerified ? "" : "unavailable"` — the pill appears only when it carries a state the user must see. Version lives in the SOURCES row alone. Update the hero table (detail column mostly `—`) and README 'result at a glance'.

**F068** · **medium** · round 1 · `data-truth` · at: §5 Plugin detail sheet — nine sections (TRUST BASELINE, WHAT CHANGED, CAPABILITIES OBSERVED, REVIEW ITEMS, FILES AND EDGES, COVERAGE, MARKETPLACE CLAIM, ENFORCEMENT, PROVENANCE)

- Issue: Nine flat sections with separators is roughly two full popup heights of scroll at base 12; only PROVENANCE is collapsed. FILES AND EDGES is Z2-trace material already owned by Flow (04 §9.4), and CAPABILITIES OBSERVED precedes REVIEW ITEMS although review items are what the persona should look at first. This is the 'one idea too many' — the sheet tries to be the trace view as well.
- Proposed fix: Fold FILES AND EDGES into COVERAGE as a collapsed sub-row (`5 file references ›`, expands to the `EdgeRow`s — the coverage state on each target is coverage information anyway). Order by decision relevance: TRUST BASELINE → WHAT CHANGED → REVIEW ITEMS → CAPABILITIES OBSERVED → COVERAGE → MARKETPLACE CLAIM → ENFORCEMENT → PROVENANCE (collapsed). Drop the dim explainer line under CAPABILITIES OBSERVED (it duplicates the header tooltip; §3.6 forbids tooltip/label repetition). Net: seven visible sections, one screen shorter.

**F069** · **medium** · round 1 · `data-truth` · at: §4.1 Overview wireframe plugin rows `… 5 rev.` / `1 rev.` vs callout "followed by `· <n> review items` / `· 1 review item`" and 02 §2.8 `1 review item`

- Issue: The wireframe uses an abbreviation (`rev.`) that exists nowhere in the copy system, because at 52 columns the 17-glyph strip plus `· 5 review items` does not fit line 2. Either the row does not fit at base 12 as designed, or the wireframe is wrong; the doc never states a width budget for strip vs count. Unresolved: real Nerd glyph advance in JetBrainsMonoNerdFont (non-Mono variant) may exceed 0.6 em, which would make the strip wider than the doc's '≈ 130 px' estimate.
- Proposed fix: Define the budget: strip `Text` has `width: Math.min(implicitWidth, Style.space(190))`, count is right-aligned `bodySmall` and never elides. Define the approved short form in Labels.js: `<n> items` (tooltip `review items`), long form `<n> review items` only in the detail header. Replace `5 rev.` in the wireframe with `5 items`. Add a Phase 1 acceptance check: measure the 17-glyph strip's `implicitWidth` at base 12 and record it in 02 §2.8.

**F070** · **medium** · round 1 · `design-quality` · at: §5.4 ENFORCEMENT callout, lines 526-527: "a copyable recovery command row (`omasafe-cli plugins analyze <id>` derived from the reason codes; when no mapping exists the row is omitted)"; wireframe line 503 `Recovery  omasafe-cli plugins analyze <id>`

- Issue: Verified against omasafe-report/src/enforcement.rs:381-404: `EnforcementDecision` has no recovery/remediation field, and enforcement_status (main.rs:4030) emits none. The panel would therefore invent a remediation policy (reason code -> command), i.e. interpret enforcement policy itself (lens f). A wrong mapping (e.g. `analyzer-identity-stale` needs a CLI upgrade, not a re-analyze; `override-expired-or-mismatched` needs a new override the panel cannot create) presents a panel guess as a CLI instruction.
- Proposed fix: Remove the derived recovery row. Render only CLI-supplied text: `reason_codes` as words, `blocking_rule_ids` as rule rows, and verbatim stderr from the failed enable/review-update. Add to 05 §12 CLI asks: a `recovery` (or `next_step`) field on `EnforcementDecision` that the panel renders verbatim once it exists.

**F071** · **medium** · round 1 · `design-quality` · at: §10 Confirmations, no-bypass invariant 3 (lines 873-874): "Confirming needs Left/Right/Tab then Enter, or a hover then click on the confirm button (kit behaviour, Ui/ConfirmDialog.qml:120–129)"; same chrome adopted in 05-implementation-roadmap.md §4 (lines 218-222)

- Issue: The kit chrome the sheet copies sets `selectedIndex` on pointer hover (`Ui/ConfirmDialog.qml:119-121`: `hoverEnabled: true; onEntered: root.selectedIndex = index`). A stationary pointer resting where the confirm button appears when the sheet opens flips `selectedIndex` to 1 on show; the auto-repeat of the held Enter that opened the sheet (which `swallowNextActivate` does not cover, because it reaches the sheet's own `Keys.onPressed`, not the catcher) or the next Enter then confirms. That is a keyboard path to confirmation without a deliberate horizontal key, contrary to invariant 3 and P5's review test. Runtime behaviour of hover-enter-on-show is not verified in this session (unresolved), but the kit code path exists.
- Proposed fix: In `ConfirmSheet`, do not let hover change `selectedIndex`; route the button MouseAreas through the same `PointerMoveGate.moved()` the rows use so only real pointer motion can pre-select, and let a click on the confirm button fire `confirmed()` directly without touching the keyboard selection. Ignore `event.isAutoRepeat` Enter in `handleKey` for the first 300 ms after open. Add acceptance: park the pointer over the confirm button's future position, press and hold Enter on Record baseline: nothing is confirmed.

**F072** · **medium** · round 1 · `feasibility` · at: §4.1 Overview attention wireframe and §14 text-scaling table ("20 … height cap space(560) scrolls")

- Issue: At base 12 the drawn Overview is ≈ 970 units (hero 34 + chips 30 + ALERTS 20 + 3 × 42 + PLUGINS 20 + 8 × 42 + toggle 34 + 4-line footer 52 + SOURCES 20 + 4 × 28 + disclaimer 26 + 7 × space(12) gaps) plus the 32-unit inset, against a 560 cap. Only hero, chips, ALERTS and ~4 plugin rows are visible on open; SOURCES, the PLUGINS baseline definition and the product disclaimer ("sits at the foot of Overview", README/02) are always below the fold at every base size. The §14 table implies 12 and 16 fit and only 20 scrolls, which is false.
- Proposed fix: Mark the fold in the §4.1 wireframe and the states matrix; decide what must be above the fold (e.g., cap PLUGINS at N rows with a `+N more` row, or place the disclaimer immediately under PLUGINS); correct the §14 table (every base scrolls Overview-attention); require ScrollBar.vertical and ensureCursorVisible on the outer Flickable in Phase 1 acceptance.

**F073** · **medium** · round 1 · `feasibility` · at: §3 Panel shell tree — `Flickable > Column { PanelHero … ButtonGroup … Loader … footer }`

- Issue: Hero, status line, view chips, finder and breadcrumb all live inside the scrolling Column. Because Overview and the detail sheet are 1.7–3× the height cap (previous issue), scrolling to plugin row 5+ removes the hero status sentence and the view chips from view; first-party panels never hit this because they fit. It also makes the Flow body height uncomputable (issue on 04 §4.3) since the scroll viewport, not the column, is what the graph must fit.
- Proposed fix: Structure as Column { PanelHero; status line; ButtonGroup; Flickable { view Loader } } with fittedContentHeight(hero + chips + viewImplicit, space(560)) and the Flickable height = contentHeight − fixed part; the ConfirmSheet then covers the whole card as today. Update §3 tree, 05 fate table row 1300–1308 and 04 §4.3 accordingly.

**F074** · **medium** · round 1 · `feasibility` · at: §2 Bar widget — "`Text { font.pixelSize: Style.font.caption }` right of the glyph, `9+` cap" inside `BarIconButton { slotSize: Style.bar.statusSlot }`

- Issue: BarIconButton sets `fixedWidth: slotSize` (Ui/BarIconButton.qml:20) and `text` and `iconComponent` are mutually exclusive (glyph visible only when iconComponent is null, lines 32/43). `Style.bar.statusSlot` is 21 × fontScale; a 13-px shield (0.6 em ≈ 7.8 px) plus gap plus a caption `9+` (≈ 12 px) is ≈ 23 px and overflows the slot at every base size, clipping or overlapping the neighbouring widget. TailscaleIcon avoids this by overlaying a badge inside the icon square, but a 42 %-of-glyph badge is ≈ 5–7 px at base 9–12, too small for digits.
- Proposed fix: Bind `slotSize` to `Style.bar.statusSlot + (count !== "" ? countText.implicitWidth + Style.space(4) : 0)` so the button widens with the count (fixedWidth follows slotSize), or render the count via a sibling `BarIndicator`/`WidgetButton` text; keep the urgent badge for critical/block only. Verify in a left/right (vertical) bar where `fixedHeight` applies instead.

**F075** · **medium** · round 1 · `ground-rules` · at: §7.2 wireframe rows 'oma.script.download-execute  – of 4' / 'oma.python.download-execute  – of 4' vs 04-trust-graph-spec.md §9.6 'sudoers-dangerous-passwo… 2 rules 0 of 4' and §12 '… 2 rules · 0 of 4'

- Issue: Two rules that fire nowhere while 4 plugins are analyzed are rendered differently: 03 prints '–' (which 02 P3 defines as 'not measured'), 04 prints '0 of 4' (measured zero). Under the fail-closed vocabulary these mean different things; the documents contradict each other on the same data condition.
- Proposed fix: State one rule in 02 §3.5: '–' only while zero plugins are analyzed; once n ≥ 1 analyzed, print '0 of n'. Then change 03 §7.2 to '0 of 4' for the two download-execute rows (and '–' only for the two note-only rows).

**F076** · **medium** · round 1 · `ground-rules` · at: §4.3 'The chips stay enabled so 2/3 still switch views; each view renders the same notice' vs 04-trust-graph-spec.md §8 first row 'view and lens chips disabled'

- Issue: Behaviour of the view ButtonGroup when the CLI is missing/incompatible is contradictory: 03 keeps the chips enabled, 04 disables them.
- Proposed fix: Pick 03's behaviour (chips enabled, every view shows the unavailable NoticeRow) and change 04 §8 to 'view chips enabled; lens chips disabled; body is the NoticeRow'.

**F077** · **medium** · round 1 · `ground-rules` · at: §8 Finder: 'class → Flow Z0 with that class current' vs 04-trust-graph-spec.md §6.1 '/' row 'class → Matrix column' and §2.3 Matrix entry

- Issue: Enter on a capability-class finder result lands in two different places in the two documents (Flow Z0 Graph lens with the class node current vs the Matrix lens column).
- Proposed fix: Choose one destination and mirror it in 03 §8, 03 §13 and 04 §6.1; 04 §13 already flags the related Z0 pinned-class ambiguity for the owner, so resolve both together.

**F078** · **medium** · round 2 · `api-truth` · at: §5.5 Actions summary success lines (line 707–713), §12.4 Reviewed update (line 1228: "exit 0 → '<id> updated to <commit7> and baseline recorded.'"), §15 Mutations row ("success lines from exit status and stdout"); 02-design-principles.md §3.3 Success lines (line 575–577)

- Issue: The review-update success line asserts an update and a recorded baseline on exit 0 alone, but `plugins review-update` exits 0 without doing either: omasafe-cli/src/main.rs:1200–1203 prints "Already at pinned commit {candidate}; nothing to update." and returns `Ok(())`. The argv in 05 §10 (`plugins review-update ID --expected-commit SHA --policy … --yes`) has no `--format json`, so there is no structured field to key on. 02 §3.3 already applies the correct rule to `enable` ("keyed on the CLI's own words, never on exit status alone … GR3") but not to review-update, so the panel would print a state change the CLI did not make.
- Proposed fix: Apply the enable rule to review-update: render `<id> updated to <commit7> and baseline recorded.` only when stdout contains the CLI's own success text (or, preferably, file a CLI ask for `review-update --format json` with a `ReviewUpdateResult { updated: bool, commit, decision }` and key on `updated === true`); on exit 0 with "nothing to update" print `Already at the claimed commit; nothing was updated.`; otherwise print the neutral `Review update finished; TRUST BASELINE and ENFORCEMENT re-fetched.` and let the re-fetched `plugins status` supply the trust word. Update 03 §5.5, §12.4, §15 and 02 §3.3 consistently.

**F079** · **medium** · round 2 · `api-truth` · at: §5.5 Actions summary (line 711–713: "the row's trust word updates optimistically and reconciles with the `plugins status` re-fetch"), §12.1 Mermaid (line 1154: "row reads matches baseline · status re-fetched"), §12.3 Mermaid (line 1208: "optimistic trust word"); 02-design-principles.md §P11 Do (line 226: "flip a row after a successful trust and reconcile with `plugins status`")

- Issue: After `plugins trust` exits 0 the panel writes the trust word `matches baseline` itself before `plugins status` has returned. `matches baseline` is defined (02 §3.2, §3.4) as the rendering of the CLI state `unchanged`; producing it from an exit code is the panel asserting a trust state the CLI has not reported (fail-closed rule: a slot without CLI data renders its loading/unavailable word, never a positive value). The 03 §4.1 wireframe already has the correct interim word, `checking…`.
- Proposed fix: Replace "optimistic" with the existing loading word: on exit 0 render the success line (`Baseline recorded for <id> at digest <12>.`, sourced from the CLI's "Trusted identity recorded" stdout, main.rs:391) and set the row's trust word to `checking…` until the `plugins status <id>` re-fetch supplies `state`. Reword 02 P11 Do to "render the success line in place, show `checking…`, and let `plugins status` supply the new trust word"; fix the two Mermaid diagrams.

**F080** · **medium** · round 2 · `api-truth` · at: §2 Bar widget: state table rows "`unavailable`, earlier result kept | filled `󰒃`, dim | last known count, dim (none when the earlier result was quiet)" (line 135) and the ASCII frame line "(S) 3  dim filled + dim count: scan failed, earlier result kept" (line 123–124); "Badge rules" paragraph (line 142–144)

- Issue: When a scan fails after a quiet result, the bar draws the same filled shield as the quiet state with no count, differing only by `dim`. At `Style.bar.iconFont` size and on light themes (`white` fg `#000000` — 02 §2.3 notes `Qt.darker` collapses there, and `dimStep(0.33)` on black is a mid-grey glyph a few pixels wide) that difference is not reliably readable, so a failed scan renders as "quiet" — a failed/stale result presented as clean. The doc's own rule for the hero ("A failed scan always titles `Scan unavailable`… `No outstanding alerts` is never printed from stale data", §3) is not mirrored in the bar, where the claim "a failed scan never returns the glyph to the quiet state (fail-closed)" rests on dimming alone.
- Proposed fix: Encode failure by shape, not by dim: for every `scanState == unavailable` draw the outline shield `󰦟` (dim) regardless of prior result, and keep the stale count beside it when one exists (`(s) 3` dim); the tooltip stays `OmaSafe: last scan failed; showing results from <relative>` / `results unavailable`. Then the filled shield means exactly one thing — a scan result from the last successful run — and quiet is never confusable with failed. Update the table row, the ASCII frame and the OmaSafeShield `filled` binding in §2 and 05 §9.

**F081** · **medium** · round 2 · `completeness` · at: §4.1 Attention state wireframe and callout "Order: outstanding alert desc, analyzed first, then id" / "every alerted plugin is above the fold whenever there are alerts"

- Issue: The drawn PLUGINS order (ilyazar.btop, io.github.tuthan.omasafe, lgse.sandman, io.github.tuthan.dropdown-terminal, crmne.hyprmoncfg, ianswope.snapshots, io.github.hvo.omarchy-unraid, io.github.tuthan.omarchy-lunar-calendar) does not follow the stated key against scan.json: `io.github.hvo.omarchy-unraid` carries a `provenance-conflict` alert and must sort third (it is drawn below the fold, contradicting the above-the-fold guarantee), and `io.github.tuthan.dropdown-terminal` sorts before `lgse.sandman` by id.
- Proposed fix: Redraw rows as btop, omasafe, omarchy-unraid (`– not analyzed`), dropdown-terminal, sandman, crmne.hyprmoncfg, ianswope.snapshots, omarchy-lunar-calendar, or state that unanalyzed alerted plugins sort after analyzed ones and drop the above-the-fold claim.

**F082** · **medium** · round 2 · `ground-rules` · at: §4.1 Attention state — PLUGINS wireframe vs callout "Order: outstanding alert desc, analyzed first, then id" and decision (1) "every alerted plugin is above the fold whenever there are alerts"

- Issue: The wireframe contradicts its own ordering rule and the fold claim. scan.json has three alerts (ilyazar.btop, io.github.hvo.omarchy-unraid, io.github.tuthan.omasafe), yet the drawn PLUGINS order is btop, omasafe, sandman, dropdown-terminal, hyprmoncfg, snapshots, [fold], unraid, lunar-calendar: unraid (alerted) sits below the fold, and sandman is drawn before io.github.tuthan.dropdown-terminal although the tie-break is id ascending. 04 §9.1/§9.2/§9.5 repeat the same order (omasafe before btop, unraid at row 5) against 04 §4.1 step 2 "outstanding desc, analyzed first, id asc".
- Proposed fix: Redraw the PLUGINS column in 03 §4.1 and the Z0/Matrix frames in 04 §9.1, §9.2, §9.5 as: ilyazar.btop, io.github.tuthan.omasafe, io.github.hvo.omarchy-unraid (alerted; unraid hollow), then io.github.tuthan.dropdown-terminal, lgse.sandman (analyzed, id asc), then crmne.hyprmoncfg, ianswope.snapshots, io.github.tuthan.omarchy-lunar-calendar — or change the stated key to what is drawn and drop the above-the-fold claim.

**F083** · **medium** · round 2 · `ground-rules` · at: §5.2 "`[Open rule]` → Rules view with that rule current and its sheet open (§7.1); `h` returns here" and §12.2 "U->>R: h (returns to the detail sheet the rule was opened from)"

- Issue: §13 defines `h` as: horizontal move in horizontal sections, and depth-pop only "in a vertical section at depth ≥ 1" of the current view's own depth stack; depth stacks are per view and "1/3 switch views (Flow keeps its depth and cursor)". The Rules view's `visibleSections` are `hero → views → rules → baseline` at depth 0 (the rule sheet is an inline expansion, not a depth), so `h` there does nothing by the table. The cross-view return path Open rule → Rules → back to the detail sheet (and 04 §6.1's pinned rule → rule sheet → back to Flow) is therefore unspecified and contradicts the per-view stack model.
- Proposed fix: Add to 03 §13 a cross-view return rule (e.g. Open rule pushes a `{view, depth, cursor}` return frame; `h`/`-`/back in the Rules view with a return frame pops to it; the Breadcrumb shows `󰅁 lgse.sandman` in that case) and reference it from §5.2, §12.2 and 04 §6.1/§7.

**F084** · **medium** · round 2 · `ground-rules` · at: §7.2 Baseline V3 coverage table wireframe vs 04 §9.6 Baseline V3 coverage table wireframe

- Issue: The same Rules-view table is drawn with two different row anatomies. 03 §7.2: two-line rows (`≈ curl-pipe-shell` / `3 OmaSafe rules · Partially covered`, `≈ installer` / `process-execution (class) · Partially covered`, not-covered rows print `Not covered by OmaSafe` as line 2). 04 §9.6: one-line rows with a right-aligned slot (`≈ curl-pipe-shell 3 rules`, `≈ installer class PX`, `note only`, `not covered`). 05 Phase 2b builds `RelationRow` once from these; neither document declares itself binding.
- Proposed fix: Pick one anatomy (03 §7.2's two-line row matches the 02 §2.8 density rule) and redraw 04 §9.6 to match, or state in 04 §9.6 that it is a schematic of the 03 §7.2 row and remove the divergent slot words (`note only`, `class PX`, `3 rules`) from the drawing.

#### Low (36)

**F085** · **low** · round 1 · `api-truth` · at: §5.2 CAPABILITIES OBSERVED wireframe, expanded process-execution site rows ("LidService.qml:158 · Process · parser-backed")

- Issue: LidService.qml:158 is not a process-execution occurrence in analyze-lgse.sandman.json; the real first sites are LidService.qml:142, :156, :169, :182 (line 158 appears only in the `sink-reference-rejected` limitation codes). Service.qml:250 and 142 are correct.
- Proposed fix: Use 142, 156, 169 (or 142, 156, Service.qml:250) for the three visible rows.

**F086** · **low** · round 1 · `api-truth` · at: §8 Finder wireframe for query 'proc' (PLUGINS 1 `crmne.hyprmoncfg`; RULES 6; row "PX Shell download-and-execute · oma.script.download-execute") and §7.1 wireframe row "DX QML detached execution"

- Issue: `crmne.hyprmoncfg` does not contain 'proc' so it cannot be a substring match; RULES 6 matches neither ids+titles (3) nor ids+titles+capability (11); the title 'Shell download-and-execute' does not exist — rules-list.json title is 'Script downloads and executes remote content'; oma.qml.detached-execution's title is 'QML detached process execution', not 'QML detached execution'.
- Proposed fix: Use real titles verbatim from rules-list.json; rebuild the finder example from an actual query (e.g. 'proc' → PLUGINS 0, CAPABILITIES 2, RULES 3 or 11 depending on the stated index, BASELINE V3 1).

**F087** · **low** · round 1 · `completeness` · at: §4.1 callout "Backups: kit `Toggle { label: ...; checked: root.showBackups; hasCursor }` (`Ui/Toggle.qml:18–25`)" together with 02 P8 review test ("a plugin row is ≤ `Style.space(44)` tall") and 05 §5 ("`Toggle { label; description; checked; hasCursor }` for the backups row")

- Issue: Properties exist, but the kit `Toggle` also hard-codes `implicitHeight: Math.max(54, content.implicitHeight + Style.spacing.huge)` (Toggle.qml:45, a 54 px floor that does not scale down), `implicitWidth: Style.space(240)` (46), `titleSize: Style.font.subtitle` bold, `activeFocusOnTab: true` (40) and a 100 ms `ColorAnimation` (55). None of these facts appear in the docs, and the row-height and motion-set claims ("{60, 120, 140, 900} ms") are stated as if the Toggle row conforms.
- Proposed fix: Note the 54 px floor, `space(240)` implicit width and 100 ms fill on the kit Toggle; either accept them explicitly for this one row (bind `width: parent.width`) or use a `CursorSurface` row with a `ToggleSwitch { interactive: false }` (ToggleSwitch.qml:34) if the ≤ space(44) row rule must hold.

**F088** · **low** · round 1 · `data-truth` · at: §5.1 header `TRUST BASELINE | LOCAL`, §5.4 header `ENFORCEMENT | POLICY` (also README 'three authority sections')

- Issue: The header right slot carries a count or data everywhere else (`ALERTS | 3`, `COVERAGE | 13 LIMITS`, `CATALOG 65b6385 · 15 MIN`). `LOCAL` and `POLICY` are the only two slot values that are neither data nor a count; `POLICY` is not an authority and `LOCAL` does not say whose. The one slot that earns its place is the catalog one, because it names an artefact and an age.
- Proposed fix: Put data in the slot or leave it empty: `TRUST BASELINE` with no right value (the section body's first line already says who recorded it); `ENFORCEMENT | <policy of the recorded decision>` → `ADVISORY` / `HARDENED` / `NO DECISION` from `decision.enforcement_policy_identity` or null. Keep `MARKETPLACE CLAIM | CATALOG <commit7> · <age>` as is.

**F089** · **low** · round 1 · `data-truth` · at: §5.1 wireframe: hero title `lgse.sandman` and breadcrumb `All plugins › lgse.sandman` two lines apart; §8 Breadcrumb

- Issue: At depth 1 the plugin id is printed twice within three lines (hero title, breadcrumb tail). The breadcrumb's only job at depth 1 is the way back, and the hero already names where you are.
- Proposed fix: At depth 1 render `‹ All plugins` only (back glyph + parent label); render the full `›` path only at depth ≥ 2 (Flow Z2). State this in §8 and redraw §5.1.

**F090** · **low** · round 1 · `data-truth` · at: §4.3 loading frame and §11 states matrix, PLUGINS row: "`LOADING PLUGINS…` value; last-good rows stay"

- Issue: On the first-ever open there are no last-good rows, so the frame is a `PLUGINS | LOADING PLUGINS…` header over an empty body — the blank slot P3 forbids. The NoticeRow catalogue (§9) defines `Loading plugins…` but neither §4.3 nor the matrix says when it is used.
- Proposed fix: Add to §4.3 and the matrix cell: `vm.plugins.length === 0` → body is `NoticeRow { reason: "loading"; text: "Loading plugins…" }` and the header value is omitted (one loading indicator, not two).

**F091** · **low** · round 1 · `design-quality` · at: §10 review-update ConfirmSheet wireframe (lines 841-845) and variant table row `review-update` (line 798): identity rows `Tree` / `Digest` next to `Expected commit`

- Issue: For a reviewed update the pinned target identity is `--expected-commit`; the Tree and Digest shown are those of the CURRENTLY installed source, not of the commit being installed. Labelling them bare `Tree` / `Digest` beside `Expected commit` lets the reader take them as the identity of what will be installed. Today's overlay (Panel.qml:2470) labels the second value `Current digest`, which the redesign drops.
- Proposed fix: Label the rows `Current tree` / `Current digest` (or group them under a `Installed now` sub-heading in the InfoGrid) and keep `Expected commit … — claimed by catalog snapshot <commit7>` as the only target identity. Mirror in 02 §3.7 variants.

**F092** · **low** · round 1 · `design-quality` · at: §7.2 Baseline V3 header (lines 651-652) `automated-security-baseline v3 · map 2 · verified at 964dc08`; 02-design-principles.md §3.5 (line 551); 04-trust-graph-spec.md §9.6 (line 652) and §12 (line 929)

- Issue: `verified at 964dc08` uses the banned bare word "verified" (02 §3.1) on the same view family that suppresses "verified" for stale marketplace claims. `verified_at_commit` (omasafe-analyzer/src/equivalence.rs:22) is the marketplace-repository commit at which OmaSafe's map was checked; a reader can take "verified" as a marketplace verification of something local.
- Proposed fix: Header: `automated-security-baseline v3 · map 2 · checked against marketplace commit 964dc08` (tooltip: `verified_at_utc <ISO>`). Apply in 02 §3.5, 03 §7.2, 04 §9.6 and the 04 §12 / 05 Phase 2 acceptance strings.

**F093** · **low** · round 1 · `design-quality` · at: §11 States matrix, row "Detail: CAPABILITIES / REVIEW ITEMS", stale cell (line 899): "analysis older than current policy identity → `Results from an earlier analyzer; press a to re-analyze`"

- Issue: The panel itself compares a cached analysis' `policy_identity` against the current one and shows the old results with a stale notice. 01 §8.3 (line 383) says a cache hit whose policy_identity differs "must be discarded", and the CLI already emits the `analyzer-policy-update` alert for this event. Rendering discarded-grade results as review items contradicts GR3 (stale renders unavailable) and duplicates policy evaluation in the panel (lens f).
- Proposed fix: On policy_identity mismatch treat the slice as `not analyzed`: `Analyzer policy changed since this analysis (alert analyzer-policy-update). Press a to re-analyze.` with no review-item or capability rows. Keep only the alert row as the source of the staleness fact.

**F094** · **low** · round 1 · `design-quality` · at: §5.2 header `REVIEW ITEMS | 2 · ALL LOW` (lines 388, 416); 04-trust-graph-spec.md §9.5 Matrix inspector (line 636) `16 occurrences in 2 files · 0 review items`

- Issue: `ALL LOW` is an aggregate of catalog default severities placed in the section header without the `catalog` qualifier the pills carry; read alone it summarises the plugin ("all low"), which P1/P4 forbid. `0 review items` in the Matrix inspector prints a zero for a plugin with 8 `unsupported` and 4 `partial` files, while 02 §3.3 requires the reasoned form `No review items in analyzed files. <n> files were not analyzed.`
- Proposed fix: Header value as counts by word: `2 · LOW 2` (or `1 HIGH · 3 LOW`) with the header tooltip `Catalog severity of matched rules; not a measure of this plugin.` Matrix inspector: `no review items in analyzed files · 8 not analyzable` using `payload_inventory.coverage_states`.

**F095** · **low** · round 1 · `design-quality` · at: §4.1 PLUGINS rows, line 2 (wireframe lines 165-171; callout lines 210-212): `CapabilityStrip` + `<n> review items`, no coverage indicator

- Issue: The plugin row shows an analysis result (review-item count) without any coverage signal; `lgse.sandman` (13 limitations) and `io.github.tuthan.omasafe` (2) read identically to `io.github.tuthan.dropdown-terminal` (0). GR4 requires coverage_limitations to be visible wherever analysis results are shown; the Flow node already appends `· 13 limits`, so Overview is the one surface where limits are one level down (lens d).
- Proposed fix: Append `· <n> limits` (dim, `bodySmall`) after the review-item count on line 2 when `coverage_limitations.length > 0`, and ` · text match only` when `parser == null`; at base 9 abbreviate to `· 13 lim`. Add to the 05 Phase 2 acceptance list.

**F096** · **low** · round 1 · `feasibility` · at: §10 wiring invariants 1–3 and 05 §4 ConfirmSheet wiring (`swallowNextActivate`; acceptance (3) "holding Enter … opens the sheet and does not confirm", (4) "Enter immediately after open cancels")

- Issue: PanelKeyCatcher emits `returnRequested()` then `activateRequested()` for one Return press (Ui/PanelKeyCatcher.qml:71–74). If `openSheet()` runs from `activateRequested` there is no later activate from the same press for `swallowNextActivate` to swallow; the flag is only meaningful if activation is wired to `returnRequested`. Independently, key auto-repeat is not addressed: with the sheet open and `blocked` true, the next auto-repeated Return is delivered to the sheet and `handleKey` fires the selected button — Cancel — so a held Enter opens and immediately dismisses the sheet (safe, but a flicker that breaks P5's review test wording).
- Proposed fix: In ConfirmSheet.Keys.onPressed: `if (event.isAutoRepeat && (Return|Enter|Space)) { event.accepted = true; return }`. State that activation is wired to `activateRequested` only and either drop `swallowNextActivate` or define it as "ignore activateRequested while pendingAction was set in the same event-loop turn".

**F097** · **low** · round 1 · `feasibility` · at: §13 cursor sections table — ConfirmSheet `policy (H, optional) → buttons (H)`; §10 "keeps the kit ConfirmDialog contract"

- Issue: The kit `handleKey` (Ui/ConfirmDialog.qml:23–38) handles only Esc, Left/Right/Tab/Backtab and Return/Enter. With the catcher blocked, nothing maps Up/Down/j/k inside the sheet, so the cursor cannot move between the policy ButtonGroup and the button row; and Left/Right would toggle Cancel/confirm and move the policy chip at the same time.
- Proposed fix: Specify the extended handleKey: Up/Down/j/k switch the sheet section (`policy` ↔ `buttons`); Left/Right/h/l move within the focused section only; Enter on `policy` selects the chip and moves to `buttons` (never confirms); Esc cancels; everything else accepted and ignored.

**F098** · **low** · round 1 · `feasibility` · at: §4.1 backups `Toggle { … hasCursor }` and §8 FinderField (`keyCatcher.blocked` follows `finder.activeFocus`)

- Issue: Kit `Toggle` hard-codes `activeFocusOnTab: true` (Ui/Toggle.qml:39) and has no `focusable` property; kit `TextField` is a QQC TextField that does not accept Tab. While the finder has focus, Tab bubbles to the blocked catcher (not accepted) and Qt's focus chain then moves activeFocus to the Toggle (or any activeFocusOnTab item), which drops `finder.activeFocus`, un-blocks the catcher and paints a focus ring the design forbids ("no Button is focusable").
- Proposed fix: FinderField.Keys.onPressed accepts Tab/Backtab (no-op or result-cursor move); set `activeFocusOnTab: false` on the Toggle instance (it is a plain Item property and can be overridden); add `grep -rn activeFocusOnTab` to the Phase 2 acceptance.

**F099** · **low** · round 1 · `feasibility` · at: §10 ConfirmSheet template and the review-update wireframe (≈ 24 lines: title, 12 grid lines, policy + definition, 6-line body, buttons)

- Issue: The card is `anchors.centerIn` the scrim with no maximum height (kit ConfirmDialog only wraps one message). The review-update card is ≈ 440 units at base 12 (≈ 733 px at base 20). The scrim is the catcher's area, i.e. the panel viewport: 528 px at base 12 (fine) but ≈ 700 px on a 768-px display at base 20, where the Cancel/Update row is clipped off-screen — the one row that must never be unreachable.
- Proposed fix: Card `height: Math.min(implicitHeight, parent.height − Style.space(32))`, title + InfoGrid + body inside a `Flickable`, button row anchored to the card bottom; add the 768-px/base-20 case to the 05 §11.3 matrix. Eliding hashes is not an option under GR6.

**F100** · **low** · round 1 · `feasibility` · at: §10 invariant 4 — `Flickable.interactive: false` while `navigationLocked`

- Issue: `navigationLocked` is `operationRunning || pendingAction !== ""`; enable and review-update run up to 60 s, so the whole panel (which always scrolls, see the Overview height issue) becomes unscrollable for the duration of the CLI call, not just while the sheet is open.
- Proposed fix: Gate `Flickable.interactive` on `sheet.opened` (pendingAction) only; keep action Buttons disabled on the full `navigationLocked`.

**F101** · **low** · round 1 · `ground-rules` · at: §13 table 'Plugin detail sheet' visibleSections: 'hero → views (H) → trust-actions (H) → changed → classes → review → edges → coverage → claim-actions (H) → enforcement → provenance'

- Issue: No section covers the TRUST BASELINE identity rows (§5.1 InfoGrid with three copy PanelActionButtons and the optional 'Recorded baseline' grid), so those targets are unreachable by keyboard, contradicting §14 'every target is reachable with j/k/h/l and Enter'.
- Proposed fix: Insert a 'trust' section (vertical rows; l moves the cursor onto the copy PanelActionButton, as 01 §4 describes for row actions) before 'trust-actions'.

**F102** · **low** · round 1 · `ground-rules` · at: §6 'Entry: … Enter on a plugin node → detail sheet' and §5 'Enter on a pinned plugin node in Flow' vs 04-trust-graph-spec.md §6.1 Enter row (Z0: pinned plugin → Z1; Z1: pinned plugin → plugin detail sheet) and README mermaid 'F -->|Enter on plugin node| Z1'

- Issue: 03 sends Enter on a pinned plugin node straight to the detail sheet from any zoom level; 04 (the binding spec) makes Z0 Enter go to Z1 and only Z1 Enter open the detail sheet.
- Proposed fix: Change 03 §5 and §6 to 'Enter on a pinned plugin node at Z1 (Z0 Enter zooms to Z1 first)'.

**F103** · **low** · round 1 · `ground-rules` · at: §12.2 sequence 'U->>R: 2 / R->>F: Z1 for io.github.tuthan.omasafe'

- Issue: Per §13, '2' from a detail sheet opens Flow at Z1 for that plugin, but from the Rules view '2' opens Flow at its own retained depth/Z0; the flow presses 2 while in the Rules view yet lands at Z1 for a plugin.
- Proposed fix: Either route the sequence back through the detail sheet ('h' to the detail sheet, then '2'), or define in §13 that '2' from a rule sheet opens Z1 for the plugin whose LOCAL HITS row holds the cursor.

**F104** · **low** · round 2 · `api-truth` · at: §4.4 SOURCES expanded (line 409–410: "Enforcement overrides · 1 active", "<plugin id> · expires <date>") and §11 States matrix, SOURCES overrides row (line 1139: "expired bindings labelled `expired <date>`")

- Issue: The `active`/`expired` words and the `1 active` count are shown without naming their source field. The CLI computes `status` at list time by comparing `expires_at` to now (omasafe-cli/src/main.rs:4244–4249) and the docs (01 §8.3) list `overrides[] {status, binding}`, but 03 renders from `OverrideBinding` fields only ("from `OverrideBinding` (`enforcement.rs:363–375`)"), which contain `expires_at` and no status. An implementer following 03 alone would compute expiry from the clock — the panel evaluating override validity itself, which §4.4's own footer sentence ("Override validity is evaluated by the CLI") rules out.
- Proposed fix: State explicitly in §4.4 and §11 that `active` / `expired <expires_at>` and the header count come from `overrides[].status` via `overrideStatus` (Panel.qml:338; unknown → `unsupported`), and that `expires_at` is displayed verbatim and never compared to the local clock. Add a fixture check: a binding with `status: "active"` and a past `expires_at` renders `active`.

**F105** · **low** · round 2 · `api-truth` · at: §7.1 Rule sheet LOCAL HITS rows (line 774–780: "io.github.tuthan.omasafe 18 occurrences", "lgse.sandman 16 occurrences") and 04-trust-graph-spec.md §9.5 Matrix lens rows (line 729–736)

- Issue: Both surfaces present per-plugin analysis results (occurrence counts) without the plugin's `coverage_limitations` count or lexical-only marker, whereas the Overview plugin row (03 §4.1) and the Flow node (04 §5 suffix `· N limits`) carry them. P4 requires coverage to be visible "on every view that shows analysis results"; in the rule sheet `lgse.sandman 16 occurrences` (13 limits) and `io.github.tuthan.dropdown-terminal 5 occurrences` (0 limits) read identically, and in the Matrix a row of digits carries no limitation signal except for the cursor cell's inspector line.
- Proposed fix: Append the same dim `· <n> limits` (and ` · text match only` when `parser == null`) to LOCAL HITS rows and to Matrix row labels' trailing slot (or as a per-row suffix column), reusing the `PluginRow` line-2 rule; add both to the P4 review test.

**F106** · **low** · round 2 · `api-truth` · at: §13 Keyboard map, rows `1 2 3` (line 1247) and `a / A` (line 1249) in the "No sheet, finder unfocused" column; §3 Panel shell ("Disabled while `navigationLocked`" applies to the `ButtonGroup` only)

- Issue: View switching by digit is not gated on `navigationLocked` in the keyboard table; only the mouse `ButtonGroup` is disabled. Today `setActive()` is blocked while `navigationLocked` (01 §2.5) and 05 §1.1 lists "tab switch locked during an operation" among confirmation semantics. With the redesign the sheet is open for the whole `operationRunning` window so `blocked` usually covers it, but `navigationLocked` also becomes true in the moment between `confirmed()` and the sheet's `busy` state and whenever a future action runs without a sheet; the doc should not rely on the sheet being open to lock view changes.
- Proposed fix: In §13 make the `1 2 3` (and `2` → Z1 shortcut) row explicit: "no-op while `navigationLocked`", mirroring `r`; state the same for `/` and `-`. In §3 write `setView()` as `if (root.navigationLocked) return` so keyboard and mouse share one gate; add to the Phase 1 acceptance list in 05 §4: "with `operationRunning` true and the sheet closed (fixture: 40 s `plugins trust`), digits do not change the view".

**F107** · **low** · round 2 · `completeness` · at: §4.1 and §4.3 wireframes, `CapabilityStrip` lines `PX··TM·············` (omasafe) and `PX·FSTMWM············` (sandman, dropdown-terminal) vs callout "one `Text` of 17 glyphs in fixed catalog order — class glyph when observed, `·` when analyzed and not observed"

- Issue: The drawn strips pack observed glyphs together instead of placing them at their catalog positions (02 §2.7: FS = 3, TM = 8, WM = 10), so TM sits at position 4 and WM at 5; the same fixture is drawn correctly in 02 §2.8 (`PX · · · · · · TM · ...`). §1 acknowledges the packing, but it contradicts the fixed-position semantics that the strip's "same position = same class" claim rests on.
- Proposed fix: Draw the strips at catalog positions (`PX······TM·········`, `PX·FS····TM·WM·······`, with DX at 2 for btop) or drop the fixed-position claim from the wireframe callout.

**F108** · **low** · round 2 · `completeness` · at: §7.1 Rule catalog wireframe, row `o  QML loads content through a computed ref.` for `oma.qml.dynamic-reference`

- Issue: The rule row's leading glyph is drawn as `o` (= hollow `󰝦`, which 02 §2.4 reserves for a not-analyzed/unavailable Flow node). Per the callout ("line 1 = class glyph + title") the glyph must be the rule's capability class: `oma.qml.dynamic-reference` has `capability: filesystem-access` in rules-list.json, i.e. `FS`.
- Proposed fix: Replace `o` with `FS` on that row.

**F109** · **low** · round 2 · `data-truth` · at: §2 Bar widget QML sketch and table: `root.hasScanResult`, `root.cliFailed`, `root.checking`, `root.urgentBadge`, `root.barForeground`, `root.dim`; §3 Panel shell hero: `iconSpinning: root.checking`, `enabled: … !root.checking`

- Issue: None of these exist on the current roots. BarWidget.qml exposes `scanState`, `statusLevel`, `outstandingCount`, `highestSeverity`, `cliVerified`, `cliVersion`, `cliError` (BW:11–31, 60, 117); Ui/BarWidget.qml adds only `bar`, `moduleName`, `settings`, `vertical`, `barSize`. `barForeground` exists on Ui/Panel.qml:22 (so `root.barForeground` is valid in Panel.qml) but not on Ui/BarWidget.qml. Panel.qml has `statusLevel === "checking"` (155, 196), not `checking`. The sketch reads as if binding to existing state.
- Proposed fix: Declare them explicitly as new root properties in 03 §2/§3 and 05 Phase 1, e.g. `readonly property color barForeground: bar ? bar.barForeground : Color.foreground` (Bar.qml:69 — the transparent-bar-aware colour the kit's WidgetButton uses, distinct from `bar.foreground` at Bar.qml:68), `readonly property bool checking: scanState === "checking"`, `readonly property bool hasScanResult: …`, `readonly property color dim: dimStep(0.33)`; or map them to the existing names (`statusLevel`, `scanState`).

**F110** · **low** · round 2 · `data-truth` · at: §4.1 Backups bullet: "a bold `Style.font.subtitle` title (35), `activeFocusOnTab: true` (39 …)" — repeated in 05 §5 and 05 Sources ("`Ui/Toggle.qml` (35–55, rejected)")

- Issue: In Ui/Toggle.qml `titleSize: Style.font.subtitle` is line 34 (the bold is applied at 77) and `activeFocusOnTab: true` is line 40. The other Toggle anchors (45 `Math.max(54, …)`, 46 `Style.space(240)`, 55 `duration: 100`) are correct.
- Proposed fix: Cite 34 (titleSize) and 40 (activeFocusOnTab); keep 45/46/55.

**F111** · **low** · round 2 · `data-truth` · at: §3 Panel shell tree: "`Flickable` … `ScrollBar.vertical { policy: ScrollBar.AsNeeded }`" and §4.1 decision (2) "`ScrollBar.vertical { policy: ScrollBar.AsNeeded }` on the Flickable" (05 §4 acceptance repeats it)

- Issue: `ScrollBar.vertical` is an attached property; `ScrollBar.vertical { … }` is not valid QML. The first-party form is `ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }` (network/Panel.qml:1487, bluetooth/Panel.qml:815) or `ScrollBar.vertical.policy: …` (audio/Panel.qml:693).
- Proposed fix: Write `ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }` (requires `import QtQuick.Controls`, already present in Panel.qml:2).

**F112** · **low** · round 2 · `data-truth` · at: §5.1 Actions bullet: "because the kit tooltip shows only on `mouseArea.containsMouse` (`Ui/Button.qml:131`), `ActionRow` also prints the same condition … so keyboard users get it" (implies pointer users get the tooltip on a `Button { enabled: false }`)

- Issue: Unresolved. `Button.enabled: false` (an `Item.enabled`) propagates to the internal `MouseArea`; whether Qt 6.11 still delivers hover to a `MouseArea` under a disabled ancestor (and so whether `containsMouse`/the `ToolTip` ever fires) could not be confirmed from the kit source — no first-party file puts a tooltip on a disabled `Button`. If hover is not delivered, the ineligible-verb tooltip never shows for pointer users either and the caption line under the row is the only carrier of the unmet condition.
- Proposed fix: Verify on the first Phase 2 build (hover a disabled `Button { tooltipText }`); if the tooltip does not appear, make the dim condition `Text` under `ActionRow` unconditional for ineligible verbs (not only while `hasCursor`) and drop the pointer-tooltip claim from 03 §5.1 and 02 §3.6.

**F113** · **low** · round 2 · `ground-rules` · at: §2 Bar widget QML: `countText … font.pixelSize: Style.font.caption` and table column "Count (sibling `Text`) … `caption`"

- Issue: 02 P7 states "Anything read as data — … counts (including Flow node counts) … is `bodySmall` or larger at every base size" and reserves `caption` for headers, hero meta, hints, relative times and the footer. The bar outstanding count is a count rendered at `caption`.
- Proposed fix: Either exempt the bar explicitly in 02 P7/§2.1 (it lives under `Style.bar.*` tokens, not the panel type roles) or bind the count to `Style.font.bodySmall` / a `Style.bar.*` size token in 03 §2 and 05 §9.

**F114** · **low** · round 2 · `ground-rules` · at: §14 Accessibility — "Screen readers: … Recorded as an open limitation in 05."

- Issue: 05 §13 Open questions (items 1–8) and §12 contain no entry about the missing Quickshell accessibility bridge / `Accessible` attached properties; the cross-reference points at nothing.
- Proposed fix: Add an open item to 05 §13 ("No accessibility bridge is verifiable in Quickshell panels; all content stays plain `Text.PlainText` so a future bridge reads the same words") or delete the sentence from 03 §14.

**F115** · **low** · round 2 · `ground-rules` · at: §10 Confirmations — "departs from it deliberately in four ways (feasibility §8)"

- Issue: "feasibility §8" refers to the scratchpad research report (qml-feasibility.md), not to any in-repo document; the committed equivalent is 01 §9.6 "Why the kit ConfirmDialog cannot be used as-is". Unresolvable for a repo reader.
- Proposed fix: Replace "(feasibility §8)" with "(01 §9.6)".

**F116** · **low** · round 2 · `ground-rules` · at: §7.1 Rule catalog wireframe, row "|  o  QML loads content through a computed ref.  v |" (oma.qml.dynamic-reference)

- Issue: §1 defines `o` as the outline circle `󰝦` (not analyzed / unavailable) and 02 §2.4 says `󰝦` "means exactly one thing: a hollow, unanalyzed or unavailable node in Flow". The row's leading glyph is the rule's class glyph; `oma.qml.dynamic-reference` has capability `filesystem-access`, so the cell should read `FS`.
- Proposed fix: Replace `o` with `FS` on that row.

**F117** · **low** · round 2 · `ground-rules` · at: §5.4 MARKETPLACE CLAIM wireframe (lgse.sandman)

- Issue: The callout specifies rows for `upstream_moved` (`Upstream still at the validated commit` for the fixture's `false`) and the `Catalog says:` / `installed_matches_listing` lines, but the drawn frame shows only the status line, `Catalog says: verified`, `Installed commit matches the listing`, the disclaimer and the button — the `upstream_moved` row is missing from the drawing.
- Proposed fix: Add the line `Upstream still at the validated commit` between `Installed commit matches the listing` and the disclaimer, or state that the frame is abbreviated.

**F118** · **low** · round 2 · `ground-rules` · at: §1 Conventions — "`n` = installed without git `󰏗`" vs 02 §2.8 density wireframe using `[p ]` for the same glyph

- Issue: Two documents use different ASCII stand-ins (`n` in 03 §4.1/§4.3, `p` in 02 §2.8) for the same classification glyph `󰏗`; 02 §2.7 also lists the ASCII fallback for it as `p`.
- Proposed fix: Use `p` in 03 (matches the Glyphs.js ASCII fallback) and update 03 §1.

**F119** · **low** · round 2 · `ground-rules` · at: §3 Panel shell hero table and §11 States matrix (Hero row)

- Issue: 01 §2.2 records a live hero state `hostWidget` null → "Scan status unavailable / Waiting for the OmaSafe widget." The new hero table (§3), the copy system (02 §3.3 hero titles) and the states matrix (§11) do not cover it, so the panel has no specified title/meta/glyph when the bar widget reference is absent.
- Proposed fix: Add a `hostWidget == null` row to 03 §3 and §11 (outline shield, `iconOpacity 0.5`, title `Scan status unavailable`, meta `WAITING FOR THE OMASAFE WIDGET`) and the title to 02 §3.3.

**F120** · **low** · round 2 · `ground-rules` · at: §5.1 TRUST BASELINE actions — "`state == untrusted` → `[Record baseline]`; `changed` → `[Replace baseline] [Remove baseline]`" and wireframe showing `[Record baseline] [Remove baseline]` with Remove dim

- Issue: README §The decision (from C) and 03 §5.1 say "ineligible verbs stay visible, dim, with the unmet condition named", and 02 §3.5 provides the condition string "Replace baseline appears only when the source differs from the baseline". But Replace is omitted entirely outside `changed` (only Record and Remove drawn for `untrusted`), so the rule is applied to Remove and not to Replace, and the 02 condition string is never displayable.
- Proposed fix: State the exception explicitly in 03 §5.1 ("Record and Replace are the same verb on the same argv; only the one matching the state is shown; Remove is always shown") and delete the unused "Replace baseline appears only when…" string from 02 §3.5, or draw Replace dim as well.

### 4.5 04-trust-graph-spec.md

28 issues (round 1: 23, round 2: 5).

#### High (6)

**F121** · **high** · round 1 · `api-truth` · at: §3.3 worked example lgse.sandman row 'marketplace' ("Catalog says: listed, verified · snapshot 65b6385, 16 min old") and §9.1 Z0 wireframe inspector line "Catalog says: conflict · snapshot 65b6385, 16 min"; also §5 encodings row 'Catalog claim'

- Issue: `listed` and `conflict` are not catalog claims: they are the CLI's correlation result (`omasafe-marketplace/src/lib.rs:376–407`, `status` field), and for `conflict` the sample has `registry_claim: null`, so the catalog states nothing at all. Prefixing a CLI-derived status with "Catalog says:" misattributes OmaSafe's own correlation to the catalog snapshot and contradicts 02 §3.4, which maps `status` to "Catalog entry conflicts with the installed repository" and reserves "Catalog says:" for `registry_claim.verification_status` (null → "not stated").
- Proposed fix: Inspector line for io.github.tuthan.omasafe: "Catalog entry conflicts with the installed repository · Catalog says: not stated · snapshot 65b6385, 15 min old"; for lgse.sandman: "Listed in catalog snapshot · Catalog says: verified · …". Update §5 encodings row to say the `Catalog says:` fragment carries only `verification_status`, and the status label comes from `Labels.marketplaceStatus`.

**F122** · **high** · round 1 · `data-truth` · at: §4.1 steps 5–6 (`gutter = Style.space(24)`, `mx = (x1 + x2) / 2`) and §4.3 sizing table

- Issue: Edges only have the 24-unit gutter to travel in: `x1 = col[i].x + width`, `x2 = col[j].x`, so a plugin→class edge with a vertical delta of up to 11 × 28 = 308 units is a cubic whose control points sit 12 units in — a near-vertical S packed into a 24-px lane. With 13 real edges (136 worst case) sharing that lane the Z0 graph is a vertical hairball, not the readable ribbons the §9.1 ASCII (`=\`, `-\=`, `=/-`) implies; the ASCII lane is ~4 columns ≈ 32 units wide and still only shows 4 edges. This is the single most important legibility decision in the graph and the spec never sizes the lane.
- Proposed fix: Give the open pair a real edge lane and shrink the rail gutters: `pairGutter = Style.space(72)` between the two open columns, `railGutter = Style.space(12)` between a rail and its neighbour. `openW = (388 − 2·28 − 72 − 2·12) / 2 = 118` at base 12 (≈ 11 label chars, within the 10–12 budget §4.3 already accepts). Control points at thirds, not the midpoint: `C x1+lane/3 y1, x2−lane/3 y2`, so parallel edges fan visibly. Edges into rails keep the 12-unit gutter but terminate at the rail's glyph column (they are only ever 1-hop hot highlights there). Update the §4.3 table (`railW 28 · pairGutter 72 · railGutter 12 · openW 118`) and the Z0/Z1 wireframes to show the lane at ~9 columns.

**F123** · **high** · round 1 · `data-truth` · at: §2.2 row `class → baseline (drawn past the RULES column)`, §4.1 step 6 "drawn behind the RULES nodes", §9.2 callout `.B marks where a dashed edge arrives`

- Issue: Class→baseline skip edges are drawn as dashed curves *behind* the RULES column, but 02 §2.5 makes every row transparent at rest and P10 forbids opaque plates inside the card — so five dashed curves pass straight through the rule-id labels (`oma.qml.process…`). In §9.2 they also pass behind the `PX45` rail glyph. That is the one place the graph will actually look like a hairball, and it carries the least information (the relation is already a `≈` glyph on the node).
- Proposed fix: Do not draw skip edges as curves. Encode the via-class on the BASELINE node itself: leading class glyph before the relation mark (`󰆍 ≈ installer`), and add the baseline node to the class node's hot set so the label brightens (`faint` → `fg`) when the cursor is on `process-execution`. Rule→baseline edges (adjacent columns) stay as drawn. Inspector line for the baseline node states `via class process-execution` in words. Remove the `skip: true` edge shape from §3.2, the `j = i + 2` branch from §4.1, and the `.B` callouts from §9.2.

**F124** · **high** · round 1 · `feasibility` · at: §4.3 Sizing math — "Flow height at base 12: hero 40 + views 34 + header 20 + lens row 34 + body 356 + inspector 62 ≈ 546 ≤ fittedContentHeight(h, Style.space(560))"; §4.1 step 4 "maxRows = floor(Style.space(360) / rowH) = 12"

- Issue: The sum omits (a) the outer Column gaps (2 × Style.space(12)) and FlowView's inner gaps (~3 × space(10)) ≈ 54 units, (b) KeyboardPanel's verticalContentInset that fittedContentHeight adds on top of the implicit height (2 × popupPadding 14 + 2 × border max(1, space(2)) = 32, Ui/KeyboardPanel.qml:159–173), and (c) the status line / lexical NoticeRow / breadcrumb rows at Z1–Z2. Real total at base 12 ≈ 630–650 units against the 560 cap, so the graph body is cut by ~2.5 rows and the InspectorStrip sits below the fold on every Flow entry; wireframes 9.1–9.3 cannot render as drawn without scrolling. The fixed space(360) body also ignores the screen cap (on a 768-px display at base 20 availableCardHeight ≈ 700 px, not the 933 px space(560) assumes). Wheel over a column will also go to the outer Flickable because the FlowNode sketch has no onWheel.
- Proposed fix: Derive maxRows from the space actually left: bodyH = panel.contentHeight − inset − (hero + chips + header + lens + inspector + gaps); maxRows = floor(bodyH / Style.spacing.popupRowHeight) (≈ 9 at base 12), or fix the body cap at ≈ space(270) and say so. Add the gap and inset rows to the §4.3 table; state that hero+chips may be pinned outside the Flickable (see 03 §3 issue) so the body height is computable; make ensureCursorVisible on graph rows mandatory and put the column onWheel handler in TrustFlow, not FlowNode.

**F125** · **high** · round 1 · `feasibility` · at: §6.1 `a / A` row ("through the existing analysisProcess queue (4712)"), §11 Analyses row; 05 §6 Phase 3 "feeding the existing ensureAnalysis path and analysisProcess 4692 sequentially"

- Issue: There is no analysis queue in Panel.qml. `analysisProcess.startFor()` (4692–4707) keeps a single `nextPluginId` slot and calls terminateBoundedProcess on the running analysis to preempt it; `ensureAnalysis()` (1096) reads `selectedPlugin()` and writes single-slot root state (`analysisPluginId`, `analysisReport`, `analysisLoading`). `a` on a cursor node that is not `selectedPluginId`, and `A` over 8 plugins one at a time, both need new root-owned state: an `analysisQueue` + generation counter (mirror `statusQueue` / `statusSweepGeneration`, Panel.qml:77–78, 603–620), start-next-on-exit, cancel on `x` and on close, and a per-plugin loading/unavailable map instead of `analysisLoading`. The Phase 3 estimate does not account for this and the roadmap's Open question 5 treats it as UX polish.
- Proposed fix: Replace "existing queue" with an explicit Phase 3 (or 2a, since the detail sheet's Analyze button needs it too) work item: `analysisQueue`, `analysisSweepGeneration`, `startNextAnalysis()` on `analysisProcess.onExited`, `x`/close cancellation, `analysisStateById` map; keep `startFor()` preemption only for the selected-plugin path. Add ~1 day to Phase 3.

**F126** · **high** · round 1 · `ground-rules` · at: §3.3 worked example (coverage_limitations row), §9.4 Z2 wireframe 'COVERAGE LIMITS ON THIS PATH', §12 'grouped as 8 sink references rejected (absolute) + 5 missing local target'; also 02-design-principles.md §3.4 'limitation code' row

- Issue: The lgse.sandman limitation split is reversed. analyze-lgse.sandman.json has 5 'sink-reference-rejected:absolute' (lines 144/158/171/213/239) and 8 'missing-local-target'. 04 and 02 print 8 absolute / 5 missing; 01 §8.4 and 03 §5.3 print 5 absolute / 8 missing (correct). The 04 §12 acceptance check therefore encodes a wrong expected value and would fail against the real fixture.
- Proposed fix: Change every occurrence in 04 (§3.3, §9.4 wireframe, §12) and 02 §3.4 to '5 sink references rejected (absolute) · 8 missing local target' so all four documents agree with the sample.

#### Medium (10)

**F127** · **medium** · round 1 · `api-truth` · at: §3.3 lgse.sandman row 'coverage_limitations' ("8 `absolute`, 5 `missing-local-target`"); §9.4 Z2 wireframe COVERAGE LIMITS rows ("8 sink references rejected (ab…" / "5 missing local target"); §12 acceptance bullet for Z1/Z2 ("grouped as `8 sink references rejected (absolute)` + `5 missing local target`")

- Issue: The counts are swapped. analyze-lgse.sandman.json has 5 `sink-reference-rejected:absolute:LidService.qml:*` codes and 8 `sink-reference-rejected:missing-local-target:LidService.qml:*` codes (13 total). 01 §8.4 and 03 §5.3 state it correctly (5 absolute, 8 missing local targets).
- Proposed fix: Change all three places to "5 sink references rejected (absolute) · 8 missing local target".

**F128** · **medium** · round 1 · `completeness` · at: §3.3 worked example lgse.sandman row "coverage_limitations" ("13, all `sink-reference-rejected:*:LidService.qml:*` (8 `absolute`, 5 `missing-local-target`)"); §9.4 wireframe ("LidService.qml · 8 sink references rejected (ab…" / "5 missing local target"); §12 acceptance ("grouped as `8 sink references rejected (absolute)` + `5 missing local target`")

- Issue: The split is inverted. `analyze-lgse.sandman.json` has 5 `sink-reference-rejected:absolute:*` and 8 `sink-reference-rejected:missing-local-target:*` codes (all on LidService.qml). 01 §8.4 and the 03 §5.3 wireframe have it right (5 absolute / 8 missing); the 04 acceptance check as written would fail against the real fixture.
- Proposed fix: Change all three places in 04 to `5 sink references rejected (absolute) · 8 missing local target`.

**F129** · **medium** · round 1 · `data-truth` · at: §5 encodings row "Count … digits in `Style.font.caption` at the node's right edge" and §10.2 `FlowNode` sketch (`count` Text, `font.pixelSize: Style.font.caption`); 02 §2.1 row "Hints, relative times, chip labels, footer, node counts, breadcrumb | caption"

- Issue: Contradicts 02 P7, which lists 'counts' in the data floor (`bodySmall` or larger). The result is that the flagship surface — the graph — is the smallest type on any screen: labels `bodySmall`, counts `caption` (7.5 px at base 9), while a plain plugin row gets `body`. Hierarchy is inverted: the view the ask cares most about reads as a footnote.
- Proposed fix: Node count `Style.font.bodySmall` (1–2 digits, ≈ 1 px wider than caption; label budget in §4.3 drops by less than one character). Rail rows keep glyph + count at `bodySmall`. Remove 'node counts' from the caption row of 02 §2.1 and add them to the `bodySmall` row; update the `FlowNode` sketch. Keep node labels at `bodySmall` — characters matter more than 1 px here because ids elide.

**F130** · **medium** · round 1 · `data-truth` · at: §5 legend line "`— thin ≤ 3 · = medium 4–9 · ≡ thick ≥ 10 occurrences · … · = equivalent check · — not covered`"; 02 §2.4 relation glyphs `=` `≈` `—`

- Issue: The legend collides with itself: `—` means 'thin edge' and 'not covered'; `=` means 'medium edge' and 'equivalent check', in the same sentence. On nodes, not-covered `—` (em dash) and not-analyzed `–` (en dash) differ by a fraction of a cell at `bodySmall` — indistinguishable in a monospace face.
- Proposed fix: Describe thickness in words only (`thin ≤ 3 · medium 4–9 · thick ≥ 10 occurrences`); drop the dash/equals mimicry. Relation marks: `=` equivalent, `≈` partially covered, and **no glyph** for not-covered — render the dim word `not covered` in the count slot (the row is already dim and edgeless). Update 02 §2.4, 04 §2.1 table, §9.2/§9.6 wireframes (replace `x`), and Labels.js.

**F131** · **medium** · round 1 · `design-quality` · at: §3.3 worked example line 197 `Catalog says: listed, verified · snapshot 65b6385, 16 min old`; §9.1 inspector line 510 `Catalog says: conflict · snapshot 65b6385, 16 min`; §5 encodings line 346; §8 line 471. Root cause in README.md GR2 (line 35) and 02-design-principles.md P2 (line 54) / checklist (line 638): "every catalog value is prefixed Catalog says:"

- Issue: `listed` and `conflict` are values of marketplace `status`, which omasafe-marketplace/src/lib.rs:367-407 computes by correlating the installed id/repository against the snapshot. They are OmaSafe's correlation results, not statements the catalog makes; only `registry_claim.*` (verification_status, commits, repository) is the catalog's word. Prefixing the correlation with `Catalog says:` misattributes an OmaSafe result to the catalog (GR2 in reverse), and for `conflict` there is no registry_claim at all (null). 02 §3.4's own label table already keeps `status` labels unprefixed (`Listed in catalog snapshot`, `Catalog entry conflicts…`) and prefixes only `verification_status`, so the README/P2 rule and the graph inspector contradict the label table.
- Proposed fix: Narrow the rule in README GR2, 02 P2 and the checklist to: every value passed through from the catalog snapshot (`registry_claim.verification_status`, `listing_validated_commit`, `upstream_observed_commit`, `repository`) is prefixed `Catalog says:`; correlation `status` uses `Labels.marketplaceStatus` unprefixed. Inspector lines become `Listed in catalog snapshot · Catalog says: verified · snapshot 65b6385, 16 min old` and `Catalog entry not matched (repository conflicted or unavailable) · snapshot 65b6385, 16 min old`. Fix 04 §12 fixture `marketplace_stale` check wording to match.

**F132** · **medium** · round 1 · `feasibility` · at: §10.2 TrustFlow sketch — `Repeater { model: flow.layout.columns }` / `Repeater { model: col.modelData.nodes }`; §6.2 moveCursorH (`slidePair(next) // widths snap; layout rebuilt`, `edgeLayer.paths = FlowLayout.hot(...)`); §11 hot-path budget

- Issue: `layout` is a plain object reassigned by build(), so every rebuild (each `a`, every `h`/`l` that slides a rail — most column crossings per §6.2 — every ensureCursorVisible offset move, every width change) replaces the Repeater models and destroys/recreates up to 52 FlowNodes (CursorSurface + OpticalGlyph with TextMetrics + 2 Text + MouseArea + a QQC ToolTip each). That is allocation churn on the keyboard hot path, contradicting §11 "hot path = one bucket() pass". Separately, `EdgeLayer { paths: flow.layout.paths }` is a binding that the imperative `edgeLayer.paths = FlowLayout.hot(...)` overwrites on the first cursor move, so later `layout` rebuilds leave stale edges until the next cursor move.
- Proposed fix: Keep per-column node arrays stable (assign only when membership changes: inventory/analysis/scope/filter), and expose pair/open/offset/x/width as separate properties the delegates bind to, so a slide changes geometry without touching models. Give TrustFlow a `property var paths`, bind `EdgeLayer.paths` to it, and set that property from both build() and hot(). Add "no delegate recreation on h/l" to §12 interaction invariants.

**F133** · **medium** · round 1 · `ground-rules` · at: §4.1 step 4 'maxRows = 12 … A column with more nodes shows maxRows − 1 and a +N more rail row' and §8 'Too many nodes (column > 12)' vs §9.1 callout '+4 is the BASELINE rail's +N more row (12 ids, 8 visible beside 8 plugin rows)', §12 'BASELINE shows +4 more beside 8 plugin rows'; §9.3 callout '+7 for the rest' vs §12 'BASELINE rail 6 reachable ids + +6 more'

- Issue: The windowing rule says a 12-node column fits without a rail row, yet the Z0 wireframe and acceptance check show BASELINE (12 ids) windowed to 8 + '+4'. No rule ties a column's visible rows to the tallest neighbouring column. In Z1, 12 − 6 reachable = 6 hidden, so '+7' in §9.3 contradicts '+6 more' in §12.
- Proposed fix: Either add a step to §4.1 ('all columns share one window height = max(rows of the open pair)') and keep +4, or redraw §9.1 with all 12 baseline rows and drop '+4' from §12. Change §9.3 '+7' to '+6'.

**F134** · **medium** · round 2 · `api-truth` · at: §9.2 wireframe inspector line (line 631: "LOCAL HITS 4 plugins · 45 occurrences · – review…") and callout (line 644–645: "`45 occurrences · – review items` (`–`, never `0`, until a review item is recorded)"); §12 acceptance (line 1087: "`oma.qml.process-execution`: `45 occurrences · – review items`")

- Issue: Here `–` is used for a measured zero (four plugins analyzed, the rule matched 45 occurrences and 0 review items). 02 §2.4 defines `–` as the single placeholder for "not analyzed / no data" and 02 §3.5 fixes the dash rule: "`–` (not yet measured) only while zero plugins are analyzed; once n ≥ 1 they print the measured value". Using `–` for a measured zero makes an analyzed result look unmeasured and, conversely, teaches the reader that `–` sometimes means "none found" — which then undermines every other `–` (unanalyzed plugin strip, Matrix cell, rule row) that must never be read as clean. The same acceptance line prints `0 occurrences · 10 review items` for `oma.qml.dynamic-reference`, so the doc contradicts itself within one bullet.
- Proposed fix: Print the measured value: `45 occurrences · no review items` (matching the Matrix inspector wording in §9.5, "no review items") or `0 review items`; reserve `–` for the case where zero plugins are analyzed. Correct §9.2 line 631, the callout at 644–645, and the §12 acceptance bullet; add a fixture check "an analyzed rule with zero review items never prints `–`".

**F135** · **medium** · round 2 · `data-truth` · at: §6.1 Inputs, `?` · `g` row: "`bar.shell.summon(manifest.id, JSON.stringify(payload))` when `bar.shell` exists" — repeated in 05 §8 Contract ("the popup calls `bar.shell.summon(manifest.id, …)`")

- Issue: `manifest` is not available inside a bar-widget/popup QML tree. The host injects `manifest` only into panel/overlay/menu loader items (shell.qml:630–631 `if ("manifest" in item) item.manifest = panelEntry.manifest`); bar widgets receive `bar`, `moduleName` and `settings` only (Ui/BarWidget.qml:15–17; Bar.qml:1770–1771, 1804). Panel.qml/BarWidget.qml have no `manifest` property today, so `manifest.id` is undefined there. The cited precedent network/Panel.qml:468 passes a literal id.
- Proposed fix: From the popup use `root.moduleName` (the widget's canonical id, equal to the manifest id under which the widget component is registered, shell.qml:678) or the literal `"io.github.tuthan.omasafe"`; keep `manifest.id` only inside `TrustFlowWindow.qml`, where the panel loader injects it. Update 04 §6.1 and 05 §8.

**F136** · **medium** · round 2 · `ground-rules` · at: §7 table row Z1 "`All plugins › lgse.sandman`" and §9.3 wireframe first line

- Issue: 03 §8 fixes the Breadcrumb rule for "depth ≥ 1 of any view": at depth 1 it renders the way back only (`󰅁 All plugins`), and the full `›` path only at depth ≥ 2. Flow Z1 is depth 1, yet 04 §7 and §9.3 draw the full path `All plugins › lgse.sandman` at Z1.
- Proposed fix: Either redraw 04 §9.3 and the §7 Z1 row as `󰅁 All plugins` (back-only, consistent with 03 §5.1 and §8), or amend 03 §8 to exempt Flow (state the reason: the Flow header names the plugin but the hero does not swap at Z1).

#### Low (12)

**F137** · **low** · round 1 · `api-truth` · at: §9.4 Z2 Trace wireframe, EVIDENCE rows ("LidService.qml:158", "LidService.qml:171")

- Issue: Neither 158 nor 171 is a process-execution site in the sample; the ordered sites are LidService.qml 142, 156, 169, 182, 211, 237, 252, 263, 265 then Service.qml 250, 267, 281, 293, 366, 377, 383. 158/171 are lines named in the D-Bus `sink-reference-rejected` limitations.
- Proposed fix: Rows: LidService.qml:142 · :156 · :169 · Service.qml:250 (then +12 more).

**F138** · **low** · round 1 · `api-truth` · at: §12 Testing and acceptance, bullet 'Edge counts: plugin → class 13 (sandman 4, omasafe 2, btop 5, dropdown-terminal 4) plus omasafe's review-item-only edge into `filesystem-access`'

- Issue: 4 + 2 + 5 + 4 = 15 occurrence-backed plugin→class edges, 16 with the review-item-only edge; the bullet says 13. (Per-plugin class counts are verified against the samples: sandman 4, omasafe 2, btop 5, dropdown-terminal 4.)
- Proposed fix: "plugin → class 15 (…) plus omasafe's review-item-only edge = 16"; adjust §11's '≈ 25 real' if it was derived from the same sum.

**F139** · **low** · round 1 · `api-truth` · at: §9.3 Z1 wireframe callout ("the BASELINE rail shows the ids reachable from this plugin (… six ids) and `+7` for the rest") vs §12 bullet 'Z1 for lgse.sandman: … BASELINE rail 6 reachable ids + `+6 more`'

- Issue: rules-coverage.json has 12 distinct externalIds; 6 reachable + 7 hidden = 13. The wireframe draws only 5 rail rows, so `+7` is right for the drawing but the callout's arithmetic and §12's `+6 more` contradict each other.
- Proposed fix: Pick one: rail shows 5 ids + `+7 more`, or 6 ids + `+6 more`; make §9.3 and §12 agree.

**F140** · **low** · round 1 · `completeness` · at: §10.2 sketch `graph/EdgeLayer.qml` ("`component Bucket: ShapePath {…}` / `component Dashed: Bucket {…}` … `Behavior on strokeColor`")

- Issue: Verified, not fabricated — recorded so the maintainer knows it was checked: an offscreen `qml` run on Qt 6.11.2 of a `Shape { preferredRendererType: Shape.CurveRenderer; component Bucket: ShapePath {…}; component Dashed: Bucket { strokeStyle: ShapePath.DashLine; dashPattern: [4, 4] } … Behavior on strokeColor {…}; PathSvg {…} }` loads and instantiates (exit 0; a control with an unknown base type fails with exit 2). `PathSvg` is exported as `QtQuick/PathSvg 6.0` (`QtQuick/plugins.qmltypes:12162`); `DashLine`, `dashPattern`, `capStyle`, `RoundCap`, `CurveRenderer`, `preferredRendererType` are in `Shapes/plugins.qmltypes` at the cited lines. No change needed except that the README/04 wording "probe QML was `qmllint`-clean only" can now say the bucket pattern also instantiates under `qml -platform offscreen`.
- Proposed fix: Optionally update the status line in README and 04 §12 to record the offscreen instantiation result; no identifier changes required.

**F141** · **low** · round 1 · `data-truth` · at: §9.1 lens row `[Graph] [Matrix]                HIDING 7 BACKUPS` vs 03 §6 frame `[Graph] [ Matrix ]                             ?` and 03 §6 callout "Filters and toggles print what they hide in the header meta"

- Issue: The two documents place the same two elements differently: 03 puts `?` on the lens row and the HIDING string in the header meta; 04 puts HIDING on the lens row and omits `?`. Minor, but it is exactly the kind of drift that produces two implementations.
- Proposed fix: Lens row right slot = `?` legend `PanelActionButton` (and the Phase 5 launcher when available). Hidden counts append to the section header value: `TRUST FLOW · ALL PLUGINS | 4 OF 8 ANALYZED · HIDING 7 BACKUPS`. Redraw 04 §9.1, §9.2, §9.5 headers to match 03 §6.

**F142** · **low** · round 1 · `design-quality` · at: §2.1 Layers table, RULES row (line 56): count text "review items if any, else occurrences"; wireframe §9.1 (lines 497-502) shows `R49`, `R45` (occurrences) beside `R10` (review items) in the same slot

- Issue: One visual slot carries two different quantities without a label: `oma.qml.persistence-scheduling 49` is occurrences, `oma.qml.dynamic-reference 10` is review items. The reader compares them as one magnitude, and the higher occurrence digits on benign rules visually outrank the review-item rule, which is the kind of implicit ranking GR1 forbids and P1 ("counts are labelled") requires to be explicit.
- Proposed fix: Always print occurrences in the count slot and add review items as the node suffix the plugin nodes already use (`· 10 review items`, dim caption), or use a two-glyph form `49 ○ · 10 !` with the legend entry. Update the §9.1/§9.2 wireframes and the §12 count checks.

**F143** · **low** · round 1 · `feasibility` · at: §10.2 FlowNode sketch — `PanelToolTip { visible: node.hasCursor && !!node.modelData.tooltip }`; §5 Cursor row

- Issue: A QQC ToolTip pops 400 ms after every keyboard cursor move (one ToolTip object per node, up to 52 alive), duplicating InspectorStrip line 1 and contradicting the adopted Little Snitch pattern X8 ("fixed inspector, not floating tooltips").
- Proposed fix: Show the node tooltip on pointer hover only (root sets a `hoverKey` from gate.moved) or use one TrustFlow-level PanelToolTip positioned at the cursor node; keep the inspector as the keyboard path.

**F144** · **low** · round 1 · `feasibility` · at: §4.3 label capacity ("12 / 10" chars) and wireframes 9.1 / 9.3 (`TM persistence 49`, `PX process-exec 16`)

- Issue: With the glyph column the open CAPABILITIES/RULES text width is openW − space(10) − space(22) − space(6) − space(8) − countW(≈ 20) − space(8) = 130 − 74 = 56 px at base 12; at bodySmall 11 px the advance is 0.6 em = 6.6 px (verified in JetBrainsMonoNerdFont hmtx: letters and all 17 class glyphs are 0.6 em), so ≈ 8 characters, not 10. `persistence` (11) and `process-exec` (12) will render as `persi…ling` / `proce…exec`.
- Proposed fix: Correct the table to 12 / 8, draw the elided forms in 9.1 and 9.3, or drop the count from the open CAPABILITIES column (inspector shows it) to regain 3 characters; keep the §13 open point about dropping the RULES glyph.

**F145** · **low** · round 1 · `ground-rules` · at: §5 'Filter / toggle' row and §8 'HIDING 7 BACKUPS · 4 NOT ANALYZED'; also 02 §3.5 and 03 §6

- Issue: The meta string claims 4 not-analyzed plugins are hidden, but 04 §8 says unanalyzed nodes are 'listed (never omitted)', the §9.1 wireframe draws all 8 plugins, and no key or toggle to hide unanalyzed plugins is defined anywhere (03 §13 key map has none).
- Proposed fix: Either define the filter (key, default, where it appears) or change the example string to 'HIDING 7 BACKUPS' in 02 §3.5, 03 §6, 04 §5 and 04 §8.

**F146** · **low** · round 1 · `ground-rules` · at: §9.4 Z2 wireframe EVIDENCE rows 'LidService.qml:158', 'LidService.qml:171'; 03-ui-overhaul-proposal.md §5.2 expanded class row 'LidService.qml:158 · Process · parser-backed'

- Issue: Lines 158 and 171 are not process-execution sites in analyze-lgse.sandman.json (they are the D-Bus sink-rejection lines); the Process occurrences in LidService.qml are at 142, 156, 169, 182, 211, 237, 252, 263, 265. Service.qml:250 and the 16/2-file totals are correct.
- Proposed fix: Replace 158→156 and 171→169 in both wireframes so the fixture rows match the sample.

**F147** · **low** · round 2 · `completeness` · at: §9.1 Z0 Atlas wireframe PLUGINS column vs §4.1 step 2 "Plugins: `outstanding desc, analyzed first, id asc`"

- Issue: Drawn order is omasafe, btop, sandman, dropdown-terminal, omarchy-unraid, crmne, ianswope, lunar-calendar. With the stated key and the fixture (alerts on btop, omarchy-unraid, omasafe) the order is ilyazar.btop, io.github.tuthan.omasafe, io.github.hvo.omarchy-unraid, io.github.tuthan.dropdown-terminal, lgse.sandman, crmne.hyprmoncfg, ianswope.snapshots, io.github.tuthan.omarchy-lunar-calendar. The PLUGINS layer is not barycentre-adjusted (§4.1 step 3: middle layers only), so nothing else explains the drawn order.
- Proposed fix: Redraw the column in key order (and the `!` marks with it), or amend the key if the drawn order is intended.

**F148** · **low** · round 2 · `ground-rules` · at: §8 States vs §9 Wireframes

- Issue: States the proposal names but never draws: Flow with inventory ready and zero analyses (all PLUGINS hollow, three dim rail rows, inspector `Analyze (a) · Analyze all (A)`), Flow lexical-only (NoticeRow + all edges dashed), Flow CLI-unavailable, and the text-only fallback body (`TRUST FLOW · MATRIX` header). In 03 §10 the remove, enable and schedule ConfirmSheets are tabulated but not drawn although schedule has a unique anatomy (Unit row, no plugin identity) and enable is the first Policy-only variant; 03 §4.2 Overview quiet and §5.1 WHAT CHANGED are prose/schematic only.
- Proposed fix: Add at least a Flow zero-analysis frame and a schedule ConfirmSheet frame (both are GR3/GR6-relevant), and one-line "delta from §x" notes for the rest; or state in README §Documents that these states are intentionally prose-only.

### 4.6 05-implementation-roadmap.md

17 issues (round 1: 14, round 2: 3).

#### Medium (6)

**F149** · **medium** · round 1 · `api-truth` · at: §12 Rollout, bullet 'CLI asks to file as issues against omasafe-cli' ("a flag on the `schedule install` unit template so scheduled scans can carry `--include-analysis`")

- Issue: This already exists. `schedule install --policy hardened` writes `ExecStart="<exe>" scan --notify --only-new --include-analysis` (omasafe-cli/src/main.rs:3465–3477, `analysis_flag`); advisory omits the flag. The ask contradicts the panel copy in 02 §3.7 / 03 §10 ("hardened adds analysis") and would be closed as invalid.
- Proposed fix: Delete the ask, or reword it to what is actually missing (e.g. `--include-analysis` under advisory policy, or a `report_only: false` mode) after confirming with the CLI owner.

**F150** · **medium** · round 1 · `completeness` · at: §1.1 ("re-validates `targetStillExact` at execution (`runEnable` 1219, `runReviewUpdate` 1241)") and §2 fate table row "1219–1268 | `runEnable` / `runReviewUpdate` with `targetStillExact` | keep verbatim"

- Issue: `runEnable()` starts at 1244 (`targetStillExact` 1246) and `runReviewUpdate()` at 1269 (`targetStillExact` 1273, argv 1291–1295). The "keep verbatim" range 1219–1268 therefore excludes `runReviewUpdate` entirely and includes the confirm-opening helpers instead.
- Proposed fix: Change to `runEnable` 1244 / `runReviewUpdate` 1269 and widen the keep-verbatim range to 1219–1298 (or split: 1244–1268 `runEnable`, 1269–1298 `runReviewUpdate`).

**F151** · **medium** · round 1 · `feasibility` · at: §1 phase table and §4 Phase 1 ("Content is still the four tabs' content, now on kit rows", acceptance "Every row … reachable with j/k/h/l") vs §5 Phase 2 (delete 2584–3790, re-home into views/*)

- Issue: Phase 1 converts every row, card, button and expander in the four tab components (~1,200 lines, 2584–3790) to CursorSurface/Button with a cursor model, and Phase 2 deletes those components and rebuilds the content as views/*. The conversion is done twice; 3–4 d + 4–5 d is optimistic under that plan. Phase 3 (5–6 d) additionally covers FlowLayout.js, six QML files, Matrix, Trace, inspector, the new analysis queue and the smoke test; 8–12 d is more realistic.
- Proposed fix: Limit Phase 1 to shell chrome (bar icon, hero, chips, tokens, ConfirmSheet, root colour/type bindings, cursor scaffold covering shell targets only) and leave tab bodies untouched; move row conversion into Phase 2 so each row is written once. Re-estimate Phase 3 at 8–12 d (or split the queue and Matrix/Trace into 3a/3b) and state the assumption (one QML-fluent engineer, full time).

**F152** · **medium** · round 1 · `ground-rules` · at: §5 Phase 2, sentence 'The Flow chip exists from 2a with a NoticeRow body (… the chip is hidden until Phase 3)'

- Issue: Self-contradictory: the sentence says the Flow chip exists from milestone 2a and, in the same parenthesis, that it is hidden until Phase 3. The Phase 1 summary table also lists 'Flow frame' as shipping in Phase 2, while Phase 3 'Files modified' says 'Flow chip visible' first appears there.
- Proposed fix: Decide one: either 'the Flow chip is hidden until Phase 3 (ButtonGroup options omit it)' and drop 'Flow frame' from the Phase 2 row, or ship the frame with a NoticeRow body in 2a and state the exact copy of that NoticeRow.

**F153** · **medium** · round 1 · `ground-rules` · at: §3 Phase 0 goal: 'every defect the audit rated High is closed inside the current UI'; 01-research-and-audit.md §10 row for 05 ('Phase 0 list (A1–A4, A6–A9, A13, A17, A21, A39)')

- Issue: Phase 0 does not close every High defect: A5, A9, A11, A12, A14–A16, A18–A20, A42 are rated H in 01 §3 but land in Phases 1–2. 01 §10 also says Phase 0 includes A9 (inventory coverage.limitations never rendered), while 05 Phase 0 (0.1–0.14) omits it and 05 §5 lists that field under Phase 2 'rendered for the first time'.
- Proposed fix: Reword the Phase 0 goal to 'every High defect that is a correctness or ground-rule violation fixable without visual change (A1–A4, A6–A8, A10, A13, A17, A21, A39)'; either add A9 to Phase 0 (a one-line Text under the status row) or remove A9 from the 01 §10 Phase 0 list.

**F154** · **medium** · round 2 · `data-truth` · at: §9 Component inventory, closing paragraph: "OmaSafe uses the argv-only `Util.execArgv(["wl-copy", "--", value])` (`Commons/Util.qml:62`) instead, so no shell is involved and the value is never interpolated." (same call in 03 §5.1 TRUST BASELINE copy button)

- Issue: `Util.execArgv` is `Quickshell.execDetached(["bash", "-lc", 'exec "$@"', "bash"].concat(argv))` (Util.qml:62–64). A login bash *is* spawned; what is true is that the value lands in a positional parameter and is never re-tokenised. The sentence misstates the API, and OmaSafe's self-analysis will still record a bash-spawning `detached-process-execution` occurrence (the same class the first-party `bash -c … | wl-copy` idiom produces).
- Proposed fix: Reword: "`Util.execArgv` runs `bash -lc 'exec "$@"' bash wl-copy -- <value>`: a login shell is spawned but the value is passed as a positional argument, never interpolated into the command string." If a shell-free copy is wanted, call `Quickshell.execDetached(["wl-copy", "--", value])` directly (argv, no bash) and cite that instead.

#### Low (11)

**F155** · **low** · round 1 · `api-truth` · at: §5 Phase 2 acceptance bullet ("`/` then `process` lists the class, 10 rules and the 3 Baseline ids that mention it")

- Issue: Against rules-list.json and rules-coverage.json: two classes contain 'process' (process-execution, detached-process-execution); rules matching 'process' in id or title = 3 (oma.qml.process-execution, oma.qml.detached-execution, oma.python.reverse-shell), or 11 if the capability string is indexed (03 §8 says the index is ids + titles); Baseline ids containing 'process' = 1 (privileged-process-control-from-shared-temp). '10 rules' and '3 Baseline ids' match neither index definition.
- Proposed fix: State the index (id · title · capability · externalId) and the resulting counts: 2 classes · 11 rules · 1 Baseline id.

**F156** · **low** · round 1 · `completeness` · at: §1.1 ("`enforcementEnum` (240), `coverageRelation` (313), `overrideStatus` (331)"), §2 fate table row 187–450, and Sources ("240, 313, 331")

- Issue: `coverageRelation` is defined at Panel.qml:320 and `overrideStatus` at 338 (01 §2.6 has the correct lines). 313 and 331 are inside other helpers.
- Proposed fix: Replace 313→320 and 331→338 in all three places.

**F157** · **low** · round 1 · `completeness` · at: §2 fate table row "1–139 | ... tabs model (132–137)"

- Issue: The `tabs` array is at Panel.qml:134–139 (132 is `property int analysisRequestId`). 01 §2.6 says 134–139 correctly.
- Proposed fix: Change to 134–139.

**F158** · **low** · round 1 · `completeness` · at: §9 Component inventory, closing paragraph ("The `wl-copy` copy action (`Util.execArgv(["wl-copy", "--", value])`, first-party precedent tailscale/Service.qml and network/Panel.qml:450)")

- Issue: Neither cited file uses `Util.execArgv`. `tailscale/Service.qml:109` and `network/Panel.qml:450` both run `Quickshell.execDetached(["bash", "-c", "printf %s " + Util.shellQuote(value) + " | wl-copy"])`. `Util.execArgv` does exist (`Commons/Util.qml:62`) and is the safer form, so the proposal is valid; only the precedent claim is wrong.
- Proposed fix: Say: "first-party panels copy via `Quickshell.execDetached` + `Util.shellQuote` (tailscale/Service.qml:109, network/Panel.qml:450); OmaSafe uses the argv-only `Util.execArgv` (Util.qml:62) instead."

**F159** · **low** · round 1 · `feasibility` · at: §2 fate table — "Expected size after Phase 2: Panel.qml ≈ 2 000 lines"

- Issue: 5174 − 950 (legacy) − ~1,210 (2584–3790) − ~160 (overlay) − ~130 (tab strip/status row) ≈ 2,720 before adding the cursor model, depth stacks, `vm`, the analysis queue and the cloned `rulesListProcess` (~80 lines). The collectors alone are ~1,360 lines (3815–5173) and are declared untouchable.
- Proposed fix: State ≈ 2,900–3,100 lines, or add a phase item that moves the 16 Process blocks verbatim into a `Collectors.qml` QtObject exposed to the root (which the never-changes list currently forbids).

**F160** · **low** · round 1 · `feasibility` · at: §1.1 and §2 fate table ("coverageRelation (313), overrideStatus (331)", "runEnable 1219, runReviewUpdate 1241"); also 03 §10 invariant 8 ("targetStillExact … 1219, 1241")

- Issue: Verified against Panel.qml: `coverageRelation` is at 320, `overrideStatus` at 338, `runEnable` at 1244, `runReviewUpdate` at 1269 (targetStillExact re-validation inside them at 1246 and 1273). 01 §2.6 has the correct numbers; 05 and 03 disagree with it.
- Proposed fix: Correct the anchors in 05 §1.1, 05 §2 and 03 §10(8) to 320 / 338 / 1244 / 1269 (1246, 1273).

**F161** · **low** · round 1 · `feasibility` · at: §8 Phase 5 — "IPC route change — `omarchy-shell shell summon io.github.tuthan.omasafe` routes to the window" and README note (summon / toggle only)

- Issue: Verified feasible: `isBarWidgetPanelPlugin` (shell.qml:426–438) returns false for a dual-kind manifest, `computePanelEntries`/`isEnabled` accept a `bar.layout` entry (PluginRegistry.qml:206–223 findEntryLocation), and `open(payloadJson)`/`close()` is the wifiqr contract. But `hide()` (shell.qml:480–494), `isPluginOpen` and therefore `toggle` also switch to the loader path, so `omarchy-shell shell hide io.github.tuthan.omasafe` can no longer close the popup and `toggle` never reaches it. The README note covers only summon/toggle.
- Proposed fix: Document summon, toggle and hide as window-only after Phase 5; the popup is reached by the bar icon, Esc and outside-click only. Add `shell hide` to the Phase 5 acceptance.

**F162** · **low** · round 1 · `ground-rules` · at: §1.1 'coverageRelation (313), overrideStatus (331)' and §2 range row '187–450 … coverageRelation 313, overrideStatus 331'

- Issue: Wrong line anchors. Panel.qml defines coverageRelation at 320 and overrideStatus at 338 (verified with grep); 01 §2.6 has the correct numbers.
- Proposed fix: Replace 313→320 and 331→338 in both places in 05.

**F163** · **low** · round 1 · `ground-rules` · at: §9 row 'TrustFlowWindow.qml (Phase 5 only) | … TrustFlow, PluginDetailView, ConfirmSheet' vs 04-trust-graph-spec.md §10.1 'Phase 5: TrustFlowWindow.qml | PanelWindow, BorderSurface card, PanelKeyCatcher, PanelHero, ButtonGroup, TrustFlow, InspectorStrip, ConfirmSheet'

- Issue: The two component lists for the optional window differ (05 adds PluginDetailView and drops InspectorStrip). Since 04 §6.1 says mutations live only in the detail sheet's TRUST BASELINE section, a window with a ConfirmSheet but no PluginDetailView (04's list) has no path to open that sheet.
- Proposed fix: Align both lists: include PluginDetailView and InspectorStrip in both 04 §10.1 and 05 §9, or drop ConfirmSheet from the window and state that mutations always happen in the popup.

**F164** · **low** · round 2 · `ground-rules` · at: §12 CLI asks — "the schedule confirm copy \"hardened adds analysis\" (doc 02 §7, doc 03 §10)"

- Issue: 02 has sections §1–§5 only; the schedule confirm copy is in 02 §3.7 Confirmation template.
- Proposed fix: Change "doc 02 §7" to "doc 02 §3.7".

**F165** · **low** · round 2 · `ground-rules` · at: §6 Phase 3 acceptance — "12 Baseline ids (3 edgeless)" and "Z2 trace … renders the map note verbatim"

- Issue: (a) At Z0 only `curl-pipe-shell` receives an edge (04 §3.3, §12: rule → baseline 1; class-level rows are node adornments, not edges), so 11 of 12 Baseline ids are edgeless; "3 edgeless" conflates edgeless with not-covered/markless. (b) 04 §7 Z2 "What is added" and the §9.4 Z2 wireframe contain no `note` row; the note is rendered only in the coverage table (04 §9.6, 03 §7.2), so this Phase 3 check cannot pass against the spec.
- Proposed fix: Reword (a) to "12 Baseline ids: 3 markless (not covered), 5 with a via-class glyph, 1 with an incoming edge"; for (b) either add the note to 04 §9.4's chain block (a fourth chain line) or drop "renders the map note verbatim" from the Phase 3 acceptance.

## 5 Reviewer notes

Verbatim notes returned by the fixers and the round-1 consistency pass. They record what was applied, what was declined and why, and cross-file follow-ups.

### 5.1 Round 1 fixer notes

#### README.md

Applied five surgical edits to /home/hvo/Projects/omasafe-plugin/docs/design/README.md; no other file touched.

VERIFIED AND FIXED
1. [data-truth] Status table row (line 95) relabelled "Real data used in the worked examples; verified against `cli-samples/`". The row's own numbers re-checked against cli-samples: inventory 7 backup / 6 Git-managed / 2 built-in; marketplace 7 unlisted / 3 listed / 3 conflict / 2 installed-differs; pinned-fetch, 935 s, 65b6385; scan 3 alerts all provenance-conflict; findings 5+2+1+2 = 10, all low, all oma.qml.dynamic-reference; limitations btop 3 / dropdown 0 / omasafe 2 / sandman 13; schedule installed:false; overrides []; every enforcement decision null. All correct as stated.
   Sources line (line 112): subcommand list now includes `plugins trust` and `plugins review`, with the exact argv shapes and anchors `Panel.qml:571` (trust: `--yes --expected-head/--expected-tree/--expected-digest`) and `Panel.qml:594` (`review <id> --action untrust --yes`), plus `omasafe-cli/src/main.rs:141, 181` where the dispatch arms live. Note: the issue cites `docs/cli-surface.txt` lines 7 and 10 — that file does not exist in this repo (docs/ contains only cli-v0.2-plan.md, cli-v0.2.1-plan.md, design/). The installed `omasafe-cli` usage line also collapses the plugins subcommands to `plugins ...`, so main.rs is the authoritative source; I cited it instead.
2. [completeness] 03 row now states what is drawn: attention drawn, quiet in prose as a delta, unavailable/loading/error drawn; ConfirmSheet "two variants drawn — record, review update; remove, replace, enable and schedule tabulated". Verified against 03 §4.2 (lines 227–231, prose only) and §10 (only two `+--` frames: "Record trust baseline?" and "Update at the catalog-claimed commit?"; six-row Kind table). 04 row: "five wireframes" → "six wireframes" (9.1–9.6 verified by headings) and size 600–1000 → 600–1100 (file is 1006 lines). 03 is 1129 lines, inside its stated 700–1200.
3. [design-quality] GR2 rewritten: "Every verification claim is prefixed 'Catalog says:'", prefix scoped to `registry_claim.verification_status` only; `status` renders as its `model/Labels.js` sentence, never a bare enum word; 02 §3.4 named as the single home of the rule. This matches what 02 §3.4 (line 532) and 03 §5.4 (line 512) already specify.

CROSS-FILE FOLLOW-UPS (not made; needed for consistency with the README as now written)
- 02-design-principles.md:54 (P2 "Every catalog-derived value is prefixed `Catalog says:`") and :638 (checklist "every catalog value starts `Catalog says:`") → narrow to verification_status; add the short-form `status` labels for one-line contexts to §3.4 (`listed` → Listed in snapshot; `conflict` → Conflicts with installed repo; `installed-differs` → Listed; commit differs; `unlisted` → Not in snapshot).
- 04-trust-graph-spec.md:197 (`Catalog says: listed, verified · snapshot …`), :346 (encodings table), :510 (§9.1 inspector `Catalog says: conflict · …`), :879 comment → inspector line format `<status short> · Catalog says: <verification> · snapshot <commit7>, <age>`; §9.1 should read `Conflicts with installed repo · Catalog says: verified · snapshot 65b6385, 16 min` (check the omasafe row's actual verification_status in inventory.json before writing).
- 05-implementation-roadmap.md:293 ("every catalog string starts with `Catalog says:`") and 01-research-and-audit.md:172, :421 ("Every value prefixed") → same narrowing.
- 03-ui-overhaul-proposal.md: optionally add a quiet-state frame at §4.2 and drawn `remove` (destructive) and `schedule` (identity-less) ConfirmSheet frames at §10; if added, revert the README 03 row wording to "all states drawn / six variants drawn".
- The issue's list of worked-example mismatches (02 §2.8 omasafe as Git checkout with baseline; 02 §3.7 placeholder hashes; 03 §5.2 / 04 §9.4 evidence line numbers; 03 §8 invented rule titles; 04 limitation counts swapped) lives in 02/03/04 and was not verified or fixed here; the README claim was softened so it no longer asserts every example is exact.

#### 01-research-and-audit.md

All 12 issues applied to /home/hvo/Projects/omasafe-plugin/docs/design/01-research-and-audit.md via exact-string replacements (each asserted unique; structure unchanged). Every replacement was verified against source first.

APPLIED
1. Hover/PointerMoveGate: §4 row now cites Ui/PointerMoveGate.qml:30 moved() (+ reset() 18, allowInitialSample() 25) and the first-party idiom plugins/clipboard/Clipboard.qml:192 / plugins/menu/Menu.qml:876 (PointerMoveGate ids at 245/907); monitor/Panel.qml:55–59 kept only for cursorActive/textSizeStops. §9.4 sentence and §11 sources list updated the same way. NOTE: the issue also named the "A5 fix column" — A5 (line 162) never mentioned PointerMoveGate or monitor/Panel.qml in 01, so nothing to change there.
2. "verified commit" body: 2453→2455 in §2.4 Review-update row, §2.6 anchors (2283–2581 row), §3 A10. Line 214 ("2453, 2455" for architecture words) intentionally kept — both lines carry listed words ("policy"/"Policy:").
3. Status icon: §4 row now reads "tailscale/Panel.qml:767 shield Text + TailscaleIcon.qml:46–64 badge BorderSurface", states TailscaleIcon draws a 3×3 Dot: Rectangle grid (26–34/66–71), and requires the badge font size to be a Style.font.*/Style.space() token because TailscaleIcon.qml:61 uses a literal Math.max(6, parent.height*0.72). §5 T16 cross-reference updated likewise.
4. Key:value blocks: power/Panel.qml:510–535 cited as InfoPair: Row / InfoLabel / InfoValue type-role precedent (not a GridLayout); network/Panel.qml:1224 (columns: 4) as the GridLayout precedent; InfoGrid note adds `import QtQuick.Layouts` (Panel.qml imports only QtQuick, QtQuick.Controls, qs.Commons, qs.Ui, Quickshell.Io at 1–5).
5. BorderOverlay: 30→28 in §6 closing paragraph and §9.1 table (preferredRendererType: Shape.CurveRenderer is line 28; Shape opens 26, ShapePath 30; PathSvg 51 correct).
6. Color.qml: T1 135–168→135–165; T14 168→164; §9.1 Theme reload → "Color.qml:28 declaration; mergeShell() 204–209 (shellValues = merged, 208; themeShellValues/userShellValues 170–171)"; §11 sources list updated to 135–165 loadColors, 164 muted fallback, 204–209 mergeShell.
7. Limitation codes — ISSUE PARTLY WRONG: `staged-script-analysis-budget-exhausted` DOES exist (omasafe-analyzer/src/detect/script/mod.rs:302, pushed when MAX_STAGED_CHAIN_LINES or STAGED_CHAIN_TIME_BUDGET is hit), so it was kept. The invented code was actually `time_budget_exhausted` (bare) — it appears only in omasafe-report/src/enforcement.rs test code (597–681) and is never emitted; replaced with `analysis_time_budget_exhausted` (detect.rs:188, 326). Added sink-reference-rejections-truncated:<n> (detect.rs:372) and the ingest.rs codes (file_limit_exceeded, aggregate_byte_limit_reached, tree_depth_limit_exceeded, directory_entry_limit_exceeded, symlink_target_truncated; ingest.rs:161–302, 665–707). Stated that bare/underscore codes have no file segment, do not fit kind[:sub]:file[:line[:target]], and render verbatim as their own group (not "unsupported limitation").
8. Totals: "only 5 of 17 classes" with the five class names (verified via jq over the four analyze-*.json: compositor-control, detached-process-execution, filesystem-access, persistence-scheduling, process-execution).
9. Coverage map: rule-level rows 6; appended "plus the 3 not-covered rows: 6 + 4 + 2 + 3 = 15" (verified: rules-coverage.json result.coverage has 15 rows, 6 with omaRuleId, 4 with omaCapability only, 12 partial-overlap + 3 not-covered).
10. §6 rows renamed P1–P14 → E1–E14 (14 rows); §6 intro now says they are numbered E1–E14 everywhere and 02 reserves P1–P12; §10 row for 02 reads "§6 ethos principles E1–E14 and divergences". No other P-number references existed in 01 outside §6.
11. Cache lifetime: §2.7 item 5 no longer lists clearing as preserved — it documents every clearAnalysisCache() call site (close 947–948, onAlertsChanged 3808–3809 with BW:530–535 scan-then-open, onCliVersionChanged 3796–3799, signature change 974, review update 5055, trust/untrust 5138) and states that under this policy every reopen is cold so the warm-cache states in 03/04 cannot appear. §8.7 Analysis row now specifies the new policy: entries survive close(); wholesale clear only in onCliVersionChanged; onAlertsChanged drops only entries with analyzer-policy-update / source-drift alerts; 974 may stay; flagged as a Panel.qml change for roadmap Phase 0/2.
12. Column widths: §9.2 now "openW ≈ 130 units each at base 12, 96 at base 9 — content-holder width, card − 2 × Style.spacing.popupPadding − 2 × border, 04 §4.3" (matches 04 §4.3 table).

CROSS-FILE FOLLOW-UPS (not made; other owners)
- 05 §2 range-map row ("'verified' copy 2453", line 106), 05 §3 row 0.14 ("(2453)", line 141), 05 line 618 anchor list, and README: cite 2455.
- 03 §2 and 05 §9: replace "follows TailscaleIcon.qml (glyph plus …)" / "TailscaleIcon pattern" with the tailscale/Panel.qml:767 shield Text + TailscaleIcon.qml:46–64 badge description and the token-size requirement.
- 02 §3.4 / 03 §5.3 limitation grammar kind[:sub]:file[:line[:target]] must add a branch for bare underscore codes (analysis_time_budget_exhausted, file_limit_exceeded, aggregate_byte_limit_reached, tree_depth_limit_exceeded, directory_entry_limit_exceeded, symlink_target_truncated, staged-script-analysis-budget-exhausted) and for sink-reference-rejections-truncated:<n>; any 02/03/05 mention of `time_budget_exhausted` should become `analysis_time_budget_exhausted`.
- 05: add the Phase 0/2 item that changes analysisCache lifetime (remove wholesale clears at Panel.qml 947–948, 3808–3809, 5055, 5138; keep onCliVersionChanged; per-plugin drop on analyzer-policy-update/source-drift); update 05 §1.1 preserve list and 04 §11 idle-cost row ("reused on reopen") accordingly — or, if the owner keeps clearing on close, 03 §4.1 and 04 §4.1/§11 must state Flow and LOCAL HITS start empty on every open.
- 05 §6 risk "openW ≈ 110 units at base 9" → 96.
- 02 intro already uses E1–E14; no change needed there.

The docs/design/ directory is untracked in git (?? status), so git diff shows nothing; the file on disk carries all edits.

#### 02-design-principles.md

All 20 issues applied to 02-design-principles.md via surgical edits (690 -> 759 lines; structure unchanged). Each fix was verified against source before editing.

VERIFIED AND FIXED IN 02
- Limitation code (both api-truth and data-truth entries, same issue): analyze-lgse.sandman.json has 5 `absolute` + 8 `missing-local-target` -> §3.4 now reads `5 sink references rejected (absolute) · 8 missing local target`.
- Counts: grep confirms 25 `Rectangle {`, 126 `Text {`, 6 `MouseArea {` in Panel.qml and 32 exports in Ui/qmldir -> P6 Why now "4 of the 32 components `Ui/qmldir` exports ... 25 `Rectangle`".
- §2.8 density sample: inventory.json shows io.github.tuthan.omasafe `built-in`, repository null; status = `untrusted`/`no trust baseline exists` -> row is now `[p ] io.github.tuthan.omasafe ... no baseline`; unanalyzed row prints single `–` + `not analyzed`; note added naming dropdown-terminal as the only `unchanged` plugin. Strip positions re-laid to catalog order.
- §3.7 wireframe hashes: now lgse.sandman's real head e8161c6e… / tree 4e5fab6d… / digest 59fdc825… (d26a… was btop's digest), with a sourcing sentence.
- §3.4 null rows: added `upstream_moved` false/null ("Upstream movement not stated") and a new `installed_matches_listing` row true/false/null ("Listing commit not stated"), anchored to omasafe-marketplace/src/lib.rs:85–86, 387–398. True/false labels match 03 §5.4 wording.
- Schedule: main.rs:3424–3500 confirms hardened only appends ` --include-analysis`, `report_only: true` -> labels `Advisory: daily drift scan, reports only` / `Hardened: daily drift scan with analysis, reports only`; `Labels.policy` split into `Labels.schedulePolicy` and `Labels.enforcementPolicy` (new row); §3.7 variants paragraph now gives both ConfirmSheet policy definition lines.
- marketplace `conflict`: lib.rs:367–371 reason "conflicted or was unavailable" -> label `Catalog entry not matched: installed repository conflicts with the listing or is unavailable` + verbatim reason + `Installed repository: unavailable (no git remote)` fact line when repository null.
- `<id> enabled.`: bound to `schema === "omasafe.report.v1" && result.enabled === true` (EnableResult main.rs:2216–2221; enabled:false paths 2345/2374/2449), else `Enable refused: <reason_codes>` + ENFORCEMENT re-fetch.
- classification: omasafe-plugin-trust/src/lib.rs:340–370 confirms `cloned/local` -> added `cloned/local` -> "Installed without git (local copy)", `built-in` -> "(shell built-in)", `unscannable` -> "Unscannable: <classification_reason>"; §3.2 vocabulary row updated to match.
- P5 Update catalog: reworded as non-destructive network fetch replacing the snapshot (main.rs:4805), manual only, no letter key, inline progress, PanelActionButton gated on `!navigationLocked`.
- Class order: rules-list.json first-appearance order verified (PX DX FS SP IN SC NW TM ...) -> §2.7 table renumbered (NW is #7), "catalog order" defined once there; CapabilityStrip/MatrixGrid use catalog order, Flow CAPABILITIES layer uses occurrence order (barycentre-adjusted).
- Node counts: moved to `bodySmall` in §2.1 (removed from the caption row) and P7 statement names Flow node counts and button labels explicitly.
- P6 Do composites: now points to 05 §9 and enumerates the full components/ list incl. FactPill, OmaSafeShield.
- P1 badge wording: "The bar shows a count in foreground; the urgent badge appears only for a critical / error alert or an enforcement block."
- Confirm buttons: Ui/ConfirmDialog.qml:97–98 fixed `space(88)` and :114 caption verified -> §2.1 row = `Style.font.body`, §2.2 = `Math.max(Style.space(88), label.implicitWidth + Style.space(28)) × space(34)`, §3.7 wireframe `[ Cancel ] [ Record ]`, table labels Record/Replace/Remove (Enable/Update/Install were already verbs).
- Placeholder vocabulary: single `–` / `·` / `unavailable` set stated in §2.4; `┄` removed from §2.7 and §2.8 and added to the never-list; checklist item added.
- Colour: kit has no luminance helper (grep empty); computed Qt.darker on latte #4c4f69 -> #323445/#262734 (heavier) and on white #000000 -> #000000 (no hierarchy at all). §2.3 now defines `dimStep(k)` mixing fg toward `Color.background` (dimHeader 0.25, dim 0.33, faint 0.55), states the divergence from PanelHero.dim, and puts catppuccin-latte + white at base 9 in Phase 1 acceptance. P9 statement updated. NOTE: I inlined `Color.background` inside dimStep rather than a `bar.background` binding because first-party panels only read `bar.foreground` (tailscale/Panel.qml:40) and the root colour-name set in decision record §12 stays unchanged.
- Severity glyphs: CORRECTION TO THE ISSUE — fontTools shows F068C is `md-skull`, not alert-octagon; `md-alert_octagon` is F0029 (`󰀩`). Used F0029. New scale: info `󰋽` · low word-only · medium `󰝥` · high `󰀦` bold · critical `󰀩` bold urgent; `󰝦` reserved for hollow Flow node. §2.4 rows + notes, §2.7 UI glyph table (ASCII `O`), glyph count 46 of 47, P9 Do updated.
- `Not analyzed. Press a or Analyze.` in §3.3 with the timing removed and reason noted.
- FactPill: §2.5 defines components/FactPill.qml from Ui/PanelHero.qml:67–87 detailPill pattern (BorderSurface + controlSpec("normal"), radius Style.cornerRadius, bodySmall dim text, PanelToolTip on parent hasCursor); P10 Do and §2.1 updated; disabled-Button-as-label explicitly banned.
- §4 checklist: added dimStep/light-theme, no `┄`, `–` sole placeholder, confirm button sizing, success-line keying, FactPill, and the new enum labels. §5 sources: added lib.rs / main.rs anchors used above.

CROSS-FILE FOLLOW-UPS (not made; other owners)
- README.md:110 "30 primitives" -> "32 exported `qs.Ui` components"; README GR6 sentence -> confirm label is the bare verb.
- 01 §1 / §2.1 already say 32 / 25 (consistent). 01 §8.3 (line 378): list all five classification values with omasafe-plugin-trust/src/lib.rs:340–370 anchor.
- 03 §2 badge wording fine; 03 §4.1 plugin rows: replace `┄┄┄ not analyzed` with `– not analyzed`; 03 §4.4 schedule row (304–306): use `Labels.schedulePolicy`; 03 §5.2: severity glyphs (critical F0029, low word-only), FactPill instead of disabled Buttons, remove "(about 0.2 s)"; 03 §5.4 (510–513): conflict label + null rows for upstream_moved / installed_matches_listing; 03 §5.5 (546–550): Update-catalog wording + success line keyed on result.enabled; 03 §10 (787 + two wireframes): verb-only confirm labels, body font, content-sized buttons, schedule policy definition line; 03 §11 remove timing; 03 §14 Contrast: dimStep decision moved to Phase 1.
- 04 §3.3 (211): conflict label; 04 §4.1 step 2 keep occurrence order but cite 02 §2.7 as the definition; 04 §4.3 countW term recomputed for bodySmall; 04 §5 / §10.2 FlowNode count Text -> Style.font.bodySmall, node glyphs `󰝦` + `–`, remove "(about 0.2 s)"; 04 §8 same; 04 §9.5 Matrix legend keep `–`/`·` (already matches); 04 §12 "PX TM WM FS DX" relabel as occurrence order or change to catalog order "PX DX FS TM WM".
- 05 Phase 1 acceptance: add catppuccin-latte + white at base 9 screenshots, `result.enabled === true` check, FactPill in §9 inventory; 05 §13 open question 3 (light-theme dim) now resolved by 02 §2.3.
- Decision record (scratchpad) §6 colour block, §7 schedule labels/confirm labels, §12 root names still describe Qt.darker / "Record baseline" / Labels.policy; update if it is to remain the binding contract.

#### 05-implementation-roadmap.md

All 15 issues applied to /home/hvo/Projects/omasafe-plugin/docs/design/05-implementation-roadmap.md via surgical edits (file 653 -> 712 lines; structure unchanged). Every replacement was verified against Panel.qml, /usr/share/omarchy/shell, cli-samples and omasafe-cli/src/main.rs before editing. No other file touched.

VERIFIED AND FIXED
1. Anchors (§1.1, §2, Sources): coverageRelation 313->320, overrideStatus 331->338 (grep: `function coverageRelation` 320, `function overrideStatus` 338); runEnable 1219->1244 (targetStillExact 1246), runReviewUpdate 1241->1269 (targetStillExact 1273, argv 1291-1295); tabs model 132-137 -> 134-139 (132 is `property int analysisRequestId`). Fate table row 1219-1268 split into 1202-1243 (beginReviewUpdate 1202 / beginEnable 1217 / applyEnableResult 1227, Phase 0 pendingAction), 1244-1268 runEnable keep verbatim, 1269-1298 runReviewUpdate keep verbatim.
2. wl-copy precedent (§9): now states first-party panels use `Quickshell.execDetached(["bash","-c","printf %s " + Util.shellQuote(value) + " | wl-copy"])` (tailscale/Service.qml:109, network/Panel.qml:450) and OmaSafe uses argv-only `Util.execArgv` (Commons/Util.qml:62). Confirmed by grep.
3. schedule install CLI ask (§12): reworded. main.rs:3465-3477 `analysis_flag` already emits `--include-analysis` for hardened; the ask is now "optionally, after confirming with the CLI owner, --include-analysis for advisory scheduled scans" with an explicit "do not file as a missing unit flag".
4. Finder acceptance (§5): index now stated as lowercase id · title · capability (rules), capability (classes), externalId (Baseline), id (plugins); counts from rules-list.json / rules-coverage.json: 2 classes, 11 rules (3 by id/title + 8 by capability process-execution), 1 Baseline id (privileged-process-control-from-shared-temp).
5. Flow chip contradiction (§1 table, §5, §6): decided "hidden until Phase 3". Phase 2 ButtonGroup is [Overview] [Rules] on keys 1 and 3, key 2 inert; Phase 3 makes the chip visible and binds 2. "Flow frame" removed from the Phase 2 row; no placeholder body.
6. Phase 0 goal (§3): reworded to "every correctness or ground-rule defect fixable without visual change": High A1-A4, A6-A10, A13, A17 plus A21 (M), A39 (L); explicitly lists the High items that land in Phases 1-2 (A5, A11, A12, A14-A16, A18-A20, A42). Added A9 as item 0.15 (one caption Text under the status row 2348-2389, visible only when inventory result.coverage.limitations[] is non-empty; on this machine it is [] so the pixel-identical screenshot claim holds). Verified: Panel.qml stores inventoryReport (14, applyInventory 962) but nothing reads coverage.limitations outside the deleted legacy block. Acceptance bullet, fate-table row 2283-2417, §5 "fields rendered for the first time", §10 inventory row and §12 CHANGELOG list updated accordingly.
7. TrustFlowWindow component list (§9): now includes InspectorStrip AND PluginDetailView with the reason (mutations exist only inside the detail sheet: TRUST BASELINE per 04 §6.1 line 379; MARKETPLACE CLAIM / ENFORCEMENT per 03).
8. Phase 1 / 2 / 3 scope and effort (§1 mermaid+table, §4, §5, §6, §11.4): Phase 1 limited to shell chrome (bar icon, hero, ButtonGroup with four options, tokens, root bindings, ConfirmSheet, cursor scaffold over scan Button + chips; tab bodies untouched) at M 2-3 d; ActionRow moved to Phase 2a (§4 files, §5 files, §9 row); row conversion written once in Phase 2 at M 5-6 d with the keyboard-row acceptance bullet moved there; Phase 3 split into 3a (smoke test, FlowLayout.js, TrustFlow/FlowNode/EdgeLayer, FlowView Graph lens, InspectorStrip, chip visible) and 3b (MatrixGrid, TraceChain, a/A queue, m c t x ? keys) at L 8-12 d. Added the assumption line (one QML-fluent engineer, full time, fixture shim from Phase 0; Phases 0-4 = 18-26 working days). §11.4 keyboard script now states which targets/digits apply per phase.
9. Panel.qml size (§2, §9): now ≈ 2 900-3 100 lines with the arithmetic (5174 - 950 - ~1210 - ~160 - ~130 ≈ 2720 + cursor model/depth stacks/vm/pendingAction/rulesListProcess ~80); notes the 15 Process blocks (~1360 lines, 3815-5173) stay by §1.1 and adds open question 8 for a Collectors.qml QtObject that would require amending the never-changes rule. Note: the issue text said "16 Process blocks"; grep `^  Process {` counts 15 today (rulesListProcess makes 16 after Phase 2), so the file keeps "15 + 1".
10. Phase 5 IPC (§8, §12): verified shell.qml hide 480-494 and isPluginOpen 497 (hence toggle 510) also switch to the loader path when isBarWidgetPanelPlugin is false. Risk paragraph now documents summon, toggle and hide as window-only after Phase 5, popup reached by bar icon and dismissed by Esc/outside-click; acceptance adds `shell hide` closing the window and leaving an open popup untouched; README IPC note in §12 updated to summon|toggle|hide.

CROSS-FILE FOLLOW-UPS (not made; other owners)
- 03-ui-overhaul-proposal.md §10 invariant 8 (line 883) and its Sources line 1095: change targetStillExact anchors 1219, 1241 -> 1244 (1246), 1269 (1273). 03:718 finder index says "45 rule ids + titles"; 05 now indexes id · title · capability (needed to reach 11 rules) — 03 should add capability or 05's count reverts to 3. 03 §8 copy-action sentence also cites "first-party precedent tailscale/Service.qml:109, network/Panel.qml:450" for Util.execArgv — same precedent correction as §9 here.
- 01-research-and-audit.md §10 row for 05: Phase 0 list "A1-A4, A6-A9, A13, A17, A21, A39" omits A10 (item 0.14, the 2453 "verified" copy); should read A1-A4, A6-A10, A13, A17, A21, A39. A9 is now genuinely in Phase 0 (0.15), so that part is consistent.
- 04-trust-graph-spec.md §10.1 (line 694) TrustFlowWindow component list lacks PluginDetailView; add it to match 05 §9 (or drop ConfirmSheet from the window).
- decision-record.md (scratchpad, not a deliverable) still carries 1219/1241 anchors, Panel.qml ≈ 2 000 lines, Phase 1 3-4 d / Phase 3 5-6 d, and a Phase 5 component list without InspectorStrip; update if it is republished. docs/design/README.md and 01-04 contain no effort or size figures (grep confirmed), so no further drift there.
- 03 and 02 schedule confirm copy ("hardened adds analysis") is correct against main.rs:3465-3477; no change needed.

ISSUE TEXT CORRECTIONS
- None of the listed issues was wrong. Minor: the feasibility issue counted 16 Process blocks; the file today has 15 (the 16th is the Phase 2 rulesListProcess).

#### 03-ui-overhaul-proposal.md

All 38 listed issues were applied to docs/design/03-ui-overhaul-proposal.md with surgical Edits (structure and section numbering kept; all 377 wireframe frame lines re-measured at 52 columns). Every replacement fact was re-verified against source before editing: Panel.qml 1183–1194 (updateEligible accepts ["unchanged","clean","acknowledged"] + analysisDigestFor), 1244–1246 / 1269–1273 (targetStillExact), 2478 ("Current digest"); Ui/Toggle.qml 35/39/45/46/55, Ui/ToggleSwitch.qml 34/87–98 (120 ms), network/Panel.qml:1143 precedent; Ui/BarIconButton.qml 20–21/32/43, Ui/WidgetButton.qml:68, Ui/BarIndicator.qml:49, Style.qml:347 statusSlot=21; Ui/ConfirmDialog.qml 23–38 and 119–121 (onEntered sets selectedIndex); Ui/PanelKeyCatcher.qml 71–74; Ui/PanelHero.qml:54; Ui/Button.qml:131; enforcement.rs 381–404 (no recovery field; enforcement_policy_identity: String exists, used for the new ENFORCEMENT header value); equivalence.rs 3–8/22/23; analyze-lgse.sandman.json process-execution sites 142/156/169/182 (158 only in limitation codes); rules-list.json titles; U+F099F present in JetBrainsMonoNerdFont-Regular.ttf (fontTools).

Adjustments to the stated FIXes, because source contradicted them:
1. Ineligible-verb buttons: the FIX said the kit Button tooltip is "shown on hasCursor". It is not — Ui/Button.qml:131 shows the tooltip only on mouseArea.containsMouse. The doc therefore keeps the dim disabled Button with tooltipText AND has ActionRow print the same condition as one caption line under the row while the disabled button hasCursor (§5.1, §5.4). The permanent sentences are gone.
2. Baseline V3 tooltip `verified_at_utc <ISO>`: the field exists on EquivalenceMap (equivalence.rs:23) but `rules coverage` output has no such key (verified in rules-coverage.json). Worded as "once rules coverage emits it" and listed as a CLI ask.
3. Finder 'proc': real result is PLUGINS 0 · CAPABILITIES 2 · RULES 3 (ids+titles; oma.python.reverse-shell matches via its title "Python script wires a socket to a process") · BASELINE V3 1. Groups with zero matches are omitted rather than printing a 0.
4. review-update 'partial': dropped from the eligibility text (not added to code); rationale stated.
5. Finder class destination: chose 04's binding (Flow Matrix lens, cursor on the class column) and mirrored it in 03 §8 and §13.
6. §12.2: routed back through the detail sheet with `h` (as §5.2 already defines for [Open rule]) then `2`.
7. Backups row: chose CursorSurface + ToggleSwitch { interactive: false } over the kit Toggle (54 px floor, space(240), subtitle bold, activeFocusOnTab, 100 ms animation all documented as the reasons).
8. Shell tree: fixed part = hero, status line, NoticeRows, ButtonGroup, FinderField, Breadcrumb; Flickable holds only the view Loader (Overview footer inside the view). fittedContentHeight(fixed + space(12) + viewImplicit, space(560)); Flickable.interactive gated on sheet.opened only.

Cross-file follow-ups (NOT made; other owners):
- 02-design-principles.md: §3.3 hero titles — failed scan always `Scan unavailable`, add meta fragments `SHOWING <n> ALERTS FROM <relative>` / `EARLIER RESULT: NO ALERTS · <relative>`; §3.5 dash rule ("– only while zero plugins analyzed; once n ≥ 1 print the measured value") and header string `checked against marketplace commit 964dc08`; §3.5 ineligible sentence add "an analysis of the installed source (press a)" and drop 'partial'; §3.6 trust-word tooltip no longer carries the baseline definition (caveat printed only in ConfirmSheet body + Overview footer); §3.7 review-update variant labels `Current tree` / `Current digest` under `Installed now`; §2.7 glyph table add outline shield `󰦟` U+F099F with ASCII `(s)`, and ToggleSwitch stand-in; §2.8 short form `<n> items` and record the measured 17-glyph strip implicitWidth at base 12; §12 consistency strings: `TRUST BASELINE` (no right value), `ENFORCEMENT | ADVISORY/HARDENED/NO DECISION`, `REVIEW ITEMS | <n>` (count only), retire `FILES AND EDGES | <n> EDGES`; P8 row-height claim now holds (no kit Toggle row).
- 04-trust-graph-spec.md: §9.6 and §12 acceptance — drop `4 of 4` / `0 of 4` per-baseline counts, use `observed in / not observed in <n> analyzed plugins` inside the expanded row only; §9.6/§12 header `checked against marketplace commit 964dc08`; §9.5 Matrix inspector `no review items in analyzed files · 8 not analyzable`; §8 first row → "view chips enabled; lens chips disabled; body is the NoticeRow"; §4.3 size the graph to the Flickable height (viewport), not the column; §13 open point on Z0 pinned class: resolved as Matrix column (03 now matches §6.1); §9.4 owns file-reference chains (03 folds FILES AND EDGES into COVERAGE).
- 05-implementation-roadmap.md: §4 ConfirmSheet wiring — activation on activateRequested only, swallowNextActivate redefined (same-turn guard), isAutoRepeat Enter/Return/Space ignored + 300 ms window, hover routed through PointerMoveGate, card height cap with scrolling middle, extended handleKey; acceptance: hold-Enter-with-parked-pointer test, quiet-run-then-failing-scan prints no `No outstanding alerts`, ScrollBar.vertical + ensureCursorVisible on the Flickable, bar widget implicitWidth growth (top and vertical bar), `grep -rn activeFocusOnTab` empty, `· <n> limits` on plugin rows, 768-px/base-20 confirm card in §11.3; §9 component inventory: BarWidget.qml gains the Row (BarIconButton + count Text), Toggle → ToggleSwitch row, EdgeRow now under COVERAGE; fate table row 1300–1308 (fixed part + Flickable body); Phase 2 "nine sections incl. FILES AND EDGES" → seven visible + PROVENANCE; §12 CLI asks: `recovery`/`next_step` on EnforcementDecision, `verified_at_utc` in `rules coverage` output.
- README.md: 'three authority sections' strings (`TRUST BASELINE | LOCAL`, `ENFORCEMENT | POLICY`), 'result at a glance' mermaid (FILES AND EDGES node; section order; hero pill `cli 0.2.1`).
- 01-research-and-audit.md: §2.4/§2.7 already cite 1244–1246/1269–1273 correctly; no change needed.
- decision-record.md (scratchpad): §3 IA tree, §7 header strings, §8 invariant 8 anchors (1219, 1241) and G12/R17 (kit Toggle) are now superseded by the above.

#### 04-trust-graph-spec.md

All 21 issues verified against source before editing; all applied in 04 only (docs/design/ is untracked in git, so `git diff` shows nothing — the file is edited in place, 1170 lines, fences balanced, every ASCII frame 52 columns).

VERIFIED FACTS (samples / source): analyze-lgse.sandman.json coverage_limitations = 5 `absolute` (lines 144/158/171/213/239) + 8 `missing-local-target`; process-execution sites LidService.qml 142,156,169,182,211,237,252,263,265 then Service.qml 250,267,281,293,366,377,383; inventory marketplace: omasafe `status: conflict`, `registry_claim: null`; sandman `status: listed`, `verification_status: verified`; `marketplace_age_seconds` 935; rules-coverage 12 distinct externalIds, 3 not_covered; per-plugin plugin→class edges btop 5, dropdown 4, omasafe 2 (+1 review-only), sandman 4 = 16; RULES hits 49/45/14/10/8/4. omasafe-marketplace/src/lib.rs:338–411 `correlate()` computes `status` locally. Panel.qml: 77–78 statusQueue/statusSweepGeneration, 602–622 runNextPluginStatus, 109–116 single-slot analysis state, 1096 ensureAnalysis, 4692–4707 startFor() = single nextPluginId slot + preemption (no queue). Ui/KeyboardPanel.qml:159 verticalContentInset, 168–173 fittedContentHeight. Style: popupRowHeight 28, popupPadding 14, caption 10 / bodySmall 11 at base 12.

FIXES APPLIED (by section):
- §2.1 layers table: RULES count = "local hits" (occurrences + review items, one labelled quantity, inspector splits it); RULES/BASELINE open columns drop the fixed layer glyph (rail form only); CAPABILITIES `ElideRight`; BASELINE mark in count slot, not-covered = no mark + dim label; marketplace prose now separates `Labels.marketplaceStatus(status)` (unprefixed) from `Catalog says: <verification_status>`. Class node "second count line" removed (rows are single-height).
- §2.1 mermaid + §2.2: class→baseline skip edges removed; encoded as via-class glyph on the BASELINE node + class node hot set + inspector `via class …`.
- §3.1/§6.1/§8/§10.1/§11: "existing analysisProcess queue" replaced by an explicit new root work item: `analysisQueue`, `analysisSweepGeneration`, `analysisStateById`, `startNextAnalysis()` on onExited, cancel on `x`/close/gate loss, startFor() preemption kept only for the selected-plugin path (table in §10.1).
- §3.2 shapes: `skip: true` edge removed; `hits` added; output split into stable `nodes` (assigned only when `membershipKey` changes) + `geometry` + `paths` + `hotSets`.
- §3.3: sandman inspector line → `Listed in catalog snapshot · Catalog says: verified · snapshot 65b6385, 15 min old`; omasafe → `Catalog entry conflicts with the installed repository · Catalog says: not stated · …`; limitation split 5 absolute / 8 missing; Z0 totals recomputed (16 / 6 / 1 edges).
- §4.1: maxRows derived from remaining height (10 at base 12 with no notice, 9 with one, 7 at Z1 with breadcrumb+notice, 5 on 768 px @ base 20); shared window `rows = min(maxRows, max over four columns)`; Z1 baseline set = reach only; `pairGutter = space(72)`, `railGutter = space(12)`, `openW = 118`; Bézier control points at thirds; no skip edges; ensureCursorVisible mandatory.
- §4.2 pseudocode updated accordingly (rows, gutters, thirds, membershipKey, hotSets, slide()/moveWindow() note); `hot()` returns paths + hotKeys.
- §4.3: widths table (railW 28 · pairGutter 72 · railGutter 12 · openW 118; labels 11 / 7 / 8-or-12) + new heights table incl. Column gaps and KeyboardPanel inset; old "≈ 546" sum called out as wrong (≈ 640 real); hero+chips-outside-Flickable option stated; window colW → 206.
- §5: count font `bodySmall`; Marketplace row rewritten; relation row (no dash for not-covered, via-class glyph); limitation suffix bodySmall; filter row → header value `… · HIDING 7 BACKUPS`, no `NOT ANALYZED` fragment; legend in words (no `—`/`=`/`≡` mimicry).
- §6.1: hover tooltip = one TrustFlow-level PanelToolTip, pointer only; wheel = column-level MouseArea in TrustFlow; `a` never changes selection. §6.2 moveCursorH uses stable nodes, `trustFlow.paths` (no `edgeLayer.paths` shadowing), geometry-only slides; sequence diagram shows queue.
- §7/§8: Z0 header value carries HIDING fragment; stale row example; `+3 more`/`+36 more`.
- §9: stand-in legend (`x` removed, `≈` mark, `PX~` rows, caption-vs-cell note); 9.1/9.2/9.3 redrawn with 72-unit lane, elided 11/7/11-char labels, R10 above R 8 (tie key), BASELINE 9 + `+3` at Z0, Z1 exactly 6 reachable ids with no `+N`; lens row right slot `?` and header value `… · HID…` (matches 03 §6); 9.4 evidence rows 142/156/169/Service.qml:250, limits 5/8, chain line 3 "via class" in words; 9.5 header/lens row; 9.6 `≈` marks and markless `not covered` rows.
- §10.2: FlowNode count `bodySmall`, no PanelToolTip, no onWheel, `faint` property; TrustFlow sketch with `nodes`/`geometry`/`paths`/`hotKeys`/`hoverKey`, `Repeater { model: 4 }`, per-column wheel MouseArea, single PanelToolTip; binding-discipline paragraph updated.
- §11: 23 real edges; node budget by stable arrays; slide/window rows; analyses row.
- §12: offscreen `qml -platform offscreen` instantiation recorded; counts 16/6/1/0 edges; `+3`/`+4` by notice state; RULES hits + inspector split; label-width check; Z1 6 ids no `+N`; Z2 5/8 and 142/156/169; header/lens check; no-delegate-recreation, tooltip, wheel, queue, `a`-selection invariants; marketplace_stale wording.
- §13: openW 118 consequences and the two remaining levers; `space(72)` contract addition; `x` dual role flagged; skip-edge render risk removed. Sources: Panel.qml queue anchors, lib.rs:338–411, offscreen probe result.

DEVIATIONS FROM THE SUGGESTED FIX TEXT (deliberate, stated in the doc):
- Age printed as `15 min old` (935 s floors to 15; 03 §3 uses 15 min) rather than the "16 min" in the ground-rules fix.
- Z1 BASELINE rail: neither "5 + `+7`" nor "6 + `+6`"; §2.3/§4.1 already define Z1 as the plugin's reach, so the column holds exactly 6 ids and no `+N` row. §9.3 and §12 now agree on that.
- Z0 BASELINE `+4`: kept only for the one-notice case; the drawn no-notice frame shows 9 + `+3` because the shared window is 10 rows there.
- Not-covered word: `not covered` cannot share a 118-px row with a label (73 px word), so in the popup it is inspector line 1 + legend, printed in the count slot only in the Phase 5 window and in the Rules-view coverage table; same rule applied to `unavailable`.
- Baseline via-class glyph goes in the glyph slot with the `≈` mark right-aligned in the count slot (`󰆍 installer ≈`), not `󰆍 ≈ installer`, to reuse the count-slot mechanism.
- RULES review items: adopted the "one labelled quantity" route (local hits, split in the inspector) instead of a suffix or two-glyph form, because `· 10 review items` cannot fit an 11-char column and `!` text glyphs are forbidden.
- Open RULES column drops `󰧮` (was a §13 open point; now decided because of the 118-px budget). `oma.q…ution` collides for process-execution / detached-execution — recorded in §13 with inspector line 1 as the resolver.
- Label capacity is 11 / 7 / 8(12), not the suggested "12 / 8" (that pair assumed openW 130).

CROSS-FILE FOLLOW-UPS (not done, other owners):
- README.md GR2 (line 35), 02 P2 (line 54) and 02 checklist (line 638): narrow "every catalog value is prefixed Catalog says:" to registry_claim.* only; correlation `status` uses `Labels.marketplaceStatus` unprefixed.
- 02 §3.4 limitation-code row (line 543): `8 sink references rejected (absolute) · 5 missing local target` → `5 … · 8 …`.
- 03 §5.2 expanded class row (line 381): `LidService.qml:158` → `:156`.
- 02 §2.1 type table (line 259): remove "node counts" from the caption row, add to bodySmall.
- 02 §2.4 (line 325) and Labels.js: drop the `—` relation glyph for not-covered (no mark; word `not covered`).
- 02 §3.5 and 03 §6 (line 583): `HIDING 7 BACKUPS · 4 NOT ANALYZED` → `HIDING 7 BACKUPS`, and 03 §6 "in the header meta" → "appended to the section header value".
- 03 §6 frame (line 569) "height cap Style.space(360)" → derived body height (04 §4.1 step 4); 03 §3 decide whether hero + view chips are pinned outside the Flickable.
- 03 §13 key map and decision record §8: `x` also drops the remaining `A` sweep (or reject and remove from 04 §6.1).
- 05 Phase 3 (line 52, 98) and open question 5: replace "a/A queue" / "existing queue" with the new root queue work item; add ~1 day; detail-sheet Analyze button also depends on it.
- 05 §6 / record §5 Rendering: "≤ 52 node items" → stable arrays with `visible:false` outside the window (31 here, ≤ 89 bound).
- Decision record §5 (gutter space(24), height cap space(360), ≈ 25 real) and §12 spacing set: add `space(72)`, drop `space(360)` from the graph, edges 23 real; §6 type roles: node counts bodySmall.
- README status line (line 90): may now say the EdgeLayer bucket pattern also instantiates under `qml -platform offscreen` (Qt 6.11.2, exit 0).

### 5.2 Round 2 fixer notes

#### 05-implementation-roadmap.md

All three issues verified against source and fixed in 05-implementation-roadmap.md only.

1. [medium/api-truth] §9 closing paragraph (now lines 563-568). Verified `Commons/Util.qml:62-64`: `execArgv(argv)` = `Quickshell.execDetached(["bash", "-lc", 'exec "$@"', "bash"].concat(argv))`. Reworded to state that a login bash IS spawned and the value lands in a positional parameter (never interpolated / re-tokenised), that the self-report occurrence is therefore the same `detached-process-execution` class as the first-party `bash -c ... | wl-copy` idiom, and that the shell-free alternative is `Quickshell.execDetached(["wl-copy", "--", value])` at the cost of the login-shell PATH the kit helper exists to preserve (per the Util.qml comment). Kept `execArgv` as the chosen call; the "argv-only ... no shell is involved" claim is removed.
   CROSS-FILE FOLLOW-UP (not made): 03-ui-overhaul-proposal.md:481 (§5.1 TRUST BASELINE copy button) and :1349 cite the same `Util.execArgv` call; if either describes it as shell-free, apply the same rewording there.

2. [low/completeness] §12 CLI asks (line 704): "doc 02 §7" -> "doc 02 §3.7". Verified 02-design-principles.md has §1-§5 only and the "hardened adds analysis" schedule confirm copy is at line 695 inside §3.7 Confirmation template.

3. [low/completeness] §6 Phase 3 acceptance (lines 422-427 and 436-440).
   (a) Replaced "12 Baseline ids (3 edgeless)" with an exact breakdown verified against cli-samples/rules-coverage.json (12 distinct externalIds, 15 rows) and 04 §3.3/§2.2/§12: 3 markless not-covered (cargo-git-unpinned, remote-build, remote-git-execution-unpinned); 5 with a via-class glyph (installer, package-manager, privilege, sudoers-modification under the process-execution glyph; service-management under persistence-scheduling); 1 with an incoming dashed edge (oma.qml.process-execution -> curl-pipe-shell); 3 marked `≈` with neither edge nor glyph (bundled-executable-binary and privileged-process-control-from-shared-temp note-only rows, plus sudoers-dangerous-passwordless-command whose two rules have no local hits); class -> baseline edges 0. Note the issue's suggested wording summed to 9 of 12; the remaining 3 are now accounted for so the check is complete.
   (b) Took the drop option (the alternative required editing 04 §9.4, another file): removed "renders the map note verbatim" and replaced it with the three-line TraceChain check from 04 §9.4, concrete counts from the fixture (EVIDENCE | 16 ROWS, FILE EDGES | 5, COVERAGE LIMITS ON THIS PATH | 13), and an explicit statement that the map note is rendered verbatim only in the Baseline V3 coverage table (04 §9.6, 03 §7.2), reached via Enter on the chain's baseline id.

No other text in the file was changed; structure preserved.

#### README.md

All three issues verified against source and fixed in README.md only (surgical replacements, structure kept).

1. Mutating commands (§Sources, last bullet). Verified in Panel.qml: trust argv 571–574 (includes `--note "trusted from OmaSafe panel"`), untrust 593–597 (includes `--reason "untrusted from OmaSafe panel"`), `schedule install --policy` 910, `plugins enable ... --format json` 1260–1263, `plugins review-update ... --expected-commit ... --policy ... --yes` 1291–1295, `marketplace refresh --latest` 3927. README now lists all six with full argv shapes and anchors, notes that marketplace refresh is the only one unconfirmed today (matches 01 §2.4 "Update catalog | none"), and cites 01 §2.4 and 05 §10.

2. Thesis framing (line 43). Reworded to "states what the last scan left outstanding (...)" and added an explicit clause that the user's "am I okay" is the question the panel deliberately does not answer (GR1).

3. Decision record. README now: says "Seven Markdown files" / "six numbered documents" (line 3, 20), explains why the decision record is committed (G/R anchors in 01–04), adds a row for 06-decision-record.md in §Documents (512 lines, verified `wc -l`; G1–G27 = 27 rows, R1–R24 = 24 rows verified), adds a "Resolving a G<n>/R<n> citation" bullet in §How to read pointing to 06 §2/§11/§12, and moves the decision record from the scratchpad list into a new "Committed with this folder" list in §Sources.

CROSS-FILE FOLLOW-UPS (not done; README now presupposes them):
- Create /home/hvo/Projects/omasafe-plugin/docs/design/06-decision-record.md as a verbatim copy of /tmp/claude-1000/-home-hvo-Projects-omasafe-plugin/5147ee75-1bd3-428a-bf49-cffcc0cb46ab/scratchpad/decision-record.md (512 lines, contains no scratchpad path references, so it copies clean). Until this exists, README links to 06 dangle. Note docs/design/ is currently untracked in git (`??`), so nothing in the folder is committed yet.
- 01-research-and-audit.md line 177 (A20): "Level-1 information (am I okay, which plugins, what next)" frames level-1 content as answering the safety question; reword to keep "am I okay" as the persona's question the panel does not answer. Line 34 (§1 persona) is fine as a persona description but could add the same clause.
- 01-research-and-audit.md §2.4 last paragraph cites the untrust argv as "590–595"; the argv is at 593–597 (function `untrustSelectedPlugin` starts at 585). Also 01 §2.4 omits `--reason "untrusted from OmaSafe panel"` in the untrust shape and elides review-update argv as "…"; 05 §10 has both correct.
- 04-trust-graph-spec.md cites R45 and R49, which do not exist in the decision record (R1–R24 only); check whether those are typos or refer to something else.

#### 01-research-and-audit.md

All five issues verified against source and fixed in 01-research-and-audit.md only (surgical string replacements; structure unchanged; file is untracked in git so no diff is shown by `git diff`).

Fixes applied in 01:
1. hostWidget Connections range (§2.1 line 60, §2.6 line 135): 3792–3813 → 3784–3813; now lists `onCliVerifiedChanged` 3788 (inventory/schedule/override loads + `ensureCoverage`), `onCliVersionChanged` 3796, `onAlertsChanged` 3808. Verified: Panel.qml:3784 `Connections {`, 3785 `target: root.hostWidget`, 3788 `function onCliVerifiedChanged()`.
2. T12 (§5 line 270): 2295 → 2298. Verified: Panel.qml:2295 is `required property var modelData`; 2298 is `height: Style.space(28)`; 2335 `width: Style.space(64)` kept.
3. Destructive buttons row (§4 line 237): replaced "network forget 1745 idiom" with a citation of `Ui/PanelActionButton.qml:6–9` (documented urgent mode) and property at line 33; states no first-party panel sets `hoverColor` (grep confirms) and that network/Panel.qml:1745 is only the urgent-tint-on-forget precedent for a `Text` glyph. Also tightened the binding to `hoverColor: root.bar.urgent` to match the component's documented mode.
4. `time_budget_exhausted` (§8.3 line 383): removed the false "exists only in enforcement.rs tests and is never emitted" claim; added `time_budget_exhausted` to the bare-code list with `ingest.rs:142, 294, 874`, and documented the path `note()` (ingest.rs:130–138) → `finish()` (ingest.rs:148–157) → `PayloadInventory.limitations` → `plugins analyze` copies into `coverage_limitations` (main.rs:5451). All line numbers re-verified in /home/hvo/Projects/omasafe/crates.
5. Held-Enter mechanism (§9.6 line 526): replaced "swallowed by `swallowNextActivate` (G7)" with the correct mechanism — `ConfirmSheet.Keys.onPressed` drops `isAutoRepeat` Return/Enter/Space and ignores non-repeat Return/Enter for 300 ms after open, pointer to 03 §10 invariant 2 and 05 §4; `swallowNextActivate` (G7) kept and described only as the same-event-loop-turn double-delivery guard.

No issue was found to be wrong; none left unedited.

Cross-file follow-ups (NOT made; other owners):
- 05-implementation-roadmap.md §2 fate table line 118: "3792–3813 | `hostWidget` `Connections`" → 3784–3813, add `onCliVerifiedChanged` (3788) to the row; also line 723 lists "3792–3813" in the preserved-ranges sentence → 3784–3813.
- 02-design-principles.md §3.4 line 608: add `time_budget_exhausted` to the known bare-code group (alongside `analysis_time_budget_exhausted`, `file_limit_exceeded`, ...).
- 03-ui-overhaul-proposal.md §5.3 bare-code list: add `time_budget_exhausted`; the `Labels.js` limitation parser spec must include it in the known bare-code set so the "anything else → verbatim + unsupported limitation" fallback does not label a real CLI code as unsupported.
- 02-design-principles.md P5 Do (line 121) and Review checklist (line 728): replace "`swallowNextActivate` on open" as the held-key protection with a pointer to 03 §10 invariant 2 (auto-repeat drop + 300 ms window in `ConfirmSheet.Keys.onPressed`); keep `swallowNextActivate` only as the double-delivery guard.

#### 02-design-principles.md

All twelve issues verified against source before editing (fontTools cmap on /usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf; Ui/ConfirmDialog.qml:96-99; omasafe-cli/src/main.rs:4649, 5404-5411, 5457-5459, 5470-5473; omasafe-plugin-trust/src/lib.rs:353-359; cli-samples/inventory.json first_party values). Every issue was correct; none left unfixed.

EDITS MADE IN 02-design-principles.md
- §2.7 intro: fontTools check now asserts codepoint AND glyph name (cmap[0xF0483]=='md-security', cmap[0xF0499]=='md-shield_outline', cmap[0xF1513]=='md-dock_top', cmap[0xF120E]=='md-archive_outline', cmap[0xF0029]=='md-alert_octagon'); Glyphs.js carries the expected name per row; "no ASCII character is assigned to two meanings".
- §2.7 UI glyphs: outline shield F099F (md-set_top_box) -> U+F0499 `󰒙` md-shield_outline; filled shield kept at F0483 md-security (tailscale kinship, decision record binding). backup copy F0053 -> U+F120E `󱈎` md-archive_outline (chosen over F006F md-backup_restore because that shares the circular-arrow shape of rescan 󰑐). In-flight ASCII fallback `~` -> `/` (spinner idiom; avoided `%` because the §4 blocker greps for percentages). Added a note paragraph stating the rejected codepoints and their real names.
- §2.7 class table row 16: F10A2 (md-decimal_comma) -> U+F1513 `󱔓` md-dock_top (bar sits at the top edge), with a note line.
- §2.7 Text glyphs ASCII fallback line: `~` scoped to ≈ only.
- §2.2: closed set replaced with rule ("any Style.space(n) or Style.spacing.*; never a bare pixel literal") plus the bound set {1,2,3,4,6,8,10,12,14,18,20,22,28,32,34,44,72,88,190,370,400,420,560} + {600,1080} Phase 5 only, declared preferred not closed. Covers both spacing issues.
- §2.2 Confirm card: cite ConfirmDialog.qml:98 (width space(88)) and :99 (height space(34)).
- §3.3: `(stale)` keyed solely on result.marketplace_stale; Time.js formats ages and decides nothing; CLI threshold cited at main.rs:4649.
- P3 review test: added marketplace_stale:false + 40-day age -> no `(stale)`, "verified" not suppressed.
- §3.2 vocabulary + §3.4 classification: `built-in` -> "Installed without git" (no parenthesis); added `first_party` row: First-party: yes / no / not stated (null on backups); lib.rs cite corrected to 353-359; fixture facts stated.
- §3.4 marketplace status: installed-differs -> "Listed; installed commit is not the listed commit" (short: "Listed; not at listed commit"); installed_matches_listing true/false -> "Installed commit is the listed commit" / "Installed commit is not the listed commit"; note that matches/differs never appear in marketplace labels.
- P2 review test: catalog word list gains `listed commit`; test also fails on any MARKETPLACE CLAIM string containing matches/differs.
- §3.4 limitation code: fourth grammar `<code>:<value>` (suppressions-unreadable:<error text> with colons allowed in value, suppression-reconfirmation-required:<n>, equivalence-map-stale:map-v<x>-observed-v<y>) rendered as group "Suppressions and equivalence map" with value verbatim; parser matches known prefixes of (2)(3)(4) before falling back to file grammar (1); main.rs lines cited.
- §5 sources: fontTools line updated to codepoint + glyph-name verification and the three replacements.
- PLUGINS footer (issue 10): 02 is the copy authority; left unchanged. Fix belongs in 03.

CROSS-FILE FOLLOW-UPS (not made; other owners)
- 03 §1 Conventions `(s)`, 03 §2 bar table/code (lines ~36-37, 103-104, 132, 136), 03 §3 hero glyph rule (~187), 05 §9 OmaSafeShield row (line 522): replace `󰦟` U+F099F with `󰒙` U+F0499 md-shield_outline; drop "re-checked with fontTools" presence-only claim or restate it as a name check.
- 04 §5 glyph list `… 󰌘 󱂢 󰍛`: replace `󱂢` with `󱔓` (F1513).
- decision-record.md lines 222-230 list F099F-free shield but F0053 backup and F10A2 replaces-bar-context; update to F120E and F1513, and line 265 "(stale) at ≥ 30 days", line 474 closed space set.
- 03 §10 confirm chrome range cite (96-130) is still valid; no change needed there.
- 01 §8.3 `plugins analyze` row and 03 §5.3 COVERAGE: add the fourth grammar codes (suppressions-unreadable, suppression-reconfirmation-required, equivalence-map-stale) and the prefix-first parse order.
- 01 §8.3 "`built-in` = no git ... and is not first-party": reword to "`first_party` may be true or false; both fixture plugins report false".
- 03 §5.4 wireframe (line ~619) and prose (~650-657): change "installed commit differs from the listing" / "matches the listing" to the new "is / is not the listed commit" strings; add the strings to P2 review-test word lists wherever 03/05 repeat them.
- 05 §9 line 548 `model/Time.js` responsibility: delete "stale threshold" (Time.js formats ages only); 03 §4.4, 03 §11, 04 §8 already key on marketplace_stale — no change expected but re-check for "30 days".
- 03 §4.1 wireframe (line 262) and callout (line 323): replace "Baseline = the exact source identity you recorded. Matches / differs is a comparison, not a judgment." with the 02 §3.3 sentence "A baseline is the exact source identity you recorded. "Matches" and "differs" compare the installed files against it; neither is a safety judgment." (05 Phase 2 acceptance checks for the 02 sentence).
- 04 §9 rails use `~` for ≈ — consistent with the fix; the Glyphs.js description in 04/05 should record in-flight fallback `/`.

OBSERVATIONS OUTSIDE THE ISSUE LIST (not acted on)
- §3.5 ineligible-verb copy "Review update needs: catalog status listed or installed-differs …" prints the raw enum `installed-differs` in UI copy, putting "listed" and "differs" on one row; it fails the P2 review test as now sharpened. Same string in 03 §5.4 and 03 §5.3 line ~670. Suggest "catalog status listed (at or off the listed commit)".
- F0483 md-security is the MDI shield-with-check; P1 bans the check glyph as a state mark. It is the tailscale kit glyph and binding in the decision record, so left as is, but worth a conscious decision (md-shield F0498 is the check-free pair of F0499).
- docs/design/ is untracked in git (git status shows `?? docs/design/`), so `git diff` shows nothing for these edits.

#### 04-trust-graph-spec.md

All five issues verified against source and fixed in 04 only (surgical Edit calls; structure kept; file grew 1187 -> 1263 lines). Every wireframe line in §9 re-checked at exactly 52 columns.

1. api-truth (§6.1 `?`/`g` row, line 447). Verified: shell.qml:631 injects `manifest` only into panel-loader items; Ui/BarWidget.qml:15-17 gives widgets `bar`/`moduleName`/`settings`; plugins/bar/Bar.qml:1770 injects `moduleName`; Commons/Util.qml:70 `canonicalWidgetId` is the identity so the widget's moduleName == registry key == `manifest.id` (shell.qml:678); our Panel.qml:9 and BarWidget.qml:8 hardcode `moduleName: "io.github.tuthan.omasafe"` and Ui/Panel.qml:13 declares the property. Fix: row now reads `bar.shell.summon(root.moduleName, JSON.stringify(payload))` with the provenance chain and the statement that `manifest.id` is used solely inside TrustFlowWindow.qml; network/Panel.qml:468 literal-id precedent cited. Sources section (line ~1252) gained the shell.qml:631/678, Bar.qml:1770, BarWidget.qml:15-17, Panel.qml:13, Util.qml:70 anchors.

2. data-truth (§9.1 PLUGINS order). Verified against scan.json: alerts on ilyazar.btop, io.github.hvo.omarchy-unraid, io.github.tuthan.omasafe (outstanding 3). Redrew §9.1 rows in key order btop, omasafe, omarchy-unraid, dropdown-terminal, sandman, crmne, ianswope, lunar-calendar with `!` marks and a re-fanned edge lane (btop 5 med edges, omasafe 2 thick + 1 dashed, dropdown 4, sandman 4); callout now states the order derivation and that the PLUGINS layer is not barycentre-adjusted, cursor on row 2 (omasafe) so the inspector text is unchanged. Also redrew the §9.2 PL rail (`*27 *54 o *10 *29 o o o`) for consistency and noted it in its callout.

3. ground-rules (`–` for a measured zero). Fixed §2.1 RULES row (line 56), §9.2 inspector line (`45 occurrences · no revie…`), the §9.2 callout (now explains measured zero = `no review items`, `–` reserved for zero plugins analyzed, per 02 §2.4/§3.5), §12 acceptance bullet (`45 occurrences · no review items`), and added an honesty-fixture check: "an analyzed rule with zero review items never prints `–`; with the cache emptied the slot prints `–`; `0` never appears in a review-item slot."

4. completeness (Z1 breadcrumb). Chose option A: §7 Z1 row now `󰅁 All plugins` (with the 03 §8 reason), §9.3 first line redrawn `[<] All plugins`, callout explains depth-1 back-only and that the header `TRUST FLOW · lgse.sandman` carries the name because the hero does not swap at Z1. §9.4 (depth 2, full path) untouched. 03 §8 needs no amendment.

5. completeness (undrawn states). Added §9.7 "Z0 Atlas — inventory ready, zero analyses" (full 52-col frame: all 8 nodes hollow `o –` in key order, CAPABILITIES one dim `not analyzed` row, RU/BA rails `–`, header `0 OF 8 ANALYZED · HIDING 7 BACKUPS`, 8-row window, inspector `Analyze (a)` button + `Not analyzed. Press a or Analyze; A analyzes all.` + btop's real trust/catalog facts from status-ilyazar.btop.json and inventory.json) and §9.8 "Flow states drawn by delta" with one-paragraph deltas for lexical-only (NoticeRow, 9-row window, all lanes `.`), CLI-unavailable (one NoticeRow replaces header/lens/columns/inspector), text-only fallback (`TRUST FLOW · MATRIX` header, lens row hidden, `?` moves to the header slot — this placement is my proposal, flag if the owner prefers otherwise) and in-flight/failed.

Observations not in the issue list (left as-is in 04, for the owner): (a) §4.1 step 1 says the Z0 BASELINE set is all 12 externalIds from `rules coverage` regardless of analyses, while §8 (and now §9.7, which follows §8) collapses BASELINE to one dim rail row when zero plugins are analyzed — the two should be reconciled (the coverage map is available without analyses, so 12 edgeless ids would also be defensible). (b) The CAPABILITIES column in §9.1/§9.2 is drawn in the pre-sweep key order (TM PX WM FS DX); a literal unweighted barycentre per §4.2 would place DX first under either plugin order — the barycentre pseudocode may want edge-weighting or the wireframes a note. (c) 04 §8 zero-analysis copy `Not analyzed. Press a or Analyze.` differs from the decision record §7 `Not analyzed. Press a to analyze (about 0.2 s).`

Cross-file follow-ups (not made): 05 §8 Contract line 488 still says "the popup calls `bar.shell.summon(manifest.id, …)`" — change to `root.moduleName` (line 490's `shell.hide(manifest.id)` is inside TrustFlowWindow.qml and is correct). 03 §10 tabulates but does not draw the schedule ConfirmSheet (unique anatomy: Unit row, no plugin identity) and the enable variant; 03 §4.2 Overview quiet and §5.1 WHAT CHANGED are prose-only — either draw the schedule sheet in 03 or state in README §Documents that those states are intentionally prose-only. Decision record G13 (scratchpad) also quotes `manifest.id`; not a deliverable.

#### 03-ui-overhaul-proposal.md

All edits applied to /home/hvo/Projects/omasafe-plugin/docs/design/03-ui-overhaul-proposal.md (1365 -> 1453 lines), surgical exact-match replacements, structure unchanged. Every ASCII frame line re-checked at 52 columns. No other file touched.

VERIFIED AND FIXED (with the source I checked)
- Root properties (§2/§3): §2 QML sketch now ends with an explicit "NEW declarations" block: barForeground (Bar.qml:69, distinct from bar.foreground at :68; Ui/Panel.qml:22 has the same line), dim = dimStep(0.33), checking = scanState === "checking", hasScanResult = scanState is "quiet" || "attention" (BW:235 sets exactly those two from a fresh result), earlierResultKept = scanResultsStale && lastScanAt !== "", cliFailed, urgentBadge (+ new blockedDecisions int). §3 hero bullet states root.checking / root.hasScanResult are new Panel.qml root properties (statusLevel === "checking" is tested inline at 196, 219, 2153, 2336, 2783).
- Toggle anchors: titleSize 34 (bold at 77), activeFocusOnTab 40; 45/46/55 kept (verified Ui/Toggle.qml).
- ScrollBar: both occurrences now `ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }` (network/Panel.qml:1487, bluetooth:815; QtQuick.Controls is imported at Panel.qml:2).
- Disabled-button tooltip (§5.1, §5.4 caption): condition line under ActionRow is now the unconditional carrier for ineligible verbs; tooltip described as unverified duplicate; Phase 2 hover check named; §5.4 "drawn while it has the cursor" reworded.
- ENFORCEMENT header (both high issues): wireframe `ENFORCEMENT | EVALUATED`, line 2 `enable · <evaluated_at>`; text now derives the value from evaluation_state via enforcementEnum (Panel.qml:240) -> EVALUATED / NOT EVALUATED / UNSUPPORTED / NO DECISION; explains enforcement_policy_identity is the SHA-256 identity() (enforcement.rs:206-226), EnforcementDecision has no mode field, enforcement-status emits {plugin_id, decision} (main.rs:4030-4045), EnableResult.policy (main.rs:2216-2221) is the only mode source; fingerprint + audit_event_id added to PROVENANCE; CLI ask for persisted `mode` referenced to 05 §12.
- Review-update success (§5.5, §12.4, §15): keyed on stdout "Reviewed update complete" (main.rs:2100, verified println) vs "Already at pinned commit" (main.rs:1201, exits 0 without updating); neutral line otherwise; CLI ask for --format json ReviewUpdateResult referenced to 05 §12.
- Optimistic trust word (§5.5, §12.1, §12.3): replaced with `checking…` until plugins status re-fetch; success line keyed on "Trusted identity recorded" (main.rs:391); untrust keyed on "Review decision recorded" (main.rs:3952).
- Bar failure by shape (§2): every `unavailable` draws the dim outline shield; stale count kept beside it; table row, ASCII frame, prose and badge rules updated. For consistency I also made the hero follow the same rule (§1 convention, §3 rows "scan failed, earlier result …" -> outline · 0.5, §3 failed-scan rule, §4.3 third frame `(s)`, §11 Hero stale cell) so "filled = result of the last successful run" holds on both surfaces. This goes slightly beyond the issue's stated scope; flag if the hero should stay filled.
- Overrides status (§4.4, §11): status word and `1 active` count sourced from overrides[].status via overrideStatus (Panel.qml:338; CLI computes it at main.rs:4244-4249); expires_at verbatim, never compared to the clock; fixture check added.
- PLUGINS order (§4.1, both issues): redrawn btop, omasafe, omarchy-unraid (p, checking…, not analyzed), dropdown-terminal, sandman, hyprmoncfg, snapshots (fold), lunar-calendar; four rows still read checking…; decision (1) and the Order sentence now spell the sort out against scan.json.
- CapabilityStrip positions (§1, §4.1, §4.3): PXDXFS····TM·WM······· (btop: PX,DX,FS,TM,WM verified from analyze-ilyazar.btop.json), PX······TM········· (omasafe), PX·FS····TM·WM······· (sandman, dropdown); §1 no longer says "packed".
- Rule glyph `o` -> `FS` (rules-list.json: oma.qml.dynamic-reference capability filesystem-access); RuleRow text states the glyph is the capability class.
- LOCAL HITS (§7.1): rows now two-line with `· <n> limits` / `· text match only` suffix (omasafe 2, sandman 13, btop 3, dropdown none), reusing the PluginRow line-2 rule.
- Keyboard gating (§13, §3): 1 2 3, / and - are no-ops while navigationLocked; setView() begins `if (root.navigationLocked) return`.
- Cross-view return rule added to §13 (returnFrame {view, depth, cursor}; h/-/back pop it; Breadcrumb shows `󰅁 lgse.sandman`); §5.2 and §12.2 reference it.
- §7.2 declares the two-line RelationRow anatomy binding and 04 §9.6 a schematic of it.
- Bar count: caption -> Style.font.bodySmall (§2 QML, table, prose).
- §14: dangling "Recorded as an open limitation in 05" sentence deleted.
- §10: "(feasibility §8)" -> "(01 §9.6)" (heading verified at 01:522).
- §5.4 wireframe: `Upstream still at the validated commit` row added.
- `n` -> `p` for 󰏗 in §1 and §4.1.
- hostWidget == null hero row added to §3 table and §11 Hero cell (title Scan status unavailable, meta WAITING FOR THE OMASAFE WIDGET, detail unavailable, outline · 0.5).
- Replace-baseline exception stated explicitly in §5.1 (Record/Replace are one verb; only the state-matching one is shown; Remove always shown); the 02 §3.5 condition string is named as having no surface.
- Mermaid: new/edited sequence messages use ` · ` instead of `;` (pre-existing messages elsewhere in §12.3 still contain semicolons; not mine, left alone).

NO ISSUE FOUND WRONG. All 26 confirmed against source.

CROSS-FILE FOLLOW-UPS (not made; other files)
1. 05 Phase 1 (§4): add the new BarWidget/Panel root property declarations (barForeground, dim, checking, hasScanResult, earlierResultKept, cliFailed, urgentBadge, blockedDecisions) and the acceptance item "with operationRunning true and the sheet closed (fixture: 40 s plugins trust), digits do not change the view"; 05 §5 acceptance: hover a disabled Button { tooltipText } on the first Phase 2 build.
2. 05 §5 and 05 Sources: Ui/Toggle.qml cites -> 34 (titleSize) and 40 (activeFocusOnTab); 05 §4 acceptance: `ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }` form.
3. 05 §9: OmaSafeShield `filled` binding = hasScanResult (outline for every unavailable); bar count token bodySmall.
4. 05 §12 CLI asks: add (a) persist `mode` (advisory/hardened) on EnforcementDecision; (b) `plugins review-update --format json` with ReviewUpdateResult { updated, commit, decision }.
5. 05 §13: add open item "No accessibility bridge verifiable in Quickshell panels; all content stays Text.PlainText" (03 §14 pointer was removed; add only if wanted).
6. 02 P2 (line 55) `ENFORCEMENT | ADVISORY / HARDENED / NO DECISION` -> `ENFORCEMENT | EVALUATED / NOT EVALUATED / NO DECISION`; README "The decision" (line 47) and 01 §6 divergence (c) (line 304) likewise.
7. 02 §3.3 success lines: apply the review-update stdout-phrase rule ("Reviewed update complete" / "Already at pinned commit") and the `<id> enabled (<policy>)` form; 02 P11 Do (line 226): "render the success line in place, show checking…, and let plugins status supply the new trust word".
8. 02 §3.5: delete the unused string "Replace baseline appears only when the source differs from the baseline".
9. 02 §3.3 hero titles: add `Scan status unavailable` (hostWidget null). 02 P7/§2.1: no exemption needed now that the bar count is bodySmall.
10. 02 §3.6: drop the claim that pointer users get the ineligible-verb tooltip (pending the Phase 2 hover check).
11. 04 §9.1/§9.2/§9.5: reorder Z0/Matrix frames to btop, omasafe, omarchy-unraid (hollow), dropdown-terminal, sandman, hyprmoncfg, snapshots, lunar-calendar; 04 §9.5 Matrix row labels: append `· <n> limits` / `· text match only`; 04 §9.6: redraw as the 03 §7.2 two-line row (drop `note only`, `class PX`, `3 rules` slot words) or label it a schematic; 04 §6.1/§7: reference the 03 §13 cross-view return rule for pinned rule -> rule sheet -> back to Flow.

Note: docs/design/ is untracked in git (`??`), so there is no diff to review via git; the file on disk is the edited version.

### 5.3 Round 1 consistency-pass notes

CROSS-FILE CONSISTENCY PASS (round 1) — 127 exact-string replacements across the six documents (README 7, 01 16, 02 28, 03 33, 04 34, 05 39), each asserted unique before writing; no document rewritten, no section renumbered. All relative links and heading anchors verified to resolve (0 problems; the em-dash headings slug to a double hyphen, which the links already use). Every redrawn ASCII frame line re-measured at 52 columns; fences balanced in all files.

WHERE EACH CONTRADICTION WAS SETTLED (the binding choice, then the files brought into line)

1. GR2 prefix scope — "Catalog says:" applies to `registry_claim.verification_status` only; correlation `status` renders as its Labels.js sentence, never prefixed, never a bare enum word (README GR2 was already right). Narrowed in 02 P2 Do, 02 §4 checklist, 01 A15, 01 §8.5, 05 §5 acceptance. Added `Labels.marketplaceStatusShort` one-line forms to 02 §3.4 (`Listed in snapshot`, `Listed; commit differs`, `Not in snapshot`, `Catalog entry not matched`, `Catalog entry incomplete`) and used them in 04 §2.1, §3.3 (both worked examples), §5, §8, §9.1 frame + callout, §12. Long `conflict` label (02 §3.4, GR3-safe "not matched … or is unavailable") now used in 03 §5.4 and 03 §12.1 mermaid, with the `Installed repository: unavailable (no git remote)` fact line and the null rows for `upstream_moved` / `installed_matches_listing`.

2. Authority header strings — `TRUST BASELINE` (no right value), `MARKETPLACE CLAIM | CATALOG <commit7> · <age>`, `ENFORCEMENT | ADVISORY / HARDENED / NO DECISION` (03's form). Updated README (decision paragraph + mermaid), 02 P2, 01 §6 divergence (c). 03 §5.4 header now "policy word of `decision.enforcement_policy_identity`, uppercased" (no `Labels.policy`, which 02 split).

3. Hero detail pill — only `unavailable`; CLI version is a SOURCES row (03 §3). Aligned 02 §2.1 and §3.3, 01 E9 consequence, 05 §10 `--version` row, 04 §9.1 frame (pill removed).

4. Colour — `dimStep` mixes (02 §2.3), no `Qt.darker` in plugin code. Aligned README thesis, 01 T2/§4/§9.7, 03 §2 code + table + §14 Contrast, 04 §5 edge row + FlowNode/InspectorStrip sketches (root-passed `dimColor`/`faintColor`/`dimHeaderColor`), 05 §4 root bindings (now the `dimStep` function), §7, §11.3, open question 3 (resolved).

5. Graph geometry — 04 §4.3 is binding: `openW` 118 @12 / 87 @9 / 157 @16, `pairGutter space(72)`, `railGutter space(12)`, derived body height (10 rows @12), no `space(360)`, thirds control points, 23 real edges, stable node arrays (31 here, ≤ 89) with `visible:false` outside the window. Aligned 01 §9.2/§9.5, 02 §2.2 (spacing set now includes 72, drops 24 and 360), 02 §2.9, 02 §4 checklist, 03 §6 frame + bullet, 05 §6 risk/components. 04 §4.3 Flickable sentence corrected: 03 §3 pins the fixed part and subtracts it from the Flickable height, so the body is the same 284 units (the "gains 98 units" claim was wrong).

6. Analysis queue — new root `analysisQueue` / `analysisSweepGeneration` / `analysisStateById` / `startNextAnalysis()` (04 §10.1), not "the existing queue". Aligned 03 §6 bullet, 05 §2 fate row, §6 files/data/effort note (~1 day inside 3b, detail-sheet Analyze depends on it), open question 5 (decided: `x` drops the rest of the sweep). 03 §13 `x` row now lists both read-only roles; 04 §13 updated accordingly.

7. Analysis cache lifetime — 01 §8.7 policy (entries survive close; wholesale clear only on CLI version change; per-plugin drop on analyzer-policy-update / source-drift). Added 05 Phase 0 item 0.16, fate-table rows 858–954 / 1062–1159 / 3792–3813 / 3815–5173 ("four places"), §1.1 note, acceptance bullet. 04 §11 "reused on reopen" is now consistent.

8. Baseline V3 — header `checked against marketplace commit 964dc08` (03 §7.2 reasoning) and no plugin count on a Baseline row; covering rules print `observed in / not observed in <n> analyzed plugins`; `–` only while zero analyzed. Aligned 02 §3.5, 04 §2.3, §7, §9.6 (frame redrawn with the expanded `curl-pipe-shell` row, `4 of 4` / `0 of 4` removed), §12, 05 §5 acceptance. Not-covered relation: no mark (02 §2.4/§2.7, 03 §7.1 text, 03 §7.2 frame `—` removed).

9. Severity glyphs — low = word only, critical = `󰀩` alert-octagon (02 §2.4). Aligned 03 §5.2 text + two frame rows (glyph column blanked), 04 §5. Review-item pills are `FactPill` (02 §2.5) in 03 §5.2, 04 §7; `FactPill.qml` added to 05 §5 files and §9 inventory. `Not analyzed. Press a or Analyze.` (no timing) in 03 §5.2/§11, 04 §5/§8.

10. Placeholders — `–` single mark, no `┄`: 03 §4.1 frame (four rows), §4.1 bullet, §11. Short count form `<n> items`: 02 P8, §2.8 text + frame.

11. Backups row — `CursorSurface` + `ToggleSwitch { interactive:false }` (03 §4.1): README thesis, 02 P6, 01 §4 row, 05 §5, §9 (two rows), sources; 04 sources.

12. Confirm sheet — bare-verb labels, `body` label role, content-sized buttons, scrolling card middle, activateRequested-only wiring, isAutoRepeat + 300 ms guard, PointerMoveGate hover, extended handleKey, policy definition lines `Labels.enforcementPolicy` vs `Labels.schedulePolicy`: README GR6, 01 §9.6, 03 §10 (template, table, frame `[ Record ]`, new paragraph), 05 §4 wiring paragraph + invariant (3)/(4) acceptance, §9 row, §11.3 (768-px/base-20 case). 03 §4.4 schedule row now `Labels.schedulePolicy` with 02's labels; 03 §5.5 `<id> enabled.` keyed on `result.enabled === true`; Update catalog gated on `!navigationLocked`.

13. Other reconciliations — hero meta fragments `SHOWING <n> ALERTS FROM` / `EARLIER RESULT: NO ALERTS` (02 §3.3); `HIDING 7 BACKUPS` only, appended to the header value (02 §3.5, 03 §6); limitation grammar with the bare-code and `sink-reference-rejections-truncated:<n>` branches (02 §3.4, 03 §5.3); ineligible review-update sentence gains "an analysis of the installed source (press a)" (02 §3.5); trust-word tooltip no longer carries the baseline definition (02 §3.6); review-update variant `Installed now` / `Current tree` / `Current digest` (02 §3.7); outline shield `󰦟` F099F added to 02 §2.7 (47 of 48 glyphs; §5 sources fixed from 45/46); OmaSafeShield described as tailscale/Panel.qml:767 `Text` + TailscaleIcon.qml:46–64 badge with token font size (03 §2, 05 §9); Matrix columns in catalog order PX DX FS TM WM (04 §9.5 frame redrawn, §12) with 04 §4.1 citing 02 §2.7 for the Flow exception; Matrix inspector `no review items` (never `0`); 04 §8 first row (view chips enabled, lens chips disabled); 04 §10.1 TrustFlowWindow gains `PluginDetailView`; 04 InspectorStrip comment fixed (marketplace line is one string); 03 §5.2 "bold from high" matches 02 weights; finder count reverted in 05 §5 to 03's verified result (index = id · title, 3 rules, `proc`); 01 §10 Phase 0 list adds A10; 01 §8.3 lists all five classification values with lib.rs:340–370; 2453 → 2455 in 05 §2/§3/sources; README "30 primitives" → "32 exported `qs.Ui` components", status row notes the offscreen instantiation, mermaid detail-sheet node drops FILES AND EDGES; 05 §12 CLI asks add `verified_at_utc` and `recovery`/`next_step`; 05 §5/§9/§10 FILES AND EDGES → COVERAGE (file references).

NOT CHANGED, DELIBERATELY
- Bar badge ink "!" in Color.background: kept — it is the TailscaleIcon.qml:46–64 first-party idiom, distinct from the banned OmaSafeStatusIcon `✓ … ⟳ ? !` disc alphabet.
- 03:234, 886–887 frame lines exceeding 52 columns carry pre-existing trailing annotations (`^ fixed part ends…`, `depth 1`), not frame content; 02 §3.7's frame is 50 wide by its own convention. Left as found.
- decision-record.md (scratchpad, not a deliverable) still carries the superseded 1219/1241 anchors, Qt.darker ladder, `Labels.policy`, "Record baseline" confirm labels, `space(24)`/`space(360)`, ≈ 146 openW and ≤ 52 node budget; the six docs no longer cite it as binding for those values.
- docs/design/ is untracked in git, so `git diff` shows nothing; all edits are on disk.

### 5.4 Round 2 consistency pass (interrupted)

No notes were returned because the pass was stopped. Its transcript shows these edits before interruption (20:04–20:05):

- Copied the decision record into the folder as `06-decision-record.md`.
- `README.md`: six edits to the documents table and closing paragraphs (section-header vocabulary, 03/04 one-liners, decision-record row).
- `01-research-and-audit.md`: six edits (trust argv shapes, audit row A20, authority headers, `built-in`/backup classification wording, `payload_inventory.limitations` note, link to 02).
- `02-design-principles.md`: one edit to the `CATALOG`/`ENFORCEMENT` header examples.

Cross-file follow-ups listed in the round-2 fixer notes above that are not covered by those 14 edits should be treated as unapplied.

## 6 Open items

**Historical status at the end of the recorded run.** The list below preserves the stopped run's state. Section 8
supersedes it for current document status.

1. **Round-2 cross-file follow-ups.** Read section 5.2; any follow-up that names another document and is not among the 14 edits in 5.4 is still open.
2. **Final polish pass not run.** Mechanical checks run by script on 2026-09-02 20:11: all seven documents have balanced code fences; every relative `.md` link resolves; no `TODO`/`TBD`/`FIXME` placeholders; each document has exactly one H1; README's documents table lists 01–06 (this file added below). Not checked mechanically: TOC entries vs actual headings, Mermaid syntax, wireframe widths ≤ 60 columns, heading-anchor fragments.
3. **Line and size check.** Sizes after the interrupted pass: 01 616 lines, 02 806, 03 1454, 04 1264, 05 768, 06 541, README 118.
4. **Unresolved items flagged by lenses.** Search this file for "unresolved" to find issues the reviewers could not settle against source.
5. **Decision record lives in two places.** `06-decision-record.md` is a copy of the scratch decision record made by the interrupted pass; keep the in-repo copy as the binding one.

## 7 Sources and references

- Run journal: `~/.claude/projects/-home-hvo-Projects-omasafe-plugin/5147ee75-1bd3-428a-bf49-cffcc0cb46ab/subagents/workflows/wf_252ae40b-1b1/journal.jsonl` (issue lists and fixer results).
- Consistency-pass transcripts in the same directory: `agent-a0d35c40b64466bfc.jsonl` (interrupted, 14 edits), `agent-ab5699f8238b774ef.jsonl` (no edits).
- Verification targets: `/usr/share/omarchy/shell` (kit), `~/Projects/omasafe/crates/omasafe-report/src/*.rs` and `~/Projects/omasafe/docs/cli-surface.txt` (CLI contract), real `omasafe-cli` 0.2.1 JSON samples captured 2026-09-02.
- Design documents reviewed: [README.md](README.md), [01](01-research-and-audit.md), [02](02-design-principles.md), [03](03-ui-overhaul-proposal.md), [04](04-trust-graph-spec.md), [05](05-implementation-roadmap.md); decisions in [06](06-decision-record.md).

## 8 Post-finalization architecture review and closure

This addendum records the senior architecture/UI review performed after the documents were declared final. It
cross-checked the current deliverables against the historical findings and every unapplied follow-up named in §§5.2–6.
PF-08 through PF-10 come from a later implementation-readiness pass over Phase 0, which re-ran every anchor, QML name
and reachability claim in the Phase 0 table against `Panel.qml` and `BarWidget.qml` at commit `de594d4` while the
per-phase task plans in [`docs/implementation/`](../implementation/README.md) were written.
Historical issue text above is intentionally unchanged; this section is the current-status ledger.

| ID | Finding | Applied resolution | Current status |
|---|---|---|---|
| PF-01 · authorization | GR6 and the confirmation copy treated a visible identity and QML `targetStillExact` as a transaction, but CLI 0.2.1 Enable accepts no expected identity and the untrust branch does not enforce an expected recorded baseline | Replaced the universal identity claim with action-specific authorization contracts across README/01/02/03/05; added target Enable and Remove argv, atomic-under-lock refusal semantics, unavailable states on 0.2.1, and a `cliVersionMin` prerequisite. Added matching errata to 06 and stale-value fixtures | **Design contract closed; implementation blocked** until the CLI contracts are implemented and released. No version number is invented |
| PF-02 · recorded follow-ups | The interrupted consistency pass left concrete F011/F025/F034/F035/F114/F135 and cross-file work unapplied | Added both real budget codes and the fourth prefix-first limitation grammar; corrected outline shield to U+F0499; reserved matches/differs for trust; removed `Time.js` policy; changed popup summon to `root.moduleName`; corrected `3784–3813`; moved enum ownership into `Labels.js`; documented the honest accessibility limitation | **Closed in the design documents** |
| PF-03 · edge evidence | A scope-level lexical flag made unrelated parser-backed edges dashed and contradicted the one-edge fixture | Replaced it with `lexicalOnlyCount` for the notice and per-edge support counts. Only all-lexical/null evidence edges dash; mixed edges remain solid and disclose both counts; Rule→Baseline dash retains its separate partial-overlap meaning | **Closed in 03/04/05/06 and fixtures** |
| PF-04 · graph implementation | Edge coordinates applied `headerH` twice; same-membership analysis changes could fail to notify QML; barycentre could reorder after `a` and did not match the declared order | Put nodes and paths in one root coordinate space; added `contentKey`; allowed data revisions (not navigation) to reassign models; gated both key sort and weighted barycentre tie-breaks on `orderEpoch`; preserved previous order and appended new keys during the epoch; reconciled the zero-analysis Baseline sentinel | **Closed in 04/05/06 and fixtures** |
| PF-05 · semantic emphasis | The global “one urgent per screen” quota could hide or demote simultaneous critical/block states; schedule hardened mode was incorrectly destructive | Replaced the quota with a strict semantic allowlist that permits independent critical/block rows, and made both schedule policies neutral because both are report-only. The schedule sheet now shows exact effective argv | **Closed across README/01–06** |
| PF-06 · reproducibility | Worked numbers depended on an ephemeral scratch capture | Added [`fixtures/verified-summary.json`](fixtures/verified-summary.json) with sanitized worked facts and source SHA-256 values, plus [`fixtures/contract-cases.json`](fixtures/contract-cases.json) for lexical/mixed edges, multiple blocks, same-membership content changes, stale mutation authorization, limitation parsing and hostile/unknown copy | **Closed for design/test reproducibility**; full raw reports remain provenance, not a repository dependency |
| PF-07 · final polish | The original run did not perform its planned final mechanical pass | Added `verify-docs.sh` and rechecked all eight Markdown files plus the two fixtures: exactly one H1 per document; balanced code fences; all relative Markdown targets and heading anchors exist; both JSON fixtures parse with `jq`; no stale high-risk phrase from PF-02–PF-05 remains in current README/01–05; plain-fence wireframe lines in 03/04 are ≤ 60 columns | **Mechanical subset passed 2026-09-02**. Mermaid rendering and live QML/Hyprland validation remain implementation-phase tests because no Mermaid renderer was installed and the proposal is unimplemented |
| PF-08 · Phase 0 buildability | Item 0.6 gated `r` on `hostWidget.checking`, but `checking` is a Phase 1 declaration (03 §2 on `BarWidget`, 03 §3 on the panel root) and Phase 0's file scope is `Panel.qml` only. Because `hostWidget` is `property var` (Panel.qml:13), `!hostWidget.checking` evaluates `!undefined` — the scan-in-progress half of the guard silently does nothing, and `qmllint` cannot see it | Phase 0 now gates on `root.statusLevel !== "checking"` (Panel.qml:155, aliasing BW:117), with Phase 1 re-spelling the same gate `!root.checking`; the phase dependency and the silent-`undefined` reason are stated in 05 §3 item 0.6, 01 A4, 03 §10 invariant 7 and 06 §14 | **Closed in 01/03/05/06** |
| PF-09 · confirmation reachability | A2 / item 0.3 described the buttons reachable through the scrim as "gated only on `!operationRunning`". Re-checked per button: only the two schedule installs (2727, 2737) match; Update catalog (`Button` 3663, `enabled` 3666) gates on its own `marketplaceRefreshProcess.running` alone and so is reachable even while a mutation runs; Explain rule (2994, CLI process at 3002) and the provenance and coverage expanders (3019, 3106) carry no `enabled` binding at all. Anchors also drifted: the Update catalog control is 3663 (3667 is its `bordered` line), the action if-chain is 2571 (2570 is its `onClicked`), the status-row `Item` is 2349–2389, and the bar's scan-then-open press handler is BW:532–535 | Per-button gating and the corrected anchors written into 01 §2.3, §2.4, §2.6, §2.7, A2, A4 and A30; 03 §2 bar sketch and §10 invariants 5 and 7; 05 §2 fate table, §3 items 0.3/0.4/0.6/0.15/0.16 and the Sources anchor lists; 06 §14 carries both errata rows. Item 0.3's fix now says the `enabled` binding is *added* where none exists | **Closed in 01/03/05/06** |
| PF-10 · drifting authorization facts | The confirmation never pinned what it authorized: `trustSelectedPlugin` (568) reads `selectedPlugin()` at confirm time and builds `--expected-head/--expected-tree/--expected-digest` from that row, and the identity block (2469–2492) reads the same live row. Update catalog (3663) is gated only on `marketplaceRefreshProcess.running` and is not part of `operationRunning`, so a refresh started before the confirmation opens lands `applyInventory` (962, via 3958 → 716) under the open sheet; the argv then carries a digest the user never saw, and the CLI's `--expected-*` comparison cannot detect it because it compares against that same new value. A `plugins status` re-fetch moves the Remove sheet's baseline digest and can flip the record/replace title (2440–2442) identically. The design required pinned values (`03 §10` invariant 8; `05 §4` "never reconstructs authorization from whichever plugin happens to be selected at click time") but assigned them to the Phase 1 sheet, leaving the drift live for a phase | Added as roadmap item 0.18 in `05 §3` with its acceptance bullets, and as task T0.18 in [`docs/implementation/phase-0-correctness.md`](../implementation/phase-0-correctness.md): the facts are captured once at open, the identity block and argv read only those values, record vs replace is decided at open, and a drift check writes nothing and closes with `Cancelled: <id> changed since the confirmation opened.` The CLI's locked comparison remains the authorization boundary | **Closed in 05; scheduled as Phase 0 work** |

### 8.1 Remaining gates, not documentation defects

1. Implement and release the CLI expected-value contracts for Enable and Remove; then set the manifest's
   `cliVersionMin` to that actual release and execute the stale-authorization tests.
2. Run `qmllint`, plugin validation, CurveRenderer checks, theme/text-size screenshots and assistive-technology testing
   against the implementation. The documents make no live-render or screen-reader-accessibility claim before those pass.
3. Preserve §6 as the historical stopped-run snapshot. For current status, this section and 06 §14 are authoritative.
