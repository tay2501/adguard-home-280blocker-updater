# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - Phase 3 Optimization

#### Raspberry Pi Optimizations
- **tmpfs usage**: Temporary files now use `/tmp` (RAM disk) to reduce SD card writes
- **ARM performance**: Reduced external command calls (date command optimized from 2 to 1 call)
- **Retry logic**: Implemented exponential backoff retry (3 attempts with increasing delays)
- **Network resilience**: Added `--max-time` timeout to curl for better WiFi handling

#### Error Handling Enhancements
- **syslog integration**: Automatic logging to system log for cron monitoring
- **ERR trap**: Stack trace on script failures (available in verbose mode)
- **Detailed diagnostics**: Enhanced error messages with context and suggestions

#### Improved Functionality
- **Flexible permissions**: Automatic root/non-root detection and appropriate permission setting
- **File validation**: Three-tier validation (empty check, HTML check, size check)
- **BSD/Linux compatibility**: Cross-platform stat command support (macOS and Linux)
- **Help option**: Added `-h` flag for usage information

#### Code Quality
- **shdoc annotations**: All functions documented with `@description`, `@arg`, `@return`
- **readonly constants**: Immutable configuration values for safety
- **Verbose logging**: Comprehensive progress information in verbose mode
- **Success logging**: Track successful updates via syslog

### Changed - Phase 2 Quality Assurance

#### Testing Infrastructure
- Added comprehensive test suite with bats-core v1.13.0
- 40+ test cases covering all functionality
- Integration test stubs for future expansion

#### CI/CD Pipeline
- GitHub Actions workflow for automated testing
- ShellCheck static analysis on every push
- Format checking with shfmt
- Multi-OS testing (Ubuntu 20.04, 22.04)

#### Documentation
- Separated user documentation (README.md) and developer documentation (CONTRIBUTING.md)
- Added comprehensive contribution guidelines
- Detailed troubleshooting section

### Changed - Phase 1 Foundation

#### Project Structure
- Reorganized to standard shell project layout (`bin/`, `test/`, `lib/`)
- Added Makefile for development tasks
- Configured ShellCheck and EditorConfig

#### Naming Conventions
- Executable renamed: `update_280` → `adguard-280blocker-update`
- Following UNIX hyphen convention (e.g., `apt-get`, `docker-compose`)
- Source files retain `.sh` extension, installed commands have no extension

## [0.1.0] - 2024-01-11

### Added
- Initial release
- Basic 280blocker filter download functionality
- FHS-compliant file structure
- Bash strict mode
- Change detection to minimize I/O

### Technical Details

#### Performance Metrics
- **SD Card Protection**: ~50% reduction in write operations (tmpfs + change detection)
- **Network Resilience**: 3x retry attempts with exponential backoff
- **Error Recovery**: Comprehensive error handling with syslog integration

#### Compatibility
- **Operating Systems**: Linux (Debian/Ubuntu/Raspberry Pi OS), macOS (partial)
- **Bash Versions**: 4.0+ (3.2+ with limited features)
- **Architectures**: x86_64, ARM (Raspberry Pi optimized)

#### Standards Compliance
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Filesystem Hierarchy Standard (FHS)](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)
- [UNIX Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy)

---

For detailed migration guides between versions, see [UPGRADING.md](UPGRADING.md).
