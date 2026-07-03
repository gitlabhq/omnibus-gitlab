---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 画像スケーリング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabには、サイトのレンダリングパフォーマンスを向上させるための組み込み画像スケーラーが搭載されています。デフォルトで有効になっています。

## スケーラーを設定する {#configure-the-scaler}

私たちは、常に大多数のGitLabのデプロイで機能する適切なデフォルトを設定するよう努めています。ただし、ご希望のパフォーマンスプロファイルに最適になるように画像のスケーリングを微調整することができるいくつかの設定も提供しています。

### 画像スケーラーの最大数 {#maximum-number-of-image-scalers}

画像の再スケーリングは、Workhorseが稼働している同じノードで実行される追加の一時的なプロセスをもたらします。デフォルトでは、これらのプロセスが同時に実行できる数を、そのマシンまたは仮想マシンのCPUコア数の半分（ただし2つ以上）に制限しています。

代わりに固定値を設定することもできます:

1. `/etc/gitlab/gitlab.rb`を編集し、以下を追加します:

   ```ruby
   gitlab_workhorse['image_scaler_max_procs'] = 10
   ```

1. 変更を適用するために再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

これは、すでに10個の画像が処理されている場合、11番目のリクエストは再スケーリングされず、代わりに元のサイズで提供されることを意味します。これに上限を設けることは、高負荷時でもシステムが利用可能であることを保証するために重要です。

### 画像の最大ファイルサイズ {#maximum-image-file-size}

デフォルトでは、GitLabは最大250 KBの画像を再スケーリングするのみです。これは、Workhorseノードでの過剰なメモリ消費を防ぎ、レイテンシーを妥当な範囲に保つためです。あるファイルサイズを超えると、実際には元の画像を配信する方が全体的に高速です。

許可されるファイルサイズの最大値を引き下げまたは引き上げたい場合:

1. `/etc/gitlab/gitlab.rb`を編集し、以下を追加します:

   ```ruby
   gitlab_workhorse['image_scaler_max_filesize'] = 1024 * 1024
   ```

1. 変更を適用するために再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

これにより、最大1 MBの画像を再スケーリングできるようになります（単位はバイトです）。

### 画像スケーラーの無効化 {#disabling-the-image-scaler}

画像スケーリングを完全にオフにすることもできます。これは、それぞれの機能フラグをオフにすることで実現できます:

```ruby
Feature.disable(:dynamic_image_resizing)
```

機能フラグを操作する方法については、[機能フラグドキュメント](https://docs.gitlab.com/administration/feature_flags/)を参照してください。
