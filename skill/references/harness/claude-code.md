# Harness — Claude Code

Crash, checkpoint, and coordination mechanics for Claude Code. The portable
rules live in [`../delegation.md`](../delegation.md); this file adds what is
true of this harness.

## Lanes are in-process and mortal

- **Subagents spawned with the Task tool run inside the parent session's
  process.** A crash, an OOM kill, a timeout, or a machine restart stops every
  lane at once. The only thing that survives is **what was written to files,
  branches, and worktrees**.
- Therefore: give each lane its own branch or worktree from the start, and
  **commit inside the lane early and often**. A killed lane's work is
  recoverable only if it is on disk in a commit.
- **After any interruption, inspect the branches and worktrees before
  restarting.** A killed lane usually leaves captures, drafts, and partial
  commits behind; redoing the work from scratch may cost a long replay. Read
  what is already on disk and continue from there.

## Coordination

- **There is no live message channel between lanes.** Cross-lane coordination
  happens through the plan on disk and through a single integration owner for
  shared files — do not design a workflow that requires two lanes to talk
  mid-flight.
- **A lane's final report is a claim.** Verify the artifact: the commit exists,
  the test fails without the fix, the gate is green on the current tree.
