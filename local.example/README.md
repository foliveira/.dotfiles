# Private config repo: example layout

Settings that are private go in a separate, private repo called
`dotfiles-local`. Secrets never go there. Secrets stay in 1Password.

The repo has one folder per machine and one shared folder:

```
dotfiles-local/
  shared/      used by both laptops
  personal/
  work/
  homelab/
  denylist     words that must never be committed to the public repo
```

`install.sh` links `~/.config/local` to the folder for this machine, and
`~/.config/local-shared` to `shared/`. Every file is optional:

| File | Used by | For example |
|---|---|---|
| `gitconfig` | git, read last | your signing key, work email rules |
| `ssh_config` | ssh, read first | hosts you connect to |
| `env.zsh` | zsh, sourced at start | `ATUIN_SYNC_ADDRESS`, aliases for this machine |
| `tmux.conf` | tmux | settings for this machine |
| `mise.toml` | mise (machine folder only) | settings for this machine |

The files in this folder are examples with fake values.
