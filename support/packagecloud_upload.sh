#!/bin/env bash
# packagecloud_upload.sh
# Upload packages to packagecloud after built.
# - We're splitting this out because we need to split off the sl/ol repos per
#   gitlab-omnibus !892 . These will be the same package, just uploaded to all
#   related distribution repositories.

# - We set LC_ALL below because package_cloud is picky about the locale
export LC_ALL='en_US.UTF-8'

if [ $# -ne 3 ]; then
    echo "FAILURE: Invalid number of arguments. Got $#, '$@'"
    exit 1;
fi

PACKAGECLOUD_USER=$1
PACKAGECLOUD_REPO=$2
PACKAGECLOUD_OS=$3

declare -A OS

OS[0]="${PACKAGECLOUD_OS}"
if [[ "${PACKAGECLOUD_OS}" =~ "el/" ]]; then
    OS[1]="${OS[0]/el/scientific}"
    OS[2]="${OS[0]/el/ol}"
fi

for distro in "${OS[@]}" ; do
    location="${PACKAGECLOUD_USER}/${PACKAGECLOUD_REPO}/${distro}"
    # Here we loop on the output of find, in the off chance that we accidentally
    # get more than one file. This _should_ never be the case, but in the off
    # chance that it occurs, we'll output a warning, and then attempt upload anyways
    count=0
    for package in `find pkg -name '*.rpm' -o -name '*.deb'`; do
        count=$(expr $count + 1)
        if [ $count -gt 1 ]; then
            echo "WARNING: multiple packages detected!"
        fi
        echo "Uploading '$package' to packagecloud at '$location'"
        bin/package_cloud push $location $package --url=https://packages.gitlab.com
    done;
done;
