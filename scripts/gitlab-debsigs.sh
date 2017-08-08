#!/bin/bash
#   gitlab-debsigs: Scripted configuration of `debsigs` for GitLab packages
#   Usage: gitlab-debsigs KEYFILE
#   This script will configure the policy and keyring for GitLab packages to be
#   checked by the `debsig-verify` program.

KEYRINGS=/usr/share/debsig/keyrings
POLICIES=/etc/debsig/policies
PROTOCOL=https
KEYFILE=$1

# checkInputs
# Verify the input (`$1`) is provided, a file, and understood by GnuPG
function checkInputs() {
    if [ -z "$KEYFILE" -o ! -f $KEYFILE ]; then
        echo "Please provide the key file as the argument to this script."
        exit 1
    else
        echo "Supplied key file: $KEYFILE"
    fi

    echo "Checking key file validity with GnuPG ..."
    gpg --no-options --no-default-keyring --batch \
        --no-secmem-warning --no-permission-warning \
        $KEYFILE 2>/dev/null 1>/dev/null
    gpg=$?
    if [ $gpg -ne 0 ]; then
        echo "Provided key does not appear valid according to GnuPG. Please confirm '$KEYFILE' is correct."
        exit 1
    fi
}

# fetchProgramInfo
# Detect `debsig-verify` version and configured directories. Handle quirks of DTD
function fetchProgramInfo() {
    # detect version of debsig-verify, as any version > 0.15 uses HTTPS in the DTD
    version=`debsig-verify --version 2>&1 | grep 'Debsig Program' | cut -d '-' -f 2`
    versionMajor=`echo $version | cut -d '.' -f 1`
    versionMinor=`echo $version | cut -d '.' -f 2`
    echo "debsig-verify - version: $versionMajor,$versionMinor"
    if [ $versionMajor -eq 0 -a $versionMinor -lt 15 ]; then
        PROTOCOL=http
    fi
    echo "debsig-verify - DTD Protocol: $PROTOCOL"

    # check the configuration values for paths
    policies=`debsig-verify --version 2>&1 | grep 'Policies Directory' | cut -d '-' -f 2`
    POLICIES=`echo $policies`
    echo "debsig-verify - Polcies: $POLICIES"

    keyrings=`debsig-verify --version 2>&1 | grep 'Keyrings Directory' | cut -d '-' -f 2`
    KEYRINGS=`echo $keyrings`
    echo "debsig-verify - Keyrings: $KEYRINGS"
}

checkInputs
fetchProgramInfo

# find the key id
KEYID=$(gpg --no-options --no-permission-warning --no-default-keyring --list-packets $KEYFILE | grep -A2 'user ID packet' | grep signature)
KEYID=${KEYID/*keyid /}
echo "Found KeyID: $KEYID"

# import the key into the keyring
mkdir -p "$KEYRINGS/$KEYID"
gpg --no-default-keyring --batch --no-permission-warning --no-options \
    --keyring "$KEYRINGS/$KEYID/gitlab.gpg" \
    --import $KEYFILE

# create the policies based on the key id
mkdir -p "$POLICIES/$KEYID"
cat <<EOB > "$POLICIES/$KEYID/gitlab.pol"
<?xml version="1.0"?>
<!DOCTYPE Policy SYSTEM "https://www.debian.org/debsig/1.0/policy.dtd">
<Policy xmlns="$PROTOCOL://www.debian.org/debsig/1.0/">

  <Origin Name="GitLab, Inc." id="$KEYID" Description="GitLab"/>

  <Selection>
    <Required Type="origin" File="gitlab.gpg" id="$KEYID"/>
  </Selection>

  <Verification MinOptional="0">
    <Required Type="origin" File="gitlab.gpg" id="$KEYID"/>
  </Verification>

</Policy>
EOB
