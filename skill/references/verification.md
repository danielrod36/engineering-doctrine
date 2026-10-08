# Verification — evidence before claims

**Every failure this doctrine exists to prevent has one shape: a check that was assumed
rather than read.** Either it ran and its result was inferred from something adjacent to it
(a pipeline's exit status, where a string appeared), or it never ran and the author wrote
down what they expected to be true. This file is how to make that impossible.

## The bar for a claim

A claim about the codebase ships with:

1. **the command that produced it**, and
2. **a `path:line`** for the behaviour it names.

If you did not run the check in *this* tree, at *this* commit, say so at the claim. Label
inference `[INFERENCE]` and say what would confirm it. An unverified claim made visible is
useful; the same claim passing as verified is the bug.

**A string's location is not its owner.** To justify "X is reachable from / used by / owned
by Y", resolve **X's consumers** — grep the *import* or read the route that imports the module
— not the places where X's name appears as text. A component name in an iframe says nothing
about which route serves that component.

**A comment, a docblock, a report, a plan, and a PR body are all claims** and take the same
bar as a test assertion. Replacing a false statement with an unverified one is the same defect
with different wording. When you touch a file because it contained a false statement, every
sentence you leave behind must survive the same check.

## Reading proves a mechanism *can* fail. A run proves it *does*.

When the question is "is this working", boot the thing and observe it.

- **Instrument the boundary.** If a control is silent, attach a network listener *before* the
  action and assert on the requests. A panel that rendered a placeholder because a query was
  *disabled* looks identical, in a screenshot, to one that failed — the request log names the
  cause directly.
- **Read the layer that owns the fact.** When the defect is about data that reaches the client,
  read the API payload or the database, not the DOM. `fog_enabled: true` next to
  `fog_data: []` is proof; a screenshot of an empty map is not.
- **Seed through the application's own routes** where triggers or row-level policies guard the
  table. A naive insert will fail with a confusing error, or worse, succeed and bypass the
  guard you meant to test.
- **Impersonate correctly.** Testing as a superuser bypasses row-level security entirely, so
  an assertion made as one passes vacuously. Switch to the real role/identity.
- **The empty-library blind spot:** a fixture with no rows tests no controls. Seed data before
  asserting on any surface that renders per-row.
- **Distinguish an invalid value from a valid empty/zero.** "No result", "zero", and "not
  found" are different facts; conflating them hides both bugs and correct behaviour.

## Reproduce before you fix; revert to prove the fix

- **Reproduce every finding before touching it.** If it does not reproduce, say so and drop
  it — a real fraction of reported findings are the reporter's own fixture or environment.
- **Each fix gets a test that fails without it.** Verify by reverting the fix and watching the
  test go red. A test that passes both ways pins nothing.
- **Beware the spec that always skips**, or whose selector exists only inside a mock. Check
  that it *fails* without the fix; a test that is green while asserting nothing is the same
  shape as the defect it was written to catch.
- **A test asserting the broken shape is itself a defect.** Rewrite it to the correct contract;
  never preserve it.

## Gates, and proving a gate can fail

- **Read a gate's exit status directly.** A status read through a pipe is the status of the
  last command. To shorten output, redirect to a file and read it, or use `${PIPESTATUS[0]}`.
- **Prefer a single entry point** that runs the gate and only merges on a `0` status, decided
  in-process (a script that reads the child's code and does not call the merge tool otherwise).
- **Demonstrate that the gate can fail.** Remove the thing it checks for, run it, and **quote
  the failure verbatim**. A gate you have only seen pass is a gate you have not verified — it
  may be checking nothing at all.
- **Report the failing check, never loosen it.** When a check fails, the answer is the defect
  it names, not a relaxed rule or a skip.

## Closing the loop

State **tested, untested, and blocked** explicitly. When you verify something, record against
which commit you verified it — a verification from an earlier tree is not a verification of
this one. That single habit is what separates a green board from a true one.
