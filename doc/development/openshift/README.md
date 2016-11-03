## Development Setup

### Setup OpenShift Origin

First you need to setup an OpenShift Origin environment. To setup the environment you can use the production installer
on a cloud machine, or use the all-in-one VM on your local machine (uses vagrant and virtualbox).

#### All-in-One VM

Installation instructions for the all-in-one vm can be found at [www.openshift.org/vm/](https://www.openshift.org/vm/).

1. Make sure you have virtualbox and vagrant installed.
   - VirtualBox 5.0 with Vagrant 1.8.4 have been tested working (Vagrant 1.8.5 and 1.8.6 do not)
   - VirtualBox 5.1 requires Vagrant 1.8.7 to work.

2. In a new folder run `vagrant init openshift/origin-all-in-one`

3. Then `vagrant up` to import and start the vm.
   - This will provision the vm with 2 cpu cores and 5Gb of RAM.

4. You can now login to the UI at https://10.2.2.2:8443/console and create a new project

#### Production Installer

You can use OpenShift's Ansible installer to setup OpenShift masters and slaves in Digital Ocean. The docs are here:
https://docs.openshift.org/latest/install_config/install/advanced_install.html and the Ansible playbooks are here: https://github.com/openshift/openshift-ansible

After setting it all up, you will need to make sure you deploy the registry and router mentioned in the `what's next` section: https://docs.openshift.org/latest/install_config/install/advanced_install.html#what-s-next

In order to make the permissions of your install match those on the all-in-one you need to edit the anyuid security context:

 - `oc edit scc anyuid`
 - and add `system:authenticated` OR the service user for your project to the `groups` array


### Add the GitLab template to OpenShift

1. Download and install the OpenShift Origin Client Tools onto your path if you don't already have them.
   - Found here: https://github.com/openshift/origin/releases

2. Add the GitLab template to OpenShift (The next release of the VM includes GitLab, so this may not be required)
   - `oc login https://10.2.2.2:8443` username: `admin` password: `admin` for the all-in-one vm. (different for other installation methods)
   - From the root of your omnibus-gitlab repo, `oc create -f docker/openshift-template.json -n openshift`

### Removing the GitLab template

In case you want to upload a new version of it:

`oc delete template/gitlab-ce -n openshift`

### Known Issues

 There is an issue with the all-in-one VM where it's networking isn't properly setup when OpenShift starts.
 This results in the GitLab app not able to communicate with redis or postgres, and the postgres post-hook fails
 during setup. The current solution is to issue `vagrant ssh` into the box, then `sudo shutdown -r now` and once
 it comes back up you will neeed to deploy the failed deployments.

## Releasing a New Version

See [doc/release/openshift.md.](doc/release/openshift.md)
