# GH-1479 stage signature inventory (generated from the AST of utils/py/swarm_preflight.py)

- record `SourceSelection` — 11 fields, frozen dataclass
- record `RepositoryState` — 22 fields, frozen dataclass
- record `CandidateEvaluation` — 24 fields, frozen dataclass
- `parse_args() -> argparse.Namespace` — 33 lines
- `resolve_source_selection(args: argparse.Namespace) -> SourceSelection` — 70 lines
- `load_contracts(source_docs: Sequence[str]) -> dict[str, Any]` — 29 lines
- `inspect_repository(selection: SourceSelection, merged: dict[str, Any]) -> RepositoryState` — 129 lines
- `evaluate_candidate(selection: SourceSelection, merged: dict[str, Any], effective_artifacts: dict[str, list[str]], index_only_unscoped: list[str], repository: RepositoryState) -> CandidateEvaluation` — 250 lines
- `normalize_candidate(selection: SourceSelection, merged: dict[str, Any], repository: RepositoryState, evaluation: CandidateEvaluation) -> dict[str, Any]` — 45 lines
- `report_candidate(args: argparse.Namespace, selection: SourceSelection, merged: dict[str, Any], repository: RepositoryState, evaluation: CandidateEvaluation, rc_obj: dict[str, Any]) -> str` — 73 lines
- `write_packet(args: argparse.Namespace, selection: SourceSelection, merged: dict[str, Any], repository: RepositoryState, evaluation: CandidateEvaluation, rc_obj: dict[str, Any], invocation: str) -> NoReturn` — 197 lines
- `main() -> None` — 11 lines

Functions: 57 (all parameters and returns annotated: True).
`locals()`/`vars()`/`globals()` calls: 0. `type: ignore`: 0. `cast(`: 0.
Pre-change `main()`: 734 lines (base 5967bde25).
