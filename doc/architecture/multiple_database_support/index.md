---
status: proposed
creation-date: "2023-10-02"
authors: [ "@pursultani" ]
approvers: [ "@product-manager", "@engineering-manager" ]
owning-stage: "~devops::systems"
participating-stages: []
---

# Multiple databases support

## Summary

This document explains how to support a component with one or more databases. It
describes different levels of support and offers an implementation model for
each level to overcome the several challenges of the [recommended deployment models](https://docs.gitlab.com/ee/administration/reference_architectures/).

The [architecture page](../index.md#multiple-databases) provides some
background on this subject.

A [development document](../../development/database_support.md) accompanies this
blueprint. It details the implementation model and provides a few examples.

## Goals

- Offer [higher levels of support](#levels-of-support) for current and new
  components with database requirements.
- Implementation refactors maintain the current configuration options
  already present in `gitlab.rb`.
- Minimize breaking changes and refactors in database code with a consistent,
  testable, and extensible implementation model.
- Migrate code to the newer implementation method.

## Proposal

### Terminology

|Term|Definition|
|-|-|
|Database|A _logical_ database that a component, such as Rails application, uses. For example, `gitlabhq_production`. A component can have more than one database.|
|Database server| A _standalone process_ or a _cluster_ that provides PostgreSQL database service. Not to be confused with database objects or data.|
|Database objects| Anything that is created with Data Definition Language (DDL), such as `DATABASE`, `SCHEMA`, `ROLE`, or `FUNCTION`. It may include reference data or indices as well. These are partially created by Omnibus GitLab and the rest are created by application-specific _database migrations_.|
|Standalone database server| A single PostgreSQL database server. It can be accessed through a PgBouncer instance.|
|Database server cluster|Encompasses multiple PostgreSQL database servers, managed by Patroni services, backed by a Consul cluster, accessible by using one or more PgBouncer instances, and may include an HAProxy (in TCP mode) as a frontend.|

### Levels of support

There are different levels of database support for Omnibus GitLab components.
Higher levels indicate more integration into Omnibus GitLab.

#### Level 1

Configure the component with user-provided parameters from `gitlab.rb` to work
with the database server. For example,  `database.yml` is rendered with database
server connection details of the Rails application or database parameters of
Container Registry are passed to its `config.yml`.

#### Level 2

Create database objects and run migrations of the component. Full support at
this level requires Omnibus GitLab to not only create the required database
objects, such as `DATABASE` and `ROLE`, but also to run the application
migration to for the component.

#### Level 3

Static configuration of PgBouncer. At this level, Omnibus GitLab can create a
_dedicated PgBouncer user_ for the component and configure it with user-provided
(from `gitlab.rb`) or application-mandated connection settings.

This is not specific to clustered database server setups but it is a requirement
for it. There are scenarios where PgBouncer is configured with a standalone
database server. However, all clustered database server setups depend on
PgBouncer configuration.

#### Level 4

Configuration of database server cluster in high-availability (HA) mode. At this
level, Omnibus GitLab supports various deployment models, ranging from _one
cluster for all databases_ to _one cluster per database_.

Therefore the HA configuration of logical databases must be independent of the
deployment model.

Consul [services](https://developer.hashicorp.com/consul/docs/srvices/configuration/services-configuration-reference)
can have multiple health-checks and [watches](https://developer.hashicorp.com/consul/docs/dynamic-app-config/watches#service).
At this level, Omnibus GitLab defines _a Consul service per database cluster_
and _a service watch per logical database_.

Omnibus GitLab configures [Patroni to register a Consul service](https://patroni.readthedocs.io/en/latest/yaml_configuration.html#consul).
The name of the service is the scope parameter as its tag is the role of the
node which can be one of `master`, `primary`, `replica`, or `standby-leader`. It
uses this service name, which is the same as the scope of Patroni cluster, to
address a database cluster and associate it to any logical database that the
cluster serves.

This is done with Consul watches that track Patroni services. They find cluster
leaders and notify PgBouncer with the details of both the database cluster and
the logical database.

#### Level 5

Automated or assisted transition from previous deployment models. Not all
components require this level of support but, in some cases, where a recommended
yet deprecated database configuration is in use, Omnibus GitLab may provide
specialized tools or procedures to allow transitioning to the new database
model. In most cases, this is not supported unless specified.

### Design overview

Each component manages every aspect of its own database requirements, _except
its database users_. It means that component-specific implementation of database
operations are done in the specific cookbooks of each component. For example,
Rails or Registry database requirements are exclusively addressed in `gitlab`
and `registry` cookbooks and not in `postgresql`, `pgbouncer`, or `patroni`
cookbooks.

The database users are excluded because `SUPERUSER` or users with `CREATEROLE`
privilege can create PostgreSQL users. Due to security considerations we do not
grant this privilege to the users that are connected over TCP connection. So
components that may connect to a remote database do not have the permission to
create their users.

Hence each component creates its own database objects, _except its database user_.
`postgresql` and `patroni` cookbooks create the database users but each component
creates the rest of its database objects. The database users must have `CREATEDB`
privilege to allow components create their own `DATABASE` and trusted `EXTENSION`.

To impose a structure and fix some of the shortcomings of this approach, such as
locality and limited reusability, we use [Chef resource model](https://docs.chef.io/resources/)
and leverage [custom resources](https://docs.chef.io/custom_resources/) for
database configuration and operations, including:

- Manage lifecycle of component-specific database objects
- Run application-specific database migrations
- Set up PgBouncer to serve the application
- Set up Consul watches to track Patroni clusters

Cross-cutting concerns such as [central on/off switch for auto-migration](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7716),
logging control, and [pre-flight checks](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5428)
are addressed with [helper classes](https://docs.chef.io/helpers/) that are
available to all components. The `package` cookbook is a suitable place for
these helpers.

Helper classes also provide a place to translate the existing user configuration
model (in `gitlab.rb`) to the new model needed for management of
multiple databases.

### Implementation details

[Development document](../../development/database_support.md) provides
implementation details and concrete examples for the proposed design.
