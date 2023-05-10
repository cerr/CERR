#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

struct LTFAT_NAME(idgt_fb_plan)
{
    ltfat_int a;
    ltfat_int M;
    ltfat_int gl;
    ltfat_phaseconvention ptype;
    LTFAT_COMPLEX* cbuf;
    LTFAT_TYPE*    gw;
    LTFAT_COMPLEX* ff;
    LTFAT_NAME_REAL(ifft_plan)* p_small;
};

#define THE_SUM { \
    memcpy(cbuf,cin+n*M+w*M*N,M*sizeof*cbuf); \
    LTFAT_NAME_REAL(ifft_execute)(p->p_small); \
    LTFAT_NAME_COMPLEX(circshift)(cbuf,M,p->ptype==LTFAT_TIMEINV?glh:-n*a+glh,ff); \
    LTFAT_NAME_COMPLEX(periodize_array)(ff,M,gl,ff); \
    for (ltfat_int ii=0; ii<gl; ii++) \
        ff[ii] *= gw[ii]; \
}

LTFAT_API int
LTFAT_NAME(idgt_fb)(const LTFAT_COMPLEX* cin, const LTFAT_TYPE* g,
                    ltfat_int L, ltfat_int gl, ltfat_int W,
                    ltfat_int a, ltfat_int M,
                    const ltfat_phaseconvention ptype, LTFAT_COMPLEX* f)

{
    LTFAT_NAME(idgt_fb_plan)* plan = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        LTFAT_NAME(idgt_fb_init)(g, gl, a, M, ptype, FFTW_ESTIMATE, &plan));

    CHECKSTATUS(
        LTFAT_NAME(idgt_fb_execute)(plan, cin, L, W, f));

error:
    if (plan) LTFAT_NAME(idgt_fb_done)(&plan);
    return status;
}

LTFAT_API int
LTFAT_NAME(idgt_fb_init)(const LTFAT_TYPE* g, ltfat_int gl,
                         ltfat_int a, ltfat_int M, const ltfat_phaseconvention ptype,
                         unsigned flags, LTFAT_NAME(idgt_fb_plan)** pout)
{
    LTFAT_NAME(idgt_fb_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(g); CHECKNULL(pout);
    CHECK(LTFATERR_BADSIZE, gl > 0, "gl (passed %td) must be positive.", gl);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a (passed %td) must be positive.", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M (passed %td) must be positive.", M);
    CHECK(LTFATERR_CANNOTHAPPEN, ltfat_phaseconvention_is_valid(ptype),
          "Invalid ltfat_phaseconvention enum value." );

    CHECKMEM( p = LTFAT_NEW(LTFAT_NAME(idgt_fb_plan)) );

    p->ptype = ptype;
    p->a = a;
    p->M = M;
    p->gl = gl;

    CHECKMEM( p->cbuf  = LTFAT_NAME_COMPLEX(malloc)(M));
    CHECKMEM( p->gw    = LTFAT_NAME(malloc)(gl));
    CHECKMEM( p->ff    = LTFAT_NAME_COMPLEX(malloc)(gl > M ? gl : M));

    CHECKSTATUS(
        LTFAT_NAME_REAL(ifft_init)(M, 1, p->cbuf, p->cbuf, flags, &p->p_small));

    LTFAT_NAME(fftshift)(g, gl, p->gw);

    *pout = p;
    return status;
error:
    if (p) LTFAT_NAME(idgt_fb_done)(&p);
    return status;
}

LTFAT_API int
LTFAT_NAME(idgt_fb_done)(LTFAT_NAME(idgt_fb_plan)** p)
{
    LTFAT_NAME(idgt_fb_plan)* pp;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;
    LTFAT_SAFEFREEALL(pp->cbuf, pp->ff, pp->gw);
    if (pp->p_small) LTFAT_NAME_REAL(ifft_done)(&pp->p_small);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}

LTFAT_API int
LTFAT_NAME(idgt_fb_execute)(LTFAT_NAME(idgt_fb_plan)* p,
                            const LTFAT_COMPLEX* cin,
                            ltfat_int L, ltfat_int W, LTFAT_COMPLEX* f)
{
    ltfat_int M, a, gl, N, ep, sp, glh, glh_d_a;
    LTFAT_COMPLEX* cbuf, *ff;
    LTFAT_TYPE* gw;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(cin); CHECKNULL(f);
    CHECK(LTFATERR_BADTRALEN, L >= p->gl && !(L % p->a),
          "L (passed %td) must be positive and divisible by a (passed %td).", L, p->a);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W (passed %td) must be positive.", W);

    M = p->M;
    a = p->a;
    gl = p->gl;
    N = L / a;

    /* This is a floor operation. */
    glh = gl / 2;

    /* This is a ceil operation. */
    glh_d_a = (ltfat_int)ceil((glh * 1.0) / (a));

    cbuf = p->cbuf;
    gw = p->gw;
    ff = p->ff;

    LTFAT_NAME_COMPLEX(clear_array)( f, L * W);
    /* memset(f, 0, L * W * sizeof * f); */

    for (ltfat_int w = 0; w < W; w++)
    {
        LTFAT_COMPLEX* fw = f + w * L;
        /* ----- Handle the first boundary using periodic boundary conditions. --- */
        for (ltfat_int n = 0; n < glh_d_a; n++)
        {
            THE_SUM;

            sp = ltfat_positiverem(n * a - glh, L);
            ep = ltfat_positiverem(n * a - glh + gl - 1, L);

            /* % Add the ff vector to f at position sp. */
            for (ltfat_int ii = 0; ii < L - sp; ii++)
                fw[sp + ii] += ff[ii];

            for (ltfat_int ii = 0; ii < ep + 1; ii++)
                fw[ii] += ff[L - sp + ii];
        }


        /* ----- Handle the middle case. --------------------- */
        for (ltfat_int n = glh_d_a; n < (L - (gl + 1) / 2) / a + 1; n++)
        {
            THE_SUM;

            sp = ltfat_positiverem(n * a - glh, L);
            ep = ltfat_positiverem(n * a - glh + gl - 1, L);

            /* Add the ff vector to f at position sp. */
            for (ltfat_int ii = 0; ii < ep - sp + 1; ii++)
                fw[ii + sp] += ff[ii];
        }

        /* Handle the last boundary using periodic boundary conditions. */
        for (ltfat_int n = (L - (gl + 1) / 2) / a + 1; n < N; n++)
        {
            THE_SUM;

            sp = ltfat_positiverem(n * a - glh, L);
            ep = ltfat_positiverem(n * a - glh + gl - 1, L);

            /* Add the ff vector to f at position sp. */
            for (ltfat_int ii = 0; ii < L - sp; ii++)
                fw[sp + ii] += ff[ii];

            for (ltfat_int ii = 0; ii < ep + 1; ii++)
                fw[ii] += ff[L - sp + ii];
        }
    }

error:
    return status;
}
