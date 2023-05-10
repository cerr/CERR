#include "phaseret/legla.h"
#include "legla_private.h"
#include "ltfat/macros.h"


int
phaseret_legla_params_defaults(phaseret_legla_params* params)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);

    params->relthr = 1e-3;
    params->ksize.width = 0;
    params->ksize.height = 0;
    params->leglaflags = MOD_COEFFICIENTWISE | MOD_MODIFIEDUPDATE;
    CHECKMEM( params->dparams = ltfat_dgt_params_allocdef());
error:
    return status;
}


PHASERET_API phaseret_legla_params*
phaseret_legla_params_allocdef()
{
    phaseret_legla_params* params =
        (phaseret_legla_params*) ltfat_calloc(1, sizeof * params);

    phaseret_legla_params_defaults(params);

    return params;
}

PHASERET_API int
phaseret_legla_params_set_relthr(phaseret_legla_params* params, double relthr)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    params->relthr = relthr;
error:
    return status;
}


PHASERET_API int
phaseret_legla_params_set_kernelsize(phaseret_legla_params* params,
                                     phaseret_size ksize)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    params->ksize = ksize;
error:
    return status;
}

PHASERET_API int
phaseret_legla_params_set_leglaflags(phaseret_legla_params* params,
                                     unsigned leglaflags)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    params->leglaflags = leglaflags;
error:
    return status;
}

PHASERET_API ltfat_dgt_params*
phaseret_legla_params_get_dgtreal_params(phaseret_legla_params* params)
{
    if (params)
        return params->dparams;
    else
        return NULL;
}

PHASERET_API int
phaseret_legla_params_free(phaseret_legla_params* params)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(params);
    ltfat_dgt_params_free(params->dparams);
    ltfat_free(params);
error:
    return status;

}
