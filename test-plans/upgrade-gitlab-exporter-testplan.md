# `gitlab-exporter` component upgrade test plan

<!-- Copy and paste the following into your MR description. -->
## Test plan

- [ ] Check `gitlab-exporter` project repository for potential breaking changes at https://gitlab.com/gitlab-org/ruby/gems/gitlab-exporter.

- [ ] Green pipeline with `Trigger:ee-package` and `build-package-on-all-os`.

- [ ] `gitlab-exporter` starts. Run `sudo gitlab-ctl status gitlab-exporter` and check output
  to ensure `gitlab-exporter` started successfully.

  ```shell
  sudo gitlab-ctl status gitlab-exporter
  ```

- [ ] Check exporter version. Run `/opt/gitlab/embedded/bin/gem list gitlab-exporter`

  ```shell
  /opt/gitlab/embedded/bin/gem list gitlab-exporter
  ```

- [ ] Check that `gitlab-exporter` endpoint can be queried.

  ```shell
  curl --silent http://localhost:9168/metrics | head -n5
  ```

- [ ]  Check that prometheus scrapes `gitlab_exporter_database`, `gitlab_exporter_ruby` and `gitlab_exporter_sidekiq` by poking metrics endpoint.

  ```shell
  curl --silent http://localhost:9090/metrics | grep gitlab_exporter
  ```
