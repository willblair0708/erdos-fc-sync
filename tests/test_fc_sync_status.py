import json

from fc_sync_status import (
    Claim,
    build_proofs,
    build_status,
    render_next_batch_md,
    render_status_md,
)


def erdos_records(*problems):
    return {
        problem: {
            "number": problem,
            "status": {"state": "solved"},
            "formalized": {"state": "yes"},
        }
        for problem in problems
    }


def complete_plby_proofs(*problems):
    return build_proofs([{"key": f"Erdos{problem}"} for problem in problems], [], {})


def status_for(problem, *, proof=None, fc=None, claims=None, override=None):
    payload = build_status(
        erdos=erdos_records(problem),
        fc={problem: fc} if fc else {},
        proofs={problem: proof} if proof else {},
        claims_by_problem={problem: claims} if claims else {},
        claims_available=True,
        overrides={problem: override} if override else {},
        generated_at="2026-06-29",
    )
    return payload, payload["rows"][0]


def test_plby_conditional_key_presence_counts_even_when_value_is_null():
    proofs = build_proofs([{"key": "Erdos1148", "conditional": None}], [], {})

    proof = proofs[1148]
    assert proof["complete"] is False
    assert proof["conditional"] is True
    assert proof["sources"]["plby"]["state"] == "conditional"


def test_jayyhk_complete_axiomatic_and_trust_extended_states():
    proofs = build_proofs(
        [],
        [
            {"number": 1, "proof": {"state": "complete"}},
            {"number": 2, "proof": {"state": "axiomatic"}},
            {"number": 3, "proof": {"state": "trust_extended"}},
        ],
        {},
    )

    assert proofs[1]["complete"] is True
    assert proofs[1]["conditional"] is False
    assert proofs[2]["complete"] is False
    assert proofs[2]["conditional"] is True
    assert proofs[3]["complete"] is False
    assert proofs[3]["conditional"] is True


def test_complete_proof_plus_open_pr_becomes_in_pr_with_claim_details():
    proof = complete_plby_proofs(199)[199]
    claim = Claim(number=4343, title="Erdos batch", url="https://example.test/pr/4343", head_ref="batch")

    _, row = status_for(199, proof=proof, claims=[claim])

    assert row["bucket"] == "in-pr"
    assert row["claims"] == [
        {
            "number": 4343,
            "title": "Erdos batch",
            "url": "https://example.test/pr/4343",
            "head_ref": "batch",
        }
    ]


def test_mismatch_override_beats_actionable_statement():
    proof = complete_plby_proofs(214)[214]

    _, row = status_for(
        214,
        proof=proof,
        override={"bucket": "mismatch", "reason": "quantifier mismatch"},
    )

    assert row["bucket"] == "mismatch"
    assert row["override"]["reason"] == "quantifier mismatch"


def test_hypothesis_conditional_override_prevents_statement_bucket():
    proof = complete_plby_proofs(1148)[1148]

    _, row = status_for(
        1148,
        proof=proof,
        override={"bucket": "hypothesis-conditional", "reason": "extra theorem hypothesis"},
    )

    assert row["bucket"] == "hypothesis-conditional"


def test_330_override_prevents_unsafe_link_bucket():
    proof = complete_plby_proofs(330)[330]
    fc = {
        "has_file": True,
        "linked": False,
        "path": "FormalConjectures/ErdosProblems/330.lean",
        "formal_proof_link": None,
    }

    _, row = status_for(
        330,
        proof=proof,
        fc=fc,
        override={"bucket": "needs-statement-update", "reason": "answer still open"},
    )

    assert row["bucket"] == "needs-statement-update"


def test_status_json_shape_and_rendered_artifacts_are_useful():
    proofs = complete_plby_proofs(24, 214)
    payload = build_status(
        erdos=erdos_records(24, 214),
        fc={},
        proofs=proofs,
        claims_by_problem={},
        claims_available=True,
        overrides={214: {"bucket": "mismatch", "reason": "not the boxed statement"}},
        generated_at="2026-06-29",
    )

    encoded = json.dumps(payload)
    decoded = json.loads(encoded)
    assert decoded["counts"]["statement"] == 1
    assert decoded["counts"]["mismatch"] == 1
    assert {row["problem"]: row["bucket"] for row in decoded["rows"]} == {
        24: "statement",
        214: "mismatch",
    }

    status_md = render_status_md(payload)
    next_batch_md = render_next_batch_md(payload, top_count=20, batch_size=8)
    assert "## `mismatch`" in status_md
    assert "Problem 24" in next_batch_md
    assert "ErdosProblems/24" in next_batch_md
    assert "Problem 214" not in next_batch_md
