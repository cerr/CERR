#include "dgtreal_long_private.h"

LTFAT_API int
LTFAT_NAME(dgtreal_long)(const LTFAT_REAL* f, const LTFAT_REAL* g,
                         ltfat_int L, ltfat_int W, ltfat_int a,
                         ltfat_int M, const ltfat_phaseconvention ptype,
                         LTFAT_COMPLEX* cout)
{

    LTFAT_NAME(dgtreal_long_plan) *plan = NULL;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(f); CHECKNULL(cout);

    CHECKSTATUS(
        LTFAT_NAME(dgtreal_long_init)(g, L, W, a, M, f, cout, ptype, FFTW_ESTIMATE,
                                      &plan));

    LTFAT_NAME(dgtreal_long_execute)(plan);

    LTFAT_NAME(dgtreal_long_done)(&plan);

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_long_init)( const LTFAT_REAL* g,
                               ltfat_int L, ltfat_int W,
                               ltfat_int a, ltfat_int M,
                               const LTFAT_REAL* f, LTFAT_COMPLEX* cout,
                               const ltfat_phaseconvention ptype,
                               unsigned flags, LTFAT_NAME(dgtreal_long_plan)** pout)
{
    LTFAT_NAME(dgtreal_long_plan)* plan = NULL;
    ltfat_int minL, N, h_m, b, p, q, d, d2, wfs;

    int status = LTFATERR_SUCCESS;
    CHECK(LTFATERR_NULLPOINTER, (flags & FFTW_ESTIMATE) || cout != NULL,
          "cout cannot be NULL if flags is not FFTW_ESTIMATE");
    // CHECKNULL(f); // f can be NULL
    CHECKNULL(g); CHECKNULL(pout);
    CHECK(LTFATERR_BADSIZE, L > 0, "L (passed %td) must be positive", L);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive");
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive");
    CHECK(LTFATERR_CANNOTHAPPEN, ltfat_phaseconvention_is_valid(ptype),
          "Invalid ltfat_phaseconvention enum value." );

    minL = ltfat_lcm(a, M);
    CHECK(LTFATERR_BADTRALEN, !(L % minL),
          "L must divisible by lcm(a,M)=%td.", minL);

    CHECKMEM(plan = LTFAT_NEW(LTFAT_NAME(dgtreal_long_plan)));

// f and cout can be NULL if flags is FFTW_ESTIMATE
    plan->a = a;
    plan->M = M;
    plan->L = L;
    plan->W = W;
    plan->ptype = ptype;
    N = L / a;

    plan->c = ltfat_gcd(a, M, &plan->h_a, &h_m);
    b = L / M;
    p = a / plan->c;
    q = M / plan->c;
    d = b / p;
    plan->h_a = -plan->h_a;

    d2 = d / 2 + 1;
    wfs = wfacreal_size(L, a, M);

    plan->cout = cout;
    plan->f    = f;
    CHECKMEM( plan->sbuf = LTFAT_NAME_REAL(malloc)( d ));
    CHECKMEM( plan->cbuf = LTFAT_NAME_COMPLEX(malloc)(d2));
    CHECKMEM( plan->ff = LTFAT_NAME_REAL(malloc)(2 * d2 * p * q * W));
    CHECKMEM( plan->cf = LTFAT_NAME_REAL(malloc)(2 * d2 * q * q * W));
    CHECKMEM( plan->gf = LTFAT_NAME_COMPLEX(malloc)(wfs));
    //CHECKMEM( plan->cwork = (LTFAT_REAL*) LTFAT_NAME_COMPLEX(malloc)(M2 * N * W));

    /* Get factorization of window */
    LTFAT_NAME(wfacreal)(g, L, 1, a, M, plan->gf);

    /* Create plans. In-place. */

    CHECKSTATUS(
        LTFAT_NAME(fftreal_init)(M, N * W,
                                 (LTFAT_REAL*) cout, cout, flags, &plan->p_veryend));

    CHECKSTATUS(
        LTFAT_NAME(fftreal_init)(d, 1, plan->sbuf, plan->cbuf, flags, &plan->p_before));

    CHECKSTATUS(
        LTFAT_NAME(ifftreal_init)(d, 1, plan->cbuf, plan->sbuf, flags, &plan->p_after));

    *pout = plan;
    return status;
error:
    if (plan) LTFAT_NAME(dgtreal_long_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_long_done)(LTFAT_NAME(dgtreal_long_plan)** plan)
{
    LTFAT_NAME(dgtreal_long_plan)* pp;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(*plan);
    pp = *plan;
    if (pp->p_veryend) LTFAT_NAME(fftreal_done)(&pp->p_veryend);
    if (pp->p_before)  LTFAT_NAME(fftreal_done)(&pp->p_before);
    if (pp->p_after)   LTFAT_NAME(ifftreal_done)(&pp->p_after);
    LTFAT_SAFEFREEALL(pp->sbuf, pp->cbuf,// pp->cwork,
                      pp->gf, pp->ff, pp->cf);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_long_execute)(LTFAT_NAME(dgtreal_long_plan)* plan)
{
    int status = LTFATERR_SUCCESS;
    ltfat_int M2;
    CHECKNULL(plan); CHECKNULL(plan->f); CHECKNULL(plan->cout);
    M2 = plan->M / 2 + 1;

    LTFAT_NAME(dgtreal_walnut_plan)(plan);

    if (plan->ptype == LTFAT_TIMEINV)
        LTFAT_NAME_REAL(dgtphaselockhelper)((LTFAT_REAL*) plan->cout, plan->L, plan->W,
                                            plan->a, 2 * M2, plan->M, (LTFAT_REAL*) plan->cout);

    /* FFT to modulate the coefficients. */
    LTFAT_NAME(fftreal_execute)(plan->p_veryend);

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_long_execute_newarray)(LTFAT_NAME(dgtreal_long_plan)* plan,
        const LTFAT_REAL* f, LTFAT_COMPLEX* c)
{
    int status = LTFATERR_SUCCESS;
    LTFAT_NAME(dgtreal_long_plan) plan2;
    ltfat_int M2;

    CHECKNULL(plan); CHECKNULL(f); CHECKNULL(c);
    M2 = plan->M / 2 + 1;

    // Make a shallow copy of the plan and overwrite f
    plan2 = *plan;
    plan2.f = f;
    plan2.cout = c;

    LTFAT_NAME(dgtreal_walnut_plan)(&plan2);

    if (plan->ptype == LTFAT_TIMEINV)
        LTFAT_NAME_REAL(dgtphaselockhelper)((LTFAT_REAL*)c, plan->L, plan->W, plan->a,
                                            2 * M2, plan->M, (LTFAT_REAL*) c);

    /* FFTW new array execute function */
    LTFAT_NAME(fftreal_execute_newarray)(plan->p_veryend, (LTFAT_REAL*)c, c);

error:
    return status;
}


/*  This routine computes the DGT factorization using strided FFTs so
    the memory layout is optimized for the matrix product. Compared to
    dgt_fac_1, it moves the r-loop to be the outermost loop to
    conserve memory and hopefully use the cache hierachy better

    The routine uses a very small buffer to do the DFTs.

    Integer indexing is optimized.

    Special code for integer oversampling.

*/

LTFAT_API int
LTFAT_NAME(dgtreal_walnut_plan)(LTFAT_NAME(dgtreal_long_plan)* plan)
{
    /*  --------- initial declarations -------------- */

    ltfat_int a = plan->a;
    ltfat_int M = plan->M;
    ltfat_int L = plan->L;
    ltfat_int W = plan->W;
    ltfat_int N = L / a;
    ltfat_int c = plan->c;
    ltfat_int p = a / c;
    ltfat_int q = M / c;
    ltfat_int d = N / q;
    ltfat_int M2 = M / 2 + 1;


    /* This is a floor operation. */
    ltfat_int d2 = d / 2 + 1;

    const LTFAT_REAL* f = plan->f;
    const LTFAT_COMPLEX* gf = (const LTFAT_COMPLEX*)plan->gf;

    ltfat_int h_a = plan->h_a;

    LTFAT_REAL* sbuf = plan->sbuf;
    LTFAT_COMPLEX* cbuf = plan->cbuf;

    LTFAT_REAL* cout = (LTFAT_REAL*) plan->cout;


    LTFAT_REAL* gbase, *fbase, *cbase;

    LTFAT_REAL* ffp;

    const LTFAT_REAL* fp;

    /* Scaling constant needed because of FFTWs normalization. */
    LTFAT_REAL scalconst = 
        ( LTFAT_REAL) ( 1.0 / ((double)d * sqrt(( double)M)));

    /* Leading dimensions of the 4dim array. */
    ltfat_int ld2a = 2 * p * q * W;

    /* Leading dimensions of cf */
    ltfat_int ld3b = 2 * q * q * W;

    /* --------- main loop begins here ------------------- */
    for (ltfat_int r = 0; r < c; r++)
    {
        /*  ---------- compute signal factorization ----------- */
        ffp = plan->ff;
        fp = f + r;
        if (p == 1)
        {
            /* Integer oversampling case */
            for (ltfat_int w = 0; w < W; w++)
            {
                for (ltfat_int l = 0; l < q; l++)
                {
                    for (ltfat_int s = 0; s < d; s++)
                    {
                        sbuf[s]   = fp[(s * M + l * a) % L];
                    }

                    LTFAT_NAME(fftreal_execute)(plan->p_before);

                    for (ltfat_int s = 0; s < d2; s++)
                    {
                        ffp[s * ld2a]   = ltfat_real(cbuf[s]) * scalconst;
                        ffp[s * ld2a + 1] = ltfat_imag(cbuf[s]) * scalconst;
                    }
                    ffp += 2;
                }
                fp += L;
            }
            /* fp -= 2 * L * W; */
        }
        else
        {
            /* rational sampling case */

            for (ltfat_int w = 0; w < W; w++)
            {
                for (ltfat_int l = 0; l < q; l++)
                {
                    for (ltfat_int k = 0; k < p; k++)
                    {
                        for (ltfat_int s = 0; s < d; s++)
                        {
                            sbuf[s]   = fp[ ltfat_positiverem(k * M + s * p * M - l * h_a * a, L) ];
                        }

                        LTFAT_NAME(fftreal_execute)(plan->p_before);

                        for (ltfat_int s = 0; s < d2; s++)
                        {
                            ffp[s * ld2a]   = ltfat_real(cbuf[s]) * scalconst;
                            ffp[s * ld2a + 1] = ltfat_imag(cbuf[s]) * scalconst;
                        }
                        ffp += 2;
                    }
                }
                fp += L;
            }
            /* fp -= 2 * L * W; */
        }

        /* ----------- compute matrix multiplication ----------- */

        /* Do the matmul  */
        if (p == 1)
        {
            /* Integer oversampling case */


            /* Rational oversampling case */
            for (ltfat_int s = 0; s < d2; s++)
            {
                gbase = (LTFAT_REAL*)gf + 2 * (r + s * c) * q;
                fbase = plan->ff + 2 * s * q * W;
                cbase = plan->cf + 2 * s * q * q * W;

                for (ltfat_int nm = 0; nm < q * W; nm++)
                {
                    for (ltfat_int mm = 0; mm < q; mm++)
                    {
                        cbase[0] = gbase[0] * fbase[0] + gbase[1] * fbase[1];
                        cbase[1] = gbase[0] * fbase[1] - gbase[1] * fbase[0];
                        gbase += 2;
                        cbase += 2;
                    }
                    gbase -= 2 * q;
                    fbase += 2;
                }
                cbase -= 2 * q * q * W;
            }

        }
        else
        {

            /* Rational oversampling case */
            for (ltfat_int s = 0; s < d2; s++)
            {
                gbase = (LTFAT_REAL*)gf + 2 * (r + s * c) * p * q;
                fbase = plan->ff + 2 * s * p * q * W;
                cbase = plan->cf + 2 * s * q * q * W;

                for (ltfat_int nm = 0; nm < q * W; nm++)
                {
                    for (ltfat_int mm = 0; mm < q; mm++)
                    {
                        cbase[0] = 0.0;
                        cbase[1] = 0.0;
                        for (ltfat_int km = 0; km < p; km++)
                        {
                            cbase[0] += gbase[0] * fbase[0] + gbase[1] * fbase[1];
                            cbase[1] += gbase[0] * fbase[1] - gbase[1] * fbase[0];
                            gbase += 2;
                            fbase += 2;
                        }
                        fbase -= 2 * p;
                        cbase += 2;
                    }
                    gbase -= 2 * q * p;
                    fbase += 2 * p;
                }
                cbase -= 2 * q * q * W;
                fbase -= 2 * p * q * W;
            }
        }



        /*  -------  compute inverse coefficient factorization ------- */
        LTFAT_REAL* cfp = plan->cf;
        ltfat_int ld5c = 2 * M2 * N;

        /* Cover both integer and rational sampling case */
        for (ltfat_int w = 0; w < W; w++)
        {
            /* Complete inverse fac of coefficients */
            for (ltfat_int l = 0; l < q; l++)
            {
                for (ltfat_int u = 0; u < q; u++)
                {
                    for (ltfat_int s = 0; s < d2; s++)
                    {
                        LTFAT_REAL* cbufTmp = (LTFAT_REAL*) &cbuf[s];
                        cbufTmp[0] = cfp[s * ld3b];
                        cbufTmp[1] = cfp[s * ld3b + 1];
                    }
                    cfp += 2;

                    /* Do inverse fft of length d */
                    LTFAT_NAME(ifftreal_execute)(plan->p_after);

                    for (ltfat_int s = 0; s < d; s++)
                    {
                        cout[ r + l * c + ltfat_positiverem(u + s * q - l * h_a,
                                                            N) * 2 * M2 + w * ld5c ] = sbuf[s];
                    }
                }
            }
        }


        /* ----------- Main loop ends here ------------------------ */
    }

    return 0;
}
