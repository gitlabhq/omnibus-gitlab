---
name: oak-component-integration
description: >
  Integrating a new advanced component with OAK (Omnibus Adjacent Kubernetes).
  Use this skill when a task involves adding NGINX reverse proxy configuration,
  Helm values generation, component database documentation, CI jobs, or
  operator documentation for a new OAK component in omnibus-gitlab.
---

# OAK Component Integration Skill

This skill body is shared by all agents. The Claude skill at
`.claude/skills/oak-component-integration/SKILL.md` points here.

## When to use this skill

Use this skill when asked to:

- Integrate a new advanced component with OAK.
- Add NGINX reverse proxy configuration for a component.
- Add Helm values file generation for a component.
- Document a component database using `postgresql['component_databases']`
  (configuration and documentation only; the framework needs no code changes).
- Add a CI job for an OAK component.
- Write operator documentation for an OAK component.

## Source of truth

The full 6-step integration guide lives at:

**`doc/development/oak_component_integration.md`** in this repository.

Read that file before starting any implementation. It contains:

- Colocated and external-cluster setups, plus multi-node Omnibus
  considerations (per the OAK design document and its ADRs).
- Step-by-step instructions with code patterns.
- Links to the canonical OpenBao MRs as worked examples.
- Known gaps and open issues.

The guide includes a "Worked example: OpenBao" section with a table of all
reference MRs. Read that section for the full list of worked-example MRs
rather than duplicating it here.

## How to proceed

1. Read `doc/development/oak_component_integration.md` in full.
2. Confirm the component name and which of the 6 steps are in scope.
3. Use the issue template at `.gitlab/issue_templates/oak_component_integration.md`
   to track progress if an issue has not already been filed.
4. Work through each step in order, using the OpenBao MRs as the pattern.
   Read the OpenBao equivalents before generating NGINX templates or Ruby
   library files, and do not invent new attribute namespaces; follow
   `oak['components']['<name>']`.
5. Verify colocated and external-cluster setups before marking the
   integration complete.
