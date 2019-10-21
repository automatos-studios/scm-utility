#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh scm_changelist_details [OPTIONS] <changelist_unique_name>"
   echo "e.g. >> sh scm_changelist_details -v AS_000111"
   echo "[OPTIONS]:"
   echo -e "\t-v : print verbose changelist details"
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


REPO_NAME=$(basename $PWD)
CHANGELIST_NAME="$1"
SCM_ITEM="$2"
CHANGELIST_FILE_PATH="${CHANGELIST_NAME}/data.changelist"
SHELVED_FOLDER_PATH="${CHANGELIST_NAME}/shelved_files"
LATEST_SHELVED_FOLDER_PATH="${SHELVED_FOLDER_PATH}/data.shelve"


if [ -e $CHANGELIST_FILE_PATH ]; then
  echo ""
  echo "-------------------------------------------------"
  echo ""
  echo "changelist [ $CHANGELIST_NAME ] items:"
  echo ""
  cat $CHANGELIST_FILE_PATH | nl 
  echo ""
  echo "changelist [ $CHANGELIST_NAME ] shelved items details:"
  echo ""
  ls -lR $LATEST_SHELVED_FOLDER_PATH | nl
  echo ""
  echo "repository [ $REPO_NAME ] checkout items details:"
  echo ""
  eval $scm_cmd_impl_list_ckeckouts | nl
  echo ""
  echo "-------------------------------------------------"
else
  echo "ERROR : changelist [" $CHANGELIST_NAME "] is not initialized."
fi

