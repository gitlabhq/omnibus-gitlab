---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 設定ファイルの設定を変更する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabの機能の一部は、[`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/gitlab.yml.example)を通じてカスタマイズできます。`gitlab.yml`の設定をLinuxパッケージインストール用に変更したい場合は、`/etc/gitlab/gitlab.rb`を使用する必要があります。翻訳は次のように機能します。利用可能なすべてのオプションについては、[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)を参照してください。

`/etc/gitlab/gitlab.rb`にリストされているテンプレートのすべてのオプションは、デフォルトで利用可能です。

`gitlab.yml`では、次のような構造があります:

```yaml
production: &base
  gitlab:
    default_theme: 2
```

`gitlab.rb`では、これは次のように解釈されます:

```ruby
gitlab_rails['gitlab_default_theme'] = 2
```

ここで起きるのは、`production: &base`を無視し、`gitlab:`と`default_theme:`を結合して`gitlab_default_theme`にすることです。すべての`gitlab.yml`設定がまだ`gitlab.rb`経由で変更できるわけではないことに注意してください。[`gitlab.yml.erb`テンプレート](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb)を参照してください。属性が不足していると思われる場合は、`omnibus-gitlab`リポジトリでマージリクエストを作成してください。

`gitlab.rb`での変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

`/var/opt/gitlab/gitlab-rails/etc/gitlab.yml`内の生成されたファイルを編集しないでください。次回の`gitlab-ctl reconfigure`実行時に上書きされます。

## `gitlab.yml`に新しい設定を追加する {#adding-a-new-setting-to-gitlabyml}

まず、`gitlab.yml`に設定を追加しないことを検討してください。[GitLab-specific concerns](https://docs.gitlab.com/development/code_review/#gitlab-specific-concerns)の下の**設定**を参照してください。

新しい設定を追加する際は、次の5つのファイルを更新することを忘れないでください:

- [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)ファイルは、`/etc/gitlab/gitlab.rb`を介して設定をエンドユーザーに公開します。
- [`default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb)ファイルは、新しい設定に適切なデフォルトを提供します。
- [`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/blob/master/config/gitlab.yml.example)ファイルは、`gitlab.rb`からの設定の値を実際に使用します。
- [`gitlab.yml.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb)ファイル
- [`gitlab-rails_spec.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/spec/chef/cookbooks/gitlab/recipes/gitlab-rails_spec.rb)ファイル
