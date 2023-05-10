#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

struct LTFAT_NAME(iwfac_plan)
{
    ltfat_int b;
    ltfat_int c;
    ltfat_int p;
    ltfat_int q;
    ltfat_int d;
    ltfat_int a;
    ltfat_int M;
    ltfat_int L;
    LTFAT_REAL scaling;
    LTFAT_REAL* sbuf;
    /* LTFAT_FFTW(plan) p_before; */
    LTFAT_NAME_REAL(ifft_plan)* p_before;
};

LTFAT_API int
LTFAT_NAME(iwfac)(const LTFAT_COMPLEX* gf, ltfat_int L, ltfat_int R,
                  ltfat_int a, ltfat_int M, LTFAT_TYPE* g)
{
    LTFAT_NAME(iwfac_plan)* p = NULL;

    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        LTFAT_NAME(iwfac_init)( L, a, M, FFTW_MEASURE, &p));

    CHECKSTATUS(
        LTFAT_NAME(iwfac_execute)(p, gf, R, g));

error:
    if (p) LTFAT_NAME(iwfac_done)(&p);
    return status;
}

LTFAT_API int
LTFAT_NAME(iwfac_init)(ltfat_int L, ltfat_int a, ltfat_int M,
                       unsigned flags, LTFAT_NAME(iwfac_plan)** pout)
{
    ltfat_int minL, h_a, h_m;
    LTFAT_NAME(iwfac_plan)* plan = NULL;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(pout);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a (passed %td) must be positive.", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M (passed %td) must be positive.", M);

    minL = ltfat_lcm(a, M);
    CHECK(LTFATERR_BADARG,
          L > 0 && !(L % minL),
          "L (passed %td) must be positive and divisible by lcm(a,M)=%td.",
          L, minL);

    CHECKMEM(plan = LTFAT_NEW(LTFAT_NAME(iwfac_plan)) );

    plan->b = L / M;
    plan->c = ltfat_gcd(a, M, &h_a, &h_m);
    plan->p = a / plan->c;
    plan->q = M / plan->c;
    plan->d = plan->b / plan->p;
    plan->a = a; plan->M = M; plan->L = L;
    plan->scaling = (LTFAT_REAL)( 1.0 / sqrt((double)M) / plan->d );

    CHECKMEM(plan->sbuf = LTFAT_NAME_REAL(malloc)(2 * plan->d));

    /* Create plan. In-place. */
    /* plan->p_before = LTFAT_FFTW(plan_dft_1d)((int)plan->d, */
    /*                  (LTFAT_FFTW(complex)*) plan->sbuf, */
    /*                  (LTFAT_FFTW(complex)*) plan->sbuf, */
    /*                  FFTW_BACKWARD, flags); */
    LTFAT_NAME_REAL(ifft_init)(plan->d, 1,
                               (LTFAT_COMPLEX*) plan->sbuf,
                               (LTFAT_COMPLEX*) plan->sbuf,
                               flags, &plan->p_before);

    CHECKINIT(plan->p_before, "FFTW plan creation failed.");

    *pout = plan;
    return status;
error:
    if (plan)
    {
        /* if (plan->p_before) LTFAT_FFTW(destroy_plan)(plan->p_before); */
        if (plan->p_before) LTFAT_NAME_REAL(ifft_done)(&plan->p_before);
        ltfat_free(plan->sbuf);
        ltfat_free(plan);
    }
    *pout = NULL;
    return status;
}

LTFAT_API int
LTFAT_NAME(iwfac_execute)(LTFAT_NAME(iwfac_plan)* plan, const LTFAT_COMPLEX* gf,
                          ltfat_int R, LTFAT_TYPE* g)
{
    ltfat_int rem, negrem, c, p, q, d, M, a, L, ld3;
    LTFAT_REAL scaling;
    LTFAT_REAL* sbuf, *gfp;
    /* LTFAT_FFTW(plan) p_before; */
    LTFAT_NAME_REAL(ifft_plan)* p_before;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(g); CHECKNULL(gf);
    CHECK(LTFATERR_NOTPOSARG, R > 0, "R (passed %td) must be positive.", R);

    c = plan->c;
    p = plan->p;
    q = plan->q;
    d = plan->d;
    M = plan->M;
    a = plan->a;
    L = plan->L;

    scaling = plan->scaling;
    sbuf = plan->sbuf;
    p_before = plan->p_before;

    ld3 = c * p * q * R;
    gfp = (LTFAT_REAL*)gf;

    for (ltfat_int r = 0; r < c; r++)
    {
        for (ltfat_int w = 0; w < R; w++)
        {
            for (ltfat_int l = 0; l < q; l++)
            {
                for (ltfat_int k = 0; k < p; k++)
                {
                    negrem = ltfat_positiverem(k * M - l * a, L);
                    for (ltfat_int s = 0; s < 2 * d; s += 2)
                    {
                        sbuf[s]   = gfp[s * ld3] * scaling;
                        sbuf[s + 1] = gfp[s * ld3 + 1] * scaling;
                    }

                    /* LTFAT_FFTW(execute)(p_before); */
                    LTFAT_NAME_REAL(ifft_execute)(p_before);

                    for (ltfat_int s = 0; s < d; s++)
                    {
                        rem = (negrem + s * p * M) % L;
#ifdef LTFAT_COMPLEXTYPE
                        LTFAT_REAL* gTmp = (LTFAT_REAL*) & (g[r + rem + L * w]);
                        gTmp[0] = sbuf[2 * s];
                        gTmp[1] = sbuf[2 * s + 1];
#else
                        g[r + rem + L * w] = sbuf[2 * s];
#endif
                    }
                    gfp += 2;
                }
            }
        }
    }

error:
    return status;
}

LTFAT_API int
LTFAT_NAME(iwfac_done)(LTFAT_NAME(iwfac_plan)** pout)
{
    int status = LTFATERR_SUCCESS;
    CHECKNULL(pout);
    CHECKNULL(*pout);

    /* LTFAT_FFTW(destroy_plan)((*pout)->p_before); */
    LTFAT_NAME_REAL(ifft_done)(&(*pout)->p_before);
    ltfat_free((*pout)->sbuf);
    ltfat_free(*pout);
    *pout = NULL;
error:
    return status;
}
