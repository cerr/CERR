#include "basicmacros.h"
#include "ltfat/types.h"

#ifdef PHASERET_NAME_REAL
#undef PHASERET_NAME_REAL
#endif

#ifdef PHASERET_NAME_COMPLEX
#undef PHASERET_NAME_COMPLEX
#endif

#ifdef PHASERET_NAME
#undef PHASERET_NAME
#endif

#ifdef LTFAT_DOUBLE
#  define PHASERET_NAME_REAL(name) PHASERET_NAME_DOUBLE(name)
#  define PHASERET_NAME_COMPLEX(name) PHASERET_NAME_COMPLEXDOUBLE(name)
#  if defined(LTFAT_COMPLEXTYPE)
#    define PHASERET_NAME(name) PHASERET_NAME_COMPLEXDOUBLE(name)
#  else
#    define PHASERET_NAME(name) PHASERET_NAME_DOUBLE(name)
#  endif
#endif

#ifdef LTFAT_SINGLE
#define PHASERET_NAME_REAL(name) PHASERET_NAME_SINGLE(name)
#define PHASERET_NAME_COMPLEX(name) PHASERET_NAME_COMPLEXSINGLE(name)
#  if defined(LTFAT_COMPLEXTYPE)
#    define PHASERET_NAME(name) PHASERET_NAME_COMPLEXSINGLE(name)
#  else
#    define PHASERET_NAME(name) PHASERET_NAME_SINGLE(name)
#  endif
#endif
