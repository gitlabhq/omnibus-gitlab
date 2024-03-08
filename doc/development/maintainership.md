---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Maintainership

## Scoped Maintainership

`omnibus-gitlab` is a comparatively complex project that handles both software
builds and deployment.

The build aspect covers the build toolchain, CI infrastructure, and dependency
management. The deployment aspect covers the installation and configuration of
GitLab at the user site along with upgrade tasks.

Because the two aspects are very different both in nature and the technical
stack involved, trainee-maintainers must spend a large amount of time to gain
both sets of competencies. Scoped maintainership decreases the time required
to onboard a new maintainer through separation of these core responsibilities.

### Build scope

The build scope covers all the parts of the codebase that build the artifacts
used to ship Omnibus GitLab.

This includes:

1. Omnibus project configurations and component software definitions.
1. Patches used in software definitions.
1. Libraries and Rake tasks used for build, release, and other maintenance
   activities.
1. CI configuration used for build, release, and other maintenance activities.
1. Infrastructure management required for the above.

Ideally, a build-scoped maintainer of `omnibus-gitlab` should be
well versed in all the above-mentioned topics. Several of these areas
get infrequent updates, therefore it is not fair to expect trainee-maintainers
to work on all of them. The following checklist provides a guideline to evaluate
the progress of a trainee-maintainer in the build scope.

NOTE:
We do not differentiate between the trainee-maintainer as the author
or reviewer in this list because `omnibus-gitlab` is a relatively stable
and mature project. The majority of merge requests follow established
patterns and only need to pass a set of well known tests that prove
the changes work as expected.

1. Author or review merge requests which update any 3 components from the list below that
   support high availability. The trainee-maintainer should gain familiarity with complex
   deployment scenarios and how to test them.

     1. PostgreSQL
     1. Patroni
     1. PgBouncer
     1. Consul
     1. Redis
     1. Sentinel

1. Author or review a merge request which updates any of our "runtime" environments, preferably
   Ruby/Go. This ensures familiarity with the
   [Omnibus Builder](https://gitlab.com/gitlab-org/gitlab-omnibus-builder)
   project and how it relates to `omnibus-gitlab`.

     1. Ruby
     1. Go
     1. Python

1. Author or review a Mattermost version update merge request. Ensures familiarity with its update
   process and Distribution team's communication process with the Mattermost team.

1. Author or review merge requests which update 5 other components.

1. Author or review 3 merge requests which modify CI configuration.

1. Author or review 3 merge requests which refactor build related code.

1. **OPTIONAL**: Author or review 1 merge request which modifies the `omnibus` project. This
   is an optional requirement , because updates to `omnibus` itself are
   comparatively rare. It is highly recommended that the Maintainers look through
   the commits we have [added on top of the upstream tag](https://gitlab.com/gitlab-org/omnibus/-/compare/9.0.19...9.0.19-stable).

### Deploy scope

TBA

### Architectural changes

Architectural changes to `omnibus-gitlab` project, as well as the `omnibus`
project require sign-off from current full maintainers of the project.
