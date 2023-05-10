#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

struct LTFAT_NAME(dgt_fb_plan)
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int gl;
    ltfat_phaseconvention ptype;
    LTFAT_NAME_REAL(fft_plan)* p_small;
    LTFAT_COMPLEX* sbuf;
    LTFAT_COMPLEX* fw;
    LTFAT_TYPE* gw;
};

LTFAT_API int
LTFAT_NAME(dgt_fb)(const LTFAT_TYPE* f, const LTFAT_TYPE* g,
                   ltfat_int L, ltfat_int gl,
                   ltfat_int W,  ltfat_int a, ltfat_int M,
                   const ltfat_phaseconvention ptype, LTFAT_COMPLEX* cout)
{

    LTFAT_NAME(dgt_fb_plan)* plan = NULL;

    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        LTFAT_NAME(dgt_fb_init)(g, gl, a, M, ptype, FFTW_ESTIMATE, &plan));

    CHECKSTATUS(
        LTFAT_NAME(dgt_fb_execute)(plan, f, L, W, cout));

error:
    if (plan) LTFAT_NAME(dgt_fb_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgt_fb_init)(const LTFAT_TYPE* g,
                        ltfat_int gl, ltfat_int a, ltfat_int M,
                        const ltfat_phaseconvention ptype, unsigned flags, LTFAT_NAME(dgt_fb_plan)** p)
{
    LTFAT_NAME(dgt_fb_plan)* plan = NULL;

    int status = LTFATERR_SUCCESS;
    CHECKNULL(g);
    CHECKNULL(p);
    CHECK(LTFATERR_BADSIZE, gl > 0, "gl must be positive");
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive");
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive");
    CHECK(LTFATERR_CANNOTHAPPEN, ltfat_phaseconvention_is_valid(ptype),
          "Invalid ltfat_phaseconvention enum value." );

    CHECKMEM(plan = LTFAT_NEW(LTFAT_NAME(dgt_fb_plan)));

    plan->a = a;
    plan->M = M;
    plan->gl = gl;
    plan->ptype = ptype;

    CHECKMEM(plan->gw  = LTFAT_NAME(malloc)(plan->gl));
    CHECKMEM(plan->fw  = LTFAT_NAME_COMPLEX(calloc)(plan->gl));
    CHECKMEM(plan->sbuf = LTFAT_NAME_COMPLEX(malloc)(M));

    CHECKSTATUS(
        LTFAT_NAME_REAL(fft_init)(M, 1, plan->sbuf, plan->sbuf, flags, &plan->p_small));
    LTFAT_NAME(fftshift)(g, gl, plan->gw);
    LTFAT_NAME(conjugate_array)(plan->gw, gl, plan->gw);

    // Assign the "return" value
    *p = plan;
    return status;
error:
    if (plan) LTFAT_NAME(dgt_fb_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgt_fb_done)(LTFAT_NAME(dgt_fb_plan)** plan)
{
    int status = LTFATERR_SUCCESS;
    LTFAT_NAME(dgt_fb_plan)* pp = NULL;
    CHECKNULL(plan); CHECKNULL(*plan);
    pp = *plan;

    LTFAT_SAFEFREEALL(pp->sbuf, pp->gw, pp->fw);
    if (pp->p_small) LTFAT_NAME_REAL(fft_done)(&pp->p_small);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

/* The following macro adds the coefficients together performing the
 * last part of the Poisson summation, executes the FFT on the summed
 * coefficients, and places the coefficients in the output array.
 *
 * The first summation is done in that peculiar way to obtain the
 * correct phase for a frequency invariant Gabor transform. Summing
 * them directly would lead to a time invariant (phase-locked) Gabor
 * transform.
 *
 * The macro is called in three different places in the dgt_fb function.
 */
#define THE_SUM { \
LTFAT_NAME_COMPLEX(fold_array)(fw,gl,plan.ptype==LTFAT_TIMEINV?-glh:n*a-glh,M,sbuf); \
LTFAT_NAME_REAL(fft_execute)(plan.p_small); \
memcpy(cout + (n*M + w*M*N),sbuf,M*sizeof*cout); \
}

LTFAT_API int
LTFAT_NAME(dgt_fb_execute)(const LTFAT_NAME(dgt_fb_plan)* p,
                           const LTFAT_TYPE* f,
                           ltfat_int L, ltfat_int W,  LTFAT_COMPLEX* cout)
{
    ltfat_int a, M, N, gl, glh, glh_d_a;
    LTFAT_COMPLEX* sbuf, *fw;
    LTFAT_TYPE* fbd;
    LTFAT_NAME(dgt_fb_plan) plan;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(f); CHECKNULL(cout);
    CHECK(LTFATERR_BADTRALEN, L >= p->gl && !(L % p->a) ,
          "L (passed %td) must be positive and divisible by a (passed %td).", L, p->a);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");

    /*  --------- initial declarations -------------- */
    plan = *p;

    a = plan.a;
    M = plan.M;
    N = L / a;

    gl = plan.gl;
    sbuf = plan.sbuf;
    fw = plan.fw;

    /* This is a floor operation. */
    glh = plan.gl / 2;

    /* This is a ceil operation. */
    glh_d_a = (ltfat_int)ceil((glh * 1.0) / (a));


    /*  ---------- main body ----------- */

    /*----- Handle the first boundary using periodic boundary conditions.*/
    for (ltfat_int n = 0; n < glh_d_a; n++)
    {
        for (ltfat_int w = 0; w < W; w++)
        {

            fbd = (LTFAT_TYPE*)f + (L - (glh - n * a) + L * w);
            for (ltfat_int l = 0; l < glh - n * a; l++)
                fw[l] = fbd[l] * plan.gw[l];

            fbd = (LTFAT_TYPE*)f -  (glh - n * a) +  L * w;
            for (ltfat_int l = glh - n * a; l < gl; l++)
                fw[l] = fbd[l] * plan.gw[l];

            THE_SUM

        }
    }

    /* ----- Handle the middle case. --------------------- */
    for (ltfat_int n = glh_d_a; n < (L - (gl + 1) / 2) / a + 1; n++)
    {
        for (ltfat_int w = 0; w < W; w++)
        {
            fbd = (LTFAT_TYPE*)f + (n * a - glh + L * w);
            for (ltfat_int l = 0; l < gl; l++)
                fw[l] = fbd[l] * plan.gw[l];

            THE_SUM
        }

    }

    /* Handle the last boundary using periodic boundary conditions. */
    for (ltfat_int n = (L - (gl + 1) / 2) / a + 1; n < N; n++)
    {
        for (ltfat_int w = 0; w < W; w++)
        {
            fbd = (LTFAT_TYPE*)f + (n * a - glh + L * w);
            for (ltfat_int l = 0; l < L - n * a + glh; l++)
                fw[l] = fbd[l] * plan.gw[l];

            fbd = (LTFAT_TYPE*)f - (L - n * a + glh) +  L * w;
            for (ltfat_int l = L - n * a + glh; l < gl; l++)
                fw[l] = fbd[l] * plan.gw[l];

            THE_SUM
        }
    }

error:
    return status;
}

#undef THE_SUM
