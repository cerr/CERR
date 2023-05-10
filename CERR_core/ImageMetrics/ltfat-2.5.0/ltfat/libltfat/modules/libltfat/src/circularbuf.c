#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "circularbuf_private.h"

LTFAT_API int
LTFAT_NAME(block_processor_init)( ltfat_int winLen, ltfat_int hop,
                                  ltfat_int numChans,
                                  ltfat_int bufLenMax, ltfat_int procDelay,
                                  LTFAT_NAME(block_processor_state)** p)
{
    LTFAT_REAL* prebuf = NULL, *postbuf = NULL;
    int status = LTFATERR_FAILED;

    CHECK(LTFATERR_NOTPOSARG, winLen > 0, "winLen must be positive");

    CHECKSTATUS(
        LTFAT_NAME(block_processor_init_withbuffers)(
            winLen, hop, numChans, bufLenMax, procDelay, NULL, NULL, p));

    return LTFATERR_SUCCESS;
error:
    LTFAT_SAFEFREEALL(prebuf, postbuf);
    return status;
}

LTFAT_API int
LTFAT_NAME(block_processor_init_withbuffers)(
    ltfat_int winLen, ltfat_int hop, ltfat_int numChans,
    ltfat_int bufLenMax, ltfat_int procDelay,
    LTFAT_REAL* prebuf, LTFAT_REAL* postbuf,
    LTFAT_NAME(block_processor_state)** pout)
{
    LTFAT_NAME(block_processor_state)* p = NULL;
    int status = LTFATERR_FAILED;
    CHECKNULL(pout);
    CHECK(LTFATERR_BADARG, (prebuf != NULL && postbuf != NULL) ||
          (prebuf == NULL && postbuf == NULL),
          "prebuf and postbuf must either both be NULL or non-NULL");
    CHECK(LTFATERR_NOTPOSARG, winLen > 0,
          "winLen must be positive (passed %td)", winLen);
    CHECK(LTFATERR_NOTPOSARG, numChans > 0,
          "numChans must be positive (passed %td)", numChans);
    CHECK(LTFATERR_NOTPOSARG, bufLenMax > 0,
          "bufLenMax must be positive (passed %td)", bufLenMax);
    CHECK(LTFATERR_NOTPOSARG, procDelay > 0,
          "procDelay must be positive (passed %td)", procDelay);

    CHECKMEM( p = LTFAT_NEW(LTFAT_NAME(block_processor_state)));
    p->bufLenMax = bufLenMax;

    if (prebuf == NULL && postbuf == NULL)
    {
        p->freeBuffers = 1;
        CHECKMEM( p->prebuf  = LTFAT_NAME_REAL(malloc)(winLen * numChans));
        CHECKMEM( p->postbuf = LTFAT_NAME_REAL(malloc)(winLen * numChans));
    }
    else
    {
        p->prebuf = prebuf; p->postbuf = postbuf;
    }

    CHECKMEM( p->inTmp = LTFAT_NEWARRAY(const LTFAT_REAL*, numChans));
    CHECKMEM( p->outTmp = LTFAT_NEWARRAY(LTFAT_REAL*, numChans));

    CHECKSTATUS(
        LTFAT_NAME(analysis_fifo_init)(bufLenMax + winLen, procDelay,
                                       winLen, hop, numChans, &p->fwdfifo));
    CHECKSTATUS(
        LTFAT_NAME(synthesis_fifo_init)(bufLenMax + winLen, winLen, hop,
                                        numChans, &p->backfifo));

    p->prehop = hop; p->posthop = hop;
    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (p) LTFAT_NAME(block_processor_done)( &p);
    return status;
}

LTFAT_API int
LTFAT_NAME(block_processor_execute_compact)(
    LTFAT_NAME(block_processor_state)* p,
    const LTFAT_REAL* in, ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen,
    LTFAT_REAL* out)
{
    ltfat_int chanLoc;
    LTFAT_REAL** outTmpLoc = NULL;
    int status2 = LTFATERR_SUCCESS;
    int status = LTFATERR_SUCCESS;

    CHECKNULL(p);
    chanLoc = chanNo > p->fwdfifo->numChans ? p->fwdfifo->numChans : chanNo;

    for (ltfat_int w = 0; w < chanLoc; w++)
    {
        p->inTmp[w] = &in[w * inLen];
        if (out)
        {
            outTmpLoc = p->outTmp;
            p->outTmp[w] = &out[w * outLen];
        }
    }

    // Clear superfluous channels
    if (chanNo > chanLoc)
    {
        DEBUG("Channel overflow (passed %td, max %td)", chanNo, chanLoc);
        status = LTFATERR_OVERFLOW;

        if (out)
            memset(out + chanLoc * outLen, 0, (chanNo - chanLoc)*outLen * sizeof * out);
    }

    status2 = LTFAT_NAME(block_processor_execute)( p, p->inTmp, inLen,
              chanLoc, outLen, outTmpLoc);

    if (status2 != LTFATERR_SUCCESS) return status2;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(block_processor_execute)(
    LTFAT_NAME(block_processor_state)* p,
    const LTFAT_REAL** in, ltfat_int inLen, ltfat_int chanNo,
    ltfat_int outLen, LTFAT_REAL** out)
{
    int status = LTFATERR_FAILED, callbackstatus = 0;
    ltfat_int samplesWritten = 0, samplesRead = 0;

    // Failing these checks prohibits execution altogether
    CHECKNULL(p); CHECKNULL(in); // CHECKNULL(out);

    CHECK(LTFATERR_CANNOTHAPPEN, p->processorCallback != NULL ||
                                 (p->prewin != NULL && p->postwin != NULL),
          "processor callback is not set" );

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

        if (out)
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

    if ( out && outLen > p->bufLenMax )
    {
        DEBUG("Buffer overflow (passed %td, max %td)", outLen, p->bufLenMax);
        status = LTFATERR_OVERFLOW;

        for (ltfat_int w = 0; w < chanNo; w++)
            memset(out[w] + p->bufLenMax, 0, (outLen - p->bufLenMax)*sizeof * out[w]);

        outLen = p->bufLenMax;
    }

    // Write new data
    samplesWritten =
        LTFAT_NAME(analysis_fifo_write)(p->fwdfifo, in, inLen, chanNo);

    // While there is new data in the input fifo
    while ( LTFAT_NAME(analysis_fifo_read)(p->fwdfifo, p->prebuf) > 0 )
    {
        if (p->prewin)
        {
            for (ltfat_int w = 0; w < p->fwdfifo->numChans; w++)
                for (ltfat_int l = 0; l < p->fwdfifo->winLen; l++)
                    p->prebuf[l + w * p->fwdfifo->numChans] *= p->prewin[l];
        }

        if (out)
        {
            callbackstatus =
                p->processorCallback(p->userdata, p->prebuf, p->fwdfifo->winLen,
                                     p->fwdfifo->numChans, p->postbuf);

            if (p->postwin)
            {
                for (ltfat_int w = 0; w < p->fwdfifo->numChans; w++)
                    for (ltfat_int l = 0; l < p->fwdfifo->winLen; l++)
                        p->postbuf[l + w * p->fwdfifo->numChans] *= p->postwin[l];
            }

            LTFAT_NAME(synthesis_fifo_write)(p->backfifo, p->postbuf);
        }
        else
        {
            callbackstatus =
                p->processorCallback(p->userdata, p->prebuf, p->fwdfifo->winLen,
                                     p->fwdfifo->numChans, NULL);
        }

        if (callbackstatus < 0)
            CHECKSTATUS(LTFATERR_FAILED);
    }

    // Read sampples for output
    if (out)
    {
        samplesRead =
            LTFAT_NAME(synthesis_fifo_read)(p->backfifo, outLen, chanNo, out);
    }

    LTFAT_NAME(block_processor_advanceby)( p, samplesWritten, samplesRead);
    LTFAT_NAME(analysis_fifo_sethop)(p->fwdfifo, p->prehop);
    LTFAT_NAME(synthesis_fifo_sethop)(p->backfifo, p->posthop);
    status = LTFATERR_SUCCESS;
error:
    if (status != LTFATERR_SUCCESS) return status;
    // These should never occur, it would mean internal error
    if ( samplesWritten != inLen ) return LTFATERR_OVERFLOW;
    else if ( out && samplesRead != outLen ) return LTFATERR_UNDERFLOW;
    return status;

}



LTFAT_API int
LTFAT_NAME(block_processor_reset)( LTFAT_NAME(block_processor_state)* p)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);

    LTFAT_NAME(analysis_fifo_reset)(p->fwdfifo);
    LTFAT_NAME(synthesis_fifo_reset)(p->backfifo);
    p->in_pos = 0; p->out_pos = 0;
    p->in_in_out_offset = 0.0;
    p->out_in_in_offset = 0.0;

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API size_t
LTFAT_NAME(block_processor_nextinlen)(LTFAT_NAME(block_processor_state)* p,
                                      size_t Lout)
{
    double stretch = ((double) (p->backfifo->hop)) / p->fwdfifo->hop;
    return (size_t) round(Lout / stretch + p->out_in_in_offset);
}

LTFAT_API size_t
LTFAT_NAME(block_processor_nextoutlen)(LTFAT_NAME(block_processor_state)* p,
                                       size_t Lin)
{
    double stretch = ((double) (p->backfifo->hop)) / p->fwdfifo->hop;
    return (size_t) round(Lin * stretch + p->in_in_out_offset);
}

void
LTFAT_NAME(block_processor_advanceby)(
    LTFAT_NAME(block_processor_state)* p,
    size_t Lin, size_t Lout)
{
    double stretch = ((double) (p->backfifo->hop)) / p->fwdfifo->hop;

    p->in_pos += Lin;
    p->out_pos += Lout;

    p->in_in_out_offset += Lin * stretch;
    p->in_in_out_offset -= Lout;

    p->out_in_in_offset += Lout / stretch;
    p->out_in_in_offset -= Lin;
}

LTFAT_API int
LTFAT_NAME(block_processor_done)( LTFAT_NAME(block_processor_state)** p)
{
    LTFAT_NAME(block_processor_state)* pp;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(*p);

    pp = *p;
    if (pp->fwdfifo) LTFAT_NAME(analysis_fifo_done)(&pp->fwdfifo);
    if (pp->backfifo) LTFAT_NAME(synthesis_fifo_done)(&pp->backfifo);
    if (pp->freeBuffers)
    {
        LTFAT_SAFEFREEALL(pp->prebuf, pp->postbuf);
    }
    LTFAT_SAFEFREEALL(pp->prewin, pp->postwin, pp->inTmp, pp->outTmp);

    ltfat_free(pp); pp = NULL;
    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(block_processor_setprehop)(
    LTFAT_NAME(block_processor_state)* p, ltfat_int hop)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, hop > 0 , "Hop must be greater than 0");
    p->prehop = hop;
    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(block_processor_setposthop)(
    LTFAT_NAME(block_processor_state)* p, ltfat_int hop)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, hop > 0 , "Hop must be greater than 0");
    p->posthop = hop;
    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(block_processor_setfirwin)(
    LTFAT_NAME(block_processor_state)* p, LTFAT_FIRWIN win, int do_prewin)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);

    if (p->prewin == NULL)
        CHECKMEM( p->prewin = LTFAT_NAME_REAL(malloc)(p->fwdfifo->winLen));

    CHECKSTATUS(LTFAT_NAME_REAL(firwin)(win, p->fwdfifo->winLen, p->prewin));
    CHECKSTATUS(LTFAT_NAME(block_processor_setwin)(p, p->prewin, do_prewin));

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(block_processor_setwin)(
    LTFAT_NAME(block_processor_state)* p, LTFAT_REAL g[], int do_prewin)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);

    if (g == NULL)
    {
        ltfat_safefree(p->prewin);
        ltfat_safefree(p->postwin);
        p->prewin = NULL;
        p->postwin = NULL;
    }
    else
    {
        if (p->prewin == NULL)
            CHECKMEM( p->prewin = LTFAT_NAME_REAL(malloc)(p->fwdfifo->winLen));
        if (p->postwin == NULL)
            CHECKMEM( p->postwin = LTFAT_NAME_REAL(malloc)(p->backfifo->winLen));

        if (do_prewin)
        {
            if (g != p->prewin)
                memcpy(p->prewin, g, p->fwdfifo->winLen * sizeof * g);

            LTFAT_NAME(gabdual_painless)( p->prewin, p->fwdfifo->winLen,
                    p->backfifo->hop, p->fwdfifo->winLen, p->postwin);

            for (ltfat_int l = 0; l < p->fwdfifo->winLen; l++)
                p->postwin[l] *= p->fwdfifo->winLen;
        }
        else
        {
            memcpy(p->postwin, g, p->backfifo->winLen * sizeof * g);
            LTFAT_NAME(gabdual_painless)( p->postwin, p->backfifo->winLen,
                    p->fwdfifo->hop, p->fwdfifo->winLen, p->prewin);

            for (ltfat_int l = 0; l < p->fwdfifo->winLen; l++)
                p->prewin[l] *= p->fwdfifo->winLen;
        }

        LTFAT_NAME_REAL(fftshift)(p->prewin, p->fwdfifo->winLen, p->prewin);
        LTFAT_NAME_REAL(fftshift)(p->postwin, p->backfifo->winLen, p->postwin);
    }
    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(block_processor_setprebufchanstride)( LTFAT_NAME(
            block_processor_state)* p, ltfat_int stride)
{
    return LTFAT_NAME(analysis_fifo_setreadchanstride)(p->fwdfifo, stride);
}

LTFAT_API int
LTFAT_NAME(block_processor_setpostbufchanstride)( LTFAT_NAME(
            block_processor_state)* p, ltfat_int stride)
{
    return LTFAT_NAME(synthesis_fifo_setwritechanstride)( p->backfifo, stride);
}

LTFAT_API int
LTFAT_NAME(block_processor_setcallback)(
    LTFAT_NAME(block_processor_state)* p,
    LTFAT_NAME(block_processor_callback)* callback, void* userdata)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    p->processorCallback = callback;
    p->userdata = userdata;

    return LTFATERR_SUCCESS;
error:
    return status;
}

/* FWD FIFO */

LTFAT_API int
LTFAT_NAME(analysis_fifo_init)(ltfat_int fifoLen, ltfat_int procDelay,
                               ltfat_int winLen, ltfat_int hop, ltfat_int numChans,
                               LTFAT_NAME(analysis_fifo_state)** pout)
{
    LTFAT_NAME(analysis_fifo_state)* p = NULL;

    int status = LTFATERR_FAILED;
    CHECK(LTFATERR_NOTPOSARG, fifoLen > 0, "fifoLen must be positive");
    CHECK(LTFATERR_NOTPOSARG, winLen > 0, "winLen must be positive");
    CHECK(LTFATERR_NOTPOSARG, hop > 0, "hop must be positive");
    CHECK(LTFATERR_NOTPOSARG, numChans > 0, "numChans must be positive");
    CHECK(LTFATERR_BADARG, procDelay >= winLen - 1 , "procDelay must be positive");
    CHECK(LTFATERR_BADARG, fifoLen > winLen + 1,
          "fifoLen must be bugger than winLen+1");

    CHECKMEM(p = LTFAT_NEW(LTFAT_NAME(analysis_fifo_state)) );
    CHECKMEM(p->buf = LTFAT_NAME_REAL(calloc)( numChans * (fifoLen + 1)));

    p->bufLen = fifoLen + 1;
    p->hop = hop; p->winLen = winLen; p->readIdx = fifoLen + 1 - (procDelay);
    p->numChans = numChans;
    p->readchanstride = winLen;

    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (p) LTFAT_NAME(analysis_fifo_done)(&p);
    return status;
}

LTFAT_API int
LTFAT_NAME(analysis_fifo_done)(LTFAT_NAME(analysis_fifo_state)** p)
{
    LTFAT_NAME(analysis_fifo_state)* pp;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;
    ltfat_safefree(pp->buf);
    ltfat_free(pp);
    pp = NULL;

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(analysis_fifo_sethop)(LTFAT_NAME(analysis_fifo_state)* p,
                                 ltfat_int hop)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, hop > 0, "hop must be positive");

    p->hop = hop;

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(analysis_fifo_setreadchanstride)(LTFAT_NAME(analysis_fifo_state)* p,
        ltfat_int stride)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, stride > 0, "stride must be positive");

    p->readchanstride = stride;

    return LTFATERR_SUCCESS;
error:
    return status;
}


LTFAT_API int
LTFAT_NAME(analysis_fifo_reset)(LTFAT_NAME(analysis_fifo_state)* p)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);

    memset(p->buf, 0, p->numChans * p->bufLen * sizeof * p->buf);

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API ltfat_int
LTFAT_NAME(analysis_fifo_write)(LTFAT_NAME(analysis_fifo_state)* p,
                                const LTFAT_REAL** buf, ltfat_int bufLen, ltfat_int W)
{
    ltfat_int Wact, freeSpace, toWrite, valid, over, endWriteIdx;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(buf);
    CHECK(LTFATERR_NOTPOSARG, bufLen >= 0, "bufLen must be positive.");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive.");

    if ( bufLen == 0 ) return 0;

    for (ltfat_int w = 0; w < W; w++)
        CHECKNULL(buf[w]);


    freeSpace = p->readIdx - p->writeIdx - 1;
    if (freeSpace < 0) freeSpace += p->bufLen;

    // CHECK(LTFATERR_OVERFLOW, freeSpace, "FIFO owerflow");

    Wact = p->numChans < W ? p->numChans : W;

    toWrite = bufLen > freeSpace ? freeSpace : bufLen;
    valid = toWrite;
    over = 0;

    endWriteIdx = p->writeIdx + toWrite;

    if (endWriteIdx > p->bufLen)
    {
        valid = p->bufLen - p->writeIdx;
        over = endWriteIdx - p->bufLen;
    }

    if (valid > 0)
    {
        for (ltfat_int w = 0; w < p->numChans; w++)
        {
            LTFAT_REAL* pbufchan = p->buf + w * p->bufLen + p->writeIdx;
            if (w < Wact)
                memcpy(pbufchan, buf[w], valid * sizeof * p->buf );
            else
                memset(pbufchan, 0, valid * sizeof * p->buf );
        }
    }
    if (over > 0)
    {
        for (ltfat_int w = 0; w < Wact; w++)
        {
            LTFAT_REAL* pbufchan = p->buf + w * p->bufLen;
            if (w < Wact)
                memcpy(pbufchan, buf[w] + valid, over * sizeof * p->buf);
            else
                memset(pbufchan, 0,  over * sizeof * p->buf);
        }
    }
    p->writeIdx = ( p->writeIdx + toWrite ) % p->bufLen;

    return toWrite;
error:
    return status;
}

LTFAT_API ltfat_int
LTFAT_NAME(analysis_fifo_read)(LTFAT_NAME(analysis_fifo_state)* p,
                               LTFAT_REAL* buf)
{
    ltfat_int available, toRead, valid, over, endReadIdx;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(buf);

    available = p->writeIdx - p->readIdx;
    if (available < 0) available += p->bufLen;

    // CHECK(LTFATERR_UNDERFLOW, available >= p->winLen, "FIFO underflow");
    // p->hop can actually be larger than p->winLen
    if (available < p->winLen || available < p->hop) return 0;

    toRead = p->winLen;

    valid = toRead;
    over = 0;

    endReadIdx = p->readIdx + valid;

    if (endReadIdx > p->bufLen)
    {
        valid = p->bufLen - p->readIdx;
        over = endReadIdx - p->bufLen;
    }

    if (valid > 0)
    {
        for (ltfat_int w = 0; w < p->numChans; w++)
        {
            LTFAT_REAL* pbufchan = p->buf + w * p->bufLen + p->readIdx;
            memcpy(buf + w * p->readchanstride, pbufchan, valid * sizeof * p->buf );
        }
    }
    if (over > 0)
    {
        for (ltfat_int w = 0; w < p->numChans; w++)
        {
            memcpy(buf + valid + w * p->readchanstride, p->buf + w * p->bufLen,
                   over * sizeof * p->buf);
        }
    }

    // Only advance by hop
    p->readIdx = ( p->readIdx + p->hop ) % p->bufLen;

    return toRead;
error:
    return status;
}

/* BACK FIFO */




LTFAT_API int
LTFAT_NAME(synthesis_fifo_init)(ltfat_int fifoLen, ltfat_int winLen,
                                ltfat_int hop, ltfat_int numChans,
                                LTFAT_NAME(synthesis_fifo_state)** pout)
{
    LTFAT_NAME(synthesis_fifo_state)* p = NULL;

    int status = LTFATERR_FAILED;
    CHECK(LTFATERR_NOTPOSARG, fifoLen > 0, "fifoLen must be positive");
    CHECK(LTFATERR_NOTPOSARG, winLen > 0, "winLen must be positive");
    CHECK(LTFATERR_NOTPOSARG, hop > 0, "hop must be positive");
    CHECK(LTFATERR_NOTPOSARG, numChans > 0, "numChans must be positive");
    CHECK(LTFATERR_BADARG , fifoLen > winLen + 1,
          "fifoLen must be bugger than winLen+1");

    CHECKMEM( p = LTFAT_NEW( LTFAT_NAME(synthesis_fifo_state) ));
    CHECKMEM( p->buf = LTFAT_NAME_REAL(calloc)( numChans * (fifoLen + winLen + 1)));
    p->hop = hop; p->winLen = winLen; p->numChans = numChans;
    p->bufLen = fifoLen + winLen + 1;
    p->writechanstride = winLen;

    *pout = p;
    return LTFATERR_SUCCESS;
error:
    if (p) LTFAT_NAME(synthesis_fifo_done)(&p);
    return status;
}

LTFAT_API int
LTFAT_NAME(synthesis_fifo_reset)(LTFAT_NAME(synthesis_fifo_state)* p)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);

    memset(p->buf, 0, p->numChans * p->bufLen * sizeof * p->buf);

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(synthesis_fifo_setwritechanstride)(LTFAT_NAME(
            synthesis_fifo_state)* p,
        ltfat_int stride)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, stride > 0, "stride must be positive");

    p->writechanstride = stride;

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(synthesis_fifo_sethop)(LTFAT_NAME(synthesis_fifo_state)* p,
                                  ltfat_int hop)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    CHECK(LTFATERR_NOTPOSARG, hop > 0, "hop must be positive");

    p->hop = hop;

    return LTFATERR_SUCCESS;
error:
    return status;
}


LTFAT_API int
LTFAT_NAME(synthesis_fifo_done)(LTFAT_NAME(synthesis_fifo_state)** p)
{
    LTFAT_NAME(synthesis_fifo_state)* pp;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;
    ltfat_safefree(pp->buf);
    ltfat_free(pp);
    pp = NULL;

    return LTFATERR_SUCCESS;
error:
    return status;
}

LTFAT_API ltfat_int
LTFAT_NAME(synthesis_fifo_write)(LTFAT_NAME(synthesis_fifo_state)* p,
                                 const LTFAT_REAL* buf)
{
    ltfat_int freeSpace, toWrite, valid, over, endWriteIdx;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(buf);

    freeSpace = p->readIdx - p->writeIdx - 1;
    if (freeSpace < 0) freeSpace += p->bufLen;

    // CHECK(LTFATERR_OVERFLOW, freeSpace >= p->winLen, "FIFO overflow");
    if (freeSpace < p->winLen) return 0;

    toWrite = p->winLen;
    valid = toWrite;
    over = 0;

    endWriteIdx = p->writeIdx + toWrite;

    if (endWriteIdx > p->bufLen)
    {
        valid = p->bufLen - p->writeIdx;
        over = endWriteIdx - p->bufLen;
    }

    if (valid > 0)
    {
        for (ltfat_int w = 0; w < p->numChans; w++)
        {
            LTFAT_REAL* pbufchan = p->buf + p->writeIdx + w * p->bufLen;
            const LTFAT_REAL* bufchan = buf + w * p->writechanstride;
            for (ltfat_int ii = 0; ii < valid; ii++)
                pbufchan[ii] += bufchan[ii];
        }
    }
    if (over > 0)
    {
        for (ltfat_int w = 0; w < p->numChans; w++)
        {
            LTFAT_REAL* pbufchan = p->buf + w * p->bufLen;
            const LTFAT_REAL* bufchan = buf + valid + w * p->writechanstride;
            for (ltfat_int ii = 0; ii < over; ii++)
                pbufchan[ii] += bufchan[ii];
        }
    }

    p->writeIdx = ( p->writeIdx + p->hop ) % p->bufLen;

    return toWrite;
error:
    return status;
}

LTFAT_API ltfat_int
LTFAT_NAME(synthesis_fifo_read)(LTFAT_NAME(synthesis_fifo_state)* p,
                                ltfat_int bufLen, ltfat_int W,
                                LTFAT_REAL** buf)
{
    ltfat_int available, toRead, valid, over, endReadIdx;
    int status = LTFATERR_FAILED;
    CHECKNULL(p); CHECKNULL(buf);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive.");
    CHECK(LTFATERR_NOTPOSARG, bufLen >= 0, "bufLen must be positive.");
    if (bufLen == 0) return 0;

    for (ltfat_int w = 0; w < W; w++) CHECKNULL(buf[w]);


    available = p->writeIdx - p->readIdx;
    if (available < 0) available += p->bufLen;

    // CHECK(LTFATERR_UNDERFLOW, available, "FIFO underflow");

    toRead = available < bufLen ? available : bufLen;

    valid = toRead;
    over = 0;

    endReadIdx = p->readIdx + valid;

    if (endReadIdx > p->bufLen)
    {
        valid = p->bufLen - p->readIdx;
        over = endReadIdx - p->bufLen;
    }

    // Set the just read samples to zero so that the values are not used in
    // write again
    if (valid > 0)
    {
        for (ltfat_int w = 0; w < W; w++)
        {
            LTFAT_REAL* pbufchan = p->buf + p->readIdx + w * p->bufLen;
            memcpy(buf[w], pbufchan, valid * sizeof * p->buf);
            memset(pbufchan, 0, valid * sizeof * p->buf);
        }
    }
    if (over > 0)
    {
        for (ltfat_int w = 0; w < W; w++)
        {
            LTFAT_REAL* pbufchan = p->buf + w * p->bufLen;
            memcpy(buf[w] + valid, pbufchan, over * sizeof * p->buf);
            memset(pbufchan, 0, over * sizeof * p->buf);
        }
    }

    p->readIdx = ( p->readIdx + toRead ) % p->bufLen;

    return toRead;
error:
    return status;
}
