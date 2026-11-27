# GH-792: dispositions for preparation review round 2 (Codex)

- **F1 (descendant arm unchecked for mutation): fixed.** Case 3, `make_sandbox(host, <host>/inside)`, now records `makedirs`/`rmtree`/`subprocess` calls. It requires zero calls and `<host>/inside` never created. `matrix.txt` (each variant applied to `utils/py/gen4_campaign.py` in this checkout, then reverted; patches beside it):

  | Variant | Probe exit | Failing arm |
  |---|---|---|
  | base | 1 | equality (source deleted) |
  | symmetric fix | 0 | none |
  | forward-only check moved early | 1 | reverse containment |
  | equality + reverse early, old forward check left after clone (reviewer's fake) | 1 | descendant (`mutation calls=['makedirs', 'subprocess']`, `host/inside` created) |

- **Nit (stale wording): fixed.** The #1626 capture's observed line now describes the one-PR probe. Both SUMMARY notes now say that a fix without `delivery.md` reads AMBIGUOUS (exit 7), not STALE (see `probe-proof-r2/2b-*`).
