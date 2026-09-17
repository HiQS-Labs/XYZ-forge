"""Bounded public-path check for the GH-606 authored docs; no runtime integration."""
import re
import sys
from pathlib import Path

pattern = re.compile(r"/(?:Users|home)/[^/\s]+/|[A-Za-z]:\\Users\\|gh[pousr]_[A-Za-z0-9]{20,}")
failed = False
for arg in sys.argv[1:]:
    data = Path(arg).read_text()
    if not data.strip():
        print(f"FAIL: empty input: {arg}")
        failed = True
    elif pattern.search(data):
        print(f"FAIL: personal path or token-shaped literal: {arg}")
        failed = True
    else:
        print(f"PASS: {arg}")
if len(sys.argv) < 2:
    print("FAIL: no input paths")
    failed = True
raise SystemExit(1 if failed else 0)
