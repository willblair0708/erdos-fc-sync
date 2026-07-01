#!/usr/bin/env bash
# Sign a reviewed campaign batch in one pass, under YOUR key.
#
#   bash scripts/sign-batch.sh [stub-file]
#   (default stub: packets/draft-review/verdicts_stub.json)
#
# Prerequisite: you read the packets and filled each row's "verdict" in the stub
# (faithful / variant / unfaithful). This script then, for every VERDICT-FILLED
# row: creates the campaign finding (`vela finding add --apply`), fills the row's
# `target` with the vf_ id, and finally signs ALL rows in one `vela attest
# --batch` (one key read) and re-materializes the frontier.
#
# KEY CUSTODY: the attest verdicts are reserved for reviewer: actors by the
# substrate; an agent cannot run this to any effect. Rows with an empty verdict
# are refused — the judgment is yours, not defaultable.
#
# Env: VELA (default vela), REVIEWER (default reviewer:will-blair).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"
VELA="${VELA:-vela}"
REVIEWER="${REVIEWER:-reviewer:will-blair}"
STUB="${1:-packets/draft-review/verdicts_stub.json}"

[ -f "$STUB" ] || { echo "no stub at $STUB (run match_packet.py --draft first)"; exit 1; }

# refuse empty verdicts + validate values, BEFORE creating anything
python3 - "$STUB" <<'EOF'
import json, sys
rows = json.load(open(sys.argv[1]))
bad = [r["problem"] for r in rows if r.get("verdict") not in ("faithful","variant","unfaithful")]
if bad:
    sys.exit(f"unfilled/invalid verdict for problems {bad} — read the packets and "
             f"fill each \"verdict\" (faithful/variant/unfaithful) first.")
print(f"{len(rows)} rows, all verdicts filled.")
EOF

# create one finding per row, fill targets, emit the vela-shaped bare array
FINAL="packets/draft-review/verdicts_signed_input.json"
python3 - "$STUB" "$FINAL" "$VELA" "$REVIEWER" <<'EOF'
import json, re, subprocess, sys
stub, final, vela, reviewer = sys.argv[1:5]
rows = json.load(open(stub))
out = []
for r in rows:
    n = r["problem"]
    res = subprocess.run(
        [vela, "finding", "add", ".",
         "--assertion",
         f"The Formal Conjectures statement drafted for Erdős problem {n} "
         f"faithfully represents the informal problem.",
         "--type", "theoretical", "--source", "erdos-frontier campaign",
         "--author", reviewer, "--apply", "--json"],
        capture_output=True, text=True)
    m = re.search(r"vf_[0-9a-f]+", res.stdout + res.stderr)
    if not m:
        sys.exit(f"finding add failed for {n}: {res.stderr[-300:]}")
    out.append({"target": m.group(0), "verdict": r["verdict"],
                "informal_ref": r.get("informal_ref",""),
                "formal_ref": r.get("formal_ref",""),
                "formal_statement_hash": r.get("formal_statement_hash",""),
                "note": r.get("note","")})
    print(f"  {n}: finding {m.group(0)} ({r['verdict']})")
json.dump(out, open(final, "w"), indent=2)
print(f"wrote {final}")
EOF

"$VELA" attest . --batch "$FINAL" --as "$REVIEWER"
"$VELA" frontier materialize .
echo
echo "signed + materialized. next:"
echo "  git add .vela/ frontier.json frontier.yaml vela.lock proof/ && git commit -m 'Sign batch fidelity verdicts' && git push"
echo "  python scripts/submit_batch.py assemble batch-3"
