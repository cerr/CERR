cmake_minimum_required (VERSION 3.1)
project (examples CXX C)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/utils)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../modules/libltfat/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../modules/libphaseret/include)

set (CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_FLAGS ${OLD_CMAKE_CXX_FLAGS})
set(CMAKE_C_FLAGS ${OLD_CMAKE_C_FLAGS})


if(CMAKE_CROSSCOMPILING)
SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static-libstdc++")
endif(CMAKE_CROSSCOMPILING)

add_subdirectory(multigabormp)
