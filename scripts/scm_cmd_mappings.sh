#!/usr/bin/env bash

## PARENT REPOSITORY INFO
REPO_NAME=$(basename $PWD)
declare -A scm_parent_repo_map
scm_parent_repo_map["TEST_scm_repo"]="data"

export PARENT_REPO_NAME=${scm_parent_repo_map[$REPO_NAME]}

if [[ -z $scm_parent_repo_host_overloaded ]]; then
  scm_parent_repo_host=""
fi

## SCM IMPL COMMANDS
if [[ -z $scm_cmd_impl_list_ckeckouts_overloaded ]]; then
  scm_cmd_impl_list_ckeckouts="echo \"WARNING : scm_cmd_impl_list_ckeckouts NOT-IMPLEMENTED\""
fi

if [[ -z $scm_cmd_impl_private_add_overloaded ]]; then
  scm_cmd_impl_private_add="echo \"WARNING : scm_cmd_impl_private_add NOT-IMPLEMENTED\""
fi

if [[ -z $scm_cmd_impl_private_checkout_overloaded ]]; then
  scm_cmd_impl_private_checkout="echo \"WARNING : scm_cmd_impl_private_checkout NOT-IMPLEMENTED\""
fi

if [[ -z $scm_cmd_impl_private_uncheckout_overloaded ]]; then
  scm_cmd_impl_private_uncheckout="echo \"WARNING : scm_cmd_impl_private_uncheckout NOT-IMPLEMENTED\""
fi
