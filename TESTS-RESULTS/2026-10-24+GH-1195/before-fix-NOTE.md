# before-fix red control (development @ 80e67677, login env XYZ_HARNESS=primary)
Clone releases.db moved away; `bash utils/marathon-plan.sh --format json` still ran (rc=4 drift findings, not rc=3 cannot-read) and wrote its plan relative to the PRIMARY: the engine read the primary clone ledger.
