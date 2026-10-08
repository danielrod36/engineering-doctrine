# Environment — probe the machine, do not assume it

The machine is part of the system, and it is the part that rots fastest. **Anything platform
specific belongs in the repository's profile, discovered by Reconcile — never in this file as
an instruction.** What is portable is the *habit*: when an answer depends on the machine, go
and look at the machine, and treat a remembered fact about it as a hypothesis.

## What to probe, and how to probe it portably

- **Runtimes and package managers.** Read the repository's `.nvmrc`, `engines`, `.tool-versions`,
  or Dockerfile, and the lockfile. **The lockfile decides the package manager** — never assume
  one. Compare the declared version against what is actually installed; a mismatch is a
  first-class cause of "works on my machine".
- **Whether tooling is containerized.** Some setups require the test/build/CLI gate inside a
  container because the host toolchain is broken. Detect it rather than fight it: if the repo
  documents a container invocation, use exactly that; if a command fails oddly on the host but
  the repo has a container path, suspect the host toolchain.
- **Long-running services and their lifecycle.** List what is running before assuming a clean
  slate, and understand *who will clean it up*. This matters for databases, dev servers, and
  anything started by a test or a background job.
- **Auth and privilege.** Determine how the current shell authenticates and whether it can
  authenticate non-interactively. Some authentication (hardware keys, fingerprint prompts)
  **requires an interactive terminal and will hang or silently fail without one** — probe for
  it, and do not build a pipeline around a prompt that cannot be answered.
- **Filesystem and permission conventions** that differ from the norm, and any environment
  variables the shell exports that change tool behaviour.

## The reboot and interruption invariant

**A machine restart is a routine event, and it is a source of stale state:**

- **Services with a restart policy come back; services without one do not.** A resource started
  during an earlier task can survive a reboot and appear as if it is in use, when its owner is
  long gone. **List resources and confirm nothing is actually using them before removing them**
  — but do remove genuinely orphaned ones, because they accumulate silently.
- **Subagents and background jobs run in-process and do not survive.** After an interruption,
  the only thing that persists is **what was written to files, branches, and worktrees**. Inspect
  those before restarting: a killed lane usually leaves recoverable work, and re-doing it may
  cost a long rebuild.
- **Environment variables inherit into child processes.** An exported variable in the shell
  (a git dir override, a proxy, a config path) can silently redirect a tool that spawns a child
  — producing a result that is wrong but plausible. Prefer spawning children with a **scrubbed,
  explicit environment** for anything that can be redirected this way.

## Documented machine claims rot fastest

When a document or a script **describes** what the machine does — "the service restarts itself",
"the gate is enforced", "this directory is safe to delete" — that description is a claim like
any other. **Verify one cheaply** when it matters, and when it is false, fix the document rather
than working around the reality. A runbook that promises resilience the provisioner does not
install is how an outage happens during an unrelated change.

## Local development versus production

- Know where local dev data comes from and how to reset it, and whether resetting destroys
  work you need.
- Know how the repo fakes external services locally (emulators, containers, stubs) and use the
  fake for local work rather than reaching for the real thing.
- Never mutate a shared or production resource during local experimentation; if a task seems
  to require it, that is a decision to surface, not to take.
