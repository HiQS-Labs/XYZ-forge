# Reconstruct retained inventory snapshots

Decompress inventories.sanitized.json.gz as JSON. Iterate snapshots in recorded order.
Initialize state with the first baseline object. For each later snapshot, for each
area delete the paths in remove and update with entries in set. Copy state to retain
that snapshot. JSON serialize each state with sorted keys and separators (comma,colon),
no trailing newline, then SHA-256: it must equal the recorded canonical_sha256.

All 16 reconstructed objects were compared equal to the full sanitized originals
before publication. This is lossless representation of parsed inventory observations,
not truncation or selected-path filtering. Original raw files and byte hashes remain
retained locally; the published raw-evidence manifest binds their original formatting.
No candidate command is needed to inspect or reconstruct this evidence.
