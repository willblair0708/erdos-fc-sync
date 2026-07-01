#!/usr/bin/env bash
# Red-path test for the vela-check gate: flip ONE byte inside one signed event
# in a throwaway clone of this repo and assert the gate goes red. This is the
# local stand-in for "the Action fails on a tampered event log" — the property
# that makes a green check mean something.
#
# Usage:
#   scripts/ci-red-test.sh
#   VELA=/path/to/vela scripts/ci-red-test.sh   # override the binary
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VELA="${VELA:-vela}"
command -v "$VELA" >/dev/null 2>&1 || {
  echo "FAIL: vela binary not found (set VELA=/path/to/vela)" >&2
  exit 1
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone -q "$REPO" "$TMP/repo"
cd "$TMP/repo"

# Baseline: the untampered clone must replay cleanly. (Non-strict: strict has
# known owner key-custody debt and is a separate, non-blocking signal in CI.)
if ! "$VELA" check . >/dev/null 2>&1; then
  echo "FAIL: baseline 'vela check .' is already red on an untampered clone — fix the frontier before trusting this test" >&2
  exit 1
fi

# Tamper: flip one byte inside the payload of one signed event.
ev="$(find .vela/events -name '*.json' -type f | sort | head -n 1)"
[ -n "$ev" ] || { echo "FAIL: no event files under .vela/events/" >&2; exit 1; }
python3 - "$ev" <<'PY'
import sys
path = sys.argv[1]
b = open(path, "rb").read()
i = max(b.find(b'"payload"'), 0)
while i < len(b) and not b[i:i+1].isdigit():
    i += 1
if i >= len(b):
    sys.exit("FAIL: no digit found to flip in " + path)
old = b[i:i+1]
new = b"3" if old != b"3" else b"7"
open(path, "wb").write(b[:i] + new + b[i+1:])
print(f"tampered {path}: offset {i}, {old.decode()} -> {new.decode()}")
PY

# The gate must go red — strict AND non-strict.
if "$VELA" check . --strict >/dev/null 2>&1; then
  echo "FAIL: 'vela check . --strict' passed on a tampered event log" >&2
  exit 1
fi
if "$VELA" check . >/dev/null 2>&1; then
  echo "FAIL: 'vela check .' passed on a tampered event log" >&2
  exit 1
fi

echo "OK: one flipped byte in $ev turns the gate red (strict and non-strict)"
