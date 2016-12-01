
cmake_minimum_required(VERSION 2.8)

project(PatchwiseGlcmFeatures)

find_package(ITK REQUIRED)
include(${ITK_USE_FILE})
if (ITKVtkGlue_LOADED)
  find_package(VTK REQUIRED)
  include(${VTK_USE_FILE})
endif()

add_executable(PatchwiseGlcmFeatures PatchwiseGlcmFeatures.cxx)

if( "${ITK_VERSION_MAJOR}" LESS 4 )
  target_link_libraries(PatchwiseGlcmFeatures ITKReview ${ITK_LIBRARIES})
else( "${ITK_VERSION_MAJOR}" LESS 4 )
  target_link_libraries(PatchwiseGlcmFeatures ${ITK_LIBRARIES})
endif( "${ITK_VERSION_MAJOR}" LESS 4 )

