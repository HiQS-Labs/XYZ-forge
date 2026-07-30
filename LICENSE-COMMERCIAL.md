# Commercial License

XYZ is dual-licensed. This file describes the second option. Most users need
only the first.

## Which license applies to you

**The AGPL-3.0-only license in [`LICENSE`](./LICENSE) applies by default, and it is
almost certainly all you need.** It costs nothing and it is a real open-source
license — you may use, study, modify, self-host, and redistribute XYZ.

You do **not** need a commercial license to:

- Run XYZ internally for your own team, however large.
- Modify it for your own internal use.
- Vendor it into your own repositories (`xyz-vendor.sh`), including private ones.
- Redistribute it or a fork, provided you do so under the AGPL and supply source.

You may want a commercial license if:

- You want to **offer XYZ (or a modified XYZ) to third parties over a network** —
  as a hosted product, a managed service, or an agent-orchestration feature inside
  one — **without publishing your modifications.**
- You want to **embed XYZ in a proprietary product** you distribute, and you cannot
  license that product under the AGPL.
- Your organization's policy prohibits AGPL-licensed code in the deployed stack,
  regardless of how you actually use it. (This is common, and it is a legitimate
  reason to ask.)

## What the AGPL actually requires

The obligation people most often miss is **section 13, "Remote Network
Interaction"**. Plain-language summary — the binding text is in [`LICENSE`](./LICENSE):

> If you modify XYZ and let users interact with your modified version remotely over
> a network, you must prominently offer those users the complete corresponding
> source of your version, at no charge, from a network server.

Two things follow from that. Merely *using* XYZ over a network, unmodified, triggers
nothing extra. And "modify" is broader than a fork — patches, custom turn-taker
shims, changed relay or gate behavior, and a vendored `.xyz/` copy you have edited
all count. If your service is built on a changed XYZ, section 13 reaches it.

Section 5 also applies to conveyed copies: modified versions carry prominent change
notices and must be licensed as a whole under the AGPL.

**A note specific to how XYZ is used.** XYZ is a developer tool that runs on a
machine and coordinates coding agents against a repository. Running it as part of
your own development workflow — however many people are on the team, and whether or
not you have modified it — is internal use, and section 13 does not reach it. The
network-interaction clause is about letting *third parties* reach a modified XYZ
remotely, which is a different thing from your team using it to build software.

## What a commercial license grants

Relief from the AGPL's reciprocal obligations — principally the section 13
network-source requirement and the requirement to license derivative works under the
AGPL — so you can keep your modifications and surrounding product closed.

It does **not** grant trademark rights to "XYZ" or "Neochrome", and it does not
change the licensing of the third-party dependencies XYZ incorporates. XYZ's runtime
dependencies are deliberately minimal — Node and Python standard libraries, plus
`acorn`/`acorn-walk` (MIT) for one static-analysis utility — and it shells out to
whichever agent CLIs you have installed, which carry their own separate terms that
this license does not affect.

## How to get one

**Terms are negotiated, not click-through.** There is no self-serve purchase flow,
no price list in this repository, and nothing here is an offer or a binding quote.

Email **support@neochro.me** with the subject line **"Commercial license — XYZ"**.
It helps to include:

- Your organization, and how you intend to deploy XYZ.
- Whether you will modify it, and whether third parties will reach it over a network.
- Whether you need redistribution rights, hosting rights, or both.

## Contributions

Because Neochrome offers commercial licenses, it must hold sufficient rights in all
contributed code to grant them — a contribution accepted under the AGPL alone could
not be included in a commercially licensed build.

**There is no `CONTRIBUTING.md` in this repository yet, so the inbound terms that
make the dual license work are not written down.** Until they are, XYZ cannot accept
an outside contribution without resolving this first: the intended terms are that
contributors keep their copyright and license their work under the AGPL like everyone
else, and additionally grant Neochrome the right to include it under other license
terms — nothing is assigned away — but an intention is not an agreement. If you want
to contribute, say so and the terms will be settled explicitly before any code is
merged. This is a known gap, tracked in the repository's issues, not an oversight
being quietly relied upon.

---

This document is a plain-language summary offered for orientation. It is not legal
advice, and where it differs from the text of [`LICENSE`](./LICENSE) or a signed
commercial agreement, those control.

Copyright (c) 2026 Neochrome. All rights reserved.
