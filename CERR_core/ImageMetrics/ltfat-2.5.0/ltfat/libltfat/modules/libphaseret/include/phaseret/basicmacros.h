#ifndef _PHASERET_BASICMACROS_H
#define _PHASERET_BASICMACROS_H

#ifndef PHASERET_API
#if defined(_WIN32) || defined(__WIN32__)
#   if defined(LTFAT_BUILD_SHARED)
#       define PHASERET_API __declspec(dllexport)
#   elif !defined(LTFAT_BUILD_STATIC)
#       define PHASERET_API __declspec(dllimport)
#   else
#       define PHASERET_API
#   endif
#else
// #   if __GNUC__ >= 4
// #       define PHASERET_API __attribute__((visibility("default")))
// #   else
#       define PHASERET_API
// #   endif
#endif
#endif

#define PHASERET_NAME_DOUBLE(name) LTFAT_MAKENAME(phaseret,name,_d)
#define PHASERET_NAME_SINGLE(name) LTFAT_MAKENAME(phaseret,name,_s)
#define PHASERET_NAME_COMPLEXDOUBLE(name) LTFAT_MAKENAME(phaseret,name,_dc)
#define PHASERET_NAME_COMPLEXSINGLE(name) LTFAT_MAKENAME(phaseret,name,_sc)

#endif
