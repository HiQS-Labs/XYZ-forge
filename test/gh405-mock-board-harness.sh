#!/usr/bin/env bash
# gh405-mock-board-harness.sh — GH-405: test suite for mock_gh_board.py offline simulator
#
# Hermetic, offline verification of mock_gh_board.py CLI interface, Projects V2
# query/mutation resolvers, re-add duplicate creation fidelity, and fault injection.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$ROOT/utils/py/mock_gh_board.py"
SYNC_TOOL="$ROOT/utils/py/board_sync.py"

. "$ROOT/test/lib/fixture-guard.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok  - $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh405-mock-board.XXXXXX")"
fixture_guard_init "$WORK"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

MOCK_STATE="$WORK/mock_state.json"
SYNC_STATE="$WORK/sync_state.json"

[ -f "$TOOL" ] || { echo "mock_gh_board.py missing at $TOOL" >&2; exit 1; }
[ -x "$TOOL" ] || { echo "mock_gh_board.py not executable" >&2; exit 1; }

echo "GH-405 mock_gh_board harness:"

# ── 1. Management CLI verbs ───────────────────────────────────────────────────
echo "1. management CLI verbs"
RESET_OUT="$(python3 "$TOOL" --reset --state "$MOCK_STATE" 2>&1)"
if grep -q "reset state" <<<"$RESET_OUT" && [ -f "$MOCK_STATE" ]; then
  ok "--reset initializes clean state file"
else bad "--reset failed: $RESET_OUT"; fi

DUMP_OUT="$(python3 "$TOOL" --dump --state "$MOCK_STATE" 2>&1)"
if grep -q '"project_owner": "noelsaw1"' <<<"$DUMP_OUT" && grep -q '"Status"' <<<"$DUMP_OUT"; then
  ok "--dump outputs valid JSON state"
else bad "--dump failed: $DUMP_OUT"; fi

SEED_OUT="$(python3 "$TOOL" --seed --state "$MOCK_STATE" 2>&1)"
if grep -q "seeded state" <<<"$SEED_OUT"; then
  ok "--seed populates initial items"
else bad "--seed failed: $SEED_OUT"; fi

# ── 2. GraphQL query resolution ────────────────────────────────────────────────
echo "2. query resolution"
# user.projectV2 query
Q_PROJ='query($o:String!,$n:Int!,$f:String!){user(login:$o){projectV2(number:$n){id field(name:$f){... on ProjectV2SingleSelectField{id options{id name}}}}}}'
PROJ_RES="$(python3 "$TOOL" --state "$MOCK_STATE" api graphql -f query="$Q_PROJ" -F o=noelsaw1 -F n=3 -F f=Status 2>&1)"; PROJ_RC=$?
if [ "$PROJ_RC" -eq 0 ] && grep -q '"id": "PVT_mock_proj_001"' <<<"$PROJ_RES" && grep -q '"name": "In progress"' <<<"$PROJ_RES"; then
  ok "user projectV2 and single-select field options resolved"
else bad "user project query failed (rc=$PROJ_RC): $PROJ_RES"; fi

# repository.issue query
Q_ISS='query($o:String!,$n:String!,$i:Int!){repository(owner:$o,name:$n){issue(number:$i){id state}}}'
ISS_RES="$(python3 "$TOOL" --state "$MOCK_STATE" api graphql -f query="$Q_ISS" -F o=HiQS-Labs -F n=XYZ-forge -F i=405 2>&1)"; ISS_RC=$?
if [ "$ISS_RC" -eq 0 ] && grep -q '"id": "ISS_mock_HiQS-Labs_XYZ-forge_405"' <<<"$ISS_RES" && grep -q '"state": "OPEN"' <<<"$ISS_RES"; then
  ok "repository issue node resolved"
else bad "issue query failed (rc=$ISS_RC): $ISS_RES"; fi

# ── 3. Mutation and duplicate card creation fidelity (Should 3) ───────────────
echo "3. mutations & duplicate card fidelity"
python3 "$TOOL" --reset --state "$MOCK_STATE" >/dev/null

# Add item 1
Q_ADD='mutation($p:ID!,$c:ID!){addProjectV2ItemById(input:{projectId:$p,contentId:$c}){item{id}}}'
ADD1_RES="$(python3 "$TOOL" --state "$MOCK_STATE" api graphql -f query="$Q_ADD" -F p=PVT_mock_proj_001 -F c=ISS_mock_HiQS-Labs_XYZ-forge_405 2>&1)"
ADD1_ID="$(grep -o 'PVTI_mock_item_[0-9]*' <<<"$ADD1_RES" | head -n 1)"
if [ -n "$ADD1_ID" ]; then
  ok "addProjectV2ItemById creates first item ($ADD1_ID)"
else bad "first add failed: $ADD1_RES"; fi

# Add same item again -> must create distinct second item ID (Should 3 fidelity)
ADD2_RES="$(python3 "$TOOL" --state "$MOCK_STATE" api graphql -f query="$Q_ADD" -F p=PVT_mock_proj_001 -F c=ISS_mock_HiQS-Labs_XYZ-forge_405 2>&1)"
ADD2_ID="$(grep -o 'PVTI_mock_item_[0-9]*' <<<"$ADD2_RES" | head -n 1)"
if [ -n "$ADD2_ID" ] && [ "$ADD1_ID" != "$ADD2_ID" ]; then
  ok "repeated addProjectV2ItemById creates distinct duplicate item ($ADD2_ID != $ADD1_ID)"
else bad "duplicate add did not produce distinct ID: $ADD2_RES"; fi

# Update status
Q_SET='mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){projectV2Item{id}}}'
SET_RES="$(python3 "$TOOL" --state "$MOCK_STATE" api graphql -f query="$Q_SET" -F p=PVT_mock_proj_001 -F i="$ADD1_ID" -F f=PVTF_status_001 -F o=OPT_in_progress_001 2>&1)"; SET_RC=$?
if [ "$SET_RC" -eq 0 ] && grep -q "$ADD1_ID" <<<"$SET_RES"; then
  ok "updateProjectV2ItemFieldValue sets field value"
else bad "status update failed (rc=$SET_RC): $SET_RES"; fi

# Delete duplicate item
Q_DEL='mutation($p:ID!,$i:ID!){deleteProjectV2Item(input:{projectId:$p,itemId:$i}){deletedItemId}}'
DEL_RES="$(python3 "$TOOL" --state "$MOCK_STATE" api graphql -f query="$Q_DEL" -F p=PVT_mock_proj_001 -F i="$ADD2_ID" 2>&1)"; DEL_RC=$?
if [ "$DEL_RC" -eq 0 ] && grep -q "$ADD2_ID" <<<"$DEL_RES"; then
  ok "deleteProjectV2Item removes item"
else bad "delete failed (rc=$DEL_RC): $DEL_RES"; fi

# ── 4. End-to-end integration with board_sync.py ──────────────────────────────
echo "4. integration with board_sync.py"
python3 "$TOOL" --reset --state "$MOCK_STATE" >/dev/null

export XYZ_BOARD_SYNC_GH_BIN="$TOOL"
export XYZ_MOCK_BOARD_STATE="$MOCK_STATE"
export XYZ_BOARD_SYNC_STATE_PATH="$SYNC_STATE"

TOUCH_OUT="$(python3 "$SYNC_TOOL" touch 405 --write 2>&1)"; TOUCH_RC=$?
if [ "$TOUCH_RC" -eq 0 ] && grep -q "gh-405: added + Status='In progress'" <<<"$TOUCH_OUT"; then
  ok "board_sync touch 405 --write completes via mock"
else bad "touch failed (rc=$TOUCH_RC): $TOUCH_OUT"; fi

# Idempotent second touch
TOUCH2_OUT="$(python3 "$SYNC_TOOL" touch 405 --write 2>&1)"
if grep -q "already on board.*no-op" <<<"$TOUCH2_OUT"; then
  ok "board_sync check-first reports already on board (no-op)"
else bad "check-first failed: $TOUCH2_OUT"; fi

# ── 5. Fault injection and self-heal retry (Demo 2) ─────────────────────────────
echo "5. fault injection and self-heal retry"
python3 "$TOOL" --reset --state "$MOCK_STATE" >/dev/null
python3 "$TOOL" --fault stale_option_once --state "$MOCK_STATE" >/dev/null

FAULT_TOUCH_OUT="$(python3 "$SYNC_TOOL" touch 405 --write 2>&1)"; FAULT_RC=$?
if [ "$FAULT_RC" -eq 0 ] \
   && grep -q "re-resolved IDs and succeeded" <<<"$FAULT_TOUCH_OUT" \
   && grep -q "gh-405: added + Status='In progress'" <<<"$FAULT_TOUCH_OUT"; then
  ok "fault injection triggers self-healing retry without duplicating card"
else bad "fault retry failed (rc=$FAULT_RC): $FAULT_TOUCH_OUT"; fi

DEDUPE_OUT="$(python3 "$SYNC_TOOL" dedupe 2>&1)"
if grep -q "no duplicate cards" <<<"$DEDUPE_OUT"; then
  ok "dedupe confirms single item preserved after self-heal retry"
else bad "unexpected duplicates found: $DEDUPE_OUT"; fi

echo
echo "GH-405 mock_gh_board harness: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
