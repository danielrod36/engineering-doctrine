# engineering-doctrine

A portable engineering discipline, packaged as an agent skill that **installs into any
repository and adapts itself to that repository before it does anything.**

It is the distilled, de-identified method from a body of work where every rule was paid for
by a real defect — recorded, with its detection signal, in the incidents annex. Four
principles predate that record and are carried there as its only exceptions. The rules are
not preferences: each backed one exists because its absence produced a specific, recorded
failure — a gate that reported success because it sat on the left of a pipe, a screenshot
that silently dropped content and passed forever, a merge whose PR body described the code
the author *remembered* rather than the code that was there.

## The idea

A skill that hardcodes `pnpm pr:merge` is useful in exactly one repository and is a lie in
every other. So this skill keeps three layers separate:

1. **The philosophy — the source of truth.** How to work: check before acting, prove before
   claiming, enforce with gates not paragraphs, fix causes not instances, inspect the
   evidence itself. Repository-independent because it is about reasoning, not tooling.
2. **The harness mechanics.** Crash, checkpoint, and channel behaviour of the agent runtime
   you actually run in (`references/harness/`) — one file per harness, never blended into
   the portable doctrine.
3. **The reconciliation protocol.** On first use in a repository, and whenever the repository
   changes, the skill **probes the repo and writes down what it found** — the real commands,
   the real gates, the real conventions, the real authorities — into the repository profile.
   Everything mechanical is read from there.

The philosophy is fixed; the harness facts are labeled; the mechanics are discovered. That is
the whole design, and it is also the philosophy in miniature: *do not assume, go and check,
then act with what you found.*

## Install into a repository

```bash
git clone https://github.com/danielrod36/engineering-doctrine ~/Projects/engineering-doctrine
~/Projects/engineering-doctrine/install.sh /path/to/target-repo
```

The installer copies the skill into the target's skills directory (plus `check.sh`, and a
`.doctrine-version` stamp recording the source commit) and tells your agent to run the
**Reconcile** step. Reconcile reads the repo's own `AGENTS.md`, `CLAUDE.md`, CI workflows,
`package.json`, test layout, migration tree, and existing skills, writes the repository
profile, and pins it to the commit it verified at.

Options:

| Flag | Effect |
|---|---|
| `--force` | Overwrite an existing installation (the repository profile is preserved). |
| `--global` | Install once at the user level; per-repo profiles live under it, keyed by repository path, so repo switches never clobber each other. |
| `--refs-only` | Update `references/` and `check.sh` in place; keep `SKILL.md` and the profile. Re-stamps the version. |
| `--harness NAME` | Harness conventions: `claude` (default, `.claude/skills/`) or `agents` (`.agents/skills/`). |
| `--skills-dir DIR` | Any other harness: explicit skills dir (relative to the target repo, or absolute with `--global`). |

## Where the profile lives, and who owns it

- **Copy-in installs (default):** the profile lives inside the repository at
  `<skills-dir>/engineering-doctrine/references/repo-profile.md` and **is committed** — it is
  that repository's own discovered knowledge. A fresh clone that has to re-derive it learned
  nothing. Profile updates ride along with the work that discovered them.
- **Global installs:** the doctrine lives once at `~/.<harness>/skills/engineering-doctrine/`;
  each repository's profile lives under `profiles/<repo path, / → _>/repo-profile.md`, keyed
  by absolute path, so switching repositories selects the right profile instead of
  overwriting another's.

## The check

The doctrine gates itself the way it tells you to gate everything else — with a command that
runs and reports a status:

```bash
bash .claude/skills/engineering-doctrine/check.sh   # from the repository root
```

It locates the installation (project-level first, then user-level), resolves the profile for
the repository you are in, and fails on: no installation, a profile that is still the stub,
unfilled placeholders, a missing commit pin, or a pin outside the repository's history. It
warns when HEAD has moved past the pin (re-verify the entries you rely on) and counts
`UNVERIFIED` command rows. **Reconcile is not finished until `check.sh` exits 0.** This
repository's CI runs the same discipline on itself.

## Layout

```
├── install.sh                     harness-aware installer, version stamping, profile preservation
├── check.sh                       the gate: validates an installation and its profile
├── tests/test-install.sh          installer + check tests (bash, no dependencies)
├── .github/workflows/ci.yml       runs the tests and shellcheck
└── skill/
    ├── SKILL.md                   the constitution — principles, reconcile-first, floor, routing
    └── references/
        ├── reconcile.md           probe a repo, localize the doctrine, pin the profile
        ├── repo-profile.template.md  the stub Reconcile fills in
        ├── verification.md        claim verification, gates-not-paragraphs, reproduce-before-fix
        ├── delegation.md          portable slicing, briefs, convergence
        ├── harness/               per-harness crash/checkpoint/channel mechanics
        │   ├── claude-code.md
        │   └── omp.md
        ├── audit-and-arc.md       pathway audit, findings → tracked arc, evidence decks
        ├── delivery.md            PR/merge/release hygiene, migration parity, branch discipline
        ├── environment.md         probe-your-environment (containers, package managers, auth)
        ├── memory.md              using agent memory without letting it become stale authority
        └── incidents.md           ANNEX — the failure that taught each rule, and its detection
```

## Keeping repositories up to date

The doctrine improves by adding incidents, not by rewriting principles. When a rule earns a
new incident here, pull it into every installed repository:

```bash
~/Projects/engineering-doctrine/install.sh --refs-only /path/to/target-repo
```

The repository profile is never overwritten by an update — it is the target repository's own
knowledge, and only that repository's Reconcile may change it. The installer stamps the
source commit into `.doctrine-version` on every install and update, so "which doctrine
version is in this repo?" always has an answer; `check.sh` reports it.

## License

MIT — see [LICENSE](LICENSE). Safe to install and use anywhere, including at work.
