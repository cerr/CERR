#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"


LTFAT_API int
LTFAT_NAME(multiwingabtight_long)(const LTFAT_TYPE g[],
                          ltfat_int L, ltfat_int R, ltfat_int a,
                          ltfat_int M, LTFAT_TYPE gt[])
{
    ltfat_int minL;
    LTFAT_COMPLEX* gf = NULL;
    LTFAT_COMPLEX* gtf = NULL;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(g); CHECKNULL(gt);
    CHECK(LTFATERR_BADSIZE, L > 0, "L (passed %td) must be positive.", L);
    CHECK(LTFATERR_NOTPOSARG, R > 0, "R (passed %td) must be positive.", R);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a (passed %td) must be positive.", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M (passed %td) must be positive.", M);
    CHECK(LTFATERR_NOTAFRAME, M >= a, "Not a frame. Check if M>=a.");

    minL = ltfat_lcm(a, M);
    CHECK(LTFATERR_BADTRALEN, !(L % minL),
          "L must and divisible by lcm(a,M)=%td.", minL);

    CHECKMEM( gf = LTFAT_NAME_COMPLEX(malloc)(L * R));
    CHECKMEM( gtf = LTFAT_NAME_COMPLEX(malloc)(L * R));

#ifdef LTFAT_COMPLEXTYPE

    CHECKSTATUS( LTFAT_NAME(wfac)(g, L, R, a, M, gf));
    LTFAT_NAME_REAL(gabtight_fac)(gf, L, R, a, M, gtf);
    CHECKSTATUS( LTFAT_NAME(iwfac)(gtf, L, R, a, M, gt));

#else

    LTFAT_NAME_REAL(wfacreal)(g, L, R, a, M, gf);
    LTFAT_NAME_REAL(gabtightreal_fac)(gf, L, R, a, M, gtf);
    LTFAT_NAME_REAL(iwfacreal)(gtf, L, R, a, M, gt);

#endif

error:
    LTFAT_SAFEFREEALL(gtf, gf);
    return status;
}

LTFAT_API int
LTFAT_NAME(gabtight_long)(const LTFAT_TYPE* g,
                          ltfat_int L, ltfat_int a,
                          ltfat_int M, LTFAT_TYPE* gt)
{
    return LTFAT_NAME(multiwingabtight_long)(g,L,1,a,M,gt);
}

LTFAT_API int
LTFAT_NAME(gabtight_fir)(const LTFAT_TYPE* g, ltfat_int gl,
                         ltfat_int L, ltfat_int a,
                         ltfat_int M, ltfat_int gtl, LTFAT_TYPE* gt)
{
    LTFAT_TYPE* tmpLong = NULL;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(g); CHECKNULL(gt);
    CHECK(LTFATERR_BADSIZE, gl > 0, "gl must be positive");
    CHECK(LTFATERR_BADSIZE, gtl > 0, "gtl must be positive");
    CHECK(LTFATERR_BADREQSIZE, L >= gl && L >= gtl,
          "L>=gl && L>= gtl must hold. Passed L=%td, gl=%td, gtl=%td", L, gl, gtl);

    CHECKMEM( tmpLong = LTFAT_NAME(malloc)(L));

    LTFAT_NAME(fir2long)(g, gl, L, tmpLong);
    LTFAT_NAME(gabtight_long)(tmpLong, L, a, M, tmpLong);
    LTFAT_NAME(long2fir)(tmpLong, L, gtl, gt);

error:
    if (tmpLong) ltfat_free(tmpLong);
    return status;
}
