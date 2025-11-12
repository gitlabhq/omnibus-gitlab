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

GitLabをすべての機能を有効にして実行するには、かなりのメモリ使用量が必要です。すべての機能が必要とされない小規模なインスタンスでGitLabを実行するなど、ユースケースがあります。例:

- 個人使用または非常に小規模なチームでのGitLabの実行。
- コスト削減のためにクラウドプロバイダー上の小さなインスタンスを使用する。
- Raspberry PIのようなリソース制約のあるデバイスの使用。

いくつかの調整を行うことで、GitLabは、[最小要件](https://docs.gitlab.com/install/requirements/)または[参照アーキテクチャ](https://docs.gitlab.com/administration/reference_architectures/)に記載されているよりもはるかに低い仕様で快適に実行できます。

ほとんどのGitLabパーツはこれらの設定が有効な状態で機能しますが、製品の機能とパフォーマンスの両方が予期せず低下する可能性があります。

{{< alert type="note" >}}

以下のセクションでは、個々のGitリポジトリが100 MB以下の5人までのデベロッパーでGitLabを実行する方法について説明します。

{{< /alert >}}

## 制約のある環境の最小要件 {#minimum-requirements-for-constrained-environments}

GitLabを実行できる最小限の予想される仕様は次のとおりです:

- Linuxベースのシステム（理想的にはDebianベースまたはRedHatベース）
- ARM7/ARM64の4つのCPUコアまたはAMD64アーキテクチャの1つのCPUコア
- 最小2 GBのRAM + 1 GBのSWAP、最適には2.5 GBのRAM + 1 GBのスワップ
- 20 GBの利用可能なストレージ
- 優先順位の良いランダムI/Oパフォーマンスを備えたストレージ:
  - [SSD](https://en.wikipedia.org/wiki/Solid-state_drive)
  - [eMMC](https://magazine.odroid.com/article/emmc-memory-modules-a-simple-guide/)
  - [HDD](https://en.wikipedia.org/wiki/Hard_disk_drive)
  - [高性能A1タイプSDカード](https://www.sdcard.org/developers/sd-standard-overview/application-performance-class/)

上記のリストのうち、CPUのシングルコアパフォーマンスとストレージのランダムI/Oパフォーマンスが最も影響を与えます。制約のある環境では、ある程度のメモリ使用量のスワップが発生することが予想され、使用済みディスクへの負荷が高まるため、ストレージは特に関連性があります。小規模プラットフォームのパフォーマンスが制限される一般的な問題は、非常に遅いディスクストレージであり、システム全体のボトルネックにつながります。

これらの最小設定では、システムは通常動作中にスワップを使用する必要があります。すべてのコンポーネントが同時に使用されるわけではないため、許容できるパフォーマンスを提供する必要があります。

## システムのパフォーマンスを検証する {#validate-the-performance-of-your-system}

Linuxベースのシステムのパフォーマンスを検証するために使用できるツールが多数あります。システムのパフォーマンスのチェックに役立つプロジェクトの1つは、[sbc-bench](https://github.com/ThomasKaiser/sbc-bench)です。特に組込みシステムでGitLabを実行する場合に重要な、システムテストのすべての注意点と、さまざまな動作がシステムのパフォーマンスに与える影響について説明しています。システムのパフォーマンスが、制約のある環境でGitLabを実行するのに十分であるかどうかを検証する方法として使用できます。

これらのシステムは、GitLabの小規模なインスタンスを実行するための適切なパフォーマンスを提供します:

- [Raspberry PI 4 2 GB](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)。
- [DigitalOcean Basic 2 GB with SSD](https://www.digitalocean.com/pricing)。
- [Scaleway DEV1-S 2 GB/20 GB](https://www.scaleway.com/en/pricing/)。
- [GCS e2-small](https://cloud.google.com/compute/docs/machine-resource)。

## スワップの設定 {#configure-swap}

GitLabをインストールする前に、スワップが設定されている必要があります。スワップは、物理RAMがいっぱいになったときに使用されるディスク上の専用スペースです。LinuxシステムのRAMが不足すると、非アクティブなページがRAMからスワップスペースに移動されます。

スワップの使用は、レイテンシーが増加する可能性があるため、問題と見なされることがよくあります。ただし、GitLabの機能により、割り当てられたメモリ使用量の多くは頻繁にアクセスされません。スワップを使用すると、アプリケーションは正常に実行および機能し、時々スワップのみを使用できます。

一般的なガイドラインは、使用可能なメモリ使用量の約50％になるようにスワップを設定することです。メモリ制約のある環境では、システムのスワップを少なくとも1 GB設定することをおすすめします。それを行う方法に関するガイドラインが多数あります:

- [Ubuntu 20.04にスワップスペースを追加する方法](https://linuxize.com/post/how-to-add-swap-space-on-ubuntu-20-04/)
- [CentOS 7にスワップスペースを追加する方法](https://linuxize.com/post/how-to-add-swap-space-on-centos-7/)

設定したら、スワップが正しく有効になっていることを検証する必要があります:

```shell
free -h
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       115Mi       1.4Gi       0.0Ki       475Mi       1.6Gi
Swap:         1.0Gi          0B       1.0Gi
```

また、`/proc/sys/vm/swappiness`を調整して、システムがスワップスペースをどのくらいの頻度で使用するかを設定することもできます。Swappinessの範囲は`0`から`100`です。デフォルト値は`60`です。値を小さくすると、匿名メモリ使用量ページを解放してスワップに書き込むLinuxの優先度が下がりますが、ファイルバックアップページで同じことを行う優先度が高くなります:

1. 現在のセッションで設定します:

   ```shell
   sudo sysctl vm.swappiness=10
   ```

1. `/etc/sysctl.conf`を編集して永続的にします:

   ```shell
   vm.swappiness=10
   ```

## GitLabをインストールする {#install-gitlab}

メモリ制約のある環境では、どのGitLabディストリビューションが自分に適しているかを検討する必要があります。

[GitLab Enterprise Edition (EE)](https://about.gitlab.com/install/)には、[GitLab Community Edition (CE)](https://about.gitlab.com/install/?version=ce)よりも大幅に多くの機能が付属していますが、これらの追加機能はすべて、コンピューティングとメモリ使用量の要件を増加させます。

メモリ使用量の消費が主な懸念事項である場合は、GitLab CEをインストールします。いつでも[GitLab EEにアップグレード](https://docs.gitlab.com/update/package/convert_to_ee/)できます。

## Pumaの最適化 {#optimize-puma}

{{< alert type="warning" >}}

これは実験的な[Alpha機能](https://docs.gitlab.com/policy/development_stages_support/#alpha-features)であり、予告なしに変更される場合があります。この機能は本番環境での使用には対応していません。この機能を使用する場合は、最初に本番環境以外のデータでテストすることをお勧めします。詳細については、[既知の問題](https://docs.gitlab.com/administration/operations/puma/#puma-single-mode-known-issues)を参照してください。

{{< /alert >}}

GitLabはデフォルトで、多くの同時接続を処理するように設計された設定で実行されます。

高いスループットを必要としない小規模なインスタンスの場合は、Puma [クラスタ化モード](https://github.com/puma/puma#clustered-mode)の[無効化](https://docs.gitlab.com/administration/operations/puma/#memory-constrained-environments)を検討してください。その結果、単一のPumaプロセスのみがアプリケーションを処理します。

`/etc/gitlab/gitlab.rb`で:

```ruby
puma['worker_processes'] = 0
```

このようにPumaを設定すると、メモリ使用量が100〜400MB削減されることが確認されました。

## Sidekiqの最適化 {#optimize-sidekiq}

Sidekiqはバックグラウンド処理デーモンです。デフォルトでGitLabで設定すると、`20`の並行処理モードで実行されます。これは、特定の時点で割り当てることができるメモリ使用量に影響します。大幅に小さい`5`または`10`（推奨）の値を使用するように設定することをおすすめします。

`/etc/gitlab/gitlab.rb`で:

```ruby
sidekiq['concurrency'] = 10
```

## Gitalyの最適化 {#optimize-gitaly}

Gitalyは、Gitベースのリポジトリへの効率的なアクセスを可能にするストレージサービスです。Gitalyによって強制される最大の並行処理とメモリ使用量制限を設定することをお勧めします。

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

GitLabは、追加の設定なしで完全なDevOpsソリューションを提供するために、すべてのサービスをデフォルトで有効にします。モニタリングなどのデフォルトサービスの一部は、GitLabが機能するために不可欠ではなく、メモリ使用量を節約するために無効にできます。

`/etc/gitlab/gitlab.rb`で:

```ruby
prometheus_monitoring['enable'] = false
```

このようにGitLabを設定すると、メモリ使用量が200 MB削減されることが確認されました。

## GitLabがメモリ使用量を処理する方法の設定 {#configure-how-gitlab-handles-memory}

GitLabは、（RubyとGoで記述された）多くのコンポーネントで構成されており、GitLab Railsが最大であり、ほとんどのメモリ使用量を消費します。

GitLab Railsは、メモリアロケーターとして[jemalloc](https://github.com/jemalloc/jemalloc)を使用します。[jemalloc](https://github.com/jemalloc/jemalloc)は、パフォーマンスを向上させるために、より大きなチャンクでメモリ使用量を事前割り当てし、より長い期間保持しています。パフォーマンスの低下を犠牲にして、GitLabを設定して、より長い期間保持する代わりに、不要になった直後にメモリ使用量を解放できます。

`/etc/gitlab/gitlab.rb`で:

```ruby
gitlab_rails['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}

gitaly['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}
```

アプリケーションの実行中、はるかに安定したメモリ使用量が確認されました。

## 追加のアプリケーション内モニタリングの無効化 {#disable-additional-in-application-monitoring}

GitLabは内部データ構造を使用して、それ自体のさまざまな側面を測定します。モニタリングが無効になっている場合、これらの機能は不要になります。

これらの機能を無効にするには、GitLabの管理者エリアに移動し、Prometheusメトリクス - Prometheus機能を無効にする必要があります:

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. **設定 > メトリクスとプロファイリング**を選択します。
1. **メトリクス - Prometheus**を展開する。
1. **Prometheusメトリクスの有効化**を無効にします。
1. **変更を保存**を選択します。

## すべての変更を含む設定 {#configuration-with-all-the-changes}

1. これまでに説明したすべてを適用すると、`/etc/gitlab/gitlab.rb`ファイルには次の設定が含まれている必要があります:

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

1. これらすべての変更を加えた後、新しい設定を使用するようにGitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   GitLabはこれまでメモリ使用量を節約する設定で動作しなかったため、この操作にはしばらく時間がかかる可能性があります。

## パフォーマンスの結果 {#performance-results}

上記の設定を適用すると、次のメモリ使用量が予想されます:

```plaintext
              total        used        free      shared  buff/cache   available
Mem:          1.9Gi       1.7Gi       151Mi        31Mi       132Mi       102Mi
Swap:         1.0Gi       153Mi       870Mi
```
