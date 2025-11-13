---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 設定ファイルの設定の変更
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

一部のGitLab機能は、[`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/gitlab.yml.example)を使用してカスタマイズできます。Linuxパッケージのインストールで`gitlab.yml`設定を変更する場合は、`/etc/gitlab/gitlab.rb`で変更する必要があります。翻訳は次のように機能します。利用可能なオプションの完全なリストについては、[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)を参照してください。

`/etc/gitlab/gitlab.rb`にリストされているテンプレートのすべてのオプションは、デフォルトで使用できます。

`gitlab.yml`には、次のような構造があります:

```yaml
production: &base
  gitlab:
    default_theme: 2
```

`gitlab.rb`では、これは次のように変換されます:

```ruby
gitlab_rails['gitlab_default_theme'] = 2
```

ここで何が起こるかというと、`production: &base`を無視し、`gitlab:`と`default_theme:`を`gitlab_default_theme`に結合します。すべての`gitlab.yml`設定を`gitlab.rb`経由で変更できるわけではありません。[`gitlab.yml.erb`テンプレート](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb)を参照してください。属性が見つからない場合は、`omnibus-gitlab`リポジトリでマージリクエストを作成してください。

`sudo gitlab-ctl reconfigure`を実行して、`gitlab.rb`の変更を有効にします。

生成されたファイルを`/var/opt/gitlab/gitlab-rails/etc/gitlab.yml`で編集しないでください。次の`gitlab-ctl reconfigure`の実行時に上書きされるためです。

## 新しい設定を`gitlab.yml`に追加する {#adding-a-new-setting-to-gitlabyml}

まず、`gitlab.yml`への設定の追加を見送ることを検討してください。**設定**については、[GitLab固有の考慮事項](https://docs.gitlab.com/development/code_review/#gitlab-specific-concerns)を参照してください。

新しい設定を追加するときは、次の5つのファイルを更新することを忘れないでください:

- `/etc/gitlab/gitlab.rb`を介してエンドユーザーに設定を公開するための[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)ファイル。
- 新しい設定に対して適切なデフォルトを提供するための[`default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb)ファイル。
- `gitlab.rb`からの設定の値を実際に使用するための[`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/blob/master/config/gitlab.yml.example)ファイル。
- [`gitlab.yml.erb`ファイル](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb)
- [`gitlab-rails_spec.rb`ファイル](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/spec/chef/cookbooks/gitlab/recipes/gitlab-rails_spec.rb)
