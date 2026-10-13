"""task-sync adapters — one module per IDE's task store.

Adapters own only their app's store I/O and implement the contract:
``doctor()``, ``sweep(...)``, ``set_title(task_id, description)``. They
raise ``core.AdapterError`` (never proceed) on a failed safety check —
a failed or empty-authoritative read never triggers a destructive write.
"""
