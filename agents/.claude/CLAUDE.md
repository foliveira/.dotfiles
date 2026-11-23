# Instructions for every session

These apply to every Claude Code session. Put project rules in the project's
own CLAUDE.md.

## Writing

- Be short. No intro and no summary at the end unless I ask.
- Use plain, simple English in docs, comments and commit messages.
- Answer a short question with a short answer.

## Code

- Change existing files before you add new ones.
- Add a comment only when the reason for the code is not clear from the code.
- Don't add compatibility layers, error handling for cases that can't happen,
  or abstractions "for later".
- Use rg and fd instead of grep and find when they are installed.

## Git

- Use Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:` and so on).
- Don't commit or push unless I ask.
- Ask before you delete files, force-push, rewrite history or change a
  database schema.

## Secrets

- Never print, copy or commit secrets. Secrets come from 1Password through
  `fx` (fnox). Don't read `.env` files or `~/.npmrc` unless I ask.

## Scope

- When you are not sure how much to change, change less and ask.
