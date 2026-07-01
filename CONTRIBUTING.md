# Contributing

There are two ways to contribute, for two kinds of work. Neither asks you to
trust the maintainer's word: everything is re-derived from a clean checkout by
the [`Verify the signed frontier`](.github/workflows/vela-frontier.yml) gate.

## 1. Contribute a proof — the audit reads it automatically

If you formalize an Erdős problem in Lean, you do not touch this repo at all. Host
the proof and the audit picks it up on its next run:

- add a `@[formal_proof using lean4 at "<url>"]` link in
  [Formal Conjectures](https://github.com/google-deepmind/formal-conjectures), or
- add it to a tracked proof index (`plby/lean-proofs`, `Jayyhk/erdos-lean`,
  `williamjblair/lean-proofs`).

The daily audit loads your proof, runs the assumption extractor
([`lean/`](lean/)), and reports mechanically whether it proves the problem
**unconditionally** or only under an axiom / an undischarged hypothesis. Your
proof appears on its [finding page](https://williamjblair.github.io/erdos-frontier/)
with that verdict, and in the load-bearing condition map if it assumes something.
No key, no review — the reading is a fact, not a judgment.

If your proof closes a problem the frozen wiki recorded as solved-but-conditional,
that discrepancy resolves on the next run.

## 2. Propose a finding to the signed frontier — fork, propose, a maintainer accepts

The `.vela/` frontier holds signed, replayable state. You do not need a key to
**propose**; you need one only to **accept**, and accepting is the maintainer's
job. Install [`vela`](https://github.com/constellate-science/vela) (`vela --version`
should print `0.720.0`), then:

```bash
# in your fork:
vela finding add . \
  --assertion "Your claim, scoped precisely." \
  --type theoretical --source "<where it comes from>" \
  --author "github:your-handle"        # NO --apply: this is a proposal, unsigned
git add .vela/ && git commit -m "Propose: <claim>" && git push
# then open a pull request.
```

On the PR, the verify gate replays the event log and confirms your proposal is
structurally valid and does **not** change the accepted state (it stays a pending
`vpr_*`, not frontier truth). A maintainer reviews it and, if it holds, accepts it
under their reviewer key:

```bash
vela accept . <vpr_id>     # emits the signed acceptance event; only then is it state
```

For a **machine proof-attestation** (a Lean kernel axiom audit), your proof repo's
CI can self-sign a `vpv_` under a `ci:` actor — that is signed *evidence*, not an
accept, and the gate still governs whether the finding reaches verified.

## The rule underneath

Git stores and transports. The proof checker checks derivations. A verifier
judges evidence. **A human key accepts the truth-bearing judgments — an agent may
propose, extract, or attest evidence, but never signs an accept.** The reducer
derives the view. If you can clone the repo and run `vela check . --strict`, you
can verify every claim here yourself.
