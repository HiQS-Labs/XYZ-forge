# Failed wrapper campaign attempt — preserved, superseded

Run 11ab9aaf-175c-4769-b8fe-06137e58fbf3 (300 iterations, all failed): the campaign target's
Python used invalid `String_...` placeholder tokens (a shell-quoting transcription error), so
every iteration died on NameError before reaching the oracle. Disposition: not a resolver
defect — an adapter authoring error. Superseded by the corrected shlex-safe target
(../wrapper-seed11/, run 6016e964-36da-48ae-9dfd-46e67b783c41, 300/300 green). Recorded here
per the #460 loop contract: failed adapter runs are dispositioned, never silently erased.
