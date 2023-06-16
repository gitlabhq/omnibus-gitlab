<!-- After merging changes to this template, update the `Default description template for merge requests` -->
<!-- found under Settings - General Merge Requests -->
## What does this MR do?

<!-- Briefly describe what this MR is about. -->

%{first_multiline_commit}

## Related issues

<!-- Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it. -->

## Checklist

See [Definition of done](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/CONTRIBUTING.md#definition-of-done).

For anything in this list which will not be completed, please provide a reason in the MR discussion.

### Required

- [ ] MR title and description are up to date, accurate, and descriptive.
- [ ] MR targeting the appropriate branch.
- [ ] Latest Merge Result pipeline is green.
- [ ] When ready for review, MR is labeled "~workflow::ready for review" per the [Distribution MR workflow](https://about.gitlab.com/handbook/engineering/development/enablement/systems/distribution/merge_requests.html).

#### For GitLab team members

If you don't have access to this, the reviewer should trigger these jobs for you during the review process.

- [ ] The manual `Trigger:ee-package` jobs have a green pipeline running against latest commit.
  - To debug QA failures, refer to the [Investigate QA failures](https://about.gitlab.com/handbook/engineering/quality/quality-engineering/enablement-saas-platforms-qe-team/distribution/#investigate-qa-failures) section.
- [ ] If `config/software` or `config/patches` directories are changed, make sure the `build-package-on-all-os` job within the `Trigger:ee-package` downstream pipeline succeeded.
- [ ] If you are changing anything SSL related, then the `Trigger:package:fips` manual job within the `Trigger:ee-package` downstream pipeline must succeed.
- [ ] If CI configuration is changed, the branch must be pushed to [`dev.gitlab.org`](https://dev.gitlab.org/gitlab/omnibus-gitlab) to confirm regular branch builds aren't broken.

### Expected (please provide an explanation if not completing)

- [ ] Test plan indicating conditions for success has been posted and passes.
- [ ] Documentation created/updated.
- [ ] Tests added.
- [ ] Integration tests added to [GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa).
- [ ] Equivalent MR/issue for the [GitLab Chart](https://gitlab.com/gitlab-org/charts/gitlab) opened.
- [ ] Validate potential values for new configuration settings. Formats such as integer `10`, duration `10s`, URI `scheme://user:passwd@host:port` may require quotation or other special handling when rendered in a template and written to a configuration file.
