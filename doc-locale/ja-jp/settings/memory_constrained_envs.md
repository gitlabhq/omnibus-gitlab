---
stage: Data Stores
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: メモリ制約のある環境でのGitLabの実行
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabをすべての機能を有効にして実行すると、かなりの量のメモリが必要になります。すべての機能が必要とされない小規模なGitLabインストレーションでGitLabを実行するなど、ユースケースがあります。例:

- 個人使用または非常に小規模なチームでのGitLabの実行。
- コスト削減のために、クラウドプロバイダー上の小さなインスタンスを使用する。
- Raspberry PIのようなリソース制約のあるデバイスの使用。

いくつかの調整により、GitLabは、[最低要件](https://docs.gitlab.com/install/requirements/)または[リファレンスアーキテクチャ](https://docs.gitlab.com/administration/reference_architectures/)に記載されているよりもはるかに低い仕様で快適に実行できます。

ほとんどのGitLabのパーツはこれらの設定で機能しますが、製品の機能とパフォーマンスの両方で予期しない低下が発生する可能性があります。

{{< alert type="note" >}}

次のセクションでは、最大5人のデベロッパーが、100 MB以下の個々のGitリポジトリでGitLabを実行する方法について説明します。

{{< /alert >}}

## 制約のある環境の最小要件 {#minimum-requirements-for-constrained-environments}

GitLabを実行できる最小予測仕様は次のとおりです:

- Linuxベースのシステム（理想的にはDebianベースまたはRedHatベース）
- ARM7/ARM64の4つのCPUコア、またはAMD64アーキテクチャの1つのCPUコア
- 最小2 GBのRAM + 1 GBのSWAP、最適には2.5 GBのRAM + 1 GBのスワップ
- 20 GBの使用可能なストレージ
- 適切なランダムI/Oパフォーマンスを備えたストレージ。優先順位は次のとおりです:
  - [SSD](https://en.wikipedia.org/wiki/Solid-state_drive)
  - [eMMC](https://magazine.odroid.com/article/emmc-memory-modules-a-simple-guide/)
  - [HDD](https://en.wikipedia.org/wiki/Hard_disk_drive)
  - [高性能A1タイプSDカード](https://www.sdcard.org/developers/sd-standard-overview/application-performance-class/)

上記のリストのうち、CPUのシングルコアパフォーマンスとストレージのランダムI/Oパフォーマンスが最も大きな影響を与えます。制約のある環境では、ある程度のメモリスワップが発生すると予想され、使用済みディスクへの負荷が高まるため、ストレージは特に関連性があります。小規模プラットフォームのパフォーマンスが制限される一般的な問題は、ディスクストレージが非常に遅いことであり、システム全体のボトルネックにつながります。

これらの最小設定では、システムは通常の操作中にスワップを使用する必要があります。すべてのコンポーネントが同時に使用されるわけではないため、許容できるパフォーマンスを提供する必要があります。

## システムのパフォーマンスを検証する {#validate-the-performance-of-your-system}

Linuxベースシステムのパフォーマンスを検証できるツールが多数あります。システムのパフォーマンスのチェックに役立つプロジェクトの1つに、[sbc-bench](https://github.com/ThomasKaiser/sbc-bench)があります。システムのテストに関するすべての注意点と、さまざまな動作がシステムのパフォーマンスに与える影響について説明します。これは、組込みシステムでGitLabを実行する場合に特に重要です。システムのパフォーマンスが、制約のある環境でGitLabを実行するのに十分であるかどうかを検証する方法として使用できます。

これらのシステムは、GitLabの小規模なインストールを実行するための適切なパフォーマンスを提供します:

- [Raspberry PI 4 2 GB](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)。
- [DigitalOcean Basic 2 GB with SSD](https://www.digitalocean.com/pricing)。
- [Scaleway DEV1-S 2 GB/20 GB](https://www.scaleway.com/en/pricing/)。
- [GCS e2-small](https://cloud.google.com/compute/docs/machine-resource)。

## 設定スワップ {#configure-swap}

GitLabをインストールする前に、スワップを設定する必要があります。スワップは、物理RAMが満杯の場合に使用される、ディスク上の専用スペースです。LinuxシステムでRAMが不足すると、非アクティブなページがRAMからスワップスペースに移動されます。

スワップの使用はレイテンシーを増加させる可能性があるため、問題と見なされることがよくあります。ただし、GitLabの機能により、割り当てられたメモリの多くは頻繁にアクセスされません。スワップを使用すると、アプリケーションは正常に実行および機能し、時々スワップのみを使用できます。

一般的なガイドラインは、使用可能なメモリの約50％になるようにスワップを設定することです。メモリ制約のある環境では、システムに少なくとも1 GBのスワップを設定することをお勧めします。それを行う方法に関するガイドラインが多数あります:

- [Ubuntu 20.04にスワップスペースを追加する方法](https://linuxize.com/post/how-to-add-swap-space-on-ubuntu-20-04/)
- [CentOS 7にスワップスペースを追加する方法](https://linuxize.com/post/how-to-add-swap-space-on-centos-7/)

設定したら、スワップが適切に有効になっていることを検証する必要があります:

```shell
free -h
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       115Mi       1.4Gi       0.0Ki       475Mi       1.6Gi
Swap:         1.0Gi          0B       1.0Gi
```

また、`/proc/sys/vm/swappiness`を調整して、システムがスワップスペースを使用する頻度を設定することもできます。Swappinessの範囲は`0`〜`100`です。デフォルト値は`60`です。値を小さくすると、匿名メモリページを解放してスワップに書き込むLinuxの優先度が低下しますが、ファイルバックアップされたページで同じことを行う優先度が高まります:

1. 現在のセッションで設定します:

   ```shell
   sudo sysctl vm.swappiness=10
   ```

1. `/etc/sysctl.conf`を編集して、永続的にします:

   ```shell
   vm.swappiness=10
   ```

## GitLabをインストールする {#install-gitlab}

メモリ制約のある環境では、どのGitLabディストリビューションが適切かを検討する必要があります。

[GitLab Enterprise Edition (EE)](https://about.gitlab.com/install/)には、[GitLab Community Edition (CE)](https://about.gitlab.com/install/?version=ce)よりも大幅に多くの機能が付属していますが、これらの追加機能はすべて、コンピューティングとメモリの要件を増加させます。

メモリ消費が主な懸念事項である場合は、GitLab CEをインストールします。いつでも[GitLab EEにアップグレード](https://docs.gitlab.com/update/convert_to_ee/package/)できます。

## Pumaの最適化 {#optimize-puma}

デフォルトでは、GitLabは、多数の同時接続を処理するように設計された設定で実行されます。

高いスループットを必要としない小規模なインストールでは、[Pumaクラスタ化モードを無効にします](https://docs.gitlab.com/administration/operations/puma/#disable-puma-clustered-mode-in-memory-constrained-environments)。この設定は、アプリケーションを提供するために、単一のPumaプロセスのみを実行します。

`/etc/gitlab/gitlab.rb`で:

```ruby
puma['worker_processes'] = 0
```

この最適化により、100〜400 MBのメモリ使用量の削減が確認されました。

## Sidekiqの最適化 {#optimize-sidekiq}

Sidekiqは、バックグラウンド処理デーモンです。デフォルトでGitLabで設定すると、`20`の並行処理モードで実行されます。これにより、特定の時点で割り当てることができるメモリの量に影響します。`5`または`10`（推奨）の大幅に小さい値を使用するように設定することをお勧めします。

`/etc/gitlab/gitlab.rb`で:

```ruby
sidekiq['concurrency'] = 10
```

## Gitalyの最適化 {#optimize-gitaly}

Gitalyは、Gitベースのリポジトリへの効率的なアクセスを可能にするストレージサービスです。Gitalyによって強制される最大の並行処理とメモリ制限を設定することをお勧めします。

`/etc/gitlab/gitlab.rb`で:

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

## モニタリングの無効化 {#disable-monitoring}

GitLabは、追加の設定なしで完全なDevOpsソリューションを提供するために、デフォルトですべてのサービスを有効にします。モニタリングのようなデフォルトの一部のサービスは、GitLabが機能するために不可欠ではなく、メモリを節約するために無効にすることができます。

`/etc/gitlab/gitlab.rb`で:

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

このようにGitLabを設定すると、300 MBのメモリ使用量の削減が確認されました。

## GitLabのメモリ処理方法の設定 {#configure-how-gitlab-handles-memory}

GitLabは、多くのコンポーネント（RubyおよびGoで記述）で構成されており、GitLab Railsが最大であり、メモリのほとんどを消費しています。

GitLab Railsはメモリアロケーターとして[jemalloc](https://github.com/jemalloc/jemalloc)を使用します。[jemalloc](https://github.com/jemalloc/jemalloc)は、パフォーマンスを向上させるために、より大きなチャンクでメモリを事前割り当てし、より長い期間保持されます。パフォーマンスがいくらか低下しますが、GitLabを設定して、より長い期間保持する代わりに、不要になった直後にメモリを解放することができます。

`/etc/gitlab/gitlab.rb`で:

```ruby
gitlab_rails['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}

gitaly['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}
```

アプリケーションの実行中、より安定したメモリ使用量が確認されました。

## アプリケーション内の追加のモニタリングを無効にする {#disable-additional-in-application-monitoring}

GitLabは、内部データ構造を使用して、それ自体のさまざまな側面を測定します。これらの機能は、モニタリングが無効になっている場合は不要になります。

これらの機能を無効にするには、GitLabの**管理者**エリアに移動し、Prometheusメトリクス機能を無効にします:

1. 右上隅で、**管理者**を選択します。
1. **設定 > メトリクスとプロファイリング**を選択します。
1. **メトリクス - Prometheus**を展開します。
1. **Enable Prometheus Metrics**を無効にします。
1. **変更を保存**を選択します。

## すべての変更を含む設定 {#configuration-with-all-the-changes}

1. これまで説明したすべてのことを適用すると、`/etc/gitlab/gitlab.rb`ファイルには次の設定が含まれているはずです:

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

1. これらすべての変更を加えたら、GitLabを再設定して、新しい設定を使用します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   GitLabはこれまでメモリを消費しない設定では動作しなかったため、この操作にはしばらく時間がかかる可能性があります。

## パフォーマンス結果 {#performance-results}

上記の設定を適用すると、次のメモリ使用量が予想されます:

```plaintext
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       1.7Gi       151Mi        31Mi       132Mi       102Mi
Swap:         1.0Gi       153Mi       870Mi
```
