#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

struct LTFAT_NAME(idgtreal_long_plan)
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int L;
    ltfat_int W;
    ltfat_int c;
    ltfat_int h_a;
    ltfat_phaseconvention ptype;
    LTFAT_REAL scalconst;
    LTFAT_REAL* f;
    LTFAT_COMPLEX* cin;
    LTFAT_COMPLEX* gf;
    LTFAT_COMPLEX* ff;
    LTFAT_COMPLEX* cf;
    LTFAT_COMPLEX* cbuf;
    LTFAT_REAL* cwork;
    int freecwork;
    LTFAT_REAL* sbuf;
    LTFAT_NAME(ifftreal_plan)* p_veryend;
    LTFAT_NAME(ifftreal_plan)* p_before;
    LTFAT_NAME(fftreal_plan)* p_after;
    int do_overwriteoutarray;
};


LTFAT_API int
LTFAT_NAME(idgtreal_long)(const LTFAT_COMPLEX* cin, const LTFAT_REAL* g,
                          ltfat_int L, ltfat_int W,
                          ltfat_int a, ltfat_int M,
                          const ltfat_phaseconvention ptype, LTFAT_REAL* f)
{
    LTFAT_NAME(idgtreal_long_plan)* plan = NULL;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(cin); CHECKNULL(f);

    CHECKSTATUS(
        LTFAT_NAME(idgtreal_long_init)( g, L, W, a, M,
                                        (LTFAT_COMPLEX*)cin, f,
                                        ptype, FFTW_ESTIMATE, &plan));

    LTFAT_NAME(idgtreal_long_execute)(plan);

    LTFAT_NAME(idgtreal_long_done)(&plan);

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(idgtreal_long_set_overwriteoutarray)(
    LTFAT_NAME(idgtreal_long_plan)* p, int do_overwriteoutarray)
{
    int status = LTFATERR_FAILED;
    CHECKNULL(p);
    p->do_overwriteoutarray = do_overwriteoutarray;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(idgtreal_long_init)( const LTFAT_REAL* g,
                                ltfat_int L, ltfat_int W,
                                ltfat_int a, ltfat_int M,
                                LTFAT_COMPLEX* cin, LTFAT_REAL* f,
                                const ltfat_phaseconvention ptype, unsigned flags,
                                LTFAT_NAME(idgtreal_long_plan)** pout)
{
    ltfat_int minL, h_m, b, N, p, q, d, d2, size;
    // Downcast to int
    LTFAT_NAME(idgtreal_long_plan)* plan = NULL;
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
          !(L % minL), "L (passed %td) must be divisible by lcm(a,M)=%td.", L, minL);

    CHECKMEM(plan = LTFAT_NEW(LTFAT_NAME(idgtreal_long_plan)) );

    /*  ----------- calculation of parameters and plans -------- */

    plan->a = a; plan->L = L; plan->M = M; plan->W = W; plan->ptype = ptype;
    plan->do_overwriteoutarray = 1;
    b = L / M;
    N = L / a;

    plan->c = ltfat_gcd(a, M, &plan->h_a, &h_m);
    p = a / plan->c;
    q = M / plan->c;
    d = b / p;

    /* This is a floor operation. */
    d2 = d / 2 + 1;

    size = wfacreal_size(L, a, M);
    CHECKMEM( plan->gf    = LTFAT_NAME_COMPLEX(malloc)(size));
    CHECKMEM( plan->ff    = LTFAT_NAME_COMPLEX(malloc)(d2 * p * q * W));
    CHECKMEM( plan->cf    = LTFAT_NAME_COMPLEX(malloc)(d2 * q * q * W));
    CHECKMEM( plan->cbuf  = LTFAT_NAME_COMPLEX(malloc)(d2));
    CHECKMEM( plan->sbuf  = LTFAT_NAME_REAL(malloc)(d));
    plan->cin = cin;
    plan->f = f;

    if ( flags & FFTW_DESTROY_INPUT )
    {
        CHECKSTATUS(
            LTFAT_NAME(ifftreal_init)(M, N * W, plan->cin, (LTFAT_REAL*) plan->cin,
                                      flags, &plan->p_veryend));

        plan->cwork = (LTFAT_REAL*) plan->cin;
    }
    else
    {
        CHECKMEM( plan->cwork = LTFAT_NAME_REAL(malloc)(M * N * W));
        plan->freecwork = 1;

        CHECKSTATUS(
            LTFAT_NAME(ifftreal_init)(M, N * W, plan->cin, plan->cwork,
                                      flags | FFTW_PRESERVE_INPUT, &plan->p_veryend));
    }

    LTFAT_NAME(wfacreal)(g, L, 1, a, M, plan->gf);

    /* Scaling constant needed because of FFTWs normalization. */
    plan->scalconst = (LTFAT_REAL) ( 1.0 / ((double)d * sqrt((double)M)));

    CHECKSTATUS(
        LTFAT_NAME(ifftreal_init)(d, 1, plan->cbuf, plan->sbuf, flags,
                                  &plan->p_before));

    CHECKSTATUS(
        LTFAT_NAME(fftreal_init)(d, 1, plan->sbuf, plan->cbuf, flags, &plan->p_after));

    *pout = plan;
    return status;
error:
    if (plan) LTFAT_NAME(idgtreal_long_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(idgtreal_long_done)(LTFAT_NAME(idgtreal_long_plan)** plan)
{
    LTFAT_NAME(idgtreal_long_plan)* p;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(*plan);
    p = *plan;

    if (p->p_before)  LTFAT_NAME(ifftreal_done)(&p->p_before);
    if (p->p_after)   LTFAT_NAME(fftreal_done)(&p->p_after);
    if (p->p_veryend) LTFAT_NAME(ifftreal_done)(&p->p_veryend);
    LTFAT_SAFEFREEALL(p->gf, p->ff, p->cf, p->cbuf, p->sbuf);
    if ( p->freecwork) ltfat_free(p->cwork);
    ltfat_free(p);
    p = NULL;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(idgtreal_long_execute)(LTFAT_NAME(idgtreal_long_plan)* p)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(p->f); CHECKNULL(p->cin);

    LTFAT_NAME(ifftreal_execute)(p->p_veryend);

    if (p->ptype == LTFAT_TIMEINV)
        LTFAT_NAME_REAL(dgtphaseunlockhelper)(p->cwork, p->L, p->W, p->a, p->M, p->M,
                                              p->cwork);

    LTFAT_NAME(idgtreal_walnut_execute)(p);
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(idgtreal_long_execute_newarray)(LTFAT_NAME(idgtreal_long_plan)* p,
        const LTFAT_COMPLEX* c, LTFAT_REAL* f)
{
    LTFAT_NAME(idgtreal_long_plan) p2;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(c); CHECKNULL(f);

    // The plan was created with the FFTW_PRESERVE_INPUT so it is ok to cast away the const
    LTFAT_NAME(ifftreal_execute_newarray)(p->p_veryend, c, p->cwork);

    if (p->ptype == LTFAT_TIMEINV)
        LTFAT_NAME_REAL(dgtphaseunlockhelper)(p->cwork, p->L, p->W, p->a, p->M, p->M,
                                              p->cwork);

    // Make a shallow copy and rewrite f
    p2 = *p;
    p2.f = f;

    LTFAT_NAME(idgtreal_walnut_execute)(&p2);
error:
    return status;
}

LTFAT_API void
LTFAT_NAME(idgtreal_walnut_execute)(LTFAT_NAME(idgtreal_long_plan)* p)
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

    /* This is a floor operation. */
    ltfat_int d2 = d / 2 + 1;

    ltfat_int h_a = -p->h_a;

    /* Scaling constant needed because of FFTWs normalization. */
    const LTFAT_REAL scalconst = p->scalconst;

    ltfat_int ld4c = p->M * N;

    /* Leading dimensions of cf */
    ltfat_int ld3b = q * q * W;

    /* Leading dimensions of the 4dim array. */
    ltfat_int ld2ff = pp * q * W;

    /* -------- Main loop ----------------------------------- */
    for (ltfat_int r = 0; r < c; r++)
    {
        /* -------- compute coefficient factorization ----------- */

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
                        p->sbuf[s] = p->cwork[r + l * c +
                                              ltfat_positiverem(u + s * q - l * h_a, N) *
                                              M + w * ld4c];
                    }

                    /* Do inverse fft of length d */
                    LTFAT_NAME(fftreal_execute)(p->p_after);

                    for (ltfat_int s = 0; s < d2; s++)
                    {
                        cfp[s * ld3b] = p->cbuf[s];
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
        for (ltfat_int s = 0; s < d2; s++)
        {
            const LTFAT_COMPLEX* gbase = p->gf + (r + s * c) * pp * q;
            LTFAT_COMPLEX*       fbase = p->ff + s * pp * q * W;
            const LTFAT_COMPLEX* cbase = p->cf + s * q * q * W;

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
        LTFAT_REAL*    fp  = p->f + r;

        for (ltfat_int w = 0; w < W; w++)
        {
            for (ltfat_int l = 0; l < q; l++)
            {
                for (ltfat_int k = 0; k < pp; k++)
                {
                    for (ltfat_int s = 0; s < d2; s++)
                    {
                        p->cbuf[s] = ffp[s * ld2ff];
                    }

                    LTFAT_NAME(ifftreal_execute)(p->p_before);

                    for (ltfat_int s = 0; s < d; s++)
                    {
                        if (p->do_overwriteoutarray)
                            fp[ltfat_positiverem(k * M + s * pp * M - l * h_a * a, L)] = p->sbuf[s];
                        else
                            fp[ltfat_positiverem(k * M + s * pp * M - l * h_a * a, L)] += p->sbuf[s];
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
    }
}
