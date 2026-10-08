# Repository profile — <REPO NAME>

> **STATUS: STUB — Reconcile has not run.** Every entry below is a guess until
> [`reconcile.md`](reconcile.md) has been executed against this repository and replaced the
> placeholder. **Do not act on an unverified entry.** While this banner is present, treat
> every command as `UNVERIFIED` and verify before use.

Filled by: `<who> · <YYYY-MM-DD>`

Pinned at commit: `<sha>` · `<YYYY-MM-DD>` — entries are trusted while HEAD matches this
pin; `check.sh` compares them, and a pin outside this repository's history fails the check.

## 1. The repository's own rules (these win)

- Rules live in: `<AGENTS.md / CLAUDE.md / CONTRIBUTING.md / docs/…>`
- The repo's stated working principle: `<quote it>`
- Existing skills / agents: `<paths>`
- **Conflicts with this doctrine:** `<list each, and record that the repo's rule prevails>`

## 2. Identity and layout

- Language / framework: `<…>` · monorepo: `<yes/no>`
- Source: `<path>` · Tests: `<path>` · Docs: `<path>` · Migrations: `<path>`
- Stated boundary/import rules: `<…>`

## 3. Commands (verify each; record the exact invocation)

| Purpose | Command | Status |
|---|---|---|
| Install | `<…>` | `UNVERIFIED` |
| Format | `<…>` | `UNVERIFIED` |
| Lint | `<…>` | `UNVERIFIED` |
| Type-check | `<…>` | `UNVERIFIED` |
| Unit tests (one file) | `<…>` | `UNVERIFIED` |
| Unit tests (all) | `<…>` | `UNVERIFIED` |
| Build | `<…>` | `UNVERIFIED` |
| **The single pre-push gate** | `<…>` | `UNVERIFIED` |

## 4. Gates — what actually blocks a change

| Gate | Command / where | Trigger | Failure message | Status read directly? |
|---|---|---|---|---|
| CI | `<…>` | `<…>` | `<…>` | `<yes/no — a pipe or || true means NO>` |
| Merge gate | `<…>` | `<…>` | `<…>` | `<…>` |
| Review bot / threads | `<…>` | — | `<…>` | `<…>` |
| Audit / record validator | `<…>` | — | `<…>` | `<…>` |
| Schema / migration check | `<…>` | — | `<…>` | `<…>` |

- **Gates that cannot fail** (found during Reconcile): `<list, or "none found">`
- Record / plan validator grammar (if the repo has one): `<the exact item grammar it
  parses — discovered, never invented; "none" is a valid answer>`

## 5. Branch, commit, release

- Default branch: `<…>` · Branch naming: `<…>` · Commit format: `<…>`
- Version/changelog ownership: `<tool-owned / hand-edited / none>` — **hand-editing is
  `<allowed / forbidden>`**; the owner is `<tool name>`

## 6. Data and infrastructure

- Database / migration tool: `<…>` · How migrations are validated: `<…>`
- Authority is decided in: `<the one legitimate place>` — do not re-implement inline
- External services and their local substitutes: `<…>`

## 7. Environment expectations

- Required runtimes: `<…>` · Container-required tooling: `<…>`
- Documented machine claims, and whether verified: `<…>`

## Verification log

- `<YYYY-MM-DD>` — `<what was run, against which commit>`
