string(APPEND CPPDEFS " -DNO_SHR_VMATH -DCNL")
if (DEBUG)
  string(APPEND FFLAGS " -check all -ftrapuv")
endif()
string(APPEND SLIBS " -llapack -lblas -qmkl")
string(APPEND LDFLAGS " -L/usr/tce/packages/mkl/mkl-2022.1.0/lib/intel64/")
set(KOKKOS_OPTIONS "--with-serial --ldflags='-L/usr/tce/packages/mkl/mkl-2022.1.0/lib/intel64/'")
set(MPI_LIB_NAME "mpich")
set(MPI_PATH "/usr/tce/packages/mvapich2/mvapich2-2.3.7-intel-classic-2021.6.0/")
set(NETCDF_PATH "$ENV{NETCDFROOT}")
set(PNETCDF_PATH "$ENV{PNETCDFROOT}")
execute_process(COMMAND  /usr/tce/packages/netcdf-fortran/netcdf-fortran-4.6.0-mvapich2-2.3.7-intel-classic-2021.6.0/bin/nf-config --flibs OUTPUT_VARIABLE SHELL_CMD_OUTPUT_BUILD_INTERNAL_IGNORE0 OUTPUT_STRIP_TRAILING_WHITESPACE)
string(APPEND SLIBS " ${SHELL_CMD_OUTPUT_BUILD_INTERNAL_IGNORE0}")
