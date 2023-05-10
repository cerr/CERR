#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

struct LTFAT_NAME(dgtreal_fb_plan)
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int gl;
    ltfat_phaseconvention ptype;
    LTFAT_NAME_REAL(fftreal_plan)* p_small;
    LTFAT_REAL*    sbuf;
    LTFAT_COMPLEX* cbuf;
    LTFAT_REAL* fw;
    LTFAT_REAL* gw;
    LTFAT_COMPLEX* cout;
};

LTFAT_API int
LTFAT_NAME(dgtreal_fb)(const LTFAT_REAL* f, const LTFAT_REAL* g,
                       ltfat_int L, ltfat_int gl,
                       ltfat_int W, ltfat_int a, ltfat_int M,
                       const ltfat_phaseconvention ptype, LTFAT_COMPLEX* cout)
{
    LTFAT_NAME(dgtreal_fb_plan)* plan = NULL;

    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        LTFAT_NAME(dgtreal_fb_init)(g, gl, a, M, ptype, FFTW_ESTIMATE, &plan));

    CHECKSTATUS(
        LTFAT_NAME(dgtreal_fb_execute)(plan, f, L, W, cout));

error:
    if (plan) LTFAT_NAME(dgtreal_fb_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_fb_init)(const LTFAT_REAL* g,
                            ltfat_int gl, ltfat_int a,
                            ltfat_int M, const ltfat_phaseconvention ptype,
                            unsigned flags, LTFAT_NAME(dgtreal_fb_plan)** pout)
{
    LTFAT_NAME(dgtreal_fb_plan)* plan = NULL;
    ltfat_int M2;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(g); CHECKNULL(pout);
    CHECK(LTFATERR_BADSIZE, gl > 0, "gl must be positive");
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a must be positive");
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M must be positive");
    CHECK(LTFATERR_CANNOTHAPPEN, ltfat_phaseconvention_is_valid(ptype),
          "Invalid ltfat_phaseconvention enum value." );

    CHECKMEM( plan = LTFAT_NEW(LTFAT_NAME(dgtreal_fb_plan)) );

    plan->a = a;
    plan->M = M;
    M2 = M / 2 + 1;
    plan->gl = gl;
    plan->ptype = ptype;

    CHECKMEM( plan->gw   = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM( plan->fw   = LTFAT_NAME_REAL(malloc)(gl));
    CHECKMEM( plan->sbuf = LTFAT_NAME_REAL(malloc)(M));
    CHECKMEM( plan->cbuf = LTFAT_NAME_COMPLEX(malloc)(M2));

    CHECKSTATUS(
        LTFAT_NAME_REAL(fftreal_init)(M, 1, plan->sbuf, plan->cbuf, flags,
                                      &plan->p_small));

    LTFAT_NAME(fftshift)(g, gl, plan->gw);

    *pout = plan;
    return status;
error:
    if (plan) LTFAT_NAME(dgtreal_fb_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(dgtreal_fb_done)(LTFAT_NAME(dgtreal_fb_plan)** plan)
{
    LTFAT_NAME(dgtreal_fb_plan)* pp;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(*plan);
    pp = *plan;
    LTFAT_SAFEFREEALL(pp->sbuf, pp->cbuf, pp->gw, pp->fw);
    if (pp->p_small) LTFAT_NAME_REAL(fftreal_done)(&pp->p_small);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

/* #define THE_SUM_REAL { \ */
/* ltfat_int premarg = plan.ptype?-glh:n*a-glh; \ */
/* for (ltfat_int m=0;m<M;m++) \ */
/* { \ */
/*    rem = ltfat_positiverem(m+(premarg), M); \ */
/*    sbuf[rem]=0.0; \ */
/*    fbd=fw+m; \ */
/*    for (ltfat_int k=0;k<gl/M;k++) \ */
/*    { \ */
/*      sbuf[rem]+=(*fbd);         \ */
/*       fbd+=M; \ */
/*    } \ */
/* } \ */
/* \ */
/*  LTFAT_FFTW(execute)(plan.p_small);         \ */
/* \ */
/* coefsum=(LTFAT_REAL*)cout+2*(n*M2+w*M2*N); \ */
/* for (ltfat_int m=0;m<M2;m++) \ */
/* { \ */
/*    coefsum[2*m]   = CH(creal)(cbuf[m]); \ */
/*    coefsum[2*m+1] = CH(cimag)(cbuf[m]); \ */
/* }} */

#define THE_SUM_REAL { \
LTFAT_NAME(fold_array)(fw,gl,plan->ptype==LTFAT_TIMEINV?-glh:n*a-glh,M,sbuf); \
LTFAT_NAME_REAL(fftreal_execute)(plan->p_small); \
memcpy(cout+(n*M2+w*M2*N),cbuf,M2*sizeof*cbuf); \
}

LTFAT_API int
LTFAT_NAME(dgtreal_fb_execute)(LTFAT_NAME(dgtreal_fb_plan)* plan,
                               const LTFAT_REAL* f,
                               ltfat_int L, ltfat_int W,
                               LTFAT_COMPLEX* cout)
{
    ltfat_int a, M, M2, N, gl, glh, glh_d_a;
    LTFAT_REAL* sbuf, *fw;
    const LTFAT_REAL* fbd;
    LTFAT_COMPLEX* cbuf;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(plan); CHECKNULL(f); CHECKNULL(cout);
    CHECK(LTFATERR_BADSIZE, L > 0, "L must be positive");
    CHECK(LTFATERR_BADTRALEN, L >= plan->gl && !(L % plan->a) ,
          "L (passed %td) must be greater or equal to gl and divisible by a (passed %td).",
          L, plan->a);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W must be positive");

    /*  --------- initial declarations -------------- */
    a = plan->a;
    M = plan->M;
    N = L / a;

    gl = plan->gl;
    sbuf = plan->sbuf;
    cbuf = plan->cbuf;
    fw = plan->fw;

    /* These are floor operations. */
    glh = plan->gl / 2;
    M2 = M / 2 + 1;

    /* This is a ceil operation. */
    glh_d_a = (ltfat_int)ceil((glh * 1.0) / (a));

    /*  ---------- main body ----------- */

    /*----- Handle the first boundary using periodic boundary conditions.*/
    for (ltfat_int n = 0; n < glh_d_a; n++)
    {
        for (ltfat_int w = 0; w < W; w++)
        {
            fbd = f + L - (glh - n * a) + L * w;
            for (ltfat_int l = 0; l < glh - n * a; l++)
                fw[l]  = fbd[l] * plan->gw[l];

            fbd = f - (glh - n * a) + L * w;
            for (ltfat_int l = glh - n * a; l < gl; l++)
                fw[l]  = fbd[l] * plan->gw[l];

            THE_SUM_REAL
        }
    }

    /* ----- Handle the middle case. --------------------- */
    for (ltfat_int n = glh_d_a; n < (L - (gl + 1) / 2) / a + 1; n++)
    {
        for (ltfat_int w = 0; w < W; w++)
        {
            fbd = f + (n * a - glh + L * w);
            for (ltfat_int l = 0; l < gl; l++)
                fw[l]  = fbd[l] * plan->gw[l];

            THE_SUM_REAL
        }

    }

    /* Handle the last boundary using periodic boundary conditions. */
    for (ltfat_int n = (L - (gl + 1) / 2) / a + 1; n < N; n++)
    {
        for (ltfat_int w = 0; w < W; w++)
        {
            fbd = f + (n * a - glh + L * w);
            for (ltfat_int l = 0; l < L - n * a + glh; l++)
                fw[l]  = fbd[l] * plan->gw[l];

            fbd = f - (L - n * a + glh) + L * w;
            for (ltfat_int l = L - n * a + glh; l < gl; l++)
                fw[l]  = fbd[l] * plan->gw[l];

            THE_SUM_REAL
        }
    }

error:
    return status;
}

#undef THE_SUM_REAL
