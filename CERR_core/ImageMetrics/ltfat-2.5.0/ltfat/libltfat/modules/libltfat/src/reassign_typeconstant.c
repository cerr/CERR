#include "ltfat.h"
#include "ltfat/macros.h"

LTFAT_API fbreassOptOut*
fbreassOptOut_init(ltfat_int l, ltfat_int inital)
{
    fbreassOptOut* ret = (fbreassOptOut*) ltfat_calloc( 1, sizeof * ret);
    ret->l = l;
    // This is an array of pointers.
    ret->repos = (ltfat_int**) ltfat_malloc(l * sizeof * ret->repos);
    ret->reposl = (ltfat_int*) ltfat_calloc(l , sizeof * ret->reposl);
    ret->reposlmax = (ltfat_int*) ltfat_malloc(l * sizeof * ret->reposlmax);
    ltfat_int inital2 = ltfat_imax(1, inital);
    for (ltfat_int ii = 0; ii < l; ii++)
    {
        ret->repos[ii] = (ltfat_int*) ltfat_malloc( inital2 * sizeof * ret->repos[ii]);
        ret->reposlmax[ii] = inital2;
    }

    return ret;
}

LTFAT_API void
fbreassOptOut_destroy(fbreassOptOut* oo)
{

    for (ltfat_int ii = 0; ii < oo->l; ii++)
    {
        if (oo->repos[ii] && oo->reposlmax[ii] > 0)
        {
            ltfat_free(oo->repos[ii]);
        }
    }

    LTFAT_SAFEFREEALL(oo->repos, oo->reposl, oo->reposlmax, oo);
    oo = NULL;
}

LTFAT_API void
fbreassOptOut_expand(fbreassOptOut* oo, ltfat_int ii)
{
    ltfat_int explmax = (ltfat_int) (fbreassOptOut_EXPANDRAT * oo->reposlmax[ii]);
    oo->repos[ii] = (ltfat_int*) ltfat_realloc( (void*) oo->repos[ii],
                    oo->reposlmax[ii] * sizeof * oo->repos[ii],
                    explmax * sizeof * oo->repos[ii]);
    oo->reposlmax[ii] = explmax;
}
