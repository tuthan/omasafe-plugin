# Phase 0 — correctness and authorization, no visual change

Close every audit defect that is a correctness or ground-rule violation fixable inside today's four-tab UI, so the
later phases refactor a correct panel. Nineteen tasks: one baseline capture, one ≈ 950-line deletion of code that is
never instantiated, a five-task cluster that rebuilds confirmation state around a single pinned pending action, and
twelve local fixes — one of them blocked on a CLI release. **Exit criterion:** a before/after screenshot in `tokyo-night` at base 12 is pixel-identical except for the
strings named in T0.8, T0.11, T0.14 and T0.15, and the unavailable copy T0.17 introduces if its CLI dependency has
landed. Nothing moves on screen, no colour changes, no component is added.

Files: `Panel.qml`, and `manifest.json` only if T0.17's CLI release exists. No new files, no new components, no new
collectors. One argv changes (`rules explain` gains `--format json`); mutation argv gains expected values only in
T0.17. Effort S · 2–3 days, excluding the separately owned CLI work.

Spec: [`05 §3`](../design/05-implementation-roadmap.md) (item table), [`01 §3`](../design/01-research-and-audit.md)
(findings A1–A4, A6–A10, A13, A17, A21, A39), [`02 §3.3`](../design/02-design-principles.md) (every string),
[`03 §10`](../design/03-ui-overhaul-proposal.md) (confirmation invariants).

## Contents

1. [Entry criteria and baseline](#1-entry-criteria-and-baseline)
2. [Task list](#2-task-list)
3. [Tasks](#3-tasks)
4. [Commit plan](#4-commit-plan)
5. [Acceptance](#5-acceptance)
6. [Risks and rollback](#6-risks-and-rollback)
7. [Sources](#7-sources)

## 1 Entry criteria and baseline

- Working tree clean at `de594d4`; `qmllint -I /usr/share/omarchy/shell -I /usr/lib/qt6/qml Panel.qml BarWidget.qml
  OmaSafeStatusIcon.qml` exits 0 and `omarchy plugin validate .` exits 0 — both do today.
- `omasafe-cli 0.2.1` on `PATH`, the eight live plugins and seven backups of
  [`fixtures/verified-summary.json`](../design/fixtures/verified-summary.json) installed, and the three
  `provenance-conflict` alerts present. Without them the acceptance numbers cannot be reproduced.
- Read [`03 §10`](../design/03-ui-overhaul-proposal.md) before T0.4: the state model this phase installs is the one the
  Phase 1 `ConfirmSheet` inherits, and getting it wrong twice costs more than reading it once.

## 2 Task list

Execution order is top to bottom. Ids match the roadmap items in `05 §3`; `T0.0` and `T0.18` are additions and say so.

| Order | Task | Touches | Blocked by | Effort |
|---|---|---|---|---|
| 1 | [T0.0](#t00-baseline-capture-added) baseline capture | nothing | — | 20 min |
| 2 | [T0.1](#t01-delete-the-never-instantiated-legacy-block) delete legacy block | 1310–2258 | T0.0 | 30 min |
| 3 | [T0.2](#t02-textformat-textplaintext-on-every-text) `Text.PlainText` sweep | 82 `Text` items | T0.1 | 1 h |
| 4 | [T0.4](#t04-one-pendingaction-instead-of-five-stacking-booleans) one `pendingAction` | ~60 sites | T0.1 | 4 h |
| 5 | [T0.18](#t018-pin-the-authorization-facts-when-the-confirmation-opens-added) pin authorization facts | 568–600, overlay | T0.4 | 2 h |
| 6 | [T0.3](#t03-make-the-confirmation-modal-and-gate-every-action-control) modal scrim + gating | 2421, 12 controls | T0.4 | 2 h |
| 7 | [T0.5](#t05-esc-cancels-the-confirmation-close-and-onopenedchanged-reset-it) Esc / close / opened | 2267, 947, root | T0.4 | 30 min |
| 8 | [T0.6](#t06-gate-the-r-key-on-one-shared-scan-condition) gate `r` | 2277, 2338 | T0.4 | 30 min |
| 9 | [T0.7](#t07-delete-the-forced-tab-jump) delete forced tab jump | 855 | — | 10 min |
| 10 | [T0.8](#t08-render-the-mutation-result) render mutation result | 3513, 5130 | T0.4 | 2 h |
| 11 | [T0.9](#t09-expand-one-review-item-not-every-item-sharing-a-rule) per-item expansion | 1166–1181, 2994 | T0.1 | 45 min |
| 12 | [T0.10](#t010-deduplicate-observed-capabilities) dedupe capabilities | 2920–2931 | T0.1 | 30 min |
| 13 | [T0.11](#t011-never-print-coverage-complete-for-missing-data) no `Coverage: complete` | 3370–3382 | T0.1 | 20 min |
| 14 | [T0.12](#t012-ask-rules-explain-for-json) `rules explain --format json` | 4830, 4861–4886 | — | 2 h |
| 15 | [T0.13](#t013-stop-the-60-second-enforcement-flash) stop enforcement flash | 936–945 | — | 20 min |
| 16 | [T0.14](#t014-stop-calling-a-catalog-claim-verified) confirm copy | 2455 | T0.4 | 10 min |
| 17 | [T0.15](#t015-render-inventory-level-coverage-limitations) inventory coverage limits | 2390 | T0.1 | 45 min |
| 18 | [T0.16](#t016-let-a-cached-analysis-survive-close-and-reopen) cache lifetime | 947, 3809, 5055, 5138 | T0.4 | 2 h |
| 19 | [T0.17](#t017-enable-and-remove-need-cli-contracts-that-do-not-exist-yet) Enable / Remove gate | 3557, 3540, 585–600 | **CLI release** | 1 d + CLI |

## 3 Tasks

### T0.0 Baseline capture (added)

**Why.** The phase's exit criterion is pixel-identity. Without a recorded baseline it cannot be checked, and "nothing
moved" becomes an opinion.

**Do.** Record `git rev-parse HEAD`. Capture `tokyo-night` at base 12: each of the four tabs, one plugin selected with
an analysis rendered, and one open trust confirmation. Save the output of the section 5 command block. Note the
counts the acceptance list quotes: 15 inventory rows (8 live, 7 backups), 4 analyzed, 10 review items, 3 outstanding
`provenance-conflict` alerts, marketplace snapshot `65b6385`, schedule not installed, no overrides, every enforcement
`decision: null`.

**Verify.** Six screenshots and one log exist outside the repo (they are not committed; Phase 4 owns the published
screenshot set).

### T0.1 Delete the never-instantiated legacy block

Roadmap 0.1 · finding A39 · **prerequisite for T0.4**

**Today.** `Panel.qml:1310` opens `Flickable { id: panelFlick; visible: false }` inside `KeyboardPanel`, holding
`Component { id: legacyContent }` at 1322. `grep -n 'panelFlick\|legacyContent' Panel.qml` returns exactly three hits
— 1311 and 1323 (the `id:` lines) and 1327 (`width: panelFlick.width`, inside the block). No `Loader` names
`legacyContent`, so the component is never instantiated. Brace depth confirms the extent: 1310 opens at depth 2 → 3
and 2258 closes 3 → 2; `PanelKeyCatcher` (2260) is a sibling inside `KeyboardPanel`, not a child of the deleted item.

Ids declared inside the block: `content`, `details`, `finding`, `legacyContent`, `panelFlick`, `pluginRow`,
`snapshotDetails`, `summary`, `summaryIcon`, `summaryStats`, `trustConfirmation`, `trustControls`,
`untrustConfirmation`. None is referenced from outside it — the three outside word matches (`details`, `finding`,
`summary`) are a comment at 508 and local JS variables at 1743/1751 and 2510. The product disclaimer sentence exists
twice (2249 inside the block, 2763 in the live Findings tab), so the deletion loses no copy.

**Why first.** The block holds a second, complete copy of the confirmation UI — `trustConfirmation` at 1991,
`untrustConfirmation` at 2079, and the trust/untrust toggles at 1872–1894 — all bound to the five `*Confirming`
booleans T0.4 removes. Left in place it would either force the same refactor twice in code that never runs, or leave
bindings to properties that no longer exist.

**Change.** Delete lines 1310–2259 (the block plus the blank line after it, leaving exactly one blank line between
1308 and `PanelKeyCatcher`). Self-checking form:

```python
lines = open('Panel.qml').read().split('\n')
assert lines[1309].strip() == 'Flickable {'
assert lines[1310].strip() == 'id: panelFlick'
assert lines[2257].strip() == '}'
assert lines[2258].strip() == ''
assert lines[2259].strip() == 'PanelKeyCatcher {'
del lines[1309:2259]
open('Panel.qml', 'w').write('\n'.join(lines))
```

**Verify.** `wc -l Panel.qml` → 4224. `grep -n 'panelFlick\|legacyContent' Panel.qml` → nothing. `qmllint` exits 0.
`grep -c 'Text {' Panel.qml` → 82 and `grep -c 'textFormat: Text.PlainText' Panel.qml` → 12 (all 44 `Text` items in
the deleted block already carried the attribute; every one of the 70 that lack it is in the live UI). The panel is
visually unchanged: the block was `visible: false` and unreferenced.

**Note.** This deletion and its assertions were executed and `qmllint`-checked while writing this plan, then reverted;
the assertion block above is the check that they still hold.

### T0.2 `textFormat: Text.PlainText` on every `Text`

Roadmap 0.2 · finding A6 · GR4

**Today.** After T0.1 the file holds 82 `Text` items; 12 set `textFormat`. The remaining 70 render CLI output, plugin
ids, file paths, rule titles and provenance strings with `textFormat` at its `Text.AutoText` default, which
interprets a string containing markup as rich text. Plugin ids and CLI messages are attacker-influenced input.

**Change.** Add `textFormat: Text.PlainText` to every `Text` that lacks it. Keep one `Text {` per line — the
acceptance gate counts lines.

**Verify.** `grep -c 'textFormat: Text.PlainText' Panel.qml` equals `grep -c 'Text {' Panel.qml` (82 = 82). The gate
is exact, not approximate: no `Text {` line is inside a comment, no line holds two of them, and there is no
`TextEdit`/`TextInput` in the file. A fixture whose plugin `id` contains `<b>x</b>` renders the tag characters
literally.

**Risk.** A `Text` that intentionally used rich text would lose formatting — none exists: `grep -nE '<b>|<i>|<a
href|StyledText|RichText' Panel.qml` returns nothing, and no `textFormat:` in the file has a value other than
`Text.PlainText`.

### T0.4 One `pendingAction` instead of five stacking booleans

Roadmap 0.4 · finding A2 · GR6 · spec [`03 §10`](../design/03-ui-overhaul-proposal.md) invariants 2 and 6

**Today.** Five independent booleans — `scheduleConfirming` (29), `trustConfirming` (87), `untrustConfirming` (88),
`reviewUpdateConfirming` (90), `enableConfirming` (101) — drive one overlay. Nothing prevents two from being true at
once, and the overlay resolves the conflict by declaration order in three separate `if` chains: the title at 2437, the
confirm label at 2559–2563 and the confirm action at 2571. The identity block (2470) and the policy row (2507) have
their own visibility conditions, so a stale flag can print one action's identity under another action's title.
`navigationLocked` (144–146) ORs all five.

**Change.** Replace the five booleans with one enum plus a dispatcher. New root state:

```qml
// The single pending confirmation. "" means none is open; otherwise it names the one
// action the open confirmation authorizes, and the only action its confirm button may
// run. Confirmations never stack: a request arriving while one is open is dropped.
readonly property var pendingActions: ["record", "replace", "remove", "enable", "review-update", "schedule"]
property string pendingAction: ""
readonly property bool baselineWritePending: root.pendingAction === "record" ||
  root.pendingAction === "replace"

readonly property bool navigationLocked: root.operationRunning || root.pendingAction !== ""

// Returns false when a request is dropped, so no caller assumes its action is armed.
function requestConfirmation(action) {
  if (root.pendingActions.indexOf(String(action)) < 0) return false
  if (root.pendingAction !== "" || root.operationRunning) return false
  root.pendingAction = String(action)
  return true
}

function clearPendingAction() {
  root.pendingAction = ""
  root.clearAuthorizedTarget()          // T0.18
}

// The confirm button's only entry point. One switch, no if-order.
function runPendingAction() {
  if (root.pendingAction === "schedule") root.runScheduleInstall()
  else if (root.pendingAction === "review-update") root.runReviewUpdate()
  else if (root.pendingAction === "enable") root.runEnable()
  else if (root.baselineWritePending) root.trustSelectedPlugin()
  else if (root.pendingAction === "remove") root.untrustSelectedPlugin()
}
```

`record` versus `replace` is decided **when the confirmation opens**, from `statusReport.trusted`, not re-derived on
every binding evaluation — see T0.18. Site-by-site:

| Site today | Change |
|---|---|
| 29, 87, 88, 90, 101 | delete the five `property bool *Confirming` declarations |
| 144–146 | `navigationLocked` as above |
| 809–816 (`selectPlugin` cancels a pending review-update / enable whose plugin changed) | keep the behaviour, expressed on `pendingAction`: cancel when `pendingAction === "review-update" && id !== reviewUpdatePluginId`, likewise for `enable`, and set the same two error strings |
| 819–820 (`selectPlugin` clears trust/untrust) | `if (root.baselineWritePending \|\| root.pendingAction === "remove") root.clearPendingAction()` |
| 896 (`beginScheduleInstall`) | `if (!root.requestConfirmation("schedule")) return` after the existing policy validation |
| 900 (`runScheduleInstall` guard) | `if (root.pendingAction !== "schedule" \|\| !root.cliVerified \|\| root.operationRunning) return` |
| 1214 (`beginReviewUpdate`), 1224 (`beginEnable`) | same pattern with `"review-update"` / `"enable"`; keep every value capture that precedes it |
| 1248–1249, 1277–1278 (`targetStillExact` guards) | read `pendingAction` instead of the boolean; keep both error strings and the guards themselves — they stay feedback checks, never the authorization boundary |
| 2423–2424 (overlay `visible`) | `visible: root.pendingAction !== ""` |
| 2437–2442 (title chain) | one lookup on `pendingAction`: `record` → `TRUST CURRENT IDENTITY?`, `replace` → `REPLACE TRUST BASELINE?`, `remove` → `REMOVE TRUST BASELINE?`, `enable` → `ENABLE PLUGIN?`, `review-update` → `REVIEW UPDATE?`, `schedule` → `INSTALL SCHEDULE?` |
| 2451–2461 (body chain) | same lookup; T0.14 rewrites the review-update sentence |
| 2469–2492 (identity block) | `visible: root.pendingAction !== "" && root.pendingAction !== "schedule"`; content from the pinned values of T0.18 |
| 2507 (policy row), 2511, 2519, 2525, 2533 (chips) | `visible: root.pendingAction === "review-update" \|\| root.pendingAction === "enable"`; the chips keep writing `reviewUpdatePolicyChoice` / `enablePolicyChoice` |
| 2542–2556 (Cancel) | `onClicked: root.clearPendingAction()` |
| 2559–2563 (confirm label) | one lookup: `Install schedule` · `Review update` · `Enable plugin` · `Trust identity` (record) · `Replace baseline` (replace) · `Untrust plugin` (remove) |
| 2570–2576 (confirm action) | `onClicked: root.runPendingAction()` |
| 3533–3538, 3548–3553 (trust / untrust `onClicked` handlers) | `onClicked: root.beginTrust()` / `root.beginRemove()` — the two new openers in T0.18 |
| 4445, 4460, 4471, 4498 (schedule paths) | `root.clearPendingAction()` where the code cleared `scheduleConfirming`; the failure paths keep the sheet open exactly as today by *not* clearing |
| 4963 (enable success) | `root.clearPendingAction()` |
| 5022, 5036, 5052, 5079 (review-update paths) | same |
| 5106–5107, 5122–5123, 5135–5136, 5147–5148, 5161–5162 (trust paths, which clear both booleans) | one `root.clearPendingAction()` per site |

**Verify.** `grep -c 'Confirming' Panel.qml` → 0. With a trust confirmation open, pressing Install advisory schedule
(after T0.3 it is disabled; before T0.3, with the scrim still non-modal) leaves the title, identity block and confirm
button on the trust action and starts nothing. `qmllint` exits 0.

### T0.18 Pin the authorization facts when the confirmation opens (added)

Not a roadmap item. Found while verifying `05 §3`; recorded as PF-10 in
[`07 §8`](../design/07-verification-findings.md). Spec [`03 §10`](../design/03-ui-overhaul-proposal.md) invariant 8 and
`05 §4` ("`runPendingAction()` copies these immutable sheet values into argv. It never reconstructs authorization from
whichever plugin happens to be selected at click time"), which the design assigns to the Phase 1 sheet — leaving the
drift live for a whole phase.

**Today.** `trustSelectedPlugin()` (568) reads `root.selectedPlugin()` **at confirm time** (569) and builds
`--expected-head` / `--expected-tree` / `--expected-digest` from that row (571–574). The overlay's identity block
(2469–2492) reads the same live row. Nothing pins either. The window between the two is reachable:

1. Click **Update catalog** (3663). It is gated only on `marketplaceRefreshProcess.running`, is not part of
   `operationRunning`, and runs up to 60 s.
2. While it runs, **Trust source** / **Replace baseline** (3524, 3540) is still enabled (`!operationRunning`), so the
   confirmation opens and displays digest `D1`.
3. The refresh exits 0 (3958) → `marketplaceRefreshAwaitingInventory = true` → `reloadInventoryForRefresh()` (716) →
   `inventoryProcess` → `applyInventory` (962) replaces `inventoryReport`. The plugin row now carries `D2`.
4. The user clicks **Trust identity**. The argv carries `D2`. The CLI's `--expected-*` comparison passes, because it
   compares against the value the panel just re-read — so the CLI cannot catch this, and a baseline is recorded for an
   identity the user was never shown.

The same window flips the title between `TRUST CURRENT IDENTITY?` and `REPLACE TRUST BASELINE?` (2440–2442, derived
live from `statusReport.trusted`), and moves the Remove sheet's displayed baseline digest when a `plugins status`
re-fetch lands. T0.3 and T0.6 close the *user-initiated* routes into this window; an already-in-flight refresh and the
status sweep remain.

**Change.** Capture the facts once, at open, and pass those exact values to argv.

```qml
// Facts the open confirmation authorizes. Written once by the begin* openers, read by
// the overlay and by argv, cleared with the pending action. Never re-derived.
property string authorizedPluginId: ""
property string authorizedHead: ""
property string authorizedTree: ""
property string authorizedDigest: ""
property string authorizedBaselineDigest: ""

function clearAuthorizedTarget() {
  root.authorizedPluginId = ""
  root.authorizedHead = ""
  root.authorizedTree = ""
  root.authorizedDigest = ""
  root.authorizedBaselineDigest = ""
}

function beginTrust() {
  var plugin = root.selectedPlugin()
  if (!plugin || !root.canTrustSelectedPlugin()) return
  var replacing = !!(root.statusReport && root.statusReport.trusted)
  if (!root.requestConfirmation(replacing ? "replace" : "record")) return
  root.trustError = ""
  root.authorizedPluginId = plugin.id
  root.authorizedHead = String(plugin.head || "")
  root.authorizedTree = String(plugin.tree || "")
  root.authorizedDigest = String(plugin.content_digest || "")
  root.authorizedBaselineDigest = replacing && root.statusReport.trusted
    ? String(root.statusReport.trusted.content_digest || "") : ""
}

function beginRemove() {
  if (!root.canUntrustSelectedPlugin()) return
  if (!root.requestConfirmation("remove")) return
  root.trustError = ""
  root.authorizedPluginId = root.selectedPluginId
  root.authorizedBaselineDigest = root.statusReport && root.statusReport.trusted
    ? String(root.statusReport.trusted.content_digest || "") : ""
}
```

`trustSelectedPlugin()` then builds argv from the pinned values and refuses on drift:

```qml
function trustSelectedPlugin() {
  if (!root.baselineWritePending || root.authorizedDigest === "") return
  var plugin = root.pluginById(root.authorizedPluginId)
  var stillExact = plugin && root.selectedPluginId === root.authorizedPluginId &&
    String(plugin.content_digest || "") === root.authorizedDigest &&
    String(plugin.head || "") === root.authorizedHead &&
    String(plugin.tree || "") === root.authorizedTree
  if (!stillExact) {
    root.clearPendingAction()
    root.panelError = "Cancelled: " + root.authorizedPluginId +
      " changed since the confirmation opened."
    return
  }
  var args = ["plugins", "trust", root.authorizedPluginId, "--yes",
              "--note", "trusted from OmaSafe panel"]
  if (root.authorizedHead !== "") args.push("--expected-head", root.authorizedHead)
  if (root.authorizedTree !== "") args.push("--expected-tree", root.authorizedTree)
  args.push("--expected-digest", root.authorizedDigest)
  // …unchanged: reset trust state, trustOperation = "trust", timers, launch
}
```

The overlay identity block reads `authorizedHead` / `authorizedTree` / `authorizedDigest` (and
`authorizedBaselineDigest` for `remove` and for the `Recorded` line under `replace`), each rendering `unavailable`
when empty — a null git field stays visibly unavailable rather than being omitted (GR3). `untrustSelectedPlugin()`
performs the same drift check against `authorizedBaselineDigest` and `statusReport.trusted.content_digest`; it still
sends no expected value, because 0.2.1 has no flag for one (T0.17).

**Boundaries.** This is a QML feedback guard plus an argv contract, not atomicity: only the CLI comparing under the
mutation lock is the authorization boundary (`05 §1.1`). What it buys is that the values reaching the CLI are exactly
the values the user was shown.

**Verify.** With `contract-cases.json`'s stale-authorization case: open Record baseline, replace the fixture inventory
with a changed digest, confirm → no process starts, the panel prints `Cancelled: <id> changed since the confirmation
opened.` and the confirmation closes. Under the manual replay shim, run the four-step sequence above: the argv logged
by the shim carries `D1`, not `D2`. `grep -n 'expected-digest' Panel.qml` shows the flag built only from
`authorizedDigest`.

### T0.3 Make the confirmation modal and gate every action control

Roadmap 0.3 · finding A2 · spec [`03 §10`](../design/03-ui-overhaul-proposal.md) invariants 4 and 5

**Today.** The overlay at 2421 is `Rectangle { anchors.fill: parent; color: Util.alpha(Color.background, 0.94);
z: 20 }` with no `MouseArea`. Nothing behind it is blocked: the wheel scrolls `activeFlick` under the card, and every
control keeps its own hit area. The gating is inconsistent in three different ways, verified control by control:

| Control | Span | `enabled` today | Reachable during a confirmation |
|---|---|---|---|
| Scan | 2333–2346 | `hostWidget && cliVerified && statusLevel !== "checking"` | yes — starts a scan |
| Install advisory schedule | 2727–2736 | `cliVerified && !operationRunning && !scheduleLoading` | yes — opens a second confirmation |
| Install hardened schedule | 2737–2747 | same | yes |
| Explain rule | 2994–3004 | **none** | yes — launches `rules explain` |
| Show provenance | 3019–3026 | **none** | yes — view state |
| Show coverage details | 3106–3113 | **none** | yes — view state |
| Open Plugins tab | 3173–3180 | **none** | no-op (`setActive` self-gates at 526) but looks live |
| Show override details | 3287–3294 | **none** | yes — view state |
| Show decision details | 3456–3464 | **none** | yes — view state |
| Trust source / Replace baseline | 3524–3539 | `!operationRunning` | yes |
| Untrust | 3540–3554 | `!operationRunning` | yes |
| Enable inactive plugin | 3557–3567 | `!operationRunning` | yes |
| Review update | 3569–3578 | `updateEligible() && !operationRunning` | yes |
| Update catalog | 3663–3671 | `cliVerified && !marketplaceRefreshProcess.running` | yes — **even while a mutation runs** |
| Show plugin backups | 3689–3697 | **none** | yes — view state |

The row `MouseArea`s already gate correctly on `!root.navigationLocked` (2324, 2836, 3233, 3773) and need no change.

**Change.** Two edits.

1. Insert a swallowing `MouseArea` as the **first** child of the overlay `Rectangle` (before the card `Column` at
   2430, so the card's own buttons stay above it):

```qml
      // The confirmation is modal: while an authorization is pending, nothing behind
      // the scrim may be clicked, hovered or scrolled.
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: function(wheel) { wheel.accepted = true }
      }
```

2. Bind `enabled` to `!root.navigationLocked` on every control in the table above — appending `&& !root.navigationLocked`
   where a binding exists, and **adding the binding** to the eight controls that have none. The four buttons inside the
   card (2510, 2524, 2542, 2558) keep `!root.operationRunning`: they are the confirmation.

Do not gate `Flickable.interactive` on `navigationLocked`: `03 §3` keeps the body scrollable during the up-to-60 s
CLI calls, and the scrim's `MouseArea` already stops the wheel while a sheet is open.

**Verify.** With a trust confirmation open: clicking Update catalog, Install advisory schedule, Explain rule and every
expander does nothing; the wheel does not scroll; a second confirmation request is dropped (T0.4). No visual change —
`Button` disabled styling appears only while the scrim covers the button.

### T0.5 Esc cancels the confirmation; `close()` and `onOpenedChanged` reset it

Roadmap 0.5 · finding A3 · spec [`03 §10`](../design/03-ui-overhaul-proposal.md) invariants 6 and 9

**Today.** `onCloseRequested: root.close()` (2267) closes the panel mid-confirmation. `close()` (947–955) never
resets the flags, and there is no `onOpenedChanged` handler, so the next open shows the dialog again with tab
switching locked — the panel can only be recovered by cancelling a confirmation the user thought they had dismissed.

**Change.**

```qml
    onCloseRequested: {
      if (root.pendingAction !== "") root.clearPendingAction()
      else root.close()
    }
```

Add `root.clearPendingAction()` as the first statement of `close()`, and on the root:

```qml
  // A confirmation is never left armed behind a closed panel: whatever closes it — Esc,
  // the bar button, a popout switch, the compositor — drops the pending action.
  onOpenedChanged: if (!root.opened) root.clearPendingAction()
```

`opened` is the kit's `readonly property bool opened: panelController.open` (`Ui/Panel.qml:21`), so the handler is
valid in this derived component and also covers the closes that never call `close()`:
`closeForPopoutSwitch()` (`Ui/Panel.qml:26`) and `bar.switchPanelFrom`. Both resets are idempotent.

**Verify.** Press Replace baseline, then Esc: the dialog closes, the panel stays open, `pendingAction === ""`. Close
and reopen: no dialog, tabs switch. Open a confirmation and switch bar panels with Tab: reopening shows no dialog.

### T0.6 Gate the `r` key on one shared scan condition

Roadmap 0.6 · finding A4

**Today.** `onTextKey` (2272) runs `hostWidget.runScan()` (2278) with no gate at all, so `r` starts a scan during a
confirmation; the scan's `onAlertsChanged` (3808) then clears the analysis cache and re-fetches enforcement under the
open dialog. The Scan button (2338–2339) already gates on `cliVerified && statusLevel !== "checking"` — the same
condition, written separately.

**Change.** Declare the condition once and use it in both places:

```qml
  readonly property bool scanAvailable: root.cliVerified &&
    root.statusLevel !== "checking" && !root.navigationLocked
```

`Button.enabled: root.scanAvailable` at 2338–2339, and in `onTextKey`:

```qml
      else if (t === "r" || t === "R") {
        if (root.scanAvailable && root.hostWidget) root.hostWidget.runScan()
      }
```

**Do not** write `!hostWidget.checking` here. `checking` is a Phase 1 declaration (`03 §2` on `BarWidget`, `03 §3` on
the panel root); Phase 0 does not touch `BarWidget.qml`, and because `hostWidget` is `property var` (13) the premature
lookup evaluates `!undefined` → `true`, silently dropping the scan-in-progress guard with no `qmllint` error. Phase 1
re-spells `scanAvailable` with `!root.checking`. `statusLevel` is the panel's own alias at 155 (BW:117), already
tested inline at 196, 219, 2153, 2336 and 2783.

The digit keys 1–4 (2273–2276) need no change: `setActive()` returns early on `navigationLocked` (526–527).

**Verify.** With a confirmation open, `r` starts no process and the analysis under the dialog is untouched. With no
confirmation, `r` still scans. While a scan runs, `r` is inert and the Scan button is disabled.

### T0.7 Delete the forced tab jump

Roadmap 0.7 · finding A1

**Today.** `selectPlugin(id, alert)` ends with `if (alert) root.setActive(1)` (855). Two callers pass an alert:
`applyInventory`'s initial selection (989) — so opening with alerts lands on Findings whatever tab the user left — and
`trustProcess.onExited` on success (5139), which yanks the user out of Plugins after a successful trust.

**Change.** Delete line 855.

**Why this loses no navigation.** The other three call sites are unaffected: 3237 (plugin row, Plugins tab) and 3777
(catalog row, Catalog tab) pass `null`, and 2841 — the alert card click that *does* pass an alert — is inside
`findingsTabComponent` (`Component` 2772, `id:` 2773, ends 3185), where `setActive(1)` is already a no-op. Tab
component boundaries for reference: overview 2584–2771, findings 2772–3185, plugins 3186–3591, catalog 3592–3790.

**Verify.** Open with 3 outstanding alerts from the Plugins tab: the panel stays on Plugins. Confirm a trust from
Plugins: the view does not change. Click an alert card in Findings: the plugin is selected and the tab does not move.

### T0.8 Render the mutation result

Roadmap 0.8 · finding A1 · spec [`02 §3.3`](../design/02-design-principles.md) and
[`03 §5.5`](../design/03-ui-overhaul-proposal.md)

**Today.** `trustOutput` is written at 576 and 588 (reset), accumulated at 5102, and read only by the 2 MiB cap check
at 5103. Nothing renders it, so a successful trust or untrust shows nothing at all — the dialog vanishes, the cache is
cleared (T0.16 stops that) and a scan starts, with no statement that anything was recorded.

**Change.** Render the success line in the Plugins tab, next to `selectedError` (3513–3520), keyed on the CLI's own
words rather than exit status alone (GR3):

- stdout contains `Trusted identity recorded` → `Baseline recorded for <id> at digest <first 12 of digest>.`, or
  `Baseline replaced for <id> at digest <12>.` when the pending action was `replace`
- stdout contains `Review decision recorded` → `Baseline removed for <id>.`
- exit 0 without the expected phrase → no positive line; render the neutral existing error/empty state

Add one root `property string mutationMessage: ""`, set it in `trustProcess.onExited` (5130–5150) from
`root.authorizedPluginId` and `root.authorizedDigest` (T0.18 pinned them, so the line names the identity that was
authorized), clear it in `selectPlugin` beside `selectedError` (827) and on the next `beginTrust` / `beginRemove`.
The full success-line set for enable, review update, schedule and catalog is `03 §5.5`; Phase 0 renders only the two
trust lines, and Phase 2 adds the rest with the rows.

After a trust operation the row's trust word becomes the loading word `checking…` until the `plugins status` re-fetch
supplies `state` — never `matches baseline` on the panel's own authority (`02 §3.2`).

**Verify.** Confirm a trust on a plugin whose head matches: exit 0 renders `Baseline recorded for <id> at digest
<12>.` in place, the view does not change, and no scan is triggered by the message itself. A fixture whose stdout
lacks the phrase renders no positive line.

### T0.9 Expand one review item, not every item sharing a rule

Roadmap 0.9 · finding A17

**Today.** `findingKey(finding)` (1161–1164) composes `rule_id : relative_path : line` and is called nowhere.
`explainRule(ruleId)` (1166) sets `expandedFindingKey = id` (1169) — the rule id — and the expander at 2994–3003
compares `root.expandedFindingKey === String(modelData.rule_id || "")`. All ten review items in the fixture share
`oma.qml.dynamic-reference`, so expanding one expands all ten.

**Change.** Key the expansion on the finding, not the rule. Split the two concerns: the expander sets
`expandedFindingKey = root.findingKey(modelData)` and calls `explainRule(modelData.rule_id)` for the CLI fetch;
`explainRule` no longer writes `expandedFindingKey` (delete 1169). The rule-explanation cache stays keyed on
`cliVersion + rule_id` (1170) — one fetch still serves every item sharing the rule.

**Verify.** With the ten `oma.qml.dynamic-reference` items, Enter on the third expands the third only; Enter on it
again collapses it; the explanation text is fetched once for the ten.

### T0.10 Deduplicate observed capabilities

Roadmap 0.10 · finding A7

**Today.** 2920–2931 renders `"Observed capabilities: " + capabilities.map(…).join(", ")` with no grouping: 54 tokens
for `io.github.tuthan.omasafe`, 36 of them identical repeats of the same class.

**Change.** Group by `capability` and print `<class> ×<n>` in the existing single `Text`, keeping catalog order
(`02 §2.7`) rather than occurrence order. A class with one occurrence prints without a count.

**Verify.** `io.github.tuthan.omasafe`'s analysis renders two capability classes with counts, not 54 tokens;
`lgse.sandman` renders its classes with `process-execution ×16` among them. No line wraps to a third row at base 12.

### T0.11 Never print `Coverage: complete` for missing data

Roadmap 0.11 · finding A8 · GR3

**Today.** 3376: `"\nCoverage: " + ((p.limitations || []).join(", ") || "complete")`. A plugin whose `limitations`
field is absent — not empty, absent — renders `complete`, which is the panel asserting coverage it has no data for.
The second occurrence at 1737 disappears with T0.1.

**Change.**

```qml
              "\nCoverage: " + (Array.isArray(p.limitations)
                ? (p.limitations.length ? p.limitations.join(", ") : "No limitations reported")
                : "Coverage unavailable")
```

**Verify.** A fixture with `limitations` absent renders `Coverage unavailable`; with `[]` renders `No limitations
reported`; with codes renders the codes. The word `complete` no longer appears in the file:
`grep -n '"complete"' Panel.qml` → nothing.

### T0.12 Ask `rules explain` for JSON

Roadmap 0.12 · finding A13

**Today.** 4830 runs `["rules", "explain", id]` with no `--format json`. The handler at 4861–4886 parses stdout,
falls back to `JSON.stringify(report.result …)` when the expected fields are missing (4871), and renders the result as
one blob at 3008 — so a schema change or a plain-text answer prints a JSON dump at the user.

**Change.** Append `"--format", "json"` at 4830. In `onExited` (4861), require
`String(report.schema) === "omasafe.report.v1"` before using the payload, render the named `result.rule.*` fields
rather than a stringified object, and on any parse or schema failure set
`Rule explanation unavailable: <stderr first line>`. Delete the `JSON.stringify` fallback. Keep the cache write
(4876–4879), the 15 s timeout, the 2 MiB cap and the `cacheKey === ruleExplanationKey` guard (4865) unchanged.

**Verify.** Explain a rule: the panel renders the rule's fields, and no `{` appears in the rendered text. With the
shim returning exit 1, the line reads `Rule explanation unavailable: …`. With the shim returning valid JSON under a
different `schema`, the same unavailable line appears — never a partial render.

### T0.13 Stop the 60-second enforcement flash

Roadmap 0.13 · finding A21

**Today.** `enforcementRefreshTimer` (4680–4689) fires every 60 s while the panel is open and calls
`refreshEnforcementStatus()` (936), whose first act is `enforcementDecision = null` (939) followed by
`enforcementLoading = true` (941). The ENFORCEMENT section therefore drops to its loading string once a minute even
though a decision is already known. `onAlertsChanged` (3810) calls the same function.

**Change.** In `refreshEnforcementStatus()`: delete line 939 and make the loading flag conditional —

```qml
    root.enforcementError = ""
    root.enforcementLoading = root.enforcementDecision === null
```

Both callers are refreshes of an existing decision, so one edit fixes both. Selection changes still clear the decision
(`selectPlugin` 823–825), and the failure path is unchanged: `enforcementStatusProcess.onExited` still sets
`enforcementDecision = null` with `Enforcement status is unavailable.` (4301–4302) when the refresh fails, so a failed
refresh never leaves a stale decision presented as current (GR3).

**Verify.** With the panel open five minutes, the enforcement section never shows its loading string after the first
load, and the rendered decision is replaced only when a new report is applied. With the shim failing
`enforcement-status`, the section shows unavailable within one refresh cycle.

### T0.14 Stop calling a catalog claim "verified"

Roadmap 0.14 · finding A10 · GR2

**Today.** The review-update confirmation body (2455) reads `Update <id> at the verified commit below and trust the
result.` The commit is a marketplace *claim*; nothing has verified it at the moment the sentence is read.

**Change.** Replace `the verified commit below` with `the commit the catalog snapshot claims; the CLI verifies it
before anything changes`. The final sheet copy is `02 §3.7` / `03 §10`; Phase 0 fixes only the false word.

**Verify.** `grep -n 'verified commit' Panel.qml` → nothing. The rendered sentence names the claim and its verifier.

### T0.15 Render inventory-level coverage limitations

Roadmap 0.15 · finding A9 · GR4

**Today.** `applyInventory` (962) stores the whole `result` in `inventoryReport` (14), including
`result.coverage.limitations[]`, and nothing reads it — the panel silently drops the CLI's statement about what its own
inventory pass could not cover.

**Change.** Insert one `Text` in `tabShell` between the status-row `Item` (2349–2389) and `activeFlick` (2391):

```qml
      Text {
        width: parent.width
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        visible: {
          var coverage = root.inventoryReport && root.inventoryReport.coverage
          return !!coverage && Array.isArray(coverage.limitations) && coverage.limitations.length > 0
        }
        text: {
          var coverage = root.inventoryReport && root.inventoryReport.coverage
          var codes = coverage && Array.isArray(coverage.limitations) ? coverage.limitations : []
          return "Inventory coverage limited: " + codes.join(" · ")
        }
        color: Util.alpha(root.contentForeground, 0.70)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
```

Codes are printed verbatim in Phase 0. The four-grammar, prefix-first limitation parser lives in `model/Labels.js`
(`02 §3.4`) and Phase 2 re-homes this line as a `NoticeRow` under the hero.

**Verify.** A fixture with `coverage.limitations: ["a", "b"]` renders `Inventory coverage limited: a · b` under the
status row; with `[]` or the field absent the line is not visible — which is the case on this machine, so the
pixel-identity criterion holds.

### T0.16 Let a cached analysis survive close and reopen

Roadmap 0.16 · spec [`01 §2.7`](../design/01-research-and-audit.md) item 5 and `01 §8.7`

**Today.** `clearAnalysisCache()` (1147–1159) wipes the whole cache *and* the single-slot display state. It runs from
six places: `close()` (947–948), `onAlertsChanged` (3809 — i.e. after every scan whose alerts change, and the bar
left-click scans before it opens, BW:532–535), `onCliVersionChanged` (3799), an installed-set signature change (974),
review-update success (5055) and trust/untrust success (5138). Every reopen therefore starts cold, and the Phase 3
graph would need `A` — eight bounded processes — on each open.

**Change.** The cache key already fails closed: `cacheAnalysis` (1134–1145) stores `digest`, `cliVersion` and
`policyKey`, and `ensureAnalysis` (1104–1107) requires all three to match, so a changed identity or analyzer policy
misses without any clearing.

- Remove the calls at 947–948, 5055 and 5138.
- Keep 3799 (`onCliVersionChanged`) and 974 (installed-set signature change) as wholesale clears.
- Replace 3809 with a selective drop: collect `plugin_id` from `root.alerts` whose `kind` is `analyzer-policy-update`
  or `source-drift` and remove only those keys.

The selective drop needs a new function, because `clearAnalysisCache()` also resets the display slot:

```qml
  // Drop only the named plugins' cached analyses. The cache key already misses on a
  // changed digest, CLI version or analyzer policy; these two alert kinds are the cases
  // where the key can still match but the analysis is no longer trustworthy.
  function dropAnalysisCacheFor(ids) {
    if (!ids || ids.length === 0) return
    var next = ({})
    for (var key in root.analysisCache)
      if (ids.indexOf(key) < 0) next[key] = root.analysisCache[key]
    root.analysisCache = next
    if (ids.indexOf(root.analysisPluginId) >= 0) {
      root.analysisRequestId++
      root.analysisPluginId = ""
      root.analysisDigest = ""
      root.analysisCliVersion = ""
      root.analysisPolicyKey = ""
      root.analysisReport = null
      root.analysisCoverageStates = null
      root.analysisLoading = false
      root.analysisDetailsExpanded = false
    }
  }
```

`close()` keeps its other resets (the `nextPluginId` / `nextRuleId` clears, `coverageReport`, `coverageCliVersion`,
`coverageDetailsExpanded`) and gains `clearPendingAction()` from T0.5.

**Verify.** Analyze `lgse.sandman`, close and reopen the panel: the analysis renders from cache with no
`plugins analyze` process. A scan whose alerts name no `analyzer-policy-update` / `source-drift` for it leaves the
entry; one that does drops only that plugin's entry; a CLI version change clears everything. No pixel change on a
first open.

### T0.17 Enable and Remove need CLI contracts that do not exist yet

Roadmap 0.17 · finding A2 · GR6 · **blocked on a CLI release**

**Today.** Enable (3557) shows the current identity in the confirmation but `plugins enable` accepts no expected
identity (argv 1260–1263), and Remove (3540) shows the recorded baseline while the untrust branch (585–600) sends no
expected value either. Both confirmations therefore display facts the CLI will not check.

**Change, in three parts.**

1. **File the CLI issues** (`05 §12`): Enable requires `--expected-digest` and accepts `--expected-head` /
   `--expected-tree` when present; Remove requires `--expected-trusted-digest`; each compares while holding the
   mutation lock and refuses without writing on mismatch. This is the blocking ask; everything else on that list is an
   enhancement.
2. **Gate the two controls now.** Until a release implements both, render Enable and Remove unavailable with the
   missing-contract reason. Do not reuse `cliVersionRequireIdentity` (BW:75–76) for this: despite the name it asserts
   that `--version` output contains `omasafe` (BW:188), a check on the binary's identity, not on mutation contracts.
   Add instead:

```qml
  // First CLI release implementing the expected-identity contracts for Enable and
  // Remove (05 §10). Empty means the capability does not exist yet; no version is
  // guessed before the release does.
  readonly property string cliMinIdentityMutations: ""
  readonly property bool identitySafeMutations: {
    if (root.cliMinIdentityMutations === "" || !root.hostWidget) return false
    var have = root.hostWidget.parseVersion(root.hostWidget.cliVersion)
    var need = root.hostWidget.parseVersion(root.cliMinIdentityMutations)
    return !!have && !!need && root.hostWidget.compareVersion(have, need) >= 0
  }
```

   `parseVersion` (BW:161) and `compareVersion` (BW:168) are existing `BarWidget` functions. Bind both controls'
   `enabled` on `identitySafeMutations` and print the reason where the ineligible-verb copy goes (`02 §3.5`).
3. **When the release lands**, add the argv, raise `manifest.json` `cliVersionMin` to that exact version, set
   `cliMinIdentityMutations` to the same string, and run the stale-authorization tests.

**Verify.** On CLI 0.2.1 both controls are unavailable and name the missing CLI support; no other control changes.
Against the first supporting CLI: open either sheet, mutate the source or baseline out of band, confirm → the CLI
refuses and writes nothing, and the panel reloads the facts. `manifest.json` `cliVersionMin` equals that release.

## 4 Commit plan

| Commit | Tasks | Why grouped |
|---|---|---|
| 1 | T0.1 | one mechanical deletion, reviewable as "≈ 950 unreferenced lines gone"; keep it alone |
| 2 | T0.2 | 70 one-line additions; noise in any other commit |
| 3 | T0.4 + T0.18 + T0.3 + T0.5 + T0.6 | the confirmation cluster: the state model, its pinned facts, its modality and its two escape routes are one behaviour. Splitting them ships a half-locked dialog |
| 4 | T0.7 + T0.8 | the tab jump and the missing result line are the same "what happened after I confirmed?" defect |
| 5 | T0.9 + T0.10 + T0.11 + T0.14 | four local truth fixes, no shared state |
| 6 | T0.12 | one argv plus its handler rewrite |
| 7 | T0.13 | one binding |
| 8 | T0.15 | one new `Text` |
| 9 | T0.16 | cache lifetime, independently revertable if a reviewer disputes the policy |
| 10 | T0.17 part 2 | the capability gate; parts 1 and 3 are not code in this repository |

Run the section 5 block before and after every commit. Commit 3 is the one to bisect if a keyboard or dialog
regression appears.

## 5 Acceptance

Everything in `docs/cli-v0.2-plan.md:229–246` still passes, plus:

- [ ] `qmllint -I /usr/share/omarchy/shell -I /usr/lib/qt6/qml Panel.qml BarWidget.qml OmaSafeStatusIcon.qml` exits 0;
      `omarchy plugin validate .` exits 0.
- [ ] `grep -c 'textFormat: Text.PlainText' Panel.qml` equals `grep -c 'Text {' Panel.qml` (82 = 82). *T0.2*
- [ ] `grep -c 'Confirming' Panel.qml` → 0; `grep -n 'panelFlick\|legacyContent\|"complete"\|verified commit' Panel.qml`
      → nothing. *T0.1, T0.4, T0.11, T0.14*
- [ ] Open with 3 outstanding alerts: the panel stays on the tab that was active when it closed. *T0.7*
- [ ] Press Replace baseline, press Esc: the dialog closes, the panel stays open, `pendingAction === ""`; close and
      reopen shows no dialog. *T0.5*
- [ ] With a trust confirmation open: Update catalog, Install advisory schedule and Explain rule do nothing; the wheel
      does not scroll; `r` starts no scan; a second confirmation request is ignored. *T0.3, T0.4, T0.6*
- [ ] Confirm a trust on a plugin whose head matches: exit 0 renders `Baseline recorded for <id> at digest <12>.`, the
      view does not change, and the analysis cache is not cleared. *T0.8, T0.16*
- [ ] Stale-authorization case: with a confirmation open, change the fixture's digest, then confirm → no process runs
      and the panel prints `Cancelled: <id> changed since the confirmation opened.` *T0.18*
- [ ] Under the replay shim, the argv of a confirmed trust carries the digest that was displayed when the confirmation
      opened, not the digest that arrived while it was open. *T0.18*
- [ ] A plugin whose `id` fixture contains `<b>x</b>` renders the tag characters literally. *T0.2*
- [ ] `limitations` absent → `Coverage unavailable`; `[]` → `No limitations reported`. *T0.11*
- [ ] `io.github.tuthan.omasafe` renders two capability classes with counts, not 54 tokens. *T0.10*
- [ ] Ten `oma.qml.dynamic-reference` items: Enter on one expands one. *T0.9*
- [ ] Over five minutes open, the enforcement section never shows its loading string after the first load. *T0.13*
- [ ] `rules explain` renders named fields; a schema mismatch renders `Rule explanation unavailable: …`. *T0.12*
- [ ] Inventory `coverage.limitations: ["a","b"]` → `Inventory coverage limited: a · b`; `[]` or absent → no line.
      *T0.15*
- [ ] Analyze `lgse.sandman`, close and reopen: cache hit, no process; a `source-drift` alert for it drops only its
      entry; a CLI version change clears everything. *T0.16*
- [ ] On CLI 0.2.1, Enable and Remove are unavailable and explain that identity-safe CLI support is required. *T0.17*
- [ ] Before/after screenshots in `tokyo-night` at base 12 are identical except the strings named in T0.8, T0.11,
      T0.14 and T0.15.

## 6 Risks and rollback

| Risk | Likelihood | Mitigation |
|---|---|---|
| The confirmation refactor (commit 3) breaks a branch that only a rare fixture reaches | medium | the site table in T0.4 is exhaustive — work it row by row and re-`grep 'Confirming'` after each; the `contract-cases.json` stale-authorization and multiple-block cases exercise the odd paths |
| T0.1 deletes something referenced by a path not exercised in review | low | the three-hit `grep`, the id audit and the brace-depth check in T0.1; `qmllint` fails on a dangling reference; the commit is a pure deletion and reverts cleanly |
| T0.16 is disputed as a policy change rather than a fix | medium | it is the one item whose *behaviour* (not correctness) changes; kept in its own commit so it can be reverted without touching the rest |
| Line anchors drift as tasks land | high | anchors are `de594d4`; work top-down and re-`grep` for the named symbol instead of trusting a number |
| `Text.PlainText` on an intentionally rich `Text` | none found | verified absent (T0.2) |

Rollback: every commit is independent except commit 3, which reverts as a unit. Reverting commit 3 restores the five
booleans and the non-modal scrim together — do not revert it partially.

## 7 Sources

- [`05 §3`](../design/05-implementation-roadmap.md) item table and acceptance list; `05 §1.1` never-changes list;
  `05 §10` CLI matrix; `05 §12` CLI asks.
- [`01 §2.4`](../design/01-research-and-audit.md) mutation contracts, `01 §2.6` range map, `01 §2.7` item 5,
  `01 §3` findings A1–A4, A6–A10, A13, A17, A21, A39.
- [`02 §3.3`](../design/02-design-principles.md) status and success strings, `02 §3.4` enum labels and the limitation
  grammar, `02 §3.5` ineligible-verb copy, `02 §3.7` confirmation template.
- [`03 §5.5`](../design/03-ui-overhaul-proposal.md) actions and success lines, `03 §10` confirmation invariants.
- [`07 §8`](../design/07-verification-findings.md) PF-08 (the `checking` phase dependency in T0.6), PF-09 (per-button
  gating in T0.3), PF-10 (the pinned facts of T0.18).
- Working tree at `de594d4`: `Panel.qml`, `BarWidget.qml`, `manifest.json`; installed kit `Ui/Panel.qml:21, 26`.
