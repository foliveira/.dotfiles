# Dotfiles plan

Third version, 2026-11-22. It replaces the second version (2026-09-30), which
was written for an OrbStack VM and Linux servers that no longer exist. Every
decision below was settled in review; the few still open are listed under
[Open items](#open-items). Each phase is meant to be its own PR.

Tool versions and behaviour quoted here were checked in November 2026. Recheck
anything version-specific at the start of the phase that uses it.

## Machines

| Machine | Role | Install |
|---|---|---|
| Personal laptop (macOS) | Daily work, occasional local agents | full: core, dev, desktop |
| Work laptop (macOS) | Same setup as the personal laptop | full: core, dev, desktop |
| Homelab Mac (macOS) | Hosts the homelab's Docker containers through OrbStack, deployed by doco-cd | core and homelab |
| Paseo container (Debian, on the homelab Mac) | Where most agent work runs | no `install.sh`; the image in the homelab repo pulls selected files from this repo |

The dotfiles are macOS-only. Nothing in this repo branches on Linux.

## Requirements

- R1. Signed commits with the 1Password "Github Signing" key on both laptops,
  with no per-machine key setup. The work laptop's 1Password includes the
  personal account.
- R2. Secrets come from 1Password through fnox, and no repo can reach beyond a
  dedicated dev vault.
- R3. nub replaces npm.
- R4. mise installs what a project declares when you enter it, and those tools
  exist only inside that project.
- R5. tmux stays installed and configured; nothing starts it on its own.
- R6. herdr manages agent sessions on the laptops.
- R7. Agents run directly on a laptop only occasionally, inside Claude Code's
  built-in sandbox. Most agent work runs in the Paseo container.
- R8. Claude Code comes from the official installer.
- R9. One Claude settings base, shared by the laptops and the Paseo container.
- R10. Keybindings suit Colemak where the key's position matters.
- R11. Nothing an agent pushes to GitHub runs on a laptop or deploys to the
  homelab without passing through a laptop.

## Decisions

Settled:

| Topic | Decision |
|---|---|
| Laptop sandbox | Claude Code's built-in sandbox (Seatbelt), set to refuse commands if it can't start. No nono, no wrappers. pi runs unsandboxed on a laptop. |
| herdr | Kept on the laptops. |
| Signer | `op-ssh-sign` stays. One agent path per OS is no longer needed. |
| Identity | Name, noreply email, signing key and `allowed_signers` are tracked. Work-org email rules live in the private companion repo, so org names stay out of this public one. |
| Machine-local config | A private `dotfiles-local` repo, one folder per machine plus `shared/`, linked to `~/.config/local/`. It holds private settings, never secrets. |
| Secrets in local files | None. Secrets stay in 1Password and are read when needed. |
| Leak guard | hk pre-commit in this repo: gitleaks plus a local deny-list of names that must never be committed. |
| Spellcheck | hunspell, with `spellcheck.checker: "auto"` and an explicit `spellcheck.language`. |
| GitHub URLs | `pushInsteadOf`: clone over HTTPS, push over SSH. |
| `dot` | Refuses to apply `master` unless every commit on its first-parent line is signed by a laptop key. Merges into this repo happen on a laptop, `--no-ff` or squash. |
| Upgrades | `dot` installs without upgrading; `dot upgrade` upgrades on purpose. Claude stays on its `latest` channel. pi is installed with nub. |
| nub | Kept. Settings go in `~/.npmrc`. |
| mise | `paranoid = true`, no global tools, 7-day release age, `enter = "mise install --quiet"`. |
| fnox | A dedicated dev vault read through a vault-scoped service account, plus a wrapper that asks again whenever a repo's `fnox.toml` changes. |
| Claude settings | One base in this repo. Laptops merge it in and print drift. The container image applies its own overlay. |
| Per-repo tools | hk, cocogitto and similar tools are declared in each repo's `mise.toml`, never installed globally. |
| Pane keys | a left, r down, s up, w right, in tmux and herdr. |
| tmux clipboard | `set-clipboard external`. |
| macOS appearance | Auto light/dark stays. |
| Quarantine prompt | Stays off. |
| Zed | `trust_all_worktrees` removed. |
| Dropped tools | dust, duf, direnv, nono, gondolin, qemu, the Claude cask, pam-reattach in the Brewfile. |
| Atuin | Syncs to a self-hosted server on the homelab. |

## Design

### Repo layout and tiers

Stow packages: `shell`, `git`, `ssh`, `bin`, `agents` (renamed from `claude`).

Four Brewfiles:

| File | Machines | Contents |
|---|---|---|
| `Brewfile` | all | git, stow, tmux, neovim, starship, fzf, ripgrep, fd, jq, mise, gh, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions |
| `Brewfile.dev` | laptops | nub, fnox, `cask "1password-cli"`, herdr, lazygit, bat, eza, zoxide, atuin, btop, tealdeer, shellcheck, shfmt, yq, uv, git-delta, actionlint, hadolint, watchexec, xh, trash, mas, mactop, hunspell |
| `Brewfile.desktop` | laptops | ghostty, zed, 1password, tailscale-app, font-jetbrains-mono-nerd-font, blockblock, lulu, pearcleaner |
| `Brewfile.homelab` | homelab Mac | orbstack, smartmontools, gdu |

`install.sh` takes a profile: `--full` (default: core, dev, desktop) or
`--homelab` (core, homelab). It writes the profile to
`~/.config/dotfiles/profile` so `dot` reruns the same one.

### Machine-local config

A private repo, `dotfiles-local`, holds what differs per machine or must stay
out of a public repo: work-org git rules, host names, the Atuin server
address, per-host ssh entries. It never holds secrets; those stay in 1Password
and are read when needed (`op read`, `fx`, the Keychain).

```
dotfiles-local/
  shared/       used by both laptops
  personal/
  work/
  homelab/
  denylist      patterns that must never appear in the public repo
```

- `install.sh` clones it next to this repo when missing, then links
  `~/.config/local/` to the machine's folder. The folder name comes from a
  `--machine` flag on first install, recorded with the profile.
- Each folder may contain `gitconfig`, `ssh_config`, `env.zsh`, `tmux.conf`
  and `mise.toml`. The tracked configs include them, with `shared/` loaded
  before the machine's own file:
  - git: `[include]` of `~/.config/local/shared/gitconfig`, then
    `~/.config/local/gitconfig`, both last so they win;
  - ssh: `Include ~/.config/local/ssh_config` first, because ssh keeps the
    first value it sees;
  - zsh: `.zshrc` sources `env.zsh` from both;
  - tmux: `source-file -q` for both, before TPM;
  - mise: links the local `mise.toml` into `~/.config/mise/conf.d/`.
- These replace `~/.gitconfig.local`, `~/.localrc`, `~/.ssh/config.local` and
  `~/.config/tmux/local.conf`.
- `dot` pulls `dotfiles-local` too, with the same signature check as this
  repo.
- `local.example/` in this repo shows every file the companion repo can hold,
  with placeholder values. `dot doctor` lists which ones exist on the machine.
- Like homelab and dotfiles, `dotfiles-local` is left out of the Paseo
  container's GitHub token.

Leak guard, in this repo:
- A `mise.toml` declares hk and gitleaks, following the per-repo tools rule.
- `hk.pkl` runs on pre-commit: gitleaks on staged changes, and a check that
  fails if any pattern from the companion repo's `denylist` appears in staged
  changes. `install.sh` records the companion repo's path in
  `~/.config/dotfiles/local-repo` so the check can find it. The deny-list stays private, so the
  names it protects don't leak through it.
- CI runs gitleaks over the whole history. It can't run the deny-list check.

### Git and signing (R1)

- `git/.config/git/common`: the portable settings (aliases, diff, merge,
  pull, push, rerere, fetch, branch, tag sorting, `rebase.autoStash`,
  `pushInsteadOf`). The Paseo image fetches this file at a pinned commit.
- `git/.gitconfig` includes `common`, then sets what only the laptops use:
  `[user]` with name, noreply email and `signingkey = key::<"Github Signing"
  public key>`; `gpg.ssh.program` set to `op-ssh-sign`; `core.editor`;
  `core.excludesfile`; `gpg.ssh.allowedSignersFile`. It includes the
  companion repo's `gitconfig` files last, so local values win.
- `git/.config/git/allowed_signers` lists only the laptops' signing key. The
  Paseo container's key is deliberately absent, which is what lets `dot` tell
  laptop commits from agent commits.
- `dotfiles-local/shared/gitconfig` holds the work-org `includeIf
  "hasconfig:remote.*.url:..."` rules, matching both URL forms, like the
  container's `/etc/gitconfig`. Both laptops get them.
- On the homelab Mac there is no 1Password, so commits fail to sign and are
  refused. That is intended.
- `ssh/.ssh/config` keeps 1Password's agent socket as `IdentityAgent`, wrapped
  in `Match exec "test -S <socket>"` so ssh still works on the homelab Mac. A
  `Host github.com` block sets `IdentityFile ~/.ssh/github.pub` (the "Github"
  public key, tracked) and `IdentitiesOnly yes`.

### `dot` (R11)

- Finds the repo from its own symlink (`readlink -f`), with `$DOTFILES` as an
  override.
- `dot` (default): `git fetch`, then `git verify-commit` on every commit in
  `git rev-list --first-parent HEAD..origin/master`. If any fails, it stops and
  prints the commit. Otherwise it fast-forwards and runs `install.sh` with
  `brew bundle --no-upgrade`. Tested: a laptop-signed `--no-ff` merge of agent
  commits passes; an agent commit on `master` and a fast-forward onto agent
  commits are both rejected. GitHub's merge button signs with GitHub's key and
  is rejected, so merges happen on a laptop.
- `dot upgrade`: `brew bundle` with upgrades for the profile's Brewfiles,
  `mas upgrade` on the laptops, then `brew autoremove` and `brew cleanup`.
- `dot doctor`: `brew doctor`, a check that the signing key is reachable (on the
  laptops), free disk space with a warning under 15%, and on the homelab
  `smartctl` health for the internal SSD.

### Secrets (R2)

- fnox and `op` from `Brewfile.dev`. No `fnox activate` in the shell.
- Dev secrets move to a dedicated vault. fnox's 1Password provider uses a
  service account scoped to that vault. A provider's `vault` setting does not
  stop full `op://` references, so the scoped account is the control that
  matters. Its token lives in the macOS Keychain and is exported only into
  `fnox exec`.
- `bin/fx`: wraps `fnox exec`. It hashes the repo's `fnox.toml` and asks for
  confirmation when the hash differs from the last approved one (stored under
  `~/.local/state/fx/`). fnox's maintainer declined to add a trust step
  (jdx/fnox#1157), and a project `fnox.toml` can run commands through
  `create_command` and Lua providers.
- `FNOX_PROMPT_AUTH=false` in `.zprofile`.
- direnv goes: the `.zshrc` hook, `shell/.config/direnv/`, `new-project`'s
  `.envrc`.

### Project tools (R3, R4)

mise, in `shell/.config/mise/config.toml`:
- no `[tools]`;
- `paranoid = true` (tested: without it, `mise x` and `mise install` trusted
  an untrusted repo and ran its hooks);
- `minimum_release_age = "7d"`;
- `[hooks] enter = "mise install --quiet"` (tested: it runs on every
  directory change and repeats the trust error inside untrusted repos);
- `idiomatic_version_file_enable_tools = ["node"]`, so mise and nub both read
  `.node-version`;
- `not_found_auto_install = false`.

Editing a trusted `mise.toml`, including through `git pull`, revokes trust
until you run `mise trust` again.

nub:
- `~/.npmrc` (stowed from `shell/`) with `advisoryCheck=required` and the
  7-day release age. nub's `nub.jsonc` release-age keys apply only when nub is
  the project's package manager, so they are not used. Check the exact
  `.npmrc` key names and value format against nubjs.com/docs/config, and test
  that installing a version published today is refused in an npm-lockfile
  project.
- `alias npx=nubx` in `.zshrc`.

Per-repo tools such as hk and cocogitto go in each repo's `mise.toml`.
`new-project` writes `mise.toml` and `fnox.toml` templates and runs
`mise trust` on the `mise.toml` it creates.

### Claude Code and agents (R6 to R9)

- `install.sh` runs the official installer when `~/.local/bin/claude` is
  missing.
- `agents/claude-settings.json` is the shared base (unstowed). It starts from
  the container's `claude-settings.json` in the homelab repo, merged with the
  keys from today's `claude/.claude/settings.json` that still apply. It sets
  `sandbox.enabled: true` and `sandbox.failIfUnavailable: true` (check the key
  path against the sandboxing docs), and `spellcheck.checker: "auto"` with an
  explicit `spellcheck.language`. Claude Code only reads the spellcheck block
  from user settings, which is where the base is merged.
- Spellcheck uses hunspell. Homebrew's formula ships without dictionaries, so
  `install.sh` downloads the chosen LibreOffice dictionaries into
  `~/Library/Spelling`.
- On the laptops, `install.sh` merges the base into `~/.claude/settings.json`
  with jq (base keys win), keeping keys only the machine has, such as herdr's
  hook. Before writing, it prints every key where the machine's value differs
  from the base, so changes made through `/config` can be copied back. If
  `~/.claude/settings.json` is still a stow symlink, it becomes a regular file
  first.
- `agents/CLAUDE.md` holds global agent instructions, stowed to
  `~/.claude/CLAUDE.md` on the laptops and installed in the container as
  `/etc/claude-code/CLAUDE.md`.
- herdr: `brew "herdr"` in `Brewfile.dev`. `agents/.config/herdr/config.toml`
  is stowed with the Colemak keys below. `install.sh` runs
  `herdr integration install claude` and `herdr integration install pi` after
  the settings merge. `.zshrc` loads `herdr completion zsh` when herdr exists.
- pi: `nub add -g @earendil-works/pi-coding-agent`. pi 1.5 needs Node 22.19 or
  later on PATH at run time; see [Open items](#open-items).
  `agents/pi-settings.json` (no `lastChangelogVersion`) is merged into
  `~/.pi/agent/settings.json` like Claude's.

### Keyboard (R10)

| Action | tmux | herdr |
|---|---|---|
| Move to pane left, down, up, right | `prefix` + `a` `r` `s` `w`, repeatable | `prefix` + `a` `r` `s` `w`, and plain `a` `r` `s` `w` in navigate mode |
| Resize pane | `prefix` + `A` `R` `S` `W`, repeatable | resize mode, moved from `prefix + r` to `prefix + m` |
| Session or workspace picker | `prefix + f` | `prefix + f` |
| Settings | | `prefix + comma` |
| Reload config | `prefix + o` | `prefix + shift + r` |
| Kill pane or window without a prompt | `prefix + x`, `prefix + X` | |
| Previous or next window | `prefix + <`, `prefix + >` | |

- Ghostty: `macos-option-as-alt = left`. Under Colemak, Ghostty treats Option
  as a character key by default, so fzf's Alt-C and zsh's Alt shortcuts fail
  today. Right Option keeps the accent layer.
- hjkl stays in vim-style tools, and the prefixes (`C-a` for tmux, `C-b` for
  herdr), Cmd shortcuts and Caps Lock as Ctrl stay as they are.

### Shell and terminal

- `.zprofile`: Homebrew from `/opt/homebrew`, `XDG_CONFIG_HOME`,
  `EDITOR=nvim VISUAL=nvim`, `~/bin` and `~/.local/bin` first with
  `typeset -U path`, `SSH_AUTH_SOCK` untouched, `FNOX_PROMPT_AUTH=false`.
- `.zshrc`: `$HOMEBREW_PREFIX` instead of the fallback; no direnv; no tmux
  auto-start.
- Ghostty: the `command` line goes, so it opens a plain shell.
- tmux: `set -s set-clipboard external`, `clipboard` added to the
  `xterm-ghostty` features, `y` bound to `copy-selection-and-cancel`,
  `source-file -q` of the companion repo's `tmux.conf` files before TPM, `tmux-sensible`
  dropped, the TPM `run` line guarded with `if-shell`.
- Atuin: `sync_address` points at the homelab server. The address goes in
  `dotfiles-local/shared/env.zsh` as `ATUIN_SYNC_ADDRESS`, keeping the homelab
  host name out of the public repo. The atuin key is stored in 1Password.
- git-delta as git's pager, with the Catppuccin Mocha theme.

### macOS settings

- `macos/defaults.sh` (laptops): unchanged apart from the comment fixes in
  Phase 7.
- `macos/homelab.sh` (homelab Mac): `sudo pmset -a sleep 0 disksleep 0
  autorestart 1`, so the machine never sleeps and restarts after a power cut.
- `macos/touchid-sudo.sh` keeps installing pam-reattach itself.

## Phase 1: bugs

Safe on the laptops today.

- [ ] 1.1 `git/.gitconfig`: move the `[include]` of `~/.gitconfig.local` to the
  end so local values override.
- [ ] 1.2 `shell/.zprofile`: export `XDG_CONFIG_HOME="$HOME/.config"` (lazygit
  on macOS ignores `~/.config/lazygit` without it) and
  `EDITOR=nvim VISUAL=nvim`.
- [ ] 1.3 Themes:
  - Zed: `"auto_install_extensions": { "catppuccin": true }`.
  - `install.sh`: fetch btop's `catppuccin_mocha.theme` and atuin's
    `catppuccin-mocha-mauve.toml` when those tools exist.
  - `atuin/config.toml:17`: `name = "catppuccin-mocha-mauve"`.
  - `install.sh:67-77`: drop the bat theme download; bat 0.26 ships Catppuccin.
- [ ] 1.4 `macos/set-hostname.sh:29`: `HostName` uses `$local_name`.
- [ ] 1.5 `bin/bin/dot`: `all` runs pull, then install, instead of running
  `brew bundle` twice. Find the repo through `readlink -f "$0"`.
- [ ] 1.6 `install.sh:41`: `${src#"$DOTFILES/$pkg/"}` (shellcheck SC2295).
- [ ] 1.7 `install.sh:43`: also back up foreign symlinks, so stow doesn't
  abort on them.
- [ ] 1.8 `git/.gitignore_global`: add `.env`, `.env.local`,
  `fnox.local.toml`, `mise.local.toml`.
- [ ] 1.9 `shell/.config/ghostty/config`: `macos-option-as-alt = left`.

Done when: shellcheck is clean, and on a laptop after `./install.sh` the themes
show and `echo $EDITOR` prints `nvim`.

## Phase 2: layout and tiers

- [ ] 2.1 `test/smoke.sh`, written first: stows into a throwaway HOME on macOS
  and checks that a zsh login prints nothing to stderr, `$EDITOR` is `nvim`,
  and a local git value overrides the shared one. Later phases add checks.
- [ ] 2.2 Split the Brewfile into the four files under
  [Repo layout and tiers](#repo-layout-and-tiers). Remove direnv, dust, duf,
  pam-reattach and the `claude-code@latest` cask.
- [ ] 2.3 `install.sh`: `--full` and `--homelab` profiles, recorded in
  `~/.config/dotfiles/profile`; back up `~/.tmux.conf` with the other
  conflicting files; drop the Linux warning.
- [ ] 2.4 Rename the `claude` stow package to `agents`.
- [ ] 2.5 `shell/.config/ghostty/config`: delete the `command` line.
- [ ] 2.6 `shell/.zshrc`: use `$HOMEBREW_PREFIX`.
- [ ] 2.7 Check whether macOS already ships `/usr/bin/trash`. If it does, drop
  the `trash` formula.

Done when: the smoke test passes, and `install.sh --homelab` on the homelab Mac
installs only core and homelab packages.

## Phase 3: git, signing and `dot`

- [ ] 3.1 Split `git/.config/git/common` out of `git/.gitconfig`, and add
  identity, signing key, `allowed_signers`, `rebase.autoStash` and
  `pushInsteadOf`, as under [Git and signing](#git-and-signing-r1).
- [ ] 3.2 `git/.config/git/allowed_signers` with the noreply address and the
  laptops' signing key only.
- [ ] 3.3 Create the private `dotfiles-local` repo with `shared/`,
  `personal/`, `work/`, `homelab/` and `denylist`. Move the contents of each
  machine's `~/.gitconfig.local`, `~/.localrc`, `~/.ssh/config.local` and
  tmux `local.conf` into it, and the work-org `includeIf` rules into
  `shared/gitconfig`. Move any secret values found along the way into
  1Password.
- [ ] 3.4 `install.sh`: clone `dotfiles-local`, link `~/.config/local/`,
  `--machine` flag, and the includes listed under
  [Machine-local config](#machine-local-config). Replace
  `gitconfig.local.example` and `config.local.example` with `local.example/`.
- [ ] 3.5 `ssh/.ssh/config`: `Include ~/.config/local/ssh_config` first;
  `Match exec` guard around `IdentityAgent`; the `Host github.com` block;
  `ssh/.ssh/github.pub`.
- [ ] 3.6 Leak guard: `mise.toml` with hk and gitleaks, `hk.pkl` with the
  gitleaks and deny-list checks.
- [ ] 3.7 `dot`: signature check for this repo and `dotfiles-local`,
  `dot upgrade`, `dot doctor`, as under [`dot`](#dot-r11).
- [ ] 3.8 Smoke test: a throwaway `ssh-agent` and key, `gpg.ssh.program`
  overridden to `ssh-keygen`. A signed commit verifies, and the `dot` check
  accepts a signed merge but rejects an unsigned or wrongly signed commit on
  `master`.

Done when: a commit from each laptop shows as Verified on GitHub, `dot`
refuses a test commit signed with another key, no `*.local` override files
remain in home folders, and a commit containing a deny-listed name is blocked.

## Phase 4: secrets and project tools

- [ ] 4.1 Create the dev vault and its service account. Store the token in the
  Keychain on each laptop.
- [ ] 4.2 `shell/.config/fnox/config.toml` with the 1Password provider using
  the service account; `bin/fx`.
- [ ] 4.3 Remove direnv everywhere. `new-project` writes `mise.toml` and
  `fnox.toml` templates and trusts its `mise.toml`.
- [ ] 4.4 `shell/.config/mise/config.toml` as under
  [Project tools](#project-tools-r3-r4). Fix the `status` comment.
- [ ] 4.5 `~/.npmrc` for nub, and the release-age test.
- [ ] 4.6 `.zshrc`: `alias npx=nubx`.

Done when: `cd ~ && mise ls --current` prints nothing, entering a trusted
project installs its tools, `fx` asks once per `fnox.toml` change, and nub
refuses a version published today.

## Phase 5: Claude, herdr and keys

- [ ] 5.1 `agents/claude-settings.json` and the merge-with-drift step in
  `install.sh`. Claude installed by the official installer.
- [ ] 5.2 `agents/CLAUDE.md` from `claude/CLAUDE.md.example`, filled in.
- [ ] 5.3 herdr config with the Colemak keys; integrations installed after
  the merge.
- [ ] 5.4 pi through nub, and its settings merge.
- [ ] 5.5 tmux: the keys from the table, `set-clipboard external`, OSC 52
  copy, the companion repo's `tmux.conf`, `tmux-sensible` dropped, TPM guarded.
- [ ] 5.6 Smoke test: merge, then herdr integration, then merge again leaves
  exactly one herdr hook and every base key, and the drift report lists a
  changed key.
- [ ] 5.7 On a laptop: bare `claude` runs commands inside the sandbox, and with
  the sandbox made to fail, commands are refused.

Done when: `claude` and `pi` start through herdr with herdr showing their
state, `tmux list-keys -T prefix` shows the new bindings, and herdr accepts its
config with `herdr server reload-config`.

## Phase 6: upkeep and homelab Mac

- [ ] 6.1 `macos/homelab.sh` with the `pmset` settings.
- [ ] 6.2 Run `install.sh --homelab` on the homelab Mac, with the checkout in
  that Mac's home folder, outside `/Volumes/Homelab` (whose subfolders are
  mounted into containers).
- [ ] 6.3 git-delta config; Atuin `sync_address` in
  `dotfiles-local/shared/env.zsh` once the server runs.
- [ ] 6.4 First run of BlockBlock and LuLu on each laptop; allow the expected
  agents and connections.
- [ ] 6.5 starship: `$username$hostname` at the start (shown only over SSH).
- [ ] 6.6 ripgreprc: drop the `dist/`, `build/`, `target/` and `coverage/`
  globs.
- [ ] 6.7 Zed: delete `session.trust_all_worktrees`.
- [ ] 6.8 Optional: `.editorconfig` as the only source of indentation rules.
  Check `:verbose set sw? et?` first.

Done when: `dot doctor` passes on all three Macs.

## Phase 7: docs

- [ ] 7.1 `README.md`: bootstrap per profile; the tier table; a cheat sheet by
  tier; signing and the `dot` check; merging agent branches on a laptop;
  secrets with fnox and `fx`; project tools with mise, nub and per-repo tools;
  Claude settings and drift; herdr; the keyboard table; the companion repo
  and the leak guard; fixes left from the review (theme table, bat
  path, `yq`, the Ghostty tmux line, the `set-hostname` example, the
  "Colemak-friendly" line).
- [ ] 7.2 Code comments that describe old behaviour, including the Zed comment
  in `defaults.sh`.

## Phase 8: CI

- [ ] 8.1 `.github/workflows/ci.yml` on `macos-latest`: shellcheck, shfmt,
  actionlint, gitleaks over the full history, and `test/smoke.sh`.

## Homelab repo changes

These belong in the homelab repo, not this one, and are listed so they aren't
lost. The first item closes R11 for the homelab and should come first.

- [ ] H1. Narrow the Paseo container's GitHub access.
  - Re-register its SSH key on GitHub as a signing key only.
  - Replace `GH_TOKEN` with a fine-grained token that has contents and pull
    request access only to repos where agent pushes are acceptable, excluding
    homelab, dotfiles and dotfiles-local.
  - Push over HTTPS through `gh auth git-credential`. Remove the `insteadOf`
    rewrite from the image's `gitconfig` and update its comments.
  - For homelab and dotfiles, fetch agent branches from the homelab Mac over
    SSH and merge on a laptop.
- [ ] H2. npm in the image: install nub with the same `.npmrc` settings, and
  set `ignore-scripts=true` for plain npm. Agents' install scripts currently
  inherit `GH_TOKEN` and `CLAUDE_CODE_OAUTH_TOKEN`.
- [ ] H3. Fetch `git/.config/git/common` from this repo at a pinned commit
  into `/etc/gitconfig-common`, included by `/etc/gitconfig`. Renovate bumps
  the pin.
- [ ] H4. Fetch `agents/claude-settings.json` at the same pin and apply a
  container overlay with jq at build time (sandbox off, Paseo-specific keys).
  The entrypoint keeps replacing `~/.claude/settings.json` on start.
- [ ] H5. Install `agents/CLAUDE.md` as `/etc/claude-code/CLAUDE.md`.
- [ ] H6. zsh, fzf and starship in the image, zsh as the login shell, and the
  shell files fetched at the same pin. Don't link them from `~/dev`, which
  agents can write.
- [ ] H7. Point Paseo's projects at `/workspace`, and move `~/.npm` and
  `~/.cache` to a volume outside the configs backup.
- [ ] H8. Run an Atuin sync server as a doco-cd service.
- [ ] H9. Free space on the homelab SSD, which was 98% full in November.

## Open items

- `GH_TOKEN` scopes in the container: check them in GitHub's developer
  settings. H1 replaces the token either way; the scopes decide how urgent H1
  is.
- Node for pi on the laptops. pi needs Node 22.19 or later on PATH, and with
  `paranoid`, `mise x node@<pin> -- pi` fails in untrusted repos.
  Recommendation: Homebrew's keg-only `node@24` in `Brewfile.dev`, with `pi`
  started through a small `bin/pi` that puts that Node first on PATH.
- Which hunspell dictionaries to install, and the `spellcheck.language` to
  set. Decide in 5.1.

## Considered and not doing

- Linux support, the OrbStack VM setup, `~/.ssh/rc` and agent forwarding. No
  machine needs them.
- nono and the claude/pi wrappers. Claude's built-in sandbox covers occasional
  laptop runs, and nono can't protect `.git` or config inside a writable
  folder on Linux anyway.
- gondolin. Agents run in the Paseo container.
- Claude's `stable` channel, `brew pin` for pre-1.0 tools, and pi's own
  installer. Declined in favour of upgrading on purpose with `dot upgrade`.
- topgrade. It upgrades everything at once.
- Installing hk, cocogitto and similar tools globally. Their versions belong
  to each repo.
- Dark mode only and turning the quarantine prompt back on.
- The WASD pane layout and `set-clipboard on`.
- Merging into this repo with GitHub's merge button. `dot` would reject it.
- chezmoi. Revisit if a third merged file or more per-machine branching
  appears.
- `fnox activate` in the shell, and the `mise-env-fnox` plugin.
- nub's `node shim` and `pm shim`. They edit rc files and shadow mise.
- A Colemak remap of vim keys, and a different multiplexer prefix.
- Tracking `~/.claude/skills` links. They point at local checkouts.
