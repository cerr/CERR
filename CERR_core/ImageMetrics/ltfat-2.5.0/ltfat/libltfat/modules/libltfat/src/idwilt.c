#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

#define CH(name) LTFAT_COMPLEXH(name)

#define PREPROC_REAL \
  for (ltfat_int n=0;n<N*W;n+=2) \
  { \
     pcoef2[0]=pcoef[0]; \
\
     for (ltfat_int m=1;m<M;m+=2) \
     { \
        pcoef2[m] = -I*scalconst*(pcoef[m]); \
        pcoef2[m+coef2_ld] = scalconst*(pcoef[m+M]); \
     } \
 \
     for (ltfat_int m=2;m<M;m+=2) \
     { \
        pcoef2[m] = scalconst*(pcoef[m]); \
        pcoef2[m+coef2_ld] = -I*scalconst*(pcoef[m+M]); \
     } \
 \
     pcoef2[M+nyquestadd] = pcoef[M]; \
     pcoef+=2*M; \
     pcoef2+=2*coef2_ld; \
  }

#define PREPROC_COMPLEX \
  for (ltfat_int n=0;n<N*W;n+=2) \
  { \
     pcoef2[0] = pcoef[0]; \
 \
     for (ltfat_int m=1;m<M;m+=2) \
     { \
        pcoef2[m] = -I*scalconst*pcoef[m]; \
        pcoef2[M2-m] = I*scalconst*pcoef[m]; \
        pcoef2[M2+m] =  scalconst*pcoef[m+M]; \
        pcoef2[M4-m] = scalconst*pcoef[m+M]; \
     } \
 \
     for (ltfat_int m=2;m<M;m+=2) \
     { \
        pcoef2[m] = scalconst*pcoef[m]; \
        pcoef2[M2-m] = scalconst*pcoef[m]; \
        pcoef2[M2+m] =  -I*scalconst*pcoef[m+M]; \
        pcoef2[M4-m] = I*scalconst*pcoef[m+M]; \
     } \
 \
     pcoef2[M+nyquestadd] = pcoef[M]; \
     pcoef+=M2; \
     pcoef2+=M4; \
  }


LTFAT_API void
LTFAT_NAME_COMPLEX(idwilt_long)(const LTFAT_COMPLEX* c, const LTFAT_COMPLEX* g,
                                ltfat_int L, ltfat_int W, ltfat_int M,
                                LTFAT_COMPLEX* f)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL) ( 1.0 / sqrt(2.0));

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(calloc)(2 * M * N * W);

    ltfat_int nyquestadd = (M % 2) * M2;

    const LTFAT_COMPLEX* pcoef  = c;
    LTFAT_COMPLEX* pcoef2 = coef2;

    PREPROC_COMPLEX

    LTFAT_NAME_COMPLEX(idgt_long)(coef2, g, L, W, M, 2 * M, LTFAT_FREQINV, f);

    ltfat_free(coef2);

}

LTFAT_API void
LTFAT_NAME_REAL(idwilt_long)(const LTFAT_REAL* c, const LTFAT_REAL* g,
                             ltfat_int L, ltfat_int W, ltfat_int M,
                             LTFAT_REAL* f)
{
    ltfat_int N = L / M;
    ltfat_int coef2_ld = M + 1;
    const LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / sqrt(2.0) );
    ltfat_int nyquestadd = (M % 2) * coef2_ld;

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(calloc)((M + 1) * N * W);

    const LTFAT_REAL* pcoef  = c;
    LTFAT_COMPLEX* pcoef2 = coef2;

    PREPROC_REAL

    LTFAT_NAME(idgtreal_long)(coef2, g, L, W, M, 2 * M, LTFAT_FREQINV, f);

    ltfat_free(coef2);

}

LTFAT_API void
LTFAT_NAME_COMPLEX(idwilt_fb)(const LTFAT_COMPLEX* c, const LTFAT_COMPLEX* g,
                              ltfat_int L, ltfat_int gl,
                              ltfat_int W, ltfat_int M,
                              LTFAT_COMPLEX* f)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / sqrt(2.0) );

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(calloc)(2 * M * N * W);

    ltfat_int nyquestadd = (M % 2) * M2;

    const LTFAT_COMPLEX* pcoef  = c;
    LTFAT_COMPLEX* pcoef2 = coef2;

    PREPROC_COMPLEX

    LTFAT_NAME_COMPLEX(idgt_fb)(coef2, g, L, gl, W, M, 2 * M, LTFAT_FREQINV, f);

    ltfat_free(coef2);

}

LTFAT_API void
LTFAT_NAME_REAL(idwilt_fb)(const LTFAT_REAL* c, const LTFAT_REAL* g,
                           ltfat_int L, ltfat_int gl,
                           ltfat_int W, ltfat_int M,
                           LTFAT_REAL* f)
{
    ltfat_int N = L / M;
    ltfat_int coef2_ld = M + 1;
    ltfat_int nyquestadd = (M % 2) * coef2_ld;
    const LTFAT_REAL scalconst = (LTFAT_REAL) ( 1.0 / sqrt(2.0) );

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(calloc)((M + 1) * N * W);

    const LTFAT_REAL* pcoef  = c;
    LTFAT_COMPLEX* pcoef2 = coef2;

    PREPROC_REAL

    LTFAT_NAME(idgtreal_fb)(coef2, g, L, gl, W, M, 2 * M, LTFAT_FREQINV, f);

    ltfat_free(coef2);
}

#undef CH
#undef PREPROC_REAL
#undef PREPROC_COMPLEX
