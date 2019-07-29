<!---
Please read this!

Before you create a new issue, please make sure that you already ran

`sudo gitlab-ctl reconfigure`

Also make sure to search in https://gitlab.com/gitlab-org/omnibus-gitlab/issues,
to verify the issue you're about to submit isn't a duplicate.
--->

### Summary

<!-- Describe in short the bug you've encountered -->

### Steps to reproduce

<!-- How one can reproduce the issue - this is very important -->

### What is the current *bug* behavior?

<!-- What actually happens -->

### What is the expected *correct* behavior?

<!-- What you should see instead -->

### Relevant logs

<details>
<summary> Relevant logs </summary>
<pre>
<!-- 
Paste any relevant logs.
Live log output can be found with `sudo gitlab-ctl tail`.
Log files live in `/var/log/gitlab` by default.
-->

</pre>
</details>

### Details of package version

<details>
<summary>Provide the package version installation details</summary>
<pre>
<!--
For Debian, Ubuntu based systems, paste the output of:
`dpkg-query -l "gitlab-*"`

For RHEL based systems (CentOS, RHEL, OL, Scientific, OpenSUSE, SLES), paste the output of:
`rpm -qa | grep 'gitlab'`

If you can't provide these details, see https://about.gitlab.com/getting-help/ page on where to ask your question.
-->

</pre>
</details>

### Environment details

* Operating System: `REPLACE-WITH-DETAILS`
* Installation Target, remove incorrect values:
  * Bare Metal Machine
  * VM: Digital Ocean, AWS, GCP, Azure, Other `REPLACE-WITH-DETAILS`
  * Other: `REPLACE-WITH-DETAILS`
* Installation Type, remove incorrect values:
  * New Installation
  * Upgrade from version `REPLACE-WITH-DETAILS`
  * Other: `REPLACE-WITH-DETAILS`
* Is there any other software running on the machine: `REPLACE-WITH-DETAILS`
* Is this a single or multiple node installation?
* Resources
  * CPU: `REPLACE-WITH-DETAILS`
  * Memory total: `REPLACE-WITH-DETAILS`

### Configuration details

<details>
<summary> Provide the relevant sections of `/etc/gitlab/gitlab.rb` </summary>
<pre>
<!--
Paste the details but omit lines starting with `#`. Relevant lines can be retrieved by
running `grep -v -e '^#' -e '^$' /etc/gitlab/gitlab.rb`. Be certain to sanitize sensitive
configuration such as passwords and secrets.
-->

</pre>
</details>

/label ~bug 