# Give `make shell` the shell configuration of the other projects, and hide the venv name from the prompt

**Status:** proposed — needs go-ahead (filed 2026-11-24; open questions answered 2026-11-24)
**Priority:** 6
**Difficulty:** 2
**Created:** 2026-11-24
**Source:** the maintainer (William Emerison Six <billsix@gmail.com>, 2026-11-24): "I want make shell to have the shell config and
suppression of python venv name, like is done in geometricalgebra and modelviewprojection".

## BLUF

`make shell` here drops into a bare bash with the venv's `(venv)` prompt prefix and none of the maintainer's configuration. Make it
match `github.com/billsix/geometricalgebra` and the course repository: the host's `~/.tmux.conf`, `~/.gitconfig` and `~/.gnupg` mounted
in, a `~/.extrabashrc` (colour `ls`, `GPG_TTY`, the two-line prompt, a format-on-exit hook) sourced from `~/.bashrc`, and
`VIRTUAL_ENV_DISABLE_PROMPT=1` so the venv name stays out of the prompt. Done means: `make shell` shows `┌─(time) user@host:/superbible4`
then `└─λ`, `git config user.name` and `tmux` and `gpg --list-keys` work inside, and `exit` runs `make format`'s script before leaving.

## Context

- **Today (verified 2026-11-24):** `entrypoint/shell.sh` runs `set -e`, `source /venv/bin/activate`, `exec bash`; it does not set
  `VIRTUAL_ENV_DISABLE_PROMPT`, so the activated venv prepends `(venv)` to the prompt. The `Makefile`'s `FILES_TO_MOUNT` mounts only the
  repository, `entrypoint/shell.sh` and `entrypoint/format.sh`. There is no `entrypoint/dotfiles/`. `entrypoint/01-install-base.sh` already
  installs `tmux`; it does not install `pinentry`.
- **The pattern to copy**, read from `geometricalgebra` (its `Makefile` lines 40–66, `Dockerfile` lines 62 and 96, `entrypoint/shell.sh`,
  `entrypoint/dotfiles/.extrabashrc`) and from the course repository:
  - `Makefile`: `TMUX_MOUNT`, `GITCONFIG_MOUNT`, `GNUPG_MOUNT`, each `readlink -f` of `$(HOME)/.tmux.conf`, `.gitconfig`, `.gnupg` and a
    `-v <real path>:/root/<name>:Z` only when the file exists (a symlinked dotfile is mounted by its real path), added to `FILES_TO_MOUNT`.
  - `Dockerfile`: `COPY entrypoint/dotfiles/ /root/` and `echo "source ~/.extrabashrc" >> ~/.bashrc`, placed after the long dnf and pip layers so
    editing a dotfile rebuilds almost nothing.
  - `entrypoint/dotfiles/.extrabashrc`: `alias ls='ls --color=auto'`, `export GPG_TTY=$(tty)`, `PS1='\[\e[36m\]┌─(\t) \[\e[32m\]\u@\h:\w\n\[\e[36m\]└─λ \[\e[0m\]'`,
    and an `exit()` function that prints "Formatting on shell exit", `cd`s to the repository root and runs `format.sh` before `builtin exit`
    (`format.sh` uses repository-relative paths, so it must run from the root wherever the shell is; the maintainer's convention for every
    project of this template).
  - `entrypoint/shell.sh`: `export VIRTUAL_ENV_DISABLE_PROMPT=1` before `source /venv/bin/activate`.
  - `dnf install -y pinentry` so signing works through `GPG_TTY`.
- **Here the repository mount is `/superbible4`** (`REPO_MOUNT` in the `Makefile`), and `format.sh` is `entrypoint/format.sh` mounted at
  `/usr/local/bin/format.sh`; it runs clang-format on the C++ and ruff on `python/` and `tools/`.
- **The `:Z` on the mounted host files relabels them for SELinux** (the same as in the other projects): `~/.gitconfig` and `~/.gnupg` get the
  container's label on the host. That is the existing practice there; note it, do not change it silently.
- **`make shell-exec` and `make run` share the mounts** (they share `FILES_TO_MOUNT`); the `.extrabashrc` only affects interactive shells,
  so batch targets are unchanged.

## Plan

1. `entrypoint/dotfiles/.extrabashrc` as above, with `cd /superbible4` in the exit hook and in a trailing `cd /superbible4` (so the prompt
   starts at the root, as `shell.sh` already does).
2. `entrypoint/shell.sh`: add `export VIRTUAL_ENV_DISABLE_PROMPT=1` before `source /venv/bin/activate`.
3. `Makefile`: the three `*_MOUNT` variables and their addition to `FILES_TO_MOUNT`.
4. `Dockerfile`: the `COPY` and the `source ~/.extrabashrc` line after the existing `RUN`s; `01-install-base.sh`: add `pinentry` (its own
   `dnf install` line after the main one, as in the course repository, so a missing package does not fail the whole group).
5. Verify: `make image`; in `make shell` check the prompt, `git config user.name`, `tmux -V` and a tmux session, `gpg --list-keys`, a commit
   signed through `GPG_TTY` (in a scratch repository, not this one), and that `exit` runs `format.sh` and leaves the tree unchanged
   (`git status` before and after). Check `make run`, `make shell-exec` and `make check` are unaffected.
6. Update `CLAUDE.md` ("Container") and `python/README.md` if they describe `make shell`. Stage; the maintainer commits.

## Open questions

Both answered 2026-11-24 by the maintainer, William Emerison Six <billsix@gmail.com>:

1. Include the format-on-exit hook? It rewrites files with clang-format and ruff every time the shell exits. Answered: **yes** (recommended: as in every other
   project of the template; the formatters are idempotent and the C++ already has a `make format` gate.)
2. Also vendor `.emacs.d` as the other projects do (a large vendored `elpa` tree and its own update target)? Answered: **no** (recommended: a separate task
   if wanted; this task is the shell configuration and the prompt only.)
