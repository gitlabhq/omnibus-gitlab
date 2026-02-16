---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `nginx-module-vts` component upgrade
---

Copy the test plan below to a comment of the merge request
that upgrades the component.

## Test plan

- [ ] Checked `nginx-vts` module [changelog](https://github.com/vozlt/nginx-module-vts/blob/master/CHANGELOG.md) for potential breaking changes.
- [ ] Started a new pipeline and trigger `Trigger::ee-package`.
- [ ] Started a new pipeline on `dev.gitlab.org` for the branch.
  - Rebase to tip of `dev/master` if needed.
- Test the library:
  - [ ] Confirm `nginx` has `vts` support
    - The command `/opt/gitlab/embedded/sbin/nginx -V` should include `--add-module=/opt/gitlab/src/nginx_modules/nginx-module-vts` in the return.
  - [ ] Check the version of the `vts` module.
    - Create a minimal `nginx.conf`:

    ```shell
    worker_processes  1;
    events {
        worker_connections  1024;
    }
    http {
        vhost_traffic_status_zone;
        default_type  application/octet-stream;
        sendfile        on;
        keepalive_timeout  65;
        server {
            listen       80;
            server_name localhost;
            location /status {
                vhost_traffic_status_display;
                vhost_traffic_status_display_format html;
            }
        }
    }
    ```

    - Start `nginx` with the configuration with `/opt/gitlab/embedded/sbin/nginx -c nginx.conf`
    - Check the version with `curl -ssL localhost:80/status/format/json | jq '.moduleVersion'`
  - [ ] `function`
    - Follow the instructions to [configure](../../settings/nginx.md#configure-advanced-metrics-with-vts-module) the VTS module.
    - Run `curl -s -g "http://localhost:9090/api/v1/query?query=rate(nginx_vts_server_request_seconds_total[5m])"`
    - The command should return `"status":"success"...`
