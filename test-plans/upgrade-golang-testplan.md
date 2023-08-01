# `golang` component upgrade test plan

<!-- Copy and paste the following into your MR description. -->
## Test plan

- [ ] QA tests passed for FIPS and non FIPS builds
- [ ] Confirmed build was done with go 1.19 `strings /opt/gitlab/embedded/bin/gitaly  | grep 'go1\.' | tail -1`
- [ ] Confirmed Omnibus-built services that are owned by distribution are working
  - [ ] prometheus - (is scraping metrics)

     ```shell
     curl 'localhost:9090/api/v1/query?query=up'
     ```

  - [ ] pgbouncer exporter - (metrics endpoint returns data)

     1. Configured pgbouncer using https://docs.gitlab.com/ee/administration/postgresql/pgbouncer.html
     1. Run:

        ```shell
        curl http://localhost:9188/metrics
        ```

  - [ ] redis-exporter - (metrics endpoint returns data)

     ```shell
     curl http://localhost:9121/metrics
     ```

  - [ ] postgres-exporter - (metrics endpoint returns data)

     ```shell
     curl http://localhost:9187/metrics
     ```

  - [ ] node-exporter - (metrics endpoint returns data)

     ```shell
     curl http://localhost:9100/metrics
     ```

  - [ ] alertmanager - (test trigger an alert)

     1. Set `prometheus['listen_address'] = '0.0.0.0:9090'` in `/etc/gitlab/gitlab.rb` and run `sudo gitlab-ctl reconfigure`.
     1. Shut down `gitaly` service:

        ```shell
        gitlab-ctl stop gitaly
        ```

     1. Wait 5 minutes and check prometheus console `http://<gitlab host>:9090/alerts?search=` for service down alert.
     1. Start `gitaly` service:

        ```shell
        gitlab-ctl start gitaly
        ```

     1. Wait 5 minutes and check prometheus console `http://<gitlab host>:9090/alerts?search=` for service back up.
