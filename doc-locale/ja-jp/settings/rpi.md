---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Raspberry Piで実行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Raspberry PiでGitLab Community Editionを実行するには、最適な結果を得るために、少なくとも4 GBのRAMを搭載した最新のPi 4が必要です。Pi 3以降のような低リソースでGitLabを実行できるかもしれませんが、推奨されません。古いPiはCPUとRAMが不十分なため、古いPi用のパッケージは提供していません。

デバイスに十分なメモリがあることを確認するには、スワップスペースを4 GBに展開します。

## GitLabをインストールする {#install-gitlab}

GitLabバージョン18.0以降、Raspberry Pi向けの32ビットパッケージの提供を終了しました。

[64ビットRaspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/)を使用し、[GitLabを`arm64` Debianパッケージを使用してインストールする](https://docs.gitlab.com/install/package/debian/)必要があります。

32ビットOSでのデータのバックアップと64ビットOSへの復元については、[PostgreSQLが動作しているオペレーティングシステムをアップグレードする](https://docs.gitlab.com/administration/postgresql/upgrading_os/)を参照してください。

## 実行中のプロセスを減らす {#reduce-running-processes}

お使いのPiがGitLabの実行に苦労している場合は、一部の実行中のプロセスを減らすことができます。

詳細については、GitLabを[メモリ制約のある環境](memory_constrained_envs.md)で実行する方法を参照してください。

## 追加の推奨事項 {#additional-recommendations}

いくつかの設定でGitLabのパフォーマンスを向上させることができます。

### 適切なハードドライブを使用する {#use-a-proper-hard-drive}

GitLabは、SDカードではなくハードドライブから`/var/opt/gitlab`とスワップファイルをマウントすると、最高のパフォーマンスを発揮します。USBインターフェースを使用して、外部ハードドライブをPiに接続できます。

### 外部サービスを使用する {#use-external-services}

GitLabを外部の[データベース](database.md#using-a-non-packaged-postgresql-database-management-server)と[Redis](https://docs.gitlab.com/administration/redis/standalone/)インスタンスに接続することで、Pi上でのGitLabのパフォーマンスを向上させることができます。
