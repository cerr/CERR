#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

struct LTFAT_NAME(idgt_long_plan)
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int L;
    ltfat_int W;
    ltfat_int c;
    ltfat_int h_a;
    ltfat_phaseconvention ptype;
    LTFAT_REAL scalconst;
    LTFAT_COMPLEX* f;
    const LTFAT_COMPLEX* cin;
    LTFAT_COMPLEX* gf, *ff, *cf, *cwork, *cbuf;
    LTFAT_NAME_REAL(ifft_plan)* p_veryend;
    LTFAT_NAME_REAL(ifft_plan)* p_before;
    LTFAT_NAME_REAL(fft_plan)* p_after;
};

LTFAT_API int
LTFAT_NAME(idgt_long)(const LTFAT_COMPLEX* cin, const LTFAT_TYPE* g,
                      ltfat_int L, ltfat_int W,
                      ltfat_int a, ltfat_int M,
                      const ltfat_phaseconvention ptype,
                      LTFAT_COMPLEX* f)
{
    LTFAT_NAME(idgt_long_plan)* plan = NULL;
    int status = LTFATERR_SUCCESS;

    // Must use FFTW_ESTIMATE such that cin is not overwritten.
    // It is safe to cast away the const.
    CHECKSTATUS(
        LTFAT_NAME(idgt_long_init)( g, L, W, a, M, (LTFAT_COMPLEX*)cin, f, ptype,
                                    FFTW_ESTIMATE, &plan));

    CHECKSTATUS(
        LTFAT_NAME(idgt_long_execute)(plan));

error:
    if (plan) LTFAT_NAME(idgt_long_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(idgt_long_init)( const LTFAT_TYPE* g,
                            ltfat_int L, ltfat_int W,
                            ltfat_int a, ltfat_int M,
                            LTFAT_COMPLEX* cin, LTFAT_COMPLEX* f,
                            const ltfat_phaseconvention ptype, unsigned flags,
                            LTFAT_NAME(idgt_long_plan)** pout)
{
    ltfat_int minL, b, N, p, q, d;
    LTFAT_NAME(idgt_long_plan)* plan = NULL;
    // Downcast to int
    int status = LTFATERR_SUCCESS;
    CHECK(LTFATERR_NULLPOINTER, (flags & FFTW_ESTIMATE) || cin != NULL,
          "cin cannot be NULL if flags is not FFTW_ESTIMATE");
    // CHECKNULL(f); // can be NULL
    CHECKNULL(g); CHECKNULL(pout);
    CHECK(LTFATERR_BADSIZE, L > 0, "L (passed %td) must be positive", L);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W (passed %td) must be positive.", W);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a (passed %td) must be positive.", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M (passed %td) must be positive.", M);
    CHECK(LTFATERR_CANNOTHAPPEN, ltfat_phaseconvention_is_valid(ptype),
          "Invalid ltfat_phaseconvention enum value." );

    minL = ltfat_lcm(a, M);
    CHECK(LTFATERR_BADTRALEN,
          !(L % minL), "L (passed %td) must be positive and divisible by lcm(a,M)=%td.",
          L, minL);

    CHECKMEM(plan = LTFAT_NEW(LTFAT_NAME(idgt_long_plan)) );

    ltfat_int h_m;

    plan->a = a; plan->L = L; plan->M = M; plan->W = W; plan->ptype = ptype;
    /*  ----------- calculation of parameters and plans -------- */

    b = L / M;
    N = L / a;

    plan->c = ltfat_gcd(a, M, &plan->h_a, &h_m);
    p = a / plan->c;
    q = M / plan->c;
    d = b / p;

    CHECKMEM( plan->gf    = LTFAT_NAME_COMPLEX(malloc)(L));
    CHECKMEM( plan->ff    = LTFAT_NAME_COMPLEX(malloc)(d * p * q * W));
    CHECKMEM( plan->cf    = LTFAT_NAME_COMPLEX(malloc)(d * q * q * W));
    CHECKMEM( plan->cwork = LTFAT_NAME_COMPLEX(malloc)(M * N * W));
    CHECKMEM( plan->cbuf  = LTFAT_NAME_COMPLEX(malloc)(d));
    plan->cin = cin;
    plan->f = f;
    LTFAT_NAME(wfac)(g, L, 1, a, M, plan->gf);

    /* Scaling constant needed because of FFTWs normalization. */
    plan->scalconst = (LTFAT_REAL)(1.0 / ((double)d * sqrt((double)M)));

    /* Create plans. In-place. */

    /* plan->p_after  = LTFAT_FFTW(plan_dft_1d)((int)d, */
    /*                  (LTFAT_FFTW(complex)*) plan->cbuf, */
    /*                  (LTFAT_FFTW(complex)*) plan->cbuf, */
    /*                  FFTW_FORWARD, flags); */
    /*  */
    /* CHECKINIT(plan->p_after, "FFTW plan failed."); */

    CHECKSTATUS(
        LTFAT_NAME_REAL(fft_init)(d, 1, plan->cbuf, plan->cbuf, flags, &plan->p_after));

    /* plan->p_before = LTFAT_FFTW(plan_dft_1d)((int)d, */
    /*                  (LTFAT_FFTW(complex)*) plan->cbuf, */
    /*                  (LTFAT_FFTW(complex)*) plan->cbuf, FFTW_BACKWARD, flags); */
    /* CHECKINIT(plan->p_before, "FFTW plan failed."); */

    CHECKSTATUS(
        LTFAT_NAME_REAL(ifft_init)(d, 1, plan->cbuf, plan->cbuf, flags,
                                   &plan->p_before));

    /* Create plan. Copy data so we do not overwrite input. Therefore
       it is ok to cast away the constness of cin.*/

    /* plan->p_veryend = LTFAT_FFTW(plan_many_dft)(1, &Mint, NWint, */
    /*                   (LTFAT_FFTW(complex)*) cin, NULL, 1, Mint, */
    /*                   (LTFAT_FFTW(complex)*) plan->cwork, NULL, */
    /*                   1, Mint, FFTW_BACKWARD, flags | FFTW_PRESERVE_INPUT); */
    /*  */
    /* CHECKINIT(plan->p_veryend, "FFTW plan failed."); */

    CHECKSTATUS(
        LTFAT_NAME_REAL(ifft_init)(M, N * W, cin, plan->cwork,
                                   flags | FFTW_PRESERVE_INPUT, &plan->p_veryend));

    *pout = plan;
    return status;
error:
    if (plan) LTFAT_NAME(idgt_long_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(idgt_long_done)(LTFAT_NAME(idgt_long_plan)** plan)
{
    LTFAT_NAME(idgt_long_plan)* p;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(*plan);
    p = *plan;

    if (p->p_before) LTFAT_NAME_REAL(ifft_done)(&p->p_before);
    if (p->p_after) LTFAT_NAME_REAL(fft_done)(&p->p_after);
    if (p->p_veryend) LTFAT_NAME_REAL(ifft_done)(&p->p_veryend);
    LTFAT_SAFEFREEALL(p->gf, p->ff, p->cf, p->cwork, p->cbuf);

    ltfat_free(p);
    p = NULL;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(idgt_long_execute)(LTFAT_NAME(idgt_long_plan)* p)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(p->f); CHECKNULL(p->cin);

    LTFAT_NAME_REAL(ifft_execute)(p->p_veryend);

    if (p->ptype == LTFAT_TIMEINV)
        LTFAT_NAME_COMPLEX(dgtphaseunlockhelper)(p->cwork, p->L, p->W, p->a,
                p->M, p->M, p->cwork);

    LTFAT_NAME(idgt_walnut_execute)(p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(idgt_long_execute_newarray)(LTFAT_NAME(idgt_long_plan)* p,
                                       const LTFAT_COMPLEX c[],
                                       LTFAT_COMPLEX f[])
{
    LTFAT_NAME(idgt_long_plan) p2;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(c); CHECKNULL(f);

    LTFAT_NAME_REAL(ifft_execute_newarray)(p->p_veryend, c, p->cwork);

    if (p->ptype == LTFAT_TIMEINV)
        LTFAT_NAME_COMPLEX(dgtphaseunlockhelper)(p->cwork, p->L, p->W, p->a,
                p->M, p->M, p->cwork);

    p2 = *p;
    p2.f = f;

    LTFAT_NAME(idgt_walnut_execute)(&p2);
error:
    return status;
}

LTFAT_API void
LTFAT_NAME(idgt_walnut_execute)(LTFAT_NAME(idgt_long_plan)* p)
{
    ltfat_int b = p->L / p->M;
    ltfat_int N = p->L / p->a;

    ltfat_int c = p->c;
    ltfat_int pp = p->a / c;
    ltfat_int q = p->M / c;
    ltfat_int d = b / pp;

    ltfat_int L = p->L;
    ltfat_int W = p->W;
    ltfat_int a = p->a;
    ltfat_int M = p->M;

    ltfat_int h_a = -p->h_a;

    /* Scaling constant needed because of FFTWs normalization. */
    const LTFAT_REAL scalconst = p->scalconst;

    /* -------- Main loop ----------------------------------- */

    ltfat_int ld4c = M * N;

    /* Leading dimensions of cf */
    ltfat_int ld3b = q * q * W;

    /* Leading dimensions of the 4dim array. */
    ltfat_int ld2ff = pp * q * W;

    for (ltfat_int r = 0; r < c; r++)
    {
        LTFAT_COMPLEX* cfp = p->cf;

        for (ltfat_int w = 0; w < W; w++)
        {
            /* Complete inverse fac of coefficients */
            for (ltfat_int l = 0; l < q; l++)
            {
                for (ltfat_int u = 0; u < q; u++)
                {
                    for (ltfat_int s = 0; s < d; s++)
                    {
                        ltfat_int rem = r + l * c +
                                        M * ltfat_positiverem(u + s * q - l * h_a, N)
                                        + w * ld4c;
                        p->cbuf[s] = p->cwork[rem];
                    }

                    /* Do inverse fft of length d */
                    LTFAT_NAME_REAL(fft_execute)(p->p_after);

                    for (ltfat_int s = 0; s < d; s++)
                    {
                        cfp[s * ld3b] =  p->cbuf[s];
                    }
                    /* Advance the cf pointer. This is only done in this
                    * one place, because the loops are placed such that
                    * this pointer will advance linearly through
                    * memory. Reordering the loops will break this. */
                    cfp++;
                }
            }
        }



        /* -------- compute matrix multiplication ---------- */


        /* Do the matmul  */
        for (ltfat_int s = 0; s < d; s++)
        {

            const LTFAT_COMPLEX* gbase = p->gf + (r + s * c) * pp * q;
            LTFAT_COMPLEX*       fbase = p->ff + s * pp * q * W;
            const LTFAT_COMPLEX* cbase = (const LTFAT_COMPLEX*)p->cf + s * q * q * W;

            for (ltfat_int nm = 0; nm < q * W; nm++)
            {
                for (ltfat_int km = 0; km < pp; km++)
                {

                    fbase[km + nm * pp] = 0.0;
                    for (ltfat_int mm = 0; mm < q; mm++)
                    {
                        fbase[km + nm * pp] += gbase[km + mm * pp] * cbase[mm + nm * q];
                    }
                    /* Scale because of FFTWs normalization. */
                    fbase[km + nm * pp] = fbase[km + nm * pp] * scalconst;
                }
            }
        }




        /* ----------- compute inverse signal factorization ---------- */


        LTFAT_COMPLEX* ffp = p->ff;
        LTFAT_COMPLEX* fp  = p->f + r;

        for (ltfat_int w = 0; w < W; w++)
        {
            for (ltfat_int l = 0; l < q; l++)
            {
                for (ltfat_int k = 0; k < pp; k++)
                {
                    for (ltfat_int s = 0; s < d; s++)
                    {
                        p->cbuf[s] = ffp[s * ld2ff];
                    }

                    LTFAT_NAME_REAL(ifft_execute)(p->p_before);

                    for (ltfat_int s = 0; s < d; s++)
                    {
                        ltfat_int rem = ltfat_positiverem(k * M + s * pp * M -
                                                          l * h_a * a, L);
                        fp[rem] = p->cbuf[s];
                    }

                    /* Advance the ff pointer. This is only done in this
                    * one place, because the loops are placed such that
                    * this pointer will advance linearly through
                    * memory. Reordering the loops will break this. */
                    ffp++;
                }
            }
            fp += L;
        }
        fp -= L * W;

        /* ----- Main loop ends here ------------- */
    }



}

/* LTFAT_API void */
/* LTFAT_NAME(idgt_fac)(const LTFAT_COMPLEX* cin, const LTFAT_COMPLEX* gf, */
/*                      ltfat_int L, ltfat_int W, */
/*                      ltfat_int a, ltfat_int M, */
/*                      const ltfat_phaseconvention ptype, */
/*                      LTFAT_COMPLEX* f) */
/* { */
/*  */
/*     #<{(|  --------- initial declarations -------------- |)}># */
/*  */
/*     ltfat_int h_a, h_m; */
/*  */
/*     LTFAT_FFTW(plan) p_before, p_after, p_veryend; */
/*     LTFAT_COMPLEX* ff, *cf, *cwork, *cbuf; */
/*  */
/*     #<{(|  ----------- calculation of parameters and plans -------- |)}># */
/*  */
/*     ltfat_int b = L / M; */
/*     ltfat_int N = L / a; */
/*  */
/*     ltfat_int c = ltfat_gcd(a, M, &h_a, &h_m); */
/*     ltfat_int p = a / c; */
/*     ltfat_int q = M / c; */
/*     ltfat_int d = b / p; */
/*  */
/*     h_a = -h_a; */
/*  */
/*     ff    = ltfat_malloc(d * p * q * W * sizeof * ff); */
/*     cf    = ltfat_malloc(d * q * q * W * sizeof * cf); */
/*     cwork = ltfat_malloc(M * N * W * sizeof * cwork); */
/*     cbuf  = ltfat_malloc(d * sizeof * cbuf); */
/*  */
/*     #<{(| Scaling constant needed because of FFTWs normalization. |)}># */
/*     const LTFAT_REAL scalconst = 1.0 / ((LTFAT_REAL)d * sqrt((LTFAT_REAL)M)); */
/*  */
/*     #<{(| Create plans. In-place. |)}># */
/*  */
/*     p_after  = LTFAT_FFTW(plan_dft_1d)(d, cbuf, cbuf, */
/*                                        FFTW_FORWARD, FFTW_ESTIMATE); */
/*  */
/*     p_before = LTFAT_FFTW(plan_dft_1d)(d, cbuf, cbuf, */
/*                                        FFTW_BACKWARD, FFTW_ESTIMATE); */
/*  */
/*     #<{(| Create plan. Copy data so we do not overwrite input. Therefore */
/*        it is ok to cast away the constness of cin.|)}># */
/*  */
/*     // Downcast to int */
/*     int Mint = (int) M; */
/*  */
/*     p_veryend = LTFAT_FFTW(plan_many_dft)(1, &Mint, N * W, */
/*                                           (LTFAT_COMPLEX*)cin, NULL, */
/*                                           1, Mint, */
/*                                           cwork, NULL, */
/*                                           1, Mint, */
/*                                           FFTW_BACKWARD, FFTW_ESTIMATE); */
/*  */
/*     #<{(| -------- Execute initial IFFT ------------------------ |)}># */
/*     LTFAT_FFTW(execute)(p_veryend); */
/*  */
/*  */
/*     if (ptype) */
/*         LTFAT_NAME_COMPLEX(dgtphaseunlockhelper)(cwork, L, W, a, M, cwork); */
/*  */
/*     #<{(| -------- Main loop ----------------------------------- |)}># */
/*  */
/*     ltfat_int ld4c = M * N; */
/*  */
/*     #<{(| Leading dimensions of cf |)}># */
/*     ltfat_int ld3b = q * q * W; */
/*  */
/*     #<{(| Leading dimensions of the 4dim array. |)}># */
/*     ltfat_int ld2ff = p * q * W; */
/*  */
/*     for (ltfat_int r = 0; r < c; r++) */
/*     { */
/*         LTFAT_COMPLEX* cfp = cf; */
/*  */
/*         for (ltfat_int w = 0; w < W; w++) */
/*         { */
/*             #<{(| Complete inverse fac of coefficients |)}># */
/*             for (ltfat_int l = 0; l < q; l++) */
/*             { */
/*                 for (ltfat_int u = 0; u < q; u++) */
/*                 { */
/*                     for (ltfat_int s = 0; s < d; s++) */
/*                     { */
/*                         ltfat_int rem = r + l * c + */
/*                                              ltfat_positiverem(u + s * q - l * h_a, N) */
/*                                              * M + w * ld4c; */
/*                         cbuf[s] = cwork[rem]; */
/*                     } */
/*  */
/*                     #<{(| Do inverse fft of length d |)}># */
/*                     LTFAT_FFTW(execute)(p_after); */
/*  */
/*                     for (ltfat_int s = 0; s < d; s++) */
/*                     { */
/*                         cfp[s * ld3b] =  cbuf[s]; */
/*                     } */
/*                     #<{(| Advance the cf pointer. This is only done in this */
/*                     * one place, because the loops are placed such that */
/*                     * this pointer will advance linearly through */
/*                     * memory. Reordering the loops will break this. |)}># */
/*                     cfp++; */
/*                 } */
/*             } */
/*         } */
/*  */
/*  */
/*  */
/*         #<{(| -------- compute matrix multiplication ---------- |)}># */
/*  */
/*  */
/*         #<{(| Do the matmul  |)}># */
/*         for (ltfat_int s = 0; s < d; s++) */
/*         { */
/*  */
/*             const LTFAT_COMPLEX* gbase = gf + (r + s * c) * p * q; */
/*             LTFAT_COMPLEX*       fbase = ff + s * p * q * W; */
/*             const LTFAT_COMPLEX* cbase = (const LTFAT_COMPLEX*)cf + s * q * q * W; */
/*  */
/*             for (ltfat_int nm = 0; nm < q * W; nm++) */
/*             { */
/*                 for (ltfat_int km = 0; km < p; km++) */
/*                 { */
/*  */
/*                     fbase[km + nm * p] = 0.0; */
/*                     for (ltfat_int mm = 0; mm < q; mm++) */
/*                     { */
/*                         fbase[km + nm * p] += gbase[km + mm * p] * cbase[mm + nm * q]; */
/*                     } */
/*                     #<{(| Scale because of FFTWs normalization. |)}># */
/*                     fbase[km + nm * p] = fbase[km + nm * p] * scalconst; */
/*                 } */
/*             } */
/*         } */
/*  */
/*  */
/*  */
/*  */
/*         #<{(| ----------- compute inverse signal factorization ---------- |)}># */
/*  */
/*  */
/*         LTFAT_COMPLEX* ffp = ff; */
/*         LTFAT_COMPLEX* fp  = f + r; */
/*  */
/*         for (ltfat_int w = 0; w < W; w++) */
/*         { */
/*             for (ltfat_int l = 0; l < q; l++) */
/*             { */
/*                 for (ltfat_int k = 0; k < p; k++) */
/*                 { */
/*                     for (ltfat_int s = 0; s < d; s++) */
/*                     { */
/*                         cbuf[s] = ffp[s * ld2ff]; */
/*                     } */
/*  */
/*                     LTFAT_FFTW(execute)(p_before); */
/*  */
/*                     for (ltfat_int s = 0; s < d; s++) */
/*                     { */
/*                         ltfat_int rem = ltfat_positiverem(k * M + s * p * M - */
/*                                                                l * h_a * a, L); */
/*                         fp[rem] = cbuf[s]; */
/*                     } */
/*  */
/*                     #<{(| Advance the ff pointer. This is only done in this */
/*                     * one place, because the loops are placed such that */
/*                     * this pointer will advance linearly through */
/*                     * memory. Reordering the loops will break this. |)}># */
/*                     ffp++; */
/*                 } */
/*             } */
/*             fp += L; */
/*         } */
/*         fp -= L * W; */
/*  */
/*         #<{(| ----- Main loop ends here ------------- |)}># */
/*     } */
/*  */
/*     #<{(| -----------  Clean up ----------------- |)}># */
/*  */
/*     LTFAT_FFTW(destroy_plan)(p_veryend); */
/*     LTFAT_FFTW(destroy_plan)(p_after); */
/*     LTFAT_FFTW(destroy_plan)(p_before); */
/*  */
/*     LTFAT_SAFEFREEALL(cwork, ff, cf, cbuf); */
/* } */
