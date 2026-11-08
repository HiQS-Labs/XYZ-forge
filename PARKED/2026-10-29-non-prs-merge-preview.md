# Non-PRS merge preview observation

During CLIO #23 publication, the generic cleanup preview reached `ledger_merge.py:651` and required `releases.sql` plus `utils/py/releases_app.py` in standalone CLIO, which has neither system. It reported “releases.sql is missing at HEAD” and missing-CLI exits. The native publication contract and six existing suites, publisher red/green check, complete byte/mode parity and independent QA passed; a clean main checkout and pinned-head native GitHub merge completed the authorized publication. No helper gate or repository setting changed.

Non-PRS support in the generic helper needs triage before recommending it for another standalone publication. This is outside the CLIO capture repair; no ledger onboarding or gate change is proposed here. Sanitized incident/disposition: TESTS-RESULTS/2026-10-29+GH-1255/DEVICE-DEPLOYMENT.md.
