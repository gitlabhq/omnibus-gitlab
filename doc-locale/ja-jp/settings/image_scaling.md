---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 画像スケーリング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、サイトのレンダリングパフォーマンスを向上させるために、組み込みのイメージスケールを実行します。デフォルトで有効になっています。

## スケーラの設定 {#configure-the-scaler}

私たちは、大多数のGitLabデプロイで動作する、妥当なデフォルトを常に設定するように努めています。ただし、イメージスケールを微調整して、ご希望のパフォーマンスプロファイルに最適に一致させることができる、いくつかの設定を用意しています。

### イメージスケーラの最大数 {#maximum-number-of-image-scalers}

イメージのリスケールにより、Workhorseが実行されている同じノードで実行される、追加の一時的なプロセスが発生します。デフォルトでは、これらのプロセスが同時に実行できるようにする数を、そのマシンまたはVM上のCPUコア数の半分（ただし、2つ以上）に制限しています。

代わりに、これを固定値に設定することもできます:

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_workhorse['image_scaler_max_procs'] = 10
   ```

1. 変更を有効にするため、再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

これは、10個のイメージがすでに処理されている場合、11番目のリクエストはリスケールされず、代わりに元のサイズで提供されることを意味します。これに上限を設けることは、システムが高負荷時でも利用可能な状態を維持するために重要です。

### イメージファイルの最大サイズ {#maximum-image-file-size}

デフォルトでは、GitLabは最大250 KBのサイズのイメージのみをリスケールします。これは、Workhorseノードでの過度のメモリ消費を防ぎ、レイテンシーを妥当な範囲に保つためです。特定のファイルサイズを超えると、実際には元のイメージを提供する方が全体的に高速になります。

許可される最大ファイルサイズを小さくするか大きくするかする場合は、次のようにします:

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_workhorse['image_scaler_max_filesize'] = 1024 * 1024
   ```

1. 変更を有効にするため、再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

これにより、最大1 MBのイメージをリスケールできます（単位はバイトです）。

### イメージスケーラの無効化 {#disabling-the-image-scaler}

イメージスケールを完全にオフにすることもできます。これは、それぞれの機能切替をオフにすることで実現できます:

```ruby
Feature.disable(:dynamic_image_resizing)
```

機能フラグの操作方法については、[機能フラグのドキュメント](https://docs.gitlab.com/administration/feature_flags/)を参照してください。
