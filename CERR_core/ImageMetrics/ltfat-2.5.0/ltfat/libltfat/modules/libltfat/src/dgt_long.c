#include "dgt_long_private.h"

LTFAT_API int
LTFAT_NAME(dgt_long)(const LTFAT_TYPE* f, const LTFAT_TYPE* g,
                     ltfat_int L, ltfat_int W,
                     ltfat_int a, ltfat_int M,
                     const ltfat_phaseconvention ptype, LTFAT_COMPLEX* cout)
{
    LTFAT_NAME(dgt_long_plan)* plan = NULL;

    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        LTFAT_NAME(dgt_long_init)( g, L, W, a, M, f, cout, ptype, FFTW_ESTIMATE, &plan));

    CHECKSTATUS(
        LTFAT_NAME(dgt_long_execute)(plan));

error:
    if (plan) LTFAT_NAME(dgt_long_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgt_long_init)( const LTFAT_TYPE* g,
                           ltfat_int L, ltfat_int W,
                           ltfat_int a, ltfat_int M,
                           const LTFAT_TYPE* f, LTFAT_COMPLEX* cout,
                           const ltfat_phaseconvention ptype, unsigned flags,
                           LTFAT_NAME(dgt_long_plan)** pout)
{
    LTFAT_NAME(dgt_long_plan)* plan = NULL;
    ltfat_int h_m, N, b, p, q, d, minL;

    int status = LTFATERR_SUCCESS;
    // CHECKNULL(f); // Can be NULL
    CHECK(LTFATERR_NULLPOINTER, (flags & FFTW_ESTIMATE) || cout != NULL,
          "cout cannot be NULL if flags is not FFTW_ESTIMATE");

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

    CHECKMEM(plan = LTFAT_NEW(LTFAT_NAME(dgt_long_plan)) );

    plan->a = a;
    plan->M = M;
    plan->L = L;
    plan->W = W;
    plan->ptype = ptype;
    N = L / a;
    b = L / M;

    plan->c = ltfat_gcd(a, M, &plan->h_a, &h_m);
    p = a / plan->c;
    q = M / plan->c;
    d = b / p;
    plan->h_a = -plan->h_a;

    CHECKMEM( plan->sbuf = LTFAT_NAME_REAL(malloc)(2 * d));
    CHECKMEM( plan->gf   = LTFAT_NAME_COMPLEX(malloc)(L));
    CHECKMEM( plan->ff = LTFAT_NAME_REAL(malloc)(2 * d * p * q * W));
    CHECKMEM( plan->cf = LTFAT_NAME_REAL(malloc)(2 * d * q * q * W));
    plan->cout = cout;
    plan->f    = f;

    /* Get factorization of window */
    CHECKSTATUS(
        LTFAT_NAME(wfac)(g, L, 1, a, M, plan->gf));

    CHECKSTATUS(
        LTFAT_NAME_REAL(fft_init)(M, N * W, cout, cout, flags, &plan->p_veryend));

    CHECKSTATUS(
        LTFAT_NAME_REAL(fft_init)(d, 1, (LTFAT_COMPLEX*) plan->sbuf,
                                  (LTFAT_COMPLEX*) plan->sbuf, flags, &plan->p_before));

    CHECKSTATUS(
        LTFAT_NAME_REAL(ifft_init)(d, 1, (LTFAT_COMPLEX*) plan->sbuf,
                                   (LTFAT_COMPLEX*) plan->sbuf, flags, &plan->p_after));

    // Assign the "return" value
    *pout = plan;
    return status;
error:
    if (plan) LTFAT_NAME(dgt_long_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgt_long_done)(LTFAT_NAME(dgt_long_plan)** plan)
{
    LTFAT_NAME(dgt_long_plan)* pp;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(*plan);
    pp = *plan;

    if (pp->p_veryend) LTFAT_NAME_REAL(fft_done)(&pp->p_veryend);
    if (pp->p_before) LTFAT_NAME_REAL(fft_done)(&pp->p_before);
    if (pp->p_after) LTFAT_NAME_REAL(ifft_done)(&pp->p_after);
    LTFAT_SAFEFREEALL(pp->sbuf, pp->gf, pp->ff, pp->cf);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgt_long_execute)(LTFAT_NAME(dgt_long_plan)* plan)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(plan->f); CHECKNULL(plan->cout);

    LTFAT_NAME(dgt_walnut_execute)(plan, plan->cout);

    if (LTFAT_TIMEINV == plan->ptype)
        LTFAT_NAME_COMPLEX(dgtphaselockhelper)(plan->cout, plan->L, plan->W,
                                               plan->a, plan->M, plan->M, plan->cout);

    /* FFT to modulate the coefficients. */
    LTFAT_NAME_REAL(fft_execute)(plan->p_veryend);

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(dgt_long_execute_newarray)(LTFAT_NAME(dgt_long_plan)* plan,
                                      const LTFAT_TYPE f[], LTFAT_COMPLEX c[])
{
    LTFAT_NAME(dgt_long_plan) plan2;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(f); CHECKNULL(c);

    // Make a shallow copy and assign f
    plan2 = *plan;
    plan2.f = f;

    LTFAT_NAME(dgt_walnut_execute)(&plan2, c);

    if (LTFAT_TIMEINV == plan->ptype)
        LTFAT_NAME_COMPLEX(dgtphaselockhelper)(c, plan->L, plan->W,
                                               plan->a, plan->M, plan->M, c);

    /* FFT to modulate the coefficients. */
    LTFAT_NAME_REAL(fft_execute_newarray)(plan->p_veryend, c, c);

    /* LTFAT_FFTW(execute_dft)(plan->p_veryend, (LTFAT_FFTW(complex)*)c, */
    /*                         (LTFAT_FFTW(complex)*)c); */

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

    Code works on LTFAT_REAL's instead on LTFAT_COMPLEX
*/


LTFAT_API int
LTFAT_NAME(dgt_walnut_execute)(LTFAT_NAME(dgt_long_plan)* plan,
                               LTFAT_COMPLEX* cout)
{

    /*  --------- initial declarations -------------- */

    LTFAT_REAL* gbase, *fbase, *cbase;

    ltfat_int rem;

    LTFAT_REAL* ffp, *cfp;
    LTFAT_TYPE* fp;

    /*  ----------- calculation of parameters and plans -------- */

    ltfat_int a = plan->a;
    ltfat_int M = plan->M;
    ltfat_int L = plan->L;
    ltfat_int W = plan->W;
    ltfat_int N = L / a;
    ltfat_int c = plan->c;
    ltfat_int p = a / c;
    ltfat_int q = M / c;
    ltfat_int d = N / q;

    LTFAT_TYPE* f = (LTFAT_TYPE*) plan->f;
    const LTFAT_COMPLEX* gf = (const LTFAT_COMPLEX*)plan->gf;

    ltfat_int h_a = plan->h_a;

    LTFAT_REAL* sbuf = plan->sbuf;
    //LTFAT_COMPLEX* cout = plan->cout;

    /* Scaling constant needed because of FFTWs normalization. */
    LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / ((double)d * sqrt((
                                     double)M)) );

    /* Leading dimensions of the 4dim array. */
    ltfat_int ld2a = 2 * p * q * W;

    /* Leading dimensions of cf */
    ltfat_int ld3b = 2 * q * q * W;
    ltfat_int ld5c = M * N;

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
                        rem = (s * M + l * a) % L;
#ifdef LTFAT_COMPLEXTYPE
                        sbuf[2 * s]   = ltfat_real(fp[rem]);
                        sbuf[2 * s + 1] = ltfat_imag(fp[rem]);
#else
                        sbuf[2 * s]   = fp[rem];
                        sbuf[2 * s + 1] = 0.0;
#endif
                    }

                    LTFAT_NAME_REAL(fft_execute)(plan->p_before);

                    for (ltfat_int s = 0; s < d; s++)
                    {
                        ffp[s * ld2a]   = sbuf[2 * s] * scalconst;
                        ffp[s * ld2a + 1] = sbuf[2 * s + 1] * scalconst;
                    }
                    ffp += 2;
                }
                fp += L;
            }
            fp -= L * W;

            /* Do the Matmul */
            for (ltfat_int s = 0; s < d; s++)
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
            /* rational sampling case */

            for (ltfat_int w = 0; w < W; w++)
            {
                for (ltfat_int l = 0; l < q; l++)
                {
                    for (ltfat_int k = 0; k < p; k++)
                    {
                        for (ltfat_int s = 0; s < d; s++)
                        {
                            rem = ltfat_positiverem(k * M + s * p * M - l * h_a * a, L);
#ifdef LTFAT_COMPLEXTYPE
                            sbuf[2 * s]   = ltfat_real(fp[rem]);
                            sbuf[2 * s + 1] = ltfat_imag(fp[rem]);
#else
                            sbuf[2 * s]   = fp[rem];
                            sbuf[2 * s + 1] = 0.0;
#endif
                        }

                        LTFAT_NAME_REAL(fft_execute)(plan->p_before);

                        for (ltfat_int s = 0; s < d; s++)
                        {
                            ffp[s * ld2a]   = sbuf[2 * s] * scalconst;
                            ffp[s * ld2a + 1] = sbuf[2 * s + 1] * scalconst;
                        }
                        ffp += 2;
                    }
                }
                fp += L;
            }
            fp -= L * W;

            // Matmul
            for (ltfat_int s = 0; s < d; s++)
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

        } /* end of if p==1 */

        /*  -------  compute inverse coefficient factorization ------- */
        cfp = plan->cf;

        /* Cover both integer and rational sampling case */
        for (ltfat_int w = 0; w < W; w++)
        {
            /* Complete inverse fac of coefficients */
            for (ltfat_int l = 0; l < q; l++)
            {
                for (ltfat_int u = 0; u < q; u++)
                {
                    for (ltfat_int s = 0; s < d; s++)
                    {
                        sbuf[2 * s]   = cfp[s * ld3b];
                        sbuf[2 * s + 1] = cfp[s * ld3b + 1];
                    }
                    cfp += 2;

                    /* Do inverse fft of length d */
                    LTFAT_NAME_REAL(ifft_execute)(plan->p_after);

                    for (ltfat_int s = 0; s < d; s++)
                    {
                        rem = r + l * c + ltfat_positiverem(u + s * q - l * h_a, N) * M + w * ld5c;
                        LTFAT_REAL* coutTmp = (LTFAT_REAL*) &cout[rem];
                        coutTmp[0] = sbuf[2 * s];
                        coutTmp[1] = sbuf[2 * s + 1];
                    }
                }
            }
        }


        /* ----------- Main loop ends here ------------------------ */
    }

    return LTFATERR_SUCCESS;
}
