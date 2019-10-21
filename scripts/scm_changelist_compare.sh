#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh scm_changelist_compare [OPTIONS] <changelist_unique_name>"
   echo "e.g. >> sh scm_changelist_compare -v AS_000111"
   echo "[OPTIONS]:"
   echo -e "\t-v : print verbose changelist details at the end"
   echo -e "\t-h : print help message"
   exit 0
}
###################################################################################

while getopts ":vhe" opt; do
  case "$opt" in
    v ) verbose="on" ;;
    e ) edit="on" ;;
    h ) helpMessage ;;
    ? ) helpMessage ;;
  esac
done

. $(dirname "$BASH_SOURCE")/scm_cmd_mappings.sh

command -v compare >/dev/null 2>&1 || { echo >&2 "\"compare\" command is not found. Aborting."; return; }

REPO_NAME=$(basename $PWD)
CHANGELIST_NAME="$1"
CHANGELIST_FILE_PATH="${CHANGELIST_NAME}/data.changelist"

PARENT_REPO_HOST="$scm_parent_repo_host"
PARENT_REPO_PATH="${PARENT_REPO_HOST}/${PARENT_REPO_NAME}"

echo PARENT_REPO_NAME $PARENT_REPO_NAME

if [[ -e $CHANGELIST_FILE_PATH ]]; then
  while IFS= read -r line; do
    SCM_ITEM_PARENT=""
    if [[ $line == *"[MODIFY]"* ]]; then
      SCM_ITEM=${line#"[MODIFY]"}
      SCM_ITEM=$(echo "$SCM_ITEM" | xargs echo)
      SCM_ITEM_PARENT="${PARENT_REPO_PATH}/${SCM_ITEM}"
    elif [[ $line == *"[CREATE]"* ]]; then
      SCM_ITEM=${line#"[CREATE]"}
      SCM_ITEM=$(echo "$SCM_ITEM" | xargs echo)
      SCM_ITEM_PARENT="${SCM_ITEM}"
    elif [[ $line == *"[REPLACE]"* ]]; then
      SCM_ITEM=${line#"[REPLACE]"}
      SCM_ITEM=$(echo "$SCM_ITEM" | xargs echo)
    fi
    
    SCM_ITEM_FILENAME=$(basename -- "$SCM_ITEM")
    SCM_ITEM_FILEEXTENSION="${SCM_ITEM_FILENAME##*.}"
    if [[ $SCM_ITEM_FILEEXTENSION =~ zip|ver|rec|env ]]; then
      SCM_ITEM_PARENT=""
    fi
    
    if [[ -n $SCM_ITEM ]] && [[ -n $SCM_ITEM_PARENT ]]; then
      echo "comparing -> ${SCM_ITEM}   :   ${SCM_ITEM_PARENT}"
      if [[ -n $edit ]]; then
        compare /wait /max /2 $SCM_ITEM_PARENT $SCM_ITEM &
      else
        compare /wait /max /2 /readonly $SCM_ITEM_PARENT $SCM_ITEM &
      fi
    fi
    
  done < "$CHANGELIST_FILE_PATH"
  
  if [[ ! -z $verbose ]]; then
    scm_changelist_details $CHANGELIST_NAME
  fi
else
  echo $CHANGELIST_NAME "is not initialized in" $REPO_NAME
fi

