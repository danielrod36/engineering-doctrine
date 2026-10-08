---
name: engineering-doctrine
description: >-
  Use for any non-trivial engineering work in a repository: implementing a feature or fix,
  auditing a subsystem, verifying a claim about the codebase, writing or reviewing a PR,
  merging, releasing, delegating work to subagents, or reasoning about evidence and gates.
  This skill is the portable engineering discipline — evidence before action, gates instead
  of paragraphs, root causes instead of instances, and the evidence itself inspected rather
  than assumed. Triggers: audit, root cause, verify, reproduce, gate, merge, guard, release,
  PR review, delegate, subagent, evidence, "is this actually working", "prove it", "find what
  needs the most work", any task where the difference between claimed and proven matters.
  On first use in a repository it MUST reconcile itself against that repository before acting.
---

# Engineering doctrine

The portable discipline: **check before acting, prove before claiming, enforce with gates not
paragraphs, fix the cause not the instance, and inspect the evidence itself.**

Every rule here was paid for by a real defect. [`references/incidents.md`](references/incidents.md)
is the annex that records them; read it when you doubt a rule, or before weakening one. Four
principles — 3, 4, 9, and 10 — predate the record; the annex carries them as its only
exceptions.

## Step 0 — Reconcile, always

**Before doing anything else in a repository, establish what that repository actually is.**
Do not assume any command, path, gate, or convention. Find them.

1. Read the repository profile (in a copy-in install it is
   [`references/repo-profile.md`](references/repo-profile.md) inside the skill; in a global
   install it lives keyed by repository path — [`references/reconcile.md`](references/reconcile.md)
   names both locations). If it is still the stub, or it describes a repository you are not
   in, or the entry you need is `UNVERIFIED`, **run
   [`references/reconcile.md`](references/reconcile.md) now** and write the profile.
2. Read the repository's own rules first — `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, its
   `docs/`, its existing skills. **They win, with a floor.** The repository's conventions,
   commands, and formats override this skill's habits; when they conflict, record the
   conflict in the profile rather than silently preferring either side. But three articles
   no repository can override: **the evidence bar** (no claim passes as verified without the
   run that produced it), **no bypassing a gate to land a change** (if the gate is wrong,
   fix it in a separate, reviewed change), and **no false records** (never record a
   verification, inspection, or resolution that did not happen). A repository whose rules
   demand one of those gets the conflict surfaced, not obeyed.
3. Profiles are **commit-pinned and gated.** The profile records the commit its entries were
   verified at; entries are trusted while HEAD matches that pin, and when HEAD has moved you
   re-verify the entries you are about to rely on — not the whole profile, not nothing.
   `check.sh`, installed alongside this skill, enforces the profile's state: run it from the
   repository root; a reconciliation is not finished until it exits 0.
4. Only then act, using the commands the profile names — not the ones this skill happens to
   know from another project.

If you skip Step 0 you are about to make claims about a codebase you have not read, which is
the exact failure this doctrine exists to prevent.

## The principles

1. **Evidence in hand, then act.** A claim about the codebase ships with the command that
   produced it and a `path:line`. If you did not run it in *this* tree, say so at the claim —
   never let an unverified statement pass as verified. `[INFERENCE]` is allowed; pretending
   is not.

2. **Reading proves a mechanism *can* fail. A live run proves it *does*.** When the question
   is "is this working", boot the thing and observe it. Instrument the network when a control
   is silent. Read the API payload or the database, not the DOM, when the defect is about data
   that reaches the client.

3. **Reproduce before you fix; revert to prove the fix.** Every fix gets a test that fails
   without it — verify by reverting the fix and watching the test fail. A test that passes
   both ways pins nothing.

4. **Fix the cause, not the instance.** When a defect reveals a design flaw that produced it,
   repair the design. **Consolidate rather than duplicate** — if the same logic exists twice,
   that is itself the defect, even while both copies work.

5. **Gates, not paragraphs.** A rule that must hold is enforced by something that *runs* and
   reports a status. Prose in a docblock or a PR body is advisory; a check with an exit code
   is a rule. And **a gate read through a pipe is not a gate** — its exit status is the last
   command's. Read gate status directly or in-process.

6. **Inspect the evidence itself.** A screenshot that "shows the feature" may be missing
   content, a generated report may be empty because a selector silently matched nothing, a
   green check may have run against a different tree. Look at the artifact, not just the exit
   code that produced it. Record what you saw — including "I found nothing", which is a
   finding, not an absence.

7. **Distrust inherited claims — including your own from an hour ago.** A predecessor's
   "complete", "proven", "already rebased" is a hypothesis, not an input. Re-derive it; it
   costs minutes and it is the only reason the last three false claims were caught at all.

8. **Correct the record.** A comment, docblock, report, plan, or test that describes behaviour
   the code does not have is a defect in its own right. Replace it — never leave a false
   statement standing because the code around it works.

9. **Do things properly, and finish in the same change.** No half-measures, no "later", no
   placeholder shipped as if it were the thing. Defer only a decision that is genuinely not
   yours to make — and then record it with the evidence and the options, so it is a visible
   choice rather than an unstated gap.

10. **The report is honest about the work.** State what you tested, what you did not, and what
    is blocked. An unverified claim made visible is useful; an unverified claim hidden is the
    bug.

## Routing

Read the reference that matches the work. They are short and specific; do not read them all
and do not act from the summary above alone.

| When the work is… | Read |
|---|---|
| First use in a repo, or the repo changed underneath you | [`references/reconcile.md`](references/reconcile.md) |
| Verifying a claim, proving a fix, "is this actually working" | [`references/verification.md`](references/verification.md) |
| Slicing work, spawning subagents, converging parallel lanes | [`references/delegation.md`](references/delegation.md) |
| Running lanes through a specific agent harness (crash, checkpoint, channels) | [`references/harness/`](references/harness) |
| Auditing a subsystem, turning findings into tracked work | [`references/audit-and-arc.md`](references/audit-and-arc.md) |
| PR review, merge gating, releases, migrations | [`references/delivery.md`](references/delivery.md) |
| Anything whose answer depends on the machine (containers, runtimes, auth) | [`references/environment.md`](references/environment.md) |
| Recalling past sessions, retaining decisions | [`references/memory.md`](references/memory.md) |
| A rule looks arbitrary, or you want to weaken one | [`references/incidents.md`](references/incidents.md) |

## Anti-patterns

The shape all of these share: **a check that was assumed rather than read.**

- Reporting a mechanism as a confirmed defect because reading suggested it.
- Trusting a green gate you did not run, or that ran against a different tree.
- Placing a gate on the left of a pipe whose status decides anything.
- Resolving "X is reachable from / owned by Y" by grepping where X's string *appears* rather
  than grepping X's *consumers* — a string's location is not its owner.
- Shipping a spec that always skips, or a test that is green while asserting nothing.
- Deferring a consolidation with "out of scope" when the evidence shows it caused the defect.
- Recording a verification you performed earlier as if it were of the current tree.
- Writing findings without turning them into a tracked, ordered, decidable sequence of work.

## The one-line version

**Do not assume — go and check, then act on what you found, and say exactly which of those
things you did.**
