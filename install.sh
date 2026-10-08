#!/usr/bin/env bash
# Install the engineering-doctrine skill into a repository (or globally).
#
#   install.sh [--force] [--global] [--refs-only] [target-repo]
#
# Default target is the current directory. --global installs to ~/.claude/skills instead,
# ignoring the target. --refs-only refreshes references/ but leaves SKILL.md and the
# generated repo-profile.md untouched.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skill"
NAME="engineering-doctrine"
FORCE=0 global=0 refs_only=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --force)     FORCE=1 ;;
    --global)    global=1 ;;
    --refs-only) refs_only=1 ;;
    -h|--help)
      sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *)  TARGET="$arg" ;;
  esac
done

if [ "$global" -eq 1 ]; then
  DEST="$HOME/.claude/skills/$NAME"
else
  [ -n "$TARGET" ] || TARGET="$(pwd)"
  [ -d "$TARGET" ] || { echo "not a directory: $TARGET" >&2; exit 2; }
  TARGET="$(cd "$TARGET" && pwd)"
  DEST="$TARGET/.claude/skills/$NAME"
fi

[ -d "$SRC" ] || { echo "payload missing: $SRC" >&2; exit 2; }

PROFILE="$DEST/references/repo-profile.md"
KEEP_PROFILE=0
[ -f "$PROFILE" ] && KEEP_PROFILE=1

if [ -e "$DEST" ] && [ "$FORCE" -eq 0 ] && [ "$refs_only" -eq 0 ]; then
  echo "already installed at $DEST"
  echo "  - update references only:  $0 --refs-only ${TARGET:-}"
  echo "  - overwrite everything:     $0 --force ${TARGET:-}"
  exit 0
fi

# Snapshot the profile so we can restore it after a destructive copy.
TMP_PROFILE=""
if [ "$KEEP_PROFILE" -eq 1 ]; then
  TMP_PROFILE="$(mktemp)"
  cp "$PROFILE" "$TMP_PROFILE"
fi
if [ "$refs_only" -eq 1 ]; then
  TMP_SKILL="$(mktemp)"
  cp "$DEST/SKILL.md" "$TMP_SKILL"
fi

mkdir -p "$DEST/references"

if [ "$refs_only" -eq 1 ]; then
  cp -f "$SRC/references/"*.md "$DEST/references/"
  # The template stub must never clobber a real profile.
  rm -f "$DEST/references/repo-profile.template.md"
  [ -f "$TMP_SKILL" ] && cp -f "$TMP_SKILL" "$DEST/SKILL.md"
else
  cp -f "$SRC/SKILL.md" "$DEST/SKILL.md"
  cp -f "$SRC/references/"*.md "$DEST/references/"
fi

if [ -n "$TMP_PROFILE" ]; then
  cp -f "$TMP_PROFILE" "$PROFILE"
else
  # Fresh install: seed the profile from the template so the shape is present.
  cp -f "$SRC/references/repo-profile.template.md" "$PROFILE"
fi
# The stub is a scaffold for the profile, never a file the installed skill reads.
rm -f "$DEST/references/repo-profile.template.md"
[ -n "$TMP_PROFILE" ] && rm -f "$TMP_PROFILE"
[ -n "${TMP_SKILL:-}" ] && rm -f "$TMP_SKILL"

echo "installed $NAME -> $DEST"

if [ "$KEEP_PROFILE" -eq 1 ]; then
  echo "  repo-profile.md preserved (this repository's own discovered knowledge)."
else
  echo
  echo "  NEXT: ask your agent to run the Reconcile step, or run it yourself:"
  echo "    Reconcile $DEST/references/repo-profile.md against this repository."
  echo "  Until Reconcile has run, every command in the profile is marked UNVERIFIED."
fi
