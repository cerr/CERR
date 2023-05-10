#include "dgt_long_private.h"
#include "dgtreal_long_private.h"


LTFAT_API LTFAT_NAME(dgt_ola_plan)
LTFAT_NAME(dgt_ola_init)(const LTFAT_COMPLEX* g, ltfat_int gl,
                         ltfat_int W, ltfat_int a, ltfat_int M,
                         ltfat_int bl, const ltfat_phaseconvention ptype,
                         unsigned flags)
{

    LTFAT_NAME(dgt_ola_plan) plan;

    plan.bl = bl;
    plan.gl = gl;
    plan.W  = W;

    ltfat_int Lext    = bl + gl;
    ltfat_int Nblocke = Lext / a;

    plan.buf  = LTFAT_NAME_COMPLEX(malloc)(Lext * W);
    plan.gext = LTFAT_NAME_COMPLEX(malloc)(Lext);
    plan.cbuf = LTFAT_NAME_COMPLEX(malloc)(M * Nblocke * W);

    LTFAT_NAME_COMPLEX(fir2long)(g, gl, Lext, plan.gext);

    /* Zero the last part of the buffer, it will always be zero. */
    for (ltfat_int w = 0; w < W; w++)
    {
        for (ltfat_int jj = bl; jj < Lext; jj++)
        {
            plan.buf[jj + w * Lext] = (LTFAT_COMPLEX) 0.0;
        }
    }

    /* plan.plan = */
    /*     LTFAT_NAME(dgt_long_init)((const LTFAT_COMPLEX*)plan.buf, */
    /*                               (const LTFAT_COMPLEX*)plan.gext, */
    /*                               Lext, W, a, M, */
    /*                               plan.cbuf, ptype, flags); */


    LTFAT_NAME_COMPLEX(dgt_long_init)(plan.gext,
                                      Lext, W, a, M,
                                      plan.buf, plan.cbuf, ptype, flags,
                                      &plan.plan);

    return (plan);

}

LTFAT_API void
LTFAT_NAME(dgt_ola_execute)(const LTFAT_NAME(dgt_ola_plan) plan,
                            const LTFAT_COMPLEX* f, ltfat_int L,
                            LTFAT_COMPLEX* cout)

{
    ltfat_int bl      = plan.bl;
    ltfat_int gl      = plan.gl;
    ltfat_int a       = plan.plan->a;
    ltfat_int M       = plan.plan->M;
    ltfat_int N       = L / a;
    ltfat_int Lext    = bl + gl;
    ltfat_int Nb      = L / bl;
    ltfat_int b2      = gl / a / 2;
    ltfat_int Nblock  = bl / a;
    ltfat_int Nblocke = Lext / a;
    ltfat_int W       = plan.W;


    /* Zero the output array, as we will be adding to it */
    for (ltfat_int ii = 0; ii < M * N * W; ii++)
    {
        cout[ii] = (LTFAT_COMPLEX) 0.0;
    }

    for (ltfat_int ii = 0; ii < Nb; ii++)
    {
        ltfat_int s_ii;

        /* Copy to working buffer. */
        for (ltfat_int w = 0; w < W; w++)
        {
            memcpy(plan.buf + Lext * w, f + ii * bl + w * L, sizeof(LTFAT_COMPLEX)*bl);
        }

        /* Execute the short DGT */
        LTFAT_NAME_COMPLEX(dgt_long_execute)(plan.plan);

        /* Place the results */
        for (ltfat_int w = 0; w < W; w++)
        {
            LTFAT_COMPLEX* cout_p;
            LTFAT_COMPLEX* cbuf_p;

            /* Place large block */
            cout_p = cout + ii * M * Nblock + w * M * N ;
            cbuf_p = plan.cbuf +             w * M * Nblocke;
            for (ltfat_int m = 0; m < M; m++)
            {
                for (ltfat_int n = 0; n < Nblock; n++)
                {
                    cout_p[m + n * M] += cbuf_p[m + n * M];
                }
            }

            /* Small block + */
            s_ii = ltfat_positiverem(ii + 1, Nb);
            cout_p = cout + s_ii * M * Nblock + w * M * N ;
            cbuf_p = plan.cbuf +      M * Nblock + w * M * Nblocke;
            for (ltfat_int m = 0; m < M; m++)
            {
                for (ltfat_int n = 0; n < b2; n++)
                {
                    cout_p[m + n * M] += cbuf_p[m + n * M];
                }
            }


            /* Small block - */
            s_ii = ltfat_positiverem(ii - 1, Nb) + 1;
            cout_p = cout + M * (s_ii * Nblock - b2) + w * M * N ;
            cbuf_p = plan.cbuf + M * (Nblock + b2)     + w * M * Nblocke;
            for (ltfat_int m = 0; m < M; m++)
            {
                for (ltfat_int n = 0; n < b2; n++)
                {
                    cout_p[m + n * M] += cbuf_p[m + n * M];
                }
            }

        }

    }


}

LTFAT_API void
LTFAT_NAME(dgt_ola_done)(LTFAT_NAME(dgt_ola_plan) plan)
{
    LTFAT_NAME_COMPLEX(dgt_long_done)(&plan.plan);
    LTFAT_SAFEFREEALL(plan.cbuf, plan.gext, plan.buf);
}



LTFAT_API LTFAT_NAME(dgtreal_ola_plan)
LTFAT_NAME(dgtreal_ola_init)(const LTFAT_REAL* g, ltfat_int gl,
                             ltfat_int W, ltfat_int a, ltfat_int M,
                             ltfat_int bl, const ltfat_phaseconvention ptype,
                             unsigned flags)
{

    LTFAT_NAME(dgtreal_ola_plan) plan;

    plan.bl = bl;
    plan.gl = gl;
    plan.W  = W;
    ltfat_int M2 = M / 2 + 1;

    ltfat_int Lext    = bl + gl;
    ltfat_int Nblocke = Lext / a;

    plan.buf  = (LTFAT_REAL*) ltfat_malloc(Lext * W * sizeof(LTFAT_REAL));
    plan.gext = (LTFAT_REAL*) ltfat_malloc(Lext * sizeof(LTFAT_REAL));
    plan.cbuf = (LTFAT_COMPLEX*) ltfat_malloc(M2 * Nblocke * W * sizeof(
                    LTFAT_COMPLEX));

    LTFAT_NAME_REAL(fir2long)(g, gl, Lext, plan.gext);

    /* Zero the last part of the buffer, it will always be zero. */
    for (ltfat_int w = 0; w < W; w++)
    {
        for (ltfat_int jj = bl; jj < Lext; jj++)
        {
            plan.buf[jj + w * Lext] = 0.0;
        }
    }

    LTFAT_NAME(dgtreal_long_init)( (const LTFAT_REAL*)plan.gext,
                                   Lext, W, a, M, (const LTFAT_REAL*)plan.buf,
                                   plan.cbuf, ptype, flags, &plan.plan);

    return (plan);

}







LTFAT_API void
LTFAT_NAME(dgtreal_ola_execute)(const LTFAT_NAME(dgtreal_ola_plan) plan,
                                const LTFAT_REAL* f, ltfat_int L,
                                LTFAT_COMPLEX* cout)

{
    ltfat_int bl      = plan.bl;
    ltfat_int gl      = plan.gl;
    ltfat_int a       = plan.plan->a;
    ltfat_int M       = plan.plan->M;
    ltfat_int N       = L / a;
    ltfat_int Lext    = bl + gl;
    ltfat_int Nb      = L / bl;
    ltfat_int b2      = gl / a / 2;
    ltfat_int Nblock  = bl / a;
    ltfat_int Nblocke = Lext / a;
    ltfat_int W       = plan.W;
    ltfat_int M2      = M / 2 + 1;

    /* Zero the output array, as we will be adding to it */
    for (ltfat_int ii = 0; ii < M2 * N * W; ii++)
    {
        cout[ii] = (LTFAT_COMPLEX) 0.0;
    }


    for (ltfat_int ii = 0; ii < Nb; ii++)
    {
        ltfat_int s_ii;

        /* Copy to working buffer. */
        for (ltfat_int w = 0; w < W; w++)
        {
            memcpy(plan.buf + Lext * w, f + ii * bl + w * L, sizeof(LTFAT_REAL)*bl);
        }

        /* Execute the short DGTREAL */
        LTFAT_NAME(dgtreal_long_execute)(plan.plan);

        /* Place the results */
        for (ltfat_int w = 0; w < W; w++)
        {
            LTFAT_COMPLEX* cout_p;
            LTFAT_COMPLEX* cbuf_p;

            /* Place large block */
            cout_p = cout + ii * M2 * Nblock + w * M2 * N ;
            cbuf_p = plan.cbuf +             w * M2 * Nblocke;
            for (ltfat_int m = 0; m < M2; m++)
            {
                for (ltfat_int n = 0; n < Nblock; n++)
                {
                    cout_p[m + n * M2] += cbuf_p[m + n * M2];
                }
            }

            /* Small block + */
            s_ii = ltfat_positiverem(ii + 1, Nb);
            cout_p = cout + s_ii * M2 * Nblock + w * M2 * N ;
            cbuf_p = plan.cbuf +      M2 * Nblock + w * M2 * Nblocke;
            for (ltfat_int m = 0; m < M2; m++)
            {
                for (ltfat_int n = 0; n < b2; n++)
                {
                    cout_p[m + n * M2] += cbuf_p[m + n * M2];
                }
            }


            /* Small block - */
            s_ii = ltfat_positiverem(ii - 1, Nb) + 1;
            cout_p = cout + M2 * (s_ii * Nblock - b2) + w * M2 * N ;
            cbuf_p = plan.cbuf + M2 * (     Nblock + b2) + w * M2 * Nblocke;
            for (ltfat_int m = 0; m < M2; m++)
            {
                for (ltfat_int n = 0; n < b2; n++)
                {
                    cout_p[m + n * M2] += cbuf_p[m + n * M2];
                }
            }

        }

    }
}


LTFAT_API void
LTFAT_NAME(dgtreal_ola_done)(LTFAT_NAME(dgtreal_ola_plan) plan)
{
    LTFAT_NAME(dgtreal_long_done)(&plan.plan);
    LTFAT_SAFEFREEALL(plan.cbuf, plan.gext, plan.buf);
}
