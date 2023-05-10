#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "dgtrealmp_private.h"
#include "slicingbuf_private.h"
#include "slidgtrealmp_private.h"

LTFAT_API int
LTFAT_NAME(slidgtrealmp_init)(
    LTFAT_NAME(dgtrealmp_parbuf)* pb, ltfat_int L,
    ltfat_int numChans, ltfat_int bufLenMax,
    LTFAT_NAME(slidgtrealmp_state)** pout)
{
    int status = LTFATERR_FAILED;
    LTFAT_NAME(slidgtrealmp_state)* p = NULL;
    LTFAT_NAME(dgtrealmp_state)* mpstate = NULL;
    LTFAT_NAME(slicing_processor_state)* slistate = NULL;
    ltfat_int taperLen = 0, zpadLen = 0;

    CHECKSTATUS(
        LTFAT_NAME(dgtrealmp_init)(pb, L, &mpstate));

    for (ltfat_int k = 0; k < mpstate->P; k++)
        taperLen =
            ltfat_imax( taperLen,
                        ltfat_idivceil(mpstate->gramkerns[k + k * mpstate->P]->size.width,
                                       2) * mpstate->a[k]);

    taperLen = ltfat_imin((taperLen / 2) * 2, L);
    zpadLen = ltfat_imin(taperLen / 2, L - taperLen);
    zpadLen = (zpadLen / 2) * 2;

    DEBUG("L=%td,taperLen=%td,zpadLen=%td", L, taperLen, zpadLen);

    CHECKSTATUS(
        LTFAT_NAME(slicing_processor_init)(
            L, taperLen, zpadLen, numChans, bufLenMax, &slistate));

    CHECKSTATUS(
        LTFAT_NAME(slidgtrealmp_init_fromstates)( mpstate, slistate, &p));

    p->owning_mpstate = 1;
    p->owning_slistate = 1;
    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (mpstate) LTFAT_NAME(dgtrealmp_done)(&mpstate);
    if (slistate) LTFAT_NAME(slicing_processor_done)(&slistate);
    if (p) LTFAT_NAME(slidgtrealmp_done)(&p);
    return status;
}

LTFAT_API int
LTFAT_NAME(slidgtrealmp_init_fromstates)(
    LTFAT_NAME(dgtrealmp_state)* mpstate,
    LTFAT_NAME(slicing_processor_state)* slistate,
    LTFAT_NAME(slidgtrealmp_state)** pout)
{
    int status = LTFATERR_FAILED;

    LTFAT_NAME(slidgtrealmp_state)* p = NULL;

    CHECKNULL(mpstate); CHECKNULL(slistate); CHECKNULL(pout);
    CHECKMEM( p = LTFAT_NEW(LTFAT_NAME(slidgtrealmp_state)));
    p->P = mpstate->P;
    CHECKMEM( p->couttmp = LTFAT_NEWARRAY(LTFAT_COMPLEX*, p->P));

    for (ltfat_int pidx = 0; pidx < p->P; pidx++)
        CHECKMEM( p->couttmp[pidx] = LTFAT_NAME_COMPLEX(malloc)(
                                         mpstate->M2[pidx] * (mpstate->L / mpstate->a[pidx])));

    LTFAT_NAME(slicing_processor_setcallback)( slistate,
            &LTFAT_NAME(slidgtrealmp_execute_callback), p);

    p->mpstate = mpstate;
    p->slistate = slistate;
    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (p) LTFAT_NAME(slidgtrealmp_done)(&p);
    return status;
}

LTFAT_API ltfat_int
LTFAT_NAME(slidgtrealmp_getprocdelay)( LTFAT_NAME(slidgtrealmp_state)* p)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    return LTFAT_NAME(slicing_processor_getprocdelay)(p->slistate);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slidgtrealmp_execute)(
    LTFAT_NAME(slidgtrealmp_state)* p,
    const LTFAT_REAL* in[], ltfat_int inLen, ltfat_int chanNo,
    LTFAT_REAL* out[])
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    return LTFAT_NAME(slicing_processor_execute)( p->slistate, in, inLen, chanNo,
            out);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slidgtrealmp_execute_compact)(
    LTFAT_NAME(slidgtrealmp_state)* p,
    const LTFAT_REAL in[], ltfat_int inLen, ltfat_int chanNo,
    LTFAT_REAL out[])
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    return LTFAT_NAME(slicing_processor_execute_compact)( p->slistate, in, inLen,
            chanNo, out);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slidgtrealmp_done)(LTFAT_NAME(slidgtrealmp_state)** p)
{
    LTFAT_NAME(slidgtrealmp_state)* pp;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;

    if (pp->couttmp)
    {
        for (ltfat_int k = 0; k < pp->P; k++)
            ltfat_safefree(pp->couttmp[k]);
        ltfat_free(pp->couttmp);
    }

    if (pp->owning_mpstate && pp->mpstate)
        LTFAT_NAME(dgtrealmp_done)(&pp->mpstate);

    if (pp->owning_slistate && pp->slistate)
        LTFAT_NAME(slicing_processor_done)(&pp->slistate);

    ltfat_free(pp);
    pp = NULL;
    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slidgtrealmp_reset)(
    LTFAT_NAME(slidgtrealmp_state)* p);

int
LTFAT_NAME(slidgtrealmp_execute_callback)(void* userdata,
        const LTFAT_REAL in[], int winLen, int UNUSED(taperLen),
        int UNUSED(zpadLen), int W, LTFAT_REAL out[])
{

    LTFAT_NAME(slidgtrealmp_state)* p =
        (LTFAT_NAME(slidgtrealmp_state)*) userdata;

    for (ltfat_int w = 0; w < W; w++)
    {
        LTFAT_NAME(dgtrealmp_execute_decompose)(
            p->mpstate, in + w * winLen, p->couttmp);

        if(p->callback)
        {
            /* p->callback(p->userdata, p->mpstate, p->mpstate->iterstate->c, */
            /*             p->couttmp, p->mpstate->P, p->mpstate->M2, p->mpstate->N, */
            /*             p->mpstate->L, out + w * winLen); */
        }
        else
        {
            LTFAT_NAME(dgtrealmp_execute_synthesize)(
                p->mpstate, (const LTFAT_COMPLEX**)p->couttmp, NULL, out + w * winLen);
        }

    }
    return  0;
}

LTFAT_API int
LTFAT_NAME(slidgtrealmp_setcallback)(LTFAT_NAME(slidgtrealmp_state)* p,
        LTFAT_NAME(slidgtrealmp_processor_callback)* callback,
        void* userdata)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    p->callback = callback;
    p->userdata = userdata;
    return LTFATERR_SUCCESS;
error:
    return status;
}

/* LTFAT_API int */
/* LTFAT_NAME(slidgtrealmp_setnitercallback)( */
/*         LTFAT_NAME(slidgtrealmp_state)* p, */
/*         LTFAT_NAME(slidgtrealmp_niter_callback)* callback, */
/*         void* userdata) */
/* { */
/*     int status = LTFATERR_FAILED; */
/*     CHECKNULL(p); */
/*     p->callback = callback; */
/*     p->userdata = userdata; */
/*     return LTFATERR_SUCCESS; */
/* error: */
/*     return status; */
/* } */
