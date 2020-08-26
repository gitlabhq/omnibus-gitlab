<!-- After merging changes to this template, update the `Default description template for merge requests` -->
<!-- found uner Settings - General Merge Requests -->
## What does this MR do?

<!-- Briefly describe what this MR is about. -->

## Related issues

<!-- Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it. -->

## Checklist

See [Definition of done](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/CONTRIBUTING.md#definition-of-done).

For anything in this list which will not be completed, please provide a reason in the MR discussion

### Required
- [ ] Merge Request Title, and Description are up to date, accurate, and descriptive
- [ ] MR targeting the appropriate branch
- [ ] MR has a green pipeline on GitLab.com
- [ ] Pipeline is green on dev.gitlab.org if the change is touching anything besides documentation or internal cookbooks
- [ ] `trigger-package` has a green pipeline running against latest commit

### Expected (please provide an explanation if not completing)
- [ ] Test plan indicating conditions for success has been posted and passes
- [ ] Documentation created/updated
- [ ] Tests added
- [ ] Integration tests added to [GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa)
- [ ] Equivalent MR/issue for the [GitLab Chart](https://gitlab.com/gitlab-org/charts/gitlab) opened
