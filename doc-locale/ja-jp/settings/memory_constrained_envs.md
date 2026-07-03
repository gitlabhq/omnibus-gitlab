---
stage: Data Stores
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: メモリ制約のある環境でGitLabを実行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Gitlabは、すべての機能を有効にして実行する場合、かなりの量のメモリが必要になります。しかし、すべての機能を必要としない小規模なGitlabインストールでGitlabを実行するユースケースもあります。例:

- 個人用途または非常に小規模なチームでGitLabを運用する。
- コスト削減のため、クラウドプロバイダー上で小さなインスタンスを使用する。
- Raspberry PIのようなリソース制約のあるデバイスを使用する。

いくつか調整を行えば、[最小要件](https://docs.gitlab.com/install/requirements/)または[リファレンスアーキテクチャ](https://docs.gitlab.com/administration/reference_architectures/)に記載されている要件に比べてはるかに低い仕様でも、GitLabを快適に動作させることができます。

これらの設定を適用してもGitLabのほとんどの機能は動作しますが、製品の機能やパフォーマンスの予期しない低下が発生する可能性があります。

> [!note]
> 以下のセクションでは、個々のGitリポジトリのサイズが100 MB以下の最大5人のデベロッパーでGitLabを実行する方法について説明します。

## 制約のある環境の最小要件 {#minimum-requirements-for-constrained-environments}

GitLabを実行可能と見込まれる最小の仕様は次のとおりです:

- Linuxベースのシステム（理想的にはDebianベースまたはRedHatベース）
- ARM7/ARM64の4つのCPUコア、またはAMD64アーキテクチャの1つのCPUコア
- 最小2 GBのRAM + 1 GBのスワップ、推奨は2.5 GBのRAM + 1 GBのスワップ
- 20 GBの利用可能なストレージ
- ランダムI/O性能が優れているストレージ（優先順位は次のとおり）:
  - [SSD](https://en.wikipedia.org/wiki/Solid-state_drive)
  - [eMMC](https://magazine.odroid.com/article/emmc-memory-modules-a-simple-guide/)
  - [HDD](https://en.wikipedia.org/wiki/Hard_disk_drive)
  - [高性能なA1タイプSDカード](https://www.sdcard.org/developers/sd-standard-overview/application-performance-class/)

上記のうち、CPUのシングルコア性能とストレージのランダムI/O性能が最も大きく影響します。制約のある環境では、ある程度のメモリスワップが発生することが想定され、そのぶんディスクへの負荷が高まるため、ストレージは特に重要になります。小規模プラットフォームでパフォーマンスが制限される際のよくある問題は、ディスクストレージが非常に遅いことであり、これがシステム全体のボトルネックとなります。

これらの最小構成では、通常の運用中にスワップが使用されるはずです。すべてのコンポーネントが同時に稼働するわけではないため、この構成でも許容可能なパフォーマンスを達成できると見込まれます。

## システムのパフォーマンスを検証する {#validate-the-performance-of-your-system}

Linuxベースシステムのパフォーマンスを検証できるツールは多数あります。システムのパフォーマンスのチェックに役立つプロジェクトの1つに、[sbc-bench](https://github.com/ThomasKaiser/sbc-bench)があります。sbc-benchでは、システムテストに関するすべての注意点や、さまざまな動作がシステムのパフォーマンスに与える影響が説明されています。これは、組み込みシステムでGitLabを実行する場合に特に重要です。sbc-benchは、制約のある環境でGitLabを実行するのにシステムのパフォーマンスが十分であるかどうかを検証する方法として使用できます。

以下のシステムは、GitLabの小規模なインストールを実行するのに十分なパフォーマンスを提供します:

- [Raspberry PI 4 2 GB](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)。
- [DigitalOcean Basic 2 GB、SSD搭載](https://www.digitalocean.com/pricing)。
- [Scaleway DEV1-S 2 GB/20 GB](https://www.scaleway.com/en/pricing/)。
- [GCS e2-small](https://docs.cloud.google.com/compute/docs/machine-resource)。

## スワップを設定する {#configure-swap}

GitLabをインストールする前に、スワップを設定する必要があります。スワップは、物理RAMが満杯の場合に使用される、ディスク上の専用スペースです。LinuxシステムでRAMが不足すると、非アクティブなページがRAMからスワップスペースに移動されます。

スワップの使用はレイテンシーを増加させる可能性があるため、問題と見なされることがよくあります。ただし、GitLabの動作上、割り当てられたメモリの多くは頻繁にはアクセスされません。スワップを有効にしておけば、アプリケーションを正常に動作させつつ、必要なときだけスワップを使用させることが可能になります。

一般的なガイドラインとして、利用可能なメモリの約50％をスワップとして設定します。メモリ制約のある環境では、システムに少なくとも1 GBのスワップを設定することをおすすめします。設定方法に関するガイドは多数ありますが、以下にその一例を挙げます:

- [How to Add Swap Space on Ubuntu 20.04](https://linuxize.com/post/how-to-add-swap-space-on-ubuntu-20-04/)
- [How to Add Swap Space on CentOS 7](https://linuxize.com/post/how-to-add-swap-space-on-centos-7/)

設定したら、スワップが適切に有効になっているかを検証する必要があります:

```shell
free -h
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       115Mi       1.4Gi       0.0Ki       475Mi       1.6Gi
Swap:         1.0Gi          0B       1.0Gi
```

また、`/proc/sys/vm/swappiness`を調整して、システムがスワップスペースを使用する頻度を設定することもできます。swappinessの値は`0`〜`100`の範囲で設定できます。デフォルト値は`60`です。この値を小さくすると、Linuxは匿名メモリページを解放してスワップへ追い出す優先度を下げ、代わりにファイルに関連付けられたメモリページの破棄を優先するようになります:

1. 現在のセッション内で設定する場合:

   ```shell
   sudo sysctl vm.swappiness=10
   ```

1. `/etc/sysctl.conf`を編集して、この設定を恒久的に保存する場合:

   ```shell
   vm.swappiness=10
   ```

## GitLabをインストールする {#install-gitlab}

メモリ制約のある環境では、どのGitLabディストリビューションが適切なのかの検討が推奨されます。

[GitLab Enterprise Edition（EE）](https://about.gitlab.com/install/)には、[GitLab Community Edition（CE）](https://about.gitlab.com/install/?version=ce)よりもはるかに多くの機能が備わっています。一方で、これらの追加機能により、コンピューティングとメモリの要件も増加します。

メモリ消費が主な懸念事項である場合は、GitLab CEをインストールしてください。後からいつでも[GitLab EEにアップグレード](https://docs.gitlab.com/update/convert_to_ee/package/)できます。

## Pumaを最適化する {#optimize-puma}

デフォルトでは、GitLabは、多数の同時接続を処理するように設計された設定で実行されます。

高いスループットを必要としない小規模なインストールでは、[Pumaのクラスターモードを無効](https://docs.gitlab.com/administration/operations/puma/#disable-puma-clustered-mode-in-memory-constrained-environments)にしてください。この設定により、単一のPumaプロセスのみでアプリケーションを実行します。

`/etc/gitlab/gitlab.rb`の設定:

```ruby
puma['worker_processes'] = 0
```

この最適化により、100〜400 MBのメモリ使用量の削減が確認されました。

## Sidekiqを最適化する {#optimize-sidekiq}

Sidekiqは、バックグラウンド処理デーモンです。GitLabのデフォルト設定では、Sidekiqは`20`の並行処理数で動作します。これは、一時的なメモリ割り当て量に影響します。そのため、`5`または`10`（推奨）といった、デフォルトよりもかなり小さい値に設定することをおすすめします。

`/etc/gitlab/gitlab.rb`の設定:

```ruby
sidekiq['concurrency'] = 10
```

## Gitalyを最適化する {#optimize-gitaly}

Gitalyは、Gitベースのリポジトリへの効率的なアクセスを可能にするストレージサービスです。Gitalyによって強制される最大の並行処理数とメモリ制限を設定することをおすすめします。

`/etc/gitlab/gitlab.rb`の設定:

```ruby
gitaly['configuration'] = {
    concurrency: [
      {
        'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
        'max_per_repo' => 3,
      }, {
        'rpc' => "/gitaly.SSHService/SSHUploadPack",
        'max_per_repo' => 3,
      },
    ],
    cgroups: {
        repositories: {
            count: 2,
        },
        mountpoint: '/sys/fs/cgroup',
        hierarchy_root: 'gitaly',
        memory_bytes: 500000,
        cpu_shares: 512,
    },
}

gitaly['env'] = {
  'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
}
```

## モニタリングを無効化する {#disable-monitoring}

GitLabではデフォルトで、すべてのサービスが有効になっています。設定を変更しなくても完全なDevOpsソリューションを提供できるようにするためです。一方、モニタリングなど、デフォルトのサービスの中には、GitLabを稼働させるために必須ではないものもあります。メモリを節約するために、それらを無効にすることもできます。

`/etc/gitlab/gitlab.rb`の設定:

```ruby
alertmanager['enable'] = false
gitlab_exporter['enable'] = false
gitlab_kas['enable'] = false
node_exporter['enable'] = false
postgres_exporter['enable'] = false
prometheus_monitoring['enable'] = false
prometheus['enable'] = false
puma['exporter_enabled'] = false
redis_exporter['enable'] = false
sidekiq['metrics_enabled'] = false
```

このようにGitLabを設定すると、メモリ使用量が300 MB削減されることが確認されています。

## GitLabのメモリ処理方法を設定する {#configure-how-gitlab-handles-memory}

GitLabは多数のコンポーネントで構成されており、それらはRubyおよびGoで記述されています。中でも最大のコンポーネントがGitLab Railsで、メモリの大部分を消費しています。

GitLab Railsはメモリアロケータとして[jemalloc](https://github.com/jemalloc/jemalloc)を使用します。[jemalloc](https://github.com/jemalloc/jemalloc)は、より大きなチャンクでメモリを事前割り当てし、さらにより長い期間保持することでパフォーマンスを向上させます。多少のパフォーマンス低下と引き換えに、不要になったメモリを長期間保持するのではなく、不要になり次第すぐに解放するようにGitLabを設定できます。

`/etc/gitlab/gitlab.rb`の設定:

```ruby
gitlab_rails['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}

gitaly['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}
```

この設定により、アプリケーション実行中のメモリ使用量が大幅に安定することが確認されています。

## アプリケーション内部の追加のモニタリングを無効にする {#disable-additional-in-application-monitoring}

GitLabは、自身のさまざまな側面を測定するために内部データ構造を使用しています。モニタリングを無効にしている場合は、これらの機能は不要になります。

これらの機能を無効にするには、GitLabの**管理者**エリアに移動し、Prometheusメトリクス機能を無効にします:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定 > メトリクスとプロファイリング**を選択します。
1. **メトリクス - Prometheus**を展開します。
1. **Prometheusメトリクスを有効にする**を無効にします。
1. **変更を保存**を選択します。

## すべての変更を反映した設定 {#configuration-with-all-the-changes}

1. これまで説明した内容をすべて適用すると、`/etc/gitlab/gitlab.rb`ファイルは次のようになります:

   ```ruby
   puma['worker_processes'] = 0

   sidekiq['concurrency'] = 10

   prometheus_monitoring['enable'] = false

   gitlab_rails['env'] = {
     'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
   }

   gitaly['configuration'] = {
     concurrency: [
       {
         'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
         'max_per_repo' => 3,
       }, {
         'rpc' => "/gitaly.SSHService/SSHUploadPack",
         'max_per_repo' => 3,
       },
     ],
     cgroups: {
       repositories: {
         count: 2,
       },
       mountpoint: '/sys/fs/cgroup',
       hierarchy_root: 'gitaly',
       memory_bytes: 500000,
       cpu_shares: 512,
     },
   }
   gitaly['env'] = {
     'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000',
     'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
   }
   ```

1. これらの変更をすべて加えたら、GitLabを再設定して新しい設定を読み込ませます:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   それまで、GitLabをメモリ節約設定で動作させていなかった場合、再設定には多少時間がかかることがあります。

## パフォーマンス結果 {#performance-results}

上記の設定を適用すると、メモリ使用量は次のようになると見込まれます:

```plaintext
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       1.7Gi       151Mi        31Mi       132Mi       102Mi
Swap:         1.0Gi       153Mi       870Mi
```
