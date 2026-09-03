# Phase 1 — kit shell, tokens, cursor, confirmation sheet

Rebuild the chrome around the content out of `qs.Ui` primitives and theme tokens, put one keyboard cursor over the
shell targets, and replace the overlay with a sheet that cannot be bypassed. Scope is deliberately the frame only: bar
icon, hero, status line, notices, view chips, root colour and type bindings, `ConfirmSheet`, cursor scaffold.

**The four tab components (2584–3790 after Phase 0's deletion) are not touched.** Their hand-rolled rows, buttons and
expanders keep working by mouse and are replaced once, in Phase 2, on kit rows. Converting them here and deleting them
there writes every row twice — the single most expensive mistake available in this plan.

Effort M · 2–3 days. Risk: keyboard regressions. Spec: [`03 §2`](../design/03-ui-overhaul-proposal.md) (bar),
`03 §3` (shell and the hero state table), `03 §9` (notices), `03 §10` (confirmations), `03 §13` (keyboard and cursor),
[`02 §2`](../design/02-design-principles.md) (visual system), `02 §3` (copy),
[`05 §4`](../design/05-implementation-roadmap.md) (scope, components, acceptance).

## Contents

1. [Entry criteria](#1-entry-criteria)
2. [Task list](#2-task-list)
3. [Tasks](#3-tasks)
4. [Commit plan](#4-commit-plan)
5. [Acceptance](#5-acceptance)
6. [Risks](#6-risks)
7. [Sources](#7-sources)

## 1 Entry criteria

- Phase 0 merged; `pendingAction`, the pinned authorization facts (T0.18) and `scanAvailable` (T0.6) exist.
- `docs/design/02-design-principles.md` §2 and §3 read once, in full. This phase writes the tokens and strings every
  later phase reuses; a wrong `dimStep` or an invented sentence propagates through Phases 2–4.
- Five themes installed for the screenshot pass: `white`, `catppuccin-latte`, `retro-82`, `oxocarbon`, `ame-quattro`.

## 2 Task list

| Order | Task | Creates / modifies | Blocked by | Effort |
|---|---|---|---|---|
| 1 | [T1.1](#t11-the-three-pure-js-modules) `model/Labels.js`, `Glyphs.js`, `Time.js` | 3 files; `Panel.qml` 187–450 delegate | — | 4 h |
| 2 | [T1.2](#t12-root-colour-and-type-tokens-no-literal-anywhere) root tokens; delete `#e5a50a` ×3 | `Panel.qml`, `BarWidget.qml` | — | 3 h |
| 3 | [T1.3](#t13-decide-the-dimstep-ladder-on-light-themes) decide the `dimStep` ladder | `Panel.qml` (3 constants) | T1.2 | 2 h |
| 4 | [T1.4](#t14-sectionheaderrow-noticerow-infogrid) `SectionHeaderRow`, `NoticeRow`, `InfoGrid` | 3 files | T1.2 | 4 h |
| 5 | [T1.5](#t15-the-panel-shell) panel shell: fixed column over a scrolling body | `Panel.qml` 1300–1308, 2283–2417 | T1.4 | 1 d |
| 6 | [T1.6](#t16-the-hero-state-table) hero states, all eleven rows | `Panel.qml` | T1.5 | 4 h |
| 7 | [T1.7](#t17-omasafeshield-and-the-bar-row) `OmaSafeShield.qml`, bar `Row` + count | 2 files; delete `OmaSafeStatusIcon.qml` | T1.2 | 4 h |
| 8 | [T1.8](#t18-the-cursor-model-scaffold) cursor model over `hero` → `views` | `Panel.qml` 2260–2281 | T1.5 | 4 h |
| 9 | [T1.9](#t19-confirmsheet-and-the-nine-no-bypass-invariants) `ConfirmSheet` + invariants | 1 file; `Panel.qml` 2421–2581 deleted | T1.4, T1.8 | 1 d |

## 3 Tasks

### T1.1 The three pure-JS modules

**Goal.** One closed-enum map, one glyph table, one time formatter — imported, not duplicated.

**Files.** `model/Labels.js`, `model/Glyphs.js`, `model/Time.js`. Modified: `Panel.qml` 187–450 (label helpers) —
during migration the QML functions stay as thin wrappers that delegate, so nothing else has to change in the same
commit; Phase 2 deletes the wrappers as each consumer moves.

**Change.**

- `Labels.js` owns every closed-enum gate and its label text: `enforcementEnum` (240), `coverageRelation` (320),
  `overrideStatus` (338), the analysis labels (379–450), the marketplace `verification_status` and correlation
  `status` sets, severity and confidence words, and the four-grammar prefix-first limitation-code parser including
  bare `time_budget_exhausted` and the `<code>:<value>` suppression and equivalence codes. Unknown → `unsupported`,
  counted, never dropped. Missing → `unavailable`. Spec `02 §3.4` and `02 §3.5`.
- `Glyphs.js` is one object of Nerd Font codepoints plus the ASCII fallback table, selected when
  `Style.font.resolvedFamily` does not contain `"Nerd"`. Spec `02 §2.7` — copy the codepoints from that table, do not
  re-derive them.
- `Time.js` formats relative time and ages only. It owns **no** policy threshold: `(stale)` is printed when and only
  when `result.marketplace_stale` is true (`02 §3.3`).
- A pure JS module never calls into QML. Imports are `import "model/Labels.js" as Labels`.

**Verify.** `Catalog says:` prefixes `verification_status` values only, and the correlation `status` renders as its
`02 §3.4` sentence — never a bare enum word, never prefixed. An unknown enum value in `contract-cases.json` renders
`unsupported` and is counted. `grep -rn 'root\.' model/` is empty.

### T1.2 Root colour and type tokens; no literal anywhere

**Goal.** Colour and type are declared once, on the root, and nothing else in the repository contains a colour
expression or a raw pixel size.

**Change.** Declare on `Panel.qml`'s root exactly the block in `05 §4` (`fg`, `urgent`, `dimStep(k)`, `dimHeader`,
`dim`, `faint`, `hoverFill`, `selectedFill`, `fontFamily`), then:

- delete `warningColor` (`Panel.qml:153`) and `#e5a50a` at `BW:116` and `Icon:9`; replace every `root.warningColor`
  read with `root.urgent`, restricted to the `02 P9` semantic allowlist — critical/error alerts, enforcement blocks,
  CLI failures, the active destructive confirmation, the bar badge. Multiple independent critical or block rows keep
  their emphasis; decorative and ordinal severity uses do not.
- replace the shell's `Util.alpha(root.contentForeground, k)` chrome uses with the `dimStep` ladder. The tab bodies
  keep theirs until Phase 2 — this task converts only what T1.5 through T1.9 rewrite.
- delete `visible: !vertical` (`BW:112`); vertical bars are handled by T1.7's `Column`.

**Verify.** `grep -rnE '#[0-9a-fA-F]{6}' --include='*.qml' --include='*.js' .` is empty.
`grep -rn 'font.pixelSize:' --include='*.qml' . | grep -v 'Style.font\.'` is empty. `grep -rn 'Color.muted'` is
empty. Type roles come from `Style.font.{title,body,bodySmall,caption,icon,display}` only, and a count or hash never
renders below `bodySmall` (`02 P7`).

### T1.3 Decide the `dimStep` ladder on light themes

**Goal.** Close open decision 3 with evidence rather than deferring it to Phase 4.

**Change.** `dimStep(k)` is an opaque mix of `fg` toward `Color.background` with `k` = 0.25 (`dimHeader`), 0.33
(`dim`), 0.55 (`faint`) — not `Qt.darker`, which inverts on light themes (`02 §2.3`). Screenshot the three steps in
`catppuccin-latte` and `white` at base 9 and adjust only the three `k` values, in one place, if a step is not legibly
distinct.

**Verify.** In `catppuccin-latte` and `white` at base 9, headers, secondary lines and disabled glyphs still read as
three distinct steps below primary text. Phase 4 may re-tune the same three constants and nothing else.

### T1.4 `SectionHeaderRow`, `NoticeRow`, `InfoGrid`

**Goal.** The three structural components the shell needs now and every view reuses later.

**Files.** `components/SectionHeaderRow.qml`, `components/NoticeRow.qml`, `components/InfoGrid.qml`.

**Change.**

- `SectionHeaderRow`: `PanelSeparator` + `Row { PanelSectionHeader; Text value }`. The value after `|` is the
  section's own count or state, never a verdict; `TRUST BASELINE` has no right-hand value at all (`03 §5.4`).
- `NoticeRow`: `CursorSurface` without cursor holding one `Text` (`Style.font.body`, `WordWrap`), following the
  `tailscale/Panel.qml:511–529` idiom. `reason` is one of `loading · none · unavailable · unsupported · stale ·
  lexical-only` and selects **only** the glyph and paint — dim for everything except `lexical-only` (`fg` with `󰀦`)
  and `unavailable` when it carries a CLI failure (`urgent`). The text always carries the meaning on its own; a slot
  is never blank, `0` or `n/a`. Every string comes from the `03 §9` catalogue.
- `InfoGrid`: `GridLayout { columns: 2; columnSpacing: Style.space(20); rowSpacing: Style.spacing.labelGap }` with an
  optional copy `PanelActionButton`. Hash-only values are `WrapAnywhere` so a 64-hex digest wraps instead of
  clipping — eliding a hash is forbidden under GR6.

**Verify.** One `NoticeRow` of each of the six reasons renders in all five themes at base 9 and 20 without clipping.
No component contains a colour expression (T1.2) or reads `containsMouse` (`03 §13`).

### T1.5 The panel shell

**Goal.** The structure of `03 §3`: a fixed column that never scrolls over a body that always can.

**Change.** Replace `tabShell` (2283–2417) with:

```
Column { spacing: Style.space(12) }
├─ Column fixed          hero · status line · NoticeRow ×0..n · ButtonGroup
└─ Flickable             height: parent.height − fixed.height − Style.space(12)
    └─ Loader            the active tab body (unchanged content this phase)
```

- `KeyboardPanel` sizing (1300–1308) becomes `contentWidth: fittedContentWidth(Style.space(420))` and
  `contentHeight: fittedContentHeight(fixed.implicitHeight + Style.space(12) + viewLoader.implicitHeight,
  Style.space(560))`. The inner `Style.space(480)` cap at 2394 and the outer `space(600)` at 1308 collapse into that
  one `space(560)`.
- `Flickable`: `clip: true`, `interactive: !sheet.opened`, `ScrollBar.vertical: ScrollBar { policy:
  ScrollBar.AsNeeded }`. **Not** gated on `navigationLocked` — enable and review update run up to 60 s and the panel
  must stay scrollable throughout; action buttons stay disabled on the full lock.
- Views: `ButtonGroup { options; value: root.view; focusable: false; cursorIndex; fontSize: Style.font.bodySmall;
  onChanged: root.setView(value) }` (`Ui/ButtonGroup.qml:26–45`). **This phase keeps four options, one per existing
  tab**, so keys `1 2 3 4` keep their present meaning; Phase 2 reduces them to `[Overview] [Rules]` and Phase 3 adds
  `[Flow]`. `setView(value)` begins with `if (root.navigationLocked) return`, so the digits and the mouse share one
  gate. The hand-rolled tab strip (2288–2331) and the filled accent `Button` at 2333–2346 with its `Style.space(64)`
  width are deleted.
- Status line: one `Text` (`bodySmall`) carrying the verbatim `cliError` in `urgent` or the stale sentence in `dim`,
  hidden otherwise. Notices: `NoticeRow`s for unavailable, stale, lexical-only and the inventory
  `coverage.limitations[]` line Phase 0 added as a plain `Text` (T0.15) — re-home it here.
- The view `Loader` crossfades on change: opacity, 140 ms, `Easing.OutCubic`. No other animation.
- No cards: the seven tinted `Rectangle` containers of the current tabs go with their tabs in Phase 2, but the shell
  itself adds none.

**Verify.** The body scrolls with `ScrollBar.AsNeeded`; the hero, status line and chips stay in view while a long tab
body is scrolled; no horizontal scroll at base 9–20; nothing clips at base 20 on a 768-px display. The four tab
bodies still render and still work by mouse.

### T1.6 The hero state table

**Goal.** One sentence in the CLI's own vocabulary, and never a positive headline from stale data.

**Change.** Implement all eleven rows of the `03 §3` hero table exactly — `quiet`, `attention`, `critical`,
`checking`, `ready`, the three failed-scan variants, missing CLI, incompatible CLI, `hostWidget == null`, plus the
detail-sheet title Phase 2 uses. `PanelHero { iconComponent: OmaSafeShield { iconSize: Style.font.display; filled:
root.hasScanResult }; title; meta; detail; iconOpacity; trailingControl }`; the trailing control is the scan `Button`
bound to `root.scanAvailable` from T0.6, re-spelled with `!root.checking` now that `checking` exists.

The `detail` pill appears **only** when it reads `unavailable`. The CLI version never goes in the hero — it lives in
the SOURCES row alone (Phase 2), because the kit subtracts the pill's `implicitWidth` from the title
(`Ui/PanelHero.qml:54`) and would force `ElideRight` on `1 critical alert to review` at base 9.

Failed-scan rule (GR3): when `scanState == unavailable` the title is always `Scan unavailable`, the shield is the
outline, `iconOpacity` is 0.5, and the stale facts move into the meta (`SHOWING 3 ALERTS FROM 2 H AGO` / `EARLIER
RESULT: NO ALERTS · 2 H AGO`). The earlier result's ALERTS rows stay listed under a `stale` `NoticeRow`.
`No outstanding alerts` is never printed from stale data.

**Verify.** A quiet scan followed by a failing scan renders `Scan unavailable` with `LAST SCAN FAILED · EARLIER
RESULT: NO ALERTS · <relative>`. With `hostWidget` forced null the hero reads `Scan status unavailable` /
`WAITING FOR THE OMASAFE WIDGET` and the panel loses no other function.

### T1.7 `OmaSafeShield` and the bar row

**Goal.** The bar says state and count, in shape and digits, and never a verdict.

**Files.** `OmaSafeShield.qml` created; `OmaSafeStatusIcon.qml` deleted; `BarWidget.qml` modified.

**Change.** Per `03 §2`: the bar item becomes `Row { spacing: Style.space(2) }` holding the existing `BarIconButton
{ iconComponent; slotSize: Style.bar.statusSlot }` (BW:516–540, its `onPressed` handler at BW:532–539 unchanged) and
a **sibling** count `Text`. The count cannot live inside the icon — `BarIconButton` fixes `fixedWidth: slotSize`
(`Ui/BarIconButton.qml:20`) at 21 units (`Style.qml:347`) and shows its own `text` only when `iconComponent` is null;
a 13-unit shield plus a `bodySmall` `9+` needs ≈ 30. The root binds `implicitWidth: row.implicitWidth`
(`Ui/WidgetButton.qml:68` permits it); a vertical bar stacks the same two items in a `Column`.

`OmaSafeShield.qml` draws the shield as a `Text` glyph (the `tailscale/Panel.qml:767` idiom): filled `󰒃` U+F0483 when
a scan result exists, outline `󰒙` U+F0499 otherwise — `ready`, missing or incompatible CLI, and every `unavailable`,
with or without an earlier result. Failure is encoded by **shape**, never by dim alone. The urgent badge copies the
`TailscaleIcon.qml:46–64` `BorderSurface` but sizes its ink with a `Style.font.*` token; the literal at
`TailscaleIcon.qml:61` is not copied (`02 §4` forbids it). `󰑐` rotates in the badge slot only while
`opened && checking`.

Declare the six new `BarWidget` root properties of `03 §2` with explicit false/zero fallbacks: `barForeground`,
`checking` (`scanState === "checking"`), `hasScanResult` (`scanState` is `quiet` or `attention`, the two states a
fresh result sets, BW:235), `earlierResultKept` (`scanResultsStale && lastScanAt !== ""`), `cliFailed`,
`blockedDecisions` (count of `enforcement_summary.decisions[].outcome === "block"`), and derived `urgentBadge`. The
count `Text` is `bodySmall` — a count is data, never `caption`.

**Verify.** `implicitWidth` equals `Style.bar.statusSlot` with no count and grows by `countText.implicitWidth +
Style.space(2)` with one, in a top bar and in a left bar. A failed scan never shows the filled shield; a never-run
scan never fills it; the count never reads `0`. The badge is urgent only for critical/error severity or a block
decision.

### T1.8 The cursor model scaffold

**Goal.** One cursor, one key grammar, no focus scattered across buttons.

**Change.** Port the dev-gallery template (`plugins/dev-gallery/GalleryPanel.qml:101–262`): root owns `cursorActive`
(false on open — the first move or real pointer motion reveals the highlight), `focusSection`, `selectedIndex`,
`visibleSections`, `sectionCount`, `sectionIsHorizontal`, `moveCursor`, `moveCursorH`, `activateCursor`,
`clampCursor` (after **every** model change, so a rescan that shrinks a list cannot leave the cursor out of range) and
`ensureCursorVisible` (drives `Flickable.contentY`).

This phase's section list is `hero → views` only; Phase 2 appends the per-view sections when the rows exist. Rewrite
`PanelKeyCatcher`'s handlers (2260–2281) to the `03 §13` grammar and set `blocked: sheet.opened ||
finder.activeFocus`. Rows bind `hasCursor` from root state and never read `containsMouse`
(`Ui/CursorSurface.qml:4–8`); hover sets the same cursor through `PointerMoveGate.moved(item, mouse)`
(`Ui/PointerMoveGate.qml:30`) so reflow under a stationary pointer cannot steal it. No `Button` is `focusable` —
Tab must keep switching bar panels (2268–2271 unchanged).

**Verify.** `grep -rn 'focusable: true' --include='*.qml' .` is empty; `grep -rn containsMouse components/ views/` is
empty. From a fresh open, `j` reaches the scan `Button` and every chip and `k` returns; hover the scan button then
press `j` — exactly one highlight is on screen, on the chip row. With `operationRunning === true` and no sheet open
(the 40-second trust replay case), digit keys do not switch views and no second action starts.

### T1.9 `ConfirmSheet` and the nine no-bypass invariants

**Goal.** The overlay becomes a sheet that keeps the kit `ConfirmDialog` contract, cancels by default, and cannot be
confirmed by a held key, a parked pointer or a stray click.

**Files.** `components/ConfirmSheet.qml` created; `Panel.qml` 2421–2581 (the overlay) deleted and replaced by one
instance.

**Change.** Build it exactly as `03 §10` and `05 §4` specify. The parts that are easy to get wrong:

- Kit contract kept: `opened`, `handleKey(event)`, `canceled()`, `confirmed()`, scrim
  `Util.alpha(Color.background, 0.7)`, card `BorderSurface`, and the button chrome of `Ui/ConfirmDialog.qml:96–130`.
- Four deliberate departures: `selectedIndex` starts at `0` (Cancel — the kit defaults to `1`,
  `Ui/ConfirmDialog.qml:11`); title + identity `InfoGrid` + body replace the single `message`; an optional policy
  `ButtonGroup`; `destructive` is per kind, not index-based.
- Two more, both about reachability: the card is `Math.min(implicitHeight, parent.height − Style.space(32))` with
  title, `InfoGrid` and body inside a scrolling `Flickable` and the button row anchored to the card bottom — the
  review-update card is ≈ 440 units at base 12, ≈ 733 px at base 20, and an uncapped card pushes Cancel off a 768-px
  screen. And the button `MouseArea`s do **not** pre-select on hover: the kit sets `selectedIndex` in `onEntered`
  (`Ui/ConfirmDialog.qml:119–121`), which would flip a parked pointer's position to confirm on open.
- Held-key stop: `Keys.onPressed` first accepts and drops any `isAutoRepeat` Return/Enter/Space, and ignores a
  non-repeat Return/Enter for the first 300 ms after open. `swallowNextActivate` is only the double-delivery guard
  for one Return press (`Ui/PanelKeyCatcher.qml:71–74`), not the held-key mechanism.
- The `InfoGrid` is action-specific, not a generic identity card, and its values are the **pinned** ones from T0.18:
  record/replace and enable show the authorized head/tree/digest; remove shows `Recorded baseline digest`; review
  update shows `Expected commit — claimed by catalog snapshot <commit7>` as the only target and labels current
  tree/digest `Installed now`; schedule shows both unit names and the exact effective `ExecStart` argv and has no
  plugin identity. `runPendingAction()` copies those values into argv and never reconstructs authorization from
  whatever is selected at click time.
- Titles, bodies, verbs and destructive flags come from the `03 §10` table; the policy definition line is
  `Labels.enforcementPolicy` for enable and review update and `Labels.schedulePolicy` for schedule, never
  interchanged. Both schedule policies are **neutral** chrome: both are report-only.

**Verify.** The nine invariants of `03 §10`, each checked by hand:

1. `keyCatcher.blocked` follows `sheet.opened || finder.activeFocus`.
2. The sheet holds `activeFocus` while open; focus returns to the catcher on close.
3. With the pointer parked where the confirm button will appear, holding Enter on Replace baseline opens the sheet,
   confirms nothing, and leaves it open with Cancel selected.
4. Enter after the 300 ms window cancels; with `[Enable]` under the cursor, `k`/`j` move between Policy and the
   buttons and `l` on Policy changes the chip without touching the button selection.
5. With the sheet open, digits, `r`, `/`, the view chips and the `Flickable` are inert.
6. Clicks and the wheel on the scrim do nothing.
7. `close()` and reopen show no sheet.
8. Changing the selection cancels the pending sheet.
9. While the operation runs both buttons are disabled and the confirm label reads `Working…`.

## 4 Commit plan

| Commit | Tasks | Note |
|---|---|---|
| 1 | T1.1 | three new files plus delegating wrappers; behaviour-neutral |
| 2 | T1.2 + T1.3 | tokens and the ladder decision together — the screenshots justify the constants |
| 3 | T1.4 | three components, not yet instantiated |
| 4 | T1.5 + T1.6 | the shell and its hero are one visual change; splitting them ships a hero with no frame |
| 5 | T1.7 | bar icon; independently revertable |
| 6 | T1.8 | cursor scaffold |
| 7 | T1.9 | sheet; the overlay is deleted in the same commit |

## 5 Acceptance

Beyond each task's own Verify step:

- [ ] Screenshots in `white`, `catppuccin-latte`, `retro-82`, `oxocarbon`, `ame-quattro` at base 9 / 12 / 16 / 20:
      nothing clips, no plugin row wraps to a third line, the bar shows glyph + count and never a filled disc, and
      every urgent use belongs to the `02 P9` allowlist.
- [ ] `omarchy plugin validate .` passes; a vertical (left/right) bar shows the icon.
- [ ] The four tab bodies still work by mouse. Rows inside them are **not** cursor targets yet and are not counted as
      keyboard regressions.
- [ ] Section 5 of the folder [README](README.md) still exits 0, now including `OmaSafeShield.qml` and
      `components/*.qml` in the `qmllint` line.

## 6 Risks

| Risk | Mitigation |
|---|---|
| Keyboard regressions (medium) | T1.8's verification enumerates every target; the nine invariants are checked by hand before merge |
| `hostWidget.bar` null on a third-party bar | every `bar ? … : …` binding has a `Color` / `Style` fallback |
| Nerd Font glyphs absent in a user-chosen family | `Glyphs.js` selects the ASCII fallback when `Style.font.resolvedFamily` lacks `"Nerd"` |
| The sheet's card overflows a short screen | height cap plus scrolling middle, verified at base 20 on 768 px |
| Scope creep into the tab bodies | the phase's opening rule: they are not touched |

## 7 Sources

- [`03 §2`](../design/03-ui-overhaul-proposal.md) bar contract and the new root properties; `03 §3` shell, hero table
  and failed-scan rule; `03 §9` notice catalogue; `03 §10` confirmations and invariants; `03 §13` keyboard and cursor.
- [`02 §2`](../design/02-design-principles.md) type roles, spacing, colour derivations, encodings, glyph table,
  motion, density; `02 §3` copy system; `02 §4` review checklist and its blockers.
- [`05 §4`](../design/05-implementation-roadmap.md) file lists, kit component list, token list, `ConfirmSheet` wiring
  and the phase acceptance list; `05 §9` component inventory.
- Installed kit: `Ui/PanelHero.qml:50–101`, `Ui/ButtonGroup.qml:26–45`, `Ui/ConfirmDialog.qml:11, 23–38, 96–130,
  119–121`, `Ui/PanelKeyCatcher.qml:36, 48–84, 71–74`, `Ui/CursorSurface.qml:4–8`, `Ui/PointerMoveGate.qml:30`,
  `Ui/BarIconButton.qml:20–21, 32, 43`, `Ui/WidgetButton.qml:68`, `Style.qml:347`;
  `plugins/dev-gallery/GalleryPanel.qml:101–262`, `plugins/panels/tailscale/Panel.qml:511–529, 767`,
  `plugins/bar/TailscaleIcon.qml:46–64`.
