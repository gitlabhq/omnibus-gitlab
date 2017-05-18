# GitLab Package Architecture

## Introduction 

GitLab is focused on solving the complete end to end needs of a software development organization, from [idea to production](https://about.gitlab.com/direction/#vision). We include features like an issue tracker, code repository, CI/CD system, monitoring, and chat, just to name a few! In order to provide this diverse set of features, underneath the covers GitLab is a collection of a variety of different components. 

Our [Architecture Overview](https://docs.gitlab.com/ce/development/architecture.html) provides a high level view of the core GitLab components and how they communicate. We also offer other services such as the Container Registry, Mattermost Chat, as well as a load balancer. 

These components also have external dependencies. For example, the Rails application depends on a number of [rubygems]. Some of these dependencies also have their own external dependencies which need to be present on the Operating System in order for them to function correctly.

At GitLab, we strive to ensure customers can install, upgrade, and maintain GitLab as easily as possible. This is especially important since we issue new feature releases [every month on the 22nd](https://about.gitlab.com/release-list/), with patch releases in between. We want all of our customers to be running the latest and greatest version of GitLab.

## Strategy and Vision

GitLab is in use by hundreds of thousands of organizations, of nearly every size and stripe. From small personal projects using our open source Community Edition, to large enterprises with tens of thousands of developers using Enterprise Edition Premium, and finally GitLab.com with over one hundred thousand projects.  

The tools and methods we provide to customers to need to support these different environments, and still maintain the ease of use required to ensure customers can upgrade every month without trouble. 

To achieve this we plan to offer two primary methods of consuming GitLab:
* All-in-One Omnibus based packages and images
* Cloud native installation 

### All-in-One Omnibus based packages and images

Our Omnibus based packages and images provide an easy way to get started with GitLab. They contain everything needed for the full idea to production lifecycle, including nearly all dependencies.  We provide installation packages for a variety of operating systems, including: Ubuntu, Debian, CentOS, OpenSUSE, and even Raspbian. 

These packages provide the foundation for other Omnibus based installation methods, as well. We offer offical Docker all-in-one images on Docker Hub, and a number of virtual images for running on cloud providers like Amazon and Azure.

More detailed information on our Omnibus based packages and images is available [here](omnibus_packages.html).

### Cloud native installation

We are also working towards an installation method for organizations who desired to deploy in a more cloud native way. Typically this would be customers looking to deploy at scale using Docker images on a container scheduler like Kubernetes.

While it is possible to deploy our Omnibus based Docker image in this way, it becomes more challenging to operate and maintain as scale increases. Using "fat images" also does not align with cloud native best practices.

To achieve this we will be creating a collection of Docker images, each containing only a very specific part of the overall GitLab solution. Then using orchestration software, connect the individual services together to form a complete GitLab service.

Our goals are for this method to be both easy to deploy using tools like Helm, and easily scalable to [GitLab.com levels](http://monitor.gitlab.net) and beyond. 

More detailed information on our cloud native installation method is available [here](cloud_native.html).
