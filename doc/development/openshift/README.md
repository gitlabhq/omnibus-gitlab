## Development Setup

### Requirements

An all-in-one install of OpenShift will require at least 5Gb of free RAM on your
computer in order to test GitLab.

 - We are currently compatible with OpenShift Origin 1.3.x. Anything lower will not work.
 - For the VirtualBox based setup you need either:
   - VirtualBox 5.0 with Vagrant 1.8.4
   - VirtualBox 5.1 with Vagrant 1.8.7
 - For the Docker based setup you need Docker >= 1.10
 - For the Ansible based setup you need to be on a RHEL compatible host
   - RHEL/CentOS/Fedora/Atomic


### Setup OpenShift Origin

The first thing you need to interact with OpenShift Origin, are the `oc` client tools for your terminal:

1. Download and install the OpenShift Origin Client Tools onto your path if you don't already have them.
   - Found here: https://github.com/openshift/origin/releases
   - Example: https://github.com/openshift/origin/releases/download/v1.3.1/openshift-origin-client-tools-v1.3.1-dad658de7465ba8a234a4fb40b5b446a45a4cee1-linux-64bit.tar.gz

Next you need to setup an OpenShift Origin environment. To setup the environment you can use the production installer
on a cloud machine, use the all-in-one VM on your local machine (uses vagrant and virtualbox), or setup an instance
using docker for the master, and your own machine as the slave using `oc cluster up`

#### All-in-One VM

Installation instructions for the all-in-one vm can be found at [www.openshift.org/vm/](https://www.openshift.org/vm/).

1. Make sure you have virtualbox and vagrant installed.
   - VirtualBox 5.0 with Vagrant 1.8.4 have been tested working (Vagrant 1.8.5 and 1.8.6 do not)
   - VirtualBox 5.1 requires Vagrant 1.8.7 to work.

2. In a new folder run `vagrant init openshift/origin-all-in-one`

3. Then `vagrant up` to import and start the vm.
   - This will provision the vm with 2 cpu cores and 5Gb of RAM.

4. You can now login to the UI at https://10.2.2.2:8443/console and create a new project

#### Docker oc cluster up

If you have Docker installed, you can setup OpenShift Origin on your local machine: https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md

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

    ```
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

1. You can now login to the UI at https://localhost:8443/console/

#### Production Ansible Installer

You can use OpenShift's Ansible installer to setup OpenShift masters and slaves in Digital Ocean. Follow the [advanded install docs](https://docs.openshift.org/latest/install_config/install/advanced_install.html).

You can find the Ansible playbooks at: https://github.com/openshift/openshift-ansible

After setting it all up, you will need to make sure you deploy the registry and router mentioned in the [what's next section](https://docs.openshift.org/latest/install_config/install/advanced_install.html#what-s-next)

In order to finish setting up the cluster, you need to create a project and allow your project's service account to run as anyuid.

 - `oc new-project <your_project_name>``
 - `oc edit scc anyuid` and add `system:serviceaccount:<namespace>:<gitlab-app-name>-user` (`gitlab-app-name` is the first config option when installing GitLab, and defaults to `gitlab-ce`)

And you need to setup persistent volumes. See 3 and 4 of the [oc cluster up steps](#docker_oc_cluster_up)


### Add the GitLab template to OpenShift

Add the GitLab template to OpenShift (The next release of the VM includes GitLab, so this may not be required)
   - `oc login https://10.2.2.2:8443` username: `admin` password: `admin` for the all-in-one vm.
   - `oc login -u system:admin` for the docker cluster up
   - From the root of your omnibus-gitlab repo, `oc create -f docker/openshift-template.json -n openshift`

### Install GitLab

After having setup the template:

1. Go to the web console for OpenShift
2. Create a new project or use an existing one that doesn't already have GitLab
3. Add to Project, and add the GitLab-Ce template

### Removing the GitLab template

In case you want to upload a new version of it:

`oc delete template/gitlab-ce -n openshift`

### Known Issues

 There is an issue with the all-in-one VM where it's networking isn't properly setup when OpenShift starts.
 This results in the GitLab app not able to communicate with redis or postgres, and the postgres post-hook fails
 during setup. The current solution is to issue `vagrant ssh` into the box, then `sudo shutdown -r now` and once
 it comes back up you will need to deploy the failed deployments.

## Releasing a New Version

See [release/openshift.md.](../../release/openshift.md)
