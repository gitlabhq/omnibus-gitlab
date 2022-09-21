---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Add or remove Omnibus GitLab configuration options

## Add a configuration option

Adding a configuration option may happen during any release milestone.

- Add an entry to `files/gitlab-config-template/gitlab.rb.template` as
  documentation for administrators.
- Add a default value for the new option:
  - Values specific to a service should be set in the appropriate `files/gitlab-cookbooks/SERVICE_NAME/attributes/default.rb`
  - General values may be set in `files/gitlab-cookbooks/gitlab/attributes/default.rb`
- If the value requires calculations at runtime, then it should be added to
  the [defined `parse_variables` method in the related cookbook](new-services.md#additional-configuration-parsing-for-the-service).
- Consider whether the option should be added to [public attributes](public-attributes.md).

## Remove a configuration option

Distribution follows a strict process when removing configuration options to
minimize disruptions for Omnibus GitLab administrators.

1. Create an issue for deprecating the configuration option.
1. Create an issue for removing the configuration option that happens no
   less than three milestones after adding the deprecation messages.

### Deprecate the option

- [Add deprecation messages](adding-deprecation-messages.md).
- Remove the configuration options from `files/gitlab-config-template/gitlab.rb.template` to prevent their use in new installations.

### Final removal of the option

- Remove the default values for the deprecated option from `files/gitlab-cookbooks/gitlab/attributes/default.rb`.
