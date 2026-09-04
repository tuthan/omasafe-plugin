# Plugin Source Scan contract

This document records the plugin-side implementation of the OmaSafe CLI v0.2.2
candidate route. The plugin is a UI consumer: parsing, acquisition, Git
identity, analysis, report sizing, and policy remain CLI responsibilities.

## Route

The dedicated **Source Scan** tab is a non-destructive review surface when the running
CLI is at least `0.2.2`. It contains one multiline text control labelled
**GitHub URL or copied install command**. QML performs only the empty-input check
and passes the complete value as one argv item:

```text
omasafe-cli scan-plugin --request INPUT --report-profile review --format json
```

The panel does not parse shell syntax, fetch URLs, clone repositories, unpack
archives, render source, or execute candidate content. It has no candidate
Install, Enable, Trust, Suppress, Override, Schedule, or Approve action.

## Accepted report boundary

The view accepts only an outer `omasafe.report.v1` report with CLI version
`>=0.2.2`, nested `omasafe.acquisition.v1` and `omasafe.analysis.v1`,
`operation: "scan-only"`, `installation_performed: false`, a full resolved
Git commit, matching `target.revision` and exact integrity facts, and
`suppressions.policy: "candidate-unsuppressed"` with no consulted or applied
records. Candidate reports must use the `review` profile and include omission
arithmetic for payload entries, findings, capabilities, and invocation edges.

Marketplace candidates are attributed to the CLI's verified cached catalog
claim. The panel never substitutes a live branch head for the CLI-resolved
identity. Display text is bounded and shown as plain text; it is never treated
as instructions.

## State and failure behavior

The transient view uses `idle`, `resolving`, `fetching`, `analyzing`,
`complete`, `unavailable`, and `cancelled` states. Remote candidate runs have a
120-second timeout, bounded TERM-to-KILL cleanup, and a 2 MiB-character cap per
stdout/stderr stream. Closing or cancelling invalidates the request generation
so a late process exit cannot update the view.

Results are retained only in a session-local cache keyed by resolved commit,
policy identity, and report profile. The pasted request is not persisted. The
result always shows the exact commit and a copyable `--git URL --revision
COMMIT` rescan command. Findings, capabilities, invocation edges, and coverage
limitations retain their total/emitted/omitted markers; omission prevents an
empty-list conclusion. If the findings list is complete and contains no high or
critical finding, the view shows a suggested `omarchy plugin add|install`
command derived from the resolved repository URL. This is display/copy only;
the plugin never runs it. The command stays hidden for omitted, unknown, high,
or critical findings.

## Acceptance checks

- `qmllint -I . Panel.qml views/CandidateView.qml views/OverviewView.qml`
- `node scripts/candidate-test.js`
- The candidate argv is literal and contains the original multiline request as
  one value.
- Unsupported, malformed, stale, partial, timed-out, cancelled, and interrupted
  runs remain visibly non-clean.
- No candidate control starts an install or lifecycle mutation.
