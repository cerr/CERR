#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"
#include "mex.h"

 void LTFAT_NAME(ltfatMexAtExit)(void (*ExitFcn)(void))
 {
   mwIndex fncIdx = 0;

   #if defined(LTFAT_DOUBLE)
   #  if defined(LTFAT_COMPLEXINDEPENDENT)
   fncIdx++;
   #  endif
   #elif defined(LTFAT_SINGLE)
   fncIdx = 2;
   #  if defined(LTFAT_COMPLEXINDEPENDENT)
   fncIdx++;
   #  endif
   #endif

   exitFncPtr[fncIdx] = ExitFcn;
 }



#endif
