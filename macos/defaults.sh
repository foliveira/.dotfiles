#!/usr/bin/env bash
# Run once per machine. Reference: https://macos-defaults.com
set -e

if [[ "$(uname)" != "Darwin" ]]; then
    echo "macOS only." >&2
    exit 1
fi

# Finder
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf" # search current folder by default
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv" # list view by default
defaults write com.apple.finder NewWindowTarget -string "PfHm"      # open new windows in ~
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Save / print panels expanded by default; new docs save locally, not iCloud.
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Keyboard
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool true # press-and-hold accent picker

# CapsLock → Left Control. Persists via a LaunchAgent that runs hidutil at login.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plist_src="$DOTFILES_DIR/macos/com.user.capslock-to-ctrl.plist"
plist_dst="$HOME/Library/LaunchAgents/com.user.capslock-to-ctrl.plist"
mkdir -p "$(dirname "$plist_dst")"
cp "$plist_src" "$plist_dst"
launchctl unload "$plist_dst" 2>/dev/null || true
launchctl load "$plist_dst"

# Screenshots
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location "$HOME/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock launchanim -bool false               # no bounce on app launch
defaults write com.apple.dock expose-animation-duration -float 0.1 # faster Mission Control
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

# Skip Gatekeeper's "this app was downloaded from the internet" prompt. Trades
# a small phishing-protection layer for fewer interruptions on trusted sources.
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Require password immediately on sleep / screensaver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Skip Time Machine prompt for new disks
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Software Update + App Store — auto-check, auto-download, auto-apply security
# updates. Full OS upgrades still require manual confirmation.
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
defaults write com.apple.commerce AutoUpdate -bool true

# Mission Control — keep space order stable, group windows by app.
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock expose-group-apps -bool true

# Tab cycles through every control in dialogs, not just text fields.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Activity Monitor — show all processes, sort by CPU descending.
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# TextEdit defaults to plain text, UTF-8.
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Disk Utility — debug menu + advanced image options.
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

# Safari — developer menu. Safari's prefs live in a sandboxed container, so
# the calling terminal needs Full Disk Access (System Settings → Privacy &
# Security → Full Disk Access → enable Ghostty/Terminal). Soft-fail otherwise.
(
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
) 2>/dev/null || echo "warning: Safari defaults write blocked — grant Full Disk Access to your terminal to enable." >&2

# Show ~/Library — devs need it visible.
chflags nohidden "$HOME/Library" 2>/dev/null || true

# Developer folder for projects
mkdir -p "$HOME/Developer"

# Appearance: macOS switches between light and dark by itself. Ghostty, Zed
# and the terminal tools stay on Catppuccin Mocha either way.
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

killall Finder Dock SystemUIServer cfprefsd "Activity Monitor" Safari 2>/dev/null || true
echo "Done. Some changes need a logout/restart."
