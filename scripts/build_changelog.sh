#!/usr/bin/env bash
# Convenience wrapper around scripts/build_changelog.rb.
# Run before `bundle exec jekyll build` / `serve` if you want fresh
# changelog data in `_data/changelog.yml`.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec ruby "${SCRIPT_DIR}/build_changelog.rb" "$@"
