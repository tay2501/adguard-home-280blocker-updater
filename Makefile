# Makefile for AdGuard Home 280blocker Updater
# Follows Google Shell Style Guide and modern best practices

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

# Directories
BIN_DIR := bin
TEST_DIR := test
LIB_DIR := lib

# Main script
MAIN_SCRIPT := $(BIN_DIR)/update_280.sh

# Colors for output
COLOR_RESET := \033[0m
COLOR_CYAN := \033[36m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m

.PHONY: help
help: ## Show this help message
	@echo "$(COLOR_CYAN)AdGuard Home 280blocker Updater - Makefile$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_GREEN)Available targets:$(COLOR_RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_CYAN)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'

.PHONY: install
install: ## Install dependencies (bats-core, shellcheck, shfmt)
	@echo "$(COLOR_YELLOW)Installing dependencies...$(COLOR_RESET)"
	@command -v shellcheck >/dev/null || { echo "Installing shellcheck..."; sudo apt-get install -y shellcheck; }
	@command -v shfmt >/dev/null || { echo "Installing shfmt..."; sudo apt-get install -y shfmt || echo "shfmt not available via apt, please install manually from https://github.com/mvdan/sh"; }
	@command -v bats >/dev/null || { echo "Installing bats-core..."; sudo apt-get install -y bats; }
	@echo "$(COLOR_GREEN)Dependencies installed successfully.$(COLOR_RESET)"

.PHONY: lint
lint: ## Run ShellCheck static analysis
	@echo "$(COLOR_YELLOW)Running ShellCheck...$(COLOR_RESET)"
	@if [ -d "$(BIN_DIR)" ]; then \
		shellcheck -x $(BIN_DIR)/*.sh; \
	else \
		shellcheck -x *.sh; \
	fi
	@echo "$(COLOR_GREEN)ShellCheck passed!$(COLOR_RESET)"

.PHONY: format
format: ## Format scripts with shfmt (Google Style: 2 spaces)
	@echo "$(COLOR_YELLOW)Formatting shell scripts...$(COLOR_RESET)"
	@if command -v shfmt >/dev/null; then \
		if [ -d "$(BIN_DIR)" ]; then \
			shfmt -l -w -i 2 -ci -bn $(BIN_DIR)/ $(TEST_DIR)/ 2>/dev/null || true; \
		else \
			shfmt -l -w -i 2 -ci -bn . 2>/dev/null || true; \
		fi; \
		echo "$(COLOR_GREEN)Formatting complete.$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)shfmt not found. Skipping format.$(COLOR_RESET)"; \
	fi

.PHONY: format-check
format-check: ## Check if scripts are properly formatted
	@echo "$(COLOR_YELLOW)Checking formatting...$(COLOR_RESET)"
	@if command -v shfmt >/dev/null; then \
		if [ -d "$(BIN_DIR)" ]; then \
			shfmt -d -i 2 -ci -bn $(BIN_DIR)/ $(TEST_DIR)/ 2>/dev/null || exit 1; \
		else \
			shfmt -d -i 2 -ci -bn . 2>/dev/null || exit 1; \
		fi; \
		echo "$(COLOR_GREEN)Formatting check passed!$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)shfmt not found. Skipping format check.$(COLOR_RESET)"; \
	fi

.PHONY: test
test: ## Run bats-core tests
	@echo "$(COLOR_YELLOW)Running tests...$(COLOR_RESET)"
	@if [ -d "$(TEST_DIR)" ] && command -v bats >/dev/null; then \
		bats $(TEST_DIR)/; \
		echo "$(COLOR_GREEN)All tests passed!$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Tests not available yet or bats not installed.$(COLOR_RESET)"; \
	fi

.PHONY: test-verbose
test-verbose: ## Run bats-core tests in verbose mode
	@echo "$(COLOR_YELLOW)Running tests (verbose)...$(COLOR_RESET)"
	@if [ -d "$(TEST_DIR)" ] && command -v bats >/dev/null; then \
		bats --verbose-run $(TEST_DIR)/; \
	else \
		echo "$(COLOR_YELLOW)Tests not available yet or bats not installed.$(COLOR_RESET)"; \
	fi

.PHONY: run
run: ## Run the updater script (verbose mode)
	@echo "$(COLOR_YELLOW)Running updater script...$(COLOR_RESET)"
	@if [ -f "$(MAIN_SCRIPT)" ]; then \
		$(MAIN_SCRIPT) -v; \
	else \
		./adguard_home_280blocker_updater.sh -v; \
	fi

.PHONY: run-quiet
run-quiet: ## Run the updater script (quiet mode, as in cron)
	@if [ -f "$(MAIN_SCRIPT)" ]; then \
		$(MAIN_SCRIPT); \
	else \
		./adguard_home_280blocker_updater.sh; \
	fi

.PHONY: ci
ci: lint format-check test ## Run full CI pipeline (lint + format-check + test)
	@echo "$(COLOR_GREEN)CI pipeline completed successfully!$(COLOR_RESET)"

.PHONY: clean
clean: ## Clean up temporary files
	@echo "$(COLOR_YELLOW)Cleaning up...$(COLOR_RESET)"
	@rm -f /tmp/tmp.* 2>/dev/null || true
	@echo "$(COLOR_GREEN)Cleanup complete.$(COLOR_RESET)"

.PHONY: install-script
install-script: ## Install script to /usr/local/bin (requires sudo)
	@echo "$(COLOR_YELLOW)Installing script to /usr/local/bin...$(COLOR_RESET)"
	@if [ -f "$(MAIN_SCRIPT)" ]; then \
		sudo cp $(MAIN_SCRIPT) /usr/local/bin/update_280.sh; \
		sudo chmod +x /usr/local/bin/update_280.sh; \
	else \
		sudo cp adguard_home_280blocker_updater.sh /usr/local/bin/update_280.sh; \
		sudo chmod +x /usr/local/bin/update_280.sh; \
	fi
	@echo "$(COLOR_GREEN)Script installed successfully to /usr/local/bin/update_280.sh$(COLOR_RESET)"

.PHONY: uninstall-script
uninstall-script: ## Uninstall script from /usr/local/bin (requires sudo)
	@echo "$(COLOR_YELLOW)Uninstalling script from /usr/local/bin...$(COLOR_RESET)"
	@sudo rm -f /usr/local/bin/update_280.sh
	@echo "$(COLOR_GREEN)Script uninstalled successfully.$(COLOR_RESET)"

.PHONY: setup-cron
setup-cron: ## Setup cron job to run daily at 3:00 AM
	@echo "$(COLOR_YELLOW)Setting up cron job...$(COLOR_RESET)"
	@echo "0 3 * * * /usr/local/bin/update_280.sh" | sudo crontab -
	@echo "$(COLOR_GREEN)Cron job installed. Filter list will update daily at 3:00 AM.$(COLOR_RESET)"
	@echo "$(COLOR_CYAN)Verify with: sudo crontab -l$(COLOR_RESET)"
