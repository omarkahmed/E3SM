#!/bin/bash

module load oneapi/eng-compiler/2023.10.15.002 cray-python/3.9.13.1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

comp_script=${SCRIPT_DIR}/nccmp.py

source_dir=F2010-MMF2_sunspot_spr_mpich_ne4pg2_ne4pg2_oneapi-ifx_104x1.01
target_dir=F2010-MMF2_sunspot_spr_mpich_ne4pg2_ne4pg2_oneapi-ifx_104x1.02
export build_directory=${PWD}
export library_directory=${LIBHOME}

export HDF5_DIR=/lus/gila/projects/CSC249ADSE15_CNDA/software/oneAPI.2022.12.30.003/hdf5
export NETCDF4_DIR=/lus/gila/projects/CSC249ADSE15_CNDA/software/oneAPI.2022.12.30.003/netcdf-4.9.1
export PATH=${HDF5_DIR}/bin:${NETCDF4_DIR}/bin:${PATH}
export LD_LIBRARY_PATH=${HDF5_DIR}/lib:${NETCDF4_DIR}/lib:${LD_LIBRARY_PATH}

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
	t) target_dir=${OPTARG};;
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
  echo "python3 -m venv ${python_venv_dir}"
  python3 -m venv ${python_venv_dir}
  source ${python_venv_dir}/bin/activate
  pip3 install netCDF4
fi

file_suffix=eam.r.0001-01-02-00000.nc

source_base_name=$(basename ${source_dir})
source_file=${source_dir}/${case}/run/${source_base_name}.${file_suffix}
target_base_name=$(basename ${target_dir})
target_file=${target_dir}/${case}/run/${target_base_name}.${file_suffix}

run_cmd="${comp_script} -s ${source_file} -t ${target_file}"
echo ${run_cmd}
${run_cmd}

#ncdump ${source_file} &> source-dump.log
