#ifndef _LTFAT_BASICMACROS_H
#define _LTFAT_BASICMACROS_H

#ifndef LTFAT_API
#if defined(_WIN32) || defined(__WIN32__)
#   if defined(LTFAT_BUILD_SHARED)
#       define LTFAT_API __declspec(dllexport)
#   elif !defined(LTFAT_BUILD_STATIC)
#       define LTFAT_API __declspec(dllimport)
#   else
#       define LTFAT_API
#   endif
#else
// #   if __GNUC__ >= 4
// #       define LTFAT_API __attribute__((visibility("default")))
// #   else
#       define LTFAT_API
// #   endif
#endif
#endif

#define LTFAT_MAKENAME(prefix,name,suffix) prefix ## _ ## name ## suffix

#define LTFAT_NAME_DOUBLE(name) LTFAT_MAKENAME(ltfat,name,_d)
#define LTFAT_NAME_SINGLE(name) LTFAT_MAKENAME(ltfat,name,_s)
#define LTFAT_NAME_COMPLEXDOUBLE(name) LTFAT_MAKENAME(ltfat,name,_dc)
#define LTFAT_NAME_COMPLEXSINGLE(name) LTFAT_MAKENAME(ltfat,name,_sc)





#endif
