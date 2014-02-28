#!/bin/bash
PROJECT=gitlab
RELEASE_BUCKET=downloads-packages
RELEASE_BUCKET_REGION=eu-west-1

function error_exit
{
  echo "$0: fatal error: $1" 1>&2
  exit 1
}

if !(git diff --quiet HEAD); then
  error_exit 'uncommited changes'
fi

if !(git describe --exact-match); then
  error_exit 'HEAD is not tagged'
fi

if !(bin/omnibus clean --purge ${PROJECT}); then
  error_exit 'clean failed'
fi

if !(touch build.txt); then
  error_exit 'failed to mark build start time'
fi

if !(OMNIBUS_APPEND_TIMESTAMP=0 bin/omnibus build project ${PROJECT}); then
  error_exit 'build failed'
fi

release_package=$(find pkg/ -newer build.txt -type f -not -name '*.json')
if [[ -z ${release_package} ]]; then
  error_exit 'could not find the release package'
fi

if (git describe | grep -w ee); then
  release_dir="$(openssl rand -hex 20)"
  if [[ $? -ne 0 ]]; then
    error_exit 'failed to generate release directory name'
  fi
  remote_package_path="s3://${RELEASE_BUCKET}/${release_dir}/${release_package}"
else
  remote_package_path="s3://${RELEASE_BUCKET}/${release_package}"
fi

echo
echo 'Package MD5:'
md5sum ${release_package}

echo
echo 'Starting upload'
if !(aws s3 cp ${release_package} ${remote_package_path} --acl public-read --region ${RELEASE_BUCKET_REGION}); then
  error_exit 'release upload failed'
fi
