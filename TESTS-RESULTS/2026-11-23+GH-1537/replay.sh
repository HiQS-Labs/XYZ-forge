#!/usr/bin/env bash
# GH-1537 real-history replay of PR #1526's final refresh push (docs PR; it paid a full gate for this shape on 2026-11-19).
# Real commits: remote tip 5c5557936 (docs + a development merge, already pushed), local b7102ff9e = "Merge remote-tracking branch
# 'origin/development'" whose development parent is 6c90ed1e2. The live remote is replaced by a local bare mirror whose
# `development` is pinned to that parent (the integration tip as it stood when the push happened; the real tip has since moved
# past the landed PR). validate.sh/pdda.sh are stubs so a gate costs a second; the hook, classifier and gate_receipt are real.
# Usage: SRC=<task clone> BASE_HOOK=<pre-change hook file> OUT=<results dir> bash replay.sh
set -u
SRC="${SRC:?task clone}"; BASE_HOOK="${BASE_HOOK:?}"; OUT="${OUT:?}"
R=5c5557936a28c8e815f82b489eded3ded2bbc9bb; L=b7102ff9e; D=6c90ed1e2
W="$(mktemp -d "${TMPDIR:-/tmp}/gh1537-replay.XXXXXX")"; [ -n "$W" ] && [ -d "$W" ] || exit 2
trap 'rm -rf "$W"' EXIT
export PYTHONDONTWRITEBYTECODE=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
git clone -q --no-local --bare "$SRC" "$W/bare.git" 2>/dev/null
LFULL="$(git -C "$W/bare.git" rev-parse "$L^{commit}")"; DFULL="$(git -C "$W/bare.git" rev-parse "$D^{commit}")"
git -C "$W/bare.git" update-ref refs/heads/development "$DFULL"
git -C "$W/bare.git" update-ref -d refs/heads/main 2>/dev/null
git clone -q --no-local "$W/bare.git" "$W/w" 2>/dev/null
cd "$W/w" || exit 2
git config user.email t@t; git config user.name t
git fetch -q origin "$R" "$LFULL" 2>/dev/null; git checkout -q --detach "$LFULL"
# The replayed tree predates the hook's gate_receipt `admit` verb: overlay the CURRENT support files the hook calls.
for f in utils/py/rtl.py utils/ci-route.sh; do cp "$SRC/$f" "$f"; done
# GH-1399 attempt admission would refuse a foreign historical commit as a task candidate; it is unchanged by GH-1537 and is isolated
# here exactly as test/gh544-pre-push-gate.sh isolates it (real gate_receipt.py kept as the impl for every other verb).
cp "$SRC/utils/py/gate_receipt.py" utils/py/gate_receipt_impl.py
cat > utils/py/gate_receipt.py <<'STUB'
import gate_receipt_impl as impl
def attempt_admission(*args, **kwargs):
    return {"kind": "fixture-admitted"}
impl.attempt_admission = attempt_admission
if __name__ == "__main__":
    impl.main()
STUB
printf '#!/usr/bin/env bash\n[ "${1:-}" = "--print-mode" ] && { echo "validate.sh: stub"; exit 0; }\necho "stub full gate ran"; exit 0\n' > validate.sh
printf '#!/usr/bin/env bash\necho "stub documentation gate ran"\n' > utils/pdda/pdda.sh
mkdir -p "$OUT"; : > "$OUT/replay.log"
echo "own-diff paths (merge-base(development@$D, local)..local):" | tee -a "$OUT/replay.log"
git diff --no-renames --name-only "$(git merge-base "origin/development" HEAD)" HEAD | sed 's/^/  /' | tee -a "$OUT/replay.log"
echo "update-range path count (remote..local): $(git diff --no-renames --name-only "$R" HEAD | wc -l | tr -d ' ')" | tee -a "$OUT/replay.log"
for variant in base cand; do
  hook="$SRC/githooks/pre-push"; [ "$variant" = base ] && hook="$BASE_HOOK"
  cp "$hook" githooks/pre-push
  out="$(printf 'refs/heads/docs/replay-1526 %s refs/heads/docs/replay-1526 %s\n' "$LFULL" "$R" | bash githooks/pre-push origin 2>&1)"; rc=$?
  printf '%s\n' "$out" | sed "s|^|[$variant] |" >> "$OUT/replay.log"
  route=unknown
  case "$out" in *"docs-only update"*) route=docs ;; *"running the full gate before"*) route=full ;; esac
  printf '{"replay":"pr1526-final-refresh","variant":"%s","hook_sha256":"%s","remote_sha":"%s","local_sha":"%s","dev_parent":"%s","exit":%s,"route":"%s"}\n' \
    "$variant" "$(shasum -a 256 "$hook" | cut -c1-16)" "$R" "$LFULL" "$DFULL" "$rc" "$route" >> "$OUT/replay-provenance.jsonl"
  echo "$variant: exit=$rc route=$route"
done
