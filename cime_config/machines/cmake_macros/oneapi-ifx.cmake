if (compile_threaded)
  string(APPEND CMAKE_C_FLAGS   " -qopenmp")
  string(APPEND CMAKE_Fortran_FLAGS   " -qopenmp")
  string(APPEND CMAKE_CXX_FLAGS " -qopenmp")
  string(APPEND CMAKE_EXE_LINKER_FLAGS  " -qopenmp")
endif()
string(APPEND CMAKE_C_FLAGS_RELEASE   " -O2")
string(APPEND CMAKE_Fortran_FLAGS_RELEASE   " -O2")
string(APPEND CMAKE_CXX_FLAGS_RELEASE " -O2")
string(APPEND CMAKE_Fortran_FLAGS_DEBUG   " -O0 -g -check uninit -check bounds -check pointers -fpe0 -check noarg_temp_created")
string(APPEND CMAKE_C_FLAGS_DEBUG   " -O0 -g")
string(APPEND CMAKE_CXX_FLAGS_DEBUG " -O0 -g")
string(APPEND CMAKE_C_FLAGS   " -traceback -fp-model precise -std=gnu99")
string(APPEND CMAKE_CXX_FLAGS " -traceback -fp-model precise")
string(APPEND CMAKE_Fortran_FLAGS   " -traceback -convert big_endian -assume byterecl -assume realloc_lhs -fp-model precise")
string(APPEND CPPDEFS " -DFORTRANUNDERSCORE -DNO_R16 -DCPRINTEL -DHAVE_SLASHPROC -DHIDE_MPI")
string(APPEND CMAKE_Fortran_FORMAT_FIXED_FLAG " -fixed -132")
string(APPEND CMAKE_Fortran_FORMAT_FREE_FLAG " -free")
set(E3SM_LINK_WITH_FORTRAN "TRUE")
set(HAS_F2008_CONTIGUOUS "TRUE")
set(MPIFC "mpifort")
set(MPICC "mpicc")
set(MPICXX "mpicxx")
set(SCC "icx")
set(SCXX "icpx")
set(SFC "ifx")
