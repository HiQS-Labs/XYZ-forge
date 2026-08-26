---
title: Marathon — housekeeping / quality-of-life (non Linux-RC)
created: 2026-08-26
branch: development
doc_type: project
roadmap_exempt: true
policy: two collision-free lanes, one wave
---

# Marathon 2026-08-26 — housekeeping lane

Deliberately excludes every 0.7.4 Linux-RC item (#123 #204 #205 #232 #233 #249 #251).

Both lanes preflight `ready (exit 0)` and share zero artifacts, so they can run
concurrently in separate full clones (a linked worktree shares the driver lock).

## Wave 1 — #182 ‖ #197

### Lane A · GH-182 — self_healer --mode heal is a facade
Containment refuses any real target, so `heal` cannot do the thing it claims.
Artifacts: `utils/py/self_healer.py`, `test/gh182-healer-facade-safety.sh`, `validate.sh`
Cut from 0.9.0 Cargo on 2026-08-25 as off-theme; this is its work home.

```bash
bash utils/swarm-preflight.sh --gh-issue 182
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-182-healer RELAY_WORKTREE_ISOLATION=1 \
relay-automation/marathon-drive.sh \
  --phase-brief relay-system/preflight/$(date +%F)/gh-182-healer-facade-safety/packet.md \
  --builder agy --reviewer codex \
  --artifact utils/py/self_healer.py,test/gh182-healer-facade-safety.sh,validate.sh \
  --pre-advance-cmd 'bash validate.sh' --require-clean --round-cap 4
```

### Lane B · GH-197 — two-tier xyz-vendor.sh
Tier 1 core harness by default; Tier 2 RELEASES overlay opt-in via `--with-releases`
or a `releases.db` already at root. Quality-of-life for every downstream vendored repo.
Artifacts: `relay-automation/xyz-vendor.sh`, `test/xyz-vendor.sh`,
`skills/relay-xyz/SKILL.md`, `relay-automation/README.md`,
plus new `relay-automation/xyz-releases-onboard.sh`, `test/gh197-vendor-tier-split.sh`

```bash
bash utils/swarm-preflight.sh --gh-issue 197
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-197-vendor-tier RELAY_WORKTREE_ISOLATION=1 \
relay-automation/marathon-drive.sh \
  --phase-brief relay-system/preflight/$(date +%F)/gh-197-vendor-tier-split/packet.md \
  --builder agy --reviewer codex \
  --artifact relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,skills/relay-xyz/SKILL.md,relay-automation/README.md,relay-automation/xyz-releases-onboard.sh,test/gh197-vendor-tier-split.sh \
  --pre-advance-cmd 'bash validate.sh' --require-clean --round-cap 4
```

## Done means
`bash validate.sh` exits 0 on each lane, and each lane's contract `remediation.criteria` is met.

## Not in this marathon
Every Linux-RC item. Also excluded for lack of a preflight contract: #141, #216, #215,
#222, #243, #252, #67, #75. Contract-bearing docs GH-544 / GH-555 / GH-564 have no
GitHub issue and cannot be preflighted by `--gh-issue`.
