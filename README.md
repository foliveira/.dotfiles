# dotfiles

Settings for my Macs, linked into place with
[GNU stow](https://www.gnu.org/software/stow/). The theme is Catppuccin Mocha,
the font is JetBrainsMono Nerd Font Mono, and the keyboard layout is Colemak.

## Machines and profiles

There are three Macs. Each one uses a profile:

| Mac | Profile | Brewfiles | Stow packages |
|---|---|---|---|
| Personal laptop | `--full` | `Brewfile`, `Brewfile.dev`, `Brewfile.desktop` | `shell git ssh bin agents` |
| Work laptop | `--full` | the same | the same |
| Homelab Mac (runs the Docker containers) | `--homelab` | `Brewfile`, `Brewfile.homelab` | `shell git ssh bin` |

- `Brewfile` (core): git, git-delta, stow, tmux, neovim, starship, fzf, rg, fd,
  jq, mise, gh and the zsh plugins.
- `Brewfile.dev`: tools for coding and agents.
- `Brewfile.desktop`: apps with a window, and the font.
- `Brewfile.homelab`: OrbStack, smartmontools and gdu.

The Paseo container on the homelab Mac does not use this repo directly. The
homelab repo copies a few files from it at a fixed commit (see
[PLAN.md](PLAN.md#homelab-repo-changes)).

## Set up a new Mac

```bash
git clone git@github.com:foliveira/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --full --machine personal --local-repo <URL of dotfiles-local>
```

On the homelab Mac, use `--homelab --machine homelab`. Keep the clone in the
home folder, not in `/Volumes/Homelab`, whose folders are mounted into
containers.

`install.sh` is safe to run again. It saves the profile and machine in
`~/.config/dotfiles/profile`, so later runs need no flags. It does this:

1. Installs Homebrew if it is missing.
2. Runs `brew bundle` for the profile's Brewfiles. It installs what is
   missing and does not upgrade anything (`dot upgrade` does that).
3. Moves files that are in the way to `~/.dotfiles-backup/<time>/`.
4. Links the stow packages into `$HOME` with `stow -R --no-folding`.
5. Links the private config repo (see [Private settings](#private-settings)).
6. Adds nub's safety settings to `~/.npmrc` (laptops).
7. On the laptops: installs Claude Code, merges the Claude and pi settings,
   downloads the hunspell dictionaries, installs pi and the herdr hooks.
8. Installs TPM and downloads the Catppuccin themes that tools don't ship.

## First run on a laptop

Do these once, in this order.

1. **1Password.** Settings, Developer: turn on "Use the SSH agent" and
   "Integrate with 1Password CLI". `~/.ssh/config` already uses the agent.
2. **GitHub key.** The "Github" key in 1Password logs in to GitHub and signs
   commits. Its public half is already in `git/.gitconfig`,
   `git/.config/git/allowed_signers` and `ssh/.ssh/github.pub`. On GitHub it
   must be added twice: as an authentication key and as a signing key.
3. **macOS settings.** `bash macos/defaults.sh`, then log out. The Safari part
   needs Full Disk Access for the terminal; the rest works without it.
4. **Touch ID for sudo** (optional). `bash macos/touchid-sudo.sh`. It also
   installs pam-reattach, so Touch ID works inside tmux.
5. **Name** (optional). `bash macos/set-hostname.sh work-mbp`.
6. **Logins.** `gh auth login` (pick SSH), `claude`, and `atuin login` once
   the homelab Atuin server runs.
7. **Firewall apps.** Open BlockBlock and LuLu once and allow what you expect.
8. **This repo's hooks.** In `~/.dotfiles`: `mise trust && mise install &&
   hk install`.

On the homelab Mac, run `bash macos/homelab.sh` instead of `defaults.sh`. It
stops the Mac from sleeping and turns it on again after a power cut.

## Keep Macs in step: `dot`

| Command | What it does |
|---|---|
| `dot` | Checks the signatures of new commits, pulls this repo and the private repo, and runs `install.sh`. |
| `dot upgrade` | `dot`, and also upgrades Homebrew packages and App Store apps, then cleans up. |
| `dot doctor` | Checks Homebrew, the signing key, disk space, SSD health (homelab) and private files. |
| `dot trust` | Shows commits that failed the check and applies them if you say yes. |
| `dot install` | Runs `install.sh` without pulling. |

### The signature check

Agents in the Paseo container can push to GitHub, so `dot` does not trust
GitHub. Before it pulls, it checks every commit on master's main line (the
first parent of each merge). Each one must be signed by a key in
`git/.config/git/allowed_signers`. Only the laptops' key goes in that file.

So agent work reaches master only through a merge made on a laptop:

```bash
git fetch origin agent-branch
git merge --no-ff origin/agent-branch   # signed by 1Password
git push
```

A fast-forward, a commit made in the container, and GitHub's merge button all
fail the check. If that happens, read the commits and run `dot trust`.

While `allowed_signers` has no keys, `dot` skips the check and warns.

## Secrets: fnox and `fx`

Secrets stay in 1Password. A project lists the ones it needs in `fnox.toml`:

```toml
[secrets]
DATABASE_URL = { provider = "op", value = "My App/database-url" }
```

Run a command with them:

```bash
fx -- nub run dev
```

`fx` reads the token for the 1Password "Dev" vault from the macOS Keychain
and passes it to `fnox exec`. A `fnox.toml` can run commands, so `fx` asks
before it uses a new or changed one. Answers are kept in
`~/.local/state/fx/approved`. `fx --approve` approves without running
anything.

Store the token once. It is a 1Password service account token for the Dev
vault:

```bash
security add-generic-password -s fnox-dev-vault -a "$USER" -w
```

`FNOX_PROMPT_AUTH=false` stops fnox from running a login command from a
project file. Secrets are never written to `.env` files.

## Project tools: mise, nub and per-repo tools

- **mise** installs the tools a project lists in `mise.toml` when you `cd`
  into it. Nothing is installed globally. It runs in `paranoid` mode: a new or
  changed `mise.toml` does nothing until you run `mise trust`. Releases
  younger than 7 days are not installed. mise reads `.node-version` too.
- **nub** replaces npm. `~/.npmrc` has `advisoryCheck=required` and
  `minimumReleaseAge=7d`. `npx` is an alias for `nubx`, which skips install
  scripts. `npm login` still writes its token to `~/.npmrc`, which is why
  that file is not in this repo.
- **hk, cocogitto, gitleaks and similar** belong to each repo, pinned in its
  `mise.toml`. This repo does that for hk, gitleaks, shellcheck, shfmt and
  actionlint.
- **`new-project <name> [parent]`** makes a folder (in `~/Developer` by
  default) with git, a `.gitignore`, `mise.toml`, `fnox.toml`, a README and a
  first commit.

## Agents

### Claude Code

`agents/claude-settings.json` is one set of settings for the laptops and the
container. It is not linked. `install.sh` merges it into
`~/.claude/settings.json`:

- Keys in the repo win.
- Keys only the Mac has (herdr's hooks, for example) stay.
- Before writing, it prints each key whose value on the Mac is different. If
  you changed something in `/config` and want to keep it, copy it into the repo
  file.

The settings turn on Claude's sandbox and refuse to run commands if the sandbox
can't start. Spellcheck uses hunspell with the en_US dictionary.

`agents/.claude/CLAUDE.md` holds the instructions for every session. It is
linked to `~/.claude/CLAUDE.md`.

Claude Code comes from the official installer and updates itself.

### pi

pi is installed with nub. It needs Node 22.19 or later, so `bin/pi` starts it
with Homebrew's `node@24`, which is not on `PATH` otherwise. Its settings come
from `agents/pi-settings.json`, merged like Claude's.

### herdr

herdr runs and watches agent sessions. Its settings are in
`agents/.config/herdr/config.toml`. `install.sh` adds herdr's hooks for Claude
and pi. Reload the settings with `herdr server reload-config`.

## Keyboard

Pane keys follow Colemak: `a` left, `r` down, `s` up, `w` right. The tmux
prefix is `Ctrl-a`. The herdr prefix is `Ctrl-b`.

| Action | tmux | herdr |
|---|---|---|
| Move to a pane | `prefix` + `a` `r` `s` `w` (press again without the prefix) | `prefix` + `a` `r` `s` `w`; plain `a` `r` `s` `w` in navigate mode |
| Resize a pane | `prefix` + `A` `R` `S` `W` | resize mode: `prefix + m` |
| Pick a session or workspace | `prefix + f` | `prefix + f` |
| Settings | | `prefix + ,` |
| Reload settings | `prefix + o` | `prefix + shift + r` |
| Close pane / window, no question | `prefix + x` / `prefix + X` | |
| Previous / next window | `prefix + <` / `prefix + >` | |
| Split | `prefix + -` (one above the other), `prefix + /` (side by side) | |
| New window | `prefix + c` | |

- In tmux copy mode (`prefix + [`), `v` starts and `y` copies. tmux sends the
  copy to Ghostty (OSC 52), which puts it on the macOS clipboard. This works
  over SSH too.
- In Ghostty the left Option key is Alt, so fzf's Alt-C and zsh's Alt keys
  work. The right Option key still types accents.
- Vim-style tools keep hjkl. Caps Lock is Ctrl.

## Tools

### Every Mac (core)

- **zsh**: [`.zshrc`](shell/.zshrc), [`.zprofile`](shell/.zprofile). Emacs
  keys, shared 100k history. Aliases: `g` git, `ts` tailscale, `ll`, `la`,
  `lt` (eza), `cat` (bat), `npx` (nubx).
- **starship**: [`starship.toml`](shell/.config/starship.toml). Two lines:
  folder, branch and language, then the prompt. User and host show over SSH.
- **tmux**: [`tmux.conf`](shell/.config/tmux/tmux.conf). Keys above. Plugins
  (press `prefix + I` the first time): resurrect and continuum, which save
  sessions every 15 minutes.
- **Neovim**: [`init.lua`](shell/.config/nvim/init.lua). One file for quick
  edits. Leader is space: `<space>w` save, `<space>q` quit, `<space>h` clear
  search. `Ctrl-h/j/k/l` move between windows.
- **git**: [`.gitconfig`](git/.gitconfig) and
  [`common`](git/.config/git/common). Commits and tags are signed with the
  1Password SSH key. delta shows diffs. Pull rebases, push sets the upstream,
  and pushes to `https://github.com/` go over SSH. Aliases: `co`, `sw`, `st`,
  `lg`, `last`.
- **gh**: [`config.yml`](shell/.config/gh/config.yml). Uses SSH. Aliases:
  `co` (check out a PR), `prv`, `prl`, `prc`, `prd`, `rv`, `rw`, `rl`, `il`,
  `iv`.
- **fzf**: Ctrl-T finds files (fd, with a bat preview), Alt-C changes folder
  (eza preview), `**<Tab>` completes. Ctrl-R goes to atuin.
- **rg**: [`ripgreprc`](shell/.config/ripgrep/ripgreprc). Smart case, hidden
  files, follows links, skips `.git`, `node_modules`, lock files and minified
  files. It also skips what `.gitignore` lists.
- **fd**, **jq**, **mise**.

### Laptops (dev and desktop)

- **Ghostty**: [`config`](shell/.config/ghostty/config). Opens a plain shell.
- **Zed**: [`settings.json`](shell/.config/zed/settings.json). The main
  editor. Vim mode, format on save, installs the Catppuccin extension.
- **lazygit**: [`config.yml`](shell/.config/lazygit/config.yml). Stage parts
  of files, read diffs, rebase.
- **bat**, **eza**, **zoxide** (`z name` jumps to a folder you use often),
  **yq** (jq for YAML).
- **atuin**: [`config.toml`](shell/.config/atuin/config.toml). History search
  on Ctrl-R, synced to the homelab server. The server address is in the
  private repo. The sync key is in 1Password.
- **btop**, **mactop** (Apple Silicon power and heat), **tealdeer** (`tldr`).
- **shellcheck**, **shfmt**, **actionlint**, **hadolint**: linters for shell,
  GitHub Actions and Dockerfiles.
- **watchexec** (run a command when files change), **xh** (HTTP requests),
  **uv** (Python tools), **trash** (delete to the Trash), **mas** (App Store).
- **1Password** and its CLI, **Tailscale**.
- **BlockBlock** warns when something adds a launch agent or login item.
  **LuLu** asks before a program connects out. **Pearcleaner** removes apps
  and the files they leave.

### Homelab Mac

- **OrbStack** runs the homelab's Docker containers.
- **smartmontools** (`smartctl`) checks the SSD; `dot doctor` uses it.
- **gdu** shows what fills the disk.

## Private settings

Private settings (work email rules, host names, the Atuin server)
live in a second, private repo: `dotfiles-local`, cloned next to this one.
Secrets don't go there either; they stay in 1Password.
[`local.example/`](local.example/README.md) shows the layout with fake values.

`install.sh --machine NAME` links:

- `~/.config/local` to `dotfiles-local/NAME/`
- `~/.config/local-shared` to `dotfiles-local/shared/`

git, ssh, zsh, tmux and mise read files from those folders when they exist.
`dot` pulls and checks that repo too.

### Leak guard

This repo's pre-commit hook (hk) runs gitleaks, shellcheck and shfmt. It also
reads `dotfiles-local/denylist`, a list of patterns such as work org names and
internal host names, and refuses a commit that adds a line matching one.

## Repo layout

```
shell/    .zshrc .zprofile .editorconfig        -> ~/
          .config/<tool>/...                    -> ~/.config/<tool>/
git/      .gitconfig .gitignore_global          -> ~/
          .config/git/common, allowed_signers   -> ~/.config/git/
ssh/      .ssh/config                           -> ~/.ssh/
bin/      bin/dot fx new-project pi             -> ~/bin/
agents/   .claude/CLAUDE.md                     -> ~/.claude/
          .config/herdr/config.toml             -> ~/.config/herdr/
          claude-settings.json pi-settings.json (merged by install.sh)
lib/      scripts used by install.sh, dot and the hooks
macos/    defaults.sh homelab.sh touchid-sudo.sh set-hostname.sh (run by hand)
local.example/  example of the private repo
test/     smoke.sh: stows into an empty HOME and checks the result
```

`--no-folding` makes stow link files, never whole folders. Files that tools
write later (TPM plugins, the atuin database, gh tokens) stay out of the repo.

To change a setting, edit the file in `~/.config`. It is a link into this
repo, so commit the change here. To add a file, put it in the package at the
same path it has under `$HOME` and run `./install.sh`. To add a package, add it
to `PACKAGES` in `install.sh`.

## Theme and font

| How the tool gets Catppuccin Mocha | Tools |
|---|---|
| Ships with the tool | Ghostty, bat (0.26 and later) |
| Installed by the tool | Zed (extension) |
| Colours written in the config | tmux, starship, lazygit, fzf |
| Downloaded by `install.sh` | btop, atuin, eza, Neovim |

The font comes from `cask "font-jetbrains-mono-nerd-font"`.

macOS switches between light and dark by itself. The terminal tools and Zed
stay on Catppuccin Mocha.

## macOS settings

[`macos/defaults.sh`](macos/defaults.sh) sets:

- Finder: path and status bars, list view, search in the current folder,
  folders first, all file extensions.
- Dock: hides at once, no recent apps, no launch bounce, 48 px icons, no hot
  corners.
- Keyboard: fast key repeat, Tab moves through all controls, Colemak only,
  Caps Lock as Ctrl (a launch agent runs `hidutil` at login).
- Screenshots go to `~/Screenshots`, without shadows.
- Lock at once on sleep. No quarantine prompt for downloaded apps.
- Security updates install by themselves.
- Activity Monitor, TextEdit, Disk Utility and Safari developer options.
  `~/Library` is visible.

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on macOS:
shellcheck, shfmt, actionlint, gitleaks over the whole history, and
`test/smoke.sh`.

## License

Public domain. See [LICENSE](LICENSE).
