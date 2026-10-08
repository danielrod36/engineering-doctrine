# Harness — omp

Crash, checkpoint, and coordination mechanics for the omp agent runtime,
written from its own runtime documentation — verify against your version. The
portable rules live in [`../delegation.md`](../delegation.md).

## Lanes are separate kernels, still mortal

- **Subagents spawn via the task tool with their own kernels** and start
  blank: a brief that omits a requirement omits it entirely.
- **The parent kernel survives context compaction**, so lanes outlive the
  parent losing history — but a host suspend or reboot kills parent and lanes
  together. The only thing that survives any interruption is **what was
  written to files, branches, and worktrees**. Same rule as everywhere: commit
  inside lanes; after an interruption, read what is on disk before restarting.
- Background jobs and services (`proc://`) die with the kernel too. Long-lived
  services need unique names and an explicit lifecycle decision.

## Coordination

- **A named lane is addressable at `agent://<id>`**: write to it to steer or
  message mid-flight, `agent://all` to broadcast. Siblings coordinate through
  these writes, not through the parent relaying every exchange.
- **Fan independent waves with a workpool** rather than serializing lanes; if
  you are blocked with nothing else to do, wait on the barrier — results
  auto-deliver, so do not poll for them.
- **A lane's status and report are claims.** Verify the artifact: the commit
  exists, the test fails without the fix, the gate is green on the current tree.
