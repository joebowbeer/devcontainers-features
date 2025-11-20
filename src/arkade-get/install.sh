#!/bin/bash
set -e

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

check_packages ca-certificates curl jq

echo "Activating feature 'arkade-get'"

# Install the version of arkade that was used to generate the feature options

_ARKADE_TAG="0.11.59"

curl -sSL "https://raw.githubusercontent.com/alexellis/arkade/refs/tags/$_ARKADE_TAG/get.sh" | sh

# Match the feature options to the environment variables specifying the selected tool versions

tools=""
while IFS= read -r tool; do
    echo "Checking: '$tool'"

    # Map tool to an environment variable name by uppercasing and
    # replacing '-' with '_'. Example: 'my-tool' -> 'MY_TOOL'
    varname="${tool^^}"
    varname="${varname//-/_}"

    # Use the transformed name when looking up the version specifier
    version="${!varname}"

    if [ "$version" = "latest" ]; then
        tools="$tools $tool"
    elif [ -n "$version" ]; then
        tools="$tools $tool@$version"
    fi
done <<< "$(jq -r '.options | keys[]' devcontainer-feature.json)"

if [ -n "$tools" ]; then
    echo "Installing via arkade: $tools"
    echo "$tools" | xargs arkade get --progress=false
    chmod +x ~/.arkade/bin/*
    mv ~/.arkade/bin/* /usr/local/bin/
fi
