---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Intégration de Vault pour les jetons d'accès de groupe"
---

Ce document décrit comment Omnibus GitLab s'intègre avec HashiCorp Vault pour récupérer les jetons d'accès de groupe permettant d'accéder aux dépôts privés lors des builds.

## Vue d'ensemble {#overview}

Lors de la construction des packages GitLab, Omnibus doit accéder à des dépôts privés contenant des composants sensibles sur le plan de la sécurité. Auparavant, cela était géré à l'aide de `CI_JOB_TOKEN` depuis l'utilisateur `gitlab-bot`, qui disposait de permissions étendues. Avec la centralisation des configurations de miroir dans [`infra-mgmt`](https://gitlab.com/gitlab-com/gl-infra/infra-mgmt), nous utilisons désormais un jeton d'accès de groupe dédié stocké dans Vault.

## Jeton d'accès de groupe {#group-access-token}

Le jeton d'accès de groupe est stocké dans Vault au chemin suivant :

```shell
ci/metadata/access_tokens/gitlab-com/gitlab-org/security/_group_access_tokens/build-token
```

Ce jeton possède :

- **Rôle** : Developer
- **Portée** : `read_repository`
- **Accès** : Groupe de sécurité GitLab.com et ses projets

## Configuration CI {#ci-configuration}

### Modèle d'intégration Vault {#vault-integration-template}

Le modèle `.with-build-token` fournit :

1. **ID Token Configuration** : Configure l'authentification JWT avec Vault
1. **Conditional Secret Retrieval** : Dans les projets de sécurité, récupère automatiquement `SECURITY_PRIVATE_TOKEN` depuis Vault
1. **Environment Setup** : Active l'accès sécurisé au dépôt lorsque nécessaire

Le comportement du modèle s'adapte automatiquement en fonction du contexte du projet :

- **Security projects** (`$SECURITY_PROJECT_PATH`) : Inclure `SECURITY_PRIVATE_TOKEN` depuis Vault
- **Autres projets** : Fournir une intégration Vault de base sans jetons de sécurité

### Utilisation dans les jobs {#usage-in-jobs}

Les jobs nécessitant l'intégration Vault doivent étendre le modèle `.with-build-token` :

```yaml
my-build-job:
  extends: .with-build-token
  script:
    -  # Your build commands here
    -  # SECURITY_PRIVATE_TOKEN is automatically available in security builds
```

## Fonctionnement {#how-it-works}

1. **Authentification** : Les jobs s'authentifient auprès de Vault à l'aide d'un jeton JWT GitLab
1. **Token Retrieval** : Le jeton d'accès de groupe est récupéré depuis Vault et défini en tant que `SECURITY_PRIVATE_TOKEN`

## Dépannage {#troubleshooting}

### Jeton non disponible {#token-not-available}

Si vous voyez des erreurs concernant l'absence de `SECURITY_PRIVATE_TOKEN` :

1. Vérifiez que vous exécutez le job dans un projet de sécurité (`$CI_PROJECT_PATH == $SECURITY_PROJECT_PATH`)
1. Assurez-vous que votre job étend `.with-build-token`
1. Vérifiez que le chemin Vault est correct dans `gitlab-ci-config/vault-security-secrets.yml`

### Accès au dépôt refusé {#repository-access-denied}

Si vous obtenez des erreurs 403 lors de l'accès aux dépôts :

1. Vérifiez que le jeton d'accès de groupe dispose des permissions correctes
1. Vérifiez que `ALTERNATIVE_SOURCES` ou `SECURITY_SOURCES` est activé
1. Assurez-vous que le dépôt est dans la portée d'accès du groupe de sécurité

### Problèmes d'authentification Vault {#vault-authentication-issues}

Si l'authentification Vault échoue :

1. Vérifiez que `VAULT_ID_TOKEN` est correctement configuré
1. Vérifiez que le champ `aud` correspond à l'URL du serveur Vault
1. Assurez-vous que le projet GitLab dispose des permissions de rôle Vault nécessaires
