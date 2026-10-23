#!/usr/bin/env sh
# Downloads the newest Paper server build marked STABLE from the PaperMC Fill API.
PROJECT="paper"
USER_AGENT="minecraft-homelab-project/1.0 (student learning project)"
VERSIONS=$(curl -s -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/${PROJECT} | jq -r '.versions | to_entries[] | .value[]' | sort -V -r)
for VERSION in $VERSIONS; do
  STABLE_URL=$(curl -s -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/${PROJECT}/versions/${VERSION}/builds | jq -r 'map(select(.channel == "STABLE")) | .[0] | .downloads."server:default".url // "null"')
  if [ "$STABLE_URL" != "null" ]; then
    curl -o paper.jar "$STABLE_URL"
    break
  fi
done
