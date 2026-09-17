# PDDA Source

PDDA is the document-governance subsystem of [XYZ Forge](https://github.com/HiQS-Labs/XYZ-forge).
Canonical paths: `utils/pdda/` (runtime and distribution), `PROJECT/PDDA.md` (shared contract).
Change and review managed source in Forge; installed copies are consumers.

From a Forge checkout, install with `bash utils/pdda/pdda-install.sh /path/to/target`.
The source checkout contains that installer and `utils/pdda/pdda-sync-manifest.conf`;
ordinary installed target payloads do not. A vendored Forge checkout may include them too,
but is a pinned distribution, not a second development authority.

Historical source and issue links remain at https://github.com/Hypercart-Dev-Tools/pdda.
The migration decision is https://github.com/HiQS-Labs/XYZ-forge/issues/649.
This metadata is informational; the runtime does not read it.
