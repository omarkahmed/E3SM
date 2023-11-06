
set(CXX_LINKER "CXX")
string(APPEND SLIBS " -lmkl_intel_lp64 -lmkl_sequential -lmkl_core")
string(APPEND SLIBS " -fiopenmp -fopenmp-targets=spir64")
set(USE_SYCL "TRUE")
string(APPEND KOKKOS_OPTIONS " -DCMAKE_CXX_STANDARD=17 -DKokkos_ENABLE_OPENMP=ON -DKokkos_ARCH_INTEL_PVC=ON -DKokkos_ENABLE_SYCL=ON -DKokkos_ENABLE_EXPLICIT_INSTANTIATION=Off")
string(APPEND SYCL_FLAGS " -\-intel -fsycl -fsycl-targets=spir64_gen -mlong-double-64 -Xsycl-target-backend \"-device pvc\"")
#string(APPEND SYCL_FLAGS " -\-intel -fsycl")
string(APPEND CXX_LDFLAGS " -Wl,-\-defsym,main=MAIN_\_ -lifcore -\-intel -fsycl -lsycl -mlong-double-64 -Xsycl-target-backend \"-device pvc\"")

