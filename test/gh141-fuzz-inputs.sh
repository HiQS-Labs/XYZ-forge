#!/usr/bin/env bash
# GH-141: fuzz_inputs.py integration test
set -e

# Setup sandbox
# SCRATCH DISCIPLINE: must be under $TMPDIR or .relay-scratch/
SCRATCH="${TMPDIR:-/tmp}/gh141-fuzz-$$"
mkdir -p "$SCRATCH"
trap 'rm -rf "$SCRATCH"' EXIT

# Defective script (rejects unknown flag)
cat << 'INNEREOF' > "$SCRATCH/defective.sh"
#!/usr/bin/env bash
for arg in "$@"; do
  if [ "$arg" = "--unknown" ]; then
    echo "Unknown argument!" >&2
    exit 1
  fi
done
exit 0
INNEREOF
chmod +x "$SCRATCH/defective.sh"

# Patched script (allows unknown flag)
cat << 'INNEREOF' > "$SCRATCH/patched.sh"
#!/usr/bin/env bash
for arg in "$@"; do
  if [ "$arg" = "--unknown" ]; then
    # Allowed
    :
  fi
done
exit 0
INNEREOF
chmod +x "$SCRATCH/patched.sh"

export PYTHONPATH="$(pwd):$PYTHONPATH"

# Positive regression control
if ! python3 utils/py/fuzz_inputs.py --seed 123 --iterations 50 --target argv -- "$SCRATCH/defective.sh" > "$SCRATCH/out.json"; then
  # Expected to fail (exit 1) and output json
  if ! grep -q '"target": "argv"' "$SCRATCH/out.json"; then
    echo "Failed to find argv defect" >&2
    exit 1
  fi
  if ! grep -q '"--unknown"' "$SCRATCH/out.json"; then
    echo "Failed to shrink to --unknown" >&2
    exit 1
  fi
else
  echo "Positive control failed, fuzz_inputs.py returned 0 on defective script" >&2
  exit 1
fi

# Negative control
if ! python3 utils/py/fuzz_inputs.py --seed 123 --iterations 50 --target argv -- "$SCRATCH/patched.sh" > "$SCRATCH/out.json"; then
  echo "Negative control failed, fuzz_inputs.py returned non-zero on patched script" >&2
  cat "$SCRATCH/out.json" >&2
  exit 1
fi

echo "GH-141 fuzz_inputs.py tests passed."
exit 0
