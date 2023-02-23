<!-- Read through https://docs.gitlab.com/omnibus/development/add-remove-configuration-options.html -->
## What does this MR do?

<!-- Briefly describe what this MR is about. -->

%{first_multiline_commit}

## Related issues

<!-- Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it. -->

## Deprecation schedule

<!-- Customers need time to react to deprecation, the preferred warning time is 3 release milestones before a feature is actually removed. -->

| Configuration Key | Deprecation Date | Removal Date |
|-|-|-|
| TBD | TBD | TBD |

## Checklist

See [Definition of done](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/CONTRIBUTING.md#definition-of-done).

For anything in this list which will not be completed, please provide a reason in the MR discussion

### Required

- [ ] Merge Request Title, and Description are up to date, accurate, and descriptive
- [ ] MR targeting the appropriate branch
- [ ] MR has a green pipeline on GitLab.com
- [ ] Pipeline is green on the [dev.gitlab.org](https://dev.gitlab.org/gitlab/omnibus-gitlab/-/pipelines) mirror for this branch if the change is touching anything besides documentation or internal cookbooks. Please note that feature branches are not automatically mirrored to dev.gitlab.org, and should be manually pushed whenever necessary.
- [ ] `trigger-package` has a green pipeline running against latest commit
- [ ] When ready for review, MR is labeled "~workflow::ready for review" per the [Distribution MR workflow](https://about.gitlab.com/handbook/engineering/development/enablement/systems/distribution/merge_requests.html)

### Expected (please provide an explanation if not completing)

- [ ] Test plan indicating conditions for success has been posted and passes
- [ ] Documentation created/updated
- [ ] Tests updated
- [ ] Equivalent MR/issue for the [GitLab Chart](https://gitlab.com/gitlab-org/charts/gitlab) opened
- [ ] Notify Product for inclusion in release notes
