# GH-1220 Manual Check — Optional `config_sha256` in `relay-drive/attest@1` for marathon resume config identity

## Summary

Verified in throwaway git repositories under `$TMPDIR` with stub agent binaries (never invoking live models or mutating this repository's working tree) across all required cases (a)–(e), both before the fix (**red control**) and after the fix (**green control**):

1. **Red control (pre-fix `32fa0165`)**:
   - `marathon_drive.py` does not compute or export `MARATHON_CONFIG_SHA256`, `relay_drive.py` does not write `config_sha256` into the attestation record, and `relay_attest.trailer_text()` does not bind `config_sha256`.
   - Changing `AGY_MODEL`, `--builder`, or `--phase-brief` on resume silently reuses the prior phase attestation (`case_c1_model_change_rebuilt: false`, `case_c2_builder_change_rebuilt: false`, `case_c3_brief_change_rebuilt: false`).
   - Mutating a stored `config_sha256` field in an attestation record is accepted by `relay_attest.load()` (`case_e_tampered_config_sha256_refused: false`) because `config_sha256` was not bound into `trailer_text(record)`.
2. **Green control (post-fix)**:
   - **(a) Legacy record without `config_sha256`**: reused on marathon resume with the warning `marathon-drive: phase plegacy: legacy attestation without config identity — reusing (GH-1220)`, and accepted by `relay_attest.load(..., relay_file=None, path=...)` (matching `jog_run.py`).
   - **(b) Matching record**: first fire writes `config_sha256` into `attest@1` and `config-sha256: <hex>` into the relay trailer; resuming with identical brief, builder, reviewer, and model env vars reuses the terminal relay without rebuilding.
   - **(c) Config change rebuilds with one-line reason**: changing `AGY_MODEL` (`c1`), `--builder` (`c2`), or `--phase-brief` contents (`c3`) logs `marathon-drive: phase p1: phase config changed since attestation — rebuilding (GH-1220)` (without printing the brief contents) and allocates a fresh `-R2`/`-R3`/`-R4` retry token to rebuild the phase.
   - **(d) `jog` loader compatibility**: `relay_attest.load(..., relay_file=None, target_repo=..., path=...)` accepts attestation records carrying `config_sha256` without any `SCHEMA` bump (`SCHEMA == "relay-drive/attest@1"`).
   - **(e) Tamper resistance via trailer binding**: changing only the stored `config_sha256` in `.git/relay-attest/<task>.json` causes `relay_attest.load()` to refuse the record with `"attestation record does not match its own trailer"` (and an empty string fails with `"attestation record field config_sha256 is not a non-empty string"`), while legacy records without `config_sha256` continue to match their legacy trailers and load cleanly.

## Commands & Output

### 1. Throwaway Git Repo Red/Green Check (`$TMPDIR`)

Command:

```bash
env -u XYZ_HARNESS PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" bash -c '. relay-automation/gate-env.sh && python3 -B .relay-scratch/probe_gh1220.py'
```

Output:

```json
{
  "sha_base": "32fa016599cc0ab77c6af15718cb58b325377c62",
  "red_pre_fix": {
    "case_a_legacy_reused": true,
    "case_a_legacy_warning_logged": false,
    "case_a_jog_loader_accepts_legacy": true,
    "case_b_wrote_config_sha256": false,
    "case_b_matching_record_reused": true,
    "case_c1_model_change_rebuilt": false,
    "case_c1_reason_logged": false,
    "case_c2_builder_change_rebuilt": false,
    "case_c2_reason_logged": false,
    "case_c3_brief_change_rebuilt": false,
    "case_c3_reason_logged": false,
    "case_c3_brief_not_printed": true,
    "case_d_jog_loader_accepts_record": true,
    "case_e_tampered_config_sha256_refused": false,
    "case_e_tampered_reason": null,
    "case_e_legacy_record_still_loads": true
  },
  "green_post_fix": {
    "case_a_legacy_reused": true,
    "case_a_legacy_warning_logged": true,
    "case_a_jog_loader_accepts_legacy": true,
    "case_b_wrote_config_sha256": true,
    "case_b_matching_record_reused": true,
    "case_c1_model_change_rebuilt": true,
    "case_c1_reason_logged": true,
    "case_c2_builder_change_rebuilt": true,
    "case_c2_reason_logged": true,
    "case_c3_brief_change_rebuilt": true,
    "case_c3_reason_logged": true,
    "case_c3_brief_not_printed": true,
    "case_d_jog_loader_accepts_record": true,
    "case_e_tampered_config_sha256_refused": true,
    "case_e_tampered_reason": "attestation record does not match its own trailer",
    "case_e_legacy_record_still_loads": true
  }
}
```

### 2. End-to-End `relay_drive.py` Trailer & Record Binding Check

Output from direct `relay_drive.py` terminal attestation with `MARATHON_CONFIG_SHA256=abc123def456`:

```json
{
  "case_a_legacy_reused_with_warning": "marathon-drive: phase plegacy: legacy attestation without config identity \u2014 reusing (GH-1220)",
  "case_a_jog_loader_accepts_legacy": true,
  "case_b_matching_record_reused": true,
  "case_c1_model_change_rebuilds_with_reason": "marathon-drive: phase p1: phase config changed since attestation \u2014 rebuilding (GH-1220)",
  "case_c2_builder_change_rebuilds_with_reason": "marathon-drive: phase p1: phase config changed since attestation \u2014 rebuilding (GH-1220)",
  "case_c3_brief_change_rebuilds_with_reason": "marathon-drive: phase p1: phase config changed since attestation \u2014 rebuilding (GH-1220)",
  "case_d_jog_loader_accepts_record_with_field": true,
  "case_e_tampered_config_sha256_refused": "attestation record does not match its own trailer",
  "case_e_empty_config_sha256_refused": "attestation record field config_sha256 is not a non-empty string",
  "case_e_legacy_record_still_loads": true,
  "real_relay_drive_writes_and_binds_field": true
}
```

### 3. Existing Attestation & Marathon Resume Regression Suites

```text
$ env -u XYZ_HARNESS bash -c '. relay-automation/gate-env.sh && bash test/gh505-relay-attest.sh && bash test/gh385-retry-token-satisfied.sh && bash test/gh371-interrupt-snapshot.sh && bash test/gh372-escalation-log-tail.sh && bash test/gh441-gate-env-contract.sh && bash test/gh308-frozen-twin-guard.sh --check --base HEAD'
gh505-relay-attest: all cases passed (0 failed)
gh385-retry-token-satisfied: 19 pass, 0 fail
gh371-interrupt-snapshot: 2 pass, 0 fail
gh372-escalation-log-tail: 3 pass, 0 fail
gh441-gate-env-contract: 18 pass, 0 fail
gh308-frozen-twin-guard: PASS
```
