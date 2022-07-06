#!/bin/bash


./cmakeclean.sh
source intel-ortce.sh
#./cmakescript.sh crm2d_nx16_ny1_nz58_1024x.nc crm3d_nx8_ny8_nz58_1024x.nc
./cmakescript.sh crmdata_nx32_ny1_nz28_nxrad2_nyrad1.nc  crmdata_nx8_ny8_nz28_nxrad2_nyrad2.nc
cd cpp2d
make clean
make -j 32
cd ../cpp3d
make clean
make -j 32
#cd ../fortran2d
#make clean
#make -j 32
#cd ../fortran3d
#make clean
#make -j 32
