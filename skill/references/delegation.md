# Delegation — slicing, parallel lanes, convergence

Delegation multiplies throughput only when each lane is genuinely independent and each lane's
result is verifiable. The failure modes are shared: lanes that touch the same files destroy
each other's work, lanes given vague briefs produce plausible work that cannot be checked, and
lane results are *claims* until proven.

Crash, checkpoint, and channel mechanics differ per agent harness; the portable rules below
apply everywhere, and [`harness/`](harness/) carries the per-harness specifics. Read the file
for the harness you are running in before fanning out.

## Before spawning

1. **Map the slices and the shared contract.** Name every file, symbol, and interface each
   slice touches. Two slices that edit the same file are not independent — merge them into one
   lane, or sequence them.
2. **Never outsource the top-level plan.** You may delegate a slice's *design* or a set of
   competing approaches, but the overall decomposition is yours. A subagent that re-plans the
   whole job will produce a different job.
3. **Fan independent slices in one batch.** Do not serialize work that has no dependency on
   other work. Do not spawn a lane and then sit idle; if you have nothing to do while it runs,
   that is the moment to do a read-only reconnaissance pass yourself.

## Writing a brief

The subagent **starts blank** — it has none of your conversation. A brief that omits a
requirement omits it entirely.

- **Context:** the goal, the shared contract, the interfaces other lanes rely on. Give this
  identically to every lane; do not repeat it per-lane with drift.
- **Task:** the exact target (files, symbols, non-goals), the steps or change wanted, and the
  **observable acceptance** — how the agent knows it is done.
- **State the open space honestly.** Say how open the problem is: if the fix is given, say so;
  if several designs are plausible, say which. A vague "improve this" invites the agent to
  solve a different problem.
- **Self-contained, never sibling-referencing.** Do not tell a lane what its siblings are doing;
  give it what it needs to succeed alone.

## Working rules

- **One writer per file/module/worktree.** Never let two lanes edit the same tree; appoint a
  single integration owner for shared edits.
- **Checkpoint and recovery semantics are harness-specific.** Read the harness file that
  matches the agent you run in — [`harness/claude-code.md`](harness/claude-code.md) or
  [`harness/omp.md`](harness/omp.md). If yours is not there, the portable rule still holds:
  only work written to files, branches, and worktrees survives an interruption, so commit
  inside lanes, and inspect what is on disk before restarting a killed one.
- **Skip the full build/lint/test inside each lane.** Run it **once** after integration. Per-
  edit full gates burn the time the fan-out was meant to save.
- **Verify lane output; do not trust the report.** A lane reporting "done" or "proven" is a
  hypothesis. Check the artifact: the commit exists, the test fails without the fix, the gate
  is green *on the current tree*.

## Convergence

- **Use two independent reviewers** where the change is consequential: they find different
  things, and disagreement between them localizes the uncertain parts.
- **Converge findings into fix commits, not into an argument.** A review finding is either
  reproduced and fixed, or refuted with evidence. "Won't fix" without a reproduced reason is
  how a defect reaches production wearing a resolved thread.
- **Resolve every thread by fixing the thing it names**, then merge — and only through the
  repo's merge gate. A resolved review bot is not a green board if the gate cannot see it.
- **Do not re-audit work you have already applied.** Repeatedly re-running checks on an
  unchanged tree is not diligence; it is a way to avoid the next real step.
