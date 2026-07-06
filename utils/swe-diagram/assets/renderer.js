/*
 * swe-diagram renderer — vanilla xyflow-style system diagram.
 * No dependencies. Reads a diagram spec object and renders:
 *   - layered left→right auto-layout (longest-path ranking), or an optional
 *     radial hub & ring layout (spec.layout === "hub-ring")
 *   - draggable HTML nodes with type-colored headers
 *   - SVG edges with arrowheads + optional labels
 *   - pan (drag canvas), zoom (wheel / buttons), fit-to-view
 *   - light/dark via prefers-color-scheme
 *
 * Spec shape (see SKILL.md for the authoring contract):
 * {
 *   title: string,
 *   layout?: "layered" | "hub-ring",              // default "layered"
 *   hub?: string,                                  // hub-ring only: node id to center; default = highest-degree node
 *   nodes: [{ id, label, type?, group?, description?, tech? }],
 *   edges: [{ source, target, label?, kind? }],   // kind: "sync"|"async"|"data"
 *   groups?: [{ id, label }]                       // layered layout only — see hubRingLayout note
 * }
 */
(function () {
  'use strict';

  var NODE_W = 200;
  var NODE_MIN_H = 56;
  var COL_GAP = 120;
  var ROW_GAP = 36;

  var TYPE_COLORS = {
    service:  '#4f7cff',
    ui:       '#9a5cff',
    api:      '#00a5a5',
    database: '#e07b00',
    queue:    '#c94f7c',
    external: '#7a8699',
    job:      '#5c9a3d',
    storage:  '#b0892b',
    default:  '#6b7280'
  };

  var EDGE_DASH = { async: '6,5', data: '2,4' };

  function el(tag, cls, parent) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (parent) parent.appendChild(e);
    return e;
  }
  function svgEl(tag, parent) {
    var e = document.createElementNS('http://www.w3.org/2000/svg', tag);
    if (parent) parent.appendChild(e);
    return e;
  }

  // ---- layout: longest-path layering, groups kept adjacent within a column
  function layout(spec) {
    var nodes = spec.nodes || [];
    var edges = (spec.edges || []).filter(function (e) { return e.source !== e.target; });
    var byId = {};
    nodes.forEach(function (n) { byId[n.id] = n; });

    // Rank by longest path, but drop cycle back-edges first so a bidirectional
    // pair (A->B, B->A) stays in adjacent columns instead of drifting apart.
    var adj = {};
    nodes.forEach(function (n) { adj[n.id] = []; });
    edges.forEach(function (e) {
      if (byId[e.source] && byId[e.target]) adj[e.source].push(e.target);
    });
    var state = {}, back = {};   // DFS: flag any edge into a node still on the stack
    function walk(u) {
      state[u] = 1;
      adj[u].forEach(function (v) {
        if (state[v] === 1) (back[u] || (back[u] = {}))[v] = true;
        else if (!state[v]) walk(v);
      });
      state[u] = 2;
    }
    nodes.forEach(function (n) { if (!state[n.id]) walk(n.id); });
    var forward = edges.filter(function (e) {
      return byId[e.source] && byId[e.target] &&
             !(back[e.source] && back[e.source][e.target]);
    });

    var rank = {};
    nodes.forEach(function (n) { rank[n.id] = 0; });
    for (var pass = 0; pass < nodes.length; pass++) {   // DAG: converges in <= |V| passes
      var changed = false;
      forward.forEach(function (e) {
        if (rank[e.target] < rank[e.source] + 1) {
          rank[e.target] = rank[e.source] + 1;
          changed = true;
        }
      });
      if (!changed) break;
    }

    var cols = {};
    nodes.forEach(function (n) {
      (cols[rank[n.id]] = cols[rank[n.id]] || []).push(n);
    });

    var positions = {};
    Object.keys(cols).sort(function (a, b) { return a - b; }).forEach(function (r) {
      var col = cols[r];
      col.sort(function (a, b) {
        var ga = a.group == null ? 1 : 0, gb = b.group == null ? 1 : 0;
        return ga - gb ||
               String(a.group || '').localeCompare(String(b.group || '')) ||
               String(a.label).localeCompare(String(b.label));
      });
      var y = 0;
      col.forEach(function (n) {
        var h = nodeHeight(n);
        positions[n.id] = { x: r * (NODE_W + COL_GAP), y: y, w: NODE_W, h: h };
        y += h + ROW_GAP;
      });
      // center column vertically against tallest column later via fitView
    });
    return positions;
  }

  function nodeHeight(n) {
    var h = NODE_MIN_H;
    if (n.tech) h += 18;
    return h;
  }

  // ---- search + type filter predicate: dims (never hides/re-layouts) a node
  // that doesn't match the current text query or whose type has been toggled
  // off in the legend. Pure so it's independently testable; renderDiagram's
  // nodeMatches() below just supplies the closure's live query/excludedTypes.
  function matchesQuery(n, query, excludedTypes) {
    if (excludedTypes[n.type || 'default']) return false;
    if (!query) return true;
    var haystack = [n.label, n.id, n.type, n.tech, n.description]
      .filter(Boolean).join(' ').toLowerCase();
    return haystack.indexOf(query) !== -1;
  }

  // ---- hub & ring: a radial layout for event-driven architectures (a central
  // broker/gateway talking to independent services) where the layered
  // left→right pipeline reading doesn't fit. Every non-hub node sits on a
  // ring around the hub; overflow beyond MAX_PER_RING spills to a wider
  // concentric ring instead of crowding one circle. Coordinates below are
  // ring-center-relative (0,0 = the hub's center) and converted to the usual
  // top-left x/y before returning, so callers never see the difference.
  // Note: group swimlanes are a layered-layout-only feature (its boxes are
  // computed from column position) and are skipped entirely for hub-ring.
  function hubRingLayout(spec) {
    var nodes = spec.nodes || [];
    var positions = {};
    if (!nodes.length) return positions;

    var degree = {};
    nodes.forEach(function (n) { degree[n.id] = 0; });
    (spec.edges || []).forEach(function (e) {
      if (degree[e.source] != null) degree[e.source]++;
      if (degree[e.target] != null) degree[e.target]++;
    });

    var hubId = spec.hub;
    if (hubId == null || degree[hubId] == null) {
      hubId = nodes.reduce(function (best, n) {
        return degree[n.id] > degree[best.id] ? n : best;
      }, nodes[0]).id;
    }
    var hubNode = nodes.filter(function (n) { return n.id === hubId; })[0];
    var hubH = nodeHeight(hubNode);
    positions[hubId] = { x: -NODE_W / 2, y: -hubH / 2, w: NODE_W, h: hubH };

    var ring = nodes.filter(function (n) { return n.id !== hubId; });
    if (!ring.length) return positions;
    ring.sort(function (a, b) {
      return String(a.group || '').localeCompare(String(b.group || '')) ||
             String(a.label || a.id).localeCompare(String(b.label || b.id));
    });

    // Split into `numRings` EVENLY sized chunks rather than greedily filling
    // ring 0 to MAX_PER_RING before spilling over — a small remainder (e.g.
    // 2 of 10 nodes) would land at just two opposite angles in ring 1 and
    // read as stray spokes rather than a second ring.
    var MAX_PER_RING = 8;
    var numRings = Math.max(1, Math.ceil(ring.length / MAX_PER_RING));
    var chunkSize = Math.ceil(ring.length / numRings);
    var ringIndex = ring.map(function (n, i) { return Math.floor(i / chunkSize); });
    var ringCounts = {};
    ringIndex.forEach(function (r) { ringCounts[r] = (ringCounts[r] || 0) + 1; });

    // Radius that keeps adjacent ring nodes from overlapping: enough
    // circumference for NODE_W-wide nodes plus a gap, scaled to node count.
    var innerRadius = Math.max(280, (NODE_W + 60) * (ringCounts[0] || 1) / (2 * Math.PI));
    var ringGap = NODE_W + 140;

    var placed = {};
    ring.forEach(function (n, i) {
      var r = ringIndex[i];
      placed[r] = placed[r] || 0;
      var angle = (2 * Math.PI * placed[r] / ringCounts[r]) - Math.PI / 2; // start at 12 o'clock
      placed[r]++;
      var radius = innerRadius + r * ringGap;
      var h = nodeHeight(n);
      positions[n.id] = {
        x: radius * Math.cos(angle) - NODE_W / 2,
        y: radius * Math.sin(angle) - h / 2,
        w: NODE_W, h: h
      };
    });
    return positions;
  }

  // ---- main
  window.renderDiagram = function (spec, mount) {
    mount = mount || document.getElementById('diagram');
    mount.innerHTML = '';
    mount.classList.add('swe-canvas');

    var viewport = el('div', 'swe-viewport', mount);
    var svg = svgEl('svg', viewport);
    svg.setAttribute('class', 'swe-edges');
    var defs = svgEl('defs', svg);
    ['sync', 'async', 'data'].forEach(function (kind) {
      var m = svgEl('marker', defs);
      m.setAttribute('id', 'arrow-' + kind);
      m.setAttribute('viewBox', '0 0 10 10');
      m.setAttribute('refX', '9'); m.setAttribute('refY', '5');
      m.setAttribute('markerWidth', '7'); m.setAttribute('markerHeight', '7');
      m.setAttribute('orient', 'auto-start-reverse');
      var p = svgEl('path', m);
      p.setAttribute('d', 'M 0 0 L 10 5 L 0 10 z');
      p.setAttribute('class', 'swe-arrow');
    });
    var edgeLayer = svgEl('g', svg);
    var nodeLayer = el('div', 'swe-nodes', viewport);
    var groupLayer = el('div', 'swe-groups', viewport);
    viewport.insertBefore(groupLayer, viewport.firstChild); // paint behind edges + nodes

    var isHubRing = spec.layout === 'hub-ring';
    var pos = isHubRing ? hubRingLayout(spec) : layout(spec);
    var nodeEls = {};

    var groupLabels = {};   // honor spec.groups: render the human label, not the raw id
    (spec.groups || []).forEach(function (g) {
      if (g && g.id != null) groupLabels[g.id] = g.label || g.id;
    });

    (spec.nodes || []).forEach(function (n) {
      var p = pos[n.id];
      var d = el('div', 'swe-node', nodeLayer);
      d.style.left = p.x + 'px';
      d.style.top = p.y + 'px';
      d.style.width = p.w + 'px';
      var color = TYPE_COLORS[n.type] || TYPE_COLORS.default;
      d.style.setProperty('--node-color', color);
      var head = el('div', 'swe-node-head', d);
      head.textContent = n.type ? n.type.toUpperCase() : 'COMPONENT';
      var body = el('div', 'swe-node-body', d);
      el('div', 'swe-node-label', body).textContent = n.label || n.id;
      if (n.tech) el('div', 'swe-node-tech', body).textContent = n.tech;
      if (n.description) d.title = n.description;
      nodeEls[n.id] = d;
      makeDraggable(d, n.id);
    });

    // layout() estimated node heights before the DOM existed; a wrapped label or
    // tech line makes the real node taller. Correct pos[].h from the measured
    // height everywhere (edge anchors use it), then — layered layout only —
    // re-stack each column so nodes don't overlap. Hub-ring positions are
    // already final radial coordinates; nothing depends on column stacking.
    var byCol = {};
    (spec.nodes || []).forEach(function (n) {
      var p = pos[n.id];
      p.h = nodeEls[n.id].offsetHeight || p.h;
      if (!isHubRing) (byCol[p.x] = byCol[p.x] || []).push(n.id);
    });
    if (!isHubRing) {
      Object.keys(byCol).forEach(function (x) {
        var ids = byCol[x].sort(function (a, b) { return pos[a].y - pos[b].y; });
        var y = 0;
        ids.forEach(function (id) {
          pos[id].y = y;
          nodeEls[id].style.top = y + 'px';
          y += pos[id].h + ROW_GAP;
        });
      });
    }

    // ---- group bounding boxes (swimlanes): layered layout only — its boxes
    // are computed from column position, which hub-ring's radial coordinates
    // don't have. Drawn once per-node heights are final (after the byCol
    // re-stack correction above). A group's members are not guaranteed to
    // land in adjacent layout columns (e.g. an async worker two ranks
    // downstream of its sibling) — a single box spanning the group's full
    // min/max would then swallow unrelated nodes sitting between the runs,
    // so draw one box per contiguous run of columns instead.
    if (!isHubRing) {
      var colStride = NODE_W + COL_GAP;
      (spec.groups || []).forEach(function (g) {
        if (!g || g.id == null) return;
        var colsOfGroup = {};
        (spec.nodes || []).forEach(function (n) {
          if (n.group !== g.id || !pos[n.id]) return;
          var col = Math.round(pos[n.id].x / colStride);
          (colsOfGroup[col] = colsOfGroup[col] || []).push(n.id);
        });
        var cols = Object.keys(colsOfGroup).map(Number).sort(function (a, b) { return a - b; });
        if (!cols.length) return; // empty group
        var runs = [[cols[0]]];
        for (var i = 1; i < cols.length; i++) {
          if (cols[i] === cols[i - 1] + 1) runs[runs.length - 1].push(cols[i]);
          else runs.push([cols[i]]);
        }
        runs.forEach(function (run) {
          var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
          run.forEach(function (col) {
            colsOfGroup[col].forEach(function (id) {
              var p = pos[id];
              minX = Math.min(minX, p.x); minY = Math.min(minY, p.y);
              maxX = Math.max(maxX, p.x + p.w); maxY = Math.max(maxY, p.y + p.h);
            });
          });
          var pad = 22;
          var box = el('div', 'swe-group-box', groupLayer);
          box.style.left = (minX - pad) + 'px';
          box.style.top = (minY - pad) + 'px';
          box.style.width = (maxX - minX + pad * 2) + 'px';
          box.style.height = (maxY - minY + pad * 2) + 'px';
          el('div', 'swe-group-label', box).textContent = groupLabels[g.id] || g.id;
        });
      });
    }

    var edgeEls = [];
    (spec.edges || []).forEach(function (e) {
      if (!pos[e.source] || !pos[e.target]) return;
      var kind = EDGE_DASH[e.kind] ? e.kind : 'sync';
      var path = svgEl('path', edgeLayer);
      path.setAttribute('class', 'swe-edge swe-edge-' + kind);
      if (EDGE_DASH[kind]) path.setAttribute('stroke-dasharray', EDGE_DASH[kind]);
      path.setAttribute('marker-end', 'url(#arrow-' + kind + ')');
      var label = null;
      if (e.label) {
        label = svgEl('text', edgeLayer);
        label.setAttribute('class', 'swe-edge-label');
        label.textContent = e.label;
      }
      edgeEls.push({ e: e, path: path, label: label });
    });

    function edgePath(a, b) {
      var x1 = a.x + a.w, y1 = a.y + a.h / 2;
      var x2 = b.x, y2 = b.y + b.h / 2;
      if (b.x < a.x + a.w) { // backward edge: route from left side
        x1 = a.x; x2 = b.x + b.w;
      }
      var dx = Math.max(40, Math.abs(x2 - x1) / 2);
      var c1 = x1 < x2 ? x1 + dx : x1 - dx;
      var c2 = x1 < x2 ? x2 - dx : x2 + dx;
      return { d: 'M' + x1 + ',' + y1 + ' C' + c1 + ',' + y1 + ' ' + c2 + ',' + y2 + ' ' + x2 + ',' + y2,
               mx: (x1 + x2) / 2, my: (y1 + y2) / 2 - 6 };
    }

    // hub-ring has no consistent left→right flow direction to route "around"
    // (edges fan out from the center in every direction), so it uses a
    // straight line clipped to each node's rectangle boundary instead of
    // edgePath()'s flow-direction-aware bezier.
    function rectCenter(p) { return { x: p.x + p.w / 2, y: p.y + p.h / 2 }; }
    function clipToRectBoundary(fromX, fromY, rect) {
      var cx = rect.x + rect.w / 2, cy = rect.y + rect.h / 2;
      var dx = fromX - cx, dy = fromY - cy;
      if (dx === 0 && dy === 0) return { x: cx, y: cy };
      var scale = Math.min(
        dx !== 0 ? (rect.w / 2) / Math.abs(dx) : Infinity,
        dy !== 0 ? (rect.h / 2) / Math.abs(dy) : Infinity
      );
      return { x: cx + dx * scale, y: cy + dy * scale };
    }
    function radialEdgePath(a, b) {
      var ca = rectCenter(a), cb = rectCenter(b);
      var p1 = clipToRectBoundary(cb.x, cb.y, a);
      var p2 = clipToRectBoundary(ca.x, ca.y, b);
      return { d: 'M' + p1.x + ',' + p1.y + ' L' + p2.x + ',' + p2.y,
               mx: (p1.x + p2.x) / 2, my: (p1.y + p2.y) / 2 - 6 };
    }

    function drawEdges() {
      edgeEls.forEach(function (ee) {
        var p = (isHubRing ? radialEdgePath : edgePath)(pos[ee.e.source], pos[ee.e.target]);
        ee.path.setAttribute('d', p.d);
        if (ee.label) { ee.label.setAttribute('x', p.mx); ee.label.setAttribute('y', p.my); }
      });
    }

    // ---- pan & zoom
    var view = { x: 40, y: 40, k: 1 };
    function applyView() {
      viewport.style.transform =
        'translate(' + view.x + 'px,' + view.y + 'px) scale(' + view.k + ')';
    }
    mount.addEventListener('wheel', function (ev) {
      ev.preventDefault();
      var k = Math.min(2.5, Math.max(0.2, view.k * (ev.deltaY < 0 ? 1.1 : 0.9)));
      var r = mount.getBoundingClientRect();
      var mx = ev.clientX - r.left, my = ev.clientY - r.top;
      view.x = mx - (mx - view.x) * (k / view.k);
      view.y = my - (my - view.y) * (k / view.k);
      view.k = k;
      applyView();
    }, { passive: false });

    var panning = null;
    mount.addEventListener('mousedown', function (ev) {
      if (ev.target.closest('.swe-node')) return;
      panning = { x: ev.clientX - view.x, y: ev.clientY - view.y };
      mount.classList.add('swe-grabbing');
    });
    window.addEventListener('mousemove', function (ev) {
      if (!panning) return;
      view.x = ev.clientX - panning.x;
      view.y = ev.clientY - panning.y;
      applyView();
    });
    window.addEventListener('mouseup', function () {
      panning = null;
      mount.classList.remove('swe-grabbing');
    });

    function makeDraggable(d, id) {
      d.addEventListener('mousedown', function (ev) {
        ev.stopPropagation();
        var start = { mx: ev.clientX, my: ev.clientY, x: pos[id].x, y: pos[id].y };
        function move(mv) {
          pos[id].x = start.x + (mv.clientX - start.mx) / view.k;
          pos[id].y = start.y + (mv.clientY - start.my) / view.k;
          d.style.left = pos[id].x + 'px';
          d.style.top = pos[id].y + 'px';
          drawEdges();
        }
        function up() {
          window.removeEventListener('mousemove', move);
          window.removeEventListener('mouseup', up);
        }
        window.addEventListener('mousemove', move);
        window.addEventListener('mouseup', up);
      });
    }

    function fitView() {
      var ids = Object.keys(pos);
      if (!ids.length) return;
      var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
      ids.forEach(function (id) {
        var p = pos[id];
        minX = Math.min(minX, p.x); minY = Math.min(minY, p.y);
        maxX = Math.max(maxX, p.x + p.w); maxY = Math.max(maxY, p.y + p.h);
      });
      var r = mount.getBoundingClientRect();
      var k = Math.min(1.5, Math.max(0.2,
        Math.min((r.width - 80) / (maxX - minX), (r.height - 80) / (maxY - minY))));
      view.k = k;
      view.x = (r.width - (maxX - minX) * k) / 2 - minX * k;
      view.y = (r.height - (maxY - minY) * k) / 2 - minY * k;
      applyView();
    }

    // ---- controls + legend
    var controls = el('div', 'swe-controls', mount);
    [['+', function () { view.k = Math.min(2.5, view.k * 1.2); applyView(); }],
     ['−', function () { view.k = Math.max(0.2, view.k / 1.2); applyView(); }],
     ['▣', fitView]].forEach(function (c) {
      var b = el('button', 'swe-btn', controls);
      b.textContent = c[0];
      b.addEventListener('click', c[1]);
    });

    // ---- search + type filter: dims (never hides/re-layouts) nodes and
    // edges that don't match the current text query or whose type has been
    // toggled off in the legend. An edge is dimmed if either endpoint is
    // dimmed. Matching itself is matchesQuery() above (pure, testable); this
    // just binds it to the live closure state.
    var excludedTypes = {};
    var query = '';
    function nodeMatches(n) {
      return matchesQuery(n, query, excludedTypes);
    }
    function applyFilter() {
      var matched = {};
      (spec.nodes || []).forEach(function (n) {
        var m = nodeMatches(n);
        matched[n.id] = m;
        nodeEls[n.id].classList.toggle('swe-dimmed', !m);
      });
      edgeEls.forEach(function (ee) {
        var dim = !matched[ee.e.source] || !matched[ee.e.target];
        ee.path.classList.toggle('swe-dimmed', dim);
        if (ee.label) ee.label.classList.toggle('swe-dimmed', dim);
      });
    }

    var usedTypes = {};
    (spec.nodes || []).forEach(function (n) { usedTypes[n.type || 'default'] = true; });
    var legend = el('div', 'swe-legend', mount);
    var legendItems = {};
    Object.keys(usedTypes).sort().forEach(function (t) {
      var item = el('span', 'swe-legend-item', legend);
      var dot = el('span', 'swe-legend-dot', item);
      dot.style.background = TYPE_COLORS[t] || TYPE_COLORS.default;
      item.appendChild(document.createTextNode(t));
      item.title = 'Click to toggle ' + t + ' nodes';
      item.addEventListener('click', function () {
        excludedTypes[t] = !excludedTypes[t];
        item.classList.toggle('swe-dimmed', !!excludedTypes[t]);
        applyFilter();
      });
      legendItems[t] = item;
    });

    var search = el('div', 'swe-search', mount);
    var searchInput = el('input', 'swe-search-input', search);
    searchInput.type = 'search';
    searchInput.placeholder = 'Filter nodes…';
    var searchClear = el('button', 'swe-search-clear', search);
    searchClear.type = 'button';
    searchClear.textContent = '×';
    searchInput.addEventListener('input', function () {
      query = searchInput.value.trim().toLowerCase();
      search.classList.toggle('swe-search-active', query.length > 0);
      applyFilter();
    });
    searchClear.addEventListener('click', function () {
      searchInput.value = '';
      query = '';
      search.classList.remove('swe-search-active');
      applyFilter();
      searchInput.focus();
    });

    if (spec.title) {
      el('div', 'swe-title', mount).textContent = spec.title;
    }

    drawEdges();
    fitView();
  };

  // Node-only export for test/swe-diagram.sh (pure-logic fixtures, no
  // browser). `module` is undefined when this file is inlined into a
  // <script> tag, so this is a no-op there — zero behavior change shipped.
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { hubRingLayout: hubRingLayout, matchesQuery: matchesQuery, layout: layout };
  }
})();
