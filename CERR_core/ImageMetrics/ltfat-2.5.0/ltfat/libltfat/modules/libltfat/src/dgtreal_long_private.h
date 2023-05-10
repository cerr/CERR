#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

struct LTFAT_NAME(dgtreal_long_plan)
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int L;
    ltfat_int W;
    ltfat_int c;
    ltfat_int h_a;
    ltfat_phaseconvention ptype;
    LTFAT_NAME(fftreal_plan)* p_before;
    LTFAT_NAME(ifftreal_plan)* p_after;
    LTFAT_NAME(fftreal_plan)* p_veryend;
    LTFAT_REAL* sbuf;
    LTFAT_COMPLEX* cbuf;
    const LTFAT_REAL* f;
    LTFAT_COMPLEX* gf;
    LTFAT_REAL* cwork;
    LTFAT_COMPLEX* cout;
    LTFAT_REAL* ff, *cf;
};
