---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan for Go component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] QA tests passed for FIPS and non FIPS builds, including triggering the `build-package-on-all-os` job
- [ ] Confirmed build was done with desired version of go `strings /opt/gitlab/embedded/bin/gitaly  | grep 'go1\.' | tail -1`
- [ ] Confirmed Omnibus-built services that are owned by distribution are working
  - [ ] Prometheus - (is scraping metrics)

    ```shell
    curl 'localhost:9090/api/v1/query?query=up'
    ```

  - [ ] PgBouncer exporter - (metrics endpoint returns data)

    1. [Configure PgBouncer](https://docs.gitlab.com/administration/postgresql/pgbouncer/).
    1. Run:

       ```shell
       curl "http://localhost:9188/metrics"
       ```

  - [ ] `redis-exporter` - (metrics endpoint returns data)

    ```shell
    curl "http://localhost:9121/metrics"
    ```

  - [ ] `postgres-exporter` - (metrics endpoint returns data)

    ```shell
    curl "http://localhost:9187/metrics"
    ```

  - [ ] `node-exporter` - (metrics endpoint returns data)

    ```shell
    curl "http://localhost:9100/metrics"
    ```

  - [ ] `alertmanager` - (test trigger an alert)

    1. Set `prometheus['listen_address'] = '0.0.0.0:9090'` in `/etc/gitlab/gitlab.rb` and run `sudo gitlab-ctl reconfigure`.
    1. Shut down `gitaly` service:

       ```shell
       gitlab-ctl stop gitaly
       ```

    1. Wait 5 minutes and check Prometheus console `http://<gitlab host>:9090/alerts?search=` for service down alert.
    1. Start `gitaly` service:

       ```shell
       gitlab-ctl start gitaly
       ```

    1. Wait 5 minutes and check Prometheus console `http://<gitlab host>:9090/alerts?search=` for service back up.
````
