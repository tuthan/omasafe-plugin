// FlowLayout.js — the pure layout engine for the Trust Flow graph (doc 04 §4).
//
// No QML objects, no timers, no Style access: build(input, geo) turns a flowInput
// (ViewModel.flowInput, doc 04 §3.2) plus numeric geometry into node arrays, ordered
// and windowed, edge geometry (cubic Bézier PathSvg strings) and the eight bucket
// path strings. hot(layout, cursorKey, pinnedKey) re-buckets on cursor/pin change
// only. TrustFlow.qml keeps `nodes`, `geometry` and `paths` as three properties with
// three reassignment cadences (§3.2) so a slide or a window move never touches the
// Repeater models.
.pragma library

// ---- small helpers ------------------------------------------------------------

function _arr(v) { return Array.isArray(v) ? v : [] }
function _str(v) { return String(v === null || v === undefined ? "" : v) }
function _num(v) { var n = Number(v); return isFinite(n) ? n : 0 }
function _cap(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : s }

function _riskText(level, kind) {
  var r = _str(level)
  if (r === "") return ""
  if (r === "healthy") return " · no active alerts"
  if (r === "stale") return " · stale result"
  if (r === "unknown" || r === "incomplete" || r === "checking") return " · " + r
  return " · " + r + (kind === "health" ? " alert" : " risk")
}

// ---- edge helpers -------------------------------------------------------------

// dashed when every backing fact is lexical-fallback or null — i.e. no parser-backed
// support at all (doc 04 §2.2, contract case `edge-confidence-is-local`). A mixed
// edge (parserBacked > 0 && lexicalOnly > 0) stays solid.
function edgeDashed(e) {
  if (e.dashed === true || e.dashed === false) return e.dashed
  var s = e.support || {}
  return _num(s.parserBacked) === 0
}

function bucketOf(w) { return w >= 10 ? "thick" : (w >= 4 ? "med" : "thin") }

// Mixed-evidence inspector fragment, or "" when not mixed (doc 04 §5, §9.4).
function mixedEvidence(support) {
  var s = support || {}
  var pb = _num(s.parserBacked), lo = _num(s.lexicalOnly)
  if (pb > 0 && lo > 0)
    return "mixed evidence: " + pb + " parser-backed · " + lo + " text-match-only"
  return ""
}

// ---- node identity ------------------------------------------------------------

function key(ref) { return ref[0] + "|" + ref[1] }

var _layerOfKind = { plugin: 0, class: 1, rule: 2, baseline: 3 }

// ---- node sets (doc 04 §4.1 step 1 + display fields, §5) -----------------------

function _pluginNode(p) {
  var state = _str(p.analysis)                    // not analyzed | analyzing | analyzed | unavailable
  var analyzed = state === "analyzed"
  var riskLevel = _str(p.riskLevel)
  var count
  if (analyzed) count = _str(p.occurrences)
  else if (state === "analyzing") count = "…"
  else if (state === "unavailable") count = "unavailable"
  else count = "–"
  var suffix = (analyzed && _num(p.limits) > 0) ? " · " + p.limits + " limits" : ""
  return {
    key: key(["plugin", p.id]), layer: "plugins", id: p.id, label: p.id, count: count,
    glyphKey: "", hollow: !analyzed && state !== "analyzing", analyzing: state === "analyzing",
    bold: _num(p.outstanding) > 0, urgent: p.block === true, faint: p.faint === true,
    suffix: suffix, tooltip: p.id + (suffix ? suffix : "") + _riskText(riskLevel, "health"),
    occurrences: _num(p.occurrences), classes: _num(p.classes),
    reviewItems: _num(p.reviewItems), limits: _num(p.limits),
    outstanding: _num(p.outstanding), analyzed: analyzed,
    riskLevel: riskLevel
  }
}

function _classNode(c) {
  var riskLevel = _str(c.riskLevel || c.severity)
  return {
    key: key(["class", c.id]), layer: "classes", id: c.id, label: c.name || c.id,
    count: _str(c.occurrences), glyphKey: c.id, hollow: false, analyzing: false,
    bold: false, urgent: false, faint: c.faint === true, suffix: "",
    tooltip: (c.name || c.id) + " · " + c.occurrences + " in " + c.plugins + _riskText(riskLevel, "severity"),
    occurrences: _num(c.occurrences), plugins: _num(c.plugins), reviewItems: _num(c.reviewItems),
    riskLevel: riskLevel
  }
}

function _ruleNode(r, analyzedCount) {
  var riskLevel = _str(r.riskLevel || r.severity)
  return {
    key: key(["rule", r.id]), layer: "rules", id: r.id, label: r.id,
    count: analyzedCount > 0 ? _str(r.hits) : "–", glyphKey: "", hollow: false,
    analyzing: false, bold: false, urgent: false, faint: r.faint === true, suffix: "",
    tooltip: r.id + (r.title ? " · " + r.title : "") + _riskText(riskLevel, "severity"),
    occurrences: _num(r.occurrences), reviewItems: _num(r.reviewItems), hits: _num(r.hits),
    plugins: _num(r.plugins), severity: _str(r.severity), language: _str(r.language),
    title: _str(r.title), riskLevel: riskLevel
  }
}

function _baselineNode(b) {
  if (b.sentinel) {
    return { key: key(["baseline", "__none__"]), layer: "baseline", id: "", label: "not analyzed",
      count: "–", glyphKey: "", hollow: false, analyzing: false, bold: false, urgent: false,
      faint: true, suffix: "", tooltip: "not analyzed", sentinel: true, covered: false }
  }
  var rel = _str(b.relation)
  var mark = rel === "structural-equivalent" ? "=" : (rel === "partial-overlap" ? "≈" : "")
  var viaClasses = _arr(b.viaClasses)
  var covered = rel !== "not-covered" && rel !== ""
  return {
    key: key(["baseline", b.id]), layer: "baseline", id: b.id, label: b.id, count: mark,
    glyphKey: (viaClasses.length > 0 && _arr(b.viaRules).length === 0) ? viaClasses[0] : "",
    hollow: false, analyzing: false, bold: false, urgent: false, faint: !covered,
    suffix: "", tooltip: b.id, relation: rel, viaClasses: viaClasses,
    viaRules: _arr(b.viaRules), note: _str(b.note), covered: covered
  }
}

// Column node arrays in occurrence/catalog order (pre-sort); sort keys attached.
function nodeSets(input) {
  var analyzedCount = 0
  var plugs = _arr(input.plugins)
  for (var i = 0; i < plugs.length; i++) if (_str(plugs[i].analysis) === "analyzed") analyzedCount++

  var plugins = plugs.map(_pluginNode)
  var classes = _arr(input.classes).map(_classNode)
  var rules = _arr(input.rules).map(function(r) { return _ruleNode(r, analyzedCount) })
  var baseline = _arr(input.baseline).map(_baselineNode)

  return [
    { kind: "plugins", nodes: plugins },
    { kind: "classes", nodes: classes },
    { kind: "rules", nodes: rules },
    { kind: "baseline", nodes: baseline }
  ]
}

// ---- order keys (doc 04 §4.1 step 2) ------------------------------------------

function _cmpStr(a, b) { return a < b ? -1 : (a > b ? 1 : 0) }

function primaryCompareFor(kind) {
  switch (kind) {
    case "plugins":  // outstanding desc, analyzed first, id asc
      return function(a, b) {
        if (a.outstanding !== b.outstanding) return b.outstanding - a.outstanding
        if (a.analyzed !== b.analyzed) return a.analyzed ? -1 : 1
        return _cmpStr(a.id, b.id)
      }
    case "classes":  // occurrences desc, id asc
      return function(a, b) {
        if (a.occurrences !== b.occurrences) return b.occurrences - a.occurrences
        return _cmpStr(a.id, b.id)
      }
    case "rules":    // local hits desc, then review items desc, occurrences desc, id asc
      // Doc 04 §4.1 step 2 names "reviewItems desc" but the §9.1/§9.2 wireframes and
      // acceptance draw the column in local-hits order (persistence 49 first, then
      // 45, 14, 10, 8, 4); review items is the genuine tie-break within equal hits.
      return function(a, b) {
        if (a.hits !== b.hits) return b.hits - a.hits
        if (a.reviewItems !== b.reviewItems) return b.reviewItems - a.reviewItems
        if (a.occurrences !== b.occurrences) return b.occurrences - a.occurrences
        return _cmpStr(a.id, b.id)
      }
    default:         // baseline: map order (input order) — stable, no reordering
      return function(a, b) { return 0 }
  }
}

// stable sort with a fallback tie-break on the node's original index.
function _stableSort(list, cmp) {
  var withIdx = list.map(function(n, i) { return { n: n, i: i } })
  withIdx.sort(function(x, y) {
    var c = cmp(x.n, y.n)
    return c !== 0 ? c : x.i - y.i
  })
  return withIdx.map(function(e) { return e.n })
}

// ---- barycentre tie-break (doc 04 §4.1 step 3, §4.2) --------------------------

function _indexMap(nodes) {
  var m = {}
  for (var i = 0; i < nodes.length; i++) m[nodes[i].key] = i
  return m
}

// Order `target` column nodes tied on their primary key by the weighted mean row of
// their neighbours in the `ref` column. Primary key stays dominant.
function barycentre(cols, targetCol, refCol) {
  var pos = _indexMap(cols[refCol].nodes)
  var target = cols[targetCol].nodes
  for (var i = 0; i < target.length; i++) {
    var n = target[i]
    var links = (n.neighbours && n.neighbours[refCol]) ? n.neighbours[refCol] : []
    var wsum = 0, acc = 0, seen = 0
    for (var j = 0; j < links.length; j++) {
      var p = pos[links[j].key]
      if (p === undefined) continue
      var w = _num(links[j].weight) || 1
      acc += p * w; wsum += w; seen++
    }
    if (seen > 0 && wsum > 0) n.bc = acc / wsum
    else if (n.bc === undefined) n.bc = i
  }
  var primary = primaryCompareFor(cols[targetCol].kind)
  cols[targetCol].nodes = _stableSort(target, function(a, b) {
    var c = primary(a, b)
    if (c !== 0) return c
    var d = (a.bc === undefined ? 0 : a.bc) - (b.bc === undefined ? 0 : b.bc)
    if (d !== 0) return d
    return (a._idx === undefined ? 0 : a._idx) - (b._idx === undefined ? 0 : b._idx)
  })
}

// Attach neighbour links (per adjacent column) from the edge list, for barycentre.
function attachNeighbours(cols, edges) {
  var colOf = {}
  for (var c = 0; c < cols.length; c++)
    for (var i = 0; i < cols[c].nodes.length; i++) {
      cols[c].nodes[i].neighbours = { }
      cols[c].nodes[i]._idx = i
      colOf[cols[c].nodes[i].key] = { col: c, node: cols[c].nodes[i] }
    }
  for (var e = 0; e < edges.length; e++) {
    var a = colOf[key(edges[e].from)], b = colOf[key(edges[e].to)]
    if (!a || !b) continue
    var w = _num(edges[e].w) || 1
    if (!a.node.neighbours[b.col]) a.node.neighbours[b.col] = []
    if (!b.node.neighbours[a.col]) b.node.neighbours[a.col] = []
    a.node.neighbours[b.col].push({ key: b.node.key, weight: w })
    b.node.neighbours[a.col].push({ key: a.node.key, weight: w })
  }
}

// ---- same-epoch order preservation (doc 04 §4.1 step 3) -----------------------

// Keep the previous drawn order for keys that survive; append genuinely new keys at
// the column end. Neither key-sort nor barycentre runs. Removed keys drop out.
function preserveOrderAndAppend(newNodes, prevKeys) {
  if (!prevKeys || prevKeys.length === 0) return newNodes
  var byKey = {}
  for (var i = 0; i < newNodes.length; i++) byKey[newNodes[i].key] = newNodes[i]
  var out = [], used = {}
  for (var p = 0; p < prevKeys.length; p++) {
    var n = byKey[prevKeys[p]]
    if (n && !used[n.key]) { out.push(n); used[n.key] = true }
  }
  for (var q = 0; q < newNodes.length; q++)
    if (!used[newNodes[q].key]) { out.push(newNodes[q]); used[newNodes[q].key] = true }
  return out
}

// ---- geometry + windowing (doc 04 §4.1 steps 4–5) -----------------------------

// Columns snap: pair columns get openW, rails get railW; the gap between two open
// columns is the edge lane (pairGutter), any other gap is railGutter.
function _placeColumns(cols, geo) {
  var pair = geo.pair || [true, true, false, false]
  var x = 0, out = []
  for (var i = 0; i < 4; i++) {
    var open = pair[i] === true
    var w = open ? geo.openW : geo.railW
    out.push({ key: cols[i].kind, x: x, width: w, open: open })
    var nextOpen = pair[i + 1] === true
    x += w + ((open && nextOpen) ? geo.pairGutter : geo.railGutter)
  }
  return out
}

// Window: rows shared across columns; a fuller column reserves the bottom row for a
// "+N more" indicator ONLY while nodes remain below the window, and shows a full `rows`
// real nodes once scrolled to the end — so the final node is always reachable. Geometry
// only; the node arrays are never cut.
// Typed overflow label (T4.1): the hidden rows are a named thing, not anonymous "more".
function _moreNoun(kind, n) {
  if (kind === "plugins")  return n === 1 ? "plugin" : "plugins"
  if (kind === "classes")  return n === 1 ? "capability" : "capabilities"
  if (kind === "rules")    return n === 1 ? "rule" : "rules"
  if (kind === "baseline") return n === 1 ? "Baseline id" : "Baseline ids"
  return "more"
}
function _windowColumns(cols, geoCols, rows, offsets) {
  for (var i = 0; i < 4; i++) {
    var count = cols[i].nodes.length
    var over = count > rows
    var offset = Math.max(0, Math.min(_num(offsets && offsets[i]), over ? count - rows : 0))
    var nodesBelow = over && (offset + rows < count)  // still something past the bottom slot
    var realRows = nodesBelow ? rows - 1 : rows
    var hidden = nodesBelow ? count - (offset + realRows) : 0
    geoCols[i].offset = offset
    geoCols[i].realRows = realRows
    geoCols[i].hidden = hidden
    geoCols[i].moreLabel = hidden > 0 ? "+" + hidden + " " + _moreNoun(cols[i].kind, hidden) : ""
    geoCols[i].count = count
  }
}

// ---- edges (doc 04 §4.1 step 6, §4.2 placeEdge) -------------------------------

function _rowCenter(windowRow, geo) {
  return geo.headerH + windowRow * geo.rowH + geo.rowH / 2
}

// Place one edge as a cubic-Bézier PathSvg string. A node scrolled out below its
// window terminates its edge at the "+N more" row (doc 04 §4.1 step 4).
function _placeEdge(e, index, keyPos, geoCols, geo) {
  var a = keyPos[key(e.from)], b = keyPos[key(e.to)]
  if (!a || !b) return null
  var ga = geoCols[a.col], gb = geoCols[b.col]
  var x1 = ga.x + ga.width, x2 = gb.x, lane = x2 - x1
  var y1 = _rowCenter(_windowRow(a, ga), geo), y2 = _rowCenter(_windowRow(b, gb), geo)
  var c1 = x1 + lane / 3, c2 = x2 - lane / 3
  return {
    a: key(e.from), b: key(e.to),
    d: "M" + _r(x1) + " " + _r(y1) + " C" + _r(c1) + " " + _r(y1) + " " +
       _r(c2) + " " + _r(y2) + " " + _r(x2) + " " + _r(y2) + " ",
    bucket: bucketOf(_num(e.w)), dashed: edgeDashed(e)
  }
}

// window row of a node given its column geometry; hidden-below → the "+N more" row.
function _windowRow(loc, gcol) {
  var rel = loc.row - gcol.offset
  var band = gcol.realRows
  if (rel < 0) return 0
  if (rel >= band) return band            // the "+N more" slot
  return rel
}

function _r(v) { return Math.round(v * 10) / 10 }

// ---- bucketing (doc 04 §4.2 bucket) -------------------------------------------

// hotEdges is a map of edge INDEX → true (not node keys): an edge is hot only when it
// is itself selected, never merely because a neighbour node is highlighted. Passing
// null (build/relayout) buckets everything dim.
function bucket(edges, hotEdges) {
  var p = { dimThinSolid: "", dimThinDashed: "", dimMedSolid: "", dimMedDashed: "",
            dimThickSolid: "", dimThickDashed: "", hotSolid: "", hotDashed: "" }
  for (var i = 0; i < edges.length; i++) {
    var e = edges[i]
    var hot = hotEdges && hotEdges[i]
    var name = hot ? ("hot" + (e.dashed ? "Dashed" : "Solid"))
                   : ("dim" + _cap(e.bucket) + (e.dashed ? "Dashed" : "Solid"))
    p[name] += e.d
  }
  return p
}

// ---- membership / content keys (doc 04 §3.2, §10.1) ---------------------------

function membershipKey(cols, input) {
  var counts = cols.map(function(c) { return c.nodes.length }).join("|")
  var keys = []
  for (var c = 0; c < cols.length; c++)
    for (var i = 0; i < cols[c].nodes.length; i++) keys.push(cols[c].nodes[i].key)
  var scope = input.scope ? (input.scope.kind + (input.scope.id ? ":" + input.scope.id : "")) : "all"
  var filters = input.filters ? (input.filters.backups ? "backups" : "nobackups") : "nobackups"
  return counts + "|" + scope + "|" + filters + "|" + keys.join(",")
}

// Content key tracks everything the delegates and the inspector read, not just the
// count/adornments — so late-arriving catalog copy (rule title/severity, tooltips,
// baseline relation/via pointers, suffixes) forces a node reassignment even when the
// membership is unchanged (doc 04 §10.1). Otherwise the inspector would keep showing
// blank catalog facts until the next membership change.
function contentKey(cols) {
  var parts = []
  for (var c = 0; c < cols.length; c++)
    for (var i = 0; i < cols[c].nodes.length; i++) {
      var n = cols[c].nodes[i]
      parts.push(n.key + ":" + n.count + ":" + (n.bold ? "b" : "") +
        (n.urgent ? "u" : "") + (n.hollow ? "h" : "") + (n.analyzing ? "a" : "") +
        (n.faint ? "f" : "") + (n.glyphKey || "") + ":" + (n.label || "") + ":" +
        (n.tooltip || "") + ":" + (n.title || "") + ":" + (n.severity || "") + ":" +
        (n.suffix || "") + ":" + (n.relation || "") + ":" +
        (_arr(n.viaRules).join(">")) + ":" + (_arr(n.viaClasses).join(">")))
    }
  return parts.join("|")
}

// ---- incidence + class-level baseline hot sets --------------------------------

function incidence(edges) {
  var by = {}
  for (var i = 0; i < edges.length; i++) {
    var e = edges[i]
    if (!by[e.a]) by[e.a] = []
    if (!by[e.b]) by[e.b] = []
    by[e.a].push(i); by[e.b].push(i)
  }
  return by
}

// class → its class-level baseline rows (viaClasses, no edge): brighten with the
// class in the cursor's hot set (doc 04 §2.2, §5).
function classLevelBaseline(cols) {
  var out = {}
  var baseline = cols[3].nodes
  for (var i = 0; i < baseline.length; i++) {
    var b = baseline[i]
    var vc = _arr(b.viaClasses)
    for (var j = 0; j < vc.length; j++) {
      var ck = key(["class", vc[j]])
      if (!out[ck]) out[ck] = []
      out[ck].push(b.key)
    }
  }
  return out
}

// ---- build (doc 04 §4.2) ------------------------------------------------------

function build(input, geo) {
  geo = geo || {}
  var cols = nodeSets(input)
  var edgesIn = _arr(input.edges)

  // barycentre needs neighbour links from the edge list before sorting.
  attachNeighbours(cols, edgesIn)

  // Same-epoch data arrival: the caller (root) signals geo.sameEpoch when the Flow
  // orderEpoch has not changed since the previous layout (doc 04 §4.1 step 3). Then
  // the previous drawn order is retained and genuinely new keys append at the column
  // end — neither key-sort nor barycentre runs. A new epoch (Flow entry / scope
  // reset) re-sorts and re-sweeps.
  var sameEpoch = geo.sameEpoch === true && !!geo.previousKeys
  if (sameEpoch) {
    for (var i = 0; i < 4; i++)
      cols[i].nodes = preserveOrderAndAppend(cols[i].nodes,
        geo.previousKeys[i] || [])
  } else {
    for (var s = 0; s < 4; s++)
      cols[s].nodes = _stableSort(cols[s].nodes, primaryCompareFor(cols[s].kind))
    // middle layers only, left→right then right→left (baseline fixed in map order)
    barycentre(cols, 1, 0); barycentre(cols, 2, 1)
    barycentre(cols, 2, 3); barycentre(cols, 1, 2)
  }

  var maxCount = 0
  for (var m = 0; m < 4; m++) maxCount = Math.max(maxCount, cols[m].nodes.length)
  var rows = Math.min(_num(geo.maxRows) || maxCount, maxCount)
  if (rows < 1) rows = maxCount > 0 ? 1 : 0

  var geoCols = _placeColumns(cols, geo)
  _windowColumns(cols, geoCols, rows, geo.offsets)

  // key → { col, row } for edge placement (row = index in the column node array).
  var keyPos = {}
  for (var c = 0; c < 4; c++)
    for (var r = 0; r < cols[c].nodes.length; r++)
      keyPos[cols[c].nodes[r].key] = { col: c, row: r }

  var edges = []
  for (var e = 0; e < edgesIn.length; e++) {
    var pe = _placeEdge(edgesIn[e], e, keyPos, geoCols, {
      headerH: _num(geo.headerH), rowH: _num(geo.rowH) })
    if (pe) edges.push(pe)
  }

  return {
    membershipKey: membershipKey(cols, input),
    contentKey: contentKey(cols),
    nodes: cols.map(function(c) { return c.nodes }),
    geometry: { headerH: _num(geo.headerH), rowH: _num(geo.rowH), rows: rows, cols: geoCols },
    edges: edges,
    byNode: incidence(edges),
    hotSets: classLevelBaseline(cols),
    keyPos: keyPos,
    paths: bucket(edges, null)
  }
}

// ---- relayout() — geometry + edges + paths only, node order untouched ---------
// Called on every h/l slide, offset move and wheel (doc 04 §4.2 slide/moveWindow):
// recomputes the column geometry, the edge PathSvg strings and the bucket paths from
// the EXISTING node order in `layout`, so TrustFlow.nodes is never reassigned and no
// FlowNode delegate is created or destroyed while navigating.
var _KINDS = ["plugins", "classes", "rules", "baseline"]

function relayout(layout, geo) {
  var cols = []
  for (var i = 0; i < 4; i++) cols.push({ kind: _KINDS[i], nodes: layout.nodes[i] || [] })

  var maxCount = 0
  for (var m = 0; m < 4; m++) maxCount = Math.max(maxCount, cols[m].nodes.length)
  var rows = Math.min(_num(geo.maxRows) || maxCount, maxCount)
  if (rows < 1) rows = maxCount > 0 ? 1 : 0

  var geoCols = _placeColumns(cols, geo)
  _windowColumns(cols, geoCols, rows, geo.offsets)

  var keyPos = {}
  for (var c = 0; c < 4; c++)
    for (var r = 0; r < cols[c].nodes.length; r++)
      keyPos[cols[c].nodes[r].key] = { col: c, row: r }

  var g = { headerH: _num(geo.headerH), rowH: _num(geo.rowH) }
  var edges = []
  var src = _arr(layout.edges)
  for (var e = 0; e < src.length; e++) {
    var oe = src[e]
    var a = keyPos[oe.a], b = keyPos[oe.b]
    if (!a || !b) { edges.push(oe); continue }
    var ga = geoCols[a.col], gb = geoCols[b.col]
    var x1 = ga.x + ga.width, x2 = gb.x, lane = x2 - x1
    var y1 = _rowCenter(_windowRow(a, ga), g), y2 = _rowCenter(_windowRow(b, gb), g)
    var c1 = x1 + lane / 3, c2 = x2 - lane / 3
    edges.push({ a: oe.a, b: oe.b, bucket: oe.bucket, dashed: oe.dashed,
      d: "M" + _r(x1) + " " + _r(y1) + " C" + _r(c1) + " " + _r(y1) + " " +
         _r(c2) + " " + _r(y2) + " " + _r(x2) + " " + _r(y2) + " " })
  }
  return {
    geometry: { headerH: g.headerH, rowH: g.rowH, rows: rows, cols: geoCols },
    edges: edges, byNode: incidence(edges), keyPos: keyPos, paths: bucket(edges, null)
  }
}

// ---- hot() — cursor 1-hop, pin full reach (doc 04 §4.2) -----------------------

function _touches(edge, k) { return edge.a === k || edge.b === k }

// full reach of a pinned node within scope, following incident edges outward.
function reach(layout, startKey) {
  var set = {}
  var stack = [startKey]
  set[startKey] = true
  while (stack.length > 0) {
    var k = stack.pop()
    var inc = layout.byNode[k] || []
    for (var i = 0; i < inc.length; i++) {
      var e = layout.edges[inc[i]]
      var other = e.a === k ? e.b : e.a
      if (!set[other]) { set[other] = true; stack.push(other) }
    }
  }
  return set
}

// Two distinct outputs (doc 04 §5, §6.2):
//   hotEdges — edge INDICES that light up: the cursor's own incident edges (1-hop), and
//              the edges fully inside a pinned node's reach. A neighbour node being
//              bright never drags its unrelated edges hot.
//   hotKeys  — node keys whose `faint` is cleared: the cursor + its 1-hop neighbours +
//              the class-level baseline rows, plus a pinned node's full reach.
function hot(layout, cursorKey, pinnedKey) {
  var hotEdges = {}, hotKeys = {}
  if (cursorKey) {
    hotKeys[cursorKey] = true
    var inc = layout.byNode[cursorKey] || []
    for (var i = 0; i < inc.length; i++) {
      hotEdges[inc[i]] = true                       // the cursor's incident edges only
      var e = layout.edges[inc[i]]
      hotKeys[e.a] = true; hotKeys[e.b] = true       // its 1-hop neighbour nodes brighten
    }
    var cl = (layout.hotSets && layout.hotSets[cursorKey]) || []
    for (var j = 0; j < cl.length; j++) hotKeys[cl[j]] = true   // class-level baseline (no edge)
  }
  if (pinnedKey) {
    var r = reach(layout, pinnedKey)
    for (var k in r) hotKeys[k] = true
    for (var ei = 0; ei < layout.edges.length; ei++) {
      var pe = layout.edges[ei]
      if (r[pe.a] && r[pe.b]) hotEdges[ei] = true    // edges fully within the pinned reach
    }
    var cl2 = (layout.hotSets && layout.hotSets[pinnedKey]) || []
    for (var m = 0; m < cl2.length; m++) hotKeys[cl2[m]] = true
  }
  return { paths: bucket(layout.edges, hotEdges), hotKeys: hotKeys }
}
