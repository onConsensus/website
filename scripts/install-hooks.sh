#!/usr/bin/env bash
# install-hooks.sh — wire the project's git hooks into .git/hooks/.
#
# The hooks themselves live in scripts/ so they are version-controlled
# and reviewable. .git/hooks/ is per-clone and not in the tree, so we
# symlink rather than copy.

set -e
ROOT="$(git rev-parse --show-toplevel)"
HOOKS="$ROOT/.git/hooks"

mkdir -p "$HOOKS"
ln -sf ../../scripts/pre-commit "$HOOKS/pre-commit"
chmod +x "$ROOT/scripts/pre-commit"

echo "[install-hooks] linked $HOOKS/pre-commit -> ../../scripts/pre-commit"
