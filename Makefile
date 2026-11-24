.DEFAULT_GOAL := help

CONTAINER_CMD ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)
CONTAINER_NAME = superbible4

# Extra flags for every container `run`. Auto-set when running nested inside a runClaudeInContainer sandbox
# (NESTED_PODMAN=1 makes --cgroups=disabled apply); empty on a normal host. On `run` lines only, never `build`.
PODMAN_RUN_FLAGS ?= $(if $(filter 1,$(NESTED_PODMAN)),--cgroups=disabled)

# The whole repo is mounted at /superbible4, so a script under any path resolves.
REPO_MOUNT = /superbible4
# The maintainer's tmux, git and gpg configuration, mounted when present (a symlinked dotfile by its real path). :Z relabels the host
# files for SELinux, as in the other projects of this template.
TMUX_FILE := $(HOME)/.tmux.conf
TMUX_REAL_PATH := $(shell readlink -f $(TMUX_FILE))
TMUX_MOUNT := $(shell if [ -f $(TMUX_REAL_PATH) ]; then echo "-v $(TMUX_REAL_PATH):/root/.tmux.conf:Z" ; fi)

GITCONFIG_FILE := $(HOME)/.gitconfig
GITCONFIG_REAL_PATH := $(shell readlink -f $(GITCONFIG_FILE))
GITCONFIG_MOUNT := $(shell if [ -f $(GITCONFIG_REAL_PATH) ]; then echo "-v $(GITCONFIG_REAL_PATH):/root/.gitconfig:Z" ; fi)

GNUPG_FILE := $(HOME)/.gnupg
GNUPG_REAL_PATH := $(shell readlink -f $(GNUPG_FILE))
GNUPG_MOUNT := $(shell if [ -d $(GNUPG_REAL_PATH) ]; then echo "-v $(GNUPG_REAL_PATH):/root/.gnupg:Z" ; fi)

FILES_TO_MOUNT = -v $(shell pwd):$(REPO_MOUNT)/:Z \
                 -v ./entrypoint/shell.sh:/usr/local/bin/shell.sh:Z \
                 -v ./entrypoint/format.sh:/usr/local/bin/format.sh:Z \
                 $(TMUX_MOUNT) \
                 $(GITCONFIG_MOUNT) \
                 $(GNUPG_MOUNT)

# The demos open a window: pass the host display through for `make shell` and `make run`.
# An X11 or XWayland server refuses clients that lack its authority file ("Authorization required"), so XAUTHORITY is passed
# through and the file mounted when it exists.
XAUTH_FLAGS := $(if $(XAUTHORITY),$(shell [ -f "$(XAUTHORITY)" ] && echo '-e XAUTHORITY=$(XAUTHORITY) -v $(XAUTHORITY):$(XAUTHORITY):ro'))
USE_X = -e DISPLAY=$(DISPLAY) \
	$(XAUTH_FLAGS) \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	--security-opt label=type:container_runtime_t
# GPU render node for hardware GL (Wayland EGL / X11); skipped if /dev/dri is absent.
DRI_DEVICE := $(shell [ -d /dev/dri ] && echo "--device /dev/dri")
# Wayland for the Python demos. PyPI glfw ships an X11-only and a Wayland-only build and picks one from XDG_SESSION_TYPE
# (unset in the container, so it chose X11 and died with "Failed to open display"). The Wayland-only build lacks
# `glfwGetX11Window`, which imgui_bundle needs, and both bind the soname `libglfw.so.3`. So PYGLFW_LIBRARY points PyPI glfw at
# the Fedora system libglfw, a dual X11 + Wayland build (the `glfw` rpm); GLFW then picks Wayland at runtime from WAYLAND_DISPLAY.
WAYLAND_FLAGS_FOR_CONTAINER = -e "XDG_SESSION_TYPE=wayland" \
                              -e "WAYLAND_DISPLAY=${WAYLAND_DISPLAY}" \
                              -e "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}" \
                              -e "PYGLFW_LIBRARY=/usr/lib64/libglfw.so.3" \
                              -v "${XDG_RUNTIME_DIR}:${XDG_RUNTIME_DIR}" \
                              $(DRI_DEVICE)

# shell / shell-exec share ONE run invocation so the two cannot drift. shell is interactive; shell-exec
# runs a script or command with no TTY.
SHELL_RUN_FLAGS = --entrypoint /bin/bash \
	$(FILES_TO_MOUNT) \
	$(USE_X) \
	$(WAYLAND_FLAGS_FOR_CONTAINER)
SHELL_EXEC_ARGS = -c 'cd $(REPO_MOUNT) && $(if $(CMD),$(CMD),exec bash $(SCRIPT))'

.PHONY: all
all: shell ## Build the image and get a shell in it

.PHONY: image
image: ## Build the podman image (toolchain, GLUT/GL headers, Xvfb; the source is bind-mounted, never baked)
	$(CONTAINER_CMD) build -t $(CONTAINER_NAME) .

.PHONY: shell
shell: image ## Get a shell in an ephemeral container (X11 + Wayland passthrough)
	$(CONTAINER_CMD) run -it --rm $(PODMAN_RUN_FLAGS) \
		$(SHELL_RUN_FLAGS) \
		$(CONTAINER_NAME) \
		/usr/local/bin/shell.sh

.PHONY: shell-exec
# shell-exec depends on image (NOT format) so a batch run never reformats the source.
shell-exec: image ## Run a script/command in the container env (no TTY): make shell-exec SCRIPT=path | CMD='...'
	@[ -n "$(SCRIPT)$(CMD)" ] || { echo 'usage: make shell-exec SCRIPT=<repo path> | CMD="..."'; exit 2; }
	$(CONTAINER_CMD) run --rm $(PODMAN_RUN_FLAGS) \
		$(SHELL_RUN_FLAGS) \
		$(CONTAINER_NAME) \
		/usr/local/bin/shell.sh $(SHELL_EXEC_ARGS)

.PHONY: format
format: image ## Format the first-party C/C++ (clang-format) and the Python port (ruff) in the container
	$(CONTAINER_CMD) run --rm $(PODMAN_RUN_FLAGS) \
		--entrypoint /bin/bash \
		$(FILES_TO_MOUNT) \
		$(CONTAINER_NAME) \
		/usr/local/bin/format.sh

# The Python port (python/) and the C++ demos run from one image. The Python demos use PyOpenGL and GLFW and run on
# Wayland or X11; the C++ demos load GL through GLX, so run-c starts them on X11 (or XWayland).
.PHONY: run
run: image ## Run a Python demo on your display: make run DEMO=chapt01/block
	@[ -n "$(DEMO)" ] || { echo 'usage: make run DEMO=<chapter>/<demo> (make list shows them)'; exit 2; }
	$(CONTAINER_CMD) run -it --rm $(PODMAN_RUN_FLAGS) \
		$(SHELL_RUN_FLAGS) \
		$(CONTAINER_NAME) \
		/usr/local/bin/shell.sh -c 'cd $(REPO_MOUNT) && exec tools/run_python_demo.sh $(DEMO)'

.PHONY: run-c
run-c: image ## Build and run the C++ demo on X11: make run-c DEMO=chapt01/block
	@[ -n "$(DEMO)" ] || { echo 'usage: make run-c DEMO=<chapter>/<demo>'; exit 2; }
	$(CONTAINER_CMD) run -it --rm $(PODMAN_RUN_FLAGS) \
		$(SHELL_RUN_FLAGS) \
		$(CONTAINER_NAME) \
		/usr/local/bin/shell.sh -c 'cd $(REPO_MOUNT) && exec tools/run_c_demo.sh $(DEMO)'

.PHONY: list
list: ## List the demos that have a Python port
	@cd python && find chapt* -mindepth 1 -maxdepth 1 -type d ! -name __pycache__ | sort

.PHONY: check
check: image ## Import every module of the Python port (no display)
	$(CONTAINER_CMD) run --rm $(PODMAN_RUN_FLAGS) \
		$(SHELL_RUN_FLAGS) \
		$(CONTAINER_NAME) \
		/usr/local/bin/shell.sh -c 'cd $(REPO_MOUNT) && exec python tools/check_python_imports.py'

# The annotate-every-binding checker (the rule ty cannot enforce). ty itself is not a gate for this port: its
# diagnostics are glfw and imgui stub friction (python/README.md, "Gates").
.PHONY: type-check
type-check: image ## Check that every binding in the Python port is annotated
	$(CONTAINER_CMD) run --rm $(PODMAN_RUN_FLAGS) \
		$(SHELL_RUN_FLAGS) \
		$(CONTAINER_NAME) \
		/usr/local/bin/shell.sh -c 'cd $(REPO_MOUNT) && exec python tools/check_local_annotations.py --include-module python'

.PHONY: update-pins
update-pins: image ## Re-resolve python/constraints.txt from python/requirements.txt
	$(CONTAINER_CMD) run --rm $(PODMAN_RUN_FLAGS) \
		$(SHELL_RUN_FLAGS) \
		$(CONTAINER_NAME) \
		/usr/local/bin/shell.sh -c 'cd $(REPO_MOUNT) && exec uv pip compile python/requirements.txt -o python/constraints.txt'

.PHONY: image-export
image-export: ## Export the OCI image to a timestamped tar in the repo root
	$(CONTAINER_CMD) save $(CONTAINER_NAME) -o $(CONTAINER_NAME)-$(shell date +%m-%d-%Y_%H-%M-%S).tar

.PHONY: image-import
image-import: ## Import an OCI image tar: make image-import FILE=foo.tar
	$(CONTAINER_CMD) load -i $(FILE)

.PHONY: help
help:
	@grep --extended-regexp '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
