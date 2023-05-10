#include "ltfat/dgt_common.h"
#include "ltfat/thirdparty/fftw3.h"

LTFAT_API int
ltfat_phaseconvention_is_valid(ltfat_phaseconvention in)
{
    int isvalid = 0;

    switch (in)
    {
    case LTFAT_TIMEINV:
    case LTFAT_FREQINV:
        isvalid = 1; break;
    default:
        isvalid = 0;
    }

    return isvalid;
}



