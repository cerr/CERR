#include "phaseret/gsrtisilapghi.h"
#include "phaseret/utils.h"
#include "ltfat/macros.h"
#include "gsrtisila_private.h"
#include "rtpghi_private.h"

struct PHASERET_NAME(gsrtisilapghi_state)
{
    PHASERET_NAME(gsrtisila_state)* gsstate;
    PHASERET_NAME(rtpghi_state)* pghistate;
    LTFAT_REAL* olds;
    ltfat_int W;
    ltfat_int M;
    ltfat_int lookahead;
};

PHASERET_API int
PHASERET_NAME(gsrtisilapghi_init_win)(LTFAT_FIRWIN win, ltfat_int gl,
                                      ltfat_int W, ltfat_int a, ltfat_int M, ltfat_int lookahead,
                                      ltfat_int maxit, double tol, int do_causalrtpghi,
                                      PHASERET_NAME(gsrtisilapghi_state)** pout)
{
    double gamma;
    LTFAT_REAL* g = NULL;
    int status = LTFATERR_SUCCESS;
    int initstatus;
    CHECKMEM(g = LTFAT_NAME_REAL(malloc)(gl));

    // Analysis window
    CHECKSTATUS(LTFAT_NAME(firwin)(win, gl, g));
    gamma = phaseret_firwin2gamma(win, gl);

    initstatus =
        PHASERET_NAME(gsrtisilapghi_init)(g, gl, W, a, M, lookahead, maxit,
                                          gamma, tol, do_causalrtpghi, pout);

    ltfat_free(g);
    return initstatus;
error:
    if (g) ltfat_free(g);
    return status;
}

PHASERET_API int
PHASERET_NAME(gsrtisilapghi_init)(const LTFAT_REAL* g, ltfat_int gl,
                                  ltfat_int W, ltfat_int a, ltfat_int M, ltfat_int lookahead,
                                  ltfat_int maxit, double gamma, double tol, int do_causalrtpghi,
                                  PHASERET_NAME(gsrtisilapghi_state)** pout)
{
    int status = LTFATERR_SUCCESS;
    int initstatus;
    ltfat_int M2, gslookahead;
    PHASERET_NAME(gsrtisilapghi_state)* p = NULL;

    CHECKNULL(g); CHECKNULL(pout);
    CHECK(LTFATERR_BADARG, do_causalrtpghi || lookahead > 0,
          "0 lookahead frames cannot be combined with non-causal RTPGHI");

    gslookahead = lookahead;
    /* if (!do_causalrtpghi) gslookahead--; */

    CHECKMEM(p = (PHASERET_NAME(gsrtisilapghi_state)*)ltfat_calloc(1, sizeof * p));

    initstatus =
        PHASERET_NAME(rtpghi_init)( W, a, M, gamma, tol, do_causalrtpghi,
                                    &p->pghistate);
    CHECKSTATUS(initstatus);

    initstatus =
        PHASERET_NAME(gsrtisila_init)(g, gl, W, a, M, gslookahead, maxit, &p->gsstate);
    CHECKSTATUS(initstatus);

    PHASERET_NAME(gsrtisila_set_skipinitialization)(p->gsstate, 0);

    p->W = W; p->M = M; p->lookahead = lookahead + (do_causalrtpghi ? 0 : 1);
    M2 = M / 2 + 1;

    CHECKMEM(p->olds = LTFAT_NAME_REAL(calloc)(M2 * W));

    *pout = p;
    return status;
error:
    if (p) PHASERET_NAME(gsrtisilapghi_done)(&p);
    return status;
}

PHASERET_API int
PHASERET_NAME(gsrtisilapghi_execute)(PHASERET_NAME(gsrtisilapghi_state)* p,
                                     const LTFAT_REAL s[], LTFAT_COMPLEX c[])
{
    int status = LTFATERR_SUCCESS;
    ltfat_int M2 = p->M / 2 + 1;
    LTFAT_COMPLEX* lastc = NULL;
    LTFAT_REAL* lastphase = NULL;
    CHECKNULL(p); CHECKNULL(s); CHECKNULL(c);

    lastc = p->gsstate->cframes +
            (p->gsstate->lookback + p->gsstate->lookahead) * M2;
    lastphase = p->pghistate->phase;

    for (ltfat_int m = 0; m < M2; m++)
        lastphase[m] = ltfat_arg(lastc[m]);

    // gsrtisila was configured to reuse c as an input
    if (p->pghistate->do_causal)
    {
        PHASERET_NAME(rtpghi_execute)(p->pghistate, s, c);
        PHASERET_NAME(gsrtisila_execute)(p->gsstate, s, c);
    }
    else
    {
        PHASERET_NAME(rtpghi_execute)(p->pghistate, s, c);
        // Here s belongs to frame n, but c belongs to n-1
        PHASERET_NAME(gsrtisila_execute)(p->gsstate, p->olds, c);
        memcpy(p->olds, s, p->W * M2 * sizeof * p->olds);
    }
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(gsrtisilapghi_done)(PHASERET_NAME(gsrtisilapghi_state)** p)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(gsrtisilapghi_state)* pp;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;

    if (pp->gsstate)   PHASERET_NAME(gsrtisila_done)(&pp->gsstate);
    if (pp->pghistate) PHASERET_NAME(rtpghi_done)(&pp->pghistate);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

PHASERET_API PHASERET_NAME(gsrtisila_state)*
PHASERET_NAME(gsrtisilapghi_get_gsrtisila_state)(
    PHASERET_NAME(gsrtisilapghi_state)* p)
{
    if (!p) return NULL;
    return p->gsstate;
}

PHASERET_API PHASERET_NAME(rtpghi_state)*
PHASERET_NAME(gsrtisilapghi_get_rtpghi_state)(
    PHASERET_NAME(gsrtisilapghi_state)* p)
{
    if (!p) return NULL;
    return p->pghistate;
}


PHASERET_API int
PHASERET_NAME(gsrtisilapghi_reset)(PHASERET_NAME(gsrtisilapghi_state)* p,
                                   const LTFAT_REAL** sinit)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p);
    CHECKSTATUS(PHASERET_NAME(rtpghi_reset)(p->pghistate, sinit));
    CHECKSTATUS(PHASERET_NAME(gsrtisila_reset)(p->gsstate, sinit));

    memset(p->olds, 0, p->W * (p->M / 2 + 1) * sizeof * p->olds);

    if (sinit)
        for (ltfat_int w = 0; w < p->W; w++)
            if (sinit[w])
                memcpy(p->olds, sinit[w], (p->M / 2 + 1) * sizeof * p->olds);
error:
    return status;
}


PHASERET_API int
PHASERET_NAME(gsrtisilapghioffline)(const LTFAT_REAL s[], const LTFAT_REAL g[],
                                    ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
                                    ltfat_int lookahead, ltfat_int maxit,
                                    double gamma, double tol, int do_causalrtpghi, LTFAT_COMPLEX c[])
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(gsrtisilapghi_state)* p = NULL;
    ltfat_int N = L / a;
    ltfat_int M2 = M / 2 + 1;

    CHECKNULL(s); CHECKNULL(g); CHECKNULL(c);

    // Just limit lookahead to something sensible
    lookahead = lookahead > N ? N : lookahead;

    CHECKSTATUS(PHASERET_NAME(gsrtisilapghi_init)(g, gl, 1, a, M, lookahead, maxit,
                gamma, tol, do_causalrtpghi, &p));
    // Ge the true lookahead
    lookahead = p->lookahead;

    for (ltfat_int w = 0; w < W; w++)
    {
        // Do first lookahead frames just to preload the buffers
        // to avoid the initial error
        for (ltfat_int n = 0; n < lookahead ; ++n)
        {
            const LTFAT_REAL* sncol = s + n * M2 + w * N * M2;
            LTFAT_COMPLEX* cncol = c + n * M2 + w * N * M2;
            PHASERET_NAME(gsrtisilapghi_execute)(p, sncol, cncol);
        }

        // The main loop
        for (ltfat_int n = 0, nahead = lookahead; nahead < N; ++n, ++nahead)
        {
            const LTFAT_REAL* sncol = s + nahead * M2 + w * N * M2;
            LTFAT_COMPLEX* cncol = c + n * M2 + w * N * M2;
            PHASERET_NAME(gsrtisilapghi_execute)(p, sncol, cncol);
        }

        // Circular wrap
        for (ltfat_int n = N - lookahead, nahead = 0; n < N; ++n, ++nahead)
        {
            const LTFAT_REAL* sncol = s + nahead * M2 + w * N * M2;
            LTFAT_COMPLEX* cncol = c + n * M2 + w * N * M2;
            PHASERET_NAME(gsrtisilapghi_execute)(p, sncol, cncol);
        }
    }
error:
    if (p) PHASERET_NAME(gsrtisilapghi_done)(&p);
    return status;
}
