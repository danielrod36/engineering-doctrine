#!/usr/bin/env bash
# Check an engineering-doctrine installation and its repository profile.
#
#   check.sh [--root DIR] [--harness claude|agents] [--skills-dir DIR]
#
# Exit 0: clean (warnings allowed). Exit 1: violation. Exit 2: usage error.
#
# Hard failures: no installation found; profile missing, never reconciled (stub),
# unfilled placeholders, no commit pin, pin unknown to history, no version stamp.
# Warnings: HEAD has moved past the profile's pin (re-verify entries you rely on);
# UNVERIFIED command rows (legitimate, but do not rely on them unverified).
set -uo pipefail

usage() {
  cat <<'EOF'
Usage: check.sh [--root DIR] [--harness claude|agents] [--skills-dir DIR]

Checks the engineering-doctrine installation for the repository at --root
(default: current directory), then validates its repository profile:
reconciled, fully filled, commit-pinned within the current history.

Exit 0 = clean (warnings allowed), 1 = violation, 2 = usage error.
EOF
}

NAME="engineering-doctrine"
ROOT="$(pwd)"
HARNESS=""
SKILLS_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --root)      shift; [ $# -gt 0 ] || { echo "--root needs a value" >&2; exit 2; }; ROOT="$1" ;;
    --root=*)    ROOT="${1#--root=}" ;;
    --harness)   shift; [ $# -gt 0 ] || { echo "--harness needs a value" >&2; exit 2; }; HARNESS="$1" ;;
    --harness=*) HARNESS="${1#--harness=}" ;;
    --skills-dir) shift; [ $# -gt 0 ] || { echo "--skills-dir needs a value" >&2; exit 2; }; SKILLS_DIR="$1" ;;
    --skills-dir=*) SKILLS_DIR="${1#--skills-dir=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[ -d "$ROOT" ] || { echo "not a directory: $ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd)"

repo_key() {
  local k="${1#/}"
  printf '%s' "${k//\//_}"
}

FAILS=0
WARNS=0
fail() { FAILS=$((FAILS + 1)); echo "FAIL  $*"; }
warn() { WARNS=$((WARNS + 1)); echo "WARN  $*"; }
pass() { echo "PASS  $*"; }

# --- Locate the installation: project-level first, then user-level (global). ---
DEST="" MODE=""
SEARCH=()
if [ -n "$SKILLS_DIR" ]; then
  SEARCH+=("$ROOT/${SKILLS_DIR#./}/$NAME")
fi
if [ -z "$HARNESS" ] || [ "$HARNESS" = "claude" ]; then SEARCH+=("$ROOT/.claude/skills/$NAME"); fi
if [ -z "$HARNESS" ] || [ "$HARNESS" = "agents" ]; then SEARCH+=("$ROOT/.agents/skills/$NAME"); fi
for d in "${SEARCH[@]}"; do
  if [ -f "$d/SKILL.md" ]; then DEST="$d"; MODE="copy-in"; break; fi
done
if [ -z "$DEST" ]; then
  for d in "$HOME/.claude/skills/$NAME" "$HOME/.agents/skills/$NAME"; do
    if [ -f "$d/SKILL.md" ]; then DEST="$d"; MODE="global"; break; fi
  done
fi
if [ -z "$DEST" ]; then
  fail "no installation found for $ROOT (searched project skills dirs, then user-level)"
  echo "      install with: engineering-doctrine/install.sh $ROOT"
  exit 1
fi
pass "installation: $DEST ($MODE)"

# --- Installation integrity ---
if [ ! -f "$DEST/.doctrine-version" ]; then
  fail "no version stamp at $DEST/.doctrine-version — reinstall (or update with --refs-only)"
else
  pass "version: $(sed -n 's/^version: //p' "$DEST/.doctrine-version" | head -1) ($(sed -n 's/^mode: //p' "$DEST/.doctrine-version" | head -1))"
fi
for f in check.sh references/reconcile.md references/verification.md; do
  [ -f "$DEST/$f" ] || fail "payload incomplete: missing $f (reinstall)"
done

# --- Locate the repository profile ---
if [ "$MODE" = "copy-in" ]; then
  PROFILE="$DEST/references/repo-profile.md"
else
  PROFILE="$DEST/profiles/$(repo_key "$ROOT")/repo-profile.md"
fi
if [ ! -f "$PROFILE" ]; then
  fail "no repository profile at $PROFILE"
  echo "      ($MODE install; run Reconcile to create it — see references/reconcile.md)"
  echo "      summary: $FAILS failure(s), $WARNS warning(s)"
  exit 1
fi
pass "profile: $PROFILE"

# --- Profile state ---
if grep -q "STATUS: STUB" "$PROFILE"; then
  fail "profile is still the stub — Reconcile has never run for this repository"
fi

PLACEHOLDERS="$(grep -nE '(`<)|(<REPO NAME)' "$PROFILE" || true)"
if [ -n "$PLACEHOLDERS" ]; then
  N=$(printf '%s\n' "$PLACEHOLDERS" | wc -l)
  fail "profile has $N unfilled placeholder(s); first: $(printf '%s' "$PLACEHOLDERS" | head -1)"
else
  pass "no unfilled placeholders"
fi

# shellcheck disable=SC2016
# Single quotes intentional: the pattern matches literal backticks.
PIN="$(sed -nE 's/^Pinned at commit: *`?([0-9a-f]{7,})`?.*/\1/p' "$PROFILE" | head -1)"
if [ -z "$PIN" ]; then
  fail "profile has no commit pin — add 'Pinned at commit: <sha>' when Reconcile writes it"
elif ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  warn "root is not a git repository — commit pin '$PIN' cannot be compared to HEAD"
else
  HEAD_SHA="$(git -C "$ROOT" rev-parse --short HEAD)"
  if [ "$PIN" = "$HEAD_SHA" ]; then
    pass "commit pin matches HEAD ($PIN)"
  elif git -C "$ROOT" merge-base --is-ancestor "$PIN" HEAD 2>/dev/null; then
    warn "HEAD ($HEAD_SHA) has moved past the profile's pin ($PIN) — re-verify the entries you rely on (references/reconcile.md)"
  else
    fail "profile pin '$PIN' is not in this repository's history (rewritten? different repo?) — re-reconcile"
  fi
fi

# shellcheck disable=SC2016
# Single quotes intentional: matching the literal `UNVERIFIED` marker.
UNVERIFIED_N=$(grep -c '`UNVERIFIED`' "$PROFILE" || true)
if [ "$UNVERIFIED_N" -gt 0 ]; then
  warn "$UNVERIFIED_N UNVERIFIED command row(s) — legitimate, but do not rely on them unverified"
else
  pass "no UNVERIFIED command rows"
fi

echo "summary: $FAILS failure(s), $WARNS warning(s)"
[ "$FAILS" -eq 0 ] && exit 0
exit 1
