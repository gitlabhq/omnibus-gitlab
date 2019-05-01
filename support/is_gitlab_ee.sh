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
  echo "$CI_COMMIT_TAG" | grep -q -P -- '^\d+\.\d+\.\d+\+[^ ]{7,}\.[^ ]{7,}$'
}

function is_auto_deploy_branch(){
  echo "$CI_COMMIT_REF_NAME" | grep -q -- '-auto-deploy-'
}

ee_env_var || ee_branch_var || ee_branch_name || is_auto_deploy_tag || is_auto_deploy_branch
