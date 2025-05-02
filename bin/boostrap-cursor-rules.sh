#!/usr/bin/env bash
#
#  bootstrap_cursor_rules.sh
#  -------------------------
#  Usage:
#     ./bootstrap_cursor_rules.sh [--target /path/to/repo] [--link]
#
#  If --target is omitted the current directory is used.
#  If --link  is given the rule files are symlinked instead of copied
#  (handy when you want one central rule folder on disk).

set -euo pipefail

###############################################################################
# 1. Resolve CLI flags
###############################################################################
TARGET_DIR="$PWD"
LINK_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|-t) TARGET_DIR="$(realpath "$2")"; shift 2 ;;
    --link|-l)   LINK_MODE=true;                shift   ;;
    *)           echo "Unknown flag: $1"; exit 1 ;;
  esac
done

###############################################################################
# 2. Paths
###############################################################################
SRC_RULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.cursor/rules" && pwd)"
DEST_RULE_DIR="$TARGET_DIR/.cursor/rules"

###############################################################################
# 3. Copy or link rules
###############################################################################
mkdir -p "$DEST_RULE_DIR"

if $LINK_MODE; then
  # One symlink per file keeps rsync/backup tools happy
  for f in "$SRC_RULE_DIR"/*.mdc; do
    ln -sf "$f" "$DEST_RULE_DIR/$(basename "$f")"
  done
else
  rsync -a --checksum --delete "$SRC_RULE_DIR"/ "$DEST_RULE_DIR"/
fi

###############################################################################
# 4. Ensure .gitignore hides .cursor in the target repo
###############################################################################
IGNORE_FILE="$TARGET_DIR/.gitignore"
if [[ ! -f $IGNORE_FILE ]]; then touch "$IGNORE_FILE"; fi
if ! grep -qxF '.cursor/' "$IGNORE_FILE"; then
  echo '.cursor/' >> "$IGNORE_FILE"
  echo "➕  Added '.cursor/' to $(basename "$IGNORE_FILE")"
fi

###############################################################################
# 5. Create/merge .cursorignore so Cursor indexes what you need
###############################################################################
CURSORIGNORE="$TARGET_DIR/.cursorignore"
if [[ ! -f $CURSORIGNORE ]]; then
  cat > "$CURSORIGNORE" <<'EOF'
# Let Cursor index the important parts inside the ignored .cursor dir
!.cursor/
!.cursor/rules/**
!.cursor/specs/**
!.cursor/tasks/**
!.cursor/learnings/**

# Keep large or generated artefacts out of the embedding index
.cursor/output/
EOF
  echo "📝  Created .cursorignore"
fi

echo "✅  Cursor rules bootstrapped into $TARGET_DIR"
