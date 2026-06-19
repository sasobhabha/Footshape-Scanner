#!/bin/sh

# Prevent script from continuing if any command fails
set -e

# Navigate to the directory containing the Podfile
cd "$CI_PRIMARY_REPOSITORY_PATH/ImPrimo App"

# Avoid homebrew auto update to save build time
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Installing CocoaPods via Homebrew..."
brew install cocoapods

echo "Installing dependencies via CocoaPods..."
pod install
