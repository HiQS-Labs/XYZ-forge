#!/usr/bin/env python3
"""triage.py — the deterministic half of /standup (GH-77).

Owns everything mechanical: cross-lens dedup, tier classification, ranking, suppression, capping,
parking, and rendering the whole transcript. `SKILL.md` chooses only the verdict clause and the
`what` phrasing; nothing else is model-authored, so the frozen second-run transcript is
byte-comparable.

Why this file exists at all: the GH-77 PRD went four review rounds across two independent models and
escalated at the cap with a flat finding rate (11 -> 13 -> 10 -> 10). The defects were not hard —
they were a state machine specified in prose, where every gap needs a human reader to find it. Three
of the four rounds' structural findings are pinned here as executable behaviour instead:

  * a tier-1..3 item is NEVER silent (rendered, or counted in K with a paging escape hatch);
  * suppression hashes a canonical live-state map, so a deduped multi-lens item has one defined
    fingerprint and an escalation re-raises;
  * a park file is never itself emitted as an item, and `close` is never executed — only `check`.

Contract:
    triage.py --lenses lenses.json [--session-state PATH] [--parked-dir DIR]
              (--dry-run | --apply) [--page N] [--verdict CODE] [--verdict-clause TEXT]

Exit: 0 clean · 2 usage · 3 one or more lenses degraded.
"""

import argparse
import hashlib
import json
import os
import re
import sys

# ── constants the PRD freezes ──────────────────────────────────────────────────────────────────
CAP = 7                      # frozen tactical cap
TOTAL_LINES = 15             # 1 opening + 1 heading + 7 items + 1 notices + 1 heading + 4 body
PART2_BODY_MAX = 4
CRITICAL_TIERS = (1, 2, 3)   # never suppressed, never parked, never silent

# Corruption rules, matching the checker's own grouping at releases_app.py:2366. `dump-missing` was
# absent from an earlier draft, which would have classified a missing dump as housekeeping.
CORRUPTION_RULES = frozenset(
    {"dump-divergence", "dump-missing", "generation-mismatch", "receipt-chain", "bypass-detected"}
)
# Tier-5 advisories, by the name `check` actually emits (not the internal tally names).
ROT_RULES = frozenset({"release-overdue", "release-target-passed", "temp-ref-stale"})
PERSISTED_ARTIFACTS = frozenset({"releases.db", "releases.sql"})

EFFORT_RANK = {"S": 0, "M": 1, "L": 2}

# Part 2 verdicts are a finite vocabulary. Free prose here was a review finding: an unbounded clause
# defeats both determinism and the product's entire brevity goal.
VERDICTS = {
    "no-contradiction": "No contradiction found between the ledgers and this session's snapshot.",
    "ledger-behind": "The ROADMAP ledger is behind its shadow — sync before trusting either.",
    "release-overdue": "A release is past its target date with its exit criterion unresolved.",
    "insufficient-evidence": "Not enough signal in this snapshot to judge the plan; /radar would settle it.",
}
CLAUSE_MAX = 120  # chars; newline-free. An unbounded clause is a wall of text with extra steps.

DEGRADATION = {
    "D1": "gh unavailable",
    "D2": "PR list truncated",
    "D3": "no PARKED/",
    "D4": "no ledger",
    "D5": "lens incomplete",
    "D6": "empty session",
}


def die(msg, code=2):
    sys.stderr.write("triage: %s\n" % msg)
    raise SystemExit(code)


# ── tier classification ────────────────────────────────────────────────────────────────────────
def classify(cand):
    """First matching row wins. Tier 6 is the deterministic fallback, so this always terminates."""
    lens = cand["lens"]
    payload = cand.get("evidence_payload", "")
    rule = cand.get("rule_name") or ""

    # Tier 1 — corruption. Both emission shapes count: the checker prints corruption through fail()
    # as `FAIL: rule=...` while advisories go through warn() as `warn: rule=...`. Matching only
    # `warn:` made the founding incident class produce no candidate at all — the escalating finding.
    if lens == 6 and rule in CORRUPTION_RULES:
        return 1
    if lens == 2 and os.path.basename(payload) in PERSISTED_ARTIFACTS:
        return 1
    # Tier 2 — a crash the session actually observed, never inferred reachability.
    if cand.get("tier_hint") == "traceback":
        return 2
    # Tier 3 — operator label only. Never the agent's own judgement.
    if cand.get("tier_hint") == "operator-label":
        return 3
    # Tier 4 — one step from closed.
    if lens == 4 and cand.get("merge_state") == "CLEAN":
        return 4
    if lens == 3 and cand.get("ahead", 0) > 0 and cand.get("upstream_state") == "tracked" \
            and cand.get("clean_tree"):
        return 4
    if lens == 1 and effort_bin(cand) == "S":
        return 4
    # Tier 5 — rot.
    if lens == 4 and cand.get("stale_days", 0) > 7:
        return 5
    if lens == 3 and cand.get("behind", 0) > 0:
        return 5
    if lens in (5, 7, 8):
        return 5
    if lens == 6 and rule in ROT_RULES:
        return 5
    return 6


def effort_bin(cand):
    """S = a single command with no argument the agent must invent. M = one file to edit.
    L = everything else, including every inspect: action."""
    kind = cand.get("close_kind", "inspect")
    if kind == "command":
        return "S"
    if kind == "file-edit":
        return "M"
    return "L"


# ── dedup, fingerprint, ranking ────────────────────────────────────────────────────────────────
def dedup(cands):
    """Collapse on identical key. Keys are entity-canonical, so this is the whole rule — it does not
    depend on which lens fired, which an earlier draft got wrong (first-lens-wins made a key change
    when an unrelated lens appeared)."""
    merged = {}
    for c in cands:
        k = c["key"]
        if k not in merged:
            c = dict(c)
            c["_contrib"] = {str(c["lens"]): c.get("live_state", "")}
            c["_evidence"] = [(c.get("evidence_type", ""), c.get("evidence_payload", ""))]
            merged[k] = c
            continue
        m = merged[k]
        m["_contrib"][str(c["lens"])] = c.get("live_state", "")
        m["_evidence"].append((c.get("evidence_type", ""), c.get("evidence_payload", "")))
        # highest tier any contributing lens justified == lowest number
        if classify(c) < classify(m):
            for f in ("lens", "rule_name", "tier_hint", "merge_state", "close", "close_kind"):
                if f in c:
                    m[f] = c[f]
    return list(merged.values())


def fingerprint(item, tier):
    """sha256 over a canonical, lens-sorted map of every contributing live-state payload.

    Hashing one singular payload was undefined for a deduped multi-lens item — a review finding.
    Sorting by lens id makes it stable when contributions arrive in a different order, and a
    disappearing lens changes the map, which correctly re-raises."""
    canon = json.dumps(item["_contrib"], sort_keys=True, separators=(",", ":"))
    blob = "%s\0%d\0%s" % (item["key"], tier, canon)
    return hashlib.sha256(blob.encode("utf-8")).hexdigest()[:16]


UNKNOWN_AGE = float("inf")  # sorts after every known age *within its tier*: unmeasured never jumps


def sort_key(item):
    st = item.get("staleness")
    age = UNKNOWN_AGE if st is None else float(st)
    return (item["_tier"], age, EFFORT_RANK[effort_bin(item)], item["key"])


# ── rendering ──────────────────────────────────────────────────────────────────────────────────
DELIM = " — "
ESCAPED = " —​— "  # zero-width joiner keeps the three top-level separators unambiguous


def esc(s):
    return str(s).replace(DELIM, ESCAPED)


def render_item(item):
    ev = "%s:%s" % (item.get("evidence_type", ""), item.get("evidence_payload", ""))
    return "%d · %s%s%s%s%s" % (
        item["_tier"], esc(item["what"]), DELIM, esc(ev), DELIM, esc(item["close"])
    )


def render(items, notices, verdict_code, clause, degraded_ids, page, pages):
    out = []
    branch = os.environ.get("STANDUP_BRANCH", "?")
    shown = items
    if verdict_code not in VERDICTS:
        die("unknown verdict code %r (choose from %s)" % (verdict_code, ", ".join(sorted(VERDICTS))))
    if clause and ("\n" in clause or len(clause) > CLAUSE_MAX):
        die("verdict clause must be newline-free and <= %d chars" % CLAUSE_MAX)

    out.append("%s — %d open, %d critical." % (
        branch, len(shown), sum(1 for i in shown if i["_tier"] in CRITICAL_TIERS)))
    out.append("Do this now" + (" (page %d/%d)" % (page, pages) if pages > 1 else ""))
    if shown:
        out.extend(render_item(i) for i in shown)
    else:
        out.append("Nothing open.")
    if notices:
        out.append(notices)
    out.append("Plan")
    body = [VERDICTS[verdict_code] + (" " + clause if clause else "")]
    body.extend(degradation_lines(degraded_ids))
    out.extend(body[:PART2_BODY_MAX])
    return out


def degradation_lines(ids):
    """Lossless within the cap: <=3 IDs get a sentence each, more collapse to one line naming every
    ID. Nothing is ever dropped — 'loud, never silent' colliding with a hard cap was a finding."""
    ids = sorted(set(ids))
    if not ids:
        return []
    if len(ids) <= PART2_BODY_MAX - 1:
        return ["Degraded: %s — %s." % (i, DEGRADATION.get(i, "?")) for i in ids]
    return ["Degraded: " + ", ".join("%s %s" % (i, DEGRADATION.get(i, "?")) for i in ids) + "."]


# ── PARKED ─────────────────────────────────────────────────────────────────────────────────────
PARK_RE = re.compile(r"^- \[([^\]]+)\]")


def read_parked(parked_dir):
    """Return {item-key: fingerprint} across every PARKED/*.md."""
    seen = {}
    if not os.path.isdir(parked_dir):
        return seen
    for name in sorted(os.listdir(parked_dir)):
        if not name.endswith(".md"):
            continue
        with open(os.path.join(parked_dir, name), "r", encoding="utf-8") as fh:
            for line in fh:
                m = PARK_RE.match(line)
                if not m:
                    continue
                fp = ""
                fpm = re.search(r"fingerprint:\s*([0-9a-f]{16})", line)
                if fpm:
                    fp = fpm.group(1)
                seen[m.group(1)] = fp
    return seen


def park_record(item):
    chk = item.get("check") or {}
    return ("- [%s] tier %d · %s — evidence: %s:%s — check: %s — close: %s "
            "— fingerprint: %s — first seen: %s") % (
        item["key"], item["_tier"], item["what"],
        item.get("evidence_type", ""), item.get("evidence_payload", ""),
        json.dumps(chk, sort_keys=True, separators=(",", ":")),
        item["close"], item["_fp"], item.get("first_seen", ""),
    )


def main(argv=None):
    ap = argparse.ArgumentParser(prog="triage.py", add_help=True)
    ap.add_argument("--lenses", required=True)
    ap.add_argument("--session-state")
    ap.add_argument("--parked-dir", default="PARKED")
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--apply", action="store_true")
    ap.add_argument("--page", type=int, default=1,
                    help="1-based page of the ranked list, %d per page. Replaces an uncapped "
                         "--all, which contradicted the frozen cap." % CAP)
    ap.add_argument("--verdict", default="no-contradiction")
    ap.add_argument("--verdict-clause", default="")
    args = ap.parse_args(argv)

    with open(args.lenses, "r", encoding="utf-8") as fh:
        doc = json.load(fh)

    degraded, cands = [], []
    for lid, lens in sorted(doc.get("lenses", {}).items(), key=lambda kv: int(kv[0])):
        if lens.get("status") == "degraded":
            if lens.get("degraded_id"):
                degraded.append(lens["degraded_id"])
            continue
        for c in lens.get("candidates", []):
            c = dict(c)
            c["lens"] = int(lid)
            missing = [f for f in ("key", "what", "evidence_type", "evidence_payload", "close")
                       if not c.get(f)]
            if missing:
                # A lens that cannot supply the required fields does not emit the candidate; it
                # degrades loudly instead. Silence here would report a sweep never performed.
                degraded.append("D5")
                continue
            cands.append(c)

    items = dedup(cands)
    for it in items:
        it["_tier"] = classify(it)
        it["_fp"] = fingerprint(it, it["_tier"])

    prior = {}
    if args.session_state and os.path.exists(args.session_state):
        with open(args.session_state, "r", encoding="utf-8") as fh:
            prior = json.load(fh).get("fingerprints", {})
    parked = read_parked(args.parked_dir)

    kept, suppressed = [], 0
    for it in sorted(items, key=sort_key):
        if it["_tier"] in CRITICAL_TIERS:
            kept.append(it)          # never suppressed, never parked
            continue
        if prior.get(it["key"]) == it["_fp"] or parked.get(it["key"]) == it["_fp"]:
            suppressed += 1
            continue
        kept.append(it)

    pages = max(1, (len(kept) + CAP - 1) // CAP)
    page = min(max(1, args.page), pages)
    shown = kept[(page - 1) * CAP: page * CAP]
    overflow = [i for i in kept[page * CAP:] if i["_tier"] not in CRITICAL_TIERS]
    k_crit = sum(1 for i in kept if i["_tier"] in CRITICAL_TIERS) - \
        sum(1 for i in shown if i["_tier"] in CRITICAL_TIERS)

    bits = []
    if overflow:
        bits.append("%d parked" % len(overflow))
    if suppressed:
        bits.append("%d suppressed" % suppressed)
    if k_crit:
        bits.append("%d critical beyond cap" % k_crit)
    if "D3" in degraded:
        bits.append("no PARKED/ — say where to put it")
    notices = ""
    if bits:
        notices = ", ".join(bits) + "."
        if k_crit or overflow:
            notices += " `triage.py --page %d` lists the rest." % (page + 1)

    lines = render(shown, notices, args.verdict, args.verdict_clause,
                   [d for d in degraded if d != "D3"], page, pages)
    if len(lines) > TOTAL_LINES:
        die("render exceeded the %d-line cap (%d) — this is a bug, not a warning"
            % (TOTAL_LINES, len(lines)), 2)
    sys.stdout.write("\n".join(lines) + "\n")

    if args.apply:
        new = [i for i in overflow if i["key"] not in parked]
        revised = [i for i in overflow if i["key"] in parked and parked[i["key"]] != i["_fp"]]
        if new or revised:
            if not os.path.isdir(args.parked_dir):
                die("no %s/ — refusing to create a top-level directory unannounced"
                    % args.parked_dir, 2)
            stamp = os.environ.get("STANDUP_STAMP", "0000-00-00-0000")
            path = os.path.join(args.parked_dir, "%s-standup.md" % stamp)
            with open(path, "a", encoding="utf-8") as fh:
                for i in new:
                    fh.write(park_record(i) + "\n")
                for i in revised:
                    fh.write("- [%s] REVISED %s — live state changed\n" % (i["key"], i["_fp"]))
        # Session state lives under PARKED/, inside the frozen write authority. An earlier draft put
        # it in .git/, which both amended a frozen decision the spec had no standing to amend and
        # broke in linked worktrees, where .git is a file.
        if args.session_state:
            state = {"fingerprints": dict(prior)}
            for i in kept:
                state["fingerprints"][i["key"]] = i["_fp"]
            with open(args.session_state, "w", encoding="utf-8") as fh:
                json.dump(state, fh, sort_keys=True, indent=0)

    return 3 if degraded else 0


if __name__ == "__main__":
    raise SystemExit(main())
