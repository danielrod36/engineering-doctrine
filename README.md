# engineering-doctrine

A portable engineering discipline, packaged as an agent skill that **installs into any
repository and adapts itself to that repository before it does anything.**

It is the distilled, de-identified method from a body of work where every rule was paid for
by a real defect. The rules are not preferences. Each one exists because its absence produced
a specific, recorded failure — a gate that reported success because it sat on the left of a
pipe, a screenshot that silently dropped content and passed forever, a merge whose PR body
described the code the author *remembered* rather than the code that was there.

## The idea

A skill that hardcodes `pnpm pr:merge` is useful in exactly one repository and is a lie in
every other. So this skill carries two things and keeps them separate:

1. **The philosophy — the source of truth.** How to work: check before acting, prove before
   claiming, enforce with gates not paragraphs, fix causes not instances, inspect the evidence
   itself. This part is repository-independent because it is about reasoning, not tooling.
2. **The reconciliation protocol.** On first use in a repository, and whenever the repository
   changes, the skill **probes the repo and writes down what it found** — the real commands,
   the real gates, the real conventions, the real authorities — into
   `references/repo-profile.md`. Everything mechanical is read from there.

The philosophy is fixed; the mechanics are discovered. That is the whole design, and it is
also the philosophy in miniature: *do not assume, go and check, then act with what you found.*

## Install into a repository

```bash
git clone <this repo> ~/Projects/engineering-doctrine
~/Projects/engineering-doctrine/install.sh /path/to/target-repo
```

The installer copies the skill into `<target-repo>/.claude/skills/engineering-doctrine/`
and then tells your agent to run the **Reconcile** step. Reconcile reads the repo's own
`AGENTS.md`, `CLAUDE.md`, CI workflows, `package.json`, test layout, migration tree and
existing skills, writes `references/repo-profile.md`, and records every conflict it could
not resolve rather than guessing. From then on the skill works *in* that repository instead
of *at* it.

Options:

| Flag | Effect |
|---|---|
| `--force` | Overwrite an existing installation (repo-profile.md is preserved). |
| `--global` | Install to `~/.claude/skills/` so it is readable from every repo, no copy-in. |
| `--refs-only` | Update `references/` in place, keep `SKILL.md` and the profile. Used to pull doctrine improvements into a repo that already has it. |

## Layout

```
skill/
├── SKILL.md                    the constitution — principles, the reconcile-first rule, routing
└── references/
    ├── reconcile.md            how to probe a repo and localize the doctrine (self-update)
    ├── repo-profile.template.md   the stub Reconcile fills in
    ├── verification.md         claim verification, gates-not-paragraphs, reproduce-before-fix
    ├── delegation.md           slicing work, one-writer rule, briefs, convergence, reboot reality
    ├── audit-and-arc.md        pathway audit, findings → tracked arc, evidence decks, inspection
    ├── delivery.md             PR/merge/release hygiene, migration parity, branch discipline
    ├── environment.md          probe-your-environment (containers, package managers, auth)
    ├── memory.md               using agent memory without letting it become stale authority
    └── incidents.md            ANNEX — the failure that taught each rule, and how to detect it again
```

## Keeping repositories up to date

The doctrine improves by adding incidents, not by rewriting principles. When a rule earns a
new incident here, pull it into every installed repository:

```bash
~/Projects/engineering-doctrine/install.sh --refs-only /path/to/target-repo
```

`repo-profile.md` is never overwritten by an update — it is the target repository's own
knowledge, discovered locally, and only that repository's Reconcile may change it.

## License

CC-BY-NC-SA-4.0, matching the doctrine's origin.
