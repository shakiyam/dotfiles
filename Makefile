MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
ALL_TARGETS := $(shell grep -E -o ^[0-9A-Za-z_-]+: $(MAKEFILE_LIST) | sed 's/://')
.PHONY: $(ALL_TARGETS)
.DEFAULT_GOAL := help

# fish, chezmoi, jq, and python3 are called directly because the dotfiles themselves
# use them; the hook runs on the host's python3 with only the standard library, so the
# tests run where the hook does. Lint-only tools go through tools/, which falls back to
# a container when the host lacks them.

all: format lint test ## Format, lint, and test

fish_indent: ## Format fish scripts
	@echo -e "\033[36m$@\033[0m"
	@fish_indent -w $$(git ls-files '*.fish')

fishlint: ## Lint fish scripts for syntax and formatting
	@echo -e "\033[36m$@\033[0m"
	@for f in $$(git ls-files '*.fish'); do fish --no-execute "$$f" && fish_indent --check "$$f" || { echo "$$f: failed" >&2; exit 1; }; done

format: fish_indent ruff_format shfmt ## Run all formatting

help: ## Print this help
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9A-Za-z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

lint: fishlint markdownlint ruff settings_json shellcheck ## Run all linting

markdownlint: ## Lint Markdown files
	@echo -e "\033[36m$@\033[0m"
	@./tools/markdownlint-cli2.sh $$(git ls-files '*.md')

ruff: ## Lint Python code
	@echo -e "\033[36m$@\033[0m"
	@./tools/ruff.sh check

ruff_format: ## Format Python code
	@echo -e "\033[36m$@\033[0m"
	@./tools/ruff.sh format

settings_json: ## Check that JSON templates render to valid JSON
	@echo -e "\033[36m$@\033[0m"
	@for f in $$(git ls-files '*.json.tmpl'); do chezmoi execute-template <"$$f" | jq -e . >/dev/null || { echo "$$f: invalid JSON" >&2; exit 1; }; done

shellcheck: ## Lint shell scripts
	@echo -e "\033[36m$@\033[0m"
	@./tools/shellcheck.sh $$(git ls-files '*.sh') dot_bash_profile dot_bashrc

shfmt: ## Format shell scripts
	@echo -e "\033[36m$@\033[0m"
	@./tools/shfmt.sh -l -w -i 2 -ci -bn $$(git ls-files '*.sh') dot_bash_profile dot_bashrc

test: ## Test the Claude Code hooks
	@echo -e "\033[36m$@\033[0m"
	@python3 -I -B -m unittest discover -s tests
