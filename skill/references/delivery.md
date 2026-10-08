# Delivery — PR, merge, release, migrations

The mechanical discipline of landing a change **without letting a false statement into the
mainline**. Every rule here is a way that a claim reached a protected branch because a human
or an agent trusted an adjacent signal instead of the check itself.

## Before opening a PR

- Run the repository's own pre-push gate, whatever the profile names it. Do not substitute a
  hand-rolled sequence you believe is equivalent.
- Update documentation, changelog, and the record the repository keeps, in the same change.
  A feature landed without its docs is half-landed.

## The PR body is a claim

Every sentence in a PR body describing the code is a claim and takes the verification bar:
`path:line`, plus the command that showed it. Resolve ownership by **grepping the consumer**,
not where the string appears. A PR body that describes the code you *remember* rather than the
code that is *there* is the defect that gets reviewed forever and merged anyway.

## Merging

- **Never gate a merge through a pipe.** `guard | tail -6 && merge` merges whenever `tail`
  succeeds. Read the gate's status directly, or use a script that reads the child's exit code
  in-process and does not invoke the merge at all when it is non-zero.
- **Merge only when the gate reports pass for the current head.** Fetch first; a gate run
  against an older commit authorizes nothing.
- **A blocked gate means fix, not bypass.** Never `--admin`, never a no-verify path around the
  gate, unless the gate itself is wrong — and then fix the gate in a separate, reviewed change.

## Stale state you must re-derive, never assume

These are the claims that have repeatedly been false:

- **"The branch is already rebased / up to date."** Verify the merge-base against the default
  branch; do not trust a predecessor's sentence. A branch sitting on an old merge-base is
  ordinary and silent.
- **"CI passed."** Re-run it on the current head if it matters; a pass on another tree proves
  nothing about this one.
- **"The threads are resolved."** Ask the gate, which reads the forge's real state, not the PR
  page you last saw.
- **"It is complete."** Look at the artifact. A completion claim from an earlier session is a
  hypothesis with an expiry date.

## Migrations and schema

- **Replay every migration cleanly on a disposable, from-scratch stack**, and run the schema
  linter, before committing. "It applied to my dev database" is not replay.
- **Policy and object drops with unstable names:** drop via a deterministic loop over the
  catalogue rather than a hardcoded name, because the name a replay produces can diverge from
  the live one.
- **Update every consumer of a changed shape in the same change.** A migration whose consumers
  were not all updated is the highest-yield source of defects there is; sweep *every* table,
  not only the ones being fixed.

## Releases and versions

- **Know who owns the version and the changelog.** If a tool owns them, do not hand-edit them —
  the tool will overwrite you and the divergence is silent. If the automated path is broken
  and you hand-tag, reconcile the manifest immediately so the next automated run does not
  propose a version you already shipped.
- **After a release, verify the facts agree:** tag target, manifest, changelog section, and any
  badge or published version string. They drift independently and each is a public claim.

## Finishing

- Land, then clean up: remove the branch and worktree, remove scaffolding and throwaway scripts,
  and leave the record consistent with the code. A lingering branch with unmerged work is not
  cleanup — it is a decision, and it should be recorded as one.
