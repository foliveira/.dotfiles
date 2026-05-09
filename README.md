# dotfiles

macOS configs managed with [GNU stow](https://www.gnu.org/software/stow/).
Catppuccin Mocha throughout, JetBrainsMono Nerd Font Mono, Colemak-friendly,
keyboard-first.

---

## Bootstrap

```bash
git clone <this-repo> ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` does, in order:

1. Installs Homebrew if missing.
2. Runs `brew bundle` against the [Brewfile](Brewfile).
3. Backs up any pre-existing files into `~/.dotfiles-backup/<timestamp>/`
   (walks the full per-package tree).
4. Symlinks every package into `$HOME` with `stow -R --no-folding`.
5. Clones [TPM](https://github.com/tmux-plugins/tpm) into `~/.config/tmux/plugins/`.
6. Fetches Catppuccin Mocha themes for bat, eza, and nvim.

After the bootstrap, do the [first-run setup](#first-run-setup).

---

## First-run setup

Once per machine. Order matters — 1Password creates the SSH key whose
public half then goes into `~/.gitconfig.local`.

### 1 — 1Password SSH agent

1. 1Password → Settings → Developer.
2. Enable **Use the SSH agent** and **Integrate with 1Password CLI**.
3. Create or import an SSH key (Ed25519 recommended).
4. On GitHub → Settings → SSH and GPG keys, add the same key twice:
   once as **Authentication Key**, once as **Signing Key**.

The `IdentityAgent` line for 1Password is already in the stowed
`~/.ssh/config`. Anything host-specific (work bastions, alternate
GitHub identities, ProxyJump chains) goes into a gitignored
`~/.ssh/config.local` — copy [`ssh/config.local.example`](ssh/config.local.example)
and fill in.

### 2 — Git identity

```bash
cp git/gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
```

Set `name`, `email`, and paste your 1Password SSH **public** key as
`signingkey` (use 1Password's "Copy Public Key" on the SSH key item).
Signing format, helper program, and `commit.gpgsign = true` are already
in [`git/.gitconfig`](git/.gitconfig).

### 3 — macOS defaults

```bash
bash macos/defaults.sh
```

Sets Finder/Dock/screenshots/animations, switches input source to
**English Colemak only**, enables auto light/dark, disables hot corners,
installs the CapsLock-as-Ctrl LaunchAgent, creates `~/Developer/`.
Logout for the keyboard layout and appearance to fully apply.

The Safari block needs **Full Disk Access** for the calling terminal
(System Settings → Privacy & Security → Full Disk Access). The script
soft-fails on Safari and warns if FDA isn't granted; the rest still
applies.

### 4 — Touch ID for sudo (optional, recommended)

```bash
bash macos/touchid-sudo.sh
```

Enables Touch ID for sudo via `/etc/pam.d/sudo_local` (Sonoma+;
persists across system updates). Installs `pam-reattach` so the prompt
surfaces correctly from inside tmux/screen — without it, sudo silently
falls through to a password prompt.

### 5 — Hostname (optional)

```bash
bash macos/set-hostname.sh "Fabio's MacBook"
```

Sets `HostName`, `LocalHostName` (sanitised for Bonjour), and
`ComputerName`.

### 6 — Personal CLAUDE.md (optional)

```bash
cp claude/CLAUDE.md.example ~/.claude/CLAUDE.md
$EDITOR ~/.claude/CLAUDE.md
```

The committed [`claude/.claude/settings.json`](claude/.claude/settings.json)
carries plugin selections, permissions, and marketplaces — they follow
you across machines. Personal context lives in the gitignored
`~/.claude/CLAUDE.md`.

---

## Tools cheat sheet

Everything below is installed by `./install.sh` and pre-configured.
Configs live in `~/.config/<tool>/`; key bindings called out per tool.

### Terminal & shell

- **Ghostty** — [`config`](shell/.config/ghostty/config).
  Catppuccin Mocha, hidden titlebar with 92% opacity, JetBrainsMono
  Nerd Font Mono 13pt. Auto-launches tmux on startup
  (`command = tmux new-session -A -s main`).
- **zsh** — [`.zshrc`](shell/.zshrc), [`.zprofile`](shell/.zprofile).
  100k history, shared across sessions; `bindkey -e` (emacs).
  Aliases: `g` = git, `ts` = tailscale, `ll`/`la`/`lt` = eza variants,
  `cat` = bat. Sources `~/.localrc` for machine-local secrets.
- **starship** — [`config`](shell/.config/starship.toml).
  Two-line prompt: `dir on branch ✗ via lang` then `❯`. Catppuccin
  Mocha palette block; mauve branch, sky character.

### Multiplexer

- **tmux** — [`config`](shell/.config/tmux/tmux.conf).
  Prefix is **Ctrl-a**. `Ctrl-a Ctrl-a` sends a literal Ctrl-a so
  readline's beginning-of-line still works.
  - `prefix + -` — split horizontal divider (panes stacked).
  - `prefix + /` — split vertical divider (panes side-by-side).
  - `prefix + c` — new window in current path.
  - `prefix + r` — reload config.
  - `prefix + [`, then `v` to start, `y` to yank — copy mode (vi keys),
    yanks to system clipboard via `pbcopy`.
  - `prefix + I` — install plugins (TPM; first time only). Configured:
    sensible, resurrect, continuum. Sessions auto-save every 15 min.

### Editor

- **Zed** — [`settings.json`](shell/.config/zed/settings.json).
  Primary editor. Catppuccin Mocha, JetBrainsMono Nerd Font Mono 13pt,
  vim mode on, format-on-save, 2-space tabs (4 for Python, 4 + tabs
  for Go).
- **Neovim** — [`init.lua`](shell/.config/nvim/init.lua).
  Single-file Lua config for quick edits / commit messages / SSH.
  Catppuccin Mocha colorscheme via nvim's native pack/start.
  - Leader = space.
  - `<space>w` write, `<space>q` quit, `<space>h` clear search.
  - `<C-hjkl>` window navigation.

### Git & GitHub

- **git** — [`.gitconfig`](git/.gitconfig).
  SSH-signed commits via 1Password; `pull.rebase`, `push.autoSetupRemote`,
  `fetch.prune`, `rerere`, histogram diff with moved-block colouring,
  `branch.sort=-committerdate`, `merge.conflictStyle=zdiff3`,
  `tag.sort=version:refname`. Aliases: `co`, `sw`, `st` (short+branch),
  `lg` (graph), `last`.
- **gh** — [`config.yml`](shell/.config/gh/config.yml).
  GitHub CLI. `git_protocol: ssh` so checkouts route through 1Password.
  Aliases: `gh co` (pr checkout), `gh prv`, `gh prl`, `gh prc` (pr create),
  `gh prd`, `gh rv` (review), `gh rw` (run watch), `gh rl`, `gh il`, `gh iv`.
  First time: `gh auth login` and pick SSH.
- **lazygit** — [`config.yml`](shell/.config/lazygit/config.yml).
  TUI for staging hunks, reviewing diffs, interactive rebase. Catppuccin
  Mocha theme; `mainBranches: [master, main]`.

### File / text utilities

- **bat** — [`config`](shell/.config/bat/config).
  Syntax-highlighted `cat`. Aliased so `cat` calls bat. Theme:
  Catppuccin Mocha (fetched by `install.sh`).
- **eza** — theme fetched by `install.sh` to `~/.config/eza/theme.yml`;
  `EZA_CONFIG_DIR` is set so eza reads from there on macOS too.
  Aliases: `ls`, `ll` (`-lah --git`), `la`, `lt` (`--tree --level=2`).
- **fzf** — wired in [`.zshrc`](shell/.zshrc).
  - **Ctrl-T** — file picker (fd backend, bat preview).
  - **Alt-C** — directory picker (eza tree preview).
  - **Ctrl-R** — handed off to atuin.
  - `**<TAB>` — completion trigger.
- **fd** — fast file finder (used by fzf and as a friendlier `find`).
- **ripgrep** — [`ripgreprc`](shell/.config/ripgrep/ripgreprc).
  Default flags: smart-case, hidden, follow, glob excludes for
  `.git/`, `node_modules/`, lockfiles, minified output.
- **jq** / **yq** — JSON / YAML-TOML-XML wrangling.
- **zoxide** — `cd` that learns. `z <fragment>` jumps to a frecency
  match; `zi` is fzf-interactive.

### History / shell helpers

- **atuin** — [`config.toml`](shell/.config/atuin/config.toml).
  Replaces fzf's Ctrl-R with a richer history picker. Compact 25-line
  inline UI, Catppuccin Mocha. One-time: `atuin import zsh`. Cross-machine
  sync (optional): `atuin register` then `atuin login`.
- **direnv** — [`direnvrc`](shell/.config/direnv/direnvrc).
  Per-directory env vars. Custom layouts: `layout python` (stdlib venv),
  `layout uv`, `layout node` (puts `node_modules/.bin` on PATH). First
  time per repo: `direnv allow`.
- **mise** — [`config.toml`](shell/.config/mise/config.toml).
  Language version manager. Picks up `.tool-versions` / `mise.toml`
  per project. `not_found_auto_install = false` — explicit only.

### System utilities

- **btop** — [`btop.conf`](shell/.config/btop/btop.conf).
  Process monitor. Catppuccin Mocha theme.
- **dust** — `du` replacement with a visual tree.
- **duf** — `df` replacement with cleaner output.
- **tealdeer** — [`config.toml`](shell/.config/tealdeer/config.toml).
  Faster `tldr`. Auto-updates the page cache weekly.
- **shellcheck** — lint shell scripts.

### Network / VPN / identity

- **Tailscale** (cask `tailscale-app`) — mesh VPN. Sign in via menu
  bar or `tailscale up`. Tailnet config (ACLs, MagicDNS, SSH) lives
  in [the admin console](https://login.tailscale.com).
- **1Password + 1Password CLI** — SSH agent, secrets manager.
  `op read 'op://Vault/Item/field'` pulls a value at runtime; pairs
  with direnv (see [Project-scoped secrets](#project-scoped-secrets)).

### Apps

- **Ghostty**, **Zed** — see above.
- **Claude Code** (cask `claude-code@latest`) — settings tracked
  in [`claude/.claude/settings.json`](claude/.claude/settings.json).

### Personal scripts

`bin/` is on PATH after install. Currently:

- **`dot`** — sync wrapper. `dot` (= pull + brew bundle + install.sh),
  or `dot pull|brew|install` for individual steps. Auto-detects the
  repo or honours `$DOTFILES`.
- **`new-project <name> [parent]`** — scaffolds `mkdir + git init +
  .gitignore + .envrc + README.md + initial commit`. Parent defaults
  to `~/Developer`.

---

## Repo layout

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
          .config/lazygit/config.yml    → ~/.config/lazygit/
          .config/btop/btop.conf        → ~/.config/btop/
          .config/mise/config.toml      → ~/.config/mise/
          .config/direnv/direnvrc       → ~/.config/direnv/
          .config/tealdeer/config.toml  → ~/.config/tealdeer/
git/      .gitconfig, .gitignore_global → ~/
          gitconfig.local.example       (copy to ~/.gitconfig.local)
ssh/      .ssh/config                   → ~/.ssh/
          config.local.example          (copy to ~/.ssh/config.local)
claude/   .claude/settings.json         → ~/.claude/
          CLAUDE.md.example             (copy to ~/.claude/CLAUDE.md)
bin/      bin/<scripts>                 → ~/bin/
macos/    defaults.sh                          (run manually)
          set-hostname.sh                      (run manually with a name arg)
          touchid-sudo.sh                      (run manually, one-shot)
          com.user.capslock-to-ctrl.plist     (loaded by defaults.sh)
```

`stow -R --no-folding` keeps `~/.config/` (and similar) as a real
directory, so dynamic content (TPM plugins, atuin DB, gh tokens) doesn't
end up inside the dotfiles repo.

---

## Working with the repo

### Edit a config

Files are symlinks, so edits to `~/.config/<tool>/<file>` write
straight back to the dotfiles repo. Just commit when done.

### Add a file to a package

Drop it into `<package>/<path>` mirroring its `$HOME` location, then
re-stow:

```bash
./install.sh        # safe, idempotent
# or:
stow -R --no-folding -t ~ shell git claude ssh bin
```

### Add a new package

1. Create `<pkg>/` at the repo root mirroring the `$HOME` paths you
   want stowed.
2. Add `<pkg>` to `PACKAGES` in [`install.sh`](install.sh).
3. `./install.sh`.

### Remove

```bash
cd ~/.dotfiles
stow -D -t ~ shell git claude ssh bin
```

### Sync a machine

```bash
dot          # git pull + brew bundle + install.sh
dot pull     # just git pull
dot brew     # just brew bundle
dot install  # just install.sh
```

---

## Local overrides

`.zshrc` sources `~/.localrc` if it exists. Put machine-specific
exports, work tokens, or one-off aliases there. It lives outside the
repo, so nothing in the dotfiles can leak it.

---

## Project-scoped secrets

For per-project tokens (database URLs, API keys), use `direnv` + the
1Password CLI rather than baking them into `.localrc` or committing
`.env` files.

In a project directory:

```bash
# .envrc — gitignored
export DATABASE_URL="$(op read 'op://Personal/Project DB/url')"
export OPENAI_API_KEY="$(op read 'op://Personal/OpenAI/api key')"
# Optional: load any non-secret defaults from a checked-in file
dotenv .env.defaults
```

Once: `direnv allow`. Every subsequent `cd` into the project sets the
env vars; `cd` out unsets them. Values never live on disk in plaintext —
`op read` pulls from 1Password each time, authenticating via the SSH
agent integration that handles git signing.

For projects where 1Password isn't in the loop:

```bash
# .envrc
dotenv
```

Reads a gitignored `.env` into the environment when you enter the
directory.

---

## Theme & font

Everything is on **Catppuccin Mocha** + **JetBrainsMono Nerd Font Mono**.
The font ships via `cask "font-jetbrains-mono-nerd-font"`. Distribution:

| Mechanism | Tools |
|---|---|
| Bundled with the tool | Ghostty, Zed, btop, atuin |
| Hex palette inline | lazygit, fzf, tmux, starship |
| Named theme via setting | bat (`Catppuccin Mocha`) |
| Fetched by `install.sh` | bat tmTheme, eza `theme.yml`, nvim colorscheme |

---

## macOS defaults

[`macos/defaults.sh`](macos/defaults.sh) covers:

- **Finder** — pathbar, status bar, list view default, search current
  folder, sort folders first, show extensions, no extension-change
  warning, new windows in `~`.
- **Dock** — autohide instant, no recents, no launch animation, scale
  minimise, 48px tiles, hot corners disabled.
- **Mission Control** — stable space order, group windows by app.
- **Keyboard** — fast repeat, Tab cycles all controls in dialogs,
  Colemak-only input, CapsLock → Ctrl via the LaunchAgent
  ([plist](macos/com.user.capslock-to-ctrl.plist), runs `hidutil`
  on every login).
- **Screenshots** — saved to `~/Screenshots`, no shadow.
- **Window animations** — off; instant resize.
- **Security** — lock immediately on sleep; quarantine prompt off; SSH
  config stows the 1Password agent + ControlMaster.
- **System Update** — auto-check + auto-download; auto-install for
  security updates only.
- **Apps** — Activity Monitor shows all processes sorted by CPU,
  TextEdit defaults to plain text, Disk Utility debug menu, Safari
  developer menu, `~/Library` unhidden.

---

## Notes / gotchas

### tmux + Ghostty

Ghostty advertises `TERM=xterm-ghostty`. The tmux config explicitly
adds it to `terminal-features` so true colour and styled underlines
pass through. `focus-events on` so vim/Zed inside tmux notice focus
signals.

### Catppuccin Mocha for bat / eza / nvim

Not bundled with the upstream tools, so `install.sh` fetches them on
first run:

- bat — `~/Library/Application Support/bat/themes/Catppuccin Mocha.tmTheme`
  + `bat cache --build`.
- eza — `~/.config/eza/theme.yml` (mauve accent variant).
- nvim — `catppuccin/nvim` cloned into `~/.local/share/nvim/site/pack/colors/start/`.

### Backups on first install

If pre-existing files conflict with stow, they're moved to
`~/.dotfiles-backup/<timestamp>/` preserving the relative path. The
backup loop walks the full per-package tree, so nested files (e.g.
`~/.claude/settings.json`) are caught too.

### Touch ID + tmux

`pam_tid.so` alone silently falls through inside tmux because the
prompt can't reach the GUI session. `pam-reattach` (added by
`touchid-sudo.sh`) re-attaches the sudo invocation to the user's GUI
session so Touch ID actually appears.

### Verifying signatures locally

`git log --show-signature` only verifies SSH signatures with an
`allowedSignersFile`:

```bash
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
```

Add `you@example.com ssh-ed25519 AAAA...` lines for each identity you
want to trust. Optional; set up only when you start caring about
verifying others' commits.
