#!/bin/bash
if git describe | grep -q -e rc ; then
  echo unstable;
elif support/is_gitlab_ee.sh ; then
  echo gitlab-ee;
else
  echo gitlab-ce;
fi
