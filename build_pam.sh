#!/bin/bash

REPO_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export HARDWARE=pvc-1t
export PAM=c

if [[ $1 == '-h' || $1 == '--help' || $1 == '-help' ]]; then
  echo "Run as follows:"
  echo "./build.sh [options]"
  echo
  echo
  echo "    -c <icx>"
  echo "        hardware configuration to build for (default: ${HARDWARE})"
  echo
  echo "    -p <a|c>"
  echo "        pam configuration to build for (default: ${PAM})"
  echo
  exit 0
fi

# fetch input arguments, if any
while getopts "c:p:" flag
do
  case "${flag}" in
    c) export HARDWARE=${OPTARG};;
    p) export PAM=${OPTARG};;
  esac
done

PAM_DIR=${REPO_DIR}/components/eam/src/physics/crm/pam/external
CONFIG_DIR=${PAM_DIR}/standalone/machines/ortce

echo "source ${CONFIG_DIR}/${HARDWARE}.sh"
source ${CONFIG_DIR}/${HARDWARE}.sh
module list

echo "######## Building p3_shoc_cxx" 
cd ${PAM_DIR}/standalone/mmf_simplified/build_p3_shoc_cxx
./cmakeclean.sh
./cmakescript.sh
make -j
echo "######## Building p3_shoc_cxx_interface"
cd ${PAM_DIR}/standalone/mmf_simplified/build_p3_shoc_cxx_interface
./cmakeclean.sh
./cmakescript.sh
make -j
echo "######## Building pam"
cd ${PAM_DIR}/standalone/mmf_simplified/build
./cmakeclean.sh
./cmakescript_pam${PAM}.sh
make -j
