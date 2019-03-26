#!/bin/bash
function ee_env_var()
{
  [[ "${ee}" == "true" ]]
}

function ee_branch_var(){
  [[ -n "${GITLAB_VERSION}" ]] && [[ "${GITLAB_VERSION}" == *-ee ]]
}

function  ee_branch_name(){
  grep -q -E "\-ee" VERSION
}

ee_env_var || ee_branch_var || ee_branch_name
