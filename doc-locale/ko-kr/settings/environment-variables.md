---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 정의 환경 변수 설정
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

필요한 경우 `/etc/gitlab/gitlab.rb`을(를) 통해 Puma, Sidekiq, Rails 및 Rake에서 사용할 사용자 정의 환경 변수를 설정할 수 있습니다. 이는 인터넷에 액세스하기 위해 프록시를 사용해야 하고 외부에서 호스팅되는 리포지토리를 GitLab으로 직접 복제해야 하는 상황에서 유용할 수 있습니다. `/etc/gitlab/gitlab.rb`에서 `gitlab_rails['env']`을(를) 해시 값으로 제공합니다. 예를 들어:

```ruby
gitlab_rails['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
#    "no_proxy" => ".yourdomain.com"  # Wildcard syntax if you need your internal domain to bypass proxy. Do not specify a port.
}
```

프록시 뒤에 있을 경우 필요할 수 있는 다른 GitLab 구성 요소의 환경 변수도 재정의할 수 있습니다:

```ruby
# Needed for proxying Git clones
gitaly['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}

gitlab_workhorse['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}

gitlab_pages['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}

# If you use the docker registry
registry['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}
```

GitLab은 프록시 URL에 사용자 이름과 암호가 포함되어 있으면 HTTP 기본 인증을 사용하려고 합니다.

프록시 설정은 글로빙을 위해 `.` 구문을 사용합니다.

프록시 URL 값은 일반적으로 `http://`만 사용해야 합니다. 단, 프록시에 자체 SSL 인증서가 있고 SSL이 활성화된 경우는 제외입니다. 즉, `https_proxy` 값이더라도 일반적으로 `http://<USERNAME>:<PASSWORD>@example.com:8080`로 값을 지정해야 합니다.

> [!note]
> HTTP_PROXY 또는 HTTPS_PROXY 환경 변수가 설정되어 있고 도메인 DNS를 확인할 수 없으면 DNS 리바인드 보호가 비활성화됩니다.

## 변경 사항 적용 {#applying-the-changes}

환경 변수에 대한 모든 변경 사항이 적용되려면 재구성이 필요합니다.

재구성을 수행합니다:

```shell
sudo gitlab-ctl reconfigure
```

## 주목할 만한 환경 변수 {#noteworthy-environment-variables}

### `TMPDIR` {#tmpdir}

Ruby 및 다른 구성 요소는 `TMPDIR` 환경 변수를 사용하여 임시 파일을 저장할 위치를 결정합니다. 기본적으로 이는 `/tmp`입니다.

다음 경우 사용자 정의 임시 디렉터리를 구성해야 할 수 있습니다:

- `/tmp`이(가) `tmpfs`로 마운트되어 있고 공간이 제한되어 있습니다.
- 대용량 파일(예: LFS 객체 또는 CI 아티팩트)로 인해 `/tmp`이(가) 가득 찹니다.
- [Geo 보조 사이트](https://docs.gitlab.com/ee/administration/geo/)에서 객체 스토리지 복제 중에 `/tmp`의 공간이 부족해집니다.

사용자 정의 임시 디렉터리를 구성하려면:

1. 디렉터리를 생성하고 권한을 설정합니다:

   ```shell
   sudo mkdir -p /var/opt/gitlab/tmp
   sudo chown git:git /var/opt/gitlab/tmp
   sudo chmod 700 /var/opt/gitlab/tmp
   ```

1. `/etc/gitlab/gitlab.rb`을(를) 편집하여 Rails 및 Workhorse 모두에 대해 `TMPDIR`을(를) 설정합니다:

   ```ruby
   gitlab_rails['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   gitlab_workhorse['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   ```

   > [!note]
   > 두 값 모두 **must** 디렉터리를 가리켜야 합니다. 객체 스토리지가 활성화되어 있을 때 CI/CD 아티팩트를 업로드하면 Workhorse는 `TMPDIR`에서 메타데이터 파일을 생성하고 Rails에 경로를 전달합니다. Rails는 파일이 허용된 디렉터리(자체 `TMPDIR`포함)에 있는지 확인합니다. 이 값들이 다르면 아티팩트 업로드가 `400 Bad Request`과(와) 함께 실패합니다.

1. GitLab을 재구성하고 다시 시작합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

1. 설정을 확인합니다:

   ```shell
   sudo gitlab-rails runner "puts ENV['TMPDIR']"
   ```

   출력에서 구성된 경로가 표시되어야 합니다.

## 문제 해결 {#troubleshooting}

### 환경 변수가 설정되지 않음 {#an-environment-variable-is-not-being-set}

동일한 `['env']`에 대해 여러 항목이 없는지 확인합니다. 마지막 항목이 이전 항목을 재정의합니다. 이 예에서 `NTP_HOST`은(는) 설정되지 않습니다:

```ruby
gitlab_rails['env'] = { 'NTP_HOST' => "<DOMAIN_OF_NTP_SERVICE>" }

gitlab_rails['env'] = {
    "http_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080",
    "https_proxy" => "http://<USERNAME>:<PASSWORD>@example.com:8080"
}
```

### CI/CD 아티팩트 업로드가 `400 Bad Request`(으)로 실패함 `TMPDIR` 변경 후 {#cicd-artifact-uploads-fail-with-400-bad-request-after-changing-tmpdir}

CI/CD 아티팩트 업로드가 `400 Bad Request`을(를) `Content-Type: text/plain`과(와) 함께 반환하면 [사용자 정의 `TMPDIR`](#tmpdir)을(를) 구성한 후 Rails와 Workhorse의 `TMPDIR` 값 간에 불일치가 발생할 가능성이 가장 높습니다.

이를 해결하려면:

1. `/etc/gitlab/gitlab.rb`에서 두 값이 일치하는지 확인합니다:

   ```ruby
   gitlab_rails['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   gitlab_workhorse['env'] = { 'TMPDIR' => '/var/opt/gitlab/tmp' }
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Workhorse 로그에서 실패한 상관 ID를 확인하여 불일치를 확인할 수 있습니다. `metadata.gz` 항목을 찾고 `local_temp_path`이(가) 구성된 `TMPDIR`과(와) 다른 디렉터리를 가리키는지 확인합니다.

### 오류: `Connection reset by peer` 리포지토리 미러링 시 {#error-connection-reset-by-peer-when-mirroring-repositories}

`no_proxy` 값에 URL의 포트 번호가 포함되어 있으면 DNS 확인 오류가 발생할 수 있습니다. `no_proxy` URL에서 모든 포트 번호를 제거하여 이 이슈를 해결합니다.
