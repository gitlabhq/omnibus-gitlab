#!/bin/bash
# Order of priority:
## PACKAGECLOUD_REPO is defined, forward everything to that repository. This is a full override.
## RASPBERRY_REPO is defined, forward to raspberry-pi2 repository
## NIGHTLY_REPO is defined, forward to nightly-builds repository
## No repo defined, select based on git describe. Unstable, gitlab-ee or gitlab-ce
if [ -z ${PACKAGECLOUD_REPO+x} ]; then
  if [ -z ${RASPBERRY_REPO+x} ]; then
    if [ -z ${NIGHTLY_REPO+x} ]; then
      if git describe | grep -q -e rc ; then
        echo unstable;
      elif support/is_gitlab_ee.sh ; then
        echo gitlab-ee;
      else
        echo gitlab-ce;
      fi
    else
      echo $NIGHTLY_REPO;
    fi
  else
    echo $RASPBERRY_REPO;
  fi
else
  echo $PACKAGECLOUD_REPO;
fi
