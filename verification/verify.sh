#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

comp_script=${SCRIPT_DIR}/nccmp.py

source_dir=F2010-MMF2_sunspot_spr_mpich_ne4pg2_ne4pg2_oneapi-ifx_104x1.01
target_dir=F2010-MMF2_sunspot_spr_mpich_ne4pg2_ne4pg2_oneapi-ifx_104x1.02
export build_directory=${PWD}
export library_directory=${LIBHOME}

if [[ $1 == '-h' || $1 == '--help' || $1 == '-help' ]]; then
    echo "Run as follows:"
    echo "./run.sh [options]"
    echo
    echo "    -s <source directory for comparison>"
    echo "        root directory of run for source output (default: ${source_dir})"
    echo
    echo "    -t <target directory for comparison>"
    echo "        root directory of run for target output (default: ${target_dir})"
    echo
    echo
    exit 0
fi

# fetch input arguments, if any
while getopts "s:t:" flag
do
    case "${flag}" in
        s) source_dir=${OPTARG};;
	t) target_directory=${OPTARG};;
    esac
done

python_venv_dir=${SCRIPT_DIR}/e3sm-venv
if [[ -f ${python_venv} ]]; then
  echo "sourcing ${python_venv}"
  source ${python_venv}
else
  export HTTP_PROXY=http://proxy.alcf.anl.gov:3128

  export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128

  export http_proxy=http://proxy.alcf.anl.gov:3128

  export https_proxy=http://proxy.alcf.anl.gov:3128
  echo "python3 -m venv ${SCIRPT_base}/e3sm-venv"
  python3 -m venv e3sm-venv
  source ${python_venv}/bin/activate
  pip3 install netCDF4
fi

file_suffix=eam.r.0001-01-02-00000.nc

source_base_name=$(basename ${source_directory})
source_file=${source_directory}/${case}/run/${source_base_name}.${file_suffix}
target_base_name=$(basename ${target_directory})
target_file=${target_directory}/${case}/run/${target_base_name}.${file_suffix}

${comp_script} -s ${source_file} -t ${target_file}
