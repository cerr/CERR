
cmake_minimum_required(VERSION 2.8)

project(GlobalGlcmFeatures)

find_package(ITK REQUIRED)
include(${ITK_USE_FILE})
if (ITKVtkGlue_LOADED)
  find_package(VTK REQUIRED)
  include(${VTK_USE_FILE})
endif()

add_executable(GlobalGlcmFeatures GlobalGlcmFeatures.cxx)

if( "${ITK_VERSION_MAJOR}" LESS 4 )
  target_link_libraries(GlobalGlcmFeatures ITKReview ${ITK_LIBRARIES})
else( "${ITK_VERSION_MAJOR}" LESS 4 )
  target_link_libraries(GlobalGlcmFeatures ${ITK_LIBRARIES})
endif( "${ITK_VERSION_MAJOR}" LESS 4 )

