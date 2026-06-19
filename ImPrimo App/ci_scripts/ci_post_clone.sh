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

# Set up local gem environment for user-space installation
export GEM_HOME=$HOME/.gem
export PATH=$GEM_HOME/bin:$PATH

# Add standard Homebrew paths just in case it is installed but not in PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if command -v pod >/dev/null 2>&1; then
    echo "CocoaPods is already installed."
else
    echo "CocoaPods not found. Installing..."
    
    if command -v brew >/dev/null 2>&1; then
        echo "Installing CocoaPods via Homebrew..."
        export HOMEBREW_NO_AUTO_UPDATE=1
        brew install cocoapods
    else
        echo "Homebrew not found. Installing CocoaPods via Gem..."
        gem install cocoapods --user-install --no-document
    fi
fi

# Run pod install
echo "Installing project dependencies..."
pod install
