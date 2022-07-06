#!/bin/bash
module purge
module use /soft/modulefiles/
module use /soft/restricted/CNDA/modules
module load cmake/3.22.1
#module load oneapi/release/latest
#module load intel/oneapi/release/2022.1.2
module load oneapi/eng-compiler/latest
#module load oneapi/eng-compiler/2022.01.30.007

export YAKL_ARCH="SYCL"
export YAKL_SYCL_FLAGS="-fsycl -fsycl-targets=spir64 -gline-tables-only -fdebug-info-for-profiling"
#export YAKL_SYCL_FLAGS="-fsycl -fsycl-targets=spir64 -g"

export NCHOME="/home/azamat/soft/netcdf/4.4.1c-4.2cxx-4.4.4f/intel19-openmpi2.1.6"
export NFHOME="/home/azamat/soft/netcdf/4.4.1c-4.2cxx-4.4.4f/intel19-openmpi2.1.6"
export PATH=/home/azamat/soft/netcdf/4.4.1c-4.2cxx-4.4.4f/intel19-openmpi2.1.6/bin/:$PATH
export FFLAGS="-I${NCHOME}/include -fiopenmp -fopenmp-targets=spir64"


export CC=icx
export CXX=icpx
export FC=ifx
export YAKL_HOME="`pwd`/../../../../../../../../externals/YAKL"

export LD_LIBRARY_PATH=/home/azamat/soft/netcdf/4.4.1c-4.2cxx-4.4.4f/intel19-openmpi2.1.6/lib:$LD_LIBRARY_PATH
