#!/bin/bash

source ./intel.sh

module load intel-comp-rt/feature/impl-scaling-off

ntasks=1
if [[ ! "$1" == "" ]]; then
  ntasks=$1
fi

#printf "\nRebuilding\n\n"

#make -j8 || exit -1

################################################################################
################################################################################

printf "\n\nRunning 2-D tests\n\n"

printf "\nRunning Fortran code\n\n"
#cd fortran2d
#rm -f fortran_output_000001.nc
#./fortran2d || exit -1
#cd ..

printf "\nRunning C++ code\n\n"
cd cpp2d
rm -f cpp_output_000001.nc
ZE_AFFINITY_MASK=0.0 ./cpp2d || exit -1
cd ..

#printf "\nComparing results\n\n"
#python3 nccmp.py fortran2d/fortran_output_000001.nc cpp2d/cpp_output_000001.nc || exit -1

################################################################################
################################################################################

printf "\n\nRunning 3-D tests\n\n"

#printf "\nRunning Fortran code\n\n"
#cd fortran3d
#rm -f fortran_output_000001.nc
#./fortran3d || exit -1
#cd ..

#printf "\nRunning C++ code\n\n"
#cd cpp3d
#rm -f cpp_output_000001.nc
#./cpp3d || exit -1
#cd ..

#printf "\nComparing results\n\n"
#python3 nccmp.py fortran3d/fortran_output_000001.nc cpp3d/cpp_output_000001.nc || exit -1

################################################################################
################################################################################
