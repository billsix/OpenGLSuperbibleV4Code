# `make shell` now has the maintainer's shell configuration and a prompt without the venv name

**Done:** 2026-11-24 (work commit; the archive move follows). Source: the maintainer (William Emerison Six <billsix@gmail.com>, 2026-11-24):
"I want make shell to have the shell config and suppression of python venv name, like is done in geometricalgebra and modelviewprojection".
Both open questions were answered the same day: keep the format-on-exit hook (yes), do not vendor `.emacs.d` (no).

## What was done

Copied the pattern of `github.com/billsix/geometricalgebra` and the course repository:

- `Makefile`: `TMUX_MOUNT`, `GITCONFIG_MOUNT`, `GNUPG_MOUNT` (each mounts `readlink -f` of `~/.tmux.conf`, `~/.gitconfig`, `~/.gnupg` only when it
  exists, with `:Z`), added to `FILES_TO_MOUNT`, so `make shell`, `shell-exec`, `run` and `format` share them.
- `entrypoint/dotfiles/.extrabashrc`: colour `ls`, `GPG_TTY`, the two-line `┌─(time) user@host:path` / `└─λ` prompt, an `exit()` that prints
  "Formatting on shell exit", `cd`s to `/superbible4` and runs `format.sh`, and a trailing `cd /superbible4`.
- `Dockerfile`: `COPY entrypoint/dotfiles/ /root/` and `source ~/.extrabashrc` appended to `~/.bashrc`, as the last layers.
- `entrypoint/shell.sh`: `export VIRTUAL_ENV_DISABLE_PROMPT=1` before the venv is activated.
- `entrypoint/01-install-base.sh`: `pinentry`, on its own `dnf install` line.
- `CLAUDE.md` describes the shell.

## Verification (container, 2026-11-24)

`make shell` driven through a pseudo-terminal (`make shell` needs a TTY): the prompt was `┌─(14:58:11) root@<id>:/superbible4` over `└─λ` with no
`(venv)`; `VIRTUAL_ENV_DISABLE_PROMPT=1`; `git config user.name` returned the host's name through the mounted `.gitconfig`; `tmux -V` printed
3.8; `type exit` said "exit is a function"; `exit` printed "Formatting on shell exit", ruff and clang-format ran ("All checks passed!", "109 files
left unchanged") and `git status` showed only the intended changes afterwards.

Not verified: a signed commit through `GPG_TTY` (this sandbox has no signing key to try), and `~/.tmux.conf` (the sandbox has none; the mount is
skipped when the file is absent).

## Owed

The maintainer merges the branch `shell-config` into `master`. Note for the next `make shell` on the host: the `:Z` mounts relabel `~/.gitconfig`
and `~/.gnupg` for SELinux, as in the other projects.
