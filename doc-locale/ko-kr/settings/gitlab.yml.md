---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 설정 파일 설정 변경
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

일부 GitLab 기능은 [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/gitlab.yml.example)를 통해 사용자 지정할 수 있습니다. Linux 패키지 설치를 위해 `gitlab.yml` 설정을 변경하려면 `/etc/gitlab/gitlab.rb`로 수행해야 합니다. 변환은 다음과 같이 작동합니다. 사용 가능한 옵션의 전체 목록을 보려면 [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)을(를) 방문하세요.

`/etc/gitlab/gitlab.rb`에 나열된 템플릿의 모든 옵션은 기본적으로 사용 가능합니다.

`gitlab.yml`에서 다음과 같은 구조를 찾을 수 있습니다:

```yaml
production: &base
  gitlab:
    default_theme: 2
```

`gitlab.rb`에서 이는 다음과 같이 변환됩니다:

```ruby
gitlab_rails['gitlab_default_theme'] = 2
```

여기서 일어나는 일은 `production: &base`을(를) 잊어버리고 `gitlab:`을(를) `default_theme:`과(와) 결합하여 `gitlab_default_theme`를 만드는 것입니다. `gitlab.yml` 설정을 모두 `gitlab.rb`을(를) 통해 변경할 수 없습니다. [`gitlab.yml.erb` 템플릿](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb)을 참조하세요. 특성이 누락되었다고 생각되면 `omnibus-gitlab` 리포지토리에서 머지 리퀘스트를 생성하세요.

`sudo gitlab-ctl reconfigure`을(를) 실행하여 `gitlab.rb`의 변경 사항을 적용합니다.

`/var/opt/gitlab/gitlab-rails/etc/gitlab.yml`에서 생성된 파일을 편집하지 마세요. 다음 `gitlab-ctl reconfigure` 실행에서 덮어씌워집니다.

## `gitlab.yml`에 새 설정 추가 {#adding-a-new-setting-to-gitlabyml}

먼저 `gitlab.yml`에 설정을 추가하지 않는 것을 고려하세요. **설정** 아래의 [GitLab-specific concerns](https://docs.gitlab.com/development/code_review/#gitlab-specific-concerns)을(를) 참조하세요.

새 설정을 추가할 때 다음 5개 파일을 업데이트하는 것을 잊지 마세요:

- `/etc/gitlab/gitlab.rb`을(를) 통해 최종 사용자에게 설정을 노출하기 위한 [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template) 파일입니다.
- 새 설정에 대한 정상적인 기본값을 제공하기 위한 [`default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb) 파일입니다.
- `gitlab.rb`에서 설정의 값을 실제로 사용하기 위한 [`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/blob/master/config/gitlab.yml.example) 파일입니다.
- [`gitlab.yml.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb) 파일
- [`gitlab-rails_spec.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/spec/chef/cookbooks/gitlab/recipes/gitlab-rails_spec.rb) 파일
