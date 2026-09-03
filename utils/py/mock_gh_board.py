#!/usr/bin/env python3
"""mock_gh_board.py (GH-405) — Local debugging mock harness for GitHub Projects V2 API.

Speaks the `gh api graphql` CLI contract for Projects V2 queries and mutations,
allowing offline developer testing and debugging of board sync tools (such as board_sync.py)
without sending data to GitHub or requiring authentication.

CLI usage as gh stub:
    mock_gh_board.py api graphql -f query=... [-F key=value ...]

CLI management verbs:
    mock_gh_board.py --dump [--state PATH]
    mock_gh_board.py --seed [--state PATH]
    mock_gh_board.py --reset [--state PATH]
    mock_gh_board.py --fault FAULT_NAME [--state PATH]
"""

import json
import os
import re
import sys
from pathlib import Path

DEFAULT_STATE_FILE = Path(
    os.environ.get("XYZ_MOCK_BOARD_STATE", os.path.join(os.environ.get("TMPDIR", "/tmp"), "mock_gh_board_state.json"))
)


def get_default_state():
    return {
        "project_owner": "noelsaw1",
        "project_number": 3,
        "is_org": False,
        "project_id": "PVT_mock_proj_001",
        "fields": {
            "Status": {
                "id": "PVTF_status_001",
                "options": [
                    {"id": "OPT_in_progress_001", "name": "In progress"},
                    {"id": "OPT_todo_001", "name": "Todo"},
                    {"id": "OPT_done_001", "name": "Done"},
                ],
            }
        },
        "items": [],
        "issues": {
            "HiQS-Labs/XYZ-forge": {
                123: {"id": "ISS_mock_HiQS-Labs_XYZ-forge_123", "state": "OPEN"},
                124: {"id": "ISS_mock_HiQS-Labs_XYZ-forge_124", "state": "OPEN"},
                125: {"id": "ISS_mock_HiQS-Labs_XYZ-forge_125", "state": "OPEN"},
                126: {"id": "ISS_mock_HiQS-Labs_XYZ-forge_126", "state": "OPEN"},
                127: {"id": "ISS_mock_HiQS-Labs_XYZ-forge_127", "state": "OPEN"},
                128: {"id": "ISS_mock_HiQS-Labs_XYZ-forge_128", "state": "OPEN"},
                365: {"id": "ISS_mock_HiQS-Labs_XYZ-forge_365", "state": "CLOSED"},
                402: {"id": "ISS_mock_HiQS-Labs_XYZ-forge_402", "state": "OPEN"},
                405: {"id": "ISS_mock_HiQS-Labs_XYZ-forge_405", "state": "OPEN"},
            }
        },
        "faults": {},
        "next_item_id": 1,
    }


def load_state(state_path=None):
    p = Path(state_path) if state_path else DEFAULT_STATE_FILE
    if p.is_file():
        try:
            return json.loads(p.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            pass
    st = get_default_state()
    save_state(st, p)
    return st


def save_state(state, state_path=None):
    p = Path(state_path) if state_path else DEFAULT_STATE_FILE
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(state, indent=2), encoding="utf-8")


def resolve_project_v2_field(state, owner, number, field_name):
    # Check project match
    if owner != state["project_owner"] or int(number) != int(state["project_number"]):
        return None
    field_info = state["fields"].get(field_name)
    field_obj = None
    if field_info:
        field_obj = {
            "id": field_info["id"],
            "options": [{"id": opt["id"], "name": opt["name"]} for opt in field_info["options"]],
        }
    return {
        "id": state["project_id"],
        "field": field_obj,
    }


def handle_graphql(query, variables, state, state_path):
    # 1. user(login) / organization(login) -> projectV2(number) -> field
    if "projectV2" in query and "SingleSelectField" in query:
        owner = variables.get("o", state["project_owner"])
        number = int(variables.get("n", state["project_number"]))
        field_name = variables.get("f", "Status")
        proj = resolve_project_v2_field(state, owner, number, field_name)
        if state.get("is_org"):
            return {"data": {"user": None, "organization": {"projectV2": proj}}}
        return {"data": {"user": {"projectV2": proj}, "organization": None}}

    # 2. repository(owner, name) -> issue(number)
    if "repository(owner:" in query and "issue(number:" in query:
        repo_owner = variables.get("o", "")
        repo_name = variables.get("n", "")
        issue_num = int(variables.get("i", 0))
        repo_key = f"{repo_owner}/{repo_name}"
        repo_issues = state["issues"].get(repo_key, {})
        # If not present in fixture, generate a simulated open issue on demand
        if str(issue_num) in repo_issues:
            issue_data = repo_issues[str(issue_num)]
        elif issue_num in repo_issues:
            issue_data = repo_issues[issue_num]
        else:
            issue_data = {"id": f"ISS_mock_{repo_owner}_{repo_name}_{issue_num}", "state": "OPEN"}
            state["issues"].setdefault(repo_key, {})[str(issue_num)] = issue_data
            save_state(state, state_path)

        return {"data": {"repository": {"issue": issue_data}}}

    # 3. node(id: $id) -> ProjectV2 items pagination
    if "... on ProjectV2" in query and "items(" in query:
        proj_id = variables.get("id", state["project_id"])
        if proj_id != state["project_id"]:
            return {"data": {"node": None}}

        nodes = []
        for item in state.get("items", []):
            nodes.append({
                "id": item["id"],
                "content": {
                    "number": item["number"],
                    "repository": {"nameWithOwner": item["repository"]},
                },
            })

        return {
            "data": {
                "node": {
                    "items": {
                        "pageInfo": {
                            "endCursor": None,
                            "hasNextPage": False,
                        },
                        "nodes": nodes,
                    }
                }
            }
        }

    # 4. addProjectV2ItemById(input: {projectId: $p, contentId: $c})
    if "addProjectV2ItemById" in query:
        proj_id = variables.get("p", state["project_id"])
        content_id = variables.get("c", "")

        # Lookup issue details from content_id
        found_repo, found_num = "HiQS-Labs/XYZ-forge", 0
        for repo_key, iss_map in state.get("issues", {}).items():
            for num, iss in iss_map.items():
                if iss["id"] == content_id:
                    found_repo = repo_key
                    found_num = int(num)
                    break

        # Re-add creates a duplicate card (reproducing real GitHub behavior, [Should] 3)
        item_counter = state.get("next_item_id", len(state.get("items", [])) + 1)
        item_id = f"PVTI_mock_item_{item_counter:04d}"
        state["next_item_id"] = item_counter + 1

        new_item = {
            "id": item_id,
            "content_id": content_id,
            "repository": found_repo,
            "number": found_num,
            "field_values": {},
        }
        state["items"].append(new_item)
        save_state(state, state_path)

        return {"data": {"addProjectV2ItemById": {"item": {"id": item_id}}}}

    # 5. updateProjectV2ItemFieldValue(input: {projectId, itemId, fieldId, value: {singleSelectOptionId}})
    if "updateProjectV2ItemFieldValue" in query:
        proj_id = variables.get("p", state["project_id"])
        item_id = variables.get("i", "")
        field_id = variables.get("f", "")
        option_id = variables.get("o", "")

        # Fault injection check ([Should] 3)
        faults = state.get("faults", {})
        if faults.get("stale_option_once"):
            faults["stale_option_once"] = False
            save_state(state, state_path)
            return {
                "errors": [
                    {
                        "message": f"SingleSelect option {option_id!r} is stale or does not exist on field {field_id!r}",
                        "type": "NOT_FOUND",
                    }
                ]
            }

        # Validate option_id exists
        status_field = state["fields"].get("Status", {})
        valid_opt_ids = {opt["id"] for opt in status_field.get("options", [])}
        if option_id not in valid_opt_ids and not option_id.startswith("OPT_"):
            return {
                "errors": [
                    {"message": f"Option {option_id!r} not found on field {field_id!r}", "type": "NOT_FOUND"}
                ]
            }

        # Update item
        for item in state.get("items", []):
            if item["id"] == item_id:
                item.setdefault("field_values", {})[field_id] = option_id
                break
        save_state(state, state_path)

        return {"data": {"updateProjectV2ItemFieldValue": {"projectV2Item": {"id": item_id}}}}

    # 6. deleteProjectV2Item(input: {projectId, itemId})
    if "deleteProjectV2Item" in query:
        proj_id = variables.get("p", state["project_id"])
        item_id = variables.get("i", "")

        orig_len = len(state.get("items", []))
        state["items"] = [it for it in state.get("items", []) if it["id"] != item_id]
        save_state(state, state_path)

        return {"data": {"deleteProjectV2Item": {"deletedItemId": item_id}}}

    # Unhandled query
    return {"errors": [{"message": f"Unhandled mock query: {query[:100]}..."}]}


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    # Parse standalone CLI management options
    state_path = DEFAULT_STATE_FILE
    if "--state" in argv:
        idx = argv.index("--state")
        if idx + 1 < len(argv):
            state_path = Path(argv[idx + 1])
            argv = argv[:idx] + argv[idx + 2:]

    if "--dump" in argv:
        state = load_state(state_path)
        print(json.dumps(state, indent=2))
        return 0

    if "--reset" in argv:
        state = get_default_state()
        save_state(state, state_path)
        print(f"mock_gh_board: reset state at {state_path}")
        return 0

    if "--seed" in argv:
        state = get_default_state()
        # Seed 1 initial item (gh-123)
        state["items"] = [
            {
                "id": "PVTI_mock_item_0001",
                "content_id": "ISS_mock_HiQS-Labs_XYZ-forge_123",
                "repository": "HiQS-Labs/XYZ-forge",
                "number": 123,
                "field_values": {"PVTF_status_001": "OPT_in_progress_001"},
            }
        ]
        save_state(state, state_path)
        print(f"mock_gh_board: seeded state at {state_path}")
        return 0

    if "--fault" in argv:
        idx = argv.index("--fault")
        fault_name = argv[idx + 1] if idx + 1 < len(argv) else "stale_option_once"
        state = load_state(state_path)
        state.setdefault("faults", {})[fault_name] = True
        save_state(state, state_path)
        print(f"mock_gh_board: fault {fault_name!r} enabled at {state_path}")
        return 0

    # Support `gh api graphql` contract: argv may start with `api graphql ...` or directly with `-f` / `-F`
    query = None
    variables = {}

    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg in ("api", "graphql"):
            i += 1
            continue
        if arg == "-f" and i + 1 < len(argv):
            val = argv[i + 1]
            if val.startswith("query="):
                query = val[len("query="):]
            i += 2
            continue
        if arg.startswith("-fquery="):
            query = arg[len("-fquery="):]
            i += 1
            continue
        if arg == "-F" and i + 1 < len(argv):
            val = argv[i + 1]
            if "=" in val:
                k, v = val.split("=", 1)
                variables[k] = v
            i += 2
            continue
        if arg.startswith("-F") and "=" in arg:
            k, v = arg[2:].split("=", 1)
            variables[k] = v
            i += 1
            continue
        i += 1

    if not query:
        print("mock_gh_board: no GraphQL query provided", file=sys.stderr)
        return 2

    state = load_state(state_path)
    response = handle_graphql(query, variables, state, state_path)
    print(json.dumps(response))
    if "errors" in response and not response.get("data"):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
