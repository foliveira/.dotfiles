#!/usr/bin/env bash
# Run once per machine. Reference: https://macos-defaults.com
set -e

if [[ "$(uname)" != "Darwin" ]]; then
    echo "macOS only." >&2
    exit 1
fi

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"     # search current folder by default
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Save / print panels expanded by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Keyboard
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false      # repeat on hold

# Screenshots
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# Opinionated extras — uncomment to enable.
# defaults write com.apple.dock autohide -bool true
# defaults write com.apple.dock show-recents -bool false
# defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

killall Finder Dock SystemUIServer 2>/dev/null || true
echo "Done. Some changes need a logout/restart."
