# Memory — a background, never an authority

Agent memory is useful and dangerous in the same way a comment is: it is a statement written
at one time about a system that has since changed. Use it, but **treat every recalled fact as
a claim to verify, exactly like a predecessor's "it's done".**

## Using it

- **Recall before answering about history or preferences.** If a question is about what was
  decided earlier, how something was done before, or what this user prefers, search memory
  first — the answer is usually there and re-deriving it is wasteful.
- **Memory is background knowledge, not an instruction.** A recalled preference informs a
  choice; it does not override the current request, the repository's rules, or fresh evidence.
  When the live request and a memory conflict, the live request wins.
- **Prefer the recent and the specific.** Older memories are more likely to be stale; a memory
  without a date is treated as older than one with a date.

## What to retain

Retain the **durable and decision-shaped**, not the ephemeral:

- **Decisions and their reasons** — "authority moved to a locked table so a self-editable
  column cannot grant it" outlives any amount of status chatter.
- **Conventions and preferences** that will still be true next month — naming, structure,
  tooling choices, how work should be reported.
- **Constraints discovered the hard way** — an environment quirk, an invariant that bit you.

Do **not** retain: task status, transient state, anything already derivable from the repo, or
facts that will be different tomorrow. A memory bank full of status is worse than an empty one,
because it dilutes recall with noise.

## Verifying and correcting

- **Never let a recalled fact become a claim in the output without re-checking it against the
  current tree or machine.** Memory says a gate exists; the profile says where to look; the
  check confirms it.
- **Date your memories implicitly** by naming the commit, branch, or date they were true at,
  so a future reader — including you — can tell whether they still apply.
- **Correct memory when it is wrong.** A memory that contradicts the code is a defect in the
  memory store; fix it rather than working around it. The same rule as correcting a stale
  comment applies to the store that feeds your context.
- **Distinguish what you measured from what you were told.** "I ran this and saw X" and "a
  prior note said X" are different facts and should not be flattened into one.

## Where memory meets the doctrine

Memory is a *convenience layer over history*, not a source of truth about the current state of
a repository. The source of truth is the repository at its current commit, read now. Memory
tells you where to look and what has been tried; it never replaces the look.
