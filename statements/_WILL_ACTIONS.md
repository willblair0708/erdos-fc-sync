# Will's queue — campaign actions only you can take

## 1. Unblock #4345 (batch-2b: 31, 34, 47, 280) — 2 minutes

Smetalo asked "Does this resolve #469?" and it's sitting unanswered, which may
be why the PR has no review yet. #469 is an open request for problem 280, and
the PR adds `280.lean`.

Reply on https://github.com/google-deepmind/formal-conjectures/pull/4345:

> Yes — this adds `FormalConjectures/ErdosProblems/280.lean`, which is what
> #469 asks for. I've added "Closes #469" to the PR description so it links.

Then edit the PR body and append:

> Closes #469

## 2. Claim batch-3 on the umbrella issue — 1 minute

Comment on https://github.com/google-deepmind/formal-conjectures/issues/3998:

> Working on statements for Erdős problems 24, 93, 164, 314, 315, 333, 369,
> 401, 429, 435 (same conventions as #4319/#4343/#4345). Will open the PR once
> they're reviewed on my side.

## 3. The batch-3 fidelity session (packets are ready)

1. Read `packets/draft-review/erdos_<n>.md` for each of the ten (the draft is
   inlined; judge it against the verbatim problem text). Review-critical:
   369 (formalizes the non-trivial variant — the literal text is trivially
   true), 164 (the `2 ≤ a` floor), 315 (follows the text over a plby/jayyhk
   disagreement), 435 (bare IsGreatest proposition).
2. Fill each `"verdict"` in `packets/draft-review/verdicts_stub.json`
   (faithful / variant / unfaithful — leave nothing empty; targets are
   filled for you).
3. One command signs everything (creates the findings, fills targets, one
   key read, re-materializes):
   `bash scripts/sign-batch.sh`
4. Commit the signed state, then assemble:
   `git add .vela/ frontier.json frontier.yaml vela.lock proof/ && git commit -m 'Sign batch-3 fidelity verdicts' && git push`
   `python scripts/submit_batch.py assemble batch-3`
   …and run its three printed commands (commit, push, `gh pr create`).
