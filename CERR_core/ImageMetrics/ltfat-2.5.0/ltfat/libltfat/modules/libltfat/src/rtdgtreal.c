#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "ltfat/thirdparty/fftw3.h"
#include "circularbuf_private.h"

// These are non-public function header templates
typedef int LTFAT_NAME(realtocomplextransform)(void* userdata,
        const LTFAT_REAL* in, ltfat_int, LTFAT_COMPLEX* out);

typedef int LTFAT_NAME(complextorealtransform)(void* userdata,
        const LTFAT_COMPLEX* in, ltfat_int W, LTFAT_REAL* out);

struct LTFAT_NAME(rtdgtreal_plan)
{
    LTFAT_REAL* g; //!< Window
    ltfat_int gl; //!< Window length
    ltfat_int M; //!< Number of FFT channels
    rtdgt_phasetype ptype; //!< Phase convention
    LTFAT_REAL* fftBuf; //!< Internal buffer
    LTFAT_COMPLEX* fftBuf_cpx; //!< Internal buffer
    ltfat_int fftBufLen; //!< Internal buffer length
    LTFAT_NAME_REAL(fftreal_plan)*  pfft;
    LTFAT_NAME_REAL(ifftreal_plan)* pifft;
};

int
LTFAT_NAME(rtdgtreal_commoninit)(const LTFAT_REAL* g, ltfat_int gl,
                                 ltfat_int M, const rtdgt_phasetype ptype,
                                 const ltfat_transformdirection tradir,
                                 LTFAT_NAME(rtdgtreal_plan)** pout)
{
    ltfat_int M2;
    LTFAT_NAME(rtdgtreal_plan)* p = NULL;

    int status = LTFATERR_FAILED;
    CHECK(LTFATERR_NOTPOSARG, gl > 0, "gl must be positive");
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive");

    CHECKMEM( p = LTFAT_NEW( LTFAT_NAME(rtdgtreal_plan) ));

    M2 = M / 2 + 1;
    p->fftBufLen = gl > 2 * M2 ? gl : 2 * M2;

    CHECKMEM( p->g = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM( p->fftBuf =     LTFAT_NAME_REAL(malloc)(p->fftBufLen));
    CHECKMEM( p->fftBuf_cpx = LTFAT_NAME_COMPLEX(malloc)(M2));
    p->gl = gl;
    p->M = M;
    p->ptype = ptype;

    LTFAT_NAME_REAL(fftshift)(g, gl, p->g);

    if (LTFAT_FORWARD == tradir)
    {
        LTFAT_NAME_REAL(fftreal_init)(M, 1, p->fftBuf, p->fftBuf_cpx,
                                      FFTW_MEASURE, &p->pfft);
        CHECKINIT(p->pfft, "FFTW plan creation failed.");
    }
    else if (LTFAT_INVERSE == tradir)
    {
        LTFAT_NAME_REAL(ifftreal_init)(M, 1, p->fftBuf_cpx, p->fftBuf,
                                       FFTW_MEASURE, &p->pifft);
        CHECKINIT(p->pifft, "FFTW plan creation failed.");
    }
    else
        CHECKCANTHAPPEN("Unknown transform direction.");


    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (p) LTFAT_NAME(rtdgtreal_done)(&p);
    return status;
}

LTFAT_API int
LTFAT_NAME(rtdgtreal_init)(const LTFAT_REAL* g, ltfat_int gl,
                           ltfat_int M, const rtdgt_phasetype ptype,
                           LTFAT_NAME(rtdgtreal_plan)** p)
{
    return LTFAT_NAME(rtdgtreal_commoninit)(g, gl, M, ptype, LTFAT_FORWARD, p);
}

LTFAT_API int
LTFAT_NAME(rtidgtreal_init)(const LTFAT_REAL* g, ltfat_int gl,
                            ltfat_int M, const rtdgt_phasetype ptype,
                            LTFAT_NAME(rtdgtreal_plan)** p)
{
    return LTFAT_NAME(rtdgtreal_commoninit)(g, gl, M, ptype, LTFAT_INVERSE, p);
}

LTFAT_API int
LTFAT_NAME(rtdgtreal_execute)(const LTFAT_NAME(rtdgtreal_plan)* p,
                              const LTFAT_REAL* f, ltfat_int W,
                              LTFAT_COMPLEX* c)
{
    ltfat_int M, M2, gl;
    LTFAT_REAL* fftBuf;
    LTFAT_COMPLEX* fftBuf_cpx;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(f); CHECKNULL(c);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");

    M = p->M;
    M2 = M / 2 + 1;
    gl = p->gl;
    fftBuf = p->fftBuf;
    fftBuf_cpx = p->fftBuf_cpx;

    for (ltfat_int w = 0; w < W; w++)
    {
        const LTFAT_REAL* fchan = f + w * gl;
        LTFAT_COMPLEX* cchan = c + w * M2;

        if (p->g)
            for (ltfat_int ii = 0; ii < gl; ii++)
                fftBuf[ii] = fchan[ii] * p->g[ii];

        if (M > gl)
            memset(fftBuf + gl, 0, (M - gl) * sizeof * fftBuf);

        if (gl > M)
            LTFAT_NAME_REAL(fold_array)(fftBuf, gl, M, 0, fftBuf);

        if (p->ptype == LTFAT_RTDGTPHASE_ZERO)
            LTFAT_NAME_REAL(circshift)(fftBuf, M, -(gl / 2), fftBuf );

        LTFAT_NAME_REAL(fftreal_execute)(p->pfft);

        memcpy(cchan, fftBuf_cpx, M2 * sizeof * c);
    }

    return LTFATERR_SUCCESS;
error:
    return status;
}

int
LTFAT_NAME(rtdgtreal_execute_wrapper)(void* p,
                                      const LTFAT_REAL* f, ltfat_int W,
                                      LTFAT_COMPLEX* c)
{
    return LTFAT_NAME(rtdgtreal_execute)((LTFAT_NAME(rtdgtreal_plan)*) p, f, W, c);
}

LTFAT_API int
LTFAT_NAME(rtidgtreal_execute)(const LTFAT_NAME(rtidgtreal_plan)* p,
                               const LTFAT_COMPLEX* c, ltfat_int W,
                               LTFAT_REAL* f)
{
    ltfat_int M, M2, gl;
    LTFAT_REAL* fftBuf;
    LTFAT_COMPLEX* fftBuf_cpx;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(c); CHECKNULL(f);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");

    M = p->M;
    M2 = M / 2 + 1;
    gl = p->gl;
    fftBuf = p->fftBuf;
    fftBuf_cpx = p->fftBuf_cpx;

    for (ltfat_int w = 0; w < W; w++)
    {
        const LTFAT_COMPLEX* cchan = c + w * M2;
        LTFAT_REAL* fchan = f + w * gl;

        memcpy(fftBuf_cpx, cchan, M2 * sizeof * cchan);

        LTFAT_NAME_REAL(ifftreal_execute)(p->pifft);

        if (p->ptype == LTFAT_RTDGTPHASE_ZERO)
            LTFAT_NAME_REAL(circshift)(fftBuf, M, gl / 2, fftBuf );

        if (gl > M)
            LTFAT_NAME_REAL(periodize_array)(fftBuf, M , gl, fftBuf);

        if (p->g)
            for (ltfat_int ii = 0; ii < gl; ii++)
                fftBuf[ii] *= p->g[ii];

        memcpy(fchan, fftBuf, gl * sizeof * fchan);
    }

    return LTFATERR_SUCCESS;
error:
    return status;
}

int
LTFAT_NAME(rtidgtreal_execute_wrapper)(void* p,
                                       const LTFAT_COMPLEX* c, ltfat_int W,
                                       LTFAT_REAL* f)
{
    return LTFAT_NAME(rtidgtreal_execute)((LTFAT_NAME(rtidgtreal_plan)*)p, c, W, f);
}


LTFAT_API int
LTFAT_NAME(rtdgtreal_done)(LTFAT_NAME(rtdgtreal_plan)** p)
{
    LTFAT_NAME(rtdgtreal_plan)* pp;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(*p);

    pp = *p;
    ltfat_safefree(pp->g);
    ltfat_safefree(pp->fftBuf);
    ltfat_safefree(pp->fftBuf_cpx);
    if (pp->pfft) LTFAT_NAME_REAL(fftreal_done)(&pp->pfft);
    if (pp->pifft) LTFAT_NAME_REAL(ifftreal_done)(&pp->pifft);
    ltfat_free(pp);
    pp = NULL;

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(rtidgtreal_done)(LTFAT_NAME(rtidgtreal_plan)** p)
{
    return LTFAT_NAME(rtdgtreal_done)(p);
}


/* DGTREAL processor */
struct LTFAT_NAME(rtdgtreal_processor_state)
{
    LTFAT_NAME(rtdgtreal_processor_callback)*
    processorCallback; //!< Custom processor callback
    void* userdata; //!< Callback data
    LTFAT_NAME(analysis_fifo_state)* fwdfifo;
    LTFAT_NAME(synthesis_fifo_state)* backfifo;
    LTFAT_NAME(rtdgtreal_plan)* fwdplan;
    LTFAT_NAME(rtidgtreal_plan)* backplan;
    LTFAT_NAME(realtocomplextransform)* fwdtra;
    LTFAT_NAME(complextorealtransform)* backtra;
    LTFAT_REAL* buf;
    LTFAT_COMPLEX* fftbufIn;
    LTFAT_COMPLEX* fftbufOut;
    ltfat_int bufLenMax;
    void** garbageBin;
    int garbageBinSize;
    const LTFAT_REAL** inTmp;
    LTFAT_REAL** outTmp;
};


LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_init)(const LTFAT_REAL* ga, ltfat_int gal,
                                     const LTFAT_REAL* gs, ltfat_int gsl,
                                     ltfat_int a, ltfat_int M, ltfat_int numChans,
                                     ltfat_int bufLenMax, ltfat_int procDelay,
                                     LTFAT_NAME(rtdgtreal_processor_state)** pout)
{
    LTFAT_NAME(rtdgtreal_processor_state)* p = NULL;
    ltfat_int glmax;

    int status = LTFATERR_FAILED;
    CHECKNULL(pout);
    CHECK(LTFATERR_BADSIZE, gal > 0, "gla must be positive");
    CHECK(LTFATERR_BADSIZE, gsl > 0, "gls must be positive");

    glmax = gal > gsl ? gal - 1 : gsl - 1;

    CHECK(LTFATERR_BADSIZE, procDelay >= glmax && procDelay <= glmax + bufLenMax,
          "procdelay must be at least the window length at most the bufLenMax");
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive");
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive");
    CHECK(LTFATERR_NOTPOSARG, numChans > 0, "numChans must be positive");
    CHECK(LTFATERR_NOTPOSARG, bufLenMax > 0, "bufLenMax must be positive");
    CHECKMEM( p = LTFAT_NEW(LTFAT_NAME(rtdgtreal_processor_state)) );

    CHECKMEM(
        p->fftbufIn = LTFAT_NAME_COMPLEX(malloc)( numChans * (M / 2 + 1)));

    CHECKMEM(
        p->fftbufOut = LTFAT_NAME_COMPLEX(malloc)( numChans * (M / 2 + 1)));

    CHECKMEM( p->buf = LTFAT_NAME_REAL(malloc)( numChans * gal));
    CHECKMEM( p->inTmp =  LTFAT_NEWARRAY(const LTFAT_REAL*, numChans));
    CHECKMEM( p->outTmp = LTFAT_NEWARRAY(LTFAT_REAL*, numChans));

    CHECKSTATUS(
        LTFAT_NAME(analysis_fifo_init)(bufLenMax + gal, procDelay,
                                        gal, a, numChans, &p->fwdfifo));

    CHECKSTATUS(
        LTFAT_NAME(synthesis_fifo_init)(bufLenMax + gsl, gsl, a, numChans, &p->backfifo));

    CHECKSTATUS( LTFAT_NAME(rtdgtreal_init)(ga, gal, M, LTFAT_RTDGTPHASE_ZERO,
                                            &p->fwdplan));

    CHECKSTATUS( LTFAT_NAME(rtidgtreal_init)(gs, gsl, M,
                 LTFAT_RTDGTPHASE_ZERO, &p->backplan));

    p->fwdtra = &LTFAT_NAME(rtdgtreal_execute_wrapper);
    p->backtra = &LTFAT_NAME(rtidgtreal_execute_wrapper);
    p->bufLenMax = bufLenMax;

    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (p) LTFAT_NAME(rtdgtreal_processor_done)(&p);
    return status;
}

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_reset)(LTFAT_NAME(rtdgtreal_processor_state)* p)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);

    LTFAT_NAME(analysis_fifo_reset)(p->fwdfifo);
    LTFAT_NAME(synthesis_fifo_reset)(p->backfifo);

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_setanaa)(LTFAT_NAME(rtdgtreal_processor_state)*
                                        p, ltfat_int a)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);

    LTFAT_NAME(analysis_fifo_sethop)(p->fwdfifo, a);

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_setsyna)(LTFAT_NAME(rtdgtreal_processor_state)*
                                        p, ltfat_int a)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);

    LTFAT_NAME(synthesis_fifo_sethop)(p->backfifo, a);

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_init_win)(LTFAT_FIRWIN win,
        ltfat_int gl, ltfat_int a, ltfat_int M,
        ltfat_int numChans, ltfat_int bufLenMax, ltfat_int procDelay,
        LTFAT_NAME(rtdgtreal_processor_state)** pout)
{
    LTFAT_NAME(rtdgtreal_processor_state)* p;
    LTFAT_REAL* g = NULL;
    LTFAT_REAL* gd = NULL;
    void** garbageBin = NULL;

    int status = LTFATERR_FAILED;
    CHECKNULL(pout);
    CHECK(LTFATERR_BADSIZE, gl > 0, "gl must be positive");
    CHECK(LTFATERR_NOTPOSARG, a > 0,  "a must be positive");
    CHECK(LTFATERR_NOTPOSARG, M > 0,  "M must be positive");
    CHECK(LTFATERR_NOTPOSARG, numChans > 0, "numChans must be positive");

    CHECKMEM(g = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM(gd = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM(garbageBin = (void**) ltfat_malloc(2 * sizeof(void*)));

    CHECKSTATUS(LTFAT_NAME_REAL(firwin)(win, gl, g));
    CHECKSTATUS(LTFAT_NAME_REAL(gabdual_painless)(g, gl, a, M, gd));
    CHECKSTATUS(LTFAT_NAME(rtdgtreal_processor_init)(g, gl, gd, gl, a, M, numChans,
                bufLenMax, procDelay, pout));

    p = *pout;
    p->garbageBinSize = 2;
    p->garbageBin = garbageBin;
    p->garbageBin[0] = g;
    p->garbageBin[1] = gd;

    return LTFATERR_SUCCESS;
error:
    LTFAT_SAFEFREEALL(g, gd, garbageBin);
    // Also status is now set to the proper value
    return status;
}


LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_setcallback)(
    LTFAT_NAME( rtdgtreal_processor_state)* p,
    LTFAT_NAME(rtdgtreal_processor_callback)* callback,
    void* userdata)
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
LTFAT_NAME(rtdgtreal_processor_execute_compact)(
    LTFAT_NAME(rtdgtreal_processor_state)* p, const LTFAT_REAL* in,
    ltfat_int len, ltfat_int chanNo, LTFAT_REAL* out)
{
    return LTFAT_NAME(rtdgtreal_processor_execute_gen_compact)(
               p, in, len, chanNo, len, out);

}

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_execute_gen_compact)(
    LTFAT_NAME(rtdgtreal_processor_state)* p, const LTFAT_REAL* in,
    ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen, LTFAT_REAL* out)
{
    ltfat_int chanLoc;
    int status2 = LTFATERR_SUCCESS;
    int status = LTFATERR_SUCCESS;

    CHECKNULL(p);
    chanLoc = chanNo > p->fwdfifo->numChans ? p->fwdfifo->numChans : chanNo;

    for (ltfat_int w = 0; w < chanLoc; w++)
    {
        p->inTmp[w] = &in[w * inLen];
        p->outTmp[w] = &out[w * outLen];
    }

    // Clear superfluous channels
    if (chanNo > chanLoc)
    {
        DEBUG("Channel overflow (passed %td, max %td)", chanNo, chanLoc);
        status = LTFATERR_OVERFLOW;

        memset(out + chanLoc * outLen, 0, (chanNo - chanLoc)*outLen * sizeof * out);
    }

    status2 = LTFAT_NAME(rtdgtreal_processor_execute_gen)( p, p->inTmp, inLen,
              chanLoc,
              outLen, p->outTmp);

    if (status2 != LTFATERR_SUCCESS) return status2;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_execute)(
    LTFAT_NAME(rtdgtreal_processor_state)* p,
    const LTFAT_REAL** in, ltfat_int len, ltfat_int chanNo,
    LTFAT_REAL** out)
{
    return LTFAT_NAME(rtdgtreal_processor_execute_gen)( p, in, len, chanNo, len,
            out);
}


LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_execute_gen)(
    LTFAT_NAME(rtdgtreal_processor_state)* p,
    const LTFAT_REAL** in, ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen,
    LTFAT_REAL** out)
{
    int status = LTFATERR_FAILED;
    ltfat_int samplesWritten = 0, samplesRead = 0;
    // Get default processor if none was set
    LTFAT_NAME(rtdgtreal_processor_callback)* processorCallback =
        p->processorCallback;

    // Failing these checks prohibits execution altogether
    CHECKNULL(p); CHECKNULL(in); CHECKNULL(out);
    CHECK(LTFATERR_BADSIZE, inLen >= 0 && outLen >= 0,
          "len must be positive or zero (passed %td and %td)", inLen, outLen);
    CHECK(LTFATERR_BADSIZE, chanNo >= 0,
          "chanNo must be positive or zero (passed %td)", chanNo);

    // Just dont do anything
    if (chanNo == 0 || (inLen == 0 && outLen == 0)) return LTFATERR_SUCCESS;

    if ( chanNo > p->fwdfifo->numChans )
    {
        DEBUG("Channel overflow (passed %td, max %td)", chanNo, p->fwdfifo->numChans);
        status = LTFATERR_OVERFLOW;

        for (ltfat_int w = p->fwdfifo->numChans; w < chanNo; w++)
            memset(out[w], 0, outLen * sizeof * out[w]);

        chanNo = p->fwdfifo->numChans;
    }

    if ( inLen > p->bufLenMax )
    {
        DEBUG("Buffer overflow (passed %td, max %td)", inLen, p->bufLenMax);
        status = LTFATERR_OVERFLOW;
        inLen = p->bufLenMax;
    }

    if ( outLen > p->bufLenMax )
    {
        DEBUG("Buffer overflow (passed %td, max %td)", outLen, p->bufLenMax);
        status = LTFATERR_OVERFLOW;

        for (ltfat_int w = 0; w < chanNo; w++)
            memset(out[w] + p->bufLenMax, 0, (outLen - p->bufLenMax)*sizeof * out[w]);

        outLen = p->bufLenMax;
    }

    if (!processorCallback)
        processorCallback = &LTFAT_NAME(default_rtdgtreal_processor_callback);

    // Write new data
    samplesWritten =
        LTFAT_NAME(analysis_fifo_write)(p->fwdfifo, in, inLen, chanNo);

    // While there is new data in the input fifo
    while ( LTFAT_NAME(analysis_fifo_read)(p->fwdfifo, p->buf) > 0 )
    {
        // Transform
        p->fwdtra((void*)p->fwdplan, p->buf, p->fwdfifo->numChans,
                  p->fftbufIn);

        // Process
        processorCallback(p->userdata, p->fftbufIn, p->fwdplan->M / 2 + 1,
                          p->fwdfifo->numChans, p->fftbufOut);

        // Reconstruct
        p->backtra((void*)p->backplan, p->fftbufOut, p->backfifo->numChans, p->buf);

        // Write (and overlap) to out fifo
        LTFAT_NAME(synthesis_fifo_write)(p->backfifo, p->buf);
    }

    // Read sampples for output
    samplesRead =
        LTFAT_NAME(synthesis_fifo_read)(p->backfifo, outLen, chanNo, out);

    status = LTFATERR_SUCCESS;
error:
    if (status != LTFATERR_SUCCESS) return status;
    // These should never occur, it would mean internal error
    if ( samplesWritten != inLen ) return LTFATERR_OVERFLOW;
    else if ( samplesRead != outLen ) return LTFATERR_UNDERFLOW;
    return status;
}

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_done)(LTFAT_NAME(rtdgtreal_processor_state)** p)
{
    LTFAT_NAME(rtdgtreal_processor_state)* pp;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(*p);

    pp = *p;
    if (pp->fwdfifo) LTFAT_NAME(analysis_fifo_done)(&pp->fwdfifo);
    if (pp->backfifo) LTFAT_NAME(synthesis_fifo_done)(&pp->backfifo);
    if (pp->fwdplan) LTFAT_NAME(rtdgtreal_done)(&pp->fwdplan);
    if (pp->backplan) LTFAT_NAME(rtidgtreal_done)(&pp->backplan);
    LTFAT_SAFEFREEALL(pp->buf, pp->fftbufIn, pp->fftbufOut, pp->inTmp, pp->outTmp );

    if (pp->garbageBinSize)
    {
        for (int ii = 0; ii < pp->garbageBinSize; ii++)
            ltfat_safefree(pp->garbageBin[ii]);

        ltfat_safefree(pp->garbageBin);
    }

    ltfat_free(pp);
    pp = NULL;
    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API void
LTFAT_NAME(default_rtdgtreal_processor_callback)(void* UNUSED(userdata),
        const LTFAT_COMPLEX* in, int M2, int W, LTFAT_COMPLEX* out)
{
    memcpy(out, in, W * M2 * sizeof * in);
}
