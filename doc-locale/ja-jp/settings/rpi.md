---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Raspberry Piでの実行
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Raspberry PiでGitLab CEを実行するには、最適な結果を得るために、少なくとも4 GBのRAMを搭載した最新のPi 4が必要です。Pi 3以降など、より低いリソースでGitLabを実行できるかもしれませんが、推奨されません。古いPiはCPUとRAMが不十分なため、パッケージ化されていません。

GitLabバージョン18.0以降、Raspberry Piの32ビットパッケージは提供されなくなります。64ビットのRaspberry Pi OSを使用して、[`arm64` Debianパッケージをインストールする](https://about.gitlab.com/install/#debian)必要があります。32ビットOSでのデータのバックアップと64ビットOSへの復元については、[PostgreSQLが動作しているオペレーティングシステムをアップグレードする](https://docs.gitlab.com/administration/postgresql/upgrading_os/)を参照してください。

## スワップの設定 {#configure-swap}

新しいPiでも、最初に変更する設定は、スワップ領域を4 GBに展開して、デバイスに十分なメモリを確保することです。

Raspbianでは、スワップは`/etc/dphys-swapfile`で構成できます。利用可能な設定については、[manpage](https://manpages.ubuntu.com/manpages/lunar/en/man8/dphys-swapfile.8.html)を参照してください。

## GitLabをインストールする {#install-gitlab}

GitLabをインストールする推奨およびサポートされている方法は、GitLabの公式リポジトリを使用することです。

[公式のRaspberry Pi 64ビットディストリビューション](https://www.raspberrypi.com/software/)のみがサポートされています。

### 公式リポジトリ経由でGitLabをインストールする {#install-gitlab-via-the-official-repository}

[インストールページ](https://about.gitlab.com/install/)にアクセスし、Debianを選択して、指示に従ってGitLabをインストールします。

### GitLabを手動でダウンロードする {#manually-download-gitlab}

選択したディストリビューションがDebianベースの場合、[GitLabを手動でダウンロード](https://docs.gitlab.com/update/package/#upgrade-using-a-manually-downloaded-package)してインストールできます。

## 実行中のプロセスを削減する {#reduce-running-processes}

PiがGitLabの実行に苦労している場合は、実行中のプロセスをいくつか削減できます:

1. `/etc/gitlab/gitlab.rb`を開き、次の設定を変更します:

   ```ruby
   # Reduce the number of running workers to the minimum in order to reduce memory usage
   puma['worker_processes'] = 2
   sidekiq['concurrency'] = 9
   # Turn off monitoring to reduce idle cpu and disk usage
   prometheus_monitoring['enable'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## その他の推奨事項 {#additional-recommendations}

いくつかの設定でGitLabのパフォーマンスを向上させることができます。

### 適切なハードドライブを使用する {#use-a-proper-hard-drive}

GitLabは、SDカードではなく、ハードドライブから`/var/opt/gitlab`とスワップファイルをマウントすると、最高のパフォーマンスを発揮します。USBインターフェースを使用して、外付けハードドライブをPiに接続できます。

### 外部サービスを使用する {#use-external-services}

GitLabを外部の[データベース](database.md#using-a-non-packaged-postgresql-database-management-server)および[Redisインスタンス](https://docs.gitlab.com/administration/redis/standalone/)に接続することにより、Pi上のGitLabのパフォーマンスを向上させることができます。
