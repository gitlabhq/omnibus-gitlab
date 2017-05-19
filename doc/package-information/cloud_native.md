# Cloud Native Installation

We are working on a new method of installing GitLab, for customers who are looking to deploy into container schedulers like Kubernetes.

While this is possible today using our all-in-one Docker image, there are two primary challenges. First, it does not align with cloud native best practices by using a "fat container", which contains all parts of GitLab. Second and relatedly, it is not as easy to operate at scale as we would like. 

## Goals

We have a few core goals with this initiative:
1. Easy to scale horizontally 
1. Easy to deploy, upgrade, maintain
1. Wide support of cloud service providers
1. Initial support for Kubernetes and Helm, with flexibility to support other schedulers in the future

## Architecture

We plan to support three tiers of components:
1. Docker Containers
1. Scheduler (e.g. Kubernetes)
1. Higher level configuration tool (e.g. Helm)

The main method customers would use to install would be our [Helm Charts](https://gitlab.com/charts/charts.gitlab.io). At some point in the future, we may also offer other deployment methods like Amazon CloudFormation or Docker Swarm. 

### Docker Container Images

As a foundation, we will be creating a Docker container for each service. This will allow easier horizontal scaling with reduced image size and complexity. Configuration should be passed in a standard way for Docker, perhaps environment variables or a mounted file. This provides a clean common interface with the scheduler software.

We plan to offer a container for the following services:
* Pages
* Sidekiq
* Unicorn API
* Unicorn Web
* Gitaly
* Workhorse
* Postgres (perhaps upstream Postgres), along with Postgres Exporter
* Redis Exporter
* GitLab Monitor
* Mattermost

We likely plan to leverage the following existing official containers for underlying services:
* Docker Distribution (Container Registry)
* Redis
* Prometheus
* Node Exporter
* nginx
* kube-lego

### Scheduler

We will launch with support for Kubernetes, which is mature and widely supported across the industry. As part of our design however, we will try to avoid decisions which will preclude the support of other schedulers. This is especially true for downstream Kubernetes projects like OpenShift and Tectonic. In the future other schedulers may also be supported like Docker Swarm and Mesosphere.

We aim to support the scaling and self-healing capabilities of Kubernetes:
* Readiness and Health checks to ensure pods are functioning, and if not to recycle them
* Tracks to support canary and rolling deployments 
* [Auto-scaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

We will leverage standard Kubernetes features:
* ConfigMaps for managing configuration. These will then get mapped or passed to Docker containers
* Secrets for sensitive data

### Helm Charts

We already provide officially supported Helm Charts, and plan to continue to leverage these to provide an easy deployment method. This is particularly important for this effort, as there will be significantly more complexity in the Docker and Kubernetes layers than the all-in-one Omnibus based solutions. Helm can help to manage this complexity, and provide an easy top level interface to manage settings via the `values.yaml` file.


We plan to offer a three tiered set of Helm Charts

![Helm Chart Structure](images/charts.png)

#### The GitLab Chart

This is the top level `gitlab` chart, which configures all necessary resources for a complete configuration of GitLab. This includes GitLab, PostgreSQL, Redis, Ingress, and LEGO certificate management charts. 

At this high level, a customer can make decisions like:
* Whether they want to use the embedded Postgres chart, or to use an external database like Aamzon RDS for Postgres.
* To bring their own SSL certificates, or leverage Let's Encrypt.
* To use a load balancer, or a dedicated ingress.

Customers who would like to get started quickly and easily should begin with this chart.

#### The GitLab-Rails? Chart

This chart is dedicated to core GitLab services that make up the Idea to Production workflow: code repository, issue tracking, CI/CD, monitoring, container registry, etc.

We have not landed on a name for this yet. The present favorite is `gitlab-rails`, but this chart admittedly includes much more than just Rails functionality.

This chart would also include options to configure exactly how these services should work, whether all of them should be available, etc.

#### Redis and Postgres Charts

We will also likely need to create specific charts for Redis and Postgres. One reason is that there is a bug with variable handling between parent and child charts, but also because we will need to include the respective exporters as well.

