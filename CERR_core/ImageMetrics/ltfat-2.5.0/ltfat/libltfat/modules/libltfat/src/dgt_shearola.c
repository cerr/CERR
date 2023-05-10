#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

LTFAT_API LTFAT_NAME(dgt_shearola_plan)
LTFAT_NAME(dgt_shearola_init)(const LTFAT_COMPLEX* g, ltfat_int gl,
                              ltfat_int W, ltfat_int a, ltfat_int M,
                              ltfat_int s0, ltfat_int s1, ltfat_int br,
                              ltfat_int bl,
                              unsigned flags)
{

    LTFAT_NAME(dgt_shearola_plan) plan;

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

    plan.plan =
        LTFAT_NAME(dgt_shear_init)((const LTFAT_COMPLEX*)plan.buf,
                                   (const LTFAT_COMPLEX*)plan.gext,
                                   Lext, W, a, M,
                                   s0, s1, br,
                                   plan.cbuf, flags);

    return (plan);

}

LTFAT_API void
LTFAT_NAME(dgt_shearola_execute)(const LTFAT_NAME(dgt_shearola_plan) plan,
                                 const LTFAT_COMPLEX* f, ltfat_int L,
                                 LTFAT_COMPLEX* cout)

{
    ltfat_int bl      = plan.bl;
    ltfat_int gl      = plan.gl;
    ltfat_int a       = plan.plan.a;
    ltfat_int M       = plan.plan.M;
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
        LTFAT_NAME(dgt_shear_execute)(plan.plan);

        /* Place the results */
        for (ltfat_int w = 0; w < W; w++)
        {
            /* Place large block */
            LTFAT_COMPLEX* cout_p = cout +      ii * M * Nblock + w * M * N ;
            LTFAT_COMPLEX* cbuf_p = plan.cbuf +  w * M * Nblocke;
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
LTFAT_NAME(dgt_shearola_done)(LTFAT_NAME(dgt_shearola_plan) plan)
{
    LTFAT_NAME(dgt_shear_done)(plan.plan);

    /* ltfat_free(plan.cbuf); */

    LTFAT_SAFEFREEALL(plan.gext, plan.buf);

}

LTFAT_API void
LTFAT_NAME(dgt_shearola)(const LTFAT_COMPLEX* f, const LTFAT_COMPLEX* g,
                         ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a,
                         ltfat_int M,
                         ltfat_int s0, ltfat_int s1, ltfat_int br, ltfat_int bl,
                         LTFAT_COMPLEX* cout)
{

    LTFAT_NAME(dgt_shearola_plan) plan = LTFAT_NAME(dgt_shearola_init)(
            g, gl, W, a, M, s0, s1, br, bl, FFTW_ESTIMATE);

    LTFAT_NAME(dgt_shearola_execute)(plan, f, L, cout);

    LTFAT_NAME(dgt_shearola_done)(plan);

}
