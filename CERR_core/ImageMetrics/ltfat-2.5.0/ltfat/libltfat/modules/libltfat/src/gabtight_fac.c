#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "ltfat/blaslapack.h"

LTFAT_API void
LTFAT_NAME(gabtight_fac)(const LTFAT_COMPLEX* gf, ltfat_int L,
                         ltfat_int R,
                         ltfat_int a, ltfat_int M,
                         LTFAT_COMPLEX* gtightf)
{

    ltfat_int h_a, h_m;

    LTFAT_COMPLEX* Sf, *U, *VT, *gfwork;
    LTFAT_REAL* S;

    const LTFAT_COMPLEX zzero = (LTFAT_COMPLEX) 0.0;//{0.0, 0.0 };
    const LTFAT_COMPLEX alpha = (LTFAT_COMPLEX) 1.0; //{1.0, 0.0 };

    ltfat_int N = L / a;

    ltfat_int c = ltfat_gcd(a, M, &h_a, &h_m);
    ltfat_int p = a / c;
    ltfat_int q = M / c;
    ltfat_int d = N / q;

    S  = LTFAT_NAME_REAL(malloc)(p);
    Sf = LTFAT_NAME_COMPLEX(malloc)(p * p);
    U  = LTFAT_NAME_COMPLEX(malloc)(p * p);
    VT = LTFAT_NAME_COMPLEX(malloc)(p * q * R);
    gfwork = LTFAT_NAME_COMPLEX(malloc)(L * R);

    /* Copy the contents of gf to gfwork because LAPACK overwrites
     * the input.
     */
    memcpy(gfwork, gf, L * R * sizeof * gfwork);

    for (ltfat_int rs = 0; rs < c * d; rs++)
    {
        /* Compute the thin SVD */
        LTFAT_NAME(gesvd)(p, q * R, gfwork + rs * p * q * R, p,
                                S, U, p, VT, p);

        /* Combine U and V. */
        LTFAT_NAME(gemm)(CblasNoTrans, CblasNoTrans, p, q * R, p,
                               &alpha, (const LTFAT_COMPLEX*)U, p,
                               (const LTFAT_COMPLEX*)VT, p,
                               &zzero, gtightf + rs * p * q * R, p);


    }

    LTFAT_SAFEFREEALL(gfwork, Sf, S, U, VT);

}


LTFAT_API void
LTFAT_NAME(gabtightreal_fac)(const LTFAT_COMPLEX* gf, ltfat_int L,
                             ltfat_int R,
                             ltfat_int a, ltfat_int M,
                             LTFAT_COMPLEX* gtightf)
{

    ltfat_int h_a, h_m;

    LTFAT_COMPLEX* Sf, *U, *VT, *gfwork;
    LTFAT_REAL* S;

    const LTFAT_COMPLEX zzero = (LTFAT_COMPLEX) 0.0;
    const LTFAT_COMPLEX alpha = (LTFAT_COMPLEX) 1.0; //{1.0, 0.0 };

    ltfat_int N = L / a;

    ltfat_int c = ltfat_gcd(a, M, &h_a, &h_m);
    ltfat_int p = a / c;
    ltfat_int q = M / c;
    ltfat_int d = N / q;

    /* This is a floor operation. */
    ltfat_int d2 = d / 2 + 1;

    S  = LTFAT_NAME_REAL(malloc)(p);
    Sf = LTFAT_NAME_COMPLEX(malloc)(p * p);
    U  = LTFAT_NAME_COMPLEX(malloc)(p * p);
    VT = LTFAT_NAME_COMPLEX(malloc)(p * q * R);
    gfwork = LTFAT_NAME_COMPLEX(malloc)(L * R);

    /* Copy the contents of gf to gfwork because LAPACK overwrites
     * the input.
     */
    memcpy(gfwork, gf, L * R * sizeof * gfwork);

    for (ltfat_int rs = 0; rs < c * d2; rs++)
    {
        /* Compute the thin SVD */
        LTFAT_NAME(gesvd)(p, q * R, gfwork + rs * p * q * R, p,
                                S, U, p, VT, p);

        /* Combine U and V. */
        LTFAT_NAME(gemm)(CblasNoTrans, CblasNoTrans, p, q * R, p,
                               &alpha, (const LTFAT_COMPLEX*)U, p,
                               (const LTFAT_COMPLEX*)VT, p,
                               &zzero, gtightf + rs * p * q * R, p);
    }

    LTFAT_SAFEFREEALL(gfwork, Sf, S, U, VT);
}
