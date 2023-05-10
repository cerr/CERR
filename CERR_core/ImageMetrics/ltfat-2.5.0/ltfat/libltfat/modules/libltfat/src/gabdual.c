#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"


LTFAT_API int
LTFAT_NAME(multiwingabdual_long)(
        const LTFAT_TYPE* g, ltfat_int L, ltfat_int R, ltfat_int a,
        ltfat_int M, LTFAT_TYPE* gd)
{
    ltfat_int minL;
    LTFAT_COMPLEX* gf = NULL;
    LTFAT_COMPLEX* gdf = NULL;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(g); CHECKNULL(gd);
    CHECK(LTFATERR_BADSIZE, L > 0, "L (passed %td) must be positive", L);
    CHECK(LTFATERR_NOTPOSARG, R > 0, "R (passed %td) must be positive.", R);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a (passed %td) must be positive.", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M (passed %td) must be positive.", M);
    /* CHECK(LTFATERR_NOTAFRAME, M >= a, */
    /*       "Not a frame. Check M>=a (passed M=%td, a=%td)", M, a); */

    minL = ltfat_lcm(a, M);
    CHECK(LTFATERR_BADTRALEN, !(L % minL),
          "L must and divisible by lcm(a,M)=%td.", minL);

    CHECKMEM( gf = LTFAT_NAME_COMPLEX(malloc)(L * R));
    CHECKMEM( gdf = LTFAT_NAME_COMPLEX(malloc)(L * R));

#ifdef LTFAT_COMPLEXTYPE

    CHECKSTATUS( LTFAT_NAME(wfac)(g, L, R, a, M, gf));
    LTFAT_NAME_REAL(gabdual_fac)(gf, L, R, a, M, gdf);
    CHECKSTATUS( LTFAT_NAME(iwfac)(gdf, L, R, a, M, gd));

#else

    LTFAT_NAME_REAL(wfacreal)(g, L, R, a, M, gf);
    LTFAT_NAME_REAL(gabdualreal_fac)(gf, L, R, a, M, gdf);
    LTFAT_NAME_REAL(iwfacreal)(gdf, L, R, a, M, gd);

#endif

error:
    LTFAT_SAFEFREEALL(gdf, gf);
    return status;
}

LTFAT_API int
LTFAT_NAME(gabdual_long)(const LTFAT_TYPE* g,
                         ltfat_int L, ltfat_int a,
                         ltfat_int M, LTFAT_TYPE* gd)
{
    return LTFAT_NAME(multiwingabdual_long)( g, L, 1, a, M, gd);
}


LTFAT_API int
LTFAT_NAME(gabdual_fir)(const LTFAT_TYPE* g, ltfat_int gl,
                        ltfat_int L, ltfat_int a,
                        ltfat_int M, ltfat_int gdl, LTFAT_TYPE* gd)
{
    LTFAT_TYPE* tmpLong = NULL;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(g); CHECKNULL(gd);
    CHECK(LTFATERR_BADSIZE, gl > 0, "gl must be positive");
    CHECK(LTFATERR_BADSIZE, gdl > 0, "gdl must be positive");
    CHECK(LTFATERR_BADREQSIZE, L >= gl && L >= gdl,
          "L>=gl && L>= gdl must hold. Passed L=%td, gl=%td, gdl=%td", L, gl, gdl);

    CHECKMEM( tmpLong = LTFAT_NAME(malloc)(L));

    LTFAT_NAME(fir2long)(g, gl, L, tmpLong);
    CHECKSTATUS( LTFAT_NAME(gabdual_long)(tmpLong, L, a, M, tmpLong));
    LTFAT_NAME(long2fir)(tmpLong, L, gdl, gd);

error:
    ltfat_safefree(tmpLong);
    return status;
}
