# dotfiles

Personal configs for macOS, managed with [GNU stow](https://www.gnu.org/software/stow/).

## Bootstrap

```bash
git clone <this-repo> ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh`:

1. Installs Homebrew if missing.
2. Installs everything in `Brewfile`.
3. Backs up any pre-existing top-level dotfiles into `~/.dotfiles-backup/<timestamp>/`.
4. Symlinks each package into `$HOME` with `stow -R`.

## Layout

```
shell/    .zshrc, .zprofile             → ~/
          .editorconfig                 → ~/
          .config/starship.toml         → ~/.config/
          .config/ghostty/config        → ~/.config/ghostty/
          .config/tmux/tmux.conf        → ~/.config/tmux/
          .config/zed/settings.json     → ~/.config/zed/
          .config/nvim/init.lua         → ~/.config/nvim/
          .config/bat/config            → ~/.config/bat/
          .config/ripgrep/ripgreprc     → ~/.config/ripgrep/
          .config/gh/config.yml         → ~/.config/gh/
          .config/atuin/config.toml     → ~/.config/atuin/
git/      .gitconfig, .gitignore_global → ~/
ssh/      .ssh/config                   → ~/.ssh/
          config.local.example          (copy to ~/.ssh/config.local)
claude/   .claude/settings.json         → ~/.claude/
          CLAUDE.md.example             (copy to ~/.claude/CLAUDE.md)
macos/    defaults.sh                          (run manually)
          set-hostname.sh                      (run manually with a name arg)
          touchid-sudo.sh                      (run manually, one-shot)
          com.user.capslock-to-ctrl.plist     (loaded by defaults.sh)
```

## First-run setup on a new machine

Do these once, after `install.sh`. Order matters — 1Password creates the
SSH key whose public half then goes into `~/.gitconfig.local`.

### 1. 1Password SSH agent

1. Open 1Password → Settings → Developer.
2. Enable **Use the SSH agent** and **Integrate with 1Password CLI**.
3. Create or import an SSH key (Ed25519 recommended).
4. On GitHub → Settings → SSH and GPG keys, add the same key twice:
   once as **Authentication Key**, once as **Signing Key**.
The `IdentityAgent` line for 1Password is already in the stowed
`~/.ssh/config`. Anything host-specific (work bastions, separate
GitHub identities, ProxyJump chains) goes into `~/.ssh/config.local` —
copy `ssh/config.local.example` to `~/.ssh/config.local` and fill in.
That file is gitignored.

### 2. Git identity + signing key

```bash
cp git/gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
```

Set `name`, `email`, and paste your 1Password SSH public key as `signingkey`
(use 1Password's "Copy Public Key" on the SSH key item).

The signing protocol, helper program, and `commit.gpgsign = true` are already
set in the public `git/.gitconfig`.

### 3. macOS defaults

```bash
bash macos/defaults.sh
```

Sets Finder/Dock/screenshots/animations, switches input source to **English
Colemak only** (replaces any existing layouts), enables auto light/dark,
disables hot corners, and creates `~/Developer/`. Logout required for the
keyboard layout and appearance to fully apply.

## Local overrides

`.zshrc` sources `~/.localrc` if it exists. Put machine-specific exports,
work tokens, or one-off aliases there. It lives outside the repo, so nothing
in `~/.dotfiles/` can leak it.

## Updating

Files under `~/.dotfiles/<package>/` are symlinked into `$HOME`, so edits apply
immediately. After adding a new file to a package:

```bash
./install.sh        # or: stow -R --no-folding -t ~ shell git claude ssh
```

## Removing

```bash
cd ~/.dotfiles
stow -D -t ~ shell git claude ssh
```

## Notes

### zsh extras

`shell/.zshrc` conditionally sources `zsh-autosuggestions`,
`zsh-syntax-highlighting`, and `zsh-completions` when they're installed via
Brewfile. The prompt uses `starship` if available and falls back to a plain
zsh prompt otherwise.

CLI helpers wired into `.zshrc` if installed:

- `zoxide` — `z <fragment>` jumps, `zi` is fzf-style interactive.
- `direnv` — runs `.envrc` automatically; first time per repo, `direnv allow`.
- `mise` — picks up `.tool-versions` / `mise.toml` per project and pins
  Node/Python/Ruby/Go versions automatically.
- `atuin` — replaces fzf's Ctrl-R with a richer history picker. Local-only by
  default; for cross-machine sync run `atuin register` then `atuin login`.
- `gh` — first time, `gh auth login` and pick SSH so it routes through your
  1Password agent. Aliases (`gh co`, `gh prv`, `gh prc`, …) defined in
  `~/.config/gh/config.yml`.

`install.sh` also fetches Catppuccin themes for bat once (not bundled
upstream) and rebuilds bat's theme cache. bat then auto-picks the dark or
light Catppuccin variant based on terminal background.

### tmux

Prefix is `Ctrl-a` (pairs naturally with CapsLock-as-Ctrl). `Ctrl-a Ctrl-a`
sends a literal `Ctrl-a` to the inner shell so readline's beginning-of-line
still works.

`install.sh` clones [TPM](https://github.com/tmux-plugins/tpm) into
`~/.config/tmux/plugins/tpm` on first run. Inside a tmux session, hit
`prefix + I` once to fetch the configured plugins (sensible, resurrect,
continuum). Sessions auto-save every 15 min and restore on launch.

### CapsLock → Ctrl

`macos/defaults.sh` installs a LaunchAgent that runs `hidutil` on login to
remap CapsLock to Left Control. It takes effect immediately on the
machine where `defaults.sh` ran, and re-applies on every boot.

### Claude Code

`claude/.claude/settings.json` carries the model/permissions defaults plus
the `enabledPlugins` and `extraKnownMarketplaces` config so plugins follow
across machines. Plugin contents themselves install on first use via
`/plugin`; only the enable/marketplace metadata is committed.

`claude/CLAUDE.md.example` is the personal-instructions template — copy
it to `~/.claude/CLAUDE.md` and fill in. Not stowed; ignored via
`.stow-local-ignore`. State directories under `~/.claude/` (history,
sessions, projects, cache) stay local.

### Tailscale

`cask "tailscale-app"` installs the menu bar app, which also drops the
`tailscale` CLI on PATH. After install, sign in via the menu bar or
`tailscale up`. Tailnet config (ACLs, MagicDNS, SSH) lives in the admin
console at https://login.tailscale.com — nothing in this repo configures
it.

### Verifying signatures locally

`git log --show-signature` only verifies SSH signatures when an
`allowedSignersFile` is configured:

```bash
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
```

Add lines like `you@example.com ssh-ed25519 AAAA...` to that file for each
identity you want to trust. Optional, set up only when you start caring about
verifying others' commits.

### Backups

If pre-existing files conflict with stow on first install, they're moved to
`~/.dotfiles-backup/<timestamp>/`. Only top-level files per package are
caught — nested conflicts surface as stow errors.
