# CMake initial cache file for Perlmutter using nvidia compiler

SET(HOMMEXX_EXEC_SPACE CUDA CACHE STRING "")
#SET(HOMMEXX_MPI_ON_DEVICE FALSE CACHE BOOL "")
#SET(HOMMEXX_CUDA_MAX_WARP_PER_TEAM "16" CACHE STRING  "")
set(HOMMEXX_VECTOR_SIZE 1 CACHE STRING "")

# cray-hdf5-parallel/1.12.0.6  cray-netcdf-hdf5parallel/4.7.4.6 cray-parallel-netcdf/1.12.1.6
SET(NETCDF_DIR $ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX} CACHE FILEPATH "")
SET(PNETCDF_DIR $ENV{CRAY_PARALLEL_NETCDF_DIR} CACHE FILEPATH "")
SET(HDF5_DIR $ENV{CRAY_HDF5_PARALLEL_PREFIX} CACHE FILEPATH "")

#for scorpio
SET (NetCDF_C_PATH $ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX} CACHE FILEPATH "")
SET (NetCDF_Fortran_PATH $ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX} CACHE FILEPATH "")

SET(BUILD_HOMME_WITHOUT_PIOLIBRARY TRUE CACHE BOOL "")

SET(HOMME_FIND_BLASLAPACK TRUE CACHE BOOL "")
#CRAY_LIBSCI_PREFIX_DIR=/opt/cray/pe/libsci/21.08.1.2/NVIDIA/20.7/x86_64

SET(WITH_PNETCDF FALSE CACHE FILEPATH "")

SET(USE_QUEUING FALSE CACHE BOOL "")

SET(BUILD_HOMME_THETA_KOKKOS TRUE CACHE BOOL "")
#SET(HOMME_ENABLE_COMPOSE FALSE CACHE BOOL "")

#SET(HOMMEXX_BFB_TESTING TRUE CACHE BOOL "")

SET(USE_TRILINOS OFF CACHE BOOL "")

SET(Kokkos_ENABLE_OPENMP OFF CACHE BOOL "")
SET(Kokkos_ENABLE_CUDA ON CACHE BOOL "")
SET(Kokkos_ENABLE_CUDA_LAMBDA ON CACHE BOOL "")
SET(Kokkos_ARCH_AMPERE80 ON CACHE BOOL "")
#SET(Kokkos_ARCH_ZEN2 ON CACHE BOOL "")
#SET(Kokkos_ENABLE_CUDA_UVM ON CACHE BOOL "")
SET(Kokkos_ENABLE_EXPLICIT_INSTANTIATION OFF CACHE BOOL "")
#SET(Kokkos_ENABLE_CUDA_ARCH_LINKING OFF CACHE BOOL "") # need this to get around link error with fortran (-arch=sm_80)

#SET(CMAKE_C_COMPILER "mpicc" CACHE STRING "")
#SET(CMAKE_Fortran_COMPILER "mpifort" CACHE STRING "")
#SET(CMAKE_CXX_COMPILER "mpicxx" CACHE STRING "")
SET(CMAKE_C_COMPILER "cc" CACHE STRING "")
SET(CMAKE_Fortran_COMPILER "ftn" CACHE STRING "")
SET(CMAKE_CXX_COMPILER "CC" CACHE STRING "")
# Note: need to set OMPI_CXX env variable and perhaps NVCC_WRAPPER_DEFAULT_COMPILER

SET(CXXLIB_SUPPORTED_CACHE FALSE CACHE BOOL "")

SET(ENABLE_OPENMP OFF CACHE BOOL "")
SET(ENABLE_COLUMN_OPENMP OFF CACHE BOOL "")
SET(ENABLE_HORIZ_OPENMP OFF CACHE BOOL "")

SET(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "")

#SET(HOMME_TESTING_PROFILE "dev" CACHE STRING "")

SET(USE_NUM_PROCS 4 CACHE STRING "")

SET(USE_MPIEXEC "srun" CACHE STRING "")
SET(CPRNC_DIR /global/cfs/cdirs/e3sm/tools/cprnc CACHE FILEPATH "")
