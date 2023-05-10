#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "ltfat/blaslapack.h"

LTFAT_API void
LTFAT_NAME(gabdual_fac)(const LTFAT_COMPLEX* gf, ltfat_int L,
                        ltfat_int R,
                        ltfat_int a, ltfat_int M, LTFAT_COMPLEX* gdualf)
{

    ltfat_int h_a, h_m;

    LTFAT_COMPLEX* Sf;

    const LTFAT_COMPLEX zzero = (LTFAT_COMPLEX) 0.0;//{0.0, 0.0 };
    const LTFAT_COMPLEX alpha = (LTFAT_COMPLEX) 1.0; //{1.0, 0.0 };

    ltfat_int N = L / a;

    ltfat_int c = ltfat_gcd(a, M, &h_a, &h_m);
    ltfat_int p = a / c;
    ltfat_int q = M / c;
    ltfat_int d = N / q;

    Sf = LTFAT_NAME_COMPLEX(malloc)(p * p);

    /* Copy the contents of gf to gdualf because LAPACK overwrites it input
     * argument
     */
    memcpy(gdualf, gf, L * R * sizeof * gdualf);

    for (ltfat_int rs = 0; rs < c * d; rs++)
    {
        LTFAT_NAME(gemm)(CblasNoTrans, CblasConjTrans, p, p, q * R,
                               &alpha,
                               gf + rs * p * q * R, p,
                               gf + rs * p * q * R, p,
                               &zzero, Sf, p);

        LTFAT_NAME(posv)(p, q * R, Sf, p,
                               gdualf + rs * p * q * R, p);

    }

    /* Clear the work-array. */
    ltfat_free(Sf);


}


LTFAT_API void
LTFAT_NAME(gabdualreal_fac)(const LTFAT_COMPLEX* gf, ltfat_int L,
                            ltfat_int R,
                            ltfat_int a, ltfat_int M,
                            LTFAT_COMPLEX* gdualf)
{

    ltfat_int h_a, h_m;

    LTFAT_COMPLEX* Sf;

    const LTFAT_COMPLEX zzero = (LTFAT_COMPLEX) 0.0;
    const LTFAT_COMPLEX alpha = (LTFAT_COMPLEX) 1.0; //{1.0, 0.0 };

    ltfat_int N = L / a;

    ltfat_int c = ltfat_gcd(a, M, &h_a, &h_m);
    ltfat_int p = a / c;
    ltfat_int q = M / c;
    ltfat_int d = N / q;

    /* This is a floor operation. */
    ltfat_int d2 = d / 2 + 1;

    Sf = LTFAT_NAME_COMPLEX(malloc)(p * p);

    /* Copy the contents of gf to gdualf because LAPACK overwrites it input
     * argument
     */
    memcpy(gdualf, gf, sizeof(LTFAT_COMPLEX)*L * R);

    for (ltfat_int rs = 0; rs < c * d2; rs++)
    {
        LTFAT_NAME(gemm)(CblasNoTrans, CblasConjTrans, p, p, q * R,
                               &alpha,
                               gf + rs * p * q * R, p,
                               gf + rs * p * q * R, p,
                               &zzero, Sf, p);

        LTFAT_NAME(posv)(p, q * R, Sf, p,
                               gdualf + rs * p * q * R, p);

    }

    /* Clear the work-array. */
    ltfat_free(Sf);


}
