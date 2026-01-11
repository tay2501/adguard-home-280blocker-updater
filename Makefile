# Makefile for AdGuard Home 280blocker Updater
# Follows GNU Coding Standards and Google Shell Style Guide

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

# ==========================================
# GNU Standard Variables
# ==========================================
PREFIX ?= /usr/local
DESTDIR ?=

# Binary installation directory
bindir := $(PREFIX)/bin

# System directories for cron and systemd
sysconfdir := /etc
systemddir := $(sysconfdir)/systemd/system

# ==========================================
# Project Structure
# ==========================================
BIN_DIR := bin
TEST_DIR := test
LIB_DIR := lib
CONFIG_DIR := config

# Main script config
SCRIPT_NAME := adguardhome-280blocker-filter-updater
MAIN_SCRIPT := $(BIN_DIR)/$(SCRIPT_NAME).sh

# Configuration sources
CRON_SRC := $(CONFIG_DIR)/cron.d/adguardhome-280blocker-filter-updater
SYSTEMD_SERVICE_SRC := $(CONFIG_DIR)/systemd/$(SCRIPT_NAME).service
SYSTEMD_TIMER_SRC := $(CONFIG_DIR)/systemd/$(SCRIPT_NAME).timer

# Installation destinations
INSTALL_BIN := $(DESTDIR)$(bindir)/$(SCRIPT_NAME)
INSTALL_CRON := $(DESTDIR)$(sysconfdir)/cron.d/adguardhome-280blocker-filter-updater
INSTALL_SYSTEMD_SERVICE := $(DESTDIR)$(systemddir)/$(SCRIPT_NAME).service
INSTALL_SYSTEMD_TIMER := $(DESTDIR)$(systemddir)/$(SCRIPT_NAME).timer

# ==========================================
# Terminal Colors
# ==========================================
COLOR_RESET := \033[0m
COLOR_CYAN := \033[36m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_RED := \033[31m

# ==========================================
# Standard Targets
# ==========================================

.PHONY: all
all: ## Default target: verify script existence (No installation)
	@printf "$(COLOR_CYAN)AdGuard Home 280blocker Updater$(COLOR_RESET)\n"
	@if [ -f "$(MAIN_SCRIPT)" ]; then \
		printf "$(COLOR_GREEN)Main script found: $(MAIN_SCRIPT)$(COLOR_RESET)\n"; \
		printf "$(COLOR_CYAN)Run 'make install-systemd' (Recommended) or 'make install-cron' to install$(COLOR_RESET)\n"; \
	else \
		printf "$(COLOR_RED)Error: $(MAIN_SCRIPT) not found$(COLOR_RESET)\n"; \
		exit 1; \
	fi

# ==========================================
# Installation Targets (Refactored)
# ==========================================

.PHONY: install
install: install-systemd ## Alias for install-systemd (Recommended)

.PHONY: install-common
install-common: ## (Internal) Install script binary only
	@printf "$(COLOR_YELLOW)Installing binary: $(SCRIPT_NAME)...$(COLOR_RESET)\n"
	@if [ ! -f "$(MAIN_SCRIPT)" ]; then \
		printf "$(COLOR_RED)Error: $(MAIN_SCRIPT) not found$(COLOR_RESET)\n"; \
		exit 1; \
	fi
	@install -d "$(DESTDIR)$(bindir)"
	@install -m 755 $(MAIN_SCRIPT) "$(INSTALL_BIN)"
	@printf "$(COLOR_GREEN)Installed: $(INSTALL_BIN)$(COLOR_RESET)\n"

.PHONY: install-cron
install-cron: install-common ## Install with Cron (Legacy)
	@printf "$(COLOR_YELLOW)Setting up Cron job...$(COLOR_RESET)\n"
	@# Check if Cron source exists
	@if [ -f "$(CRON_SRC)" ]; then \
		install -d "$(DESTDIR)$(sysconfdir)/cron.d"; \
		install -m 644 -o root -g root $(CRON_SRC) "$(INSTALL_CRON)"; \
		printf "$(COLOR_GREEN)Installed: $(INSTALL_CRON)$(COLOR_RESET)\n"; \
	else \
		printf "$(COLOR_RED)Error: Cron source $(CRON_SRC) not found$(COLOR_RESET)\n"; \
	fi
	@# Warning if Systemd timer is active
	@if [ -z "$(DESTDIR)" ] && systemctl is-active --quiet $(SCRIPT_NAME).timer 2>/dev/null; then \
		printf "$(COLOR_RED)Warning: Systemd timer is also active! You should run 'make uninstall' first.$(COLOR_RESET)\n"; \
	fi
	@printf "$(COLOR_GREEN)Installation (Cron) complete!$(COLOR_RESET)\n"

.PHONY: install-systemd
install-systemd: install-common ## Install with Systemd Timer (Recommended)
	@printf "$(COLOR_YELLOW)Setting up Systemd Timer...$(COLOR_RESET)\n"
	@# 1. Check sources
	@if [ ! -f "$(SYSTEMD_SERVICE_SRC)" ] || [ ! -f "$(SYSTEMD_TIMER_SRC)" ]; then \
		printf "$(COLOR_RED)Error: Systemd files not found in $(CONFIG_DIR)/systemd/$(COLOR_RESET)\n"; \
		exit 1; \
	fi
	@# 2. Safety: Remove conflicting Cron job if exists
	@if [ -f "$(INSTALL_CRON)" ]; then \
		printf "$(COLOR_YELLOW)Removing conflicting Cron job...$(COLOR_RESET)\n"; \
		rm -f "$(INSTALL_CRON)"; \
	fi
	@# 3. Install units
	@install -d "$(DESTDIR)$(systemddir)"
	@install -m 644 $(SYSTEMD_SERVICE_SRC) "$(INSTALL_SYSTEMD_SERVICE)"
	@install -m 644 $(SYSTEMD_TIMER_SRC) "$(INSTALL_SYSTEMD_TIMER)"
	@printf "$(COLOR_GREEN)Installed: $(INSTALL_SYSTEMD_SERVICE)$(COLOR_RESET)\n"
	@printf "$(COLOR_GREEN)Installed: $(INSTALL_SYSTEMD_TIMER)$(COLOR_RESET)\n"
	@# 4. Enable & Start (Only if not packaging)
	@if [ -z "$(DESTDIR)" ]; then \
		printf "$(COLOR_YELLOW)Reloading systemd...$(COLOR_RESET)\n"; \
		sudo systemctl daemon-reload; \
		sudo systemctl enable --now $(SCRIPT_NAME).timer; \
		printf "$(COLOR_GREEN)Systemd timer enabled and started!$(COLOR_RESET)\n"; \
		systemctl list-timers $(SCRIPT_NAME).timer --no-pager; \
	fi

.PHONY: uninstall
uninstall: ## Remove all installed files
	@printf "$(COLOR_YELLOW)Uninstalling $(SCRIPT_NAME)...$(COLOR_RESET)\n"
	@# Stop Systemd (Only if systemd is running)
	@if [ -z "$(DESTDIR)" ] && [ -d /run/systemd/system ] && command -v systemctl >/dev/null; then \
		if systemctl is-active --quiet $(SCRIPT_NAME).timer 2>/dev/null; then \
			sudo systemctl stop $(SCRIPT_NAME).timer || true; \
			sudo systemctl disable $(SCRIPT_NAME).timer || true; \
		fi; \
	fi
	@# Remove files
	@rm -f "$(INSTALL_BIN)"
	@rm -f "$(INSTALL_CRON)"
	@rm -f "$(INSTALL_SYSTEMD_SERVICE)"
	@rm -f "$(INSTALL_SYSTEMD_TIMER)"
	@# Reload (Only if systemd is running)
	@if [ -z "$(DESTDIR)" ] && [ -d /run/systemd/system ] && command -v systemctl >/dev/null; then \
		sudo systemctl daemon-reload || true; \
	fi
	@printf "$(COLOR_GREEN)Uninstallation complete.$(COLOR_RESET)\n"

# ==========================================
# Development & Testing Targets
# ==========================================

.PHONY: lint
lint: ## Run ShellCheck static analysis
	@printf "$(COLOR_YELLOW)Running ShellCheck...$(COLOR_RESET)\n"
	@if command -v shellcheck >/dev/null; then \
		if [ -d "$(BIN_DIR)" ]; then \
			shellcheck -x $(BIN_DIR)/*.sh; \
		else \
			shellcheck -x *.sh; \
		fi; \
		printf "$(COLOR_GREEN)ShellCheck passed!$(COLOR_RESET)\n"; \
	else \
		printf "$(COLOR_RED)Error: shellcheck not found.$(COLOR_RESET)\n"; \
		exit 1; \
	fi

.PHONY: format
format: ## Format scripts with shfmt
	@printf "$(COLOR_YELLOW)Formatting shell scripts...$(COLOR_RESET)\n"
	@if command -v shfmt >/dev/null; then \
		shfmt -l -w -i 2 -ci -bn $(BIN_DIR)/ $(TEST_DIR)/ 2>/dev/null || true; \
		printf "$(COLOR_GREEN)Formatting complete.$(COLOR_RESET)\n"; \
	else \
		printf "$(COLOR_YELLOW)shfmt not found. Skipping.$(COLOR_RESET)\n"; \
	fi

.PHONY: format-check
format-check: ## Check formatting
	@printf "$(COLOR_YELLOW)Checking formatting...$(COLOR_RESET)\n"
	@if command -v shfmt >/dev/null; then \
		shfmt -d -i 2 -ci -bn $(BIN_DIR)/ $(TEST_DIR)/ 2>/dev/null || { \
			printf "$(COLOR_RED)Formatting issues found. Run 'make format'$(COLOR_RESET)\n"; \
			exit 1; \
		}; \
		printf "$(COLOR_GREEN)Formatting check passed!$(COLOR_RESET)\n"; \
	else \
		printf "$(COLOR_YELLOW)shfmt not found. Skipping check.$(COLOR_RESET)\n"; \
	fi

.PHONY: test
test: ## Run bats-core tests
	@printf "$(COLOR_YELLOW)Running tests...$(COLOR_RESET)\n"
	@if [ -d "$(TEST_DIR)" ] && command -v bats >/dev/null; then \
		bats $(TEST_DIR)/; \
		printf "$(COLOR_GREEN)All tests passed!$(COLOR_RESET)\n"; \
	else \
		printf "$(COLOR_YELLOW)Tests not available or bats not installed.$(COLOR_RESET)\n"; \
	fi

.PHONY: ci
ci: lint format-check test ## Run full CI pipeline
	@printf "$(COLOR_GREEN)CI pipeline completed successfully!$(COLOR_RESET)\n"

.PHONY: help
help: ## Show this help message
	@printf "$(COLOR_CYAN)AdGuard Home 280blocker Updater - Makefile$(COLOR_RESET)\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_CYAN)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'