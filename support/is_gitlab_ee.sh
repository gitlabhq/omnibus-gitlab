#!/bin/bash
function ee_env_var()
{
  [[ "${ee}" == "true" ]]
}

function ee_branch_var(){
  [[ -n "${GITLAB_VERSION}" ]] && [[ "${GITLAB_VERSION}" == *-ee ]]
}

function ee_branch_name(){
  grep -q -E "\-ee" VERSION
}

function is_auto_deploy_tag(){
  echo "$CI_COMMIT_TAG" | grep -q -E '^\d+\.\d+\.[^ ]+\+[^ ]+$'
}

function is_auto_deploy_branch(){
  echo "$CI_COMMIT_TAG" | grep -q -E '^\d+\.\d+\.[^ ]+\+[^ ]+$'
}
echo "commit tag: $CI_COMMIT_TAG"
echo "commit ref: $CI_COMMIT_REF_NAME"

ee_env_var || ee_branch_var || ee_branch_name || is_auto_deploy
