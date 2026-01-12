# Makefile for AdGuard Home 280blocker Updater
# Standards: GNU Coding Standards & Google Shell Style Guide

# Use bash for consistency
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

# ==========================================
# GNU Standard Variables
# ==========================================
PREFIX ?= /usr/local
DESTDIR ?=

# Installation directories
bindir     := $(PREFIX)/bin
sysconfdir := /etc
systemddir := $(sysconfdir)/systemd/system
# Variable data directory (FHS compliant for /opt apps)
filterdir  := /var/opt/adguardhome/filters

# ==========================================
# Project Structure
# ==========================================
BIN_DIR    := bin
TEST_DIR   := test
CONFIG_DIR := config

# Main script config
SCRIPT_NAME := adguardhome-280blocker-filter-updater
MAIN_SCRIPT := $(BIN_DIR)/$(SCRIPT_NAME).sh

# Configuration sources
CRON_SRC            := $(CONFIG_DIR)/cron.d/$(SCRIPT_NAME)
SYSTEMD_SERVICE_SRC := $(CONFIG_DIR)/systemd/$(SCRIPT_NAME).service
SYSTEMD_TIMER_SRC   := $(CONFIG_DIR)/systemd/$(SCRIPT_NAME).timer

# Installation destinations (respecting DESTDIR)
INSTALL_BIN             := $(DESTDIR)$(bindir)/$(SCRIPT_NAME)
INSTALL_CRON            := $(DESTDIR)$(sysconfdir)/cron.d/$(SCRIPT_NAME)
INSTALL_SYSTEMD_SERVICE := $(DESTDIR)$(systemddir)/$(SCRIPT_NAME).service
INSTALL_SYSTEMD_TIMER   := $(DESTDIR)$(systemddir)/$(SCRIPT_NAME).timer
INSTALL_FILTER_DIR      := $(DESTDIR)$(filterdir)

# ==========================================
# Terminal Colors
# ==========================================
COLOR_RESET  := \033[0m
COLOR_CYAN   := \033[36m
COLOR_GREEN  := \033[32m
COLOR_YELLOW := \033[33m
COLOR_RED    := \033[31m

# ==========================================
# Standard Targets
# ==========================================

.PHONY: all
all: ## Default target: verify script existence
	@printf "$(COLOR_CYAN)AdGuard Home 280blocker Updater$(COLOR_RESET)\n"
	@if [ -f "$(MAIN_SCRIPT)" ]; then \
		printf "$(COLOR_GREEN)Main script found: $(MAIN_SCRIPT)$(COLOR_RESET)\n"; \
		printf "$(COLOR_CYAN)Run 'make install-systemd' (Recommended) or 'make install-cron' to install$(COLOR_RESET)\n"; \
	else \
		printf "$(COLOR_RED)Error: $(MAIN_SCRIPT) not found$(COLOR_RESET)\n"; \
		exit 1; \
	fi

# ==========================================
# Installation Targets
# ==========================================

.PHONY: install
install: install-systemd ## Alias for install-systemd (Recommended)

.PHONY: install-common
install-common: ## Install binary and create data directory
	@printf "$(COLOR_YELLOW)Installing binary: $(SCRIPT_NAME)...$(COLOR_RESET)\n"
	@if [ ! -f "$(MAIN_SCRIPT)" ]; then printf "$(COLOR_RED)Error: $(MAIN_SCRIPT) not found$(COLOR_RESET)\n"; exit 1; fi
	@install -d "$(DESTDIR)$(bindir)"
	@install -m 755 $(MAIN_SCRIPT) "$(INSTALL_BIN)"
	@printf "$(COLOR_GREEN)Installed: $(INSTALL_BIN)$(COLOR_RESET)\n"
	@printf "$(COLOR_YELLOW)Ensuring data directory: $(filterdir)...$(COLOR_RESET)\n"
	@install -d -m 755 "$(INSTALL_FILTER_DIR)"
	@printf "$(COLOR_GREEN)Data directory ready: $(INSTALL_FILTER_DIR)$(COLOR_RESET)\n"

.PHONY: install-cron
install-cron: install-common ## Install with Cron (Legacy)
	@printf "$(COLOR_YELLOW)Setting up Cron job...$(COLOR_RESET)\n"
	@if [ -f "$(CRON_SRC)" ]; then \
		install -d "$(DESTDIR)$(sysconfdir)/cron.d"; \
		install -m 644 -o root -g root $(CRON_SRC) "$(INSTALL_CRON)"; \
		printf "$(COLOR_GREEN)Installed: $(INSTALL_CRON)$(COLOR_RESET)\n"; \
	else \
		printf "$(COLOR_RED)Error: Cron source $(CRON_SRC) not found$(COLOR_RESET)\n"; exit 1; \
	fi
	@if [ -z "$(DESTDIR)" ] && [ -d /run/systemd/system ] && systemctl is-active --quiet $(SCRIPT_NAME).timer 2>/dev/null; then \
		printf "$(COLOR_RED)Warning: Systemd timer is active! Run 'make uninstall' first.$(COLOR_RESET)\n"; \
	fi
	@printf "$(COLOR_GREEN)Installation (Cron) complete!$(COLOR_RESET)\n"

.PHONY: install-systemd
install-systemd: install-common ## Install with Systemd Timer (Recommended)
	@printf "$(COLOR_YELLOW)Setting up Systemd Timer...$(COLOR_RESET)\n"
	@if [ ! -f "$(SYSTEMD_SERVICE_SRC)" ] || [ ! -f "$(SYSTEMD_TIMER_SRC)" ]; then \
		printf "$(COLOR_RED)Error: Systemd files not found$(COLOR_RESET)\n"; exit 1; \
	fi
	@if [ -f "$(INSTALL_CRON)" ]; then \
		printf "$(COLOR_YELLOW)Removing conflicting Cron job...$(COLOR_RESET)\n"; rm -f "$(INSTALL_CRON)"; \
	fi
	@install -d "$(DESTDIR)$(systemddir)"
	@install -m 644 $(SYSTEMD_SERVICE_SRC) "$(INSTALL_SYSTEMD_SERVICE)"
	@install -m 644 $(SYSTEMD_TIMER_SRC) "$(INSTALL_SYSTEMD_TIMER)"
	@printf "$(COLOR_GREEN)Installed Systemd Units: service, timer$(COLOR_RESET)\n"
	@if [ -z "$(DESTDIR)" ] && [ -d /run/systemd/system ] && command -v systemctl >/dev/null; then \
		printf "$(COLOR_YELLOW)Reloading systemd...$(COLOR_RESET)\n"; \
		sudo systemctl daemon-reload; \
		sudo systemctl enable --now $(SCRIPT_NAME).timer; \
		printf "$(COLOR_GREEN)Systemd timer enabled and started!$(COLOR_RESET)\n"; \
		systemctl list-timers $(SCRIPT_NAME).timer --no-pager; \
	else \
		printf "$(COLOR_YELLOW)Systemd not active or DESTDIR set. Skipping service start.$(COLOR_RESET)\n"; \
	fi

.PHONY: uninstall
uninstall: ## Remove all installed files
	@printf "$(COLOR_YELLOW)Uninstalling $(SCRIPT_NAME)...$(COLOR_RESET)\n"
	@if [ -z "$(DESTDIR)" ] && [ -d /run/systemd/system ] && command -v systemctl >/dev/null; then \
		if systemctl is-active --quiet $(SCRIPT_NAME).timer 2>/dev/null; then \
			sudo systemctl stop $(SCRIPT_NAME).timer || true; \
			sudo systemctl disable $(SCRIPT_NAME).timer || true; \
		fi; \
	fi
	@rm -f "$(INSTALL_BIN)" "$(INSTALL_CRON)" "$(INSTALL_SYSTEMD_SERVICE)" "$(INSTALL_SYSTEMD_TIMER)"
	@if [ -z "$(DESTDIR)" ] && [ -d /run/systemd/system ] && command -v systemctl >/dev/null; then \
		sudo systemctl daemon-reload || true; \
	fi
	@printf "$(COLOR_GREEN)Uninstallation complete.$(COLOR_RESET)\n"

# ==========================================
# Development, Test, CI
# ==========================================

.PHONY: lint
lint: ## Run ShellCheck
	@printf "$(COLOR_YELLOW)Running ShellCheck...$(COLOR_RESET)\n"
	@shellcheck -x $(MAIN_SCRIPT)
	@printf "$(COLOR_GREEN)ShellCheck passed!$(COLOR_RESET)\n"

.PHONY: format
format: ## Format scripts with shfmt
	@shfmt -l -w -i 2 -ci -bn $(BIN_DIR)/ $(TEST_DIR)/ 2>/dev/null || true

.PHONY: test
test: ## Run bats tests
	@if [ -d "$(TEST_DIR)" ] && command -v bats >/dev/null; then bats $(TEST_DIR)/; else printf "No tests/bats found.\n"; fi

.PHONY: ci
ci: lint test ## Run CI pipeline

.PHONY: help
help: ## Show this help
	@printf "$(COLOR_CYAN)AdGuard Home 280blocker Updater - Makefile$(COLOR_RESET)\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_CYAN)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'