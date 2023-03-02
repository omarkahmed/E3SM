###############################################################################
## This assumes you have already run add_subdirectory(${YAKL_HOME} ${YAKL_BIN})
## It also assumes you've enabled CXX and C as languages (and CUDA if used)
###############################################################################

file(GLOB F90_SRC   cpp_interface_mod.F90 fft.F90 params.F90 fftpack5.F90 fftpack5_1d.F90)
file(GLOB CXX_SRC   *.cpp)
file(GLOB SAMXX_SRC ${CXX_SRC} ${F90_SRC})

# samxx will be a static library
add_library(samxx STATIC ${SAMXX_SRC})
if (${USE_CUDA})
  # samxx will be CUDA-linked with device symbols resolved at library creation
  set_target_properties(samxx PROPERTIES LINKER_LANGUAGE CUDA CUDA_SEPARABLE_COMPILATION OFF CUDA_RESOLVE_DEVICE_SYMBOLS ON)
endif()
# samxx needs to link with the yakl library
target_link_libraries(samxx yakl)
target_compile_features(samxx PUBLIC cxx_std_14)

# Set fortran compiler flags
set_source_files_properties(${F90_SRC} PROPERTIES COMPILE_FLAGS "${CPPDEFS} ${FFLAGS}")

# Set YAKL compiler flags
include(${YAKL_HOME}/yakl_utils.cmake)
yakl_process_cxx_source_files("${CXX_SRC}")
message(STATUS "YAKL Flags: ${YAKL_COMPILER_FLAGS}")

# BBFFT AOT-specific changes
if (YAKL_ARCH_SYCL)
  if (YAKL_SYCL_USE_BBFFT)
    if (YAKL_SYCL_BBFFT_USE_AOT)
      message("Building with BBFFT AOT")
      set(BBFFT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/bbfft)
      find_package(bbfft-sycl REQUIRED)
      find_program(OCLOC ocloc REQUIRED)
      add_executable(yakl-aot-generate ${BBFFT_DIR}/generate.cpp ${BBFFT_DIR}/configurations.cpp)
      target_compile_features(yakl-aot-generate PRIVATE cxx_std_17)
      target_link_libraries(yakl-aot-generate PRIVATE bbfft::bbfft-base)
      target_include_directories(yakl-aot-generate ${BBFFT_DIR})

      set(SRC_FILE "kernels.cl")
      set(NAMES_FILE "aot_compiled_kernels.cpp")
      if (YAKL_SYCL_BBFFT_AOT_LEGACY_UMD)
        # older UMD - agama-ci-devel <= 543
        set(BIN_FILE "kernels_XE_HPC_COREpvc.bin")
      else()
        # newer UMD - ci-neo-master >= 025611
        set(BIN_FILE "kernels_pvc.bin")
      endif()
      set(OBJ_FILE "kernels.o")
      add_custom_command(
        OUTPUT ${OBJ_FILE}
        BYPRODUCTS ${SRC_FILE} ${NAMES_FILE} ${BIN_FILE}
        COMMAND yakl-aot-generate ${SRC_FILE} ${NAMES_FILE}
        COMMAND ${OCLOC} compile -file ${SRC_FILE} -device pvc -internal_options "-cl-ext=+cl_khr_fp64"
        COMMAND ${CMAKE_LINKER} -r -b binary -o ${OBJ_FILE} ${BIN_FILE}
        DEPENDS yakl-aot-generate
        COMMENT "Ahead-of-time compilation of FFT kernels"
      )
      add_library(yakl-kernels OBJECT IMPORTED)
      set_property(TARGET yakl-kernels PROPERTY IMPORTED_OBJECTS "${CMAKE_CURRENT_BINARY_DIR}/${OBJ_FILE}")
      target_sources(samxx PRIVATE ${NAMES_FILE})

      target_link_libraries(samxx yakl-kernels)
    else()
      message("Building with BBFFT JIT")
    endif()
  endif()
endif()

# Include YAKL source and library directories
include_directories(${YAKL_BIN})

