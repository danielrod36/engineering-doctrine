# Reconcile — discover the repository, then localize the doctrine

**Run this before acting in a repository you have not worked in, and re-run it when the
repository changes underneath you** (a new CI workflow, a moved gate, a switch of package
manager, a migration to a new stack). It is step 0 of the skill, not an optional nicety.

Reconcile exists because the doctrine's *principles* are portable but its *commands* are not.
A skill that tells you to run `pnpm pr:merge` in a Go repository is making a false claim about
that repository. So Reconcile reads the repository and writes down what is actually true,
into [`repo-profile.md`](repo-profile.md). Everything mechanical is then read from there.

The rule that governs the whole step: **record what you found, mark what you could not
determine `UNVERIFIED`, and never fill a field with the answer that happens to be true in
another repository.**

## What to probe, and what to record

Work through these in order. For each, run a command, look at a file, or ask — do not guess.

### 1. The repository's own rules — read these first, they win

- `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `CONTRIBUTING.md`, `docs/`, `.github/`.
- Any existing skills under `.claude/skills/`, `.agents/skills/`, `.opencode/`.
- **Record:** where the rules live, the working principle the repo states, and **every place
  this skill's advice conflicts with them**. A conflict is resolved *in the repository's
  favour* and recorded here — the skill is what adapts.

### 2. Identity, language, and layout

- Primary language(s) and framework(s); monorepo or single package.
- Where source, tests, docs, migrations, and generated artifacts live.
- Import/module conventions the repo states (barrels, boundaries, layer rules).
- **Record:** the layout map and any stated boundary rule (e.g. "server routes must not import
  client-only barrels"). Boundaries are where defects cluster; name them.

### 3. The commands that matter — the real ones, verified

Find and *run* the project's own entry points, then record the exact invocation:

- Install / bootstrap. Lockfile and package manager (`pnpm`, `npm`, `yarn`, `bun`, `uv`,
  `cargo`, `go`…). **Never assume** — the lockfile decides.
- Format, lint, type-check, unit tests, integration tests, build, coverage.
- The **single gate** that runs everything, if one exists. This is the command people are
  told to run before pushing; find it and record its exact name.
- How to run **one** test file (the fast loop) versus the full suite.
- **Record each command as `VERIFIED (ran <n> on <date>)` or `UNVERIFIED`.** Do not record a
  command you did not run as if it worked.

### 4. The gates — what actually blocks a change

This is the highest-value part of Reconcile. Find every automated check and answer:

- What runs in CI, on what trigger, and **what it does when it fails** (block, warn, comment).
- Is there a **merge gate**? What exactly does it require (status checks, review threads
  resolved, approvals)? Where is it implemented — a script, a CI job, a branch protection rule?
- Is there a **review bot** or external reviewer? How are its threads resolved and how does
  the gate see that they are?
- Is there an **audit/record validator**, a **docs-link checker**, a **schema-drift check**,
  a **migration replay check**? Record the command and what makes each one go red.
- **Record for each gate:** command, trigger, failure message shape, and **whether the gate's
  exit status is read directly or can be swallowed** (a pipe, a `|| true`, a `continue-on-error`).
  A gate that cannot fail is not a gate; if you find one, that is a finding to report now.

### 5. Branch, commit, and release conventions

- Branch naming, commit message format (conventional commits?), PR template.
- **Is the version/changelog hand-edited or tool-owned?** If a release tool owns it, record
  that the files must *not* be hand-edited, and name the tool. (A hand-edit that the tool then
  overwrites is a silent, expensive mistake.)
- Default branch name — **check it, do not assume `main`.**

### 6. Data and infrastructure

- Database(s), ORM/migration tool, and **how migrations are validated** (replayed on a
  disposable stack? linted? parity-checked against production?).
- Auth model and where authority is decided. **Record whether authority is a locked table, a
  role claim, a config file** — and the one place it is legitimately read, so nobody
  re-implements the check inline.
- External services, queues, storage buckets, and how local dev fakes them.

### 7. The environment this repository expects

Probe, do not assume (see [`environment.md`](environment.md)):

- Required runtime versions (`.nvmrc`, `engines`, `.tool-versions`, Dockerfiles).
- Whether tooling is expected inside a container, and if so the exact container invocation.
- Anything the repo's docs claim about the machine that you can cheaply falsify — e.g. "the
  service restarts itself", "the gate is enforced". **Verify one such claim**; documented
  machine claims rot fastest.

## Writing the profile

Write [`repo-profile.md`](repo-profile.md) from the template. Rules:

- Every command carries its verification status. `UNVERIFIED` is a legitimate, useful value;
  a guess presented as fact is not.
- Every gate names its failure message, so the next agent recognizes it.
- Every conflict with this skill is listed explicitly, with the repository's rule prevailing.
- Keep it to what a new agent needs in its first ten minutes. It is a briefing, not a manual.

## Re-reconciling

Reconcile is cheap and safe to re-run. Re-run it when: you switch repositories; CI or a gate
changed; a command in the profile failed; the profile is older than the work; or you are about
to rely on a profile entry you have not verified this session. Updating the profile is part of
normal work — a stale profile is a false claim, which is the thing this skill forbids.
