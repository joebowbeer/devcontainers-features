#!/bin/bash
set -euo pipefail

FEATURE_JSON="$(cd "$(dirname "$0")/.." && pwd)/devcontainer-feature.json"

newoptions=$(mktemp)

# NOTE: The arkade version below should match the one specified in install.sh

# Get the list of tools from arkade and build a new options object:
# { "tool": {"type":"string","default":"","description":"tool version"}, ... }
arkade get -o list \
  | jq -R -s '
      split("\n")[:-1] 
      | map(select(length > 0) | select(. != "arkade")) as $tools 
      | reduce $tools[] as $t ({}; .[$t] = {"type":"string","default":"","description": ($t + " version")})
    ' > "$newoptions"

# Update the feature JSON .options = $newopts
cat "$FEATURE_JSON" | jq --slurpfile v "$newoptions" '.options = $v[0]' | tee "$FEATURE_JSON"

echo "Updated options in $FEATURE_JSON with $(jq length "$newoptions") entries."

rm "$newoptions"
