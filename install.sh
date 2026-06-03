#!/usr/bin/env bash
# Claude-Arsenal installer
# Author: Vivek Chanchal
# Copies offensive security skills into a Claude skills directory.
#
# Usage:
#   ./install.sh                                # interactive (asks for target)
#   ./install.sh --target ~/.claude/skills      # explicit target
#   ./install.sh --category web                 # one category only
#   ./install.sh --target DIR --category web    # combined
#   ./install.sh --list                         # list available categories
#   ./install.sh --dry-run                      # show what would be copied
#
# Default target: ~/.claude/skills/Claude-Arsenal

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/Skills"
DEFAULT_TARGET="${HOME}/.claude/skills/Claude-Arsenal"

TARGET=""
CATEGORY=""
DRY_RUN=0
LIST_ONLY=0

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

list_categories() {
  echo "Available categories:"
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    count=$(find "$d" -name SKILL.md | wc -l | tr -d ' ')
    printf "  %-20s %s skill(s)\n" "$name" "$count"
  done
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)   TARGET="$2"; shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --list)     LIST_ONLY=1; shift ;;
    -h|--help)  usage 0 ;;
    *)          echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

if [ "$LIST_ONLY" -eq 1 ]; then
  list_categories
  exit 0
fi

if [ ! -d "$SKILLS_DIR" ]; then
  echo "Error: Skills directory not found at $SKILLS_DIR" >&2
  exit 1
fi

# Interactive prompt if no target given
if [ -z "$TARGET" ]; then
  if [ -t 0 ]; then
    read -r -p "Install target [$DEFAULT_TARGET]: " TARGET || true
  fi
  TARGET="${TARGET:-$DEFAULT_TARGET}"
fi

# Validate category if specified
if [ -n "$CATEGORY" ]; then
  if [ ! -d "$SKILLS_DIR/$CATEGORY" ]; then
    echo "Error: Category '$CATEGORY' not found." >&2
    echo "" >&2
    list_categories >&2
    exit 1
  fi
  SOURCE="$SKILLS_DIR/$CATEGORY"
  DEST="$TARGET/$CATEGORY"
else
  SOURCE="$SKILLS_DIR"
  DEST="$TARGET"
fi

echo "Source:  $SOURCE"
echo "Target:  $DEST"
echo

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] Would copy:"
  find "$SOURCE" -name SKILL.md | sed "s|^$SOURCE|  $DEST|"
  exit 0
fi

mkdir -p "$DEST"

# Use rsync if available for nicer output, else cp -r
if command -v rsync >/dev/null 2>&1; then
  rsync -a --info=stats1 "$SOURCE/" "$DEST/"
else
  cp -r "$SOURCE/." "$DEST/"
  echo "Copied via cp (install rsync for progress info)."
fi

skill_count=$(find "$DEST" -name SKILL.md | wc -l | tr -d ' ')
echo
echo "Installed $skill_count skill(s) to $DEST"
echo "Claude should now auto-discover them on next session start."
