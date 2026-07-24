/*
 * swe-diagram renderer — vanilla xyflow-style system diagram.
 * No dependencies. Reads a diagram spec object and renders:
 *   - layered left→right or top→bottom auto-layout (longest-path ranking),
 *     radial hub & ring, or fixed-row Git history lanes
 *   - draggable HTML nodes with type-colored headers
 *   - SVG edges with arrowheads + optional labels
 *   - pan (drag canvas), zoom (wheel / buttons), fit-to-view
 *   - light/dark via prefers-color-scheme
 *
 * Spec shape (see SKILL.md for the authoring contract):
 * {
 *   title: string,
 *   layout?: "layered" | "top-down" | "hub-ring" | "trust-clustered" | "git-lanes", // default "layered"
 *   hub?: string,                                  // hub-ring only: node id to center; default = highest-degree node
 *   nodes: [{ id, label, type?, group?, trust?, lane?, order?, description?, tech? }],
 *   edges: [{ source, target, label?, kind? }],   // kind: "sync"|"async"|"data"|"branch"|"merge"
 *   groups?: [{ id, label }],
 *   lanes?: [{ id, label, order?, current? }]      // git-lanes only
 * }
 */
(function () {
  'use strict';

  var NODE_W = 200;
  var NODE_MIN_H = 56;
  var COL_GAP = 120;
  var ROW_GAP = 36;
  var GIT_NODE_W = 168;
  var GIT_COL_GAP = 52;
  var GIT_LANE_GAP = 112;
  var GIT_LANE_LABEL_W = 180;

  var TYPE_COLORS = {
    service:  '#4f7cff',
    ui:       '#9a5cff',
    api:      '#00a5a5',
    database: '#e07b00',
    queue:    '#c94f7c',
    external: '#7a8699',
    job:      '#5c9a3d',
    storage:  '#b0892b',
    commit:   '#4f7cff',
    merge:    '#9a5cff',
    default:  '#6b7280'
  };

  var EDGE_DASH = { async: '6,5', data: '2,4', branch: '4,4', merge: '8,5' };

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

  // Reuse layered's cycle handling, longest-path ranks, group adjacency, and
  // deterministic ordering, then rotate the rank axis. Recomputing row gaps
  // (rather than naively swapping x/y) matters because node width is fixed
  // while node height varies when `tech` is present.
  function topDownLayout(spec) {
    var horizontal = layout(spec);
    var rows = {};
    (spec.nodes || []).forEach(function (n) {
      var p = horizontal[n.id];
      (rows[p.x] = rows[p.x] || []).push(n.id);
    });

    var positions = {};
    var y = 0;
    Object.keys(rows).map(Number).sort(function (a, b) { return a - b; }).forEach(function (rankX) {
      var ids = rows[rankX].sort(function (a, b) { return horizontal[a].y - horizontal[b].y; });
      var rowH = 0;
      ids.forEach(function (id, i) {
        var p = horizontal[id];
        positions[id] = { x: i * (NODE_W + ROW_GAP), y: y, w: p.w, h: p.h };
        rowH = Math.max(rowH, p.h);
      });
      y += rowH + COL_GAP;
    });
    return positions;
  }

  // Fixed-row Git graph: branch lanes are stacked vertically while a global
  // chronological order advances left-to-right. The generator supplies
  // `lane` and `order`; the renderer stays deterministic and does not try to
  // reconstruct branch provenance from ancestry alone.
  function gitLaneLayout(spec) {
    var lanes = (spec.lanes || []).slice().sort(function (a, b) {
      return (a.order == null ? Infinity : a.order) - (b.order == null ? Infinity : b.order) ||
             String(a.label || a.id).localeCompare(String(b.label || b.id));
    });
    var laneOrder = {};
    lanes.forEach(function (lane, i) { laneOrder[lane.id] = i; });

    var nextLane = lanes.length;
    var positions = {};
    (spec.nodes || []).forEach(function (n, i) {
      if (laneOrder[n.lane] == null) laneOrder[n.lane] = nextLane++;
      var order = Number.isFinite(Number(n.order)) ? Number(n.order) : i;
      positions[n.id] = {
        x: order * (GIT_NODE_W + GIT_COL_GAP),
        y: laneOrder[n.lane] * GIT_LANE_GAP,
        w: GIT_NODE_W,
        h: nodeHeight(n)
      };
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
    var haystack = [n.label, n.id, n.type, n.tech, n.description, n.lane, n.author]
      .concat(n.refs || [])
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

  // ---- trust-clustered: bands nodes into fixed trust tiers derived from
  // each node's own `trust` field (already authored for the doc's
  // legend_note — see system-diagram.json) instead of a computed graph rank
  // or an author-chosen `group`. This makes the trust/control-plane
  // structure the layout's primary axis: the containment core reads as a
  // central spine (never a leaf, per the acceptance criteria this mode was
  // built for) with the dispatch shims, untrusted executors, shared state,
  // and off-live-path governance/audit surface as their own bands, each
  // still using the standard layered left->right bezier (edgePath) so
  // backward edges (e.g. a shim's "containment" edge back into the spine
  // column) route the same way `layout()` already handles them.
  var TRUST_TIERS = [
    { id: 'spine', label: 'Orchestration Spine',
      prefixes: ['trusted-primitive', 'trusted-orchestrator', 'trusted-containment-core', 'trusted-supervisor'] },
    { id: 'shim', label: 'Turn-Shim Cluster', prefixes: ['trusted-dispatch'] },
    { id: 'periphery', label: 'Untrusted Periphery',
      prefixes: ['untrusted-executor', 'external-credentialed', 'sandboxed-worker'] },
    { id: 'state', label: 'Shared State', prefixes: ['shared-state'] },
    { id: 'governance', label: 'Off-Live-Path Governance & Audit',
      prefixes: ['governance-gate', 'runtime-audit'] }
  ];
  var TRUST_TIER_MAX_ROWS = 6; // wrap a tall tier into side-by-side sub-columns past this

  function trustTierOf(n) {
    var t = String(n.trust || '');
    for (var i = 0; i < TRUST_TIERS.length; i++) {
      var prefixes = TRUST_TIERS[i].prefixes;
      for (var j = 0; j < prefixes.length; j++) {
        if (t.indexOf(prefixes[j]) === 0) return i;
      }
    }
    return TRUST_TIERS.length - 1; // untagged nodes land in the last band rather than vanishing
  }

  function trustClusteredLayout(spec) {
    var nodes = spec.nodes || [];
    var positions = {};
    if (!nodes.length) return positions;

    var byTier = TRUST_TIERS.map(function () { return []; });
    nodes.forEach(function (n) { byTier[trustTierOf(n)].push(n); });

    // Spine tier only: float the containment core, then its dispatching
    // orchestrator, to the front so the traced path (dispatcher -> shim ->
    // ... -> containment core) anchors at the top of the column instead of
    // landing wherever alphabetical order happens to put it.
    byTier[0].sort(function (a, b) {
      function rank(n) {
        var t = String(n.trust || '');
        if (t.indexOf('trusted-containment-core') === 0) return 0;
        if (t.indexOf('trusted-orchestrator') === 0) return 1;
        return 2;
      }
      return rank(a) - rank(b) || String(a.label || a.id).localeCompare(String(b.label || b.id));
    });
    for (var i = 1; i < byTier.length; i++) {
      byTier[i].sort(function (a, b) { return String(a.label || a.id).localeCompare(String(b.label || b.id)); });
    }

    var x = 0;
    byTier.forEach(function (tierNodes) {
      if (!tierNodes.length) return;
      var subCols = Math.max(1, Math.ceil(tierNodes.length / TRUST_TIER_MAX_ROWS));
      var perCol = Math.ceil(tierNodes.length / subCols);
      for (var c = 0; c < subCols; c++) {
        var colNodes = tierNodes.slice(c * perCol, (c + 1) * perCol);
        var y = 0;
        var colX = x;
        colNodes.forEach(function (n) {
          var h = nodeHeight(n);
          positions[n.id] = { x: colX, y: y, w: NODE_W, h: h };
          y += h + ROW_GAP;
        });
        x += NODE_W + (c < subCols - 1 ? ROW_GAP * 2 : COL_GAP);
      }
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
    ['sync', 'async', 'data', 'branch', 'merge'].forEach(function (kind) {
      var m = svgEl('marker', defs);
      m.setAttribute('id', 'arrow-' + kind);
      m.setAttribute('viewBox', '0 0 10 10');
      m.setAttribute('refX', '9'); m.setAttribute('refY', '5');
      m.setAttribute('markerWidth', '7'); m.setAttribute('markerHeight', '7');
      m.setAttribute('orient', 'auto-start-reverse');
      var p = svgEl('path', m);
      p.setAttribute('d', 'M 0 0 L 10 5 L 0 10 z');
      p.setAttribute('class', 'swe-arrow swe-arrow-' + kind);
    });
    var edgeLayer = svgEl('g', svg);
    var nodeLayer = el('div', 'swe-nodes', viewport);
    var groupLayer = el('div', 'swe-groups', viewport);
    viewport.insertBefore(groupLayer, viewport.firstChild); // paint behind edges + nodes

    var isHubRing = spec.layout === 'hub-ring';
    var isTopDown = spec.layout === 'top-down';
    var isGitLanes = spec.layout === 'git-lanes';
    var isTrustClustered = spec.layout === 'trust-clustered';
    var pos = isHubRing ? hubRingLayout(spec) :
              (isTopDown ? topDownLayout(spec) :
              (isGitLanes ? gitLaneLayout(spec) :
              (isTrustClustered ? trustClusteredLayout(spec) : layout(spec))));
    var nodeEls = {};
    var gitLaneBounds = null;

    // trust-clustered ignores spec.groups (author-chosen subsystem groups)
    // and instead groups by the derived trust tier, so the drawn boxes match
    // the axis this layout mode exists to make dominant.
    var groupDefs = isTrustClustered ? TRUST_TIERS : (spec.groups || []);
    function nodeGroupId(n) { return isTrustClustered ? TRUST_TIERS[trustTierOf(n)].id : n.group; }

    var groupLabels = {};   // render the human label, not the raw id
    groupDefs.forEach(function (g) {
      if (g && g.id != null) groupLabels[g.id] = g.label || g.id;
    });

    (spec.nodes || []).forEach(function (n) {
      var p = pos[n.id];
      var d = el('div', 'swe-node', nodeLayer);
      if (isGitLanes) d.classList.add('swe-node-commit');
      if (isTrustClustered && String(n.trust || '').indexOf('trusted-containment-core') === 0) {
        d.classList.add('swe-node-hub');
      }
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
    // height everywhere (edge anchors use it), then re-stack each layered
    // rank so nodes don't overlap. Hub-ring positions are already final
    // radial coordinates; nothing depends on rank stacking.
    var byRank = {};
    (spec.nodes || []).forEach(function (n) {
      var p = pos[n.id];
      p.h = nodeEls[n.id].offsetHeight || p.h;
      if (!isHubRing && !isGitLanes) {
        var rankCoord = isTopDown ? p.y : p.x;
        (byRank[rankCoord] = byRank[rankCoord] || []).push(n.id);
      }
    });
    if (!isHubRing && !isGitLanes) {
      if (isTopDown) {
        var rowY = 0;
        Object.keys(byRank).map(Number).sort(function (a, b) { return a - b; }).forEach(function (oldY) {
          var rowH = 0;
          byRank[oldY].forEach(function (id) {
            pos[id].y = rowY;
            nodeEls[id].style.top = rowY + 'px';
            rowH = Math.max(rowH, pos[id].h);
          });
          rowY += rowH + COL_GAP;
        });
      } else {
        Object.keys(byRank).forEach(function (x) {
          var ids = byRank[x].sort(function (a, b) { return pos[a].y - pos[b].y; });
          var y = 0;
          ids.forEach(function (id) {
            pos[id].y = y;
            nodeEls[id].style.top = y + 'px';
            y += pos[id].h + ROW_GAP;
          });
        });
      }
    }

    // ---- group bounding boxes (swimlanes): hierarchical layouts only — the
    // boxes follow rank columns or rows, which hub-ring's radial coordinates
    // don't have. Drawn once per-node heights are final (after rank restacking
    // above). A group's members are not guaranteed to land in adjacent ranks
    // (e.g. an async worker two ranks
    // downstream of its sibling) — a single box spanning the group's full
    // min/max would then swallow unrelated nodes sitting between the runs,
    // so draw one box per contiguous rank run instead.
    if (!isHubRing && !isGitLanes) {
      var rankAxis = isTopDown ? 'y' : 'x';
      var rankCoords = [];
      (spec.nodes || []).forEach(function (n) {
        var coord = pos[n.id] && pos[n.id][rankAxis];
        if (coord != null && rankCoords.indexOf(coord) === -1) rankCoords.push(coord);
      });
      rankCoords.sort(function (a, b) { return a - b; });
      groupDefs.forEach(function (g) {
        if (!g || g.id == null) return;
        var colsOfGroup = {};
        (spec.nodes || []).forEach(function (n) {
          if (nodeGroupId(n) !== g.id || !pos[n.id]) return;
          var col = rankCoords.indexOf(pos[n.id][rankAxis]);
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

    // Git lanes use full-width horizontal bands rather than component-group
    // boxes. Keep stable long-lived lanes visible even when the selected
    // commit window contains no node on one of them (for example development).
    if (isGitLanes) {
      var gitLanes = (spec.lanes || []).slice().sort(function (a, b) {
        return (a.order == null ? Infinity : a.order) - (b.order == null ? Infinity : b.order) ||
               String(a.label || a.id).localeCompare(String(b.label || b.id));
      });
      var gitMaxX = 0;
      Object.keys(pos).forEach(function (id) { gitMaxX = Math.max(gitMaxX, pos[id].x + pos[id].w); });
      gitLanes.forEach(function (lane, laneIndex) {
        var band = el('div', 'swe-lane-box' + (lane.current ? ' swe-lane-current' : ''), groupLayer);
        band.style.left = (-GIT_LANE_LABEL_W) + 'px';
        band.style.top = (laneIndex * GIT_LANE_GAP - 16) + 'px';
        band.style.width = (gitMaxX + GIT_LANE_LABEL_W + 24) + 'px';
        band.style.height = '88px';
        var laneLabel = el('div', 'swe-lane-label', band);
        laneLabel.textContent = (lane.current ? '● ' : '') + (lane.label || lane.id);
      });
      gitLaneBounds = {
        minX: -GIT_LANE_LABEL_W,
        minY: -16,
        maxX: gitMaxX + 24,
        maxY: Math.max(72, gitLanes.length * GIT_LANE_GAP - 24)
      };
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

    function verticalEdgePath(a, b) {
      var x1 = a.x + a.w / 2, y1 = a.y + a.h;
      var x2 = b.x + b.w / 2, y2 = b.y;
      if (b.y < a.y + a.h) { // backward edge: route from top side
        y1 = a.y; y2 = b.y + b.h;
      }
      var dy = Math.max(40, Math.abs(y2 - y1) / 2);
      var c1 = y1 < y2 ? y1 + dy : y1 - dy;
      var c2 = y1 < y2 ? y2 - dy : y2 + dy;
      return { d: 'M' + x1 + ',' + y1 + ' C' + x1 + ',' + c1 + ' ' + x2 + ',' + c2 + ' ' + x2 + ',' + y2,
               mx: (x1 + x2) / 2 + 6, my: (y1 + y2) / 2 };
    }

    function gitEdgePath(a, b) {
      var x1 = a.x + a.w, y1 = a.y + a.h / 2;
      var x2 = b.x, y2 = b.y + b.h / 2;
      var mid = (x1 + x2) / 2;
      return {
        d: 'M' + x1 + ',' + y1 + ' C' + mid + ',' + y1 + ' ' + mid + ',' + y2 + ' ' + x2 + ',' + y2,
        mx: mid,
        my: (y1 + y2) / 2 - 6
      };
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

    // ---- label placement: nudge an edge label vertically off any node
    // border or already-placed label it would otherwise sit on top of.
    // Width is a rough glyph-count estimate (no canvas measurement — this
    // must stay synchronous and dependency-free), which is deliberately
    // generous so a false "overlap" (nudge when none existed) is preferred
    // over a missed one. Runs for every layout, not just trust-clustered:
    // dense fan-in/fan-out reads badly regardless of which mode placed the
    // nodes.
    var LABEL_H = 15;
    function estimateLabelWidth(text) { return 6 * String(text || '').length + 8; }
    function rectsOverlap(a, b) {
      return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
    }
    function placeLabelRect(mx, my, text, obstacles) {
      var w = estimateLabelWidth(text);
      var rect = { x: mx - w / 2, y: my - LABEL_H + 3, w: w, h: LABEL_H };
      var step = LABEL_H + 3, tries = 0;
      while (tries < 14 && obstacles.some(function (o) { return rectsOverlap(rect, o); })) {
        tries++;
        var offset = Math.ceil(tries / 2) * step * (tries % 2 ? 1 : -1);
        rect.y = my - LABEL_H + 3 + offset;
      }
      return rect;
    }

    function drawEdges() {
      var labelObstacles = Object.keys(pos).map(function (id) {
        var p = pos[id];
        return { x: p.x, y: p.y, w: p.w, h: p.h };
      });
      edgeEls.forEach(function (ee) {
        var pathFn = isHubRing ? radialEdgePath :
                     (isTopDown ? verticalEdgePath : (isGitLanes ? gitEdgePath : edgePath));
        var p = pathFn(pos[ee.e.source], pos[ee.e.target]);
        ee.path.setAttribute('d', p.d);
        if (ee.label) {
          var rect = placeLabelRect(p.mx, p.my, ee.e.label, labelObstacles);
          var labelY = rect.y + LABEL_H - 3;
          ee.label.setAttribute('x', p.mx);
          ee.label.setAttribute('y', labelY);
          labelObstacles.push(rect);
        }
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
      if (gitLaneBounds) {
        minX = Math.min(minX, gitLaneBounds.minX); minY = Math.min(minY, gitLaneBounds.minY);
        maxX = Math.max(maxX, gitLaneBounds.maxX); maxY = Math.max(maxY, gitLaneBounds.maxY);
      }
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
    module.exports = {
      hubRingLayout: hubRingLayout,
      matchesQuery: matchesQuery,
      layout: layout,
      topDownLayout: topDownLayout,
      gitLaneLayout: gitLaneLayout,
      trustClusteredLayout: trustClusteredLayout,
      trustTierOf: trustTierOf,
      TRUST_TIERS: TRUST_TIERS
    };
  }
})();
