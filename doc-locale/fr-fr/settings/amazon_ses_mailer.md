---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Paramètres du mailer Amazon SES
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/3655) dans GitLab 19.3.

{{< /history >}}

Pour envoyer des e-mails d'application via l'[API Amazon SES](https://docs.aws.amazon.com/ses/latest/dg/send-email-api.html), ajoutez la configuration suivante à `/etc/gitlab/gitlab.rb` et exécutez `gitlab-ctl reconfigure`.

> [!warning]
> Si vous avez activé SMTP, définissez `gitlab_rails['smtp_enable']` sur `false`. Lorsque SMTP est activé, il remplace le mailer Amazon SES et GitLab envoie les e-mails via SMTP.

## S'authentifier avec un rôle IAM {#authenticate-with-an-iam-role}

Pour vous authentifier avec un rôle IAM, fournissez le nom de ressource Amazon (ARN) du rôle. Les identifiants sont obtenus via AWS Security Token Service (STS).

```ruby
gitlab_rails['amazon_ses_mailer_enabled'] = true
gitlab_rails['amazon_ses_mailer_region'] = "<your_aws_region>"
gitlab_rails['amazon_ses_mailer_role_arn'] = "arn:aws:iam::123456789012:role/<your_role>"
```

## S'authentifier avec des clés statiques {#authenticate-with-static-keys}

Pour vous authentifier avec des clés statiques, fournissez l'ID de clé d'accès et la clé d'accès secrète.

```ruby
gitlab_rails['amazon_ses_mailer_enabled'] = true
gitlab_rails['amazon_ses_mailer_region'] = "<your_aws_region>"
gitlab_rails['amazon_ses_mailer_access_key_id'] = "<your_aws_access_key_id>"
gitlab_rails['amazon_ses_mailer_secret_access_key'] = "<your_aws_secret_access_key>"
```

## S'authentifier avec la chaîne de fournisseurs d'identifiants AWS {#authenticate-with-the-aws-credential-provider-chain}

Lorsque vous omettez `role_arn`, `access_key_id` et `secret_access_key`, GitLab bascule vers la [chaîne de fournisseurs d'identifiants AWS](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/credential-providers.html#credchain). La chaîne vérifie les identifiants depuis des sources telles que les variables d'environnement, un profil partagé, ECS et EC2.

```ruby
gitlab_rails['amazon_ses_mailer_enabled'] = true
gitlab_rails['amazon_ses_mailer_region'] = "<your_aws_region>"
```
