# MagSafe Guard Documentation Index

> **Fork quick start:** Feature status, security actions, build, and Apple signing → [README.md](../README.md) · [README.de.md](../README.de.md)

This documentation is organized by audience and role to help you find the information you need quickly.

## 🚀 Quick Start by Role

### For Users

- **[User guide (mini)](features/user-guide.md)** — EN · [DE](features/user-guide.de.md): **operation profiles** (Beginner / Normal / Discreet / Panic), impact labels, **`magsafeguard-cli`**, discreet use, **panic** + **paranoid** protection modes
- [Operating Modes & Flows](features/operating-modes.md) - What each state/mode does (with diagrams)
- [Behavior Gaps](features/behavior-gaps.md) - Known UI vs runtime mismatches
- [Panic & Paranoid modes](features/panic-modes.md) - Panic (v0.5) + Paranoid (v0.6) shipped; [legal review gate](maintainers/legal-review-gate.md) informed self-review done
- [Future ideas (scratch pad)](features/future-ideas.md) - Uncommitted thought fragments (e.g. LAN trigger from phone)
- [Building and Running](maintainers/building-and-running.md) - Get MagSafe Guard running on your Mac
- [Troubleshooting](maintainers/troubleshooting.md) - Common issues and solutions
- [Legal review gate (Paranoid / DE/EU)](maintainers/legal-review-gate.md) - Sign-off before wide public beta
- [Feature Flags](features/flags.md) - Configure advanced features
- [Accessibility Features](features/accessibility.md) - VoiceOver and accessibility support

### For Contributors

- [AGENTS.md](../AGENTS.md) - AI agent rules (Cursor, GitHub Copilot)
- [Fork independence](FORK_INDEPENDENCE.md) - Fork vs upstream (read this first)
- [Product Requirements Document (PRD)](PRD.md) - Project vision and scope
- [Requirements](REQUIREMENTS.md) - Detailed technical specifications
- [Architecture Overview](architecture/architecture-overview.md) - System design
- [Testing Guide](maintainers/testing-guide.md) - How to write and run tests
- [Git Hooks](devops/git-hooks.md) - Commit standards and automation

### For Maintainers

- [Development Setup](DEVELOPMENT.md) - Complete development environment
- **[Stabilization checklist](maintainers/stabilization-checklist.md)** — v0.5.x → daily driver (current focus)
- **[Manual test checklist v0.5.3](maintainers/manual-test-0.5.3.md)** — abhakbare Smoke-Tests (DE)
- [CI/CD Workflows](devops/ci-cd-workflows.md) - GitHub Actions and automation
- [Code Signing Guide](maintainers/code-signing.md) - macOS app signing process
- [Crash Prevention Guide](maintainers/crash-prevention-guide.md) - Stability best practices
- [Release Process](CHANGELOG.md) - Version history and release notes

### For Security Auditors

- [Security Policy](SECURITY.md) - Vulnerability reporting
- [Security Implementation Guide](security/security-implementation-guide.md) - Security architecture
- [Authentication Hardening](security/authentication-hardening.md) - Biometric security
- [Semgrep Integration](security/semgrep.md) - Static security analysis

## 📚 Documentation by Category

### Project Overview

- [Product Requirements Document (PRD)](PRD.md) - What we're building and why
- [Technical Requirements](REQUIREMENTS.md) - Detailed specifications
- [Quality Assurance](QA.md) - Testing procedures and standards
- [Contributors](CONTRIBUTORS.md) - Project acknowledgments
- [Changelog](CHANGELOG.md) - Release history

### Architecture & Design

- [Architecture Overview](architecture/architecture-overview.md) - High-level system design
- [Swift Project Architecture: Best Practices](architecture/swift-project-architecture-practices.md) - Swift patterns and practices
- [Power Monitor Service Guide](architecture/power-monitor-service-guide.md) - Core detection service
- [Authentication Flow Design](architecture/auth-flow-design.md) - Biometric authentication
- [Menu Bar App Guide](architecture/menu-bar-app-guide.md) - macOS menu bar implementation
- [Menu Bar Design Guide](architecture/menu-bar-design-guide.md) - UI/UX patterns
- [Settings and Persistence Guide](architecture/settings-persistence-guide.md) - Configuration management
- [Demo Window Guide](architecture/demo-window-guide.md) - Demo mode implementation

### Development & Testing

- [Development Setup](DEVELOPMENT.md) - Complete development guide
- [Building and Running](maintainers/building-and-running.md) - Quick start guide
- [Testing Guide](maintainers/testing-guide.md) - Unit and integration testing
- [Test Coverage](maintainers/test-coverage.md) - Coverage reports and metrics
- [Acceptance Tests](maintainers/acceptance-tests.md) - Manual testing procedures
- [Stabilization checklist](maintainers/stabilization-checklist.md) - v0.5.x daily-driver focus
- [Troubleshooting](maintainers/troubleshooting.md) - Common issues

### Code Quality & Stability

- [Crash Prevention Guide](maintainers/crash-prevention-guide.md) - Building stable macOS apps
- [Crash Quick Reference](maintainers/crash-quick-reference.md) - Debugging crashes
- [Code Signing Guide](maintainers/code-signing.md) - macOS signing process
- [Code Signing Implementation](maintainers/code-signing-implementation.md) - Detailed signing steps

### DevOps & CI/CD

- [CI/CD Workflows](devops/ci-cd-workflows.md) - GitHub Actions automation
- [CI Caching Strategy](devops/ci-caching-strategy.md) - Build optimization
- [Testing in CI](devops/testing-in-ci.md) - Continuous integration setup
- [Git Hooks](devops/git-hooks.md) - Pre-commit automation
- [Commit Message Enforcement](devops/commit-message-enforcement.md) - Conventional commits

### Security & Compliance

- [Security Policy](SECURITY.md) - Vulnerability disclosure
- [Security Implementation Guide](security/security-implementation-guide.md) - Security architecture
- [Authentication Hardening](security/authentication-hardening.md) - Biometric security measures
- [Logging Privacy](security/logging-privacy.md) - Privacy-preserving logging
- [Semgrep Integration](security/semgrep.md) - Static security analysis
- [Security Settings](security/security-settings.md) - Repository security checklist (generic)

Archived upstream-only: [SSDLC case study](archive/ssdlc-case-study.md) · [Security workflows](archive/SECURITY_WORKFLOWS.md)

### Features & Configuration

- [User guide (mini)](features/user-guide.md) · [DE](features/user-guide.de.md)
- [Operating modes](features/operating-modes.md)
- [Panic & Paranoid modes](features/panic-modes.md)
- [Example / bundled trigger scripts](examples/scripts/README.md) → [`MagSafeGuard/Resources/TriggerScripts/`](../MagSafeGuard/Resources/TriggerScripts/)
- [Feature Flags](features/flags.md) - Runtime configuration options
- [Accessibility Features](features/accessibility.md) - VoiceOver and accessibility support

### Task Management

- [Taskfile Commands](../tasks/README.md) - Task automation reference

## 📝 Documentation Standards

- **Markdown Format**: All documentation uses GitHub-flavored Markdown
- **Descriptive Names**: Files use kebab-case naming (e.g., `menu-bar-guide.md`)
- **Clear Headers**: Each document starts with a title and brief description
- **Updated Content**: Documentation is kept in sync with code changes
- **Role-Based**: Content is organized by audience needs

## 🔍 Can't Find What You Need?

1. Check the role-based sections above
2. Use your editor's file search in the `docs/` directory
3. Review the [Architecture Overview](architecture/architecture-overview.md) for system understanding
4. See [Troubleshooting](maintainers/troubleshooting.md) for common issues
