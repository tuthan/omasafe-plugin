// Glyphs.js — the one glyph table for the OmaSafe panel (doc 02 §2.7).
//
// Nerd Font codepoints plus an ASCII fallback column, verified by codepoint AND
// glyph name against JetBrainsMonoNerdFont-Regular.ttf with fontTools. The
// expected md-name is carried beside each codepoint so the Phase 1 acceptance
// check reads the same table the panel does; presence alone is not enough (an
// earlier pass accepted F099F/F10A2/F0053 because they existed, while the font
// maps them to the wrong glyphs).
//
// This is a pure JS module: it never calls into QML. `useAscii(family)` and the
// `*(family)` accessors take the resolved font family as a parameter, so the
// ASCII column is chosen when the user-selected family is not a Nerd Font.
.pragma library

// name -> { cp, name, nerd, ascii }. `cp` and `name` document the verification;
// `nerd` is the rendered glyph; `ascii` is the legibility-floor fallback.
function _g(cp, name, ascii) {
  return { cp: cp, name: name, nerd: String.fromCodePoint(cp), ascii: ascii }
}

// UI glyphs (doc 02 §2.7 "UI glyphs").
var ui = {
  "shield-filled":   _g(0xF0483, "md-security", "S"),          // scan result exists
  "shield-outline":  _g(0xF0499, "md-shield_outline", "s"),    // no current scan result
  "in-flight":       _g(0xF0996, "md-progress_clock", "/"),
  "rescan":          _g(0xF0450, "md-refresh", "@"),
  "copy":            _g(0xF018F, "md-content_copy", "c"),
  "back":            _g(0xF0141, "md-chevron_left", "<"),
  "open":            _g(0xF0142, "md-chevron_right", ">"),
  "expand":          _g(0xF0140, "md-chevron_down", "v"),
  "collapse":        _g(0xF0143, "md-chevron_up", "^"),
  "alert":           _g(0xF0026, "md-alert", "!"),             // alert / differs / high
  "info":            _g(0xF02FD, "md-information_outline", "i"),
  "critical":        _g(0xF0029, "md-alert_octagon", "O"),     // alert-octagon
  "medium":          _g(0xF0765, "md-circle", "*"),            // filled circle
  "hollow":          _g(0xF0766, "md-circle_outline", "o"),    // not analyzed / unavailable, Flow only
  "rule":            _g(0xF09EE, "md-file_document_outline", "R"),
  "block":           _g(0xF00AD, "md-block_helper", "X"),      // enforcement block
  "catalog":         _g(0xF01BC, "md-database", "B"),          // catalog / Baseline V3
  "large-view":      _g(0xF1049, "md-graph", "#"),
  "git-checkout":    _g(0xF02A2, "md-git", "g"),
  "installed-no-git":_g(0xF03D7, "md-package_variant_closed", "p"),
  "backup":          _g(0xF120E, "md-archive_outline", "b"),
  "unsupported":     _g(0xF0625, "md-help_circle_outline", "?")
}

// Capability classes, in catalog order (doc 02 §2.7 "Capability classes"). The
// position is meaningful, so the strip renders them in this exact order.
var capability = {
  "process-execution":          _g(0xF018D, "md-console", "PX"),
  "detached-process-execution": _g(0xF03CC, "md-open_in_new", "DX"),
  "filesystem-access":          _g(0xF0256, "md-folder_outline", "FS"),
  "sensitive-path":             _g(0xF0306, "md-key", "SP"),
  "input-injection":            _g(0xF030C, "md-keyboard", "IN"),
  "screen-capture":             _g(0xF0E51, "md-monitor_screenshot", "SC"),
  "network-access":             _g(0xF059F, "md-web", "NW"),
  "persistence-scheduling":     _g(0xF051B, "md-timer_outline", "TM"),
  "clipboard-access":           _g(0xF014C, "md-clipboard_outline", "CB"),
  "compositor-control":         _g(0xF0379, "md-monitor", "WM"),
  "polkit-agent-ui":            _g(0xF0BC4, "md-shield_key", "PK"),
  "session-lock-surface":       _g(0xF0341, "md-lock_outline", "LK"),
  "pam-authentication":         _g(0xF000B, "md-account_key", "PA"),
  "dynamic-code-execution":     _g(0xF0169, "md-code_braces", "DC"),
  "shell-ipc-inventory":        _g(0xF0318, "md-lan_connect", "IPC"),
  "replaces-bar-context":       _g(0xF1513, "md-dock_top", "BAR"),
  "bundled-binary":             _g(0xF035B, "md-memory", "BIN")
}

// The catalog order of the capability keys — one array, defined once, so the
// strip and matrix always render classes at the same position on every plugin.
var capabilityOrder = [
  "process-execution", "detached-process-execution", "filesystem-access",
  "sensitive-path", "input-injection", "screen-capture", "network-access",
  "persistence-scheduling", "clipboard-access", "compositor-control",
  "polkit-agent-ui", "session-lock-surface", "pam-authentication",
  "dynamic-code-execution", "shell-ipc-inventory", "replaces-bar-context",
  "bundled-binary"
]

// The ASCII column is a legibility floor, chosen only when the resolved family
// is not a Nerd Font. `family` is passed in (a pure module never reads Style).
function useAscii(family) {
  return String(family || "").indexOf("Nerd") < 0
}

function _pick(entry, family) {
  if (!entry) return ""
  return useAscii(family) ? entry.ascii : entry.nerd
}

// Resolve a UI glyph by name for the given resolved family.
function ui_(name, family) { return _pick(ui[name], family) }

// Resolve a capability-class glyph; an unknown class returns the unsupported mark.
function cap(cls, family) { return _pick(capability[cls] || ui["unsupported"], family) }
