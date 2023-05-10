#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "dgtrealmp_private.h"

int
ltfat_dgtmp_params_defaults(ltfat_dgtmp_params* params)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    /* params->hint = ltfat_dgtrealmp_allmods; */
    params->alg = ltfat_dgtmp_alg_mp;
    params->errtoldb = -40.0;
    params->kernrelthr = 1e-4;
    params->verbose = 0;
    params->maxatoms = 0;
    params->maxit = 0;
    params->iterstep = 0;
    params->treelevels = 10;
    params->cycles = 1;
    params->atprodreltoldb = -80.0;
    params->ptype = LTFAT_TIMEINV;
error:
    return status;
}

LTFAT_API ltfat_dgtmp_params*
ltfat_dgtmp_params_allocdef()
{
    ltfat_dgtmp_params* params;
    int status = LTFATERR_SUCCESS;
    CHECKMEM( params = LTFAT_NEW(ltfat_dgtmp_params));

    ltfat_dgtmp_params_defaults(params);

error:
    return params;
}

LTFAT_API int
ltfat_dgtmp_params_free(ltfat_dgtmp_params* params)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    ltfat_free(params);
error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_atprodreltoldb(ltfat_dgtmp_params* params, double atprodreltoldb)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    CHECK(LTFATERR_NOTPOSARG, atprodreltoldb <= 0,
          "Nonpositive number is expected (passed %d)", atprodreltoldb);

    params->atprodreltoldb = atprodreltoldb;
error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_phaseconv(
    ltfat_dgtmp_params* params, ltfat_phaseconvention pconv)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    CHECK(LTFATERR_BADARG, ltfat_phaseconvention_is_valid(pconv),
          "Invalid phase conv. passed (passed %d)", pconv);

    params->ptype = pconv;
error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_pedanticsearch(
    ltfat_dgtmp_params* params, int do_pedanticsearch)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);

    params->do_pedantic = do_pedanticsearch;
error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_alg(
    ltfat_dgtmp_params* params, ltfat_dgtmp_alg alg)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    CHECK(LTFATERR_BADARG, ltfat_dgtmp_alg_isvalid(alg),
          "Invalid hint passed (passed %d)", alg);

    params->alg = alg;
error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_maxatoms(
    ltfat_dgtmp_params* params, size_t maxatoms)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);

    CHECK(LTFATERR_NOTPOSARG, maxatoms > 0, "maxatoms must be greater than 0");
    params->maxatoms = maxatoms;

    if (params->maxit == 0)
        params->maxit = 2 * maxatoms;
error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_maxit(
    ltfat_dgtmp_params* params, size_t maxit)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);

    CHECK(LTFATERR_NOTPOSARG, maxit > 0, "maxatoms must be greater than 0");
    params->maxit = maxit;

error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_cycles(
    ltfat_dgtmp_params* params, size_t cycles)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);

    CHECK(LTFATERR_NOTPOSARG, cycles > 0, "maxatoms must be greater than 0");
    params->cycles = cycles;

error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_errtoldb(
    ltfat_dgtmp_params* params, double errtoldb)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    CHECK(LTFATERR_BADARG, errtoldb <= 0, "errtoldb must be lower than 0");
    params->errtoldb = errtoldb;

error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_snrdb(
    ltfat_dgtmp_params* params, double snrdb)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    CHECK(LTFATERR_BADARG, snrdb >= 0, "snrdb must be higher than 0");
    params->errtoldb = -snrdb;
error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_iterstep(
    ltfat_dgtmp_params* params, size_t iterstep)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    CHECK(LTFATERR_NOTPOSARG, iterstep > 0, "iterstep must be greater than 0");
    params->iterstep = iterstep;
error:
    return status;
}

LTFAT_API int
ltfat_dgtmp_setpar_kernrelthr(
    ltfat_dgtmp_params* params, double thr)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    CHECK(LTFATERR_BADARG, thr <= 1 && thr >= 0,
          "Relative threshold must be in range [0-1] (passed %f)."
          " Using previously set threshold %f", thr, params->kernrelthr);
    params->kernrelthr = thr;
error:
    return status;
}

/* int */
/* ltfat_dgtrealmp_hint_isvalid(ltfat_dgtrealmp_hint in) */
/* { */
/*     int isvalid = 0; */
/*  */
/*     switch (in) */
/*     { */
/*     case ltfat_dgtrealmp_auto: */
/*     case ltfat_dgtrealmp_singlemod: */
/*     case ltfat_dgtrealmp_allmods: */
/*         isvalid = 1; */
/*     } */
/*  */
/*     return isvalid; */
/* } */

int
ltfat_dgtmp_alg_isvalid(ltfat_dgtmp_alg in)
{
    int isvalid = 0;

    switch (in)
    {
    case ltfat_dgtmp_alg_mp:
    case ltfat_dgtmp_alg_locomp:
    case ltfat_dgtmp_alg_loccyclicmp:
    case ltfat_dgtmp_alg_locselfprojmp:
        isvalid = 1;
    }

    return isvalid;
}
