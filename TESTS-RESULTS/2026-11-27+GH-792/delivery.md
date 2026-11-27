# GH-792 delivery evidence

`make_sandbox` resolves the source and candidate clone paths before calling
`os.makedirs`, `shutil.rmtree`, or `subprocess.run`. It raises the existing
`RuntimeError` for equality or containment in either direction. A disjoint
candidate follows the existing clone path.

The builder parsed the updated Python source and computed its blob ID in
memory. The result, `604cc8c03fa5634cf1076103c36ca27e2ac159b8`, matches the
postimage ID in the retained [symmetric fix patch](review-round2-fixes/symmetric-fix.patch).

| Retained readiness probe run | Exit | Observed result |
| --- | --- | --- |
| [Before](review-round2-fixes/base.txt) | 1 | Recorded `makedirs`, `rmtree`, and `subprocess` in that order. The overlapping source was deleted before clone failed. |
| [After](review-round2-fixes/symmetric-fix.txt) | 0 | Equal and both containment cases raised `RuntimeError` with zero recorded calls. The affected checkouts remained intact, the descendant sandbox root stayed absent, and the disjoint candidate cloned successfully. |

The runtime results above come from the retained preparation run. The builder
turn reserved runtime verification for the harness and did not rerun the
readiness probe or the campaign gate. The existing campaign gate exercises the
descendant refusal through the campaign's self-test.
