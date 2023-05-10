#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

/* wfac for real valued input. Produces only half the output coefficients of wfac_r */
LTFAT_API void
LTFAT_NAME(wfacreal)(const LTFAT_REAL* g, ltfat_int L, ltfat_int R,
                     ltfat_int a, ltfat_int M,
                     LTFAT_COMPLEX* gf)
{

    ltfat_int h_a, h_m;

    //LTFAT_REAL *gfp;
    LTFAT_COMPLEX* gfp = gf;

    ltfat_int s;
    ltfat_int rem, negrem;

    /* LTFAT_FFTW(plan) p_before; */
    LTFAT_NAME(fftreal_plan)* p_before;

    ltfat_int b = L / M;
    ltfat_int c = ltfat_gcd(a, M, &h_a, &h_m);
    ltfat_int p = a / c;
    ltfat_int q = M / c;
    ltfat_int d = b / p;

    /* This is a floor operation. */
    ltfat_int d2 = d / 2 + 1;

    const LTFAT_REAL sqrtM = (LTFAT_REAL) sqrt((double)M);

    LTFAT_REAL* sbuf = LTFAT_NAME_REAL(malloc)(d);
    LTFAT_COMPLEX* cbuf = LTFAT_NAME_COMPLEX(malloc)(d2);

    /* Create plan. In-place. */
    /* p_before = LTFAT_FFTW(plan_dft_r2c_1d)((int) d, sbuf, */
    /*                                        (LTFAT_FFTW(complex)*) cbuf, FFTW_MEASURE); */
    LTFAT_NAME(fftreal_init)(d, 1, sbuf, cbuf, FFTW_MEASURE, &p_before);


    // ltfat_int ld3=2*c*p*q*R;
    ltfat_int ld3 = c * p * q * R;
    //gfp=(LTFAT_REAL*)gf;
    for (ltfat_int r = 0; r < c; r++)
    {
        for (ltfat_int w = 0; w < R; w++)
        {
            for (ltfat_int l = 0; l < q; l++)
            {
                for (ltfat_int k = 0; k < p; k++)
                {
                    negrem = ltfat_positiverem(k * M - l * a, L);
                    for (s = 0; s < d; s++)
                    {
                        rem = (negrem + s * p * M) % L;
                        sbuf[s]   = sqrtM * g[r + rem + L * w];
                    }

                    /* LTFAT_FFTW(execute)(p_before); */
                    LTFAT_NAME(fftreal_execute)(p_before);

                    for (s = 0; s < d2; s++)
                    {
                        gfp[s * ld3] = cbuf[s];
                    }
                    gfp++;
                }
            }
        }
    }

    LTFAT_SAFEFREEALL(sbuf, cbuf);
    /* LTFAT_FFTW(destroy_plan)(p_before); */
    LTFAT_NAME(fftreal_done)(&p_before);
}
