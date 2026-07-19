<!--
CONTRACT.example.md — a complete, realistic capture doc with a machine-readable preflight contract.
This is the single source of truth for a swarm preflight lane.

Per-field annotations:
  target       The repo and ref the marathon should branch from.
               repo: "." (this repo) or a relative path to a foreign target.
               ref: The committish to branch from (e.g., "main" or a specific branch).
  gate         A runnable bash command that verifies the fix (e.g., "bash validate.sh").
               Preflight ensures this command exists, but it DOES NOT execute it during preflight.
  artifacts    Comma-separated list of files the builder may create or edit.
               The builder is strictly limited to these paths (plus inferred covering tests).
  remediation  Optional block indicating the scope of work (e.g., source: "self#phases").
  lanes        Optional block for assigning specific artifacts to specific agent capabilities.
  
  fix_probes   (CRITICAL FIELD) A list of probes that determine if the fix is still required.
               POLARITY: Probes detect the **bug**, NOT the fix.
               - path_absent: The file is missing (it shouldn't be).
               - path_present: The file is present (it shouldn't be).
               - grep_present: The bug evidence (string/regex) is still in the file.
               - grep_absent: The fix marker has not yet landed in the file.
               - command: A command whose exit code indicates the bug is still present.
               
               WARNING: Inverting the polarity (e.g., probing for the fix instead of the bug)
               will cause preflight to return **STALE (exit 4)**, which reads as "already done" —
               a false completion signal that will prevent the build from running.
-->

# GH-239: Implement Example Preflight Contract
We need to provide an example preflight contract in the vendored installation so consumers don't hit exit 3 without knowing what to copy.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "path_absent",
      "path": "relay-automation/CONTRACT.example.md"
    }
  ],
  "artifacts": [
    "relay-automation/CONTRACT.example.md"
  ],
  "remediation": {
    "source": "self#phases",
    "criteria": "Implement the example contract file as per requirements."
  }
}
```

## Phases
- [ ] Create `relay-automation/CONTRACT.example.md`
- [ ] Ensure it has annotations for all fields, especially `fix_probes`.
