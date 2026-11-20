# GH-1506 verification

Implementation tested: a71663d5. Plan approved by Claude round 2 at 65a26cc3; source change is diagnostic output only.

- Model-free component controls passed twice: harmless lock-named open file now reports observation without contention; log-only mtime activity retains its legacy reason code but explicitly denies useful-progress/budget inference; static dirty-file count remains state. Baseline records preserved.
- All six focused existing suites exited 0: GH114 headless TTY, GH370 telemetry, GH390 timeout attribution, GH492 idle kill, GH648 termination, GH505 relay attestation. Their raw logs are retained.
- Main/adjacent smoke: GH114 drives actual Agy shim with a stub CLI through successful PTY behavior and pipe-mode idle timeout exit 7; GH390 drives existing timeout attribution controls; GH492 retains no-sample, disable-idle and activity controls. No live inference used by these fixtures.
- Runtime ASTs match pre-change fc54f9ce after string constants are normalized. Inspected diff confirms changed strings are messages/docstrings, not predicates or command arguments. Limits, classifier order, sampling, idle_seconds and process cleanup remain unchanged.
- Full-clone identity before/after is identical. No source tests in primary or valued task clone.
- Frontmatter/status-table checks passed. Final independent QA and full classified gate remain pending.

Limits: component probes use controlled CPU samples and explicit mtime advancement; not a performance benchmark or proof of actual lock ownership. Legacy reason value is retained deliberately; consumers must use qualified detail, not infer useful progress from its historical name. No change to whether log activity resets the idle clock. No live-provider qualification.

Lessons: NO_ENTRY.
