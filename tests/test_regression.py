"""Regression gate: guard against silent machine-verdict drift.

The #347 false positive was a proof the extractor read as conditional when its
boxed answer is unconditional. A change of that kind should be a reviewed act,
never a silent drift. This test pins every audited problem's machine verdict; a
diff fails the build and points at the exact change to review.

If a change is intended (a new proof, or a corrected reading like the #347 or
#997 fixes), regenerate the golden:

    python -c "import json,sys; sys.path.insert(0,'.'); \
      from erdos_frontier import load_machine_audit; \
      json.dump({str(p):r['machine_verdict'] for p,r in sorted(load_machine_audit().items())}, \
      open('tests/golden_machine_verdicts.json','w'), indent=2, sort_keys=True)"
"""
import json
from pathlib import Path

from erdos_frontier import load_machine_audit

GOLDEN = Path(__file__).parent / "golden_machine_verdicts.json"


def test_no_machine_verdict_drift():
    golden = json.loads(GOLDEN.read_text())
    current = {str(p): rec["machine_verdict"] for p, rec in load_machine_audit().items()}

    flipped = {p: f"{golden[p]} -> {current[p]}"
               for p in set(golden) & set(current) if golden[p] != current[p]}
    added = sorted(set(current) - set(golden), key=int)
    removed = sorted(set(golden) - set(current), key=int)

    problems = []
    if flipped:
        problems.append(f"verdict flips (review each): {flipped}")
    if added:
        problems.append(f"newly audited (add to golden): {added}")
    if removed:
        problems.append(f"no longer audited: {removed}")

    assert not problems, (
        "Machine verdicts drifted from tests/golden_machine_verdicts.json. Each change "
        "must be a reviewed act, not silent drift. If intended, regenerate the golden "
        "(see the module docstring). " + " | ".join(problems))
