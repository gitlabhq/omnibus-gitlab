---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Signatures des packages Linux
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Nous maintenons un système d'hébergement de packages pour partager les différents packages OS que nous proposons à <https://packages.gitlab.com>.

L'instance utilise diverses méthodes cryptographiques pour garantir l'intégrité de ces packages.

## Clé de signature des métadonnées du dépôt de packages {#package-repository-metadata-signing-key}

Les dépôts APT et YUM utilisent une clé GPG pour signer leurs métadonnées. Cette clé est automatiquement installée par le script de configuration du dépôt spécifié dans les instructions d'installation.

### Clé de signature du dépôt actuel {#current-repository-signing-key}

La clé suivante est utilisée pour signer les métadonnées du dépôt.

| Attribut de clé | Valeur |
|:--------------|:------|
| Nom          | `GitLab B.V.` |
| E-mail         | `packages@gitlab.com` |
| Commentaire       | `package repository signing key` |
| Empreinte   | `F640 3F65 44A3 8863 DAA0 B6E0 3F01 618A 5131 2F3F` |
| Expiration        | `2028-02-06` |
| Emplacement de téléchargement | `https://packages.gitlab.com/gpgkey/gpg.key` |

- Actif depuis le **2020-04-06**.
- L'expiration a été prolongée du **2024-03-01** au **2026-02-27**.
- L'expiration a été prolongée du **2026-02-27** au **2028-02-06**.

Si vous obtenez une erreur indiquant que la clé a expiré, vous devez [récupérer la dernière clé de signature du dépôt](#fetch-the-latest-repository-signing-key).

### Récupérer la dernière clé de signature du dépôt {#fetch-the-latest-repository-signing-key}

Pour récupérer la dernière clé de signature du dépôt :

{{< tabs >}}

{{< tab title="Debian/Ubuntu/Raspbian" >}}

1. Téléchargez la clé :

   ```shell
   sudo mkdir -p /etc/apt/keyrings
   sudo curl --fail --silent --show-error \
        --output /etc/apt/keyrings/gitlab-keyring.asc \
        --url "https://packages.gitlab.com/gpgkey/gpg.key"
   ```

1. Mettez à jour votre fichier source du dépôt pour référencer la clé. Modifiez `/etc/apt/sources.list.d/gitlab_gitlab-ee.list` (ou `gitlab_gitlab-ce.list`), et ajoutez `[signed-by=/etc/apt/keyrings/gitlab-keyring.asc]` après `deb` :

   ```plaintext
   deb [signed-by=/etc/apt/keyrings/gitlab-keyring.asc] https://packages.gitlab.com/gitlab/gitlab-ee/<os>/<codename> <codename> main
   deb-src [signed-by=/etc/apt/keyrings/gitlab-keyring.asc] https://packages.gitlab.com/gitlab/gitlab-ee/<os>/<codename> <codename> main
   ```

> [!note]
> L'utilisation de `apt-key` [a été dépréciée](https://blog.packagecloud.io/secure-solutions-for-apt-key-add-deprecated-messages/) et supprimée dans Debian 13.
>
> Si vous utilisez `apt-key` et ne pouvez pas migrer vers la méthode `signed-by` (vous utilisez `apt-key` si votre fichier de liste de sources ne contient pas `signed-by`), exécutez la commande suivante en tant que root pour mettre à jour les clés publiques des dépôts GitLab :
>
> ```shell
> curl -s "https://packages.gitlab.com/gpgkey/gpg.key" | apt-key add -
> apt-key list 3F01618A51312F3F
> ```

{{< /tab >}}

{{< tab title="CentOS/OpenSUSE/SLES" >}}

1. [Vérifiez que `repo_gpgcheck` est actif](#verify-if-signature-check-is-active).
1. Obtenez la liste des clés actuellement installées et supprimez-les :

   ```shell
   rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n' | grep -i gitlab | xargs sudo rpm -e
   ```

1. Purgez le cache dnf :

   ```shell
   sudo rm -rf /var/cache/dnf
   ```

1. [Ajoutez à nouveau le dépôt de packages GitLab](https://docs.gitlab.com/install/package/almalinux/#add-the-gitlab-package-repository).
1. Reconstruisez le cache :

   ```shell
   sudo dnf makecache
   ```

{{< /tab >}}

{{< /tabs >}}

### Clés de signature du dépôt précédentes {#previous-repository-signing-keys}

Les clés suivantes ont été utilisées pour signer les métadonnées du dépôt et sont désormais expirées.

| N° de série | ID de clé                                               | Date d'expiration |
|:--------|:-----------------------------------------------------|:------------|
| 1       | `1A4C 919D B987 D435 9396  38B9 1421 9A96 E15E 78F4` | `2020-04-15` |

## Vérification de la signature des packages {#package-signature-verification}

Vous pouvez vérifier les signatures des packages produits par GitLab, à la fois manuellement et automatiquement lorsque cela est pris en charge.

### Clé de signature de package actuelle {#current-package-signing-key}

La clé suivante est utilisée pour signer les métadonnées du dépôt.

| Attribut de clé | Valeur |
|---------------|-------|
| Nom          | `GitLab, Inc.` |
| E-mail         | `support@gitlab.com` |
| Empreinte   | `98BF DB87 FCF1 0076 416C 1E0B AD99 7ACC 82DD 593D` |
| Expiration        | `2028-02-16` |
| Emplacement de téléchargement | `https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg` |

### Clés de signature de package précédentes {#previous-package-signing-keys}

| N° de série | ID de clé                                              | Date de révocation | Date d'expiration  | Emplacement de téléchargement |
|---------|-----------------------------------------------------|-----------------|--------------|-------------------|
| 1       | `9E71 648F 3A35 EA00 CAE4 43E7 1155 1132 6BA7 34DA` | `2025-02-14`    | `2025-07-01` | `https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-3D645A26AB9FBD22.pub.gpg` |

### Distributions basées sur RPM {#rpm-based-distributions}

Le format RPM contient une implémentation complète de la fonctionnalité de signature GPG et est entièrement intégré aux systèmes de gestion de packages basés sur ce format.

#### Vérifier que la clé publique GitLab est présente {#verify-gitlab-public-key-is-present}

Pour vérifier un package sur une distribution basée sur RPM, assurez-vous que la clé publique de GitLab, Inc. est présente dans le trousseau de clés `rpm`. Par exemple :

```shell
rpm -q gpg-pubkey-98bfdb87fcf10076416c1e0bad997acc82dd593d-67aefdd8 --qf '%{name}-%{version}-%{release} --> %{summary}'
```

Cette commande produit soit :

- Des informations sur la clé publique.
- Un message indiquant que la clé n'est pas installée. Par exemple : `gpg-pubkey-f27eab47-60d4a67e is not installed`.

Si la clé n'est pas présente, importez-la. Par exemple :

```shell
rpm --import https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg
```

#### Vérifier si la vérification de la signature est active {#verify-if-signature-check-is-active}

Pour vérifier si la vérification de la signature de package est active sur une installation existante, comparez le contenu du fichier du dépôt :

1. Vérifiez si le fichier du dépôt existe : `file /etc/yum.repos.d/gitlab_gitlab-*.repo`.
1. Vérifiez que la vérification de la signature est active : `grep gpgcheck /etc/yum.repos.d/gitlab_gitlab-*.repo`. Cette commande devrait produire :

   ```plaintext
   repo_gpgcheck=1
   gpgcheck=1
   repo_gpgcheck=1
   gpgcheck=1
   ```

   ou

   ```plaintext
   repo_gpgcheck=1
   pkg_gpgcheck=1
   repo_gpgcheck=1
   pkg_gpgcheck=1
   ```

Si le fichier n'existe pas, le dépôt n'est pas installé. Si le fichier existe, mais que la sortie affiche `gpgpcheck=0`, vous devez modifier cette valeur pour l'activer.

#### Vérifier un fichier `rpm` de package Linux {#verify-a-linux-package-rpm-file}

Après avoir confirmé que la clé publique est présente, vérifiez le package :

```shell
rpm --checksig gitlab-xxx.rpm
```

### Distributions basées sur Debian {#debian-based-distributions}

Le format de package Debian ne contient pas officiellement de méthode pour signer les packages. Nous avons implémenté la norme `debsig`, qui est bien documentée mais non activée par défaut sur la plupart des distributions.

Vous pouvez vérifier un fichier `deb` de package Linux de l'une des façons suivantes :

- En utilisant `debsig-verify` après avoir configuré la politique et le trousseau de clés `debsigs` nécessaires.
- En vérifiant manuellement le fichier `_gpgorigin` contenu avec GnuPG.

#### Configurer `debsigs` {#configure-debsigs}

Étant donné que la configuration d'une politique et d'un trousseau de clés pour `debsigs` peut être complexe, nous fournissons le script `gitlab-debsigs.sh` pour la configuration. Pour utiliser ce script, vous devez télécharger la clé publique et le script.

```shell
curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
curl -JLO "https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/scripts/gitlab-debsigs.sh"
chmod +x gitlab-debsigs.sh
sudo ./gitlab-debsigs.sh CB947AD886C8E8FD.pub.gpg
```

#### Vérifier avec `debsig-verify` {#verify-with-debsig-verify}

Pour utiliser `debsig-verify` :

1. [Configurez `debsigs`](#configure-debsigs).
1. Installez le package `debsig-verify`.
1. Exécutez `debsig-verify` pour vérifier le fichier :

   ```shell
   debsig-verify gitlab-xxx.deb
   ```

#### Vérifier avec GnuPG {#verify-with-gnupg}

Si vous ne souhaitez pas installer les dépendances installées par `debsig-verify`, vous pouvez utiliser GnuPG à la place :

1. Téléchargez et importez la clé publique de signature de package :

   ```shell
   curl -JLO "https://packages.gitlab.com/gitlab/gitlab-ee/gpgkey/gitlab-gitlab-ee-CB947AD886C8E8FD.pub.gpg"
   gpg --import CB947AD886C8E8FD.pub.gpg
   ```

1. Extrayez le fichier de signature `_gpgorigin` :

   ```shell
   ar x gitlab-xxx.deb _gpgorigin
   ```

1. Vérifiez que la signature correspond au contenu :

   ```shell
   ar p gitlab-xxx.deb debian-binary control.tar.xz data.tar.xz | gpg --verify _gpgorigin -
   ```

   La sortie de cette commande devrait ressembler à ceci :

   ```shell
   gpg: Signature made Wed Feb 18 18:07:22 2026 UTC
   gpg:                using RSA key 98BFDB87FCF10076416C1E0BAD997ACC82DD593D
   gpg:                issuer "support@gitlab.com"
   gpg: Good signature from "GitLab, Inc. <support@gitlab.com>" [unknown]
   Primary key fingerprint: 98BF DB87 FCF1 0076 416C  1E0B AD99 7ACC 82DD 593D
   ```

Si la vérification échoue avec `gpg: BAD signature from "GitLab, Inc. <support@gitlab.com>" [unknown]`, assurez-vous que :

- Les noms de fichiers sont écrits dans le bon ordre.
- Les noms de fichiers correspondent au contenu de l'archive.

Selon la distribution Linux que vous utilisez, le contenu de l'archive peut avoir un suffixe différent. Cela signifie que vous devez adapter la commande en conséquence. Pour confirmer le contenu de l'archive, exécutez `ar t gitlab-xxx.deb`.

Par exemple, pour Ubuntu Focal (20.04) :

```shell
$ ar t gitlab-ee_17.4.2-ee.0_amd64.deb
debian-binary
control.tar.xz
data.tar.xz
_gpgorigin
```
