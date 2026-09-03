// Time.js — relative time and age formatting for the OmaSafe panel (doc 02 §3.3).
//
// This module owns NO policy threshold. In particular `(stale)` is appended to an
// age when and only when the caller passes the CLI's own `result.marketplace_stale`
// flag as true (omasafe-cli decides staleness, main.rs:4649); the panel keeps no
// threshold of its own, so a change to the CLI's policy never leaves the two
// disagreeing. A pure JS module: it never calls into QML.
.pragma library

var MINUTE = 60
var HOUR = 60 * MINUTE
var DAY = 24 * HOUR

// Parse an ISO-8601 string to epoch milliseconds, or NaN when unparseable.
function _ms(iso) {
  if (!iso) return NaN
  var t = Date.parse(String(iso))
  return t
}

// Relative time for a past instant, lowercase (the hero kit uppercases meta):
// `just now` (< 60 s) · `<n> min ago` · `<n> h ago` · `yesterday` · `<n> days ago`.
// The exact ISO value belongs in a tooltip, not here. Returns "" for a value that
// cannot be parsed so the caller can fall back to `unavailable`.
function relative(iso, nowMs) {
  var t = _ms(iso)
  if (isNaN(t)) return ""
  var now = (nowMs === undefined) ? Date.now() : nowMs
  var s = Math.max(0, Math.round((now - t) / 1000))
  if (s < MINUTE) return "just now"
  if (s < HOUR) return Math.floor(s / MINUTE) + " min ago"
  if (s < DAY) return Math.floor(s / HOUR) + " h ago"
  var days = Math.floor(s / DAY)
  if (days === 1) return "yesterday"
  return days + " days ago"
}

// Age of a snapshot from a duration in seconds: `<n> min old` · `<n> h old` ·
// `<n> days old`, with ` (stale)` appended when `stale` is true. `stale` is the
// CLI flag, never derived here.
function age(seconds, stale) {
  var s = Math.max(0, Math.round(Number(seconds) || 0))
  var text
  if (s < HOUR) text = Math.floor(s / MINUTE) + " min old"
  else if (s < DAY) text = Math.floor(s / HOUR) + " h old"
  else text = Math.floor(s / DAY) + " days old"
  return stale === true ? text + " (stale)" : text
}
