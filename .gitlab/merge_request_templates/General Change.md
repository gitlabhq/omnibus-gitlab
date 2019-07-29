## What does this MR do?

<!-- Briefly describe what this MR is about. -->

## Related issues

<!-- Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it. -->

## Checklist

See [Definition of done](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/CONTRIBUTING.md#definition-of-done).

- [ ] Changelog entry created. Not applicable for Documentation changes and minor changes.
- [ ] Documentation created/updated
- [ ] Tests added
- [ ] Integration tests added to [GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa), if applicable
- [ ] MR targeting `master` branch
- [ ] MR has a green pipeline on GitLab.com
- [ ] Equivalent MR/issue for CNG opened if applicable
- [ ] `trigger-package` has a green pipeline running against latest commit

### Reviewer Checklist

In addition to above, reviewer must:

- [ ] Pipeline is green on dev.gitlab.org if the change is not touching documentation or internal cookbooks
