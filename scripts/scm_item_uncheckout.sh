#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh scm_item_uncheckout [OPTIONS] <changelist_unique_name> <scm_item>"
   echo "e.g. >> sh scm_item_uncheckout -v AS_000111 src\repo\datamanager\manager.h"
   echo "[OPTIONS]:"
   echo -e "\t-v : print verbose changelist details"
   echo -e "\t-h : print help message"
   exit 0
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


CHANGELIST_NAME="$1";
SCM_ITEM="$2";
CHANGELIST_FILE_PATH="${CHANGELIST_NAME}/data.changelist";

if [ -e $CHANGELIST_FILE_PATH ]; then
  if grep -Fq "$SCM_ITEM" $CHANGELIST_FILE_PATH; then
    eval $scm_cmd_impl_private_uncheckout $SCM_ITEM
    SCM_ITEM_PATTERN=${SCM_ITEM//\//\\\/}
    sed -i "/$SCM_ITEM_PATTERN/d" $CHANGELIST_FILE_PATH
  else
    echo "ERROR : changelist [ $CHANGELIST_NAME ] does not contain item" $SCM_ITEM
  fi
else
  echo "ERROR : changelist [ $CHANGELIST_NAME ] is not initialized."
fi
