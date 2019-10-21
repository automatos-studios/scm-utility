#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh scm_item_checkout [OPTIONS] <changelist_unique_name> <scm_item>"
   echo "e.g. >> sh scm_item_checkout -v AS_000111 src\repo\datamanager\manager.h"
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


CHANGELIST_NAME="$1"
SCM_ITEM="$2"
SCM_ITEM=${SCM_ITEM/\\/\/}
CHANGELIST_FILE_PATH="${CHANGELIST_NAME}/data.changelist"
SCM_ITEM_FILENAME=$(basename -- "$SCM_ITEM")
SCM_ITEM_FILEEXTENSION="${SCM_ITEM_FILENAME##*.}"

if [ -e $CHANGELIST_FILE_PATH ]; then
  if grep -Fq "$SCM_ITEM" $CHANGELIST_FILE_PATH; then
    echo "WARNING : changelist [" $CHANGELIST_NAME "] already has item" $SCM_ITEM
  elif [[ $SCM_ITEM_FILEEXTENSION =~ zip|ver|rec|env ]]; then
    eval $scm_cmd_impl_private_checkout $SCM_ITEM
    echo "[REPLACE]" $SCM_ITEM >> $CHANGELIST_FILE_PATH
  else
    eval $scm_cmd_impl_private_checkout $SCM_ITEM
    echo "[MODIFY] " $SCM_ITEM >> $CHANGELIST_FILE_PATH
  fi
else
  echo "ERROR : changelist [" $CHANGELIST_NAME "] is not initialized."
fi

