// Tiers.js — the one owner of the semantic tier colour ladder (doc 02 §2.3, 08 D1).
//
// The ladder used to live inside `components/SemanticMark.qml`, which was fine while a
// row marker was the only thing that painted a tier. The v0.3.1 charts (`MeterBar`,
// `RankedBars`, `UnitStrip`) need the same ladder for a segment fill and a strip cell,
// and a second copy of it is a second thing to drift. So the ladder moves here and
// `SemanticMark` becomes its first consumer with an unchanged public API.
//
// This is a pure JS module: it never calls into QML and never reads `Style` or `Color`.
// The caller passes the theme background in (`isDark(Color.background)`) exactly as the
// Glyphs module takes the resolved font family — a pure module is handed its context.
//
// Colour is the THIRD channel (02 §2.4, 08 CH4). Every consumer of `color()` must also
// print the level's word and draw its glyph; nothing here may be the sole carrier of a
// meaning.
.pragma library

// Rec. 709 relative luminance over a QML color (r/g/b in 0..1). A theme is "dark" below
// 0.5, which is where the two variants of each tier swap.
function isDark(background) {
  if (!background) return true
  var r = Number(background.r), g = Number(background.g), b = Number(background.b)
  if (!isFinite(r) || !isFinite(g) || !isFinite(b)) return true
  return (r * 0.2126 + g * 0.7152 + b * 0.0722) < 0.5
}

// Fold the level aliases the CLI and the views use into the canonical tier keys.
// Moved verbatim from `SemanticMark.normalizedLevel`, plus `not_applicable`.
//
// `incomplete` stays distinct from `high`: they shared the `alert` glyph until the
// v0.3.1 glyph table separated them, and they never shared a colour.
function normalize(level) {
  var v = String(level === null || level === undefined ? "" : level).toLowerCase()
  if (v === "error" || v === "blocked") return "critical"
  if (v === "warning") return "medium"
  if (v === "normal" || v === "ok" || v === "pass") return "healthy"
  if (v === "checking" || v === "loading") return "checking"
  if (v === "not analyzed" || v === "not-analyzed" || v === "incomplete") return "incomplete"
  if (v === "not_applicable" || v === "not-applicable" || v === "notapplicable") return "notApplicable"
  if (["healthy", "critical", "high", "medium", "low", "info", "stale", "unknown"].indexOf(v) >= 0) return v
  return "unknown"
}

// The tier colour for an ALREADY-NORMALIZED level, or "" when the tier carries no colour
// of its own and the caller must fall back to its `dim` role. Returning "" rather than a
// gray keeps the dim ladder (02 §2.3 `dimStep`) owned by the call site's theme roles.
//
// `dark` is the boolean from `isDark()`, not a colour, so this function stays trivially
// testable.
function color(level, dark) {
  switch (normalize(level)) {
  case "healthy": return dark ? "#72d394" : "#19733d"
  case "medium": return dark ? "#f2d16b" : "#8a6200"
  case "high": return dark ? "#ffb064" : "#a34f00"
  case "critical": return dark ? "#ff7777" : "#b42318"
  case "incomplete": return dark ? "#f2a65a" : "#9a4d00"
  case "low": return dark ? "#9bc8ff" : "#2b65a3"
  case "info": return dark ? "#9bc8ff" : "#2b65a3"
  default: return ""
  }
}

// True when `color()` yields a tier colour rather than the dim fallback. Lets a chart
// decide whether a segment needs its own paint without string-comparing the result.
function hasColor(level) { return color(level, true) !== "" }
