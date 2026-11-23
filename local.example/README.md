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

## Set it up

1. Create a private GitHub repo called `dotfiles-local`.
2. Copy this folder's files into it and replace the fake values. Make one
   folder per machine: `personal`, `work`, `homelab`.
3. Move what is in the old local files (`~/.gitconfig.local`, `~/.localrc`,
   `~/.ssh/config.local`, `~/.config/tmux/local.conf`) into the right folder.
   If you find a secret, put it in 1Password instead.
4. On each Mac: `~/.dotfiles/install.sh --machine NAME --local-repo URL`.
5. Delete the old local files. `dot doctor` warns while they exist.

Keep the Paseo container's GitHub token away from this repo.
