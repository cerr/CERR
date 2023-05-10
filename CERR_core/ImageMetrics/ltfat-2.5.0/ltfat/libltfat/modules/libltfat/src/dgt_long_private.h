#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

struct LTFAT_NAME_REAL(dgt_long_plan)
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int L;
    ltfat_int W;
    ltfat_int c;
    ltfat_int h_a;
    ltfat_phaseconvention ptype;
    LTFAT_NAME_REAL(fft_plan)* p_before;
    LTFAT_NAME_REAL(ifft_plan)* p_after;
    LTFAT_NAME_REAL(fft_plan)* p_veryend;
    LTFAT_REAL* sbuf;
    const LTFAT_REAL* f;
    LTFAT_COMPLEX* gf;
    LTFAT_COMPLEX* cout;
    LTFAT_REAL* ff, *cf;
};

struct LTFAT_NAME_COMPLEX(dgt_long_plan)
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int L;
    ltfat_int W;
    ltfat_int c;
    ltfat_int h_a;
    ltfat_phaseconvention ptype;
    LTFAT_NAME_REAL(fft_plan)* p_before;
    LTFAT_NAME_REAL(ifft_plan)* p_after;
    LTFAT_NAME_REAL(fft_plan)* p_veryend;
    LTFAT_REAL* sbuf;
    const LTFAT_COMPLEX* f;
    LTFAT_COMPLEX* gf;
    LTFAT_COMPLEX* cout;
    LTFAT_REAL* ff, *cf;
};

