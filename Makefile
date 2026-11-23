.DEFAULT_GOAL := help

CONTAINER_CMD ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)
CONTAINER_NAME = superbible4

# Extra flags for every container `run`. Auto-set when running nested inside a runClaudeInContainer sandbox
# (NESTED_PODMAN=1 makes --cgroups=disabled apply); empty on a normal host. On `run` lines only, never `build`.
PODMAN_RUN_FLAGS ?= $(if $(filter 1,$(NESTED_PODMAN)),--cgroups=disabled)

# The whole repo is mounted at /superbible4, so a script under any path resolves.
REPO_MOUNT = /superbible4
FILES_TO_MOUNT = -v $(shell pwd):$(REPO_MOUNT)/:Z \
                 -v ./entrypoint/shell.sh:/usr/local/bin/shell.sh:Z \
                 -v ./entrypoint/format.sh:/usr/local/bin/format.sh:Z

# The demos open a window: pass the host display through for `make shell`.
USE_X = -e DISPLAY=$(DISPLAY) \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	--security-opt label=type:container_runtime_t
WAYLAND_FLAGS_FOR_CONTAINER = -e "WAYLAND_DISPLAY=${WAYLAND_DISPLAY}" \
                              -e "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}" \
                              -v "${XDG_RUNTIME_DIR}:${XDG_RUNTIME_DIR}"

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
format: image ## Format the first-party C/C++ with clang-format in the container
	$(CONTAINER_CMD) run --rm $(PODMAN_RUN_FLAGS) \
		--entrypoint /bin/bash \
		$(FILES_TO_MOUNT) \
		$(CONTAINER_NAME) \
		/usr/local/bin/format.sh

.PHONY: image-export
image-export: ## Export the OCI image to a timestamped tar in the repo root
	$(CONTAINER_CMD) save $(CONTAINER_NAME) -o $(CONTAINER_NAME)-$(shell date +%m-%d-%Y_%H-%M-%S).tar

.PHONY: image-import
image-import: ## Import an OCI image tar: make image-import FILE=foo.tar
	$(CONTAINER_CMD) load -i $(FILE)

.PHONY: help
help:
	@grep --extended-regexp '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
