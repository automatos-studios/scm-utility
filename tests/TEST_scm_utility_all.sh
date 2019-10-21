#!/usr/bin/env bash

###################################################################################
helpMessage()
{
   echo ""
   echo "usage: sh TEST_scm_utility_all [OPTIONS]"
   echo "e.g. >> sh TEST_scm_utility_all -1"
   echo "[OPTIONS]:"
   echo -e "\t-1 : test one - compare files"
   echo -e "\t-2 : test two - merge files"
   echo -e "\t-h : print help message"
   exit 0
}
###################################################################################


while getopts ":12h" opt; do
  case "$opt" in
    1 ) test_one="on" ;;
    2 ) test_two="on" ;;
    h ) helpMessage ;;
    ? ) helpMessage ;;
  esac
done


echo "-------------------------------------------------"
echo ""
echo RUNNING TEST TEST_scm_utility_all
echo ""
echo "-------------------------------------------------"
echo ""

export BASEDIR=$(dirname "$BASH_SOURCE")
export BASEDIR_WIN=${BASEDIR/\/cygdrive\/d/D\:}
echo BASEDIR_WIN $BASEDIR_WIN
TEST_OUTPUT_DIR="${BASEDIR}/output"

if [[ ! -w $TEST_OUTPUT_DIR ]]; then
  echo "TEST OUTPUT FOLDER NOT AVAILABLE OR DOESN'T HAVE WRITE PERMISSIONS"
  return 0
fi

export TEMP_REPO_DIR="${BASEDIR}/output/TEST_scm_repo"
echo "TEMP_REPO_DIR=" $TEMP_REPO_DIR

rm -rf ${TEMP_REPO_DIR}
mkdir -pv -m a=rwx $TEMP_REPO_DIR
cp -a ${BASEDIR}/data/. ${TEMP_REPO_DIR}/
cd $TEMP_REPO_DIR

. $(dirname $(dirname "$BASH_SOURCE"))/scripts/scm_cmd_mappings.sh


export scm_parent_repo_host="$BASEDIR_WIN"
export scm_parent_repo_host_overloaded="YES"

TEST_private_add() {
  mkdir -p -m a=rwx $(dirname $1)
  touch $1
  chmod a=rw $1
}
export -f TEST_private_add
export scm_cmd_impl_private_add="TEST_private_add"
export scm_cmd_impl_private_add_overloaded="YES"

TEST_private_checkout() {
  chmod a=rw $1
}
export -f TEST_private_checkout
export scm_cmd_impl_private_checkout="TEST_private_checkout"
export scm_cmd_impl_private_checkout_overloaded="YES"

TEST_private_uncheckout() {
  SCM_ITEM_TEMP_WS=$1
  SCM_ITEM_ORIG=${BASEDIR}/data/$1
  cp -a -T $SCM_ITEM_ORIG $SCM_ITEM_TEMP_WS
  chmod a=r $1
}
export -f TEST_private_uncheckout
export scm_cmd_impl_private_uncheckout="TEST_private_uncheckout"
export scm_cmd_impl_private_uncheckout_overloaded="YES"

TEST_ls_checkouts() {
  ls -lR "${TEMP_REPO_DIR}/src"
}
export -f TEST_ls_checkouts
export scm_cmd_impl_list_ckeckouts="TEST_ls_checkouts"
export scm_cmd_impl_list_ckeckouts_overloaded="YES"
 
# RUN TESTS
TEST_CL_NAME="TEST_CHANGELIST"

# TEST 01 : CHANGELIST INITIALIZATION
scm_changelist_init $TEST_CL_NAME

# TEST 02 : ADD ITEMS
scm_item_add $TEST_CL_NAME "src\file_add_1.txt"
scm_item_add $TEST_CL_NAME "src/file_add_2.txt"

# TEST 02 : CHECKOUT ITEM FOR MODIFY
scm_item_checkout $TEST_CL_NAME "src\file1.txt"
scm_item_checkout $TEST_CL_NAME "src/file2.txt"
scm_item_checkout $TEST_CL_NAME "src/file3.txt"

# TEST 03 : CHECKOUT ITEM FOR REPLACE
scm_item_checkout $TEST_CL_NAME "src/dump.zip"

# TEST 04 : UNCHECKOUT ITEM FOR MODIFY
scm_item_uncheckout $TEST_CL_NAME "src/file3.txt"

echo "APPEND_MINE_1" >> "src/file1.txt"
echo "APPEND_MINE_2" >> "src/file1.txt"

# TEST 05 : SHELVE CHANGELIST
scm_changelist_shelve $TEST_CL_NAME

echo "NEW_MINE_1" > "src/file2.txt"
echo "NEW_MINE_2" >> "src/file2.txt"
echo "NEW_MINE_3" >> "src/file2.txt"

scm_changelist_shelve $TEST_CL_NAME

if [[ -n $test_one ]]; then
  # TEST 06 : REMOVE CHANGELIST
  scm_changelist_compare $TEST_CL_NAME

elif [[ -n $test_two ]]; then
  # TEST 06 : REMOVE CHANGELIST
  scm_changelist_remove $TEST_CL_NAME
  
  LINE_RANDOM="APPEND_THEIRS_3_TIMES"
  sed -i "1,3s/^/$LINE_RANDOM \n/" "src/file1.txt"
  
  echo "NEW_THEIRS_1" > "src/file2.txt"
  echo "NEW_THEIRS_2" >> "src/file2.txt"
  
  # TEST 07 : UNSHELVE CHANGELIST
  scm_changelist_unshelve $TEST_CL_NAME

fi

scm_changelist_details $TEST_CL_NAME


