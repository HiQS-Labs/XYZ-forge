#!/usr/bin/env python3
"""reachability_walk.py — GH-280 Phase 5 legacy-audit evidence generator (2026-08-29).

Function-level reachability over utils/py/jog_run.py, resolved from AST call edges,
with the executor-dispatch conditions of jog_run_main() toggled per configuration.

Method
------
1. Parse utils/py/jog_run.py; index every top-level def (and JogSupervisorLock methods)
   with its line range.
2. Extract intra-module call edges per function: `ast.Name` calls (plain functions) and
   `ast.Attribute` calls (recorded under the attribute name; JogSupervisorLock.acquire()
   called as supervisor_lock.acquire() resolves to the method).
3. The four dispatch sites inside jog_run_main() are config-sensitive (executor/simulate):
     jog_run.py:1486  if executor == "marathon" and not simulate:   -> validate_marathon_executor
     jog_run.py:1544  if executor == "marathon" and not simulate:   -> jog_reconcile_cold_start
     jog_run.py:1600  if executor == "marathon" and not simulate:   -> run_marathon_phase arm
     jog_run.py:1618  if isfile(preflight) and not simulate:        -> legacy preflight subprocess
   The else-arm of :1600 is the legacy arm -> run_single_phase_drive, handle_landing_boundary.
   These edges are switched per config below; every other edge is unconditional.
4. Roots = CLI verb entries (jog_run_main + jog_resume/jog_retry_gate/jog_retry_build/
   jog_land, reached from releases_app.py cmd_jog_* handlers, hand-audited table in
   releases_app.py:3716-3756) + the queue surface (jog_acquire_lease/jog_set_status/
   jog_reconcile_orphan_leases from releases_app.py:3623-3714).

Detector limits (GH-195 discipline — what this walk does NOT match)
------------------------------------------------------------------
- Name-based edges only: `getattr(jog_run, fn_name)` (releases_app.py:3731) and the
  handlers dict (releases_app.py:4780+) are dynamic dispatch; covered by the hand table,
  not by the AST walk.
- subprocess reachability (relay-drive.sh, bin/tick, gh, marathon-drive via argv) is
  shell/OS, invisible to a Python AST; covered by the committed grep census instead.
- Module-level side effects (none in jog_run.py beyond constants) are not modeled.
- Class instantiation `JogSupervisorLock(root)` resolves to __init__; attribute calls on
  the instance resolve by method NAME regardless of the variable — a different class with
  an identically-named method would alias (none exists in this module).
"""
import ast
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
SRC = os.path.join(REPO, "utils", "py", "jog_run.py")

with open(SRC, "r", encoding="utf-8") as f:
    text = f.read()
tree = ast.parse(text)
lines = text.splitlines()

# ── index defs ────────────────────────────────────────────────────────────────────────────────
funcs = {}  # name -> (start_line, end_line)
for node in tree.body:
    if isinstance(node, ast.FunctionDef):
        funcs[node.name] = (node.lineno, node.end_lineno)
    elif isinstance(node, ast.ClassDef):
        for sub in node.body:
            if isinstance(sub, ast.FunctionDef):
                funcs[sub.name] = (sub.lineno, sub.end_lineno)

# ── extract call edges ────────────────────────────────────────────────────────────────────────
edges = {name: set() for name in funcs}


def collect_calls(fn_node, bucket):
    for node in ast.walk(fn_node):
        if isinstance(node, ast.Call):
            if isinstance(node.func, ast.Name):
                bucket.add(node.func.id)
            elif isinstance(node.func, ast.Attribute):
                bucket.add(node.func.attr)


for node in tree.body:
    if isinstance(node, ast.FunctionDef):
        bucket = set()
        collect_calls(node, bucket)
        edges[node.name] |= bucket
    elif isinstance(node, ast.ClassDef):
        for sub in node.body:
            if isinstance(sub, ast.FunctionDef):
                bucket = set()
                collect_calls(sub, bucket)
                edges[sub.name] |= bucket

# keep only edges that point at defs in this module; resolve class instantiation
# JogSupervisorLock(...) -> acquire/release/__init__ (the methods the supervisor uses)
CLASS_CALLS = {"JogSupervisorLock": {"__init__", "acquire", "release"}}
internal = {}
for n, ts in edges.items():
    keep = {t for t in ts if t in funcs}
    for cls, methods in CLASS_CALLS.items():
        if cls in ts:
            keep |= methods
    internal[n] = keep

# ── config-sensitive arm selection inside jog_run_main ────────────────────────────────────────
# The AST sees EVERY call in jog_run_main; the two executor arms are mutually exclusive at
# runtime, guarded by `executor == "marathon" and not simulate` (:1486, :1544, :1600) with
# the legacy arm as the else (:1616-1660). Strip both arms from the unconditional edge set
# and add back exactly the arm the config selects — the toggled names are precisely the
# in-module callees of those guarded blocks.
MARATHON_ARM = {"validate_marathon_executor", "jog_reconcile_cold_start", "run_marathon_phase",
                "jog_resolve_ledger_gid"}  # :1487, :1547, :1601-1602 — all inside guarded blocks
LEGACY_ARM = {"run_single_phase_drive", "handle_landing_boundary"}  # :1639, :1653 — the else-arm
internal["jog_run_main"] = internal["jog_run_main"] - MARATHON_ARM - LEGACY_ARM

CONFIGS = {
    # name: (executor, simulate) — jog_run_main invoked with NO explicit --executor unless noted
    "pre-flip-default(relay)": ("relay", False),
    "post-flip-default(marathon)": ("marathon", False),
    "post-flip-window(--executor relay)": ("relay", False),
    "post-flip-simulate(minimal flip)": ("marathon", True),
    "post-window-target(marathon-only)": ("marathon", False),
}

# roots that exist regardless of config (CLI verbs + queue surface)
BASE_ROOTS = ["jog_resume", "jog_retry_gate", "jog_retry_build", "jog_land",
              "jog_acquire_lease", "jog_set_status", "jog_reconcile_orphan_leases"]


def roots_for(executor, simulate):
    rs = set(BASE_ROOTS)
    main = {"jog_run_main"}
    if executor == "marathon" and not simulate:
        main |= MARATHON_ARM
    else:
        # legacy arm: --executor relay, OR --simulate under EITHER default (the
        # `and not simulate` in the marathon-arm condition at :1600 routes a
        # simulate run into the legacy skeleton even when executor=marathon)
        main |= LEGACY_ARM
    return rs | main


def closure(roots, extra_edges=()):
    seen = set()
    stack = [r for r in roots if r in funcs]
    # deep-copy the edge sets: extra_edges must not leak back into the module-level
    # map (the first legacy config would otherwise re-add its arm to every later
    # config — an aliasing bug this script's first run exhibited on itself).
    edge_map = {k: set(v) for k, v in internal.items()}
    for src, tgt in extra_edges:
        edge_map.setdefault(src, set()).add(tgt)
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        stack.extend(edge_map.get(cur, ()))
    return seen


results = {}
for cfg, (executor, simulate) in CONFIGS.items():
    extra = [("jog_run_main", t) for t in (MARATHON_ARM if executor == "marathon" and not simulate
                                           else LEGACY_ARM)]
    results[cfg] = closure(roots_for(executor, simulate), extra)

# ── classification ────────────────────────────────────────────────────────────────────────────
FLIP_KEEPS = results["post-flip-window(--executor relay)"] | results["post-flip-simulate(minimal flip)"]
POST_FLIP_DEFAULT = results["post-flip-default(marathon)"]

CLASS_A, CLASS_B, CLASS_C = [], [], []
for name in sorted(funcs, key=lambda n: funcs[n][0]):
    if name in POST_FLIP_DEFAULT:
        CLASS_C.append(name)          # shared: reached even by the post-flip default run
    elif name in FLIP_KEEPS:
        CLASS_B.append(name)          # alive only during the window (relay flag / simulate)
    elif name in results["pre-flip-default(relay)"]:
        CLASS_A.append(name)          # dead the moment the flip lands
    else:
        CLASS_B.append(name)          # unreached by any modeled config (verb-only helpers)

print("GH-280 Phase 5 legacy-audit — function reachability walk")
print("parsed: %s (%d defs)" % (os.path.relpath(SRC, REPO), len(funcs)))
print()
print("Per-config reachability (x = reached):")
hdr = ["function", "lines"] + [c.split("(")[0] for c in CONFIGS]
print("  %-34s %-12s %s" % (hdr[0], hdr[1], " ".join("%-2s" % chr(97 + i) for i in range(len(CONFIGS)))))
order = {c: i for i, c in enumerate(CONFIGS)}
for name in sorted(funcs, key=lambda n: funcs[n][0]):
    s, e = funcs[name]
    marks = " ".join("%-2s" % ("x" if name in results[c] else ".") for c in CONFIGS)
    print("  %-34s %-12s %s" % (name, "%d-%d" % (s, e), marks))
print()
print("config key:")
for i, c in enumerate(CONFIGS):
    print("  %s = %s" % (chr(97 + i), c))
print()
for label, bucket in (("CLASS A — dead immediately post-flip", CLASS_A),
                      ("CLASS B — alive only during the window", CLASS_B),
                      ("CLASS C — shared, must survive removal", CLASS_C)):
    print("%s (%d):" % (label, len(bucket)))
    for name in bucket:
        s, e = funcs[name]
        print("    %s (jog_run.py:%d-%d)" % (name, s, e))
    print()
