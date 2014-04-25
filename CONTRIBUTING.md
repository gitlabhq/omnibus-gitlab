These are the contributing guidelines for omnibus-gitlab issues and merge
requests.

- Include the omnibus-gitlab version when discussing behavior: `dpkg-query -W
  gitlab` or `rpm -q gitlab`.
- Be careful when pasting log output of `gitlab-ctl reconfigure`; Chef happily
  writes secrets to the log.
