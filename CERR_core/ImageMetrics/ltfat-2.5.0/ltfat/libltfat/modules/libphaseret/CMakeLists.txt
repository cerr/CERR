cmake_minimum_required (VERSION 2.8)
project (libphaseret C CXX)

option(NOBLASLAPACK
    "Disable BLAS and LAPACK dependency. Must be used if LTFAT was compiled without BLAS
    and LAPACK dependency" OFF)

if (MSVC)
    set(USECPP 1)
else (MSVC)
    option(USECPP
        "Use C++ compiler instead of C compiler" OFF)
endif (MSVC)


# FIND_LIBRARY(FFTW3_LIB NAMES fftw3 libfftw3)
# FIND_LIBRARY(FFTW3F_LIB NAMES fftw3f libfftw3f)

FIND_LIBRARY(LTFAT_LIB NAMES ltfat libltfat)
FIND_LIBRARY(LTFATF_LIB NAMES ltfatf libltfatf)
FIND_LIBRARY(LTFATD_LIB NAMES ltfatd libltfatd)

FIND_PATH(LTFAT_INCLUDE NAMES ltfat.h)

# if (NOT NOBLASLAPACK)
#     FIND_LIBRARY(BLAS_LIB NAMES blas libblas)
#     FIND_LIBRARY(LAPACK_LIB NAMES lapack liblapack)
# endif (NOT NOBLASLAPACK)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/thirdparty)
include_directories(${LTFAT_INCLUDE})

add_subdirectory(src)

