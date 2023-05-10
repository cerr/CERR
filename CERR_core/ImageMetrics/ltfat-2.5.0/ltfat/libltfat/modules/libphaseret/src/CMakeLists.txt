include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../include)


SET(sources
    gla.c legla.c pghi.c rtisila.c rtpghi.c spsi.c utils.c
    gsrtisila.c gsrtisilapghi.c)

SET(sources_typeconstant
    legla_typeconstant.c pghi_typeconstant.c)

if (USECPP)
    SET_SOURCE_FILES_PROPERTIES( ${sources} ${sources_typeconstant} 
        PROPERTIES LANGUAGE CXX)
endif (USECPP)

add_library(libphaseret_commondouble OBJECT ${sources_typeconstant})
add_library(libphaseret_commonsingle OBJECT ${sources_typeconstant})

add_library(libphaseret_double OBJECT ${sources})
add_library(libphaseret_single OBJECT ${sources})

target_compile_definitions(libphaseret_commondouble PUBLIC LTFAT_DOUBLE)
target_compile_definitions(libphaseret_commonsingle PUBLIC LTFAT_SINGLE)
target_compile_definitions(libphaseret_double PUBLIC LTFAT_DOUBLE)
target_compile_definitions(libphaseret_single PUBLIC LTFAT_SINGLE)

if (WIN32)
if(BUILD_SHARED_LIBS)
    target_compile_definitions(libphaseret_commondouble PUBLIC LTFAT_BUILD_SHARED)
    target_compile_definitions(libphaseret_commonsingle PUBLIC LTFAT_BUILD_SHARED)
    target_compile_definitions(libphaseret_double PUBLIC LTFAT_BUILD_SHARED)
    target_compile_definitions(libphaseret_single PUBLIC LTFAT_BUILD_SHARED)
else(BUILD_SHARED_LIBS)
    target_compile_definitions(libphaseret_commondouble PUBLIC LTFAT_BUILD_STATIC)
    target_compile_definitions(libphaseret_commonsingle PUBLIC LTFAT_BUILD_STATIC)
    target_compile_definitions(libphaseret_double PUBLIC LTFAT_BUILD_STATIC)
    target_compile_definitions(libphaseret_single PUBLIC LTFAT_BUILD_STATIC)
endif(BUILD_SHARED_LIBS)
endif(WIN32)

add_library(phaseret
    $<TARGET_OBJECTS:libphaseret_commondouble>
    $<TARGET_OBJECTS:libphaseret_double>
    $<TARGET_OBJECTS:libphaseret_single>)


add_library(phaseretd
    $<TARGET_OBJECTS:libphaseret_commondouble>
    $<TARGET_OBJECTS:libphaseret_double>)

add_library(phaseretf
    $<TARGET_OBJECTS:libphaseret_commonsingle>
    $<TARGET_OBJECTS:libphaseret_single>)

if (WIN32)
if(BUILD_SHARED_LIBS)
    set_target_properties(phaseret PROPERTIES IMPORT_SUFFIX ".dll.lib")
    set_target_properties(phaseretf PROPERTIES IMPORT_SUFFIX ".dll.lib")
    set_target_properties(phaseretd PROPERTIES IMPORT_SUFFIX ".dll.lib")
endif(BUILD_SHARED_LIBS)
endif(WIN32)

target_link_libraries(phaseret  ltfat)
target_link_libraries(phaseretf ltfatf)
target_link_libraries(phaseretd ltfatd)

