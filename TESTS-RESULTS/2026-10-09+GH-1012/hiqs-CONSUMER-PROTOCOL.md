# Offline consumer protocol (v1 and v2)

`resolve-request` reads one JSON request from stdin and prints one JSON response.
It performs no network access, reads no credentials, and grants no execution permission.
The existing `resolve` command and resolver core retain their previous semantics.

From any working directory, use an installed checkout with an explicit tsconfig:

```bash
HIQS_CHECKOUT="/absolute/path/to/hiqs-ai-resolve"
node "$HIQS_CHECKOUT/node_modules/tsx/dist/cli.mjs" \
  --tsconfig "$HIQS_CHECKOUT/tsconfig.json" \
  "$HIQS_CHECKOUT/cli/index.ts" resolve-request < request.json
```

This is checkout-based distribution, not a published npm package. Install the checkout's
dependencies first. Input is limited to 1 MiB (UTF-8 bytes); callers must close stdin and
own the process deadline. No flags or positional parameters are accepted by this command.

The generated `schemas/consumer-request.schema.json` defines the request:

- `protocolVersion`: `"1"`.
- `snapshot`: the complete existing SnapshotEnvelope.
- `input`: existing ResolveInput with nonblank query, full materialized policy, harness
  reference and UTC `asOf`. Query bytes are preserved; whitespace-only values refuse.
  Preset names are not accepted. Context must be non-secret.
- `snapshotPolicy`: independently obtained `digest`, expected `registryId`, explicit
  `allowedTrustStatuses` and integer `maxAgeMs`. No defaults, fetching or cache are provided.

Do not compute an expected digest from an untrusted downloaded payload and call that
authentication. Pin it through the caller's trusted distribution policy. The `signed`
label is data; this boundary does not verify signatures. Fixture/imported snapshots
are accepted only if the caller explicitly permits those statuses.

Success returns `status: resolved`, the unchanged core `result` (including digests and
trace), and `descriptor: { trust: "untrusted", binding: ... }`. The binding carries the
exact endpoint, transport and request identifier from the pinned snapshot. Do not execute
these values or treat arbitrary adapterConfig keys as trusted configuration. A future
invoking client needs endpoint/config allowlists, credentials, session approval and limits.

Refusals return `status: refused` and a stable gate `code`; if the core ran, `result`
is retained for explanation. The outer status always governs readiness—even an inner
resolved core result can be refused for incomplete route evidence. Ambiguous aliases
refuse before core ranking, so the IDE must ask rather than silently substitute.

Exit codes: 0 descriptor returned; 2 route/trust refusal; 3 invalid/oversized input.
Errors do not echo malformed input. Valid results may contain public catalog data and
core traces; callers should not put secrets or selected source code in this request.

This is only the shared offline boundary for GH-4. It does not establish live route
publication readiness or implement the daily/Forge invoking clients (GH-3 / Forge GH-579).


## Exact recipe requests (protocol 2)

`schemas/consumer-request-v2.schema.json` adds `executionConfig` (a JSON object) and
requires `input.recipeRef`, an exact `recipe:namespace/id@revision`. The input still
requires explicit UTC `asOf`, materialized `policy`, and the same explicit snapshot
trust/freshness settings. Optional `query` and `harness` must equal the recipe's exact
model/harness references; aliases and padded refs conflict and refuse. Unlike protocol 1,
protocol 2 resolves a derived pinned input; omitted fields derive in-process. Unknown v2 input fields
refuse. Protocol 1 stays available, and old runners refuse protocol 2.

Core filters by the selector before ranking, excludes plain routes, and applies recipe
lifecycle/disposition, exact deny, evidence, expiry, dependency and policy gates. No
substitute recipe is selected. The boundary compares `digestOf(executionConfig)` against
that recipe's `configDigest`: HiQS canonical JSON sorts object keys, preserves array
order and hashes the complete versioned object with SHA-256. Callers normalize config;
HiQS does not interpret it, discover settings, read secrets, or grant execution.

Success returns `enforcedRecipeRef`, the derived `input`, existing `result`, and `lock`.
The untrusted `descriptor` contains `binding`, typed hosted `target`, and the unchanged
`executionConfig`. `result.route.recipe.target` and the lock also retain target routing.
The lock request retains the selector. Resolver revision is now `phase1-1.2.0`; old locks
report a resolver-version mismatch. Requests without a selector retain omitted fields
and legacy nonrecipe result/trace digests; lock revision necessarily advances.

Failures include `RECIPE_INPUT_CONFLICT`, `UNSUPPORTED_RECIPE_TARGET`,
`CONFIG_DIGEST_MISMATCH`, existing core refusals and snapshot trust/freshness refusals.
Invalid snapshots return `INVALID_SNAPSHOT`. A refusal never authorizes local fallback.
Snapshot digest consistency is not authenticity; callers must supply trusted setup.
Retained-time replay does not authorize execution after evidence expiration.

XYZ's supported normalized object is `xyz.claude-advisory.v1`: explicit `model`, `effort`,
`authMode: "subscription"`, `tools` and `allowedTools` equal to `["Read","Grep","Glob"]`,
`restricted: true`, `strictMcpConfig: true`, `outputFormat: "json"`, and explicit string
`maxTurns` / `maxBudgetUsd`. Build is checked separately against `harnessBuild`.
Consumers construct only locally supported argv, reject arbitrary config keys, and
check actual native subscription authentication. Managed settings cannot be bypassed.

[The offline vector](../fixtures/synthetic/consumer-v2.json) contains a full request and
expected response using fictional fixture evidence and Claude-shaped configuration.
It is source/fixture proof only, never a publication record or live attestation.


### Schema and evidence parity

Unknown protocol-level fields and unknown v2 input fields refuse. Existing non-strict
snapshot/entity/policy objects accept and strip unknown fields before resolution and
canonical digesting; their generated schemas allow those fields. They are not execution
configuration. Strict nested recipe objects retain their explicit rejection behavior.
Selected-route evidence must reference a present claim whose subject is also present in
that snapshot. Duplicate aliases are checked with the core's whitespace normalization.
