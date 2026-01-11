# Architecture & Design Decisions

本ドキュメントでは、AdGuard Home 280blocker Updaterの設計思想、アーキテクチャ、および主要な技術的判断について説明します。

## Table of Contents

- [Design Philosophy](#design-philosophy)
- [Project Structure](#project-structure)
- [Key Design Decisions](#key-design-decisions)
- [Scheduling Architecture](#scheduling-architecture)
- [Error Handling Strategy](#error-handling-strategy)
- [Future Considerations](#future-considerations)

---

## Design Philosophy

### Core Principles

1. **KISS (Keep It Simple, Stupid)**
   - 単一目的のシンプルなスクリプト
   - 外部依存を最小限に抑える（bash + curl のみ）
   - 複雑な設定を避ける

2. **UNIX Philosophy**
   - Do one thing and do it well
   - Write programs to work together
   - Text streams as universal interface

3. **Defensive Programming**
   - `set -euo pipefail`による厳格なエラーハンドリング
   - 変数の適切なクォーティング
   - 予期しない状態への対応

4. **Standards Compliance**
   - [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)準拠
   - [GNU Coding Standards](https://www.gnu.org/prep/standards/)準拠
   - [FHS (Filesystem Hierarchy Standard)](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)準拠

---

## Project Structure

```
adguard-home-280blocker-updater/
├── bin/                    # Executable scripts
│   └── *.sh               # Source scripts with .sh extension
├── config/                # System configuration templates
│   ├── cron.d/           # cron configuration
│   └── systemd/          # systemd unit files
├── lib/                   # Shared libraries (future)
├── test/                  # Test suite
│   └── *.bats            # bats-core test files
├── docs/                  # Technical documentation
├── Makefile              # GNU-compliant build system
└── README.md             # User-facing documentation
```

### Directory Rationale

#### `bin/` - Executable Scripts
- **Convention**: Source files have `.sh` extension
- **Installation**: Installed without extension (UNIX convention)
- **Example**: `bin/script.sh` → `/usr/local/bin/script`

#### `config/` - System Configuration
- **Purpose**: Version-controlled system configuration templates
- **Deployment**: Files are copied to system directories via `make install`
- **Benefit**: GitOps-ready, reproducible deployments

#### `lib/` - Shared Libraries
- **Status**: Currently unused, reserved for future modularization
- **Purpose**: Reusable functions for complex features
- **Convention**: `.sh` extension, sourced (not executed)

#### `test/` - Test Suite
- **Framework**: bats-core (Bash Automated Testing System)
- **Coverage**: Unit tests, integration tests
- **CI Integration**: Executed on every push/PR

---

## Key Design Decisions

### 1. Scheduling: cron.d vs crontab

**Decision**: Use `/etc/cron.d/` instead of `crontab -e`

**Rationale**:
- ✅ **Safe**: Does not overwrite existing user crontabs
- ✅ **Declarative**: File-based configuration is GitOps-friendly
- ✅ **Idempotent**: Re-running `make install` is safe
- ✅ **Reviewable**: Configuration is version-controlled
- ❌ **Old crontab approach**: `echo "..." | sudo crontab -` destroys all existing cron jobs

**Implementation**:
```makefile
# Makefile
sudo install -m 644 -o root -g root $(CRON_SRC) $(CRON_DEST)
```

**Security Requirements**:
- Permissions: **644 root:root** (mandatory for cron.d)
- No dots in filename (cron.d requirement)
- Must specify user in cron line format

### 2. Systemd Timer Support

**Decision**: Provide systemd timer as an alternative to cron

**Rationale**:
- ✅ **Persistent**: Runs missed jobs after system boot
- ✅ **No Overlap**: Prevents job collisions
- ✅ **Unified Logging**: `journalctl` integration
- ✅ **Modern**: Recommended for systemd-based distros
- ⚠️ **Trade-off**: More complex than cron, less portable

**Implementation**:
- `*.service`: Defines the actual job
- `*.timer`: Defines the schedule
- `Persistent=true`: Catch-up missed executions
- `OnBootSec=5min`: Run 5 minutes after boot if missed

### 3. GNU Makefile Standards

**Decision**: Adopt GNU Coding Standards for Makefile

**Rationale**:
- ✅ **PREFIX/DESTDIR**: Enables flexible installation and packaging
- ✅ **Standard Targets**: `all`, `install`, `uninstall`, `check`, `clean`
- ✅ **Packaging-Ready**: Easy DEB/RPM creation via DESTDIR
- ✅ **Developer-Friendly**: Familiar conventions

**Key Variables**:
```makefile
PREFIX ?= /usr/local    # Installation base directory
DESTDIR ?=               # Staging directory for packaging
bindir := $(PREFIX)/bin  # Binary installation directory
```

**Example Use Cases**:
```bash
# Standard installation
make install  # → /usr/local/bin/

# System package installation
make PREFIX=/usr install  # → /usr/bin/

# Package staging
make DESTDIR=/tmp/pkg PREFIX=/usr install  # → /tmp/pkg/usr/bin/
```

### 4. File Locations (FHS Compliance)

**Decision**: Store filters in `/var/opt/adguardhome/filters`

**Rationale**:
- ✅ **FHS 3.0**: `/var/opt/` for variable data of add-on packages
- ✅ **Persistent**: Survives system upgrades
- ✅ **Namespace**: Clear ownership by package name
- ❌ **Not `/tmp`**: tmpfs is cleared on reboot (Raspberry Pi optimization conflict)

**File Locations**:
| Type | Location | Standard |
|------|----------|----------|
| Executable | `/usr/local/bin/` or `/usr/bin/` | FHS 3.0 |
| Filters (Data) | `/var/opt/adguardhome/filters/` | FHS 3.0 |
| Cron Config | `/etc/cron.d/` | cron.d convention |
| Systemd Units | `/etc/systemd/system/` | systemd convention |

### 5. Raspberry Pi Optimization

**Decision**: Use tmpfs for temporary downloads, atomic move for updates

**Rationale**:
- ✅ **SD Card Longevity**: Minimize write cycles
- ✅ **Atomic Updates**: No partial writes (curl → tmpfs → mv)
- ✅ **Performance**: RAM is faster than SD card
- ⚠️ **Trade-off**: Requires sufficient RAM

**Implementation**:
```bash
# Download to tmpfs
TEMP_FILE=$(mktemp)
curl -o "$TEMP_FILE" "$DOWNLOAD_URL"

# Atomic move (only if content changed)
if ! cmp -s "$TEMP_FILE" "$TARGET_FILE"; then
  mv "$TEMP_FILE" "$TARGET_FILE"
fi
```

### 6. Error Handling Strategy

**Decision**: Fail-fast with explicit error messages

**Rationale**:
- ✅ **`set -euo pipefail`**: Exit on any error
- ✅ **Explicit Exit Codes**: 0 for success, 1 for failure
- ✅ **Descriptive Messages**: `[ERROR]` prefix for stderr
- ✅ **Idempotent**: Safe to re-run after failures

**Error Categories**:
1. **Network Failures**: Retry with exponential backoff (future)
2. **File I/O Errors**: Fail immediately with clear message
3. **Missing Dependencies**: Pre-flight checks

---

## Scheduling Architecture

### Execution Flow

```
┌─────────────────┐
│ Scheduler       │
│ (cron/systemd)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Main Script     │
│ (updater.sh)    │
└────────┬────────┘
         │
         ├─► Download filter (tmpfs)
         │
         ├─► Compare with existing
         │
         ├─► Update if changed (atomic mv)
         │
         └─► Exit 0 (success) or 1 (failure)
```

### Cron vs Systemd Timer

| Feature | cron.d | systemd timer |
|---------|--------|---------------|
| Simplicity | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Portability | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Persistent Jobs | ❌ | ✅ |
| Overlap Prevention | ❌ | ✅ |
| Unified Logging | ❌ | ✅ |
| Dependency Control | ❌ | ✅ |

**Recommendation**:
- **cron**: Simple deployments, always-on servers
- **systemd**: Production systems, laptops/desktops with intermittent uptime

---

## Error Handling Strategy

### Defensive Shell Scripting

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined var, pipe failure

# Explicit error handling
download_filter() {
  local url="$1"
  local output="$2"

  if ! curl -fsSL -o "$output" "$url"; then
    echo "[ERROR] Failed to download filter from $url" >&2
    return 1
  fi
}

# Pre-flight checks
check_dependencies() {
  local missing=()

  for cmd in curl mktemp; do
    if ! command -v "$cmd" >/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "[ERROR] Missing dependencies: ${missing[*]}" >&2
    exit 1
  fi
}
```

### Exit Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 0 | Success | Filter updated or no changes |
| 1 | Failure | Download error, I/O error, etc. |

**Note**: No distinction between "updated" and "no changes" (both return 0) because both are successful outcomes.

---

## Future Considerations

### Potential Enhancements

1. **Modularization**
   - Move reusable logic to `lib/` directory
   - Separate concerns: download, compare, install
   - Enable unit testing of individual functions

2. **Retry Logic**
   - Exponential backoff for network failures
   - Configurable retry attempts
   - Jitter to avoid thundering herd

3. **Monitoring Integration**
   - Prometheus metrics export
   - HealthChecks.io integration
   - Sentry error reporting

4. **Multi-Source Support**
   - Support multiple filter sources
   - Merge/deduplicate logic
   - Priority-based selection

5. **Configuration File**
   - Optional `/etc/adguardhome-updater.conf`
   - Override download URL, paths, schedule
   - Balance: simplicity vs flexibility

### Constraints

- **Maintain Simplicity**: Avoid feature creep
- **Zero Config by Default**: Work out-of-the-box
- **Minimal Dependencies**: bash + curl only
- **Backward Compatibility**: Respect existing installations

---

## References

### Standards & Guidelines

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [GNU Coding Standards](https://www.gnu.org/prep/standards/)
- [FHS 3.0](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)
- [systemd.timer](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [cron.d Format](https://man7.org/linux/man-pages/man5/crontab.5.html)

### Best Practices

- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [Bash Pitfalls](http://mywiki.wooledge.org/BashPitfalls)
- [Defensive BASH Programming](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/)

---

**Document Version**: 1.0
**Last Updated**: 2026-01-11
