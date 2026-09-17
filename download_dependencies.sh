#!/usr/bin/env bash

# Sourcing would apply set -e and the exit traps to the caller's SSH shell.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    printf 'Run this script with bash, not source: bash "%s"\n' "${BASH_SOURCE[0]}" >&2
    # Return success so even callers using set -e keep their current session.
    return 0
fi

set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
THIRDPARTY_DIR="$PROJECT_ROOT/3rdparty"
EXTRACT_DIR=""

cleanup() {
    if [[ -n "$EXTRACT_DIR" && -d "$EXTRACT_DIR" ]]; then
        rm -rf -- "$EXTRACT_DIR"
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for tool in curl tar mktemp; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Error: required command not found: %s\n' "$tool" >&2
        exit 1
    fi
done

mkdir -p -- "$THIRDPARTY_DIR"

download_dependency() {
    local directory="$1"
    local url="$2"
    local destination="$THIRDPARTY_DIR/$directory"
    local archive="$THIRDPARTY_DIR/$directory.tar.gz"

    if [[ -f "$destination/CMakeLists.txt" ]]; then
        printf 'Skipping %s (already present).\n' "$directory"
        return
    fi
    if [[ -e "$destination" || -L "$destination" ]]; then
        printf 'Error: %s exists but has no CMakeLists.txt; move it aside before retrying.\n' "$destination" >&2
        exit 1
    fi

    printf 'Downloading %s...\n' "$directory"
    if curl --fail --location --show-error --retry 3 --connect-timeout 30 \
        --output "$archive" "$url"; then
        :
    else
        local status=$?
        printf 'Error: download failed for %s (curl exit code %s). Run this script again to retry.\n' "$directory" "$status" >&2
        return "$status"
    fi

    # Extract into a temporary directory so failed extraction cannot leave a
    # partially installed dependency. Each upstream archive has one root folder.
    EXTRACT_DIR="$(mktemp -d "$THIRDPARTY_DIR/.extract.XXXXXX")"
    printf 'Extracting %s...\n' "$directory"
    tar -xzf "$archive" -C "$EXTRACT_DIR" --strip-components=1
    if [[ ! -f "$EXTRACT_DIR/CMakeLists.txt" ]]; then
        printf 'Error: %s does not contain a top-level CMakeLists.txt.\n' "$archive" >&2
        exit 1
    fi

    mv -- "$EXTRACT_DIR" "$destination"
    EXTRACT_DIR=""
    rm -- "$archive"
    printf 'Installed %s\n' "$destination"
}

# Directory names must match src/CMakeLists.txt.
download_dependency "pybind11-3.1.0" \
    "https://github.com/pybind/pybind11/archive/refs/tags/v3.1.0.tar.gz"
download_dependency "eigen-3.4.1" \
    "https://gitlab.com/libeigen/eigen/-/archive/3.4.1/eigen-3.4.1.tar.gz"
download_dependency "yaml-cpp-yaml-cpp-0.9.0" \
    "https://github.com/jbeder/yaml-cpp/archive/refs/tags/yaml-cpp-0.9.0.tar.gz"

printf 'All C++ dependencies are ready.\n'
