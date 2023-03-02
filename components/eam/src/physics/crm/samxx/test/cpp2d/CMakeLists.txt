
add_executable(cpp2d ../dmdf.F90 ../cpp_driver.F90
               ../../../crmdims.F90
               ../../../params_kind.F90
               ../../../crm_input_module.F90
               ../../../crm_output_module.F90
               ../../../crm_rad_module.F90
               ../../../crm_state_module.F90
               ../../../crm_ecpp_output_module.F90
               ../../../ecppvars.F90
               ../../../openacc_utils.F90
               ${CPP_SRC})
target_link_libraries(cpp2d yakl ${NCFLAGS})
set_property(TARGET cpp2d APPEND PROPERTY COMPILE_FLAGS ${DEFS2D} )
set_property(TARGET cpp2d PROPERTY LINK_FLAGS "-Wl,--defsym,main=MAIN__  -lifcore")
set_property(TARGET cpp2d PROPERTY LINKER_LANGUAGE CXX)

include(${YAKL_HOME}/yakl_utils.cmake)
yakl_process_target(cpp2d)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/../yakl)

message("YAKL_ARCH: ${YAKL_ARCH}")
message("YAKL_SYCL_USE_BBFFT: ${YAKL_SYCL_USE_BBFFT}")
message("YAKL_SYCL_BBFFT_USE_AOT: ${YAKL_SYCL_BBFFT_USE_AOT}")

# BBFFT AOT-specific changes
if ("${YAKL_ARCH}" STREQUAL "SYCL")
  if (YAKL_SYCL_USE_BBFFT)
    if (YAKL_SYCL_BBFFT_USE_AOT)
      message("Building with BBFFT AOT")
      set(BBFFT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../bbfft)
      message("BBFFT_DIR: ${BBFFT_DIR}")
      find_package(bbfft-sycl REQUIRED)
      find_program(OCLOC ocloc REQUIRED)
      add_executable(yakl-aot-generate ${BBFFT_DIR}/generate-fft.cpp ${BBFFT_DIR}/configurations-fft.cpp)
      target_compile_features(yakl-aot-generate PRIVATE cxx_std_17)
      target_link_libraries(yakl-aot-generate PRIVATE bbfft::bbfft-base)
      target_include_directories(yakl-aot-generate PRIVATE ${BBFFT_DIR})

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
      target_sources(cpp2d PRIVATE ${NAMES_FILE})

      target_link_libraries(cpp2d yakl-kernels)
    else()
      message("Building with BBFFT JIT")
    endif()
  endif()
endif()
