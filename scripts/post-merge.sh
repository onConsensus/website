#!/bin/bash
set -e

bundle install --quiet

# Refresh the article changelog (`_data/changelog.yml`) from git history
# so post pages render up-to-date post-publish edit lists.
ruby scripts/build_changelog.rb    || echo "[post-merge] changelog regen skipped"
ruby scripts/build_timestamps.rb   || echo "[post-merge] timestamps regen skipped"
ruby scripts/build_methodology.rb  || echo "[post-merge] methodology regen skipped"
ruby scripts/build_embargoes.rb    || echo "[post-merge] embargoes regen skipped"
ruby scripts/build_permaids.rb     || echo "[post-merge] permaids regen skipped"
ruby scripts/build_feeds.rb        || echo "[post-merge] feeds regen skipped"
ruby scripts/build_audio.rb        || echo "[post-merge] audio regen skipped"
ruby scripts/build_podcast.rb      || echo "[post-merge] podcast regen skipped"
ruby scripts/build_podcast_artwork.rb || echo "[post-merge] podcast artwork regen skipped"
ruby scripts/build_print.rb        || echo "[post-merge] print regen skipped"
ruby scripts/build_list_bundles.rb || echo "[post-merge] list bundles regen skipped"
