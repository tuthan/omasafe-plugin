# OmaSafe Omarchy plugin

OmaSafe is an Omarchy bar widget and review panel. It displays scan state and
opens the review panel; the scanning engine is the separate `omasafe-cli`
binary maintained in the main OmaSafe repository.

The plugin runs as unsandboxed QML inside `omarchy-shell`. Review the source
before enabling it. The plugin does not download, install, or execute a release
asset at runtime. Installing the plugin and installing the CLI are intentionally
separate operations.

The plugin id is `io.github.tuthan.omasafe`. Browse it in the
[Omarchy plugin marketplace](https://plugins.omarchy.org/index.html); the
marketplace catalog is maintained in the
[marketplace repository](https://github.com/omacom/omarchy-plugin-marketplace).

Visit the [OmaSafe landing page](https://tuthan.github.io/omasafe/) for the
project overview and roadmap.

## Screenshots and demo

<table>
  <tr>
    <td align="center"><strong>Clean scan state</strong><br><img src="media/clear.png" alt="OmaSafe clean scan state" width="420"></td>
    <td align="center"><strong>Review-needed state</strong><br><img src="media/warning.png" alt="OmaSafe review-needed state" width="420"></td>
  </tr>
</table>

<p align="center">
  <img src="media/roadmap.png" alt="OmaSafe roadmap" width="900">
</p>

<p align="center"><strong>Demo video</strong></p>



https://github.com/user-attachments/assets/d745387c-61ed-4e2c-9f2f-294dda72807c



## How it works

The plugin is the bar widget and review panel; `omasafe-cli` is the engine. The
panel calls the CLI (`plugins inventory`, `plugins status`, `plugins diff`,
`plugins trust`, `plugins review`) and renders what it returns — it never makes
a safety judgment of its own. Two independent signals drive the panel:

**1. Local trust and drift detection.** OmaSafe tracks the source of every
installed plugin against a per-plugin *trust baseline*.

- **Trust** — trusting a plugin records a baseline of its current source
  (expected head, tree, and content digest). The plugin then reads as
  `Baselined & unchanged`.
- **Detect drift** — each scan re-derives the installed plugin's source and
  compares it to that baseline. If the bytes changed, the plugin flips to
  `Source changed` (a `source-drift` finding) and the panel can show the exact
  diff. This is what catches a plugin that was silently modified or updated
  after you trusted it.
- **Untrust** — untrusting clears the baseline; the plugin returns to
  `No trust baseline` and is no longer vouched for until you trust it again.

Trust is local and operator-driven: nothing is trusted until you trust it, and
a missing or failed scan is never shown as clean.

**2. Marketplace verification (independent of local trust).** For plugins listed
in the marketplace, the panel also surfaces the catalog's own claims, bound to a
pinned catalog snapshot:

- **Snapshot integrity** — whether the catalog snapshot was verified against the
  official pinned commit (`Verified against pinned catalog commit`) or is only an
  unverified cache / local file.
- **Listing verify / unverify** — the marketplace's `verified` or `unverified`
  claim for that listing.
- **Commit comparison and drift** — whether the installed commit matches the
  listing's validated commit, and whether the upstream commit has moved past it.

Marketplace verification is a claim attributed to the catalog snapshot, **not an
OmaSafe safety verdict** and **not the same as local trust**. A listing can be
marketplace-verified while its installed source has drifted from your local
baseline — the panel shows both so the two are never conflated.

## Requirements

- Omarchy with shell plugin support
- `omasafe-cli` installed and available on the `omarchy-shell` session `PATH`

It is valid to install this plugin before the CLI. Until the CLI is available,
the widget shows `CLI` and does not imply that the system is clean.

## Install the CLI

The CLI is released separately from this plugin by the
[main OmaSafe repository](https://github.com/tuthan/omasafe). Download the
matching `omasafe-cli-<version>-x86_64-linux.tar.gz` archive and
its `.sha256` file from the [OmaSafe GitHub releases](https://github.com/tuthan/omasafe/releases).
Verify the checksum, extract the archive, and install the binary in a location
visible to the graphical Omarchy session. For a per-user install:

```sh
sha256sum --check omasafe-cli-<version>-x86_64-linux.tar.gz.sha256
tar -xzf omasafe-cli-<version>-x86_64-linux.tar.gz
install -Dm755 omasafe-cli-<version>-x86_64-linux/omasafe-cli \
  "$HOME/.local/bin/omasafe-cli"
```

The plugin does not download or install the CLI automatically. Do not pipe a
remote script to a shell; inspect the release archive and checksum before
installing.

The plugin checks `~/.local/bin/omasafe-cli`, `/usr/local/bin/omasafe-cli`,
`/usr/bin/omasafe-cli`, and finally the `omarchy-shell` session `PATH`. If you
install elsewhere, move the binary to one of those locations or update the
session environment and restart the shell. Verify the dependency before
expecting scan results:

```sh
command -v omasafe-cli
omasafe-cli --version
omasafe-cli scan --format json
```

Periodic scanning is disabled by default. Enable `Enable periodic scans` in the
plugin's bar-widget settings if desired, then choose `Periodic scan interval
(minutes)` (1–1440 minutes). Manual scans remain available by clicking the
widget. With periodic scanning disabled the plugin does not run the external CLI
at shell startup — it only locates the binary and runs `--version`; a scan is
executed at startup only when periodic scanning is enabled.

### CLI compatibility gate

Before any scan is run or trusted, the plugin resolves `omasafe-cli`, runs
`--version`, and requires it to exit `0` and report a parseable version.
A binary that does not behave like a versioned omasafe-cli is rejected and the
widget shows an `incompatible` state instead of running scans. This is a
compatibility check, not an authenticity control: `--version` output is
self-reported, so verify the binary's checksum at install time (above) to defend
against a tampered or substituted CLI.

Operators can tighten the gate via the plugin's bar-widget settings:

- `cliVersionMin` — reject any CLI older than this version (default `0.2.1`).
- `cliVersionRequireIdentity` — require the `--version` output to contain
  `omasafe`.

The plugin requires CLI `0.2.1` or newer by default; operators can raise the
floor, while identity checking remains opt-in.

The v0.2 integration enables analysis-backed scan alerts, a lazy Findings view
for `plugins analyze`, rule explanations and Baseline V3 coverage claims. The
v0.2.1 integration adds CLI-owned enforcement and schedule status, confirmed
advisory/hardened enable and reviewed-update controls, and read-only override
and recovery details. The panel renders these versioned reports as claims and
decisions from the CLI; it does not re-evaluate policy, expiry, coverage, or
plugin safety in QML. A CLI 0.2.0 binary is therefore rejected by the default
floor because it cannot provide the v0.2.1 hardening contract.

The scan may exit with status `0` (quiet) or `3` (findings); both statuses are
successful JSON-producing results. The CLI creates its XDG configuration, state,
and cache directories automatically on first use:

```text
${XDG_CONFIG_HOME:-~/.config}/omasafe
${XDG_STATE_HOME:-~/.local/state}/omasafe
${XDG_CACHE_HOME:-~/.cache}/omasafe
```

### Marketplace verification display

The review panel displays the marketplace context returned by
`omasafe-cli plugins inventory --format json`:

- whether the cached catalog snapshot matches the exact catalog bytes at the
  pinned official repository commit (`pinned-fetch`) or is an unverified cache;
- the marketplace's `verified` / `unverified` claim for the selected listing;
- whether the installed plugin commit matches the listing-validated commit; and
- whether the marketplace-observed upstream commit moved beyond that validated
  commit.

Snapshot verification binds catalog bytes to a pinned commit; it does not verify
a Git commit signature. Listing verification is a marketplace claim attributed
to the displayed snapshot, not an OmaSafe safety verdict. Missing data is shown
as unavailable rather than treated as verified.

The panel's **Update catalog** button is a manual network action. It asks the CLI
to resolve the official marketplace `main` branch to its current exact commit,
then fetches and verifies that pinned snapshot. A successful update immediately
reloads the panel inventory. Normal inventory commands, scans, and scheduled
scans remain offline and never update the catalog automatically.

## Install

Install from the published git repository or the Omarchy plugin marketplace.
The marketplace/plugin installation does not install `omasafe-cli` for you.
Replace the URL below with the repository URL if it changes:

```sh
omarchy plugin add https://github.com/tuthan/omasafe-plugin.git --enable
```

The command clones the repository into:

```text
~/.config/omarchy/plugins/io.github.tuthan.omasafe/
```

Without `--enable`, install first, review the checkout, then enable it:

```sh
omarchy plugin enable io.github.tuthan.omasafe --section right
```

The `right` placement matches this plugin's manifest default. Use
`omarchy plugin list` to confirm the installed id and enabled state.

After installing the CLI, refresh the running shell:

```sh
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.tuthan.omasafe --section right
```

If the plugin was already enabled, disable and re-enable it after installing
the CLI if a shell restart did not reload the environment. The widget shows
`CLI` while the dependency is missing and displays the CLI error in its panel;
it never treats a missing or failed CLI as a clean scan.

The add, update, and remove commands are interactive when run without
`--yes`. Use `--yes` for scripted or unattended use.

## Disable or remove

Disable the widget but keep its files installed:

```sh
omarchy plugin disable io.github.tuthan.omasafe
```

Remove the installed plugin checkout:

```sh
omarchy plugin remove io.github.tuthan.omasafe
```

Removing this plugin does not remove `omasafe-cli`; the CLI is an independent
dependency. Removing the CLI does not remove the plugin checkout.

## Update an installed copy

For a plugin installed with `omarchy plugin add`, update the checkout with:

```sh
omarchy plugin update io.github.tuthan.omasafe
```

Omarchy fetches the git changes, shows the diff, and fast-forwards the local
checkout after confirmation. To update every git-managed plugin, run:

```sh
omarchy plugin update
```

Updating the plugin does not update `omasafe-cli`. Update the CLI separately
using the [main OmaSafe repository](https://github.com/tuthan/omasafe) installer
or Arch package. Likewise, updating the CLI does not change the installed
plugin revision.

## Local development

See [docs/cli-v0.2-plan.md](docs/cli-v0.2-plan.md) for the v0.2 feature
mapping and [docs/cli-v0.2.1-plan.md](docs/cli-v0.2.1-plan.md) for the
implemented hardening contract and compatibility boundary.

Omarchy expects a real plugin directory, so local development uses `rsync`
instead of a symlink. Run this from the repository root:

```bash
plugin_dir="$HOME/.config/omarchy/plugins/io.github.tuthan.omasafe"
mkdir -p "$(dirname "$plugin_dir")"
if [ -L "$plugin_dir" ]; then unlink "$plugin_dir"; fi
mkdir -p "$plugin_dir"
rsync -a --delete --exclude='.git/' "$PWD"/ "$plugin_dir"/
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.tuthan.omasafe --section right
```

Validate the source before enabling it:

```bash
omarchy plugin validate .
qmllint BarWidget.qml Panel.qml
```

After changing `BarWidget.qml`, `Panel.qml`, or `manifest.json`, refresh the
installed copy:

```bash
rsync -a --delete --exclude='.git/' "$PWD"/ \
  "$HOME/.config/omarchy/plugins/io.github.tuthan.omasafe"/
omarchy-shell shell rescanPlugins
```

The `.git` directory stays in the source checkout and is not copied into the
runtime plugin directory. Do not use `omarchy plugin update` for this local
copy; update the source checkout with git, then run the `rsync` command above.

To stop using the local copy:

```bash
omarchy plugin disable io.github.tuthan.omasafe
omarchy plugin remove io.github.tuthan.omasafe
```

## Validate locally

Run these checks before committing or publishing:

```bash
omarchy plugin validate .
qmllint BarWidget.qml Panel.qml
```

The plugin is described by the root [`manifest.json`](manifest.json). The CLI
release and Arch package are published from the main OmaSafe repository.
