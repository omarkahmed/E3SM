string(APPEND SLIBS " -L$ENV{PNETCDF_PATH}/lib -lpnetcdf -L$ENV{CRAY_LIBSCI_PREFIX_DIR}/lib -lsci_amd")
set(PNETCDF_PATH "$ENV{PNETCDF_DIR}")
set(CRAY_LIBSCI_PREFIX_DIR "$ENV{CRAY_LIBSCI_PREFIX_DIR}")
set(PIO_FILESYSTEM_HINTS "gpfs")
#if (COMP_NAME STREQUAL gptl)
#  string(APPEND CPPDEFS " -DFORTRANUNDERSCORE")
#endif()
set(USE_HIP "TRUE")
string(APPEND HIP_FLAGS "-munsafe-fp-atomics -D__HIP_ROCclr__ -D__HIP_ARCH_GFX90A__=1 --rocm-path=$ENV{ROCM_PATH} --offload-arch=gfx90a -x hip")
