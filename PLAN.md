# Dotfiles plan

Second version, 2026-09-30, with Colemak keybindings added on 2026-10-01. It
adds your requirements from the review follow-up (1Password signing everywhere,
fnox, nub, project-scoped mise, no tmux auto-start, herdr, nono and gondolin for
Claude and pi, Claude from the official installer, this VM's Claude settings,
Colemak). The requirements come first, then the
design that meets them, the open decisions, and the phases in order. Each phase
is meant to be its own commit.

What changed from the first version:

- Signing no longer depends on a per-OS signer path. Every machine exposes its
  agent at `~/.1password/agent.sock` and git signs with `ssh-keygen`.
- direnv goes. mise `[env]` covers per-project variables and fnox covers
  secrets.
- Ghostty no longer launches tmux, and nothing else does either.
- The `claude` stow package becomes `agents`. Claude and pi settings are merged
  into place, not symlinked, because herdr and the apps write into them.
- New phases for signing and secrets (4) and for agents and sandboxes (5).
- Keyboard: pane movement in tmux and herdr moves to a Colemak key cluster, and
  Ghostty's left Option becomes Alt. Vim-style keys stay as they are.

What gets verified where:

- In an Ubuntu 24.04 aarch64 container here: shellcheck, `test/smoke.sh` and a
  full `install.sh` run.
- On this VM: signing through the forwarded 1Password agent, and nono with real
  Claude and pi sessions.
- On the Mac, by you: anything macOS. The checks are under [Rollout](#rollout).

## Requirements

- R1. Signed commits with your 1Password keys work on every machine once
  1Password is unlocked, with no per-machine key setup. Design: Signing and SSH.
  Checked by the smoke test (throwaway agent), on this VM and on the Mac.
- R2. Secrets come from 1Password through fnox. Design: Secrets.
- R3. nub replaces npm for Node projects. Design: Tools, Node and project scope.
- R4. mise installs what a project declares when you enter it, and those tools
  only exist inside that project. Same section. Checked by the smoke test
  (`mise ls --current` in `~` is empty).
- R5. tmux stays installed and configured but never starts on its own.
- R6. herdr manages agent sessions. Design: Agents and sandboxes.
- R7. Claude and pi run inside nono or gondolin, with secure defaults. Same
  section.
- R8. Claude Code comes from the official installer, not Homebrew.
- R9. This VM's `~/.claude/settings.json` becomes the tracked Claude settings.
- R10. Keybindings suit Colemak where the key's position matters. Design:
  Keyboard.

## Design

### Signing and SSH (R1)

Findings that shape this:

- OrbStack already forwards the Mac's 1Password agent into this VM at
  `/opt/orbstack-guest/run/host-ssh-agent.sock`. Checked: it lists "Github",
  "Github Signing" and three other keys.
- This VM doesn't use that socket. It runs its own `ssh-agent` with two keys
  stored on disk (`~/.ssh/id_ed25519_github*`, comments `...@vm`), started by
  `~/.ssh/agent-wrapper.sh` from `.bashrc`.
- The 1Password agent only runs where the desktop app runs. Headless machines
  have to get it by agent forwarding.
- `ssh-keygen -Y sign` works through any agent that holds the key, so git
  doesn't need `op-ssh-sign`.

The design:

- One agent path on every machine: `~/.1password/agent.sock`.
  - macOS: `install.sh` links it to 1Password's socket; 1Password documents
    this link.
  - Linux desktop with the 1Password app: the app creates it.
  - OrbStack VM: `install.sh` links it to the forwarded host socket.
  - Headless server: a stowed `~/.ssh/rc` links it to the forwarded socket at
    each SSH login. It only replaces a missing path or an existing link, never
    a real 1Password socket, and does nothing on macOS. Forwarding is turned on
    per host in `~/.ssh/config.local` on the Mac (`ForwardAgent yes`), never
    for `Host *`.
- `.zprofile` exports `SSH_AUTH_SOCK=~/.1password/agent.sock` when the path
  exists, and `~/.ssh/config` sets `IdentityAgent ~/.1password/agent.sock` for
  `Host *`.
- git signs with `ssh-keygen`, git's default, so `gpg.ssh.program` goes away
  and the shared gitconfig has no OS-specific lines. GUI apps on macOS that
  don't load your shell environment can use 1Password's documented
  `SSH_AUTH_SOCK` LaunchAgent (step 4.4). Zed loads the shell environment, so
  it doesn't need it.
- Identity lives in the repo (D9): name, the GitHub noreply address this VM
  already commits with, `user.signingkey = key::<"Github Signing" public key>`,
  and a committed `allowed_signers` so `git log --show-signature` works. All of
  it is public already: GitHub serves signing keys to anyone.
- github.com uses one key: `Host github.com`, `IdentityFile ~/.ssh/github.pub`
  (the "Github" public key, committed), `IdentitiesOnly yes`. The agent holds
  five keys, and this stops ssh offering them one by one.
- `~/.gitconfig.local` stays as an optional override (for example a work email
  via `includeIf`), included last.

### Secrets (R2)

fnox (jdx, v1.36, 1.0 since Oct 2025) resolves secrets from 1Password with
`op read`/`op inject` and hands them to a process. Project files (`fnox.toml`)
hold only `op://` references and are committed. `fnox.local.toml` is for
per-machine overrides and is gitignored.

- Install `fnox` and `op` from Homebrew. The `1password-cli` cask installs on
  Linux too. Don't install fnox through mise: `fnox activate` writes a
  versioned binary path into the shell hook.
- Secure default: no `fnox activate` in `.zshrc`. fnox has nothing like
  `direnv allow`, so a hook would load whatever a freshly cloned repo's
  `fnox.toml` asks for as soon as you `cd` into it. Secrets reach a process
  only through `fnox exec -- <cmd>`, or a mise task that wraps it
  (`run = "fnox exec -- nub run dev"`). `FNOX_PROMPT_AUTH=false` stops a repo's
  `auth_command` from running.
- On desktops, `op` uses the 1Password app, which asks for Touch ID or your
  password. On headless machines it needs its own sign-in (D11).
- direnv is removed. mise `[env]` covers the non-secret part (`_.file`,
  `_.path`, `_.python.venv`), and mise itself calls its direnv integration
  deprecated.

### Tools, Node and project scope (R3, R4)

mise (v2026.9.17) never installs just because you `cd`. A global
`[hooks] enter = "mise install"` makes it install on entry. mise also trusts
the active config automatically when it runs `install`, `exec` or `run`, so the
hook alone would trust every repo you enter. `paranoid = true` turns that off
and ties trust to each file's contents.

Global `~/.config/mise/config.toml`:

- No `[tools]` table, so nothing is active outside a project.
- `paranoid = true`, and `minimum_release_age = "7d"` (the default is 24h).
- `[hooks] enter = "mise install"`.
- A cloned repo needs `mise trust` once before anything installs, the same step
  as `direnv allow` today.
- PATH activation (`mise activate zsh`), no shims.
- Checked by `cd ~ && mise ls --current` printing nothing.

How the hook behaves in an untrusted project under `paranoid` isn't documented.
Step 4.9 tests it in a container before we rely on it.

nub (nubjs/nub, v0.9.5; Colin McDonnell; pre-1.0, one main maintainer) replaces
npm, npx and npm scripts.

- Homebrew formula `nub`, bottles for both OSes.
- It writes back in the project's existing lockfile format
  (`package-lock.json`, `pnpm-lock.yaml`, `bun.lock`), so collaborators are
  unaffected.
- Its defaults are good:
  - dependency build scripts need approval;
  - releases younger than 24h are skipped (this is why a test install picked pi
    0.87.1 over 0.99.1, which came out yesterday);
  - OSV malware advisories are checked;
  - provenance downgrades are refused.
- Changes to its defaults, in a stowed `~/.config/nub/nub.jsonc`: set
  `advisoryCheck` to `required`, so installs fail when the OSV check can't run
  (it lets them through otherwise), and match the 7-day release age.
- `alias npx=nubx`: nubx prefers local bins, asks before fetching and skips
  lifecycle scripts. npm stays available through mise's Node for projects that
  need it.
- nub reads the Node version from `.node-version`, `.nvmrc` or `engines`, not
  from `mise.toml`. If the Node on PATH (mise's) doesn't satisfy that, nub
  quietly downloads its own. Keep a project's pins consistent, and don't run
  `nub node shim` or `nub pm shim`: they edit rc files and shadow mise.

Global Node CLIs (pi, gondolin) need a `node` on PATH at run time. Tested: nub's
global bins start with `#!/usr/bin/env node`. D13 decides where that Node comes
from. The recommendation keeps it off PATH by having the wrappers run through
`mise x node@<pin> --`.

### Agents and sandboxes (R5 to R8)

tmux: stays in the core tier with its config, and nothing starts it. Ghostty's
`command` line goes, and no shell hook replaces it.

herdr (herdrdev/herdr v0.9.3, Rust, pre-1.0; this VM runs 0.8.2 from the curl
installer) is a terminal workspace manager that tracks agent state per pane.

- Install with `brew "herdr"` on both OSes.
- Stow `~/.config/herdr/config.toml`: your current file plus
  `[session] resume_agents_on_restore = false`. On restore herdr re-runs bare
  `claude --resume ...` or `pi --session ...`, which would bring a sandboxed
  agent back unsandboxed.
- `install.sh` runs `herdr integration install claude` and
  `herdr integration install pi`. The hook files are herdr's to manage, so the
  repo doesn't track them. Tested: the Claude integration adds its own
  absolute-path hook to `~/.claude/settings.json`, writes through a symlink,
  and is idempotent.
- herdr's prefix defaults to `ctrl+b` and tmux uses `C-a`, so they don't clash.

Claude Code:

- Installed with `curl -fsSL https://claude.ai/install.sh | bash`, which never
  prompts, into `~/.local/bin/claude`, with auto-updates on the `latest`
  channel. The Homebrew cask goes.
- Settings: this VM's file becomes `agents/claude-settings.json`, with three
  changes:
  - the herdr hook is dropped, because herdr adds its own per machine;
  - `sandbox.enabled` becomes `true`, so a bare run still gets Claude's own
    sandbox (D12);
  - the nono wrapper turns Claude's sandbox off for runs inside nono, because
    nesting fails.
- `install.sh` merges the base into `~/.claude/settings.json` with `jq`. Base
  keys win, and keys only the machine has (herdr's hook, plugin toggles) stay.
  It isn't a symlink, because herdr and Claude Code write into this file.
  Tested: herdr's write went straight into the tracked copy.
- `spellcheck.checker = "aspell"` needs aspell, so the Brewfile gains it.

pi (earendil-works/pi, v0.99.1; this VM runs 0.83.0 from npm under nvm):

- Installed with `nub add -g @earendil-works/pi-coding-agent`, run under the
  D13 Node. Tested in a container: this works, and the release-age gate
  applies.
- Settings: this VM's `~/.pi/agent/settings.json` without
  `lastChangelogVersion`, merged into place like Claude's. pi rewrites that
  file itself. `enableInstallTelemetry` stays `false`.
- `auth.json` (API keys, OAuth) is never tracked. The OpenRouter key moves into
  1Password, and the pi wrapper has nono inject it at launch, so it isn't
  stored on disk.

nono (nolabs-ai/nono v0.78, Landlock on Linux, Seatbelt on macOS; pre-1.0,
recent breaking changes) is the everyday sandbox on both OSes.

- Install with `brew "nono"`.
- Tracked profiles `claude-strict` and `pi-strict` extend the maintained packs
  `nolabs-ai/claude` and `nolabs-ai/pi`.
- The packs deny `~/.ssh`, cloud credentials, `~/.config/op`, 1Password
  directories, shell rc and history files, and browser data. They grant
  nothing else in home beyond each agent's own config. Network and environment
  are open by default, and the profiles close both:
  - Network: nono's `minimal` list (model APIs), plus the four domains your
    Claude sandbox already allows (`github.com`, `*.github.com`,
    `*.githubusercontent.com`, `registry.npmjs.org`), plus `openrouter.ai` for
    pi.
  - Environment: an allowlist (PATH, HOME, USER, SHELL, TERM, LANG, LC_*,
    TMPDIR, SSH_AUTH_SOCK). `HERDR_*` isn't on it, so herdr's hooks exit
    quietly inside the sandbox.
  - Unix sockets: only the agent socket (`~/.1password/agent.sock` and its
    target). On Linux this needs `af_unix_mediation: pathname`; on macOS proxy
    mode already limits socket connects. This blocks the tmux and herdr server
    sockets, which an agent could otherwise use to run commands outside the
    sandbox.
  - Filesystem additions: the dotfiles repo read-only (every stowed config is
    a symlink into it) and mise's installs read-only. The OrbStack host paths
    (`/Users`, `/mnt/mac`, `/opt/orbstack-guest/run` apart from the agent
    socket) stay ungranted.
- Git inside: agents can commit and sign through the agent socket, and 1Password
  approves each new session. They can't push: SSH port 22 and `known_hosts`
  aren't granted, so you push from outside.
- Wrappers: `~/bin/claude` and `~/bin/pi` shadow the real binaries.
  - Each sets `HERDR_AGENT=<name>` so herdr still recognises the agent, then
    runs it under nono.
  - `CLAUDE_UNSANDBOXED=1` or `PI_UNSANDBOXED=1` runs the real binary directly,
    still with Claude's own sandbox.
  - A sandboxed session can write `~/.claude`, so it could plant hooks that run
    on the next unsandboxed start. Step 5.4 tries to make `settings*.json` and
    `hooks/` read-only inside the sandbox. If nono can't express that,
    unsandboxed runs stay a deliberate exception.
- Known issues to check first:
  - an open bug where Claude reports "Not logged in" under nono 0.78 on macOS;
  - on this kernel (Landlock ABI 8), nono mediates pathname sockets itself,
    with a small race window.

gondolin (earendil-works/gondolin 0.12, QEMU micro-VMs; the project calls itself
experimental) is the stronger, opt-in sandbox: `claude-vm` and `pi-vm`.

- Mac first: QEMU runs on Apple's hypervisor there. This VM has no `/dev/kvm`,
  because OrbStack can't nest KVM on Apple Silicon, so gondolin falls back to
  emulation. The wrappers warn on Linux without `/dev/kvm`.
- Install: `brew "qemu"`, then `nub add -g @earendil-works/gondolin` under a
  Node of at least 23.6 that avoids 24.17 and 24.18 (an open bug breaks guest
  POST requests there). The first run downloads a ~200 MB guest image.
- Claude needs a custom Alpine image with git, libgcc, libstdc++ and ripgrep,
  with Claude added by the official installer. The image config is tracked.
  Building it on macOS needs Docker, which OrbStack provides.
- The launcher is a small tracked SDK script. The CLI can't give the VM more
  than 1 GiB, and Claude needs 4 GiB. It sets:
  - `--mount-hostfs "$PWD:/workspace"`;
  - exact `--allow-host` entries (the same list as nono);
  - `--disable-websockets`;
  - the Claude token as a `--host-secret` placeholder, so the real value never
    enters the VM;
  - no SSH access, so no push.
- Commits: the VM has no signing key and signed commits fail there (D14).
  Agents leave changes uncommitted and you commit on the host.
- pi: pi's own gondolin extension keeps pi on the host and runs its tools in
  the VM. The tracked copy adds an egress allowlist, which the example doesn't
  have. It's loaded with `pi -e` from `pi-vm`, not from the auto-load
  directory.
- Known issues, noted in the README:
  - writes through the host mount can leave stale bytes after a truncation
    (open bug);
  - no HTTP/2 or UDP;
  - `/root` in the guest is temporary.

### Keyboard (Colemak, R10)

Your laptops type Colemak; on macOS, `defaults.sh` makes it the only input
source. A binding needs adapting when it was chosen for where the keys sit.
Bindings chosen for the letter stay as they are.

Adapted:

- Pane movement in tmux and herdr moves to one left-hand Colemak cluster (D7),
  the same in both tools, and the arrow keys keep working.
  - This VM's tmux already does this with a/r/s/w. herdr still uses its default
    h/j/k/l.
  - The recommended layout is the physical WASD shape on Colemak: w up, a left,
    r down, s right.

  | Action | tmux | herdr |
  |---|---|---|
  | Move to pane up, left, down, right | `prefix` + `w` `a` `r` `s`, repeatable | `prefix` + `w` `a` `r` `s`, and plain `w` `a` `r` `s` in navigate mode |
  | Resize pane | `prefix` + `W` `A` `R` `S`, repeatable | resize mode, moved from `prefix + r` to `prefix + m` |
  | Session or workspace picker | `prefix + f` (was `s` and `w`) | `prefix + f` (was `w`) |
  | Settings | | `prefix + comma` (was `s`) |
  | Reload config | `prefix + o`, as on this VM | `prefix + shift + r`, unchanged |

- Ghostty: set `macos-option-as-alt = left`.
  - Ghostty's source says it treats Option as Alt by default only for the U.S.
    Standard and U.S. International layouts.
  - Under Colemak, Option types characters instead. fzf's Alt-C (in the README)
    and zsh's Alt-b, Alt-f and Alt-. all fail today.
  - With `left`, the left Option key is Alt, and right Option keeps Colemak's
    accent and symbol layer.
- Linux laptops, if you have one: `linux/keyboard.sh` sets Colemak and Caps Lock
  as Ctrl, matching what `macos/defaults.sh` does. VMs and servers need nothing,
  because the layout comes from the machine you type on.

Kept, and why:

- hjkl in vim-style tools (nvim, Zed's vim mode, lazygit, less, tmux copy mode).
  These tools share one grammar. The positional Colemak remap (h n e i) would
  push search-next (n), end-of-word (e) and insert (i) onto other keys in every
  one of them. Nothing on this VM or in the repo remaps vim, so the plan doesn't
  start.
- Bindings chosen for the letter: tmux `c`, `x`, `z`; herdr `c`, `n`, `p`, `v`;
  nvim's `<leader>w`, `q` and `h`. They follow the letter wherever it is.
- The prefixes, tmux `C-a` and herdr `C-b`. a and b sit in the same place on
  Colemak.
- macOS Cmd shortcuts. z, x, c and v don't move on Colemak.
- Caps Lock as Ctrl. `hidutil` remaps the physical key, not a letter.

### Files that apps write to

These are merged into place from a tracked base, so machine-written keys stay
on the machine:
- `~/.claude/settings.json`;
- `~/.pi/agent/settings.json`.

These stay symlinked, because the apps rarely write to them:
- Zed `settings.json` (watch it in `git status`);
- gh `config.yml`;
- herdr `config.toml`;
- mise, nub and fnox configs.

## Decisions

The phases assume the recommended option. D6 is settled; everything else is
open.

Carried over from the first version:

- D1, Linux package manager. Recommended: Homebrew on Linux with the same
  Brewfiles. Every formula has an aarch64 Linux bottle (checked). apt would
  mean handling `batcat`/`fdfind` and an fzf too old for the config.
- D2, appearance. Recommended: dark everywhere, with macOS auto light/dark
  turned off.
- D3, quarantine prompt. Recommended: back on (drop `LSQuarantine false`).
- D4, Zed `trust_all_worktrees`. Recommended: remove it.
- D5, tool cuts. Recommended: drop dust and duf.
- D6, Claude settings. Settled: this VM's file (R9).
- D7, pane keys on Colemak, the same in tmux and herdr. This VM's tmux has a
  for left, r for down, s for up and w for right. On Colemak the physical WASD
  shape is w up, a left, r down, s right, so your s and w look swapped.
  - Recommended: the WASD shape, with the table under Keyboard.
  - Other options: keep your current mapping, or vim order on the home row
    (a r s t for left, down, up, right).
  - Either way, port the VM's `x`/`X` (kill pane or window without a prompt)
    and `<`/`>` (cycle windows), with reload on `prefix + o`.
- D8, GitHub over SSH. Recommended: `pushInsteadOf` only. A global `insteadOf`
  would break HTTPS clones during bootstrap, before 1Password is signed in.

New:

- D9, identity in the public repo. Recommended: yes. That means name, the
  noreply email, the signing and GitHub public keys, and `allowed_signers`.
  None of it is private, and it's what makes R1 work without setup.
- D10, retire this VM's on-disk keys. Recommended: yes, once signing through
  the forwarded 1Password agent is verified here. You then remove the two
  `...@vm` keys from GitHub and delete the files. Nothing is deleted before you
  confirm.
- D11, secrets on headless machines. For this VM, recommended:
  `eval "$(op signin)"` when you need secrets. The session expires after 30
  idle minutes and leaves no token on disk. For unattended servers: a 1Password
  service account scoped to a dedicated vault. Service accounts can't see
  Private vaults, and they have rate limits.
- D12, Claude's own sandbox on for bare runs. Recommended: yes. This changes
  one value in your VM settings (`sandbox.enabled`). Inside nono the wrapper
  turns it off.
- D13, Node for pi and gondolin. Recommended: the wrappers run them through
  `mise x node@<pin> --`, so no Node is on PATH outside projects. Alternative: a
  global Node in mise's config, which is simpler but active in every project
  that doesn't pin its own.
- D14, commits from sandboxed agents. Recommended:
  - under nono, agents commit and sign but can't push;
  - under gondolin, they don't commit, and you commit on the host.

## Phase 1: bugs

Safe on the Mac today.

- [ ] 1.1 `git/.gitconfig`: move the `[include]` of `~/.gitconfig.local` to the
  end so local values override. Tested: at the top it can't override anything.
- [ ] 1.2 `shell/.zprofile`: export `XDG_CONFIG_HOME="$HOME/.config"` (lazygit
  on macOS ignores `~/.config/lazygit` without it) and
  `EDITOR=nvim VISUAL=nvim`.
- [ ] 1.3 Themes:
  - Zed: add `"auto_install_extensions": { "catppuccin": true }`.
  - `install.sh`: fetch btop's `catppuccin_mocha.theme` and atuin's
    `catppuccin-mocha-mauve.toml` when those tools are installed.
  - `atuin/config.toml:17`: `name = "catppuccin-mocha-mauve"`.
  - `install.sh:67-77`: drop the bat theme download, since bat 0.26 ships
    Catppuccin.
- [ ] 1.4 `macos/set-hostname.sh:29`: `HostName` uses `$local_name`.
- [ ] 1.5 `bin/bin/dot`: `all` runs pull, then install (not `brew bundle`
  twice).
- [ ] 1.6 `install.sh:41`: `${src#"$DOTFILES/$pkg/"}` (shellcheck SC2295).
- [ ] 1.7 `git/.gitignore_global`: add `.env`, `.env.local`,
  `fnox.local.toml`, `mise.local.toml`.
- [ ] 1.8 `shell/.config/ghostty/config`: `macos-option-as-alt = left`. Under
  Colemak, Ghostty leaves Option as a character key, so fzf's Alt-C and zsh's
  Alt shortcuts don't work. Right Option still types accents.

Done when: shellcheck is clean. On the Mac after `./install.sh`, the themes
show and `echo $EDITOR` prints `nvim`.

## Phase 2: macOS/Linux split

`install.sh` is the only file that branches on the OS. Shell files detect what
exists at runtime.

- [ ] 2.1 `test/smoke.sh`, written first, so it fails on today's config. It
  stows into a throwaway HOME and checks that:
  - a zsh login prints nothing to stderr;
  - `$EDITOR` is `nvim`;
  - a local git value overrides the shared one.

  Later phases add signing, mise and settings-merge checks. Run it with
  `box -r --with stow,zsh,git,openssh-client docker.io/library/ubuntu:24.04 bash /work/test/smoke.sh`.
- [ ] 2.2 `shell/.zprofile`:
  - On Linux, source `/etc/profile`. zsh doesn't read it, and that's where
    OrbStack adds its PATH entries (`pbcopy`, `open`, `code`, `mac`) and where
    the locale fix lives.
  - Find Homebrew under `/opt/homebrew`, `/usr/local` or
    `/home/linuxbrew/.linuxbrew`.
  - Put `~/bin` and `~/.local/bin` first, with `typeset -U path`. zsh doesn't
    read `~/.profile`, so `~/.local/bin` (claude, box) needs adding here.
  ```zsh
  [[ $OSTYPE == linux* && -r /etc/profile ]] && emulate sh -c '. /etc/profile'
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      [[ -x $brew_bin ]] && { eval "$("$brew_bin" shellenv)"; break; }
  done
  unset brew_bin
  typeset -U path
  path=(~/bin(N/) ~/.local/bin(N/) $path)
  ```
- [ ] 2.3 `shell/.zshrc`:
  - First line: `[[ -o login ]] || source ~/.zprofile`, so IDE terminals get the
    same PATH.
  - Replace the `brew_prefix` fallback (lines 12-16) with `$HOMEBREW_PREFIX`.
  - No tmux auto-start (R5).
- [ ] 2.4 `shell/.config/ghostty/config`: delete `command` (lines 5-7). Ghostty
  opens a plain shell.
- [ ] 2.5 `shell/.config/tmux/tmux.conf`:
  - Copy over OSC 52: `set -s set-clipboard on`, add `clipboard` to the
    `xterm-ghostty` terminal features, and bind `y` to
    `copy-selection-and-cancel`. That replaces `pbcopy`, and it also works over
    SSH.
  - Add `source-file -q ~/.config/tmux/local.conf` before the TPM line.
- [ ] 2.6 `Brewfile`: wrap the macOS-only casks in `if OS.mac?` and remove
  `pam-reattach`, which `touchid-sudo.sh` installs itself. `1password-cli`
  stays outside the guard, since it installs on Linux too.
- [ ] 2.7 `install.sh`:
  1. Detect the OS.
  2. On Linux, check Homebrew's prerequisites (zsh, git, curl, file, ps, a C
     compiler). If any is missing, print
     `sudo apt-get install -y build-essential procps curl file git zsh` and
     exit.
  3. Install and load Homebrew.
  4. `brew bundle`.
  5. Back up conflicting files, plus `~/.tmux.conf`: tmux reads it before
     `~/.config/tmux/tmux.conf`.
  6. Stow.
  7. Remind you to run `chsh` if the login shell isn't zsh.

Done when: the smoke test passes in Ubuntu 24.04, and a full `install.sh` run
in a container as a non-root user leaves a zsh that starts cleanly.

## Phase 3: must-haves and nice-to-haves

- [ ] 3.1 `Brewfile`, always installed:
  - Core: git, stow, tmux, neovim, starship, fzf, ripgrep, fd, jq, mise, nub,
    fnox, gh, herdr, nono, aspell, and `cask "1password-cli"`.
  - macOS desktop block: ghostty, zed, 1password, tailscale-app, orbstack
    (uncommented), the font.
  - Removed: direnv (replaced by mise and fnox), the `claude-code@latest` cask
    (R8), dust and duf (D5).
- [ ] 3.2 `Brewfile.extras`: bat, eza, zoxide, atuin, lazygit, btop, tealdeer,
  shellcheck, yq, uv, the three zsh plugins, and qemu (for gondolin).
- [ ] 3.3 `install.sh --minimal` or `DOTFILES_MINIMAL=1` skips the extras, TPM,
  the extras' themes and gondolin. `dot` passes arguments through.

Done when: `install.sh --minimal` in the container installs only the core.

## Phase 4: signing, SSH, secrets, project tools

- [ ] 4.1 Agent path (R1):
  - `install.sh` links `~/.1password/agent.sock`. On macOS it links 1Password's
    socket. On Linux it links the OrbStack socket, when that socket exists and
    the path is missing or already a link.
  - New `ssh/.ssh/rc` does the same with a forwarded `$SSH_AUTH_SOCK` at SSH
    login. It does nothing on macOS and never replaces a real socket.
  - `.zprofile` exports `SSH_AUTH_SOCK` when the path exists.
- [ ] 4.2 `ssh/.ssh/config`:
  - `IdentityAgent ~/.1password/agent.sock` for `Host *`.
  - A `Host github.com` block with `IdentityFile ~/.ssh/github.pub` and
    `IdentitiesOnly yes`.
  - New `ssh/.ssh/github.pub`, the "Github" public key.
  - `ssh/config.local.example`: fix the comment (ssh keeps the first value, and
    this file is included first) and add a per-host `ForwardAgent yes`
    example.
- [ ] 4.3 git (D9):
  - `git/.gitconfig` gets `[user]` with name, noreply email and
    `signingkey = key::...`, the "Github Signing" key, read with `ssh-add -L`
    (public key only).
  - It gets `gpg.ssh.allowedSignersFile = ~/.config/git/allowed_signers`, and
    the `[gpg "ssh"] program` line goes.
  - New `git/.config/git/allowed_signers` holding the noreply address and that
    key. This VM's current file lists your gmail address, which doesn't match
    the commit email.
  - `gitconfig.local.example` shrinks to optional overrides.
  - `rebase.autoStash = true` and `pushInsteadOf` (D8).
- [ ] 4.4 macOS, optional: install 1Password's documented `SSH_AUTH_SOCK`
  LaunchAgent from `defaults.sh`, so every GUI app uses the 1Password agent.
- [ ] 4.5 Smoke test: a throwaway `ssh-agent` bound at `~/.1password/agent.sock`
  holding a test key. A commit is signed with `ssh-keygen`, and
  `git log --show-signature` verifies it against a test `allowed_signers`.
- [ ] 4.6 fnox (R2):
  - Stow `~/.config/fnox/config.toml` with a shared 1Password provider, so
    projects only list secrets.
  - `.zprofile`: `export FNOX_PROMPT_AUTH=false`. No `fnox activate`.
- [ ] 4.7 Remove direnv:
  - `.zshrc` hook, `shell/.config/direnv/`, the Brewfile entry.
  - `new-project` writes `mise.toml` and `fnox.toml` templates instead of
    `.envrc`.
  - The README secrets section is rewritten for fnox.
- [ ] 4.8 mise (R4), in `shell/.config/mise/config.toml`: no `[tools]`;
  `paranoid = true`; `minimum_release_age = "7d"`;
  `[hooks] enter = "mise install"`. Fix the `status` comment. Keep
  `not_found_auto_install = false`.
- [ ] 4.9 Container test of 4.8. In a trusted project, entering installs the
  declared tools. In an untrusted one, nothing installs and the message tells
  you to run `mise trust`. `cd ~ && mise ls --current` prints nothing. If
  `paranoid` breaks the hook, fall back to `trusted_config_paths = ["~/Developer", "~/Projects"]`
  without `paranoid`. That trusts your own checkouts, but it would also trust
  anything cloned there.
- [ ] 4.10 nub (R3):
  - Stow `~/.config/nub/nub.jsonc` with `advisoryCheck` set to `required` and
    a 7-day release age. Check the key format against nub's config docs.
  - `.zshrc`: `alias npx=nubx`.

Done when: the smoke test covers signing, the mise test passes, and on this VM
a commit signed through the forwarded 1Password agent shows as Verified on
GitHub.

## Phase 5: agents and sandboxes

The `claude` stow package becomes `agents`. It stows the herdr config, the nono
profiles and the gondolin files, and it keeps unstowed bases
(`claude-settings.json`, `pi-settings.json`, `CLAUDE.md.example`) that
`install.sh` merges into place.

- [ ] 5.1 Claude (R8, R9):
  - `install.sh` runs the official installer when `~/.local/bin/claude` is
    missing.
  - If `~/.claude/settings.json` is still a stow symlink, `install.sh` replaces
    it with a regular copy, then merges `agents/claude-settings.json` into it
    with `jq`.
  - The base is this VM's file with the hook removed and D12 applied.
- [ ] 5.2 herdr (R6):
  - Stow `config.toml` with `resume_agents_on_restore = false`.
  - `install.sh` runs `herdr integration install claude` and
    `herdr integration install pi` after the merge.
  - `.zshrc` loads `herdr completion zsh`, guarded.
  - Smoke test: merge, then integration, then merge again leaves exactly one
    herdr hook and all base keys.
- [ ] 5.3 pi:
  - `install.sh` installs it with `nub add -g`, under the D13 Node.
  - `agents/pi-settings.json` (the VM's file without `lastChangelogVersion`) is
    merged into `~/.pi/agent/settings.json`.
  - Updates run through `dot`, not `pi update`, because pi's updater uses npm.
- [ ] 5.4 nono profiles (R7):
  - `agents/.config/nono/profiles/claude-strict.jsonc` and `pi-strict.jsonc`,
    with the network, environment, socket and filesystem rules from the design
    section.
  - pi also gets `NODE_USE_ENV_PROXY=1`, because Node ignores `HTTPS_PROXY`
    otherwise, and the OpenRouter key injected from 1Password.
  - Try read-only `~/.claude/settings*.json`, `~/.claude/hooks/` and
    `~/.pi/agent/extensions/` inside the sandbox.
  - `install.sh` runs `nono pull nolabs-ai/claude nolabs-ai/pi`.
- [ ] 5.5 Wrappers:
  - `bin/bin/claude` and `bin/bin/pi` set `HERDR_AGENT` and run
    `nono run --profile <name>-strict --allow-cwd -- <real binary>`.
  - Claude gets `--settings '{"sandbox":{"enabled":false}}'` there.
  - `*_UNSANDBOXED=1` runs the real binary directly.
- [ ] 5.6 nono checks on this VM:
  - `nono setup --check-only`.
  - `nono why --path ~/.ssh --op read` is denied.
  - Reaching the tmux socket from inside fails.
  - A real Claude and a real pi session can read and write the project, commit
    with a signature, and reach only the allowed hosts.
  - `git push` fails inside and works outside.
- [ ] 5.7 gondolin, Mac first (R7):
  - `agents/.config/gondolin/` holds the Claude image config and the launcher
    script.
  - The patched pi extension adds an egress allowlist.
  - New wrappers `bin/bin/claude-vm` and `bin/bin/pi-vm`.
  - `install.sh` installs qemu and gondolin in the extras tier only, and
    builds the Claude image on macOS.
- [ ] 5.8 Retire this VM's old setup (D10), after 4.10 and 5.6 pass here:
  - remove the `agent-wrapper.sh` and nvm lines from `.bashrc`;
  - retire the `...@vm` keys and the `github-vm` host alias (no repo uses it);
  - uninstall nvm and its globals (pi, pnpm, bats, corepack), since nub and
    mise replace them;
  - remove the curl-installed `~/.local/bin/herdr` and the leftover
    `~/.local/bin/claude.tmp.*` link.

Done when: on this VM, `claude` and `pi` start inside nono through herdr with
herdr showing their state, and the 5.6 checks pass. On the Mac, the same holds,
and `claude-vm` and `pi-vm` run a task in a project.

## Phase 6: defaults and judgement calls

- [ ] 6.1 (D2) `macos/defaults.sh:129-131`: dark mode, no auto-switch. Fix the
  Zed comment.
- [ ] 6.2 (D3) Delete `macos/defaults.sh:75-77`.
- [ ] 6.3 (D4) Delete `session.trust_all_worktrees` from Zed's settings.
- [ ] 6.4 (D7, R10) Colemak pane movement, the same in tmux and herdr:
  - `tmux.conf`: `bind -r` the movement and resize keys from the Keyboard
    table, reload on `o`, `choose-tree -Z` on `f`, and the VM's `x`/`X` and
    `<`/`>`.
  - `herdr/config.toml` `[keys]`: `focus_pane_*` and `navigate_pane_*` on the
    same letters. Move `workspace_picker`, `resize_mode` and `settings` as in
    the table.
  - Check: `tmux list-keys -T prefix` shows the new bindings, with nothing left
    on the old `s` and `w` pickers. `herdr server reload-config` accepts the
    file, and the moved herdr actions open from their new keys.
- [ ] 6.5 starship: `$username$hostname` at the start (only shown over SSH).
- [ ] 6.6 ripgreprc: drop the `dist/`, `build/`, `target/` and `coverage/`
  globs.
- [ ] 6.7 tmux: drop `tmux-sensible`, and guard the TPM `run` line with
  `if-shell`.
- [ ] 6.8 Optional: `.editorconfig` as the only source of indentation rules.
  Check `:verbose set sw? et?` first.
- [ ] 6.9 Optional, only for a laptop that runs Linux: `linux/keyboard.sh` sets
  Colemak and Caps Lock as Ctrl. It uses GNOME's input-source settings where
  GNOME runs, and `localectl set-x11-keymap us "" colemak ctrl:nocaps`
  elsewhere.

## Phase 7: docs

- [ ] 7.1 `README.md`, one pass:
  - bootstrap for both OSes;
  - the tier table and a cheat sheet grouped by tier;
  - signing (one agent path, per machine type);
  - secrets with fnox;
  - project tools with mise and nub;
  - agents: herdr, the wrappers, nono profiles, gondolin with its caveats;
  - a keyboard section with the Colemak table, replacing the "Colemak-friendly"
    line, which nothing backs up today;
  - local overrides;
  - corrections left from the review: the theme table, the bat path, `yq`,
    the Ghostty tmux line, the `set-hostname` example.
- [ ] 7.2 Code comments that describe old behaviour.

## Phase 8: CI (optional)

- [ ] 8.1 `.github/workflows/ci.yml`: shellcheck, plus `test/smoke.sh` on
  `ubuntu-latest` and `macos-latest`. Optionally a weekly
  `install.sh --minimal` on Ubuntu.

## Rollout

Mac (you run these):

1. `brew uninstall --cask claude-code@latest`, then `dot`. `install.sh` installs
   Claude with the official installer.
2. Signing: an empty signed commit in a scratch repo works and shows as
   Verified on GitHub.
3. SSH: `ssh -T git@github.com` works. `ssh -G github.com | grep -i identityagent`
   shows `~/.1password/agent.sock`.
4. OrbStack: restart it, then in this VM check that
   `SSH_AUTH_SOCK=/opt/orbstack-guest/run/host-ssh-agent.sock ssh-add -l`
   still lists the 1Password keys. OrbStack reportedly reads `IdentityAgent`
   from the Mac's ssh config. If the symlinked path breaks forwarding, put the
   Group Containers path in the Mac's `~/.ssh/config.local` (first value wins).
5. Ghostty opens a plain shell. `tmux` still works when run. In tmux, a yank
   reaches `pbpaste`.
6. Keyboard: Alt-C opens fzf's directory picker, right Option still types
   accented letters, and `prefix` + `w`/`a`/`r`/`s` moves between panes in
   both tmux and herdr.
7. `claude` starts inside nono and is logged in. Watch for the known "Not
   logged in" bug. `pi` starts inside nono.
8. `claude-vm` and `pi-vm` build and run.
9. Themes; `bash macos/defaults.sh`;
   `defaults delete com.apple.LaunchServices LSQuarantine`.
10. Optional cleanup: `brew uninstall dust duf direnv`.

This VM (I can drive it, with you approving the steps):

1. `sudo apt-get install -y build-essential procps curl file git zsh`, then
   `./install.sh`. It backs up `~/.gitconfig`, `~/.tmux.conf`, `~/.ssh/config`,
   `~/.ssh/rc` and `~/.claude/settings.json` into
   `~/.dotfiles-backup/<timestamp>/`. The Claude settings are then rebuilt from
   the tracked base, which is this same file.
2. `chsh -s "$(command -v zsh)"`, and log in again.
3. Check that:
   - `ssh-add -l` lists the 1Password keys;
   - a signed commit shows as Verified;
   - `claude` and `box` are still on PATH;
   - `mise ls --current` in `~` is empty.
4. The OpenRouter key: move it into 1Password, then remove it from
   `~/.pi/agent/auth.json`.
5. Then D10 and step 5.8.

## Considered and not doing

- chezmoi. The OS-specific spots are few, and runtime checks plus one agent
  path cover them.
- A per-OS signer (`op-ssh-sign`). `ssh-keygen` through the agent works
  everywhere. A runtime wrapper wouldn't work anyway, because git 2.43 doesn't
  expand `~` in `gpg.ssh.program` (tested).
- `gpg.ssh.defaultKeyCommand`. A committed public key is simpler and works in
  GUI apps.
- `fnox activate` in the shell. Without a trust step, it's a secret-loading
  hook any repo can drive.
- The `mise-env-fnox` plugin. Its author calls it an incomplete experiment.
- nub's `node shim` and `pm shim`. They shadow mise's Node and edit rc files.
- Gondolin on this VM by default. Without KVM it runs emulated.
- Symlinking Claude and pi settings. herdr and the apps write machine-specific
  values into them.
- A separate `desktop` stow package, or moving `~/bin` to `~/.local/bin`. The
  gain is small for the churn.
- A Colemak remap of vim keys (h n e i). It would displace search-next,
  end-of-word and insert in every vim-style tool.
- A different multiplexer prefix. `C-a` is the same key on Colemak, and you
  already use it on both machines.
- Tracking `~/.claude/skills` links (box, harmonia) and the VM's `CLAUDE.md`.
  They point at local checkouts and host-specific instructions; say if you
  want them managed.
