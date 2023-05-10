#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "dgtwrapper_private.h"

#include "ltfat/thirdparty/fftw3.h"

int
ltfat_dgt_params_defaults(ltfat_dgt_params* params)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    params->ptype = LTFAT_FREQINV;
    params->fftw_flags = FFTW_ESTIMATE;
    params->hint = ltfat_dgt_auto;
    params->do_synoverwrites = 1;
error:
    return status;
}

LTFAT_API ltfat_dgt_params*
ltfat_dgt_params_allocdef()
{
    ltfat_dgt_params* params;
    int status = LTFATERR_SUCCESS;
    CHECKMEM( params = LTFAT_NEW(ltfat_dgt_params));

    ltfat_dgt_params_defaults(params);
error:
    return params;
}

LTFAT_API int
ltfat_dgt_setpar_phaseconv(ltfat_dgt_params* params,
                                   ltfat_phaseconvention ptype)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    params->ptype = ptype;
error:
    return status;
}

LTFAT_API int
ltfat_dgt_getpar_phaseconv(ltfat_dgt_params* params)
{
    if(params) return params->ptype;
    else return LTFATERR_NULLPOINTER;
}

LTFAT_API int
ltfat_dgt_setpar_fftwflags(ltfat_dgt_params* params,
                                   unsigned fftw_flags)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    params->fftw_flags = fftw_flags;
error:
    return status;

}

LTFAT_API int
ltfat_dgt_setpar_synoverwrites(ltfat_dgt_params* params, int do_synoverwrites)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    params->do_synoverwrites = do_synoverwrites;
error:
    return status;
}

LTFAT_API int
ltfat_dgt_setpar_hint(ltfat_dgt_params* params,
                              ltfat_dgt_hint hint)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    params->hint = hint;
error:
    return status;
}

/* LTFAT_API int */
/* ltfat_dgt_setpar_normalizewin(ltfat_dgt_params* params, */
/*                                       int do_normalize_win) */
/* { */
/*     int status = LTFATERR_SUCCESS; */
/*     CHECKNULL(params); */
/*     params->normalize_win = do_normalize_win; */
/* error: */
/*     return status; */
/* } */

LTFAT_API int
ltfat_dgt_params_free(ltfat_dgt_params* params)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    ltfat_free(params);
error:
    return status;
}
