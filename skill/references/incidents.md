# Incidents — the annex

Each principle above was paid for. This annex records the failures, so that a rule can be
judged on its evidence and so a reader can **detect the recurrence** rather than take the rule
on faith. Names and paths are generalized; the mechanism is what matters.

Read this when a rule looks arbitrary, or before you weaken one. If you weaken a rule, add
the incident that justifies it — or you will rediscover the original one.

Four principles — **3** (reproduce before you fix; revert to prove the fix), **4** (fix the
cause, consolidate rather than duplicate), **9** (finish properly, in the same change), and
**10** (the report is honest about the work) — predate this record. They are carried as the
**only** rules not backed by a recorded incident. The first time one of them fails to hold,
the incident that results goes here and the exception ends.

---

## The gate on the left of a pipe (`verification` §gates, `delivery` §merging)

A merge command read as "merge only if the guard passes":

```bash
guard 249 2>&1 | tail -6 && merge 249
```

A pipeline's exit status is its **last** command's, so `tail` succeeded, `&&` was satisfied,
and the merge ran with three unresolved review threads. The guard had *printed* its refusal;
nothing consumed it. Each thread named a false statement about the codebase that the merge
then made permanent, requiring a follow-up change to correct the record.

**Detect a recurrence:** a `|` between a gate and anything, or a `|| true`, or a
`continue-on-error`, on a check whose result is supposed to decide something.

---

## The false claims in a comment, in a file edited to remove a false claim

Three claims went into one comment: "reachable from the hub and the header nav", "reachable
from the header nav", "embedded by the workspace rather than reimplemented there". All false.
The root error was reusable: **a string's location is not its owner.** A grep found a component
name inside an iframe and concluded the wrong route served it; the page that *owned* that
component was a different, deprecated route.

**Detect a recurrence:** a reachability/ownership claim whose evidence is "I grepped the name"
rather than "I grepped the import / read the route that imports it".

---

## The screenshot that silently dropped content

A capture spec set page content from a template string containing an unescaped type parameter
(`Promise<number | null>`). The `<number | null>` was parsed as an unknown HTML tag and
**dropped from the rendered page**, so the committed screenshot was missing part of the very
panel it claimed to show — and every "the page rendered" assertion passed. The defect was in
the **evidence itself**. Found only by a pass that actually looked at each image and recorded
what it saw.

**Detect a recurrence:** a generated artifact whose content is interpolated into markup without
escaping; an empty `found` field whose emptiness was never verified by looking; any "evidence"
whose correctness is asserted only by the thing that produced it.

---

## Three inherited "proven" claims in one night

In a single session, three claims inherited from prior work — "proven", "complete and proven",
"both branches already rebased" — were each **false**. A CI run failed on first execution; a
feature path silently discarded its own input; two branches were seven commits behind the
default branch. **Not one was caught by a gate.** Each was caught only because someone
re-derived it instead of trusting the sentence.

**Detect a recurrence:** a brief, a plan, or a PR that states a status as an input rather than
a hypothesis. "Already rebased / passing / complete" with no command behind it.

---

## The runbook that promised resilience the provisioner never installed

The documentation stated the job runner was configured to restart on failure. The provisioner
installed the stock unit with no restart policy, so a killed runner stayed dead — and the gap
was only noticed during an unrelated outage. The document described the intended system, not
the real one.

**Detect a recurrence:** a doc, comment, or runbook that describes machine behaviour ("it
restarts itself", "this is enforced") — verify it cheaply; the description is a claim.

---

## The verification recorded against a different tree

A verification was performed and then recorded as if it applied to the current head; it had
run against an earlier commit. Likewise, a check was silently wrong because an **inherited
environment variable** (a git directory override) redirected a child process, and the result
looked plausible.

**Detect a recurrence:** a claim of verification with no commit named; a tool that spawns a
child without scrubbing `GIT_DIR` / `GIT_WORK_TREE` / similar overrides.

---

## The report that was invisible to its own validator

A findings report was named so the record validator could not find it, or written as prose
rather than in the item grammar. The validator reported **"consistent"** — not because the work
was done, but because it had found **no items to check**. A gate that cannot see its input
reports success.

**Detect a recurrence:** a validator that passes on an empty or unseen input; a "0 findings"
result that was never shown to have scanned anything.

---

## The plan that was trusted instead of the branch

A plan recorded items as done. The record and the code had diverged: the plan described an
intent, the branch told the truth. The reconciliation took a full pass, and the honest outcome
was to correct the plan, not the code.

**Detect a recurrence:** any status source (plan, board, memory, PR description) treated as
authoritative over the artifact it describes.

---

## The empty inspection that was written before anyone looked

A backfill step drafted `inspection.found: []` as part of the script, in advance of the actual
inspection. If that empty result had been committed unverified, it would have asserted "we
looked and found nothing" about a pass that had not happened — a **false record**, which is
worse than an unfiled finding, because it forecloses the search.

**Detect a recurrence:** any generated default for a field whose meaning is "we checked" —
`found: []`, `tested: true`, `verified: yes` — that can be produced without the check occurring.
