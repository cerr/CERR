/**
*
*
*/
#include "basicmacros.h"

#ifndef LTFAT_COMPLEX_OPERATIONS
#define LTFAT_COMPLEX_OPERATIONS

#if defined(__cplusplus)
#   define ltfat_real(x) std::real(x)
#   define ltfat_imag(x) std::imag(x)
#   define ltfat_abs(x) std::abs(x)
#   define ltfat_arg(x) std::arg(x)
#else
#   define ltfat_complex_d(r,i) ((float)(r) + ((float)(i))*I)
#   define ltfat_complex_s(r,i) ((double)(r) + ((double)(i))*I)
#   define ltfat_real(x) creal(x)
#   define ltfat_imag(x) cimag(x)
#   define ltfat_abs(x) fabs(x)
#   define ltfat_arg(x) carg(x)
#endif
#   define ltfat_energy(x) ( ltfat_real(x)*ltfat_real(x) + ltfat_imag(x)*ltfat_imag(x) )
#endif

#ifdef LTFAT_COMPLEX
#undef LTFAT_COMPLEX
#endif
#ifdef LTFAT_REAL_MIN
#undef LTFAT_REAL_MIN
#endif
#ifdef LTFAT_REAL
#undef LTFAT_REAL
#endif
#ifdef LTFAT_TYPE
#undef LTFAT_TYPE
#endif
#ifdef LTFAT_NAME
#undef LTFAT_NAME
#endif
#ifdef LTFAT_NAME_REAL
#undef LTFAT_NAME_REAL
#endif
#ifdef LTFAT_NAME_COMPLEX
#undef LTFAT_NAME_COMPLEX
#endif
#ifdef LTFAT_FFTW
#undef LTFAT_FFTW
#endif
#ifdef LTFAT_KISS
#undef LTFAT_KISS
#endif

#ifdef LTFAT_MX_CLASSID
#undef LTFAT_MX_CLASSID
#endif

#ifdef LTFAT_MX_COMPLEXITY
#undef LTFAT_MX_COMPLEXITY
#endif

#ifdef LTFAT_COMPLEXH
#undef LTFAT_COMPLEXH
#endif

#ifdef LTFAT_DOUBLE
#  ifndef I
#     define I ltfat_complex_d(0.0,1.0)
#  endif
#  define LTFAT_REAL_MIN DBL_MIN
#  define LTFAT_REAL double
#  define LTFAT_COMPLEX ltfat_complex_d
#  define LTFAT_FFTW(name) fftw_ ## name
#  define LTFAT_KISS(name)  kiss_ ## name ## _d
#  define LTFAT_NAME_REAL(name) LTFAT_NAME_DOUBLE(name)
#  define LTFAT_NAME_COMPLEX(name) LTFAT_NAME_COMPLEXDOUBLE(name)
#  define LTFAT_COMPLEXH(name) name
#  define LTFAT_MX_CLASSID mxDOUBLE_CLASS
#  if defined(LTFAT_COMPLEXTYPE)
#    define LTFAT_TYPE LTFAT_COMPLEX
#    define LTFAT_NAME(name) LTFAT_NAME_COMPLEXDOUBLE(name)
#    define LTFAT_MX_COMPLEXITY mxCOMPLEX
#  else
#    define LTFAT_TYPE LTFAT_REAL
#    define LTFAT_NAME(name) LTFAT_NAME_DOUBLE(name)
#    define LTFAT_MX_COMPLEXITY mxREAL
#  endif
#endif

#ifdef LTFAT_SINGLE
#  ifndef I
#     define I ltfat_complex_s(0.0,1.0)
#  endif
#  define LTFAT_REAL_MIN FLT_MIN
#define LTFAT_REAL float
#define LTFAT_COMPLEX ltfat_complex_s
#define LTFAT_MX_CLASSID mxSINGLE_CLASS
#define LTFAT_NAME_REAL(name) LTFAT_NAME_SINGLE(name)
#define LTFAT_NAME_COMPLEX(name) LTFAT_NAME_COMPLEXSINGLE(name)
#define LTFAT_FFTW(name) fftwf_ ## name
#define LTFAT_KISS(name)  kiss_ ## name ## _s
#define LTFAT_COMPLEXH(name) name ## f
#  if defined(LTFAT_COMPLEXTYPE)
#    define LTFAT_TYPE LTFAT_COMPLEX
#    define LTFAT_NAME(name) LTFAT_NAME_COMPLEXSINGLE(name)
#    define LTFAT_MX_COMPLEXITY mxCOMPLEX
#  else
#    define LTFAT_TYPE LTFAT_REAL
#    define LTFAT_NAME(name) LTFAT_NAME_SINGLE(name)
#    define LTFAT_MX_COMPLEXITY mxREAL
#  endif
#endif

#if defined(__cplusplus)
    // The following is constexpr only since C++17, so it is disabled for the time being
    // static_assert(std::is_trivially_copyable<std::complex<LTFAT_REAL>>::value);
#endif
