#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh scm_item_add [OPTIONS] <changelist_unique_name> <scm_item>"
   echo "e.g. >> sh scm_item_add -v AS_000111 src\repo\datamanager\manager.h"
   echo "[OPTIONS]:"
   echo -e "\t-v : print verbose changelist details at the end"
   echo -e "\t-h : print help message"
   exit 1
}
###################################################################################

while getopts ":vh" opt; do
  case "$opt" in
    v ) verbose="on" ;;
    h ) helpMessage ;;
    ? ) helpMessage ;;
  esac
done

. $(dirname "$BASH_SOURCE")/scm_cmd_mappings.sh

CHANGELIST_NAME="$1"
SCM_ITEM="$2"
SCM_ITEM=${SCM_ITEM/\\/\/}
CHANGELIST_FILE_PATH="${CHANGELIST_NAME}/data.changelist"

if [[ -e $CHANGELIST_FILE_PATH ]]; then
  if grep -Fq "$SCM_ITEM" $CHANGELIST_FILE_PATH; then
    echo "WARNING : changelist [ $CHANGELIST_NAME ] already has item [ $SCM_ITEM ]"
  else
    eval $scm_cmd_impl_private_add $SCM_ITEM
    echo "[CREATE] " $SCM_ITEM >> $CHANGELIST_FILE_PATH
  fi
  if [[ ! -z "$verbose" ]]; then
    scm_changelist_details $CHANGELIST_NAME
  fi
else
  echo "ERROR : changelist [ $CHANGELIST_NAME ] is not initialized."
fi

