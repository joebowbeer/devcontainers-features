#!/bin/bash
set -ex

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

check_packages ca-certificates curl

echo "Activating feature 'arkade-get'"

curl -sSL "https://raw.githubusercontent.com/alexellis/arkade/refs/heads/master/get.sh" | sh

# Parse CLI tool selections

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
done <<< "$(arkade get -o list)"

if [ -n "$tools" ]; then
    echo "Installing via arkade: $tools"
    echo "$tools" | xargs arkade get --progress=false
    mv ~/.arkade/bin/* /usr/local/bin/
fi
