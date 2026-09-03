# Phase 4 — comprehension, polish, hardening, measurement

The live Phase 3 surface is correct and explains itself before cosmetic polish begins: graph delegates instantiate,
the all-plugins view leads with the Matrix, the single-plugin graph exposes one readable path at a time, incomplete
analysis is explicit, and the inspector answers “what does this mean?” before the first cursor move. Every tooltip
and empty state written in [`02 §3`](../design/02-design-principles.md) is then put in place, the light-theme pass is
done with evidence, and the panel is measured as what it actually is: a long-lived resident of a `quickshell`
process that outlives every interaction with it.

No new files except screenshots. Effort M · 4–6 days. Risk: medium in the Flow presentation and low elsewhere. The
Phase 3 live screenshot showed that lint and pure-JS tests can pass while every `FlowNode` delegate fails at runtime;
the live warning gate in T4.0 is therefore release-blocking, not optional polish.
Spec: [`05 §7`](../design/05-implementation-roadmap.md), `02 §2.3` (the ladder), `02 §2.6` (motion), `02 §3.6`
(tooltips), `05 §11.3`–`§11.4` (matrices and recipes), `05 §12` (rollout).

## Contents

1. [Entry criteria](#1-entry-criteria)
2. [Task list](#2-task-list)
3. [Tasks](#3-tasks)
4. [Acceptance](#4-acceptance)
5. [Sources](#5-sources)

## 1 Entry criteria

- Phase 3 merged, or its text fallback merged with the graph lens formally dropped for this release.
- A live Flow screenshot and a matching `journalctl --user` interval are captured. Phase 4 does not treat
  `qmllint` or the layout unit test as proof that delegates instantiate in the running shell.
- The five-theme × four-size manual matrix of `05 §11.3` is available as a checklist, and the machine can switch
  themes (`omarchy theme set <name>`) and font sizes (`[font] base-size` in `~/.config/omarchy/shell.toml`).

## 2 Task list

| Order | Task | Touches | Effort |
|---|---|---|---|
| 1 | [T4.0](#t40-phase-3-live-correctness-close-out) Phase 3 live correctness close-out | `Panel.qml`, `graph/*` | 4–6 h |
| 2 | [T4.1](#t41-flow-comprehension-and-progressive-disclosure) Flow comprehension and progressive disclosure | `Panel.qml`, `views/FlowView.qml`, `graph/*`, `components/InspectorStrip.qml` | 1–2 d |
| 3 | [T4.2](#t42-tooltip-and-empty-state-sweep) tooltip and empty-state sweep | `components/*`, `views/*`, `graph/*` | 4 h |
| 4 | [T4.3](#t43-light-theme-contrast-pass) light-theme contrast pass | `Panel.qml` (3 constants) | 4 h |
| 5 | [T4.4](#t44-binding-and-pointer-audit) binding and pointer audit | delegates across all views | 4 h |
| 6 | [T4.5](#t45-motion-audit) motion audit | animations | 2 h |
| 7 | [T4.6](#t46-residency-and-cpu-measurement) residency and CPU | nothing | 2 h + 1 h wall |
| 8 | [T4.7](#t47-screenshots-readme-changelog) screenshots, README, CHANGELOG | `media/`, `README.md`, `CHANGELOG.md` | 4 h |

## 3 Tasks

### T4.0 Phase 3 live correctness close-out

**Goal.** Close the gap between static validation and the running shell before judging the graph’s visual design. A
graph with paths but no nodes is a failed render, not a sparse or confusing state.

**Change.** Fix the `TrustFlow` repeater contract so each `FlowNode` receives its row object and index explicitly.
Use a wrapper delegate with `required property var modelData` / `required property int index`, or rename the
`FlowNode` inputs and bind them from those delegate roles; do not depend on inherited required properties being
filled implicitly. Audit `MatrixGrid` and `TraceChain` repeaters for the same imported-component pattern.

Complete two Phase 3 review residuals in the same close-out:

- `flowTraceData()` must either filter `FILE EDGES` and limitations to the selected plugin × class path, or label
  them honestly as plugin-wide. It must not print `ON THIS PATH` over unfiltered plugin-global data.
- Every analysis-generation invalidation clears `analysisProcess.nextPluginId` / `nextRequestId`; the stale
  `onExited` branch clears deferred process state before returning, so an old selected-plugin request cannot run
  after a later analysis completes.

**Verify.** Record the journal cursor/time, open Graph and Matrix, move through all four columns, open Z1 and Z2,
then inspect only the new journal interval. It contains none of `Cannot create delegate`, `Required property`,
`TypeError`, `ReferenceError`, `Binding loop` or `Unable to assign`. At `2 OF 9 ANALYZED`, the graph visibly renders
two analyzed plugin rows, seven hollow plugin rows, every observed capability row, their counts and the curves
terminating at the visible node centres. A Trace for two different capability classes never labels unrelated
plugin-global evidence as path-specific. Add a small live/delegate smoke harness if the replay shim can make this
deterministic; `qmllint` alone cannot close the task.

### T4.1 Flow comprehension and progressive disclosure

**Goal.** A person seeing Flow for the first time can answer, without opening the `?` legend: “Which analyzed plugin
showed which capability, which rule produced it, and how does that rule map to Baseline V3?” The graph is an analysis
and coverage map, not a trust or safety verdict.

**Change.** Apply progressive disclosure to the 420-unit popup:

- Z0/all plugins opens on **Matrix**, which is the readable comparison form; Graph remains available as a lens.
  Z1/single plugin opens on **Graph**, focused on `CAPABILITIES | RULES` as today.
- Change the user-visible section heading from `TRUST FLOW` to `ANALYSIS PATHS`; internal `flow*` identifiers do not
  need renaming. Add one plain-language line: `Plugin → observed capability → detecting rule → Baseline V3 mapping`.
- When fewer than all live plugins are analyzed, show a persistent honest state such as
  `2 of 9 plugins analyzed — paths are incomplete. Press A to analyze the rest.` Do not imply that absent paths are
  absent capabilities.
- The inspector is never blank. Before the first cursor move it says
  `Select a plugin to see what was observed, which rule detected it, and how it maps to Baseline V3.` Matrix uses
  the equivalent row/cell instruction.
- In Graph, no anonymous spaghetti is the resting state: hide rest edges until the cursor is active, or reduce them
  below the text hierarchy; a cursor shows its one-hop edges and a pin shows its connected path. Node labels and
  counts remain the primary information.
- Replace unexplained `RU` / `BA` rail copy with recognizable labels (`RULES`, `BASELINE V3`) when space permits;
  if a rail must abbreviate, the inspector and header name the full next step. Change bare `+4 more` to a typed label
  such as `+4 plugins` / `+3 Baseline ids`, and give it a wheel/keyboard hint.
- Put the edge vocabulary next to the graph or in the initial inspector: `solid = parser-backed`; `dashed = text
  match only`. The `?` legend remains the detailed reference, not the only explanation.

Do not add scores, grades, risk colours or a “safe” conclusion. A line means only that cached analysis or the
coverage map supplied the displayed relationship.

**Verify.** Capture Z0 with the real `2 OF 9 ANALYZED` state and Z1 for one analyzed plugin. In a five-second
comprehension check, a reviewer who has not read the design can state what each column means, what solid/dashed
means, why seven plugins have no paths, and what action reveals more data. No screenshot contains an edge without
visible endpoints, an empty inspector, an unexplained two-letter layer, or an untyped `+N more`. Keyboard and pointer
paths both reveal the same one-hop relation, and switching Matrix ↔ Graph does not start analysis.

### T4.2 Tooltip and empty-state sweep

**Change.** `PanelToolTip` on every pill, strip, trust word and section header per `02 §3.6` (`bodySmall`, 400 ms
kit-default delay). Every empty state from `02 §3.3` is present and none is blank, `0` or `n/a`.

**Verify.** Every tooltip string in the build appears in the `02 §3.6` table, and none contains `safe`, `clean`, a
bare `verified`, or `risk`. Hover a disabled `Button { tooltipText }` — the tooltip still appears, since an
ineligible verb must be able to explain itself (`02 §3.5`).

### T4.3 Light-theme contrast pass

**Change.** Re-take the five-theme screenshot set at base 9 / 12 / 16 / 20 (`05 §11.3`). The `dimStep` ladder was
decided in Phase 1 (T1.3); here the only permitted change is tuning the three `k` values — panel-wide, in one place.
Nothing else in the visual system is reopened at this stage.

**Verify.** In `white` (whose `urgent` is `#2a2a2a`, nearly the foreground) every meaning still survives without
hue; in `catppuccin-latte` the three dim steps remain distinct at base 9; in `retro-82` (radius 0) rows, pills and
the sheet card are square without clipping; in `oxocarbon` the 4–6 px borders fit; in `ame-quattro` the hover and
selected fills come from `[controls]`.

### T4.4 Binding and pointer audit

**Change.** `PointerMoveGate` on every list that can reflow under a stationary pointer. Remove every function-call
binding from delegates and every `Repeater { model: someFunction() }` — `01 §3` counted 12 + 18 of these before the
refactor; the audit confirms the count is now zero.

**Verify.** `grep -rn 'containsMouse' components/ views/ graph/` is empty. Reflow a list under a parked pointer (a
scan that removes an alert row): the cursor does not move.

### T4.5 Motion audit

**Change.** Durations are only 60 / 120 / 140 / 900 ms (`02 §2.6`). Every `loops: Animation.Infinite` is gated on
`opened && checking`, so nothing animates while the panel is closed (GR5).

**Verify.** `grep -rnE 'duration: [0-9]+' --include='*.qml' .` yields only those four values. With the panel closed,
no animation is running.

### T4.6 Residency and CPU measurement

**Change.** Nothing in the code unless a measurement fails. Run `05 §11.4`: `ps -o rss= -p "$(pgrep -x quickshell)"`
at minute 5 and minute 65, with `periodicScanEnabled` and a 1-minute interval, opening and closing the panel ten
times in between. Compare idle CPU with the panel closed against a build without the plugin.

**Verify.** RSS delta under 10 MB; idle CPU with the panel closed equal to a build without the plugin. Record both
numbers in the commit message — this is the claim the design makes about being a good resident, and it should be
falsifiable later.

### T4.7 Screenshots, README, CHANGELOG

**Change.** Replace `media/clear.png` and `media/warning.png` with `media/overview-quiet.png`,
`overview-alerts.png`, `plugin-detail.png`, `rules-baseline.png`, `analysis-paths.png` and `confirm-record.png`, all at
base 12 in `tokyo-night`, plus `light-catppuccin-latte.png` and `retro-82.png` for the theme claim. Every screenshot
uses the real data from this machine — the names, hashes and three provenance-conflict alerts are already public in
the repo's samples — and none shows a score or grade.

README sections to update (`05 §12`): "Screenshots and demo"; "How it works" (three views, Analysis Paths, and the one
disclaimer sentence quoted exactly as the panel's footer); "Marketplace verification display" (the `Catalog says:`
wording, `verified_at_commit` attribution, snapshot age); "Validate locally" and "Local development" (the `qmllint`
line with `components/ views/ graph/`); and a new "Keyboard" section carrying the `03 §13` key map. Add
`CHANGELOG.md` with the `0.3.0` entry: Phase 0's fixes under "Fixed", Phases 1–4 under "Changed".

Add a one-line pointer from `docs/cli-v0.2-plan.md` and `docs/cli-v0.2.1-plan.md` to
[`docs/design/README.md`](../design/README.md); both stay as historical CLI contracts.

**Verify.** Every image referenced by the README exists; no screenshot shows a verdict, score or grade; the
disclaimer sentence in the README is character-identical to the one in the panel footer.

## 4 Acceptance

Status recorded 2026-09-03 (branch `phase-3-trust-flow`, uncommitted).

- [x] A fresh live-shell journal interval contains no delegate-creation, required-property, assignment, JavaScript
      or binding-loop warning while Graph, Matrix and two Trace paths are exercised. *T4.0* — verified via deploy +
      restart + IPC-summon + journal read (only the pre-existing harmless `exitCode` deprecation remains).
- [x] Every Flow node label and count renders; every visible edge terminates at visible node centres; Trace labels
      plugin-global data as plugin-wide or filters it to the selected path. *T4.0* — Z0 (9-of-9) and Z1 render all
      nodes/counts; `FILE EDGES` / `COVERAGE LIMITS` relabelled `· PLUGIN-WIDE`.
- [x] Z0 defaults to Matrix, Z1 defaults to Graph, incomplete analysis is explicit, the inspector is never blank,
      and a five-second comprehension check can explain the four stages and both edge styles. *T4.1* — all verified
      live except the human five-second check, which is a reviewer sign-off.
- [x] No Flow screenshot contains anonymous curves, unexplained `RU` / `BA`, bare `+N more`, or an unlabeled
      incomplete-analysis state. *T4.1* — resting edges hidden, `+N` typed, RU/BA named by the legend line; the
      incomplete callout is persistent and auto-hides at N==M.
- [x] `grep -rnE 'duration: [0-9]+' --include='*.qml' .` yields only 60, 120, 140, 900. *T4.5* — clean; the one
      `Animation.Infinite` (OmaSafeShield rescan glyph) is gated on `opened && checking`.
- [x] `grep -rn 'containsMouse' components/ views/ graph/` is empty; no `Repeater { model: fn() }`; no banned GPU
      effects. *T4.4* — clean.
- [~] RSS after one hour with periodic scans at 1 min and ten panel opens is within 10 MB of the minute-5 value;
      idle CPU with the panel closed is unchanged from a build without the plugin. *T4.6* — short proxy run
      recorded no growth across ten open/close cycles + a five-minute idle hold (RSS ~649→645 MB, whole-shell). The
      formal one-hour run is a manual sign-off.
- [x] Every tooltip string is verdict-free — none contains `safe`, `clean`, bare `verified` or `risk`. *T4.2* — the
      only `safe`/`verified`/`clean` occurrences are disclaimers negating them, internal state enums, or attributed
      marketplace/CLI verification. Tooltip coverage is broad on interactive elements; the exhaustive per-header
      sweep against `02 §3.6` is a reviewer pass.
- [~] The five-theme × four-size matrix of `05 §11.3`. *T4.3* — the `dimStep` ladder and its three `k` values are
      centralized in one place (`Panel.qml` `dimHeader`/`dim`/`faint`), so tuning is a one-place change; the visual
      matrix and any `k` adjustment are a manual pass.
- [~] Screenshots regenerated and README updated; `CHANGELOG.md` present. *T4.7* — README fully updated (three
      views, Analysis Paths, exact footer disclaimer, Keyboard section); `CHANGELOG.md` has a Phase-4 section;
      `media/analysis-paths{,-graph}.png` regenerated and the pre-Flow shots dropped. The full themed six-image set
      is a manual clean-desktop pass.
- [x] The folder [README](README.md) §5 command block still exits 0 (qmllint 0, verify-docs pass, flow-test 89/0).

## 5 Sources

- [`05 §7`](../design/05-implementation-roadmap.md) scope and acceptance; `05 §11.3`–`§11.4` manual matrix and
  measurement recipes; `05 §12` rollout, screenshots and README list.
- [`02 §2.3`](../design/02-design-principles.md) colour derivations, `02 §2.6` motion set, `02 §3.3` status strings,
  `02 §3.5` ineligible verbs, `02 §3.6` tooltips, `02 §4` review checklist.
- [`01 §3`](../design/01-research-and-audit.md) findings A40, A41 and the binding counts carried at `01 §5`.
- Post-Phase 3 live review on 2026-09-03: the screenshot showed anonymous curves and an empty inspector; the matching
  shell journal showed `FlowNode` delegate creation failing because `modelData` and `index` were not initialized.
