#!/usr/bin/env bash
# Tests for install.sh and check.sh. Plain bash, no dependencies.
# shellcheck disable=SC2015
# (A && ok || bad is safe here: ok()/bad() never fail, so C runs only when A is false.)
#
#   bash tests/test-install.sh
#
# Every test runs against a throwaway sandbox copy of this repository, so the
# tests can mutate the payload (to prove --refs-only propagates changes) without
# touching the real tree.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0 FAIL=0
OUT="" RC=0

ok()  { PASS=$((PASS + 1)); echo "ok   - $1"; }
bad() { FAIL=$((FAIL + 1)); echo "FAIL - $1"; }

run() { OUT="$("$@" 2>&1)"; RC=$?; }

expect_rc() { # desc want_rc [output_pattern]
  local desc="$1" want="$2" pat="${3:-}"
  if [ "$RC" != "$want" ]; then
    bad "$desc (exit $RC, wanted $want)"
  elif [ -n "$pat" ] && ! grep -q "$pat" <<<"$OUT"; then
    bad "$desc (output missing: $pat)"
  else
    ok "$desc"
  fi
}

new_git_repo() { # $1 = dir
  mkdir -p "$1"
  echo "scratch" > "$1/README"
  git -C "$1" init -q
  git -C "$1" -c user.name=test -c user.email=test@test add -A
  git -C "$1" -c user.name=test -c user.email=test@test commit -qm init
}

commit_more() { # $1 = dir, $2 = file content change
  echo "$2" >> "$1/notes.txt"
  git -C "$1" -c user.name=test -c user.email=test@test add -A
  git -C "$1" -c user.name=test -c user.email=test@test commit -qm more
}

# --- Sandbox source copy (git repo, so version stamps carry a sha) ---
SRC_SANDBOX="$WORK/src"
mkdir -p "$SRC_SANDBOX"
cp -R "$REPO_ROOT/skill" "$SRC_SANDBOX/"
cp "$REPO_ROOT/install.sh" "$REPO_ROOT/check.sh" "$SRC_SANDBOX/"
git -C "$SRC_SANDBOX" init -q
git -C "$SRC_SANDBOX" -c user.name=test -c user.email=test@test add -A
git -C "$SRC_SANDBOX" -c user.name=test -c user.email=test@test commit -qm init
INSTALL="$SRC_SANDBOX/install.sh"
CHECK="$SRC_SANDBOX/check.sh"
DEST_REL=".claude/skills/engineering-doctrine"

# A minimal, fully-reconciled profile. $1 = pin sha, $2 = extra command row ("" for none).
write_profile() {
  local pin="$1" extra="$2" prof="$3"
  cat > "$prof" <<EOF
# Repository profile — scratch

Filled by: \`tester · 2026-10-08\`

Pinned at commit: \`$pin\` · 2026-10-08

## 1. The repository's own rules (these win)

- Rules live in: none found
- The repo's stated working principle: none stated
- **Conflicts with this doctrine:** none

## 3. Commands (verify each; record the exact invocation)

| Purpose | Command | Status |
|---|---|---|
| Install | echo install | \`VERIFIED (ran once on 2026-10-08)\` |
$extra
EOF
}

# ---------- T1: fresh copy-in install ----------
REPO="$WORK/t1"
new_git_repo "$REPO"
run "$INSTALL" "$REPO"
expect_rc "T1 fresh install exits 0" 0 "installed engineering-doctrine"
D="$REPO/$DEST_REL"
for f in SKILL.md check.sh .doctrine-version references/repo-profile.md \
         references/reconcile.md references/harness/omp.md references/harness/claude-code.md; do
  [ -f "$D/$f" ] && ok "T1 payload has $f" || bad "T1 payload missing $f"
done
[ -f "$D/references/repo-profile.template.md" ] && bad "T1 template should not ship" || ok "T1 template removed"
grep -q '^version: [0-9a-f]' "$D/.doctrine-version" && ok "T1 version stamped with sha" || bad "T1 version not stamped"
grep -q "Commit it" <<<"$OUT" && ok "T1 tells user to commit profile" || bad "T1 no commit advice"

# ---------- T2: re-install without flags is a no-op ----------
echo "MARKER" >> "$D/references/repo-profile.md"
run "$INSTALL" "$REPO"
expect_rc "T2 reinstall exits 0 with notice" 0 "already installed"
grep -q "MARKER" "$D/references/repo-profile.md" && ok "T2 profile untouched" || bad "T2 profile clobbered"

# ---------- T3: --refs-only on a never-installed repo ----------
REPO2="$WORK/t3"
new_git_repo "$REPO2"
run "$INSTALL" --refs-only "$REPO2"
expect_rc "T3 refs-only uninstalled exits 2" 2 "not installed at"
[ ! -e "$REPO2/$DEST_REL" ] && ok "T3 no partial install left" || bad "T3 left partial install"

# ---------- T4: --refs-only propagates reference changes, preserves SKILL.md + profile ----------
echo "# doctrine update marker" >> "$SRC_SANDBOX/skill/references/verification.md"
echo "LOCAL-EDIT" >> "$D/SKILL.md"
V1="$(sed -n 's/^installed: //p' "$D/.doctrine-version")"
sleep 1
run "$INSTALL" --refs-only "$REPO"
expect_rc "T4 refs-only exits 0" 0
grep -q "doctrine update marker" "$D/references/verification.md" && ok "T4 reference updated" || bad "T4 reference not updated"
grep -q "LOCAL-EDIT" "$D/SKILL.md" && ok "T4 SKILL.md preserved" || bad "T4 SKILL.md clobbered"
grep -q "MARKER" "$D/references/repo-profile.md" && ok "T4 profile preserved" || bad "T4 profile clobbered"
V2="$(sed -n 's/^installed: //p' "$D/.doctrine-version")"
[ "$V1" != "$V2" ] && ok "T4 version re-stamped" || bad "T4 version not re-stamped"

# ---------- T5: --force overwrites SKILL.md, preserves profile ----------
run "$INSTALL" --force "$REPO"
expect_rc "T5 force exits 0" 0
grep -q "LOCAL-EDIT" "$D/SKILL.md" && bad "T5 SKILL.md should be overwritten" || ok "T5 SKILL.md overwritten"
grep -q "MARKER" "$D/references/repo-profile.md" && ok "T5 profile preserved" || bad "T5 profile clobbered"

# ---------- T6: --harness agents ----------
REPO6="$WORK/t6"
new_git_repo "$REPO6"
run "$INSTALL" --harness agents "$REPO6"
expect_rc "T6 agents harness exits 0" 0
[ -f "$REPO6/.agents/skills/engineering-doctrine/SKILL.md" ] && ok "T6 installed to .agents/skills" || bad "T6 wrong destination"

# ---------- T7: --skills-dir custom ----------
REPO7="$WORK/t7"
new_git_repo "$REPO7"
run "$INSTALL" --skills-dir .opencode/skill "$REPO7"
expect_rc "T7 custom skills-dir exits 0" 0
[ -f "$REPO7/.opencode/skill/engineering-doctrine/SKILL.md" ] && ok "T7 installed to custom dir" || bad "T7 wrong destination"

# ---------- T8/T9: --global keyed profiles ----------
HOME8="$WORK/home8"
mkdir -p "$HOME8"
REPO8="$WORK/t8repo"
new_git_repo "$REPO8"
run env HOME="$HOME8" "$INSTALL" --global "$REPO8"
expect_rc "T8 global install exits 0" 0 "mode: global"
GD="$HOME8/.claude/skills/engineering-doctrine"
KEY="$(printf '%s' "${REPO8#/}" | tr / _)"
[ -f "$GD/profiles/$KEY/repo-profile.md" ] && ok "T8 keyed profile seeded" || bad "T8 keyed profile missing"
[ ! -f "$GD/references/repo-profile.md" ] && ok "T8 no shared profile slot" || bad "T8 profile leaked into references/"
echo "MARKER8" >> "$GD/profiles/$KEY/repo-profile.md"

REPO9="$WORK/t9repo"
new_git_repo "$REPO9"
run env HOME="$HOME8" "$INSTALL" --global "$REPO9"
expect_rc "T9 second global repo exits 0" 0
KEY9="$(printf '%s' "${REPO9#/}" | tr / _)"
grep -q "MARKER8" "$GD/profiles/$KEY/repo-profile.md" && ok "T9 first repo profile intact" || bad "T9 first repo profile clobbered"
[ -f "$GD/profiles/$KEY9/repo-profile.md" ] && ok "T9 second keyed profile seeded" || bad "T9 second keyed profile missing"

# ---------- T10: check.sh with no installation ----------
REPO10="$WORK/t10"
new_git_repo "$REPO10"
run "$CHECK" --root "$REPO10"
expect_rc "T10 no installation fails" 1 "no installation found"

# ---------- T11: check.sh on a stub profile ----------
run bash "$REPO/$DEST_REL/check.sh" --root "$REPO"
expect_rc "T11 stub profile fails" 1 "stub"

# ---------- T12-T15: check.sh on a reconciled profile ----------
SHA="$(git -C "$REPO" rev-parse --short HEAD)"
write_profile "$SHA" "" "$REPO/$DEST_REL/references/repo-profile.md"
run bash "$REPO/$DEST_REL/check.sh" --root "$REPO"
expect_rc "T12 reconciled profile passes" 0 "commit pin matches HEAD"

commit_more "$REPO" "change"
run bash "$REPO/$DEST_REL/check.sh" --root "$REPO"
expect_rc "T13 ancestor drift warns, passes" 0 "moved past the profile's pin"

write_profile "deadbee" "" "$REPO/$DEST_REL/references/repo-profile.md"
run bash "$REPO/$DEST_REL/check.sh" --root "$REPO"
expect_rc "T14 unknown pin fails" 1 "not in this repository's history"

NEW_SHA="$(git -C "$REPO" rev-parse --short HEAD)"
write_profile "$NEW_SHA" "| Build | make | \`UNVERIFIED\` |" "$REPO/$DEST_REL/references/repo-profile.md"
run bash "$REPO/$DEST_REL/check.sh" --root "$REPO"
expect_rc "T15 UNVERIFIED rows warn only" 0 "UNVERIFIED command row"

# ---------- T16: help flags ----------
run "$INSTALL" -h
expect_rc "T16 install help" 0 "Usage:"
run "$CHECK" -h
expect_rc "T16 check help" 0 "Usage:"

# ---------- T17: unknown harness rejected ----------
run "$INSTALL" --harness nosuch "$WORK"
expect_rc "T17 unknown harness exits 2" 2 "unknown harness"

# ---------- T18: global install resolves keyed profile via check ----------
SHA8="$(git -C "$REPO8" rev-parse --short HEAD)"
write_profile "$SHA8" "" "$GD/profiles/$KEY/repo-profile.md"
run env HOME="$HOME8" bash "$GD/check.sh" --root "$REPO8"
expect_rc "T18 global check resolves keyed profile" 0 "commit pin matches HEAD"

# ---------- T19: relative --global --skills-dir rejected ----------
run "$INSTALL" --global --skills-dir rel/dir "$REPO8"
expect_rc "T19 relative global skills-dir exits 2" 2 "must be absolute"

echo
# ---------- T20: --global with no target installs doctrine, no profile ----------
HOME20="$WORK/home20"
mkdir -p "$HOME20"
run env HOME="$HOME20" "$INSTALL" --global
expect_rc "T20 global without target exits 0" 0 "Per-repo profiles live under"

echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
