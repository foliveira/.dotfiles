#!/usr/bin/env bash
# Run once per machine. Reference: https://macos-defaults.com
set -e

if [[ "$(uname)" != "Darwin" ]]; then
    echo "macOS only." >&2
    exit 1
fi

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool false           # toggle on demand with ⇧⌘.
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
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool true       # press-and-hold accent picker

# Screenshots
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock launchanim -bool false                    # no bounce on app launch
defaults write com.apple.dock expose-animation-duration -float 0.1      # faster Mission Control
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock tilesize -int 48

# Hot corners — disable all four (corner=0, modifier=0)
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 0
defaults write com.apple.dock wvous-br-modifier -int 0

# Window animations
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Don't write .DS_Store on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Require password immediately on sleep / screensaver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Skip Time Machine prompt for new disks
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Developer folder for projects
mkdir -p "$HOME/Developer"

# Appearance — auto switch light/dark with sunrise/sunset
defaults delete NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true
defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true

# Keyboard layout — Colemak only. Last so a HIToolbox failure only affects this block.
(
    defaults write com.apple.HIToolbox AppleEnabledInputSources -array \
        '{InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 12825; "KeyboardLayout Name" = Colemak;}'
    defaults write com.apple.HIToolbox AppleSelectedInputSources -array \
        '{InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 12825; "KeyboardLayout Name" = Colemak;}'
    defaults write com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID -string "com.apple.keylayout.Colemak"
) || echo "warning: failed to set Colemak layout — set manually in System Settings → Keyboard." >&2

killall Finder Dock SystemUIServer cfprefsd 2>/dev/null || true
echo "Done. Some changes need a logout/restart."
