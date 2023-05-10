#include "phaseret/pghi.h"
#include "phaseret/heapint_private.h"
#include "ltfat/macros.h"
#include <float.h>

struct PHASERET_NAME(pghi_plan)
{
    double gamma;
    ltfat_int a;
    ltfat_int M;
    ltfat_int W;
    ltfat_int L;
    double tol1;
    double tol2;
    LTFAT_NAME(heapinttask)* hit;
    LTFAT_REAL* tgrad;
    LTFAT_REAL* fgrad;
    /* double* scratch; */
};

PHASERET_API int
PHASERET_NAME(pghi)(const LTFAT_REAL s[], ltfat_int L,
                    ltfat_int W, ltfat_int a, ltfat_int M,
                    double gamma, LTFAT_COMPLEX c[])
{
    PHASERET_NAME(pghi_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(s); CHECKNULL(c);
    CHECKSTATUS( PHASERET_NAME(pghi_init)( L, W, a, M, 1e-1, 1e-10, gamma, &p));
    PHASERET_NAME(pghi_execute)(p, s, c); // This cannot fail

    PHASERET_NAME(pghi_done)(&p);
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(pghi_withmask)(const LTFAT_COMPLEX cinit[], const int mask[],
                             ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                             double gamma, LTFAT_COMPLEX c[])
{
    PHASERET_NAME(pghi_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(cinit); CHECKNULL(mask); CHECKNULL(c);

    CHECKSTATUS( PHASERET_NAME(pghi_init)(L, W, a, M, 1e-1, 1e-10, gamma, &p));
    PHASERET_NAME(pghi_execute_withmask)(p, cinit, mask, NULL,
                                         c); // This cannot fail

    PHASERET_NAME(pghi_done)(&p);
error:
    return status;
}

/* int */
/* pghi_init(double gamma, const int L, const int W, */
/*           const int a, const int M, double tol, pghi_plan** pout) */
/* { */
/*     return pghi_init_twostep(gamma, L, W, a, M, tol, NAN, pout); */
/* } */

PHASERET_API int
PHASERET_NAME(pghi_init)(ltfat_int L, ltfat_int W,
                         ltfat_int a, ltfat_int M, double tol1, double tol2,
                         double gamma, PHASERET_NAME(pghi_plan)** pout)
{
    PHASERET_NAME(pghi_plan)* p = NULL;
    ltfat_int M2, N;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(pout);
    CHECK(LTFATERR_BADARG, !isnan(gamma) && gamma > 0,
          "gamma cannot be nan and must be positive. (Passed %f).", gamma);
    CHECK(LTFATERR_NOTPOSARG, L > 0, "L must be positive");
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive");
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive");
    CHECK(LTFATERR_NOTINRANGE, tol1 > 0 && tol1 < 1, "tol1 must be in range ]0,1[");

    if (!isnan(tol2))
    {
        CHECK(LTFATERR_NOTINRANGE, tol2 > 0 && tol2 < 1 && tol2 < tol1,
              "tol2 must be in range ]0,1[ and less or equal to tol1.");
    }

    CHECKMEM( p = (PHASERET_NAME(pghi_plan)*) ltfat_calloc(1, sizeof * p));
    p->gamma = gamma; p->a = a; p->M = M; p->W = W; p->L = L; p->tol1 = tol1;
    p->tol2 = tol2;

    M2 = M / 2 + 1;
    N = L / a;

    CHECKMEM( p->tgrad = LTFAT_NAME_REAL(malloc)(M2 * N));
    CHECKMEM( p->fgrad = LTFAT_NAME_REAL(malloc)(M2 * N));
    /* CHECKMEM( p->scratch = malloc(M2 * N * sizeof * p->scratch)); */
    // Not yet
    p->hit = LTFAT_NAME(heapinttask_init)( M2, N, (ltfat_int)( M2 * log((double)M2)) , NULL, 1);

    *pout = p;
    return status;
error:
    if (p) PHASERET_NAME(pghi_done)(&p);
    return status;
}

PHASERET_API int
PHASERET_NAME(pghi_execute)(PHASERET_NAME(pghi_plan)* p, const LTFAT_REAL s[],
                            LTFAT_COMPLEX c[])
{
    int status = LTFATERR_SUCCESS;
    ltfat_int M2, W, N;
    CHECKNULL(s); CHECKNULL(c); CHECKNULL(p);

    M2 = p->M / 2 + 1;
    W = p->W;
    N = p->L / p->a;

    for (ltfat_int w = W - 1; w >= 0; --w)
    {
        const LTFAT_REAL* schan = s + w * M2 * N;
        LTFAT_COMPLEX* cchan = c + w * M2 * N;
        const LTFAT_REAL* tgradwchan = p->tgrad + w * M2 * N;
        const LTFAT_REAL* fgradwchan = p->fgrad + w * M2 * N;
        LTFAT_REAL* scratch = ((LTFAT_REAL*)cchan) + M2 *
                              N; // Second half of the output

        PHASERET_NAME(pghilog)(schan, M2 * N, scratch);
        PHASERET_NAME(pghitgrad)(scratch, p->gamma, p->a, p->M, N, p->tgrad );
        PHASERET_NAME(pghifgrad)(scratch, p->gamma, p->a, p->M, N, p->fgrad );

        memset(scratch, 0, M2 * N * sizeof * scratch);

        // Start of without mask
        LTFAT_NAME(heapinttask_resetmax)(p->hit, schan, (LTFAT_REAL) p->tol1);
        LTFAT_NAME(heapint_execute)(p->hit, schan, tgradwchan, fgradwchan, scratch);
        int* donemask = LTFAT_NAME(heapinttask_get_mask)(p->hit);

        if (!isnan(p->tol2) && p->tol2 < p->tol1)
        {
            // Reuse the just computed mask
            LTFAT_NAME(heapinttask_resetmask)(p->hit, donemask, schan, (LTFAT_REAL) p->tol2, 0);
            LTFAT_NAME(heapint_execute)(p->hit, schan, tgradwchan, fgradwchan, scratch);
        }

        // Assign random phase to unused coefficients
        for (ltfat_int ii = 0; ii < M2 * N; ii++)
            if (donemask[ii] <= LTFAT_MASK_UNKNOWN)
                scratch[ii] = (LTFAT_REAL) ( 2.0 * M_PI * ((double)rand()) / RAND_MAX);

        // Combine phase and magnitude
        if (schan != (LTFAT_REAL*) cchan)
        {
            PHASERET_NAME(pghimagphase)(schan, scratch, M2 * N, cchan);
        }
        else
        {
            // Copy the magnitude first to avoid overwriting it.
            memcpy(p->tgrad, schan, M2 * N * sizeof * schan);
            PHASERET_NAME(pghimagphase)(p->tgrad, scratch, M2 * N, cchan);
        }
    }
error:
    return status;
}

PHASERET_API int
PHASERET_NAME(pghi_execute_withmask)(PHASERET_NAME(pghi_plan)* p,
                                     const LTFAT_COMPLEX cin[],
                                     const int mask[], LTFAT_REAL buffer[], LTFAT_COMPLEX cout[])
{
    LTFAT_REAL* bufferLoc = NULL;
    ltfat_int freeBufferLoc = 0, M2, W, N;
    LTFAT_REAL* schan;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(cin); CHECKNULL(mask); CHECKNULL(cout); CHECKNULL(p);

    M2 = p->M / 2 + 1;
    W = p->W;
    N = p->L / p->a;

    if (buffer)
        bufferLoc = buffer;
    else
    {
        CHECKMEM( bufferLoc = LTFAT_NAME_REAL(malloc)(M2 * N) );
        freeBufferLoc = 1;
    }

    schan = bufferLoc;

    for (ltfat_int w = 0; w < W; ++w)
    {
        const LTFAT_COMPLEX* cinchan = cin + w * M2 * N;
        LTFAT_COMPLEX* coutchan = cout + w * M2 * N;
        const int* maskchan = mask + w * M2 * N;
        const LTFAT_REAL* tgradwchan = p->tgrad + w * M2 * N;
        const LTFAT_REAL* fgradwchan = p->fgrad + w * M2 * N;
        LTFAT_REAL* scratch = ((LTFAT_REAL*)coutchan) + M2 *
                              N; // Second half of the output

        for (ltfat_int ii = 0; ii < M2 * N; ii++)
            schan[ii] = ltfat_abs(cinchan[ii]);

        PHASERET_NAME(pghilog)(schan, M2 * N, scratch);
        PHASERET_NAME(pghitgrad)(scratch, p->gamma, p->a, p->M, N, p->tgrad );
        PHASERET_NAME(pghifgrad)(scratch, p->gamma, p->a, p->M, N, p->fgrad );

        memset(scratch, 0, M2 * N * sizeof * scratch);

        // Start of without mask
        LTFAT_NAME(heapinttask_resetmask)(p->hit, maskchan, schan, (LTFAT_REAL)p->tol1, 0);
        LTFAT_NAME(heapint_execute)(p->hit, schan, tgradwchan, fgradwchan, scratch);
        int* donemask = LTFAT_NAME(heapinttask_get_mask)(p->hit);

        if (!isnan(p->tol2))
        {
            // Reuse the just computed mask
            LTFAT_NAME(heapinttask_resetmask)(p->hit, donemask, schan, (LTFAT_REAL)p->tol2, 0);
            LTFAT_NAME(heapint_execute)(p->hit, schan, tgradwchan, fgradwchan, scratch);
        }

        // Assign random phase to unused coefficients
        for (ltfat_int ii = 0; ii < M2 * N; ii++)
            if (donemask[ii] <= LTFAT_MASK_UNKNOWN)
                scratch[ii] = (LTFAT_REAL) (2.0 * M_PI * ((double)rand()) / RAND_MAX);

        // Combine phase and magnitude
        PHASERET_NAME(pghimagphase)(schan, scratch, M2 * N, coutchan);

    }
error:
    if (freeBufferLoc) ltfat_free(bufferLoc);
    return status;
}

PHASERET_API int
PHASERET_NAME(pghi_done)(PHASERET_NAME(pghi_plan)** p)
{
    int status = LTFATERR_SUCCESS;
    PHASERET_NAME(pghi_plan)* pp;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;
    if (pp->hit) LTFAT_NAME(heapinttask_done)(pp->hit);
    ltfat_safefree(pp->fgrad);
    ltfat_safefree(pp->tgrad);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

PHASERET_API int*
PHASERET_NAME(pghi_get_mask)(PHASERET_NAME(pghi_plan)* p)
{
    if (p == NULL) return NULL;
    return LTFAT_NAME(heapinttask_get_mask)(p->hit);
}

void
PHASERET_NAME(pghimagphase)(const LTFAT_REAL s[], const LTFAT_REAL phase[],
                            ltfat_int L, LTFAT_COMPLEX c[])
{
    for (ltfat_int l = 0; l < L; l++)
        c[l] = s[l] * exp(I * phase[l]);
}

void
PHASERET_NAME(pghilog)(const LTFAT_REAL* in, ltfat_int L, LTFAT_REAL* out)
{
    for (ltfat_int l = 0; l < L; l++)
#ifdef LTFAT_DOUBLE
        out[l] = log(in[l] + DBL_MIN);
#else
		out[l] = log(in[l] + FLT_MIN);
#endif

}

void
PHASERET_NAME(pghitgrad)(const LTFAT_REAL* logs, double gamma, ltfat_int a,
                         ltfat_int M,
                         ltfat_int N,
                         LTFAT_REAL* tgrad)
{
    ltfat_int M2 = M / 2 + 1;

    const LTFAT_REAL tgradmul = (LTFAT_REAL)( (a * M) / (gamma * 2.0));
    const LTFAT_REAL tgradplus = (LTFAT_REAL)( 2.0 * M_PI * a / ((double)M));


    for (ltfat_int n = 0; n < N; n++)
    {
        LTFAT_REAL* tgradCol = tgrad + n * M2;
        const LTFAT_REAL* logsCol = logs + n * M2;

        tgradCol[0]      = 0.0;
        tgradCol[M2 - 1] = 0.0;

        for (ltfat_int m = 1; m < M2 - 1; m++)
            tgradCol[m] = tgradmul * (logsCol[m + 1] - logsCol[m - 1]) + tgradplus * m;
    }
}

void
PHASERET_NAME(pghifgrad)(const LTFAT_REAL* logs, double gamma, ltfat_int a,
                         ltfat_int M, ltfat_int N, LTFAT_REAL* fgrad)
{
    ltfat_int M2 = M / 2 + 1;

    const LTFAT_REAL fgradmul = (const LTFAT_REAL) ( -gamma / (2.0 * a * M));

    for (ltfat_int n = 1; n < N - 1; n++)
    {
        const LTFAT_REAL* scol0 = logs + (n - 1) * M2;
        const LTFAT_REAL* scol2 = logs + (n + 1) * M2;
        LTFAT_REAL* fgradCol = fgrad + n * M2;

        for (ltfat_int m = 0; m < M2; ++m)
            fgradCol[m] = fgradmul * (scol2[m] - scol0[m]);
    }

    // Explicit first col
    {
        const LTFAT_REAL* scol0 = logs + (N - 1) * M2;
        const LTFAT_REAL* scol2 = logs + M2;
        LTFAT_REAL* fgradCol = fgrad;

        for (ltfat_int m = 0; m < M2; ++m)
            fgradCol[m] = fgradmul * (scol2[m] - scol0[m]);
    }

    // Explicit last col
    {
        const LTFAT_REAL* scol0 = logs;
        const LTFAT_REAL* scol2 = logs + (N - 2) * M2;
        LTFAT_REAL* fgradCol = fgrad + (N - 1) * M2;

        for (ltfat_int m = 0; m < M2; ++m)
            fgradCol[m] = fgradmul * (scol2[m] - scol0[m]);
    }
}
