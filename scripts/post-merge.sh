#!/bin/bash
set -e

bundle install --quiet

# Refresh the article changelog (`_data/changelog.yml`) from git history
# so post pages render up-to-date post-publish edit lists.
ruby scripts/build_changelog.rb || echo "[post-merge] changelog regen skipped"
