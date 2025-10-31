#!/bin/bash
set -euo pipefail

FEATURE_JSON="$(cd "$(dirname "$0")/.." && pwd)/devcontainer-feature.json"

newoptions=$(mktemp)

# Install a specific version of arkade to list the available tools.
# The install script will install this same version.

_ARKADE_TAG="${_ARKADE_TAG:-"0.11.54"}"

arkade get arkade@"$_ARKADE_TAG" --progress=false >/dev/null 2>&1 || {
    echo "Failed to install arkade version $_ARKADE_TAG"
    exit 1
}

# Get the list of tools from arkade and build a new options object:
# { "tool": {"type":"string","default":"","description":"tool version"}, ... }
~/.arkade/bin/arkade get -o list \
  | jq -R -s '
      split("\n")[:-1] 
      | map(select(length > 0) | select(. != "arkade")) as $tools 
      | reduce $tools[] as $t ({}; .[$t] = {"type":"string","default":"","description": ($t + " version")})
    ' > "$newoptions"

# Update the feature JSON .options = $newopts
cat "$FEATURE_JSON" | jq --slurpfile v "$newoptions" '.options = $v[0]' | tee "$FEATURE_JSON"

echo "Updated options in $FEATURE_JSON with $(jq length "$newoptions") entries."

rm "$newoptions"
