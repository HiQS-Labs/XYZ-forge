# GH-484 alpha evidence — partial app verification

## Later checkpoint — 2026-09-07

The initial 14-skill observations below are historical. AgentChorus was subsequently
imported, making 15 skills, and deploy-skills was replaced by skills-army-hq through
the manager's add/activate/sync/remove/sync flow. All five manager links were verified
and the old copy ZIP-backed up. The top-level README matches the shipped bundle.

After reboot, ZCode's User Skills settings listed all 14 then-selected alpha skills
enabled, including deploy-skills; its details showed Personal / Enabled. Antigravity's
global Customizations list also showed deploy-skills. These establish discovery of
the pre-rename name, not end-to-end execution or post-rename UI verification.

AgentChorus's Agy link was externally retargeted to temporary review clones after
deployment. On explicit operator request its exact link was restored with the
shared transaction/history functions and readable SKILL.md verified. The normal
CLI refuses retargeted owned links even with --migrate-from: review this recovery
usability limitation. The writer causing the retargeting remains unidentified.
Four unrelated Claude variant conflicts remain preserved. Do not claim full health.

## Initial observations

Local payloads and configuration are deliberately not committed. Version/discovery
observations below were made on 2026-09-07; paths are home-relative or redacted.

The collection contains all 14 requested folders. An independent nonempty set
assertion matched the named requirement list; omitting debug-mantra deliberately
failed that assertion. All 66 owned app links passed exact readlink and byte-for-byte
SKILL.md read-through checks. No skills-sync-trinity discovery entry exists in the
five configured physical roots. Four conflicting Claude entries remain untouched.

| Consumer | Version observed | Filesystem result | App-level result |
|---|---|---|---|
| VS Code Claude Code | extension 2.1.263, VS Code 1.135.0 | 10/14 owned links; daily/debug-mantra/recon/swe remain prior variants | Extension UI observed in an active user session with an unsent draft; no prompt injected or session interrupted. Discovery/invocation unverified. |
| VS Code Codex | extension 26.901.22334, VS Code 1.135.0 | 14/14 at shared root and compatibility root, same physical payloads | Current Codex agent's skill catalog refreshed and included deploy-skills; separate extension UI invocation not yet observed. |
| Codex desktop (bundle com.openai.codex; display ChatGPT) | 26.901.41600 | Same shared/compatibility roots | Computer-use tool explicitly denied access for safety reasons; not bypassed. App UI verification blocked. |
| Antigravity | 2.12.2 | 14/14 at current documented global root | Only “Loading Antigravity” observed; skill picker/invocation unverified. |
| ZCode | 3.11.2 | 14/14 | Startup splash observed; accessibility query timed out. Skill settings/invocation unverified. |

Current primary docs support [Claude personal symlink discovery](https://code.claude.com/docs/en/skills),
[Codex shared user skills and symlinks](https://developers.openai.com/codex/skills/),
[Antigravity's global config/skills root](https://antigravity.google/docs/skills), and
[ZCode user-level skills, refresh and symlink import](https://zcode.z.ai/en/docs/skill).
Documentation is not a substitute for the explicitly missing UI checks above.
Existing Codex compatibility entries were aligned to the same durable payloads;
distribution defaults still configure only the shared root, not duplicate roots.

Observed safety/portability findings:

- Strict intake refused consult's tracked absolute recursive child link. The task
  branch removes that artifact; consult was copied from the repaired local source.
  The maintained clone was not edited.
- SWE's original description measured 1,158 characters, exceeding ZCode's documented
  1,024-character discovery limit. Its source frontmatter was shortened (body intact),
  then the deployed copy was updated using the normal verified backup transaction.
- Workhorse's maintained source changed during alpha. Normal migration refused the
  stale digest. A previewed update refreshed the copy with a verified archive before
  the remaining matching source links were migrated.
- Local `backups/swe-2026-09-07.zip` and `backups/workhorse-2026-09-07.zip` were produced
  and verified by intake. Prior staging is retained. Private archive contents are not
  public evidence artifacts.
- Runtime requirements for relay, consult, marathon, daily, workhorse and start-task
  are recorded in the local catalog. From a neutral CWD the copied relay locator
  resolved the maintained harness using explicit XYZ_HARNESS, and copied merge-cleanup
  displayed its real CLI help. These are bounded read-only runtime checks, not a full
  exercise of those workflows or their transitive dependencies.

Pending operator choice: Claude's swe/recon/debug-mantra point to a different local
skill repository; daily points to a distinct RebalanceOS Claude-specific source.
No ownership was claimed and none was overwritten. Sync correctly returns exit 2
with those four conflicts while preserving successful independent targets. No
all-consumer deployment success is claimed. Conversational fixture execution and
final app invocation remain explicit gaps, not inferred from file placement.
