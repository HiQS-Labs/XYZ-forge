/*
 * swe-diagram renderer — vanilla xyflow-style system diagram.
 * No dependencies. Reads a diagram spec object and renders:
 *   - layered left→right auto-layout (longest-path ranking)
 *   - draggable HTML nodes with type-colored headers
 *   - SVG bezier edges with arrowheads + optional labels
 *   - pan (drag canvas), zoom (wheel / buttons), fit-to-view
 *   - light/dark via prefers-color-scheme
 *
 * Spec shape (see SKILL.md for the authoring contract):
 * {
 *   title: string,
 *   nodes: [{ id, label, type?, group?, description?, tech? }],
 *   edges: [{ source, target, label?, kind? }],   // kind: "sync"|"async"|"data"
 *   groups?: [{ id, label }]
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

    var pos = layout(spec);
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
      if (n.group) el('div', 'swe-node-group', d).textContent = groupLabels[n.group] || n.group;
      nodeEls[n.id] = d;
      makeDraggable(d, n.id);
    });

    // layout() estimated node heights before the DOM existed; a wrapped label or
    // tech line makes the real node taller. Correct pos[].h from the measured
    // heights and re-stack each column so nodes don't overlap and edge anchors
    // (which use pos.h) land on the true vertical midpoint.
    var byCol = {};
    (spec.nodes || []).forEach(function (n) {
      var p = pos[n.id];
      p.h = nodeEls[n.id].offsetHeight || p.h;
      (byCol[p.x] = byCol[p.x] || []).push(n.id);
    });
    Object.keys(byCol).forEach(function (x) {
      var ids = byCol[x].sort(function (a, b) { return pos[a].y - pos[b].y; });
      var y = 0;
      ids.forEach(function (id) {
        pos[id].y = y;
        nodeEls[id].style.top = y + 'px';
        y += pos[id].h + ROW_GAP;
      });
    });

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

    function drawEdges() {
      edgeEls.forEach(function (ee) {
        var p = edgePath(pos[ee.e.source], pos[ee.e.target]);
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

    var usedTypes = {};
    (spec.nodes || []).forEach(function (n) { usedTypes[n.type || 'default'] = true; });
    var legend = el('div', 'swe-legend', mount);
    Object.keys(usedTypes).sort().forEach(function (t) {
      var item = el('span', 'swe-legend-item', legend);
      var dot = el('span', 'swe-legend-dot', item);
      dot.style.background = TYPE_COLORS[t] || TYPE_COLORS.default;
      item.appendChild(document.createTextNode(t));
    });

    if (spec.title) {
      el('div', 'swe-title', mount).textContent = spec.title;
    }

    drawEdges();
    fitView();
  };
})();
