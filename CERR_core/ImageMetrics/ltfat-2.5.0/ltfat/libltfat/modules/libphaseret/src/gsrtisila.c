#include "phaseret/rtisila.h"
#include "phaseret/gsrtisila.h"
#include "phaseret/utils.h"
#include "ltfat/macros.h"
#include "gsrtisila_private.h"


PHASERET_API int
PHASERET_NAME(gsrtisilaupdate_init)(const LTFAT_REAL* g, const LTFAT_REAL* gd,
                                    ltfat_int gl, ltfat_int a, ltfat_int M,
                                    ltfat_int gNo, int do_skipinitialization,
                                    PHASERET_NAME(gsrtisilaupdate_plan)** pout)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(gsrtisilaupdate_plan)* p = NULL;
    /* ltfat_int M2 = M / 2 + 1; */

    CHECKMEM( p = (PHASERET_NAME(gsrtisilaupdate_plan)*)
                  ltfat_calloc(1, sizeof * p));
    p->M = M; p->a = a; p->g = g; p->gl = gl; p->gNo = gNo;
    p->do_skipinitialization = do_skipinitialization;

    CHECKSTATUS(
        PHASERET_NAME(rtisilaupdate_init)(NULL, NULL, NULL, gd, gl, a, M, &p->p2));

    *pout = p;
    return status;
error:
    if (p) PHASERET_NAME(gsrtisilaupdate_done)(&p);
    return status;
}

PHASERET_API int
PHASERET_NAME(gsrtisilaupdate_done)(PHASERET_NAME(gsrtisilaupdate_plan)** p)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(gsrtisilaupdate_plan)* pp;
    CHECKNULL(p); CHECKNULL(*p);

    pp = *p;
    if (pp->p2) PHASERET_NAME(rtisilaupdate_done)(&pp->p2);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

PHASERET_API void
PHASERET_NAME(gsrtisilaupdate_execute)(PHASERET_NAME(gsrtisilaupdate_plan)* p,
                                       const LTFAT_REAL* frames, const LTFAT_COMPLEX* cframes, ltfat_int N,
                                       const LTFAT_REAL* s, ltfat_int lookahead, ltfat_int maxit,
                                       LTFAT_REAL* frames2, LTFAT_COMPLEX* cframes2,
                                       LTFAT_COMPLEX* c)
{
    ltfat_int lookback = N - lookahead - 1;
    ltfat_int M = p->M;
    ltfat_int gl = p->gl;
    ltfat_int M2 = M / 2 + 1;

    // If we are not working inplace ...
    if (frames != frames2)
        memcpy(frames2, frames, gl * N  * sizeof * frames);

    if (cframes != cframes2)
        memcpy(cframes2, cframes, M2 * N * sizeof * cframes);

    if (!p->do_skipinitialization)
        PHASERET_NAME(rtisilaphaseupdatesyn)(p->p2,
                                             cframes2 + (lookback + lookahead)*M2,
                                             frames2 + (lookback + lookahead)*gl);

    for (ltfat_int it = 0; it < maxit; it++)
    {
        for (ltfat_int nback = lookahead; nback >= 0; nback--)
        {
            ltfat_int indx = lookback + nback;
            ltfat_int nfwd = lookahead - nback;

            PHASERET_NAME(rtisilaoverlaynthframe)(p->p2, frames2,
                                                  p->g + nfwd * gl, indx, N);

            PHASERET_NAME(rtisilaphaseupdate)(p->p2, s + nback * M2,
                                              frames2 +  indx * gl,
                                              cframes2 + indx * M2);
        }
    }

    if (c) memcpy(c, cframes2 + lookback * M2, M2 * sizeof * c);
}

PHASERET_API int
PHASERET_NAME(gsrtisila_init_win)(LTFAT_FIRWIN win, ltfat_int gl, ltfat_int W,
                                  ltfat_int a, ltfat_int M, ltfat_int lookahead, ltfat_int maxit,
                                  PHASERET_NAME(gsrtisila_state)** pout)
{
    LTFAT_REAL* g = NULL;
    int status = LTFATERR_SUCCESS;
    int initstatus;
    CHECKMEM(g = LTFAT_NAME_REAL(malloc)(gl));

    // Analysis window
    CHECKSTATUS(LTFAT_NAME(firwin)(win, gl, g));

    initstatus = PHASERET_NAME(gsrtisila_init)(g, gl, W, a, M, lookahead, maxit,
                 pout);

    ltfat_free(g);
    return initstatus;
error:
    if (g) ltfat_free(g);
    return status;
}

PHASERET_API int
PHASERET_NAME(gsrtisila_init)(const LTFAT_REAL* g, ltfat_int gl, ltfat_int W,
                              ltfat_int a, ltfat_int M, ltfat_int lookahead, ltfat_int maxit,
                              PHASERET_NAME(gsrtisila_state)** pout)
{
    int status = LTFATERR_SUCCESS;

    PHASERET_NAME(gsrtisila_state)* p = NULL;
    LTFAT_REAL* wins = NULL;
    LTFAT_REAL* gd = NULL;
    LTFAT_REAL* gana = NULL;
    LTFAT_REAL* gcopy = NULL;

    ltfat_int M2, lookback, winsNo, maxLookahead;
    LTFAT_REAL rellim = (LTFAT_REAL) 1e-3;

    CHECKNULL(g); CHECKNULL(pout);
    CHECK(LTFATERR_BADSIZE, gl > 0, "gl must be positive (passed %d)", gl);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive (passed %d)", W);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive (passed %d)", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive (passed %d)", M);
    CHECK(LTFATERR_BADARG, lookahead >= 0,
          "lookahead >=0 failed (passed %d)", lookahead);
    CHECK(LTFATERR_NOTPOSARG, maxit > 0,
          "maxit must be positive (passed %d)", maxit);

    M2 = M / 2 + 1;
    lookback = (ltfat_int)( ceil(((LTFAT_REAL) gl) / a) - 1);
    winsNo = (lookback + 1 + lookahead);
    maxLookahead = lookahead;
    CHECKMEM( p = (PHASERET_NAME(gsrtisila_state)*) ltfat_calloc(1, sizeof * p));

    CHECKMEM( gcopy = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM( gd = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM( wins = LTFAT_NAME_REAL(malloc)(gl * winsNo));
    CHECKMEM( gana = LTFAT_NAME_REAL(malloc)(gl * (lookahead + 1)));

    CHECKSTATUS( LTFAT_NAME(gabdual_painless)(g, gl, a, M, gd));

    LTFAT_NAME(fftshift)(g, gl, gcopy);
    LTFAT_NAME(fftshift)(gd, gl, gd);

    for (ltfat_int l = 0; l < gl; l++)
        wins[l] = M * gcopy[l] * gd[l];

    LTFAT_NAME(periodize_array)(wins, gl, gl * winsNo, wins);

    for (ltfat_int n = 0; n < lookahead + 1; n++)
    {
        LTFAT_REAL* ganachan = gana + (lookahead - n) * gl;
        PHASERET_NAME(overlaynthframe)(wins, gl, winsNo, a, lookback + n,
                                       ganachan);

        for (ltfat_int l = 0; l < gl; l++)
        {
            LTFAT_REAL denom = ganachan[l];
            if (denom < rellim && denom > 0) denom = rellim;
            if (denom > -rellim && denom < 0) denom = -rellim;
            if (denom == 0) denom = 1;
            ganachan[l] = gcopy[l] / denom;
        }
    }

    ltfat_free(gcopy); gcopy = NULL;
    ltfat_free(wins); wins = NULL;

    CHECKMEM( p->frames =
                  LTFAT_NAME_REAL(calloc)(gl * (lookback + 1 + maxLookahead) * W));
    CHECKMEM( p->s = LTFAT_NAME_REAL(calloc)( M2 * (1 + maxLookahead) * W));
    CHECKMEM( p->cframes =
                  LTFAT_NAME_COMPLEX(calloc)( M2 * (lookback + 1 + maxLookahead) * W));

    CHECKSTATUS(
        PHASERET_NAME(gsrtisilaupdate_init)(gana, gd, gl, a, M, lookahead + 1, 1,
                                            &p->uplan));

    p->garbageBinSize = 2;
    CHECKMEM( p->garbageBin =
                  (void**)ltfat_malloc(p->garbageBinSize * sizeof(void*)));
    p->garbageBin[0] = (void*) gana;
    p->garbageBin[1] = (void*) gd;

    p->lookback = lookback;
    p->lookahead = lookahead;
    p->maxLookahead = maxLookahead;
    p->maxit = maxit;
    p->W = W;

    *pout = p;
    return status;
error:
    if (wins) ltfat_free(wins);
    if (gcopy) ltfat_free(gcopy);
    PHASERET_NAME(gsrtisila_done)(&p);

    *pout = NULL;
    return status;
}

PHASERET_API int
PHASERET_NAME(gsrtisila_execute)(PHASERET_NAME(gsrtisila_state)* p,
                                 const LTFAT_REAL s[], LTFAT_COMPLEX c[])
{
    ltfat_int M, gl, M2, noFrames, N;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(s); CHECKNULL(c);

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
        LTFAT_COMPLEX* cframeschan = p->cframes + w * N * M2;
        LTFAT_REAL* sframeschan = p->s + w * (1 + p->maxLookahead) * M2;

        PHASERET_NAME(shiftcolsleft)(frameschan, gl, noFrames, NULL);
        PHASERET_NAME_COMPLEX(shiftcolsleft)(cframeschan, M2, noFrames, cchan);
        PHASERET_NAME(shiftcolsleft)(sframeschan, M2, p->lookahead + 1, schan);

        PHASERET_NAME(gsrtisilaupdate_execute)(p->uplan, frameschan, cframeschan,
                                               noFrames, sframeschan, p->lookahead, p->maxit,
                                               frameschan, cframeschan, cchan);
    }

error:
    return status;
}

PHASERET_API int
PHASERET_NAME(gsrtisila_done)(PHASERET_NAME(gsrtisila_state)** p)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(gsrtisila_state)* pp;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;

    CHECKSTATUS( PHASERET_NAME(gsrtisilaupdate_done)(&pp->uplan));

    if (pp->s) ltfat_free(pp->s);
    if (pp->frames) ltfat_free(pp->frames);
    if (pp->cframes) ltfat_free(pp->cframes);

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
PHASERET_NAME(gsrtisila_reset)(PHASERET_NAME(gsrtisila_state)* p,
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
    memset(p->cframes, 0, M2 * N * W * sizeof * p->cframes);

    if (sinit)
        for (ltfat_int w = 0; w < W; w++)
            if (sinit[w])
                memcpy(p->s + M2 + w * (1 + p->maxLookahead)*M2, sinit[w],
                       M2 * p->lookahead * sizeof * p->s );

error:
    return status;
}

PHASERET_API int
PHASERET_NAME(gsrtisila_set_skipinitialization)(PHASERET_NAME(
            gsrtisila_state)* p, int do_skipinitialization)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);

    p->uplan->do_skipinitialization = do_skipinitialization;
error:
    return status;
}


PHASERET_API int
PHASERET_NAME(gsrtisila_set_lookahead)(PHASERET_NAME(gsrtisila_state)* p,
                                       ltfat_int lookahead)
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

PHASERET_API int
PHASERET_NAME(gsrtisila_set_itno)(PHASERET_NAME(gsrtisila_state)* p,
                                  ltfat_int it)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);
    CHECK(LTFATERR_BADARG, it > 0, "it must be greater than 0.");

    p->maxit = it;
error:
    return status;

}

PHASERET_API int
PHASERET_NAME(gsrtisilaoffline)(const LTFAT_REAL s[], const LTFAT_REAL g[],
                                ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
                                ltfat_int lookahead, ltfat_int maxit, LTFAT_COMPLEX c[])
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(gsrtisila_state)* p = NULL;
    ltfat_int N = L / a;
    ltfat_int M2 = M / 2 + 1;

    CHECKNULL(s); CHECKNULL(g); CHECKNULL(c);
    // Just limit lookahead to something sensible
    lookahead = lookahead > N ? N : lookahead;

    CHECKSTATUS(PHASERET_NAME(gsrtisila_init)(g, gl, 1, a, M, lookahead, maxit, &p));

    for (ltfat_int w = 0; w < W; w++)
    {
        const LTFAT_REAL* schan = s + w * N * M2;
        PHASERET_NAME(gsrtisila_reset)(p, &schan);

        for (ltfat_int n = 0, nahead = lookahead; nahead < N; ++n, ++nahead)
        {
            const LTFAT_REAL* sncol = schan + nahead * M2;
            LTFAT_COMPLEX* cncol = c + n * M2 + w * N * M2;
            PHASERET_NAME(gsrtisila_execute)(p, sncol, cncol);
        }

        for (ltfat_int n = N - lookahead, nahead = 0; n < N; ++n, ++nahead)
        {
            const LTFAT_REAL* sncol = schan + nahead * M2;
            LTFAT_COMPLEX* cncol = c + n * M2 + w * N * M2;
            PHASERET_NAME(gsrtisila_execute)(p, sncol, cncol);
        }
    }
error:
    if (p) PHASERET_NAME(gsrtisila_done)(&p);
    return status;
}
