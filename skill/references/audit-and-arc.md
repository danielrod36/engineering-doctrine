# Audit and arc — establishing what exists, then doing something about it

An audit is not a list of complaints. It is: **establish what exists and how it fails, then
turn that into a tracked, ordered, decidable sequence of work.** Findings without an arc are
notes, and notes are where a codebase's debt comes from in the first place.

## Phase A — Audit (do not fix anything yet)

Keep the audit and the remediation as **separate phases with a hard boundary.** Merging them
produces an audit that explains the fixes it made instead of the state it found, and a reader
can no longer tell which claims were measured before the repairs and which were written to
justify them.

### 1. Choose the pathway from evidence, not taste

Rank candidates with the repository's own instruments (its inventory, coverage map, orphan
detector, plans). Signals worth trusting, roughly in order:

1. **Zero end-to-end coverage of a user-visible behaviour.** A unit test on a reducer passes
   while the pixels stay wrong.
2. **A schema/shape change whose consumers were not all updated.** The highest-yield signal
   there is.
3. **Orphaned modules** — code that exists, is exported, and has no consumer.
4. **A plan marked active with unchecked units** — the gap between promise and shipment.

State the ranking and the evidence for the winner *before* starting. Do not audit by feel.

### 2. Map the pathway end to end

Trace from the **entry point** (route, user action) to the **observable result** (what the
user sees, what the store holds). Record `path:line` at every hop. For anything persisted or
authoritative, follow one operation all the way through: request → storage before → storage
after → returned result → cache → rendered state → reload → second client → immutable history.

### 3. Verify against a running system, never by reading

Reading proves a mechanism *can* fail. A live run proves it *does*. Boot the stack, seed data,
and exercise the path — see [`verification.md`](verification.md) for the boundary-instrumentation,
seeding, and impersonation rules that keep the run honest.

### 4. Record findings with a defect *and* a structural section

Every finding carries `path:line` and the **observable** consequence; verify each claim against
the consumer, not the definition. Then record, **separately**, the design properties that
produced the defects — duplication, inconsistent boundaries, an unfinished schema merge. Those
properties keep generating defects of the same shape long after the individual findings are
closed, so they are the substance of the arc, not a nice-to-have.

## Phase B — Remediation

1. **Reproduce every finding before touching it.** If it does not reproduce, say so and drop
   it — several findings in history were the auditor's own fixture bugs.
2. **Fix root causes.** A symptom fix that leaves the generator in place is not a fix.
3. **Consolidate the duplication the defects exposed** in the same change.
4. **Each fix gets a test that fails without it** — verified by reverting the fix.
5. **Update tests that pinned the defect**, and correct stale comments/docblocks.

Then verify, and land through the repository's gate — see [`delivery.md`](delivery.md).

## Phase C — The arc

**The report must be discoverable.** Most repos with a record system parse items from a
report file at a known path. A report named wrong, or whose findings are prose, is invisible:
the validator reports "consistent" because it found no items to check. Confirm the gate names
your file *and a count* before trusting it.

**Items use an exact grammar**, and the validator ignores anything else — an open box, a
closed box with a **dated** resolution, an optional declared order suffix, and the item body
indented beneath it as its brief. Check the repository's grammar in the profile; do not invent
one.

**Every item must be a decision or a build, never "tidy this".** A finding worth an item is one
that will keep producing defects until somebody chooses. Order by dependency: work that changes
data before work described relative to that data; a decision about what a thing *is* before work
that relies on it; removals last, because they need the ownership decisions first.

**Carry the structure into the arc, not just the defects.** If the structural section is empty,
the audit did not go deep enough.

**Write the arc in the same pass as the findings** — the ordering is obvious only while the
evidence is in hand.

## Evidence decks, and inspecting the evidence itself

When a repository requires captured visual evidence (screenshots, generated reports) for a
closed item:

- **The capture spec must assert *before* each capture, and name that assertion.** A screenshot
  proves a screen rendered, not that it worked. A capture with no preceding assertion is
  decoration.
- **An inspection pass is mandatory, and it must be real.** Look at every capture image and
  record what you saw in a structured field (`lookedAt` / `found`). **"I found nothing" is a
  legitimate, required value; a *placeholder* `found: []` written before anyone looked is a
  false record and is worse than an unfiled finding.** If a draft inspection was generated in
  advance, treat its empty result as untrusted until a human or agent has actually looked.
- **The defect you find this way is often in the evidence, not the code.** A generated image
  can silently drop content — e.g. an unescaped `<`-delimited type parameter swallowed as an
  unknown HTML tag when the page is set from a string — and every "the page rendered" assertion
  will pass forever. Escape prose and fact lines before rendering them as markup.
- **Enforce the obligation with the build, not a paragraph.** The deck builder should *refuse*
  a summary missing its inspection field, with a named error path for genuinely legacy
  artifacts — exempt them explicitly rather than silently backfilling a claim.
- **Demonstrate the gate can fail**: delete one required artifact, run the validator, and quote
  the failure verbatim. Record that quote.
