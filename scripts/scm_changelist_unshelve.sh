#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh scm_changelist_unshelve [OPTIONS] <changelist_unique_name>"
   echo "e.g. >> sh scm_changelist_unshelve -v AS_000111"
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

command -v compare >/dev/null 2>&1 || { echo >&2 "\"compare\" command is not found. Aborting."; return; }

REPO_NAME=$(basename $PWD)
CHANGELIST_NAME="$1"
CHANGELIST_FILE_PATH="${CHANGELIST_NAME}/data.changelist"
SHELVED_FOLDER_PATH="${CHANGELIST_NAME}/shelved_files"
LATEST_SHELVED_FOLDER_PATH="${SHELVED_FOLDER_PATH}/data.shelve"
MERGE_TEMP_FOLDER="${SHELVED_FOLDER_PATH}/merge.temp"

MSG_SUCCESS=""
MSG_FAILED=""
CONFLICT_ITEMS_LIST_FILE_PATH="${MERGE_TEMP_FOLDER}/merge.conflict"
rm -rf $MERGE_TEMP_FOLDER
mkdir -p -m a=wrx $MERGE_TEMP_FOLDER
touch $CONFLICT_ITEMS_LIST_FILE_PATH
chmod a=rw $CONFLICT_ITEMS_LIST_FILE_PATH
> $CONFLICT_ITEMS_LIST_FILE_PATH


if [[ -e $CHANGELIST_FILE_PATH ]]; then
  if [[ -e $LATEST_SHELVED_FOLDER_PATH ]]; then
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
        MSG_SUCCESS="${MSG_SUCCESS}\n[SUCCESS] SHELVED ITEM FOUND AT ${SCM_ITEM_SHELVE_PATH}"
        if [[ $SCM_ITEM_OPS == "MODIFY" ]]; then          
          SCM_ITEM_SHELVE_PARENT_PATH="${SCM_ITEM_SHELVE_PATH}.parent";
          SCM_ITEM_COMMON_ANCESTOR_PATH="${MERGE_TEMP_FOLDER}/${SCM_ITEM_NAME}.ancestor"
          SCM_ITEM_THEIRS="${MERGE_TEMP_FOLDER}/${SCM_ITEM_NAME}.theirs"
          SCM_ITEM_MINE="${MERGE_TEMP_FOLDER}/${SCM_ITEM_NAME}.mine"
          cp -a --backup=numbered -T $SCM_ITEM_SHELVE_PARENT_PATH $SCM_ITEM_COMMON_ANCESTOR_PATH
          cp -a --backup=numbered -T $SCM_ITEM $SCM_ITEM_THEIRS
          cp -a --backup=numbered -T $SCM_ITEM_SHELVE_PATH $SCM_ITEM_MINE
          eval $scm_cmd_impl_private_checkout $SCM_ITEM
          # step 01: transfer ancestor content to ws-scm-item, now ws-scm-item is the common ancestor
          # cp -a --backup=numbered -T $SCM_ITEM_COMMON_ANCESTOR_PATH $SCM_ITEM
          cp -a -T $SCM_ITEM_COMMON_ANCESTOR_PATH $SCM_ITEM
          # step 02: do 3-way merge with ws-scm-item as ancestor, so that merge result is saved to the ws-scm-item.
          compare /testconflicts /nowait /merge /a1 /3 $SCM_ITEM $SCM_ITEM_THEIRS $SCM_ITEM_MINE
          if [[ $? -gt 0 ]]; then
            echo $SCM_ITEM >> $CONFLICT_ITEMS_LIST_FILE_PATH
            compare /wait /merge /max /a1 /3 $SCM_ITEM $SCM_ITEM_THEIRS $SCM_ITEM_MINE &
          else
            compare /wait /merge /max /a1 /3 $SCM_ITEM $SCM_ITEM_THEIRS $SCM_ITEM_MINE &
          fi
        elif [[ $SCM_ITEM_OPS == "CREATE" ]]; then
          mkdir -p $(dirname $SCM_ITEM)
          cp -a --backup=numbered -T $SCM_ITEM_SHELVE_PATH $SCM_ITEM
        elif [[ $SCM_ITEM_OPS == "REPLACE" ]]; then
          eval $scm_cmd_impl_private_checkout $SCM_ITEM
          cp -a -T $SCM_ITEM_SHELVE_PATH $SCM_ITEM
        fi
      else
        MSG_FAILED="${MSG_FAILED}\n[FAILED] NO SHELVED ITEM FOUND FOR ${SCM_ITEM}"
      fi
    done < "$CHANGELIST_FILE_PATH"
  else
    echo "[FAILED] no shelved folder exists for changelist ${CHANGELIST_NAME}"
  fi
  
  echo "changelist [ ${CHANGELIST_NAME} ] unshelve status:"
  echo -e $MSG_SUCCESS | nl
  echo -e $MSG_FAILED | nl
  
  if [[ ! -z $verbose ]]; then
    scm_changelist_details $CHANGELIST_NAME
  fi
else
  echo $CHANGELIST_NAME "is not initialized in" $REPO_NAME
fi

