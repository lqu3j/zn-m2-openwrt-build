#!/bin/bash
set -euo pipefail

# Include local configuration/scripts and all upstream branches in the fingerprint.
# Only successful builds persist it, so failed builds are retried next schedule.
remote_revision() {
  local url="$1" branch="$2" revision
  revision=$(git ls-remote --exit-code "$url" "refs/heads/$branch" | awk 'NR == 1 {print $1}')
  [ -n "$revision" ] || { echo "Missing upstream branch: $url $branch" >&2; return 1; }
  printf '%s %s %s\n' "$url" "$branch" "$revision"
}

SOURCE_STATE=$(remote_revision "$REPO_URL" "$REPO_BRANCH")
FEED_STATE=$(
  while read -r type name source _; do
    [[ "$type" == src-git ]] || continue
    if [[ "$source" != *';'* ]]; then
      echo "Feed $name must specify a branch: $source" >&2
      exit 1
    fi
    remote_revision "${source%;*}" "${source##*;}" || exit 1
  done < "$FEEDS_CONF"
)
LOCAL_REVISION=$(git rev-parse HEAD)
FINGERPRINT=$(printf '%s\n' "$LOCAL_REVISION" "$SOURCE_STATE" "$FEED_STATE" | sha256sum | awk '{print $1}')
STORED_FINGERPRINT=$(cat /tmp/zn-m2-upstream-cache/fingerprint 2>/dev/null || true)

SHOULD_BUILD=false
if [[ "${GITHUB_EVENT_NAME:-schedule}" == workflow_dispatch || "$FINGERPRINT" != "$STORED_FINGERPRINT" ]]; then
  SHOULD_BUILD=true
fi

echo "Source/feed/config fingerprint: $FINGERPRINT (build: $SHOULD_BUILD)"
echo "should_build=$SHOULD_BUILD" >> "$GITHUB_OUTPUT"
echo "upstream_fingerprint=$FINGERPRINT" >> "$GITHUB_OUTPUT"
