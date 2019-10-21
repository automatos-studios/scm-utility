#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh scm_changelist_init [OPTIONS] <changelist_unique_name>"
   echo "e.g. >> sh scm_changelist_init -v AS_000111"
   echo "[OPTIONS]:"
   echo -e "\t-v : print verbose changelist details at the end"
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

REPO_NAME=$(basename $PWD);
CHANGELIST_NAME="$1";
CHANGELIST_FILE_PATH="${CHANGELIST_NAME}/data.changelist";

mkdir -p -v -m a=rwx $CHANGELIST_NAME
touch $CHANGELIST_FILE_PATH
chmod a=rw $CHANGELIST_FILE_PATH

if [[ -e $CHANGELIST_FILE_PATH ]]; then
  echo $CHANGELIST_NAME "initialization successful in" $REPO_NAME
  if [[ ! -z "$verbose" ]]; then
    scm_changelist_details $CHANGELIST_NAME
  fi
else
  echo $CHANGELIST_NAME "initialization !!failed!! in" $REPO_NAME
fi

