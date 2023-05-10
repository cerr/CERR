#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "circularbuf_private.h"
#include "slicingbuf_private.h"

LTFAT_API int
LTFAT_NAME(slicing_processor_init)( ltfat_int winLen, ltfat_int taperLen,
                                    ltfat_int zpadLen, ltfat_int numChans,
                                    ltfat_int bufLenMax,
                                    LTFAT_NAME(slicing_processor_state)** pout)
{
    LTFAT_NAME(slicing_processor_state)* p = NULL;
    ltfat_int Ltrue = 0, hop = 0;
    int status = LTFATERR_FAILED;

    Ltrue = winLen - zpadLen;
    hop =  Ltrue - taperLen / 2;
    CHECK(LTFATERR_NOTPOSARG, winLen > 0,
          "winLen must be positive (passed %td)", winLen);
    CHECK(LTFATERR_NOTPOSARG, taperLen >= 0 && taperLen % 2 == 0,
          "taperLen must be positive and even (passed %td)", taperLen);
    CHECK(LTFATERR_NOTPOSARG, zpadLen >= 0 && zpadLen % 2 == 0,
          "zpadLen must be positive and even (passed %td)", zpadLen);
    CHECK(LTFATERR_NOTPOSARG, numChans > 0,
          "numChans must be positive (passed %td)", numChans);
    CHECK(LTFATERR_NOTPOSARG, bufLenMax > 0,
          "Wmax must be positive (passed %td)", bufLenMax);
    /* CHECK(LTFATERR_NOTPOSARG, procDelay > 0, */
    /*       "Wmax must be positive (passed %td)", procDelay); */
    CHECK(LTFATERR_BADARG, winLen > taperLen + zpadLen,
          "winLen must be higher than taperLen + zpadLen");

    CHECKMEM( p = LTFAT_NEW(LTFAT_NAME(slicing_processor_state)));
    p->winLen = winLen; p->taperLen = taperLen; p->zpadLen = zpadLen;

    CHECKMEM( p->ga = LTFAT_NAME_REAL(malloc)(taperLen));
    CHECKMEM( p->gs = LTFAT_NAME_REAL(malloc)(taperLen));

    LTFAT_NAME(slicing_processor_settaperwin)( p, LTFAT_HANN, 1);

    CHECKMEM( p->bufIn_start  = LTFAT_NAME_REAL(calloc)(winLen * numChans));
    CHECKMEM( p->bufOut_start = LTFAT_NAME_REAL(calloc)(winLen * numChans));
    p->bufIn = p->bufIn_start + zpadLen / 2;
    p->bufOut = p->bufOut_start + zpadLen / 2;

    CHECKSTATUS( LTFAT_NAME(block_processor_init_withbuffers)(
      Ltrue, hop, numChans, bufLenMax, Ltrue-1, p->bufIn, p->bufOut, &p->block_processor
      ));

    LTFAT_NAME(block_processor_setprebufchanstride)( p->block_processor, winLen);
    LTFAT_NAME(block_processor_setpostbufchanstride)( p->block_processor, winLen);

    CHECKSTATUS( LTFAT_NAME(block_processor_setcallback)(
            p->block_processor, &LTFAT_NAME(slicing_processor_execute_callback), p));

    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (p) LTFAT_NAME(slicing_processor_done)(&p);
    return status;
}

LTFAT_API int
LTFAT_NAME(slicing_processor_settaperwin)(
    LTFAT_NAME(slicing_processor_state)* p, LTFAT_FIRWIN g, int do_analysis)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    CHECKSTATUS( LTFAT_NAME(firwin)( g, p->taperLen, p->ga));
    CHECKSTATUS( LTFAT_NAME(slicing_processor_settaper)( p, p->ga, do_analysis));
    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API ltfat_int
LTFAT_NAME(slicing_processor_getprocdelay)( LTFAT_NAME(slicing_processor_state)* p)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    return p->winLen - p->zpadLen - 1;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slicing_processor_settaper)(
    LTFAT_NAME(slicing_processor_state)* p, const LTFAT_REAL g[], int do_analysis)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(g);

    if (do_analysis)
    {
        if (p->ga != (LTFAT_REAL*) g) memcpy(p->ga, g , p->taperLen * sizeof * g);
        LTFAT_NAME(gabdual_painless)(
                p->ga, p->taperLen, p->taperLen / 2, p->taperLen, p->gs);
        for (ltfat_int l = 0; l < p->taperLen; l++) p->gs[l] *= p->taperLen;
    }
    else
    {
        if (p->gs != (LTFAT_REAL*) g) memcpy(p->gs, g , p->taperLen * sizeof * g);
        LTFAT_NAME(gabdual_painless)(
                p->gs, p->taperLen, p->taperLen / 2, p->taperLen, p->ga);
        for (ltfat_int l = 0; l < p->taperLen; l++) p->ga[l] *= p->taperLen;
    }

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slicing_processor_done)(LTFAT_NAME(slicing_processor_state)** p)
{
    LTFAT_NAME(slicing_processor_state)* pp;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(*p);

    pp = *p;
    if(pp->block_processor) LTFAT_NAME(block_processor_done)(&pp->block_processor);
    LTFAT_SAFEFREEALL(pp->bufIn_start, pp->bufOut_start, pp->ga, pp->gs );

    ltfat_free(pp);
    pp = NULL;
    return LTFATERR_SUCCESS;
error:
    return status;
}

int
LTFAT_NAME(slicing_processor_execute_callback)(void* userdata,
        const LTFAT_REAL* UNUSED(in), int UNUSED(winLen), int W, LTFAT_REAL* UNUSED(out))
{
    int status = 0;
    LTFAT_NAME(slicing_processor_state)* p =
    (LTFAT_NAME(slicing_processor_state)*) userdata;

    LTFAT_NAME(slicing_processor_callback)* processorCallback = p->processorCallback;
    if(!processorCallback)
        processorCallback = &LTFAT_NAME(default_slicing_processor_callback);

    if (p->ga)
    {
        for (ltfat_int w = 0; w < W; w++)
            for (ltfat_int l = 0; l < p->taperLen / 2; l++)
                p->bufIn[l + w * p->winLen] *= p->ga[p->taperLen / 2 + l];

        for (ltfat_int w = 0; w < W; w++)
            for (ltfat_int l = 0; l < p->taperLen / 2; l++)
                p->bufIn_start[(w + 1)*p->winLen - p->taperLen / 2  - p->zpadLen / 2 + l] *=
                    p->ga[l];
    }

    status = processorCallback(p->userdata, p->bufIn_start, p->winLen, p->taperLen,
                               p->zpadLen, W, p->bufOut_start);

    if (p->gs)
    {
        for (ltfat_int w = 0; w < W; w++)
            for (ltfat_int l = 0; l < p->taperLen / 2; l++)
                p->bufOut[l + w * p->winLen] *= p->gs[p->taperLen / 2 + l];

        for (ltfat_int w = 0; w < W; w++)
            for (ltfat_int l = 0; l < p->taperLen / 2; l++)
                p->bufOut_start[(w + 1)*p->winLen - p->taperLen / 2  - p->zpadLen / 2 + l] *=
                    p->gs[l];
    }
    return status;
}



LTFAT_API int
LTFAT_NAME(default_slicing_processor_callback)(void* UNUSED(userdata),
        const LTFAT_REAL* in, int winLen, int UNUSED(taperLen), int UNUSED(zpadLen),
        int W, LTFAT_REAL* out)
{
    memcpy(out, in, W * winLen * sizeof * in);
    return 0;
}

LTFAT_API int
LTFAT_NAME(slicing_processor_setcallback)(
    LTFAT_NAME(slicing_processor_state)* p,
    LTFAT_NAME(slicing_processor_callback)* callback, void* userdata)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    p->processorCallback = callback;
    p->userdata = userdata;

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slicing_processor_reset)(LTFAT_NAME(slicing_processor_state)* p)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);

    LTFAT_NAME(block_processor_reset)(p->block_processor);

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slicing_processor_execute_gen)(
    LTFAT_NAME(slicing_processor_state)* p,
    const LTFAT_REAL** in, ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen,
    LTFAT_REAL** out)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    return LTFAT_NAME(block_processor_execute)( p->block_processor, in, inLen, chanNo, outLen, out);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slicing_processor_execute_gen_compact)(
    LTFAT_NAME(slicing_processor_state)* p,
    const LTFAT_REAL* in, ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen,
    LTFAT_REAL* out)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    return LTFAT_NAME(block_processor_execute_compact)( p->block_processor, in, inLen, chanNo, outLen, out);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(slicing_processor_execute)(
    LTFAT_NAME(slicing_processor_state)* p,
    const LTFAT_REAL** in, ltfat_int len, ltfat_int chanNo, LTFAT_REAL** out)
{
    return LTFAT_NAME(slicing_processor_execute_gen)(p, in, len, chanNo, len, out);
}

LTFAT_API int
LTFAT_NAME(slicing_processor_execute_compact)(
    LTFAT_NAME(slicing_processor_state)* p,
    const LTFAT_REAL* in, ltfat_int len, ltfat_int chanNo, LTFAT_REAL* out)
{
    return LTFAT_NAME(slicing_processor_execute_gen_compact)(
               p, in, len, chanNo, len, out);
}
