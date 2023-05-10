#ifndef _phaseret_h
#define _phaseret_h

#ifndef LTFAT_NOSYSTEMHEADERS
#include "ltfat.h"
#endif

#ifndef LTFAT_DOUBLE
#   ifndef LTFAT_SINGLE
#      define LTFAT_SINGLE_WASNOTDEFINED
#      define LTFAT_SINGLE
#   endif

#   include "phaseret/api.h"

#   ifdef LTFAT_SINGLE_WASNOTDEFINED
#      undef LTFAT_SINGLE
#      undef LTFAT_SINGLE_WASNOTDEFINED
#   endif
#endif

#ifndef LTFAT_SINGLE
#   ifndef LTFAT_DOUBLE
#       define LTFAT_DOUBLE_WASNOTDEFINED
#       define LTFAT_DOUBLE
#   endif

#       include "phaseret/api.h"

#   ifdef LTFAT_DOUBLE_WASNOTDEFINED
#      undef LTFAT_DOUBLE
#      undef LTFAT_DOUBLE_WASNOTDEFINED
#   endif
#endif

#endif
