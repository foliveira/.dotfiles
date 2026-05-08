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
          .config/starship.toml         → ~/.config/
          .config/ghostty/config        → ~/.config/ghostty/
          .config/tmux/tmux.conf        → ~/.config/tmux/
          .config/zed/settings.json     → ~/.config/zed/
          .config/nvim/init.lua         → ~/.config/nvim/
git/      .gitconfig, .gitignore_global → ~/
macos/    defaults.sh                          (run manually)
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
5. To route all SSH (not just git) through the 1Password agent, add to
   `~/.ssh/config`:

   ```
   Host *
       IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
   ```

   `~/.ssh/config` is intentionally not in this repo — host-specific entries
   tend to be sensitive. If you want it stowed later, ask.

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
./install.sh        # or: stow -R --no-folding -t ~ shell git
```

## Removing

```bash
cd ~/.dotfiles
stow -D -t ~ shell git
```

## Notes

### zsh extras

`shell/.zshrc` conditionally sources `zsh-autosuggestions`,
`zsh-syntax-highlighting`, and `zsh-completions` when they're installed via
Brewfile. The prompt uses `starship` if available and falls back to a plain
zsh prompt otherwise.

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
