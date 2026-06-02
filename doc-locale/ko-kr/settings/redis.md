---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Redis 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## 대체 로컬 Redis 인스턴스 사용 {#using-an-alternate-local-redis-instance}

Linux 패키지 설치에는 기본적으로 Redis가 포함됩니다. GitLab 애플리케이션을 자신의 *로컬*에서 실행 중인 Redis 인스턴스로 지정하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   # Disable the bundled Redis
   redis['enable'] = false

   # Redis via TCP
   gitlab_rails['redis_host'] = '127.0.0.1'
   gitlab_rails['redis_port'] = 6379

   # OR Redis via Unix domain sockets
   gitlab_rails['redis_socket'] = '/tmp/redis.sock' # defaults to /var/opt/gitlab/redis/redis.socket

   # Password to Authenticate to alternate local Redis if required
   gitlab_rails['redis_password'] = '<redis_password>'
   ```

1. GitLab을 재구성합니다. 변경 사항이 적용되도록 합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 번들된 Redis를 TCP를 통해 도달 가능하게 만들기 {#making-the-bundled-redis-reachable-via-tcp}

Linux 패키지에서 관리하는 Redis 인스턴스를 TCP를 통해 도달 가능하게 만들려면 다음 설정을 사용합니다:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   redis['port'] = 6379
   redis['bind'] = '127.0.0.1'
   redis['password'] = 'redis-password-goes-here'
   ```

1. 파일을 저장하고 GitLab을 다시 구성하여 변경 사항을 적용합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Linux 패키지를 사용하여 Redis 전용 서버 설정하기 {#setting-up-a-redis-only-server-using-the-linux-package}

Redis를 GitLab 애플리케이션과 다른 별도의 서버에 설정하려면 [Linux 패키지 설치에서 번들된 Redis](https://docs.gitlab.com/administration/redis/standalone/)를 사용할 수 있습니다.

## 여러 Redis 인스턴스로 실행 {#running-with-multiple-redis-instances}

<https://docs.gitlab.com/administration/redis/replication_and_failover/#running-multiple-redis-clusters>를 참조하세요.

## Redis Sentinel {#redis-sentinel}

<https://docs.gitlab.com/administration/redis/replication_and_failover/>를 참조하세요.

## 장애 조치 설정에서 Redis 사용 {#using-redis-in-a-failover-setup}

<https://docs.gitlab.com/administration/redis/replication_and_failover/>를 참조하세요.

## Google Cloud Memorystore 사용 {#using-google-cloud-memorystore}

Google Cloud Memorystore는 [Redis `CLIENT` 명령을 지원하지 않습니다](https://cloud.google.com/memorystore/docs/redis/product-constraints#blocked_redis_commands). 기본적으로 Sidekiq은 디버깅 목적으로 `CLIENT`을 설정하려고 시도합니다. 다음 구성 설정을 통해 비활성화할 수 있습니다:

```ruby
gitlab_rails['redis_enable_client'] = false
```

## Redis 연결 수를 기본값을 초과하여 증가시키기 {#increasing-the-number-of-redis-connections-beyond-the-default}

기본적으로 Redis는 10,000개의 클라이언트 연결만 허용합니다. 10,000개를 초과하는 연결이 필요한 경우 `maxclients` 속성을 필요에 맞게 설정합니다. `maxclients` 속성을 조정하면 `fs.file-max` 시스템 설정도 고려해야 합니다(예: `sysctl -w fs.file-max=20000`)

```ruby
redis['maxclients'] = 20000
```

## Redis용 TCP 스택 튜닝 {#tuning-the-tcp-stack-for-redis}

다음 설정은 보다 효율적인 Redis 서버 인스턴스를 활성화하기 위한 것입니다. `tcp_timeout`은 Redis 서버가 유휴 TCP 연결을 종료하기 전에 대기하는 시간(초)입니다. `tcp_keepalive`은 통신이 없을 때 클라이언트로 TCP ACK를 보내는 조정 가능한 시간(초) 설정입니다.

```ruby
redis['tcp_timeout'] = "60"
redis['tcp_keepalive'] = "300"
```

## 호스트 이름에서 IP 공시 {#announce-ip-from-hostname}

현재 Redis에서 호스트 이름을 활성화하는 유일한 방법은 `redis['announce_ip']`을 설정하는 것입니다. 그러나 이것은 Redis 인스턴스마다 고유하게 설정되어야 합니다. `announce_ip_from_hostname`은 이를 켜거나 끌 수 있는 부울입니다. 호스트 이름은 `hostname -f` 명령에서 동적으로 호스트 이름을 유추하여 동적으로 가져옵니다.

```ruby
redis['announce_ip_from_hostname'] = true
```

## Redis 캐시 인스턴스를 LRU로 설정 {#setting-the-redis-cache-instance-as-an-lru}

여러 Redis 인스턴스를 사용하면 Redis를 [LRU(최근에 사용되지 않은) 캐시](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/)로 구성할 수 있습니다. Redis 캐시, 속도 제한 및 리포지토리 캐시 인스턴스에서만 이를 수행해야 합니다. Redis 큐, 공유 상태 인스턴스 및 tracechunks 인스턴스는 LRU로 구성되지 않아야 합니다. 왜냐하면 이들은 지속적이어야 하는 데이터(예: Sidekiq 작업)를 포함하기 때문입니다.

메모리 사용을 32GB로 제한하려면 다음을 사용할 수 있습니다:

```ruby
redis['maxmemory'] = "32gb"
redis['maxmemory_policy'] = "allkeys-lru"
redis['maxmemory_samples'] = 5
```

## SSL(Secure Sockets Layer) 사용 {#using-secure-sockets-layer-ssl}

Redis를 SSL 뒤에서 실행하도록 구성할 수 있습니다.

### SSL 뒤에서 Redis 서버 실행 {#running-redis-server-behind-ssl}

1. Redis 서버를 SSL 뒤에서 실행하려면 `/etc/gitlab/gitlab.rb`에서 다음 설정을 사용할 수 있습니다. [`redis.conf.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/redis/templates/default/redis.conf.erb)의 TLS/SSL 섹션을 참조하여 가능한 값에 대해 알아봅니다:

   ```ruby
   redis['tls_port']
   redis['tls_cert_file']
   redis['tls_key_file']
   ```

1. 필수 값을 지정한 후 GitLab을 다시 구성하여 변경 사항을 적용합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> 일부 `redis-cli` 바이너리는 TLS를 통해 Redis 서버에 직접 연결하도록 지원하지 않습니다. `redis-cli`이 `--tls` 플래그를 지원하지 않으면 [`stunnel`](https://redis.io/blog/stunnel-secure-redis-ssl/)와 같은 것을 사용하여 디버깅 목적으로 `redis-cli`을 사용하여 Redis 서버에 연결해야 합니다.

### GitLab 클라이언트가 SSL을 통해 Redis 서버에 연결하도록 하기 {#make-gitlab-client-connect-to-redis-server-over-ssl}

GitLab 클라이언트 SSL 지원을 활성화하려면:

1. `/etc/gitlab/gitlab.rb`에 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['redis_ssl'] = true
   ```

1. GitLab을 재구성합니다. 변경 사항이 적용되도록 합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## SSL 인증서 {#ssl-certificates}

Redis용 사용자 지정 SSL 인증서를 사용하는 경우 [신뢰할 수 있는 인증서](ssl/_index.md#install-custom-public-certificates)에 추가해야 합니다.

## 이름이 바뀐 명령 {#renamed-commands}

기본적으로 `KEYS` 명령은 보안 조치로 비활성화됩니다.

이 명령 또는 다른 명령을 난독화하거나 비활성화하려면 `redis['rename_commands']` 설정을 `/etc/gitlab/gitlab.rb`에서 편집하여 다음과 같이 만듭니다:

```ruby
redis['rename_commands'] = {
  'KEYS': '',
  'OTHER_COMMAND': 'VALUE'
}
```

- `OTHER_COMMAND`은 수정하려는 명령입니다
- `VALUE`은 다음 중 하나여야 합니다:
  1. 새로운 명령 이름입니다.
  1. `''`(명령을 완전히 비활성화합니다).

이 기능을 비활성화하려면:

1. `redis['rename_commands'] = {}`을 `/etc/gitlab/gitlab.rb` 파일에 설정합니다
1. `sudo gitlab-ctl reconfigure`을 실행합니다

## Lazy freeing {#lazy-freeing}

Redis 4에서는 [lazy freeing](https://antirez.com/news/93)을 도입했습니다. 이는 큰 값을 해제할 때 성능을 개선할 수 있습니다.

이 설정은 기본적으로 `false`입니다. 이를 활성화하려면 다음을 사용할 수 있습니다:

```ruby
redis['lazyfree_lazy_eviction'] = true
redis['lazyfree_lazy_expire'] = true
redis['lazyfree_lazy_server_del'] = true
redis['replica_lazy_flush'] = true
```

## 스레드된 I/O {#threaded-io}

Redis 6에서는 스레드된 I/O를 도입했습니다. 이를 통해 여러 코어에 걸쳐 쓰기를 확장할 수 있습니다.

이 설정은 기본적으로 비활성화됩니다. 이를 활성화하려면 다음을 사용할 수 있습니다:

```ruby
redis['io_threads'] = 4
redis['io_threads_do_reads'] = true
```

### 클라이언트 시간 초과 {#client-timeouts}

기본적으로 [Redis용 Ruby 클라이언트](https://github.com/redis-rb/redis-client?tab=readme-ov-file#configuration)는 연결, 읽기 및 쓰기 시간 초과에 기본값 1초를 사용합니다. 로컬 네트워크 지연을 고려하도록 이 값들을 조정해야 할 수도 있습니다. 예를 들어 `Connection timed out - user specified timeout` 오류가 표시되면 `connect_timeout`을 올려야 할 수도 있습니다:

```ruby
gitlab_rails['redis_connect_timeout'] = 3
gitlab_rails['redis_read_timeout'] = 1
gitlab_rails['redis_write_timeout'] = 1
```

## 일반 텍스트 저장소 없이 Redis 클라이언트에 민감한 구성 제공 {#provide-sensitive-configuration-to-redis-clients-without-plain-text-storage}

자세한 내용은 [구성 문서](configuration.md#provide-redis-password-to-redis-server-and-client-components)의 예를 참조하세요.

## Redis 대신 Valkey 사용 {#using-valkey-instead-of-redis}

{{< history >}}

- GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113) 되었습니다([베타](https://docs.gitlab.com/policy/development_stages_support/#beta)).
- GitLab 19.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9383)합니다.

{{< /history >}}

[Valkey](https://valkey.io/)는 Redis와 호환되는 키-값 저장소로 Redis의 드롭인 대체물로 사용할 수 있습니다. Valkey는 Redis OSS 7.2 및 모든 이전의 오픈소스 Redis 버전과 호환됩니다.

Valkey 사용 시:

- 서비스 이름은 `redis`으로 유지됩니다. `gitlab-ctl restart redis`을 사용하여 서비스를 관리합니다. `gitlab-ctl restart valkey`은 아닙니다.
- 로그 파일은 `/var/log/gitlab/redis/`에 작성되고, 별도의 `valkey` 디렉토리에는 아닙니다.
- 데이터 디렉토리는 `/var/opt/gitlab/redis/`으로 유지됩니다.
- 구성 파일은 `redis.conf`으로 유지됩니다.
- `gitlab-ctl` 도구는 Redis 상호작용에 `redis-cli`을 계속 사용합니다.
- 문제 해결을 위해 `valkey-cli`을 사용할 때 `redis-cli`과 동일한 소켓, 호스트 및 포트를 사용합니다:

  ```shell
  sudo /opt/gitlab/embedded/bin/valkey-cli -s /var/opt/gitlab/redis/redis.socket
  ```

Redis에서 Valkey로의 마이그레이션에 대한 자세한 내용은 [Valkey 마이그레이션 문서](https://valkey.io/topics/migration/)를 참조하세요.

### Valkey로 전환 {#switch-to-valkey}

Redis 대신 Valkey를 사용하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하십시오:

   ```ruby
   redis['backend'] = 'valkey'
   ```

1. GitLab을 재구성합니다. 변경 사항이 적용되도록 합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`redis['backend']`이 `valkey`으로 설정된 경우:

- Redis 서비스는 `valkey-server` 대신 `redis-server`을 사용합니다.
- Sentinel 서비스는 `valkey-sentinel` 대신 `redis-sentinel`을 사용합니다.
- 다른 모든 Redis 설정(포트, 암호, 경로 등)은 동일하게 유지됩니다.

#### 서비스 관리 {#service-management}

이전 호환성을 보장하고 원활한 전환을 위해 서비스 구조는 Redis 또는 Valkey를 백엔드로 사용하는지 여부에 관계없이 일관되게 유지됩니다:

- 서비스 이름은 `redis`입니다. `gitlab-ctl restart redis`을 사용하여 서비스를 관리합니다.
- 로그 파일은 `/var/log/gitlab/redis/`에 작성됩니다.
- 데이터 디렉토리는 `/var/opt/gitlab/redis/`입니다.
- 구성 파일은 `redis.conf`입니다.
- `gitlab-ctl` 명령은 구성된 백엔드에 따라 적절한 CLI 도구(`redis-cli` 또는 `valkey-cli`)를 사용합니다.
- 문제 해결을 위해 활성화된 백엔드를 자동으로 감지하는 래퍼 스크립트를 사용합니다:

  ```shell
  sudo gitlab-redis-cli
  ```

Redis에서 Valkey로의 마이그레이션에 대한 자세한 내용은 [Valkey 마이그레이션 문서](https://valkey.io/topics/migration/)를 참조하세요.

## 문제 해결 {#troubleshooting}

### `x509: certificate signed by unknown authority` {#x509-certificate-signed-by-unknown-authority}

이 오류 메시지는 SSL 인증서가 서버의 신뢰할 수 있는 인증서 목록에 제대로 추가되지 않았음을 나타냅니다. 이것이 이슈인지 확인하려면:

1. `/var/log/gitlab/gitlab-workhorse/current`에서 Workhorse 로그를 확인합니다.
1. 다음과 같은 메시지가 표시되면:

   ```plaintext
   2018-11-14_05:52:16.71123 time="2018-11-14T05:52:16Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_05:52:16.74397 time="2018-11-14T05:52:16Z" level=error msg="unknown error" error="keywatcher: x509: certificate signed by unknown authority"
   ```

   첫 번째 줄은 `rediss`을 Redis 서버 주소의 스키마로 표시해야 합니다. 두 번째 줄은 인증서가 이 서버에서 제대로 신뢰되지 않음을 나타냅니다. [이전 섹션](#ssl-certificates)을 참조하세요.

1. SSL 인증서가 [이러한 문제 해결 단계](ssl/ssl_troubleshooting.md#custom-certificates-missing-or-skipped)를 통해 작동하는지 확인합니다.

### NOAUTH 인증 필요 {#noauth-authentication-required}

Redis 서버는 명령을 수락하기 전에 `AUTH` 메시지를 통해 보낸 암호가 필요할 수 있습니다. `NOAUTH Authentication required` 오류 메시지는 클라이언트가 암호를 보내지 않음을 나타냅니다. GitLab 로그는 이 오류를 해결하는 데 도움이 될 수 있습니다:

1. `/var/log/gitlab/gitlab-workhorse/current`에서 Workhorse 로그를 확인합니다.
1. 다음과 같은 메시지가 표시되면:

   ```plaintext
   2018-11-14_06:18:43.81636 time="2018-11-14T06:18:43Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_06:18:43.86929 time="2018-11-14T06:18:43Z" level=error msg="unknown error" error="keywatcher: pubsub receive: NOAUTH Authentication required."
   ```

1. `/etc/gitlab/gitlab.rb`에 지정된 Redis 클라이언트 암호가 올바른지 확인합니다:

   ```ruby
   gitlab_rails['redis_password'] = 'your-password-here'
   ```

1. Linux 패키지에서 제공한 Redis 서버를 사용하는 경우 서버가 동일한 암호를 가지고 있는지 확인합니다:

   ```ruby
   redis['password'] = 'your-password-here'
   ```

### Redis 연결 재설정(ECONNRESET) {#redis-connection-reset-econnreset}

GitLab Rails 로그(`/var/log/gitlab-rails/production.log`)에서 `Redis::ConnectionError: Connection lost (ECONNRESET)`을 보면 서버가 SSL을 예상하지만 클라이언트가 사용하도록 구성되지 않았음을 나타낼 수 있습니다.

1. 서버가 실제로 SSL을 통해 포트를 수신하고 있는지 확인합니다. 예를 들어:

   ```shell
   /opt/gitlab/embedded/bin/openssl s_client -connect redis-server:6379
   ```

1. `/var/opt/gitlab/gitlab-rails/etc/resque.yml`을 확인합니다. 다음과 같은 내용이 표시되어야 합니다:

   ```yaml
   production:
     url: rediss://:mypassword@redis-server:6379/
   ```

1. `redis://`이 `rediss://` 대신 있으면 `redis_ssl` 매개변수가 제대로 구성되지 않았거나 재구성 단계가 실행되지 않았을 수 있습니다.

### CLI를 통해 Redis에 연결 {#connecting-to-redis-via-the-cli}

문제 해결을 위해 Redis에 연결할 때 다음을 사용할 수 있습니다:

- Unix 도메인 소켓을 통한 Redis:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
  ```

- TCP를 통한 Redis:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -h 127.0.0.1 -p 6379
  ```

- 필요한 경우 Redis에 인증하기 위한 암호:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -h 127.0.0.1 -p 6379 -a <password>
  ```
