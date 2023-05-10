#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"


#define CH(name) LTFAT_COMPLEXH(name)

#define POSTPROC_REAL \
  for (ltfat_int n=0;n<N*W;n+=2) \
  { \
     pcoef[0]=ltfat_real(pcoef2[0]); \
\
     for (ltfat_int m=1;m<M;m+=2) \
     { \
       pcoef[m]=-scalconst*ltfat_imag(pcoef2[m]); \
       pcoef[m+M]=scalconst*ltfat_real(pcoef2[m+coef2_ld]); \
     } \
 \
     for (ltfat_int m=2;m<M;m+=2) \
     { \
       pcoef[m]=scalconst*ltfat_real(pcoef2[m]); \
       pcoef[m+M]=-scalconst*ltfat_imag(pcoef2[m+coef2_ld]); \
     } \
 \
     pcoef[M]=ltfat_real(pcoef2[M+nyquestadd]); \
     pcoef+=2*M; \
     pcoef2+=2*coef2_ld; \
  }

#define POSTPROC_COMPLEX \
  for (ltfat_int n=0;n<N*W;n+=2) \
  { \
     pcoef[0] = pcoef2[0]; \
 \
     for (ltfat_int m=1;m<M;m+=2) \
     { \
       pcoef[m] = scalconst*I*(pcoef2[m]-pcoef2[M2-m]); \
       pcoef[m+M]=scalconst*(pcoef2[m+M2]+pcoef2[M4-m]); \
     } \
 \
     for (ltfat_int m=2;m<M;m+=2) \
     { \
         pcoef[m] = scalconst*(pcoef2[m]+pcoef2[M2-m]); \
         pcoef[m+M] = scalconst*I*(pcoef2[m+M2]-pcoef2[M4-m]); \
     } \
 \
     pcoef[M]=pcoef2[M+nyquestadd]; \
     pcoef+=M2; \
     pcoef2+=M4; \
  }


LTFAT_API void
LTFAT_NAME_COMPLEX(dwilt_long)(const LTFAT_COMPLEX* f, const LTFAT_COMPLEX* g,
                               ltfat_int L, ltfat_int W,
                               ltfat_int M, LTFAT_COMPLEX* cout)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / sqrt(2.0) );

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(malloc)(2 * M * N * W);

    /* coef2=comp_dgt(f,g,a,2*M,L); */
    LTFAT_NAME_COMPLEX(dgt_long)(f, g, L, W, M, 2 * M, LTFAT_FREQINV, coef2);

    ltfat_int nyquestadd = (M % 2) * M2;

    LTFAT_COMPLEX* pcoef  = cout;
    LTFAT_COMPLEX* pcoef2 = coef2;

    POSTPROC_COMPLEX

    ltfat_free(coef2);

}

LTFAT_API void
LTFAT_NAME_REAL(dwilt_long)(const LTFAT_REAL* f, const LTFAT_REAL* g,
                            ltfat_int L, ltfat_int W,
                            ltfat_int M, LTFAT_REAL* cout)
{
    ltfat_int N = L / M;
    ltfat_int coef2_ld = M + 1;
    const LTFAT_REAL scalconst = (LTFAT_REAL) sqrt(2.0);
    ltfat_int nyquestadd = (M % 2) * coef2_ld;

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(malloc)((M + 1) * N * W);

    /* coef2=comp_dgt(f,g,a,2*M,L); */
    LTFAT_NAME(dgtreal_long)(f, g, L, W, M, 2 * M, LTFAT_FREQINV, coef2);


    LTFAT_REAL* pcoef  = cout;
    LTFAT_COMPLEX* pcoef2 = coef2;

    POSTPROC_REAL

    ltfat_free(coef2);

}

LTFAT_API void
LTFAT_NAME_COMPLEX(dwilt_fb)(const LTFAT_COMPLEX* f, const LTFAT_COMPLEX* g,
                             ltfat_int L, ltfat_int gl,
                             ltfat_int W, ltfat_int M,
                             LTFAT_COMPLEX* cout)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL) ( 1.0 / sqrt(2.0) );

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(malloc)(2 * M * N * W);

    /* coef2=comp_dgt(f,g,a,2*M,L); */
    LTFAT_NAME_COMPLEX(dgt_fb)(f, g, L, gl, W, M, 2 * M, LTFAT_FREQINV, coef2);

    ltfat_int nyquestadd = (M % 2) * M2;

    LTFAT_COMPLEX* pcoef  = cout;
    LTFAT_COMPLEX* pcoef2 = coef2;

    POSTPROC_COMPLEX

    ltfat_free(coef2);

}

LTFAT_API void
LTFAT_NAME_REAL(dwilt_fb)(const LTFAT_REAL* f, const LTFAT_REAL* g,
                          ltfat_int L, ltfat_int gl,
                          ltfat_int W, ltfat_int M,
                          LTFAT_REAL* cout)
{
    ltfat_int N = L / M;
    ltfat_int coef2_ld = M + 1;
    ltfat_int nyquestadd = (M % 2) * coef2_ld;
    const LTFAT_REAL scalconst = (LTFAT_REAL) sqrt(2.0);

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(malloc)((M + 1) * N * W);
    LTFAT_NAME(dgtreal_fb)(f, g, L, gl, W, M, 2 * M, LTFAT_FREQINV, coef2);

    LTFAT_REAL* pcoef  = cout;
    LTFAT_COMPLEX* pcoef2 = coef2;

    POSTPROC_REAL

    ltfat_free(coef2);
}

#undef CH
#undef POSTPROC_REAL
#undef POSTPROC_COMPLEX
