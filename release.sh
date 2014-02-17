#!/bin/bash
PROJECT=gitlab
RELEASE_BUCKET=downloads-packages
RELEASE_BUCKET_REGION=eu-west-1

function error_exit
{
  echo "$0: fatal error: $1" 1>&2
  exit 1
}

git diff --quiet HEAD || error_exit 'uncommited changes'
git describe --exact-match || error_exit 'HEAD is not tagged'
bin/omnibus clean --purge ${PROJECT} || error_exit 'clean failed'
touch build.txt
OMNIBUS_APPEND_TIMESTAMP=0 bin/omnibus build project ${PROJECT} || error_exit 'build failed'
release_package=$(find pkg/ -mnewer build.txt -type f -not -name '*.json')
if [[ -z ${release_package} ]]; then
  error_exit 'Could not find the release package'
fi
aws s3 cp ${release_package} s3://#{RELEASE_BUCKET} --acl public-read --region ${RELEASE_BUCKET_REGION}
