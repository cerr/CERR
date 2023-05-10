#include "phaseret/rtisila.h"
#include "phaseret/utils.h"
#include "ltfat/macros.h"
#include "ltfat/thirdparty/fftw3.h"

struct PHASERET_NAME(rtisilaupdate_plan)
{
    LTFAT_REAL* frame;                 //!< Time domain buffer
    LTFAT_COMPLEX* fftframe;           //!< Frequency domain buffer
    LTFAT_NAME(fftreal_plan)* fwdp;   //!< Real FFT plan
    LTFAT_NAME(ifftreal_plan)* backp; //!< Real IFFT plan
    const LTFAT_REAL* g;
    const LTFAT_REAL* gd;
    const LTFAT_REAL* specg1;
    const LTFAT_REAL* specg2;
    ltfat_int gl;
    ltfat_int M;
    ltfat_int a;
};

struct PHASERET_NAME(rtisila_state)
{
    PHASERET_NAME(rtisilaupdate_plan) * uplan;
    ltfat_int maxLookahead;
    ltfat_int lookahead;
    ltfat_int lookback;
    ltfat_int maxit;
    ltfat_int W;
    LTFAT_REAL* frames; //!< Buffer for time-domain frames
    LTFAT_REAL* s;      //!< Buffer for target magnitude
    void** garbageBin;
    ltfat_int garbageBinSize;
};

PHASERET_API int
PHASERET_NAME(rtisila_set_lookahead)(
    PHASERET_NAME(rtisila_state) * p, ltfat_int lookahead)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);
    CHECK(LTFATERR_BADARG, lookahead >= 0 && lookahead <= p->maxLookahead,
          "lookahead can only be in range [0-%d] (passed %d).", p->maxLookahead,
          lookahead);

    p->lookahead = lookahead;
error:
    return status;
}

void
PHASERET_NAME(overlaynthframe)(const LTFAT_REAL* frames, ltfat_int gl,
                               ltfat_int N, ltfat_int a, ltfat_int n, LTFAT_REAL* frame)
{
    // Copy n-th frame
    memcpy(frame, frames + gl * n, gl * sizeof * frame);

    // Overlap frames n+1 ... N-1 or until there is overlap
    for (ltfat_int ii = n + 1; ii < N; ii++)
    {
        ltfat_int jj = (ii - n) * a;
        ltfat_int nSamp = gl - jj;

        if (nSamp <= 0)
            break;

        const LTFAT_REAL* framestmp = frames + gl * ii;

        for (ltfat_int kk = 0; kk < nSamp; kk++)
            frame[jj + kk] += framestmp[kk];
    }

    // Overlap frames n-1 ... 0, or until there is no overlap
    for (ltfat_int ii = n - 1; ii >= 0; ii--)
    {
        ltfat_int jj = (n - ii) * a ;
        ltfat_int nSamp = gl - jj;

        if (nSamp <= 0)
            break;

        const LTFAT_REAL* framestmp = frames + gl * ii;

        for (ltfat_int kk = 0; kk < nSamp; kk++)
            frame[kk] += framestmp[jj + kk];
    }
}

void
PHASERET_NAME(rtisilaoverlaynthframe)(PHASERET_NAME( rtisilaupdate_plan) * p,
                                      const LTFAT_REAL* frames,
                                      const LTFAT_REAL* g,
                                      ltfat_int n, ltfat_int N)
{
    ltfat_int M = p->M;
    ltfat_int gl = p->gl;
    ltfat_int a = p->a;

    PHASERET_NAME(overlaynthframe)(frames, gl, N, a, n, p->frame);

    /* // Copy n-th frame */
    /* memcpy(p->frame, frames + gl * n, M * sizeof * p->frame); */
    /*  */
    /* // Overlap frames n+1 ... N-1 or until there is overlap */
    /* for (ltfat_int ii = n + 1; ii < N; ii++) */
    /* { */
    /*     ltfat_int jj = (ii - n) * a; */
    /*     ltfat_int nSamp = gl - jj; */
    /*  */
    /*     if (nSamp <= 0) break; */
    /*  */
    /*     const double* framestmp = frames + gl * ii; */
    /*  */
    /*     for (ltfat_int kk = 0; kk < nSamp; kk++) */
    /*         p->frame[jj + kk] += framestmp[kk]; */
    /* } */
    /*  */
    /* // Overlap frames n-1 ... 0, or until there is no overlap */
    /* for (ltfat_int ii = n - 1; ii >= 0; ii--) */
    /* { */
    /*     ltfat_int jj = (n - ii) * a; */
    /*     ltfat_int nSamp = gl - jj; */
    /*  */
    /*     if (nSamp <= 0) break; */
    /*  */
    /*     const double* framestmp = frames + gl * ii; */
    /*  */
    /*     for (ltfat_int kk = 0; kk < nSamp; kk++) */
    /*         p->frame[kk] += framestmp[jj + kk]; */
    /* } */

    // Multiply with analysis window
    for (ltfat_int m = 0; m < gl; m++)
        p->frame[m] *= g[m];

    // Set remaining samples to zeros
    for (ltfat_int m = gl; m < M; m++)
        p->frame[m] = 0.0;
}

void
PHASERET_NAME(rtisilaphaseupdate)(PHASERET_NAME(rtisilaupdate_plan) * p,
                                  const LTFAT_REAL* sframe, LTFAT_REAL* frameupd, LTFAT_COMPLEX* c)
{
    ltfat_int M = p->M;
    ltfat_int gl = p->gl;
    ltfat_int M2 = M / 2 + 1;

    LTFAT_NAME_REAL(circshift)(p->frame, M, -(gl / 2), p->frame);

    // FFTREAL
    LTFAT_NAME(fftreal_execute)(p->fwdp);

    PHASERET_NAME(force_magnitude)(p->fftframe, sframe, M2, p->fftframe);

    // Copy before it gets overwritten
    if (c) memcpy(c, p->fftframe, M2 * sizeof * c);

    // IFFTREAL // Overwrites input p->fftframe
    LTFAT_NAME(ifftreal_execute)(p->backp);

    LTFAT_NAME_REAL(circshift)(p->frame, M, (gl / 2), p->frame);

    // Multiply with the synthesis window
    for (ltfat_int m = 0; m < gl; m++)
        p->frame[m] *= p->gd[m];

    // Set remaining samples to zeros
    for (ltfat_int m = gl; m < M; m++)
        p->frame[m] = 0;

    // Copy to the output
    memcpy(frameupd, p->frame, gl * sizeof * frameupd);
}

void
PHASERET_NAME(rtisilaphaseupdatesyn)(PHASERET_NAME(rtisilaupdate_plan) * p,
                                     const LTFAT_COMPLEX* c, LTFAT_REAL* frameupd)
{
    ltfat_int M = p->M;
    ltfat_int gl = p->gl;
    ltfat_int M2 = M / 2 + 1;

    memcpy(p->fftframe, c , M2 * sizeof * p->fftframe );
    LTFAT_NAME(ifftreal_execute)(p->backp);
    LTFAT_NAME_REAL(circshift)(p->frame, M, (gl / 2), p->frame);

    // Multiply with the synthesis window
    for (ltfat_int m = 0; m < gl; m++)
        p->frame[m] *= p->gd[m];

    // Set remaining samples to zeros
    for (ltfat_int m = gl; m < M; m++)
        p->frame[m] = 0;

    memcpy(frameupd, p->frame, gl * sizeof * frameupd);
}


PHASERET_API int
PHASERET_NAME(rtisilaupdate_init)(const LTFAT_REAL* g,
                                  const LTFAT_REAL* specg1, const LTFAT_REAL* specg2, const LTFAT_REAL* gd,
                                  ltfat_int gl, ltfat_int a, ltfat_int M,
                                  PHASERET_NAME(rtisilaupdate_plan) * *pout)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(rtisilaupdate_plan)* p = NULL;
    ltfat_int M2 = M / 2 + 1;

    CHECKMEM(p = (PHASERET_NAME(rtisilaupdate_plan)*)ltfat_calloc(1, sizeof * p));
    p->M = M;
    p->a = a;
    p->g = g;
    p->gd = gd;
    p->specg1 = specg1;
    p->specg2 = specg2;
    p->gl = gl;

    // Real input array for FFTREAL and output array for IFFTREAL
    CHECKMEM(p->frame = LTFAT_NAME_REAL(malloc)(M));
    // Complex output array for FFTREAL and input array to IFFTREAL
    CHECKMEM(p->fftframe = LTFAT_NAME_COMPLEX(malloc)(M2));

    // FFTREAL plan
    LTFAT_NAME(fftreal_init)(M, 1, p->frame, p->fftframe, FFTW_MEASURE, &p->fwdp);
    CHECKINIT(p->fwdp, "FFTW plan failed");

    // IFFTREAL plan
    LTFAT_NAME(ifftreal_init)(M, 1, p->fftframe, p->frame, FFTW_MEASURE, &p->backp);
    CHECKINIT(p->backp, "FFTW plan failed");

    *pout = p;
    return status;
error:
    if (p) PHASERET_NAME(rtisilaupdate_done)(&p);
    return status;
}

PHASERET_API int
PHASERET_NAME(rtisilaupdate_done)(PHASERET_NAME(rtisilaupdate_plan) * *p)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(rtisilaupdate_plan) * pp;
    CHECKNULL(p);
    CHECKNULL(*p);

    pp = *p;
    if (pp->frame) ltfat_free(pp->frame);
    if (pp->fftframe) ltfat_free(pp->fftframe);
    if (pp->fwdp) LTFAT_NAME(fftreal_done)(&pp->fwdp);
    if (pp->backp) LTFAT_NAME(ifftreal_done)(&pp->backp);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

PHASERET_API void
PHASERET_NAME(rtisilaupdate_execute)(
    PHASERET_NAME(rtisilaupdate_plan) * p, const LTFAT_REAL* frames, ltfat_int N,
    const LTFAT_REAL* s, ltfat_int lookahead, ltfat_int maxit, LTFAT_REAL* frames2,
    LTFAT_COMPLEX* c)
{
    ltfat_int lookback = N - lookahead - 1;
    ltfat_int M = p->M;
    ltfat_int gl = p->gl;
    ltfat_int M2 = M / 2 + 1;

    // If we are not working inplace ...
    if (frames != frames2)
        memcpy(frames2, frames, gl * N * sizeof * frames);

    for (ltfat_int it = 0; it < maxit; it++)
    {
        for (ltfat_int nback = lookahead; nback >= 0; nback--)
        {
            ltfat_int indx = lookback + nback;

            // Newest lookahead frame is treated differently
            if (nback == lookahead)
                if (it == 0)
                    PHASERET_NAME(rtisilaoverlaynthframe)(p, frames2, p->specg1, indx, N);
                else
                    PHASERET_NAME(rtisilaoverlaynthframe)(p, frames2, p->specg2, indx, N);
            else
                PHASERET_NAME(rtisilaoverlaynthframe)(p, frames2, p->g, indx, N);

            if (nback == 0 && it == (maxit - 1))
                PHASERET_NAME(rtisilaphaseupdate)(p, s + nback * M2, frames2 +  indx * gl, c);
            else
                PHASERET_NAME(rtisilaphaseupdate)(p, s + nback * M2, frames2 +  indx * gl,
                                                  NULL);
        }
    }
}

void
PHASERET_NAME(rtisilaupdate)(const LTFAT_REAL* frames, const LTFAT_REAL* g,
                             const LTFAT_REAL* specg1, const LTFAT_REAL* specg2, const LTFAT_REAL* gd,
                             ltfat_int gl, ltfat_int a, ltfat_int M, ltfat_int N, const LTFAT_REAL* s,
                             ltfat_int lookahead, ltfat_int maxit, LTFAT_REAL* frames2)
{
    PHASERET_NAME(rtisilaupdate_plan)* p = NULL;
    PHASERET_NAME(rtisilaupdate_init)(g, specg1, specg2, gd, gl, a, M, &p);
    PHASERET_NAME(rtisilaupdate_execute)(p, frames, N, s, lookahead, maxit, frames2,
                                         NULL);
    PHASERET_NAME(rtisilaupdate_done)(&p);
}

void
PHASERET_NAME(rtisilaupdatecoef)(const LTFAT_REAL* frames,
                                 const LTFAT_REAL* g,
                                 const LTFAT_REAL* specg1, const LTFAT_REAL* specg2, const LTFAT_REAL* gd,
                                 ltfat_int gl, ltfat_int a, ltfat_int M, ltfat_int N, const LTFAT_REAL* s,
                                 ltfat_int lookahead, ltfat_int maxit, LTFAT_REAL* frames2, LTFAT_COMPLEX* c)
{
    PHASERET_NAME(rtisilaupdate_plan)* p = NULL;
    PHASERET_NAME(rtisilaupdate_init)(g, specg1, specg2, gd, gl, a, M, &p);
    PHASERET_NAME(rtisilaupdate_execute)(p, frames, N, s, lookahead, maxit, frames2,
                                         c);
    PHASERET_NAME(rtisilaupdate_done)(&p);
}

PHASERET_API int
PHASERET_NAME(rtisila_reset)(PHASERET_NAME(rtisila_state) * p,
                             const LTFAT_REAL** sinit)
{
    ltfat_int N, W, gl, M2;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);

    N = p->lookback + 1 + p->maxLookahead;
    W = p->W;
    M2 = p->uplan->M / 2 + 1;
    gl = p->uplan->gl;

    memset(p->s, 0, M2 * (1 + p->maxLookahead) * W * sizeof * p->s);
    memset(p->frames, 0, gl * N * W * sizeof * p->frames);

    if (sinit)
        for (ltfat_int w = 0; w < W; w++)
            if (sinit[w])
                memcpy(p->s + M2 + w * (1 + p->maxLookahead)*M2, sinit[w],
                       M2 * p->lookahead * sizeof * p->s );

error:
    return status;
}

PHASERET_API int
PHASERET_NAME(rtisila_init)(const LTFAT_REAL* g, ltfat_int gl,
                            ltfat_int W, ltfat_int a, ltfat_int M, ltfat_int lookahead, ltfat_int maxit,
                            PHASERET_NAME(rtisila_state) * *pout)
{
    int status = LTFATERR_SUCCESS;

    PHASERET_NAME(rtisila_state)* p = NULL;
    LTFAT_REAL* wins = NULL;

    ltfat_int M2, lookback, winsNo, maxLookahead;
    CHECKNULL(g);
    CHECKNULL(pout);
    CHECK(LTFATERR_BADSIZE, gl > 0, "gl must be positive (passed %d)", gl);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive (passed %d)", W);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive (passed %d)", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive (passed %d)", M);
    CHECK(LTFATERR_BADARG, lookahead >= 0, "lookahead >=0 failed (passed %d)",
          lookahead);
    CHECK(LTFATERR_NOTPOSARG, maxit > 0, "maxit must be positive (passed %d)",
          maxit);

    M2 = M / 2 + 1;
    lookback = (ltfat_int)( ceil(((LTFAT_REAL)gl) / a) - 1 );
    winsNo = (2 * lookback + 1);
    maxLookahead = lookahead;
    CHECKMEM(p = (PHASERET_NAME(rtisila_state)*)ltfat_calloc(1, sizeof * p));

    CHECKSTATUS(
        PHASERET_NAME(rtisilaupdate_init)(NULL, NULL, NULL, NULL, gl, a, M, &p->uplan));

    CHECKMEM(p->uplan->g = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM(p->uplan->gd = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM(p->uplan->specg1 = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM(p->uplan->specg2 = LTFAT_NAME_REAL(malloc)(gl));

    CHECKSTATUS(LTFAT_NAME(gabdual_painless)(g, gl, a, M,
                (LTFAT_REAL*)p->uplan->gd));

    LTFAT_NAME(fftshift)(g, gl, (LTFAT_REAL*)p->uplan->g);
    LTFAT_NAME(fftshift)(p->uplan->gd, gl, (LTFAT_REAL*)p->uplan->gd);

    CHECKMEM(wins = LTFAT_NAME_REAL(malloc)(gl * winsNo));

    // Spec2
    LTFAT_NAME(periodize_array)(p->uplan->gd, gl, gl * winsNo, wins);
    PHASERET_NAME(overlaynthframe)(wins, gl, winsNo, a, 0,
                                   (LTFAT_REAL*)p->uplan->specg2);

    // Spec1
    memset(wins, 0, gl * sizeof * wins);
    PHASERET_NAME(overlaynthframe)(wins, gl, winsNo, a, 0,
                                   (LTFAT_REAL*)p->uplan->specg1);

    ltfat_free(wins);
    wins = NULL;

    CHECKMEM(p->frames = LTFAT_NAME_REAL(calloc)(gl * (lookback + 1 + maxLookahead)
                         * W));
    CHECKMEM(p->s = LTFAT_NAME_REAL(calloc)(M2 * (1 + maxLookahead) * W));

    p->garbageBinSize = 4;
    CHECKMEM(p->garbageBin = (void**)ltfat_malloc(p->garbageBinSize * sizeof(
                                 void*)));
    p->garbageBin[0] = (void*)p->uplan->g;
    p->garbageBin[1] = (void*)p->uplan->gd;
    p->garbageBin[2] = (void*)p->uplan->specg1;
    p->garbageBin[3] = (void*)p->uplan->specg2;

    p->lookback = lookback;
    p->lookahead = lookahead;
    p->maxLookahead = maxLookahead;
    p->maxit = maxit;
    p->W = W;

    *pout = p;
    return status;
error:
    if (wins)
        ltfat_free(wins);
    PHASERET_NAME(rtisila_done)(&p);

    /* if (p) */
    /* { */
    /*     if (p->uplan) */
    /*     { */
    /*         if (p->uplan->g) ltfat_free((void*)p->uplan->g); */
    /*         if (p->uplan->gd) ltfat_free((void*)p->uplan->gd); */
    /*         if (p->uplan->specg1) ltfat_free((void*)p->uplan->specg1); */
    /*         if (p->uplan->specg2) ltfat_free((void*)p->uplan->specg2); */
    /*         if (p->garbageBin) ltfat_free(p->garbageBin); */
    /*         PHASERET_NAME(rtisilaupdate_done)(&p->uplan); */
    /*     } */
    /*     if (p->s) ltfat_free(p->s); */
    /*     if (p->frames) ltfat_free(p->frames); */
    /*     ltfat_free(p); */
    /* } */
    *pout = NULL;
    return status;
}

PHASERET_API int
PHASERET_NAME(rtisila_init_win)(LTFAT_FIRWIN win, ltfat_int gl,
                                ltfat_int W, ltfat_int a, ltfat_int M, ltfat_int lookahead, ltfat_int maxit,
                                PHASERET_NAME(rtisila_state) * *pout)
{
    LTFAT_REAL* g = NULL;
    int status = LTFATERR_SUCCESS;
    int initstatus;
    CHECKMEM(g = LTFAT_NAME_REAL(malloc)(gl));

    // Analysis window
    CHECKSTATUS(LTFAT_NAME(firwin)(win, gl, g));

    initstatus = PHASERET_NAME(rtisila_init)(g, gl, W, a, M, lookahead, maxit,
                 pout);

    ltfat_free(g);
    return initstatus;
error:
    if (g)
        ltfat_free(g);
    return status;
}

PHASERET_API int
PHASERET_NAME(rtisila_done)(PHASERET_NAME(rtisila_state) * *p)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(rtisila_state) * pp;
    CHECKNULL(p);
    CHECKNULL(*p);
    pp = *p;

    CHECKSTATUS(
        PHASERET_NAME(rtisilaupdate_done)(&pp->uplan));

    if (pp->s)
        ltfat_free(pp->s);
    if (pp->frames)
        ltfat_free(pp->frames);

    if (pp->garbageBinSize)
    {
        for (ltfat_int ii = 0; ii < pp->garbageBinSize; ii++)
            if (pp->garbageBin[ii])
                ltfat_free(pp->garbageBin[ii]);

        ltfat_free(pp->garbageBin);
    }

    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(rtisila_execute)( PHASERET_NAME(rtisila_state) * p,
                                const LTFAT_REAL* s, LTFAT_COMPLEX* c)
{
    ltfat_int M, gl, M2, noFrames, N;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);
    CHECKNULL(s);
    CHECKNULL(c);

    M = p->uplan->M;
    gl = p->uplan->gl;
    M2 = M / 2 + 1;
    noFrames = p->lookback + 1 + p->lookahead;
    N = p->lookback + 1 + p->maxLookahead;

    for (ltfat_int w = 0; w < p->W; w++)
    {
        const LTFAT_REAL* schan = s + w * M2;
        LTFAT_COMPLEX* cchan = c + w * M2;
        LTFAT_REAL* frameschan = p->frames + w * N * gl;
        LTFAT_REAL* sframeschan = p->s + w * (1 + p->maxLookahead) * M2;
        // Shift frames buffer
        PHASERET_NAME(shiftcolsleft)(frameschan, gl, noFrames, NULL);

        // Shift scols buffer
        PHASERET_NAME(shiftcolsleft)(sframeschan, M2, p->lookahead + 1, schan);

        PHASERET_NAME(rtisilaupdate_execute)(p->uplan, frameschan, noFrames,
                                             sframeschan, p->lookahead, p->maxit, frameschan, cchan);
    }

error:
    return status;
}

PHASERET_API int
PHASERET_NAME(rtisilaoffline)(const LTFAT_REAL s[], const LTFAT_REAL g[],
                              ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
                              ltfat_int lookahead, ltfat_int maxit, LTFAT_COMPLEX c[])
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(rtisila_state)* p = NULL;
    ltfat_int N = L / a;
    ltfat_int M2 = M / 2 + 1;

    CHECKNULL(s);
    CHECKNULL(g);
    CHECKNULL(c);
    // Just limit lookahead to something sensible
    lookahead = lookahead > N ? N : lookahead;

    CHECKSTATUS(PHASERET_NAME(rtisila_init)(g, gl, 1, a, M, lookahead, maxit, &p));

    for (ltfat_int w = 0; w < W; w++)
    {
        const LTFAT_REAL* schan = s + w * N * M2;
        PHASERET_NAME(rtisila_reset)(p, &schan);

        for (ltfat_int n = 0, nahead = lookahead; nahead < N; ++n, ++nahead)
        {
            const LTFAT_REAL* sncol = schan + nahead * M2;
            LTFAT_COMPLEX* cncol = c + n * M2 + w * N * M2;
            PHASERET_NAME(rtisila_execute)(p, sncol, cncol);
        }

        for (ltfat_int n = N - lookahead, nahead = 0; n < N; ++n, ++nahead)
        {
            const LTFAT_REAL* sncol = schan + nahead * M2;
            LTFAT_COMPLEX* cncol = c + n * M2 + w * N * M2;
            PHASERET_NAME(rtisila_execute)(p, sncol, cncol);
        }
    }
error:
    if (p) PHASERET_NAME(rtisila_done)(&p);
    return status;
}

PHASERET_API int
PHASERET_NAME(rtisila_set_itno)(PHASERET_NAME(rtisila_state)* p,
                                ltfat_int it)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);
    CHECK(LTFATERR_BADARG, it > 0, "it must be greater than 0.");

    p->maxit = it;
error:
    return status;

}
