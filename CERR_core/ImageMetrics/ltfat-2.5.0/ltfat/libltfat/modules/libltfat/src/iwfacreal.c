#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#include "ltfat/thirdparty/fftw3.h"

LTFAT_API void
LTFAT_NAME(iwfacreal)(const LTFAT_COMPLEX* gf, ltfat_int L,
                      ltfat_int R,
                      ltfat_int a, ltfat_int M, LTFAT_REAL* g)
{

    ltfat_int h_a, h_m;

    /* LTFAT_FFTW(plan) p_before; */
    LTFAT_NAME_REAL(ifftreal_plan)* p_before;

    ltfat_int b = L / M;
    ltfat_int c = ltfat_gcd(a, M, &h_a, &h_m);
    ltfat_int p = a / c;
    ltfat_int q = M / c;
    ltfat_int d = b / p;

    /* This is a floor operation. */
    ltfat_int d2 = d / 2 + 1;

    /* division by d is because of the way FFTW normalizes the transform. */
    LTFAT_REAL scaling = (LTFAT_REAL) ( 1.0 / sqrt((double)M) / d );

    LTFAT_REAL*    sbuf = LTFAT_NAME_REAL(malloc)( d);
    LTFAT_COMPLEX* cbuf = LTFAT_NAME_COMPLEX(malloc)( d2);

    /* Create plan. In-place. */
    /* p_before = LTFAT_FFTW(plan_dft_c2r_1d)((int)d, (LTFAT_FFTW(complex)*) cbuf, sbuf, */
    /*                                        FFTW_MEASURE); */
    LTFAT_NAME_REAL(ifftreal_init)(d, 1, cbuf, sbuf, FFTW_MEASURE, &p_before);

    ltfat_int ld3 = c * p * q * R;

    /* Advancing pointer: Runs through array pointing out the base for the strided operations. */
    const LTFAT_COMPLEX* gfp = gf;

    for (ltfat_int r = 0; r < c; r++)
    {
        for (ltfat_int w = 0; w < R; w++)
        {
            for (ltfat_int l = 0; l < q; l++)
            {
                for (ltfat_int k = 0; k < p; k++)
                {
                    ltfat_int negrem = ltfat_positiverem(k * M - l * a, L);
                    for (ltfat_int s = 0; s < d2; s++)
                    {
                        cbuf[s] = gfp[s * ld3] * scaling;
                    }

                    /* LTFAT_FFTW(execute)(p_before); */
                    LTFAT_NAME_REAL(ifftreal_execute)(p_before);

                    for (ltfat_int s = 0; s < d; s++)
                    {
                        g[r + (negrem + s * p * M) % L + L * w] = sbuf[s];
                    }
                    gfp++;
                }
            }
        }
    }

    /* Clear the work-arrays. */
    LTFAT_SAFEFREEALL(cbuf, sbuf);

    /* LTFAT_FFTW(destroy_plan)(p_before); */
    LTFAT_NAME_REAL(ifftreal_done)(&p_before);
}
