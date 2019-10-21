#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh scm_changelist_shelve [OPTIONS] <changelist_unique_name>"
   echo "e.g. >> sh scm_changelist_shelve -v AS_000111"
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


if [[ -e $CHANGELIST_FILE_PATH ]]; then
  if [[ -e $LATEST_SHELVED_FOLDER_PATH ]]; then
    TIME=$(date "+%Y-%m-%d-%H:%M:%S")
    SHELVE_BACKUP_FOLDER="${LATEST_SHELVED_FOLDER_PATH}.backup.$TIME"
    mkdir -pv -m a=rwx $SHELVE_BACKUP_FOLDER
  else
    mkdir -pv -m a=rwx $SHELVED_FOLDER_PATH
    mkdir -pv -m a=rwx $LATEST_SHELVED_FOLDER_PATH
  fi
  
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
    SCM_ITEM_SHELVE_PATH="${LATEST_SHELVED_FOLDER_PATH}/${SCM_ITEM_NAME}"
    if [[ -e $SCM_ITEM_SHELVE_PATH ]]; then
      mv --backup=numbered -t $SHELVE_BACKUP_FOLDER $SCM_ITEM_SHELVE_PATH
    fi
    cp -a --backup=numbered -t $LATEST_SHELVED_FOLDER_PATH $SCM_ITEM
  done < "$CHANGELIST_FILE_PATH"
  
  if [[ ! -z "$verbose" ]]; then
    scm_changelist_details $CHANGELIST_NAME
  fi
else
  echo $CHANGELIST_NAME "is not initialized in" $REPO_NAME
fi

