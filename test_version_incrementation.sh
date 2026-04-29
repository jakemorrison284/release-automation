#!/bin/bash

# Test script for version incrementation logic

set -e  # Exit immediately if a command exits with a non-zero status

# Function to increment version based on type
increment_version() {
    local version=$1
    local type=$2
    IFS='.' read -r major minor patch <<< "$version"

    case $type in
        major)
            ((major++))
            minor=0
            patch=0
            ;; 
        minor)
            ((minor++))
            patch=0
            ;;
        patch)
            ((patch++))
            ;;
        *)
            echo "Invalid version type. Use major, minor, or patch."
            exit 1
            ;;
    esac

    echo "$major.$minor.$patch"
}

# Test cases

# Initial version
initial_version="1.2.3"

# Major increment test
major_incremented=$(increment_version "$initial_version" "major")
if [ "$major_incremented" != "2.0.0" ]; then
    echo "Major increment test failed: expected 2.0.0 but got $major_incremented"
    exit 1
fi

# Minor increment test
minor_incremented=$(increment_version "$initial_version" "minor")
if [ "$minor_incremented" != "1.3.0" ]; then
    echo "Minor increment test failed: expected 1.3.0 but got $minor_incremented"
    exit 1
fi

# Patch increment test
patch_incremented=$(increment_version "$initial_version" "patch")
if [ "$patch_incremented" != "1.2.4" ]; then
    echo "Patch increment test failed: expected 1.2.4 but got $patch_incremented"
    exit 1
fi

# Output success message
echo "All version increment tests passed!"