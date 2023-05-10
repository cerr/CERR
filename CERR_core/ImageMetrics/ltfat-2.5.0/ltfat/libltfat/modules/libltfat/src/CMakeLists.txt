SET(src_files
    dgt.c dgtreal_fb.c dgt_multi.c dgt_ola.c dgt_shear.c
    dgtreal_long.c dwilt.c idwilt.c wmdct.c iwmdct.c
    filterbank.c ifilterbank.c heapint.c heap.c wfacreal.c
	idgtreal_long.c idgtreal_fb.c iwfacreal.c pfilt.c reassign_ti.c
	windows.c
	dgt_shearola.c utils.c rtdgtreal.c circularbuf.c slicingbuf.c
	dgtrealwrapper.c dgtrealmp.c dgtrealmp_parbuf.c dgtrealmp_kernel.c dgtrealmp_guts.c maxtree.c
	slidgtrealmp.c )

SET(src_files_complextransp
    ci_utils.c ci_windows.c spread.c wavelets.c goertzel.c
    reassign.c gabdual_painless.c wfac.c iwfac.c dgt_long.c idgt_long.c dgt_fb.c
    idgt_fb.c ci_memalloc.c dgtwrapper.c )

SET(src_files_blaslapack
    ltfat_blaslapack.c gabdual_fac.c gabtight_fac.c)

SET(src_files_blaslapack_complextransp
    gabdual.c gabtight.c)

SET(src_files_fftw_complextransp
    dct.c dst.c)

SET(src_files_notypechange
    memalloc.c error.c version.c argchecks.c
	dgtwrapper_typeconstant.c dgtrealmp_typeconstant.c
  	reassign_typeconstant.c wavelets_typeconstant.c
	integer_manip.c firwin_typeconstant.c)


if (NOT NOBLASLAPACK)
    SET(src_files ${src_files}
        ${src_files_blaslapack} )
    SET(src_files_complextransp
        ${src_files_complextransp} ${src_files_blaslapack_complextransp} )
endif (NOT NOBLASLAPACK)

if (NOT NOFFTW)
    SET(src_files ${src_files}
        fftw_wrappers.c ${src_files_fftw_complextransp})
else (NOT NOFFTW)
    SET(src_files ${src_files}
        kissfft_wrappers.c ../thirdparty/kissfft/fft.c)
endif (NOT NOFFTW)

if (USECPP)
    SET_SOURCE_FILES_PROPERTIES( ${src_files} 
        ${src_files_complextransp} 
        ${src_files_notypechange}
        PROPERTIES LANGUAGE CXX)
endif (USECPP)

add_library(libltfat_commondouble OBJECT ${src_files_notypechange})
add_library(libltfat_commonsingle OBJECT ${src_files_notypechange})

add_library(libltfat_double OBJECT ${src_files} ${src_files_complextransp})
add_library(libltfat_single OBJECT ${src_files} ${src_files_complextransp})

add_library(libltfat_complexdouble OBJECT ${src_files_complextransp})
add_library(libltfat_complexsingle OBJECT ${src_files_complextransp})

target_compile_definitions(libltfat_complexsingle PUBLIC LTFAT_SINGLE LTFAT_COMPLEXTYPE)
target_compile_definitions(libltfat_complexdouble PUBLIC LTFAT_DOUBLE LTFAT_COMPLEXTYPE)
target_compile_definitions(libltfat_commondouble PUBLIC LTFAT_DOUBLE)
target_compile_definitions(libltfat_commonsingle PUBLIC LTFAT_SINGLE)
target_compile_definitions(libltfat_double PUBLIC LTFAT_DOUBLE)
target_compile_definitions(libltfat_single PUBLIC LTFAT_SINGLE)

if (WIN32)
if(BUILD_SHARED_LIBS)
    target_compile_definitions(libltfat_complexsingle PUBLIC LTFAT_BUILD_SHARED)
    target_compile_definitions(libltfat_complexdouble PUBLIC LTFAT_BUILD_SHARED)
    target_compile_definitions(libltfat_commondouble PUBLIC LTFAT_BUILD_SHARED)
    target_compile_definitions(libltfat_commonsingle PUBLIC LTFAT_BUILD_SHARED)
    target_compile_definitions(libltfat_double PUBLIC LTFAT_BUILD_SHARED)
    target_compile_definitions(libltfat_single PUBLIC LTFAT_BUILD_SHARED)
else(BUILD_SHARED_LIBS)
    target_compile_definitions(libltfat_complexsingle PUBLIC LTFAT_BUILD_STATIC)
    target_compile_definitions(libltfat_complexdouble PUBLIC LTFAT_BUILD_STATIC)
    target_compile_definitions(libltfat_commondouble PUBLIC LTFAT_BUILD_STATIC)
    target_compile_definitions(libltfat_commonsingle PUBLIC LTFAT_BUILD_STATIC)
    target_compile_definitions(libltfat_double PUBLIC LTFAT_BUILD_STATIC)
    target_compile_definitions(libltfat_single PUBLIC LTFAT_BUILD_STATIC)
endif(BUILD_SHARED_LIBS)
endif(WIN32)

add_library(ltfat
    $<TARGET_OBJECTS:libltfat_commondouble>
    $<TARGET_OBJECTS:libltfat_double> $<TARGET_OBJECTS:libltfat_complexdouble>
    $<TARGET_OBJECTS:libltfat_single> $<TARGET_OBJECTS:libltfat_complexsingle>)

add_library(ltfatd
    $<TARGET_OBJECTS:libltfat_commondouble>
    $<TARGET_OBJECTS:libltfat_double> $<TARGET_OBJECTS:libltfat_complexdouble>)

add_library(ltfatf
    $<TARGET_OBJECTS:libltfat_commonsingle>
    $<TARGET_OBJECTS:libltfat_single> $<TARGET_OBJECTS:libltfat_complexsingle>)

if (WIN32)
if(BUILD_SHARED_LIBS)
    set_target_properties(ltfat PROPERTIES IMPORT_SUFFIX ".dll.lib")
    set_target_properties(ltfatf PROPERTIES IMPORT_SUFFIX ".dll.lib")
    set_target_properties(ltfatd PROPERTIES IMPORT_SUFFIX ".dll.lib")
endif(BUILD_SHARED_LIBS)
endif(WIN32)

target_link_libraries(ltfat ${LAPACK_LIB} ${BLAS_LIB} ${FFTW3_LIB} ${FFTW3F_LIB} ${LIBS})
target_link_libraries(ltfatf ${LAPACK_LIB} ${BLAS_LIB} ${FFTW3F_LIB} ${LIBS} )
target_link_libraries(ltfatd  ${LAPACK_LIB} ${BLAS_LIB} ${FFTW3_LIB} ${LIBS})

