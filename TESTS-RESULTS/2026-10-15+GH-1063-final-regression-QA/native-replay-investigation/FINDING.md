# Unattributed native manual replay failure

At actual final implementation5c46c49b, the first unmodified recorded native48 replay exited1 at `failed ignored enumeration preserves`, after14.6s. It asserted exact disposition PRESERVE_UNVERIFIED_QUERY but did not log the actual returned object. Its raw traceback and FAIL receipt remain in the parent QA evidence; clone identity was unchanged. No real existing checkout was targeted.

One bounded instrumented replay and one confirmation both passed all48 original predicates. The only input change wraps the existing inspect helper to log its actual result; no assertion, runtime, CI test/case or suite changed. Captured injected query-failure and warning results are PRESERVE_UNVERIFIED_QUERY with complete session evidence. Runtime/policy bytes still match the reviewed source.

The initial trigger is not established. A passing retry does not prove a harmless flake, and no claim is made that its actual return was the same as the later runs. Source has earlier protected/session/dirty preservation returns before query-failure classification; those make exact-reason observations sensitive to independent preservation evidence, but this is a hypothesis for the original event, not observed attribution. No unsafe admission or data loss was observed. No runtime fix or extra formal PR1061 review/cap reset is proposed.

Concrete observability defect: the old assertion discarded the result it graded. The retained instrumented input logs each full result before grading, preserving identical predicates for a future recurrence. The original event remains an unchecked finding in GH1063. Stop broad reruns after these two confirmation attempts; retain the uncertainty and the independent full-suite result.
