AC_PREREQ([2.62])
AC_INIT([LTFAT], [2.0.0], [http://github.com/ltfat/ltfat/issues], [ltfat])

AC_PROG_CC_C99
AC_PROG_CXX

#AC_CONFIG_MACRO_DIR([m4/])
# m4_include([m4/ax_blas.m4])
# m4_include([m4/ax_lapack.m4])

# The checks for BLAS and Lapack have been disabled because they
# provoke an error about a missing install-sh

#dnl Check for BLAS libraries
#sinclude(ax_blas.m4)
#AX_BLAS
#if test "$ax_blas_ok" = "no"; then
#   AC_MSG_ERROR([Cannot find BLAS libraries])
#fi

#dnl Check for LAPACK libraries
#sinclude(ax_lapack.m4)
#AX_LAPACK
#if test "$ax_lapack_ok" = "no"; then
#   AC_MSG_ERROR([Cannot find LAPACK libraries])
#fi

dnl Check for MKOCTFILE
AC_CHECK_PROG(MKOCTFILE_CHECK,mkoctfile,"yes")
if test "$MKOCTFILE_CHECK" != "yes" ; then
    AC_MSG_ERROR([Please install mkoctfile.])
fi

MKOCTFILE="$MKOCTFILE -g"

#AC_CHECK_HEADERS([fftw3.h],[],[AC_MSG_ERROR([fftw was not found])])
# Checking for portaudio, we pack portaudio.h with LTFAT
# AC_CHECK_HEADER(portaudio.h)
AC_CHECK_LIB(portaudio,Pa_GetHostApiCount,
  [have_libportaudio=1],
  [have_libportaudio=0
   AC_MSG_WARN([Portaudio lib not found. Disabling support of the block processing framework.])]
)

AC_SUBST(have_libportaudio)
AC_OUTPUT(Makefile)
