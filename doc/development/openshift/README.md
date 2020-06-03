---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Omnibus GitLab Development Setup

## Requirements

An all-in-one install of OpenShift will require at least 5Gb of free RAM on your
computer in order to test GitLab.

- We are currently compatible with OpenShift Origin 1.3.x. Anything lower will not work.
- For the Minishift based setup you need either:
  - Linux: KVM 0.7.0
  - Mac OSX: xhyve 0.3.1
- For the Docker based setup you need Docker >= 1.10 and < 17.00
- For the Ansible based setup you need to be on a RHEL compatible host
  - RHEL/CentOS/Fedora/Atomic

## Setup OpenShift Origin

The first thing you need to interact with OpenShift Origin, are the `oc` client tools for your terminal:

1. Download and install the OpenShift Origin Client Tools onto your path if you don't already have them.
   - Found here: <https://github.com/openshift/origin/releases>
   - Example: <https://github.com/openshift/origin/releases/download/v1.4.1/openshift-origin-client-tools-v1.4.1-3f9807a-linux-64bit.tar.gz>

Next you need to setup an OpenShift Origin environment. To setup the environment you can use the production installer
on a cloud machine, use minishift on your local machine (uses kvm or xhyve), or setup an instance
using Docker for the master, and your own machine as the slave using `oc cluster up`

### Minishift

Installation instructions for Minishift can be found at <http://docs.okd.io/3.11/minishift/getting-started/installing.html>

1. Before installing Minishift you need to install the proper Docker machine driver.
   - For Linux, install the [kvm driver](http://docs.okd.io/3.11/minishift/getting-started/setting-up-virtualization-environment.html#setting-up-kvm-driver)
   - For Mac OSX, install the [xhyve driver](http://docs.okd.io/3.11/minishift/getting-started/setting-up-virtualization-environment.html#setting-up-xhyve-driver)

1. Install Minishift, following the [instruction for your platform](http://docs.okd.io/3.11/minishift/getting-started/installing.html)

1. Start Minishift with enough cpu/memory to run GitLab: `minishift start --cpus 4 --memory 6144`
   - When it is finished starting, the command will output the location of the web console.

1. Minishift internally uses the [oc cluster up method](#docker-oc-cluster-up), so start following the directions in step 2

1. You can login to the UI at `https://<your_local_minishift_ip>:8443/console/`
   - Your minishift IP was shown after starting minishift, but you can also find it later by running `minishift ip`

### Docker oc cluster up

NOTE: **Note:**
The information listed below may be out of date. See
[OKD documentation](https://docs.okd.io/latest/welcome/index.html) for more recent information
regarding cluster setup.

If you have Docker installed, you can setup OpenShift Origin on your local machine: <https://github.com/openshift/origin/blob/77bf0a926c045142570bb50a9a83086a370506a8/docs/cluster_up_down.md>

`**Note:`this currently does not start if you are using `docker-ce`/`ee` with the new version scheme (17.xx)

1. On your terminal call `oc cluster up  --host-data-dir='/srv/openshift'`
   - Note that oc cluster needs access to port 80 on your host, so you may need to stop any webserver while using OpenShift

1. Create a new namespace to assign storage and permissions to.
   - `oc new-project <namespace>`

1. Login as system admin
   - `oc login -u system:admin`

1. In order to allow the GitLab pod to run as root you need to edit the anyuid security context:
   - `oc adm policy add-scc-to-user anyuid system:serviceaccount:<namespace>:<gitlab-app-name>-user`
   - (`gitlab-app-name` is the first config option when installing GitLab, and defaults to `gitlab-ce`)

1. Create some Persistent Volumes for GitLab to use.
   - Create a file with the following:

    ```yaml
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv0001
    spec:
      capacity:
        storage: 5Gi
      accessModes:
      - ReadWriteOnce
      hostPath:
        path: /srv/openshift-gitlab/pv0001
      persistentVolumeReclaimPolicy: Recycle
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv0002
    spec:
      capacity:
        storage: 5Gi
      accessModes:
      - ReadWriteOnce
      hostPath:
        path: /srv/openshift-gitlab/pv0002
      persistentVolumeReclaimPolicy: Recycle
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv0003
    spec:
      capacity:
        storage: 5Gi
      accessModes:
      - ReadWriteOnce
      hostPath:
        path: /srv/openshift-gitlab/pv0003
      persistentVolumeReclaimPolicy: Recycle
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv0004
    spec:
      capacity:
        storage: 5Gi
      accessModes:
      - ReadWriteOnce
      hostPath:
        path: /srv/openshift-gitlab/pv0004
      persistentVolumeReclaimPolicy: Recycle
    ```

   - run `oc create -f <filename>` for each file to add them to the cluster

1. Create each of the host paths on your own machine and ensure they have a `777` filemode

1. You can now login to the UI at <https://localhost:8443/console/>

### Production Ansible Installer

You can use OpenShift's Ansible installer to set up OpenShift masters and slaves in Digital Ocean. Follow the [advanced install docs](https://docs.openshift.com/container-platform/3.7/install_config/install/advanced_install.html).

You can find the Ansible playbooks at: <https://github.com/openshift/openshift-ansible>

After setting it all up, you will need to make sure you deploy the registry and router mentioned in the [what's next section](https://docs.openshift.com/container-platform/3.7/install_config/install/advanced_install.html#whats-next)

In order to finish setting up the cluster, you need to create a project and allow your project's service account to run as anyuid.

- `oc new-project <your_project_name>`
- `oc edit scc anyuid` and add `system:serviceaccount:<namespace>:<gitlab-app-name>-user` (`gitlab-app-name` is the first config option when installing GitLab, and defaults to `gitlab-ce`)

And you need to setup persistent volumes. See 3 and 4 of the [oc cluster up steps](#docker-oc-cluster-up)

## Add the GitLab template to OpenShift

**`Note`** This section is deprecated. Check [the open issue to for more details](https://gitlab.com/gitlab-org/distribution/team-tasks/-/issues/263).

Add the GitLab template to OpenShift (The next release of the VM includes GitLab, so this may not be required):

- `oc login -u system:admin` for the Docker cluster up
- From the root of your Omnibus GitLab repo, `oc create -f docker/openshift-template.json -n openshift`

## Install GitLab

After having setup the template:

1. Go to the web console for OpenShift
1. Create a new project or use an existing one that doesn't already have GitLab
1. Add to Project, and add the GitLab-Ce template

## Removing the GitLab template

In case you want to upload a new version of it:

`oc delete template/gitlab-ce -n openshift`

## Known Issues

 1. If running `oc cluster up` from your dev machine, newer versions of Docker are not yet supported. (The 17.xx version scheme)

 1. If you are running minishift, persistent volumes do not yet get persisted between restarts. So you need setup a new cluster each
 time you go to use it.

## Releasing a New Version

See the [OpenShift Omnibus GitLab release process](../../release/openshift.md).
