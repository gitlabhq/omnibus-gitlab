---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `nginx` component upgrade
---

We need to verify that the `nginx` upgrade won't break the 2 extensions:

- `ngx_security_headers`
- `nginx-module-vts`

Copy the following test plan to a comment of the merge request
that upgrades the component.

````markdown
## Test plan

- [ ] Checked nginx [changelog](https://nginx.org/en/CHANGES) for potential breaking changes.
- [ ] Start a new pipeline and trigger `Trigger::ee-package`.
- Test the library:
  - [ ] `version`

    ```shell
    IMAGE='registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ee:renovate-nginx-nginx-1-x'

    docker run -it --rm --platform="linux/amd64" \
    $IMAGE /opt/gitlab/embedded/sbin/nginx -v

    ```

  - [ ] `execution`

    ```shell
    docker run -it --rm --platform="linux/amd64" \
    $IMAGE bash
    cat > nginx.conf <<EOF
    worker_processes  1;
    events {
        worker_connections  1024;
    }
    http {
        hide_server_tokens on;
        security_headers on;
        vhost_traffic_status_zone;
        default_type  application/octet-stream;
        sendfile        on;
        server {
            listen       80;
            server_name  localhost;

            location /status {
                vhost_traffic_status_display;
                vhost_traffic_status_display_format prometheus;
            }
        }
    }
    EOF

    /opt/gitlab/embedded/sbin/nginx -c /nginx.conf
    curl -s -D - "http://127.0.0.1" -o /dev/null
    # You should not see "Server:" header in the response
    curl -s "http://127.0.0.1/status"
    # You should see the VTS metrics
    ```
````
