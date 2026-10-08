#!/usr/bin/env bash
# Install the engineering-doctrine skill into a repository (or globally).
#
# Copy-in installs put the skill (and its repository profile) inside the target
# repository, under the harness's skills directory. --global installs the skill
# once at the user level and keeps per-repo profiles under it, keyed by
# repository path, so switching repositories never clobbers another repo's
# discovered knowledge.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install.sh [options] [target-repo]

Options:
  --force             Overwrite an existing installation (the repository profile is preserved)
  --global            Install at the user level; per-repo profiles live under it, keyed by
                      repository path (target-repo, if given, gets its profile seeded)
  --refs-only         Update references/ and check.sh in place; keep SKILL.md and the profile
  --harness NAME      Harness conventions: claude (default) or agents (.agents/skills)
  --skills-dir DIR    Explicit skills directory. With --global: absolute user-level dir.
                      Without: directory relative to the target repository.
  -h, --help          Show this help

Examples:
  install.sh .                                    copy-in to ./.claude/skills/
  install.sh --harness agents .                   copy-in to ./.agents/skills/
  install.sh --skills-dir .opencode/skill .       copy-in to a custom directory
  install.sh --global ~/Projects/my-repo          user-level install, seeded profile for that repo
EOF
}

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skill"
SRC_ROOT="$(dirname "$SRC")"
NAME="engineering-doctrine"
FORCE=0 global=0 refs_only=0
HARNESS="claude"
SKILLS_DIR=""
TARGET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --force)     FORCE=1 ;;
    --global)    global=1 ;;
    --refs-only) refs_only=1 ;;
    --harness)
      shift
      [ $# -gt 0 ] || { echo "--harness needs a value" >&2; exit 2; }
      HARNESS="$1" ;;
    --harness=*)    HARNESS="${1#--harness=}" ;;
    --skills-dir)
      shift
      [ $# -gt 0 ] || { echo "--skills-dir needs a value" >&2; exit 2; }
      SKILLS_DIR="$1" ;;
    --skills-dir=*) SKILLS_DIR="${1#--skills-dir=}" ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
    *)  TARGET="$1" ;;
  esac
  shift
done

[ -d "$SRC" ] || { echo "payload missing: $SRC" >&2; exit 2; }

# Resolve skills directories: PROJECT_SKILLS is relative to the target repo,
# USER_SKILLS is the user-level directory for the harness.
if [ -n "$SKILLS_DIR" ]; then
  if [ "$global" -eq 1 ]; then
    case "$SKILLS_DIR" in
      /*) USER_SKILLS="$SKILLS_DIR" ;;
      *)  echo "--global --skills-dir must be absolute" >&2; exit 2 ;;
    esac
    PROJECT_SKILLS=""
  else
    PROJECT_SKILLS="${SKILLS_DIR#./}"
    USER_SKILLS="$HOME/.$HARNESS/skills"
  fi
else
  case "$HARNESS" in
    claude) PROJECT_SKILLS=".claude/skills"; USER_SKILLS="$HOME/.claude/skills" ;;
    agents) PROJECT_SKILLS=".agents/skills"; USER_SKILLS="$HOME/.agents/skills" ;;
    *)
      echo "unknown harness: $HARNESS (known: claude, agents — or pass --skills-dir)" >&2
      exit 2 ;;
  esac
fi

# Keyed profile path for global installs: the repo's absolute path with / → _.
repo_key() {
  local k="${1#/}"
  printf '%s' "${k//\//_}"
}

PROFILE=""
if [ "$global" -eq 1 ]; then
  DEST="$USER_SKILLS/$NAME"
  MODE="global"
  if [ -n "$TARGET" ]; then
    [ -d "$TARGET" ] || { echo "not a directory: $TARGET" >&2; exit 2; }
    TARGET="$(cd "$TARGET" && pwd)"
    PROFILE="$DEST/profiles/$(repo_key "$TARGET")/repo-profile.md"
  fi
else
  [ -n "$TARGET" ] || TARGET="$(pwd)"
  [ -d "$TARGET" ] || { echo "not a directory: $TARGET" >&2; exit 2; }
  TARGET="$(cd "$TARGET" && pwd)"
  DEST="$TARGET/$PROJECT_SKILLS/$NAME"
  PROFILE="$DEST/references/repo-profile.md"
  MODE="copy-in"
fi

# --refs-only requires an existing installation; fail with a reason, not a raw cp error.
if [ "$refs_only" -eq 1 ] && [ ! -f "$DEST/SKILL.md" ]; then
  echo "not installed at $DEST — run a full install first (drop --refs-only)" >&2
  exit 2
fi

if [ -e "$DEST" ] && [ "$FORCE" -eq 0 ] && [ "$refs_only" -eq 0 ]; then
  # A global install that already exists still owes a new target its keyed profile.
  if [ "$MODE" = "global" ] && [ -n "$TARGET" ] && [ ! -f "$PROFILE" ]; then
    mkdir -p "$(dirname "$PROFILE")"
    cp -f "$SRC/references/repo-profile.template.md" "$PROFILE"
    echo "already installed at $DEST — seeded profile for $TARGET:"
    echo "  $PROFILE"
    echo "  NEXT: reconcile it against the repository, then run:"
    echo "    bash $DEST/check.sh --root $TARGET"
    exit 0
  fi
  echo "already installed at $DEST"
  echo "  - update references only:  $0 --refs-only ${TARGET:-}"
  echo "  - overwrite everything:     $0 --force ${TARGET:-}"
  exit 0
fi
KEEP_PROFILE=0
if [ -n "$PROFILE" ] && [ -f "$PROFILE" ]; then KEEP_PROFILE=1; fi

TMP_PROFILE="" TMP_SKILL=""
if [ "$KEEP_PROFILE" -eq 1 ]; then
  TMP_PROFILE="$(mktemp)"
  cp "$PROFILE" "$TMP_PROFILE"
fi
if [ "$refs_only" -eq 1 ]; then
  TMP_SKILL="$(mktemp)"
  cp "$DEST/SKILL.md" "$TMP_SKILL"
fi

# Payload copy. references/ is wiped first so files deleted upstream disappear here too;
# a global install's profiles/ tree is never touched by the payload copy.
mkdir -p "$DEST"
rm -rf "$DEST/references"
cp -R "$SRC/references" "$DEST/references"
if [ "$refs_only" -eq 1 ]; then
  cp -f "$TMP_SKILL" "$DEST/SKILL.md"
  rm -f "$TMP_SKILL"
else
  cp -f "$SRC/SKILL.md" "$DEST/SKILL.md"
fi
cp -f "$SRC_ROOT/check.sh" "$DEST/check.sh"
chmod +x "$DEST/check.sh"
# The template is a scaffold in the source repo, never an installed file.
rm -f "$DEST/references/repo-profile.template.md"

# Version stamp: provenance for the installed copy (source commit, date, mode, harness).
VERSION="untagged"
if V_SHA="$(git -C "$SRC_ROOT" rev-parse --short HEAD 2>/dev/null)"; then
  VERSION="$V_SHA"
fi
{
  printf 'version: %s\n' "$VERSION"
  printf 'installed: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'mode: %s\n' "$MODE"
  printf 'harness: %s\n' "$HARNESS"
} > "$DEST/.doctrine-version"

# Restore or seed the repository profile.
if [ -n "$TMP_PROFILE" ]; then
  mkdir -p "$(dirname "$PROFILE")"
  cp -f "$TMP_PROFILE" "$PROFILE"
  rm -f "$TMP_PROFILE"
elif [ "$MODE" = "copy-in" ]; then
  cp -f "$SRC/references/repo-profile.template.md" "$PROFILE"
elif [ -n "$TARGET" ]; then
  mkdir -p "$(dirname "$PROFILE")"
  cp -f "$SRC/references/repo-profile.template.md" "$PROFILE"
fi

echo "installed $NAME ($VERSION) -> $DEST"
if [ "$MODE" = "copy-in" ]; then
  echo "  profile: $PROFILE"
  echo "  Commit it. The profile is this repository's own shared knowledge."
  echo "  NEXT: reconcile the profile against this repository, then from the repo root run:"
  echo "    bash $PROJECT_SKILLS/$NAME/check.sh"
else
  echo "  mode: global (harness: $HARNESS)"
  if [ -n "$TARGET" ]; then
    echo "  profile for $TARGET: $PROFILE"
    echo "  NEXT: reconcile that profile against the repository, then run:"
    echo "    bash $USER_SKILLS/$NAME/check.sh --root $TARGET"
  else
    echo "  Per-repo profiles live under $DEST/profiles/<repo path, / -> _>/repo-profile.md"
    echo "  Re-run with a target-repo to seed one."
  fi
fi
