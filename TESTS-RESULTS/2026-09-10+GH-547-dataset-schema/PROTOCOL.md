# GH-547 external dataset schema probe

## Purpose

Test whether NLBSE '23, TAWOS 1.1, and one verified SWE-Gym trajectory dataset expose the fields, split keys, licenses, and bounded access needed for the next ModernBERT experiments. This phase performs no training and does not download TAWOS's 638 MB archive or NLBSE's 514 MB training archive.

## Frozen candidates

- NLBSE '23 issue report classification, GitHub repository `nlbse2023/issue-report-classification`, test archive only for bounded schema sampling.
- TAWOS 1.1, Figshare article `21308124`, public schema plus archive metadata only.
- SWE-Gym `MoatlessTools-Agent-Verifier-Train-Data`, pinned Hugging Face revision `57a05d234f92268307d6db677094e0b33d62c15e`.

### Recorded amendment after the first successful probe

The pinned verifier dataset proved to contain short patch-generation conversations rather than chronological tool trajectories. Keep that negative result and add `SWE-Gym/OpenHands-Sampled-Trajectories`, pinned at `baf3a4e4bff514d48ddc08a93a2ade5c126212c7`, as the actual bounded trajectory schema probe. The preferred Moatless sampled trajectories are packaged as 5.52 GB of ZIP files and are not exposed through the dataset server, so they remain outside this bounded phase.

## Method

1. Fetch authoritative repository, dataset-server, and archive metadata.
2. Download only the 56.96 MB NLBSE test archive into a temporary directory; inspect its header, row count, label distribution, and five sample shapes.
3. Query the Hugging Face dataset server for SWE-Gym schema, split counts, and bounded first rows. Retain field names, types, message-role sequences, lengths, and SHA-256 digests, but no raw prompt text.
4. Parse TAWOS's public SQL schema and Figshare metadata. Record that representative data rows remain untested because they require the 637.55 MB full archive.
5. Emit `results.json`, `runtime.log`, and `provenance.jsonl`. Public artifacts must not contain issue bodies, trajectory messages, usernames, or repository-specific sample identifiers.

## Decision gate

A source passes the schema gate only when its actual fields and grouping keys support the intended task and its data-use terms are identified. An unclear dataset license, missing chronology, or unavailable bounded sample is recorded as an unresolved gate rather than inferred away.
