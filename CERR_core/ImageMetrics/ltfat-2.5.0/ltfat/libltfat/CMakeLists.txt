cmake_minimum_required (VERSION 3.1)
project (libltfat C CXX)

set(CMAKE_BUILD_TYPE Release)

option(BUILD_SHARED_LIBS
    "Build .so/.dll" ON)

option(NOBLASLAPACK
    "Disable BLAS and LAPACK dependency" ON)

option(NOFFTW
    "Disable FFTW dependency" ON)

if (MSVC)
    set(USECPP 1)
else (MSVC)
    option(USECPP
        "Use C++ compiler" OFF)
endif (MSVC)

if (NOT NOFFTW)
    FIND_LIBRARY(FFTW3_LIB NAMES fftw3 libfftw3)
    FIND_LIBRARY(FFTW3F_LIB NAMES fftw3f libfftw3f)
endif (NOT NOFFTW)

if (NOT NOBLASLAPACK)
    FIND_LIBRARY(BLAS_LIB NAMES blas libblas)
    FIND_LIBRARY(LAPACK_LIB NAMES lapack liblapack)
endif (NOT NOBLASLAPACK)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)


if (NOBLASLAPACK)
    add_definitions(-DNOBLASLAPACK)
endif (NOBLASLAPACK)

if (NOFFTW)
    add_definitions(-DKISS)
else (NOFFTW)
    add_definitions(-DFFTW)
endif (NOFFTW)

if (MSVC)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4 /wd4706")
else (MSVC)
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
    SET(CMAKE_SHARED_LINKER_FLAGS "-Wl,--no-undefined -Wl,-rpath,$ORIGIN")
    SET(LIBS m)
    if(CMAKE_CROSSCOMPILING)
        SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -static-libgcc")
    endif(CMAKE_CROSSCOMPILING)
endif(MSVC)

set(OLD_CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
set(OLD_CMAKE_C_FLAGS ${CMAKE_C_FLAGS})

if(USECPP)
    set (CMAKE_CXX_STANDARD 11)
else(USECPP)
    set (CMAKE_C_STANDARD 99)
endif(USECPP)

if (MSVC)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /D_HAS_EXCEPTIONS=0 /EHsc")
else (MSVC)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions -fno-rtti")
    SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-undefined -Wl,-rpath,$ORIGIN")
    SET(LIBS m)
endif(MSVC)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/modules/libltfat/include)

add_subdirectory(modules/libltfat/src)

option(DO_LIBPHASERET
    "Compile libphaseret module" OFF)

if (DO_LIBPHASERET)
    add_subdirectory(modules/libphaseret/src)
endif (DO_LIBPHASERET)

add_subdirectory(examples EXCLUDE_FROM_ALL)

