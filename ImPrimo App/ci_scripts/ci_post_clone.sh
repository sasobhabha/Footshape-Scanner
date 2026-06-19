#!/bin/sh

# Prevent script from continuing if any command fails
set -e

# Determine where the Podfile is and navigate to it
if [ -f "Podfile" ]; then
    echo "Found Podfile in current directory."
elif [ -f "ImPrimo App/Podfile" ]; then
    echo "Found Podfile in ImPrimo App subdirectory. Navigating there..."
    cd "ImPrimo App"
else
    echo "Could not find Podfile. Checking repository path..."
    if [ -n "$CI_PRIMARY_REPOSITORY_PATH" ] && [ -d "$CI_PRIMARY_REPOSITORY_PATH/ImPrimo App" ]; then
        cd "$CI_PRIMARY_REPOSITORY_PATH/ImPrimo App"
    else
        echo "Error: Podfile directory not found."
        exit 1
    fi
fi

# Avoid homebrew auto update to save build time
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Installing CocoaPods via Homebrew..."
brew install cocoapods

echo "Installing dependencies via CocoaPods..."
pod install
