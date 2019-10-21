#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh scm_changelist_remove [OPTIONS] <changelist_unique_name>"
   echo "e.g. >> sh scm_changelist_remove -v AS_000111"
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

REPO_NAME=$(dirname $PWD)
CHANGELIST_NAME="$1"
CHANGELIST_FILE_PATH="${CHANGELIST_NAME}/data.changelist"
SHELVED_FOLDER_PATH="${CHANGELIST_NAME}/shelved_files"
LATEST_SHELVED_FOLDER_PATH="${SHELVED_FOLDER_PATH}/data.shelve"

MSG_SUCCESS=""
MSG_FAILED=""

if [ -e $CHANGELIST_FILE_PATH ]; then
  sh scm_changelist_shelve $CHANGELIST_NAME
  if [ -e $LATEST_SHELVED_FOLDER_PATH ]; then
    while IFS= read -r line; do
      SCM_ITEM_OPS=""
      if [[ $line == *"[MODIFY]"* ]]; then
        SCM_ITEM=${line#"[MODIFY]"}
        SCM_ITEM_OPS="MODIFY"
      elif [[ $line == *"[CREATE]"* ]]; then
        SCM_ITEM=${line#"[CREATE]"}
        SCM_ITEM_OPS="CREATE"
      elif [[ $line == *"[REPLACE]"* ]]; then
        SCM_ITEM=${line#"[REPLACE]"}
        SCM_ITEM_OPS="REPLACE"
      fi
      SCM_ITEM=$(echo "$SCM_ITEM" | xargs echo)
      SCM_ITEM_NAME=$(basename $SCM_ITEM);
      SCM_ITEM_SHELVE_PATH="${LATEST_SHELVED_FOLDER_PATH}/${SCM_ITEM_NAME}";
      if [ -e $SCM_ITEM_SHELVE_PATH ]; then
        SHELVE_MODIFICATION_TIME=$(date -r $SCM_ITEM_SHELVE_PATH "+%Y-%m-%d %H:%M:%S")
        MSG_SUCCESS="${MSG_SUCCESS}\n[SHELVED] ON ${SHELVE_MODIFICATION_TIME} ${SCM_ITEM_SHELVE_PATH}"
        if [[ $SCM_ITEM_OPS == "MODIFY" ]]; then          
          SCM_ITEM_PARENT_PATH="${SCM_ITEM_SHELVE_PATH}.parent";
          eval $scm_cmd_impl_private_uncheckout $SCM_ITEM
          cp -a --backup=numbered -T $SCM_ITEM $SCM_ITEM_PARENT_PATH
        elif [[ $SCM_ITEM_OPS == "CREATE" ]]; then
          rm $SCM_ITEM
        elif [[ $SCM_ITEM_OPS == "REPLACE" ]]; then
          eval $scm_cmd_impl_private_uncheckout $SCM_ITEM
        fi
      else
        MSG_FAILED="${MSG_FAILED}\n[FAILED] NOT SHELVED ${SCM_ITEM}"
      fi
    done < "$CHANGELIST_FILE_PATH"
  else
    echo "WARNING : changelist items are not shelved. Shelve before remove or scm_changelist_delete for permanent deletion."
    return
  fi
  echo ""
  echo "changelist [ ${CHANGELIST_NAME} ] shelve and remove status:"
  echo -e $MSG_SUCCESS | nl
  echo -e $MSG_FAILED | nl
  if [ ! -z $verbose ]; then
    scm_changelist_details $CHANGELIST_NAME
  fi
else
  echo $CHANGELIST_NAME "is not initialized in" $REPO_NAME
fi

