# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Cursor, Copilot, etc.) when working with code in this repository.

## What This Repository Does

omnibus-gitlab builds full-stack Linux packages (DEB/RPM) that bundle all GitLab components into a single installable unit. It uses the [Omnibus](https://github.com/chef/omnibus) framework (Chef-based) to define software components, their build instructions, and post-install configuration via Chef cookbooks.

## Key Directories

- `config/software/` — ~108 software component definitions (gitaly, postgresql, nginx, redis, etc.). Each file defines how to fetch and compile a dependency.
- `config/projects/` — Top-level project definitions (gitlab CE/EE).
- `files/gitlab-cookbooks/` — Chef recipes that configure GitLab services at install time (run via `gitlab-ctl reconfigure`).
- `files/gitlab-ctl-commands/` — Ruby source for `gitlab-ctl` CLI subcommands.
- `lib/gitlab/` — Build automation: Rake tasks, version management, helpers for AWS/Docker/GCP.
- `spec/chef/` — RSpec + ChefSpec tests for cookbooks and ctl commands.

## Build & Test Commands

```bash
bundle install                    # Install dependencies

# Tests
bundle exec rspec                 # Run all tests
bundle exec rspec spec/chef/path/to/spec_file.rb          # Single spec file
bundle exec rspec spec/chef/path/to/spec_file.rb -e "desc" # Single example

# Linting
bundle exec rubocop               # Check style
bundle exec rubocop -a            # Auto-correct

# Building packages (requires full build environment)
bundle exec rake build:project    # Build omnibus package
```

## Architecture

### Configuration vs. Runtime
There are two distinct phases:
1. **Build time** — `config/software/` defines how to compile each component into `/opt/gitlab`.
2. **Runtime configuration** — `files/gitlab-cookbooks/` Chef recipes run when users execute `gitlab-ctl reconfigure`, writing config to `/var/opt/gitlab` and `/etc/gitlab`.

### Install Layout
- `/opt/gitlab` — bundled binaries and libraries
- `/etc/gitlab/gitlab.rb` — user-editable config
- `/var/opt/gitlab` — runtime data
- `/var/log/gitlab` — logs

### Component Versioning
Component versions are read from environment variables (e.g. `GITLAB_VERSION`, `GITALY_SERVER_VERSION`) or from `VERSION` files. `.custom_sources.yml` defines alternative source repos for components (used for security releases and forks).

### Chef Cookbook Structure
`files/gitlab-cookbooks/` contains one cookbook per service (e.g. `gitlab`, `gitaly`, `patroni`). Each cookbook follows standard Chef structure: `recipes/`, `attributes/`, `libraries/`, `templates/`. Tests live in `spec/chef/` mirroring the cookbook structure.

### gitlab-ctl Commands
`files/gitlab-ctl-commands/` contains individual Ruby files, each implementing a `gitlab-ctl` subcommand. Shared library code lives in `files/gitlab-ctl-commands/lib/gitlab_ctl/`. Tests mirror the source layout in `spec/chef/gitlab-ctl-commands/`.

## Merge Requests

Use the Default MR template (`.gitlab/merge_request_templates/Default.md`) when creating MRs. It requires:
- A "What does this MR do?" section
- Related issues
- Checklist including pipeline status, labeling (`~"workflow::ready for review"`), and UBT checks if applicable

## CI/CD

The pipeline (`.gitlab-ci.yml` + `gitlab-ci-config/`) runs:
1. Rubocop + RSpec tests
2. Multi-OS package builds (Ubuntu, Debian, CentOS, RHEL, SLES, Amazon Linux) across AMD64/ARM64
3. Docker image builds
4. QA tests via `gitlab-qa`

Package builds happen on dev.gitlab.org runners with full build toolchains; local development focuses on the Ruby/Chef layer tested via RSpec.
