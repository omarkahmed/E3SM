#!/bin/bash
module purge
module load intel-nightly
module load intel/mkl-nda/nightly-20220526
module load intel/mpi/2021.5.0
module load intel-comp-rt/agama-ci-prerelease/449
module load cmake/3.22.1

unset CFLAGS
unset CXXFLAGS
unset YAKL_ARCH
unset YAKL_CXX_FLAGS
unset YAKL_C_FLAGS
unset YAKL_SYCL_FLAGS
unset CC
unset CXX
unset FC
unset YAKL_HOME

export PATH=${HOME}/e3sm-libs/oneapi-ifort/packages/netcdf-serial/bin:$PATH

export LD_LIBRARY_PATH=~/e3sm-libs/oneapi-ifort/packages/hdf5-serial/lib:$LD_LIBRARY_PATH

export YAKL_ARCH="SYCL"
export YAKL_SYCL_FLAGS="-fsycl -fsycl-targets=spir64 -gline-tables-only -fdebug-info-for-profiling"

export NCHOME="${HOME}/e3sm-libs/oneapi-ifort/packages/netcdf-serial"
export NFHOME="${HOME}/e3sm-libs/oneapi-ifort/packages/netcdf-serial"

export FFLAGS="-I${NCHOME}/include -fiopenmp -fopenmp-targets=spir64"


export CC=icx
export CXX=icpx
export FC=ifx
export YAKL_HOME="`pwd`/../../../../../../../../externals/YAKL"
