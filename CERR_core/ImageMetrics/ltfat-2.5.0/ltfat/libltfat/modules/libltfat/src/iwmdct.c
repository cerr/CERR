#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"


#define CH(name) LTFAT_COMPLEXH(name)

#define PREPROC_COMPLEX \
  for (ltfat_int n=0;n<N*W;n+=2) \
  { \
     for (ltfat_int m=0;m<M;m+=2) \
     { \
        pcoef2[m] = eipi4*pcoef[m]; \
        pcoef2[M2-1-m] = emipi4*pcoef[m]; \
        pcoef2[m+M2] = emipi4*pcoef[m+M]; \
        pcoef2[M4-1-m] = eipi4*pcoef[m+M]; \
     } \
 \
     for (ltfat_int m=1;m<M;m+=2) \
     { \
        pcoef2[m] = emipi4*pcoef[m]; \
        pcoef2[M2-1-m] = eipi4*pcoef[m]; \
        pcoef2[m+M2] = eipi4*pcoef[m+M];  \
        pcoef2[M4-1-m] = emipi4*pcoef[m+M]; \
     } \
 \
     pcoef+=M2; \
     pcoef2+=M4; \
  }

#define POSTPROC_REAL \
   for(ltfat_int w=0;w<W;w++) \
      for(ltfat_int n=0;n<L;n++) \
         f[n+w*L] = scalconst*ltfat_real(f2[n+w*L]*exp(I*(LTFAT_REAL)(M_PI*n/(2.0*M))));

#define POSTPROC_COMPLEX \
   for(ltfat_int w=0;w<W;w++) \
      for(ltfat_int n=0;n<L;n++) \
         f[n+w*L] = scalconst*f2[n+w*L]*exp(I*(LTFAT_REAL)( M_PI*n/(2.0*M)) );

LTFAT_API void
LTFAT_NAME_COMPLEX(idwiltiii_long)(const LTFAT_COMPLEX* c,
                                   const LTFAT_COMPLEX* g,
                                   ltfat_int L, ltfat_int W,
                                   ltfat_int M, LTFAT_COMPLEX* f)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / sqrt(2.0) );
    const LTFAT_COMPLEX eipi4 = exp(I * (LTFAT_REAL) (M_PI / 4.0));
    const LTFAT_COMPLEX emipi4 = exp(-I * (LTFAT_REAL) ( M_PI / 4.0));

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(calloc)(2 * M * N * W);
    LTFAT_COMPLEX* f2 = LTFAT_NAME_COMPLEX(malloc)(L * W);


    const LTFAT_COMPLEX* pcoef  = c;
    LTFAT_COMPLEX* pcoef2 = coef2;

    PREPROC_COMPLEX

    LTFAT_NAME_COMPLEX(idgt_long)(coef2, g, L, W, M, 2 * M, LTFAT_FREQINV, f2);

    POSTPROC_COMPLEX

    LTFAT_SAFEFREEALL(coef2, f2);
}

LTFAT_API void
LTFAT_NAME_REAL(idwiltiii_long)(const LTFAT_REAL* c, const LTFAT_REAL* g,
                                ltfat_int L, ltfat_int W,
                                ltfat_int M, LTFAT_REAL* f)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / sqrt(2.0) );
    const LTFAT_COMPLEX eipi4 = exp(  I * (LTFAT_REAL) (M_PI / 4.0));
    const LTFAT_COMPLEX emipi4 = exp(-I * (LTFAT_REAL) (M_PI / 4.0));

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(calloc)(2 * M * N * W);
    LTFAT_COMPLEX* f2 = LTFAT_NAME_COMPLEX(malloc)(L * W);
    LTFAT_COMPLEX* g2 = LTFAT_NAME_COMPLEX(malloc)(L);
    for (ltfat_int ii = 0; ii < L; ii++)
        g2[ii] = g[ii];


    const LTFAT_REAL* pcoef  = c;
    LTFAT_COMPLEX* pcoef2 = coef2;

    PREPROC_COMPLEX

    LTFAT_NAME_COMPLEX(idgt_long)(coef2, g2, L, W, M, 2 * M, LTFAT_FREQINV, f2);

    POSTPROC_REAL

    LTFAT_SAFEFREEALL(coef2, f2, g2);

}

LTFAT_API void
LTFAT_NAME_COMPLEX(idwiltiii_fb)(const LTFAT_COMPLEX* c, const LTFAT_COMPLEX* g,
                                 ltfat_int L, ltfat_int gl,
                                 ltfat_int W, ltfat_int M,
                                 LTFAT_COMPLEX* f)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / sqrt(2.0) );
    const LTFAT_COMPLEX eipi4 =  exp( I * (LTFAT_REAL)( M_PI / 4.0));
    const LTFAT_COMPLEX emipi4 = exp(-I * (LTFAT_REAL)( M_PI / 4.0));

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(calloc)(2 * M * N * W);
    LTFAT_COMPLEX* f2 = LTFAT_NAME_COMPLEX(malloc)(L * W);


    const LTFAT_COMPLEX* pcoef  = c;
    LTFAT_COMPLEX* pcoef2 = coef2;

    PREPROC_COMPLEX

    LTFAT_NAME_COMPLEX(idgt_fb)(coef2, g, L, gl, W, M, 2 * M, LTFAT_FREQINV, f2);

    POSTPROC_COMPLEX

    LTFAT_SAFEFREEALL(coef2, f2);

}

LTFAT_API void
LTFAT_NAME_REAL(idwiltiii_fb)(const LTFAT_REAL* c, const LTFAT_REAL* g,
                              ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int M,
                              LTFAT_REAL* f)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / sqrt(2.0) );
    const LTFAT_COMPLEX eipi4 =  exp( I * (LTFAT_REAL)(M_PI / 4.0));
    const LTFAT_COMPLEX emipi4 = exp(-I * (LTFAT_REAL)(M_PI / 4.0));

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(calloc)(2 * M * N * W);
    LTFAT_COMPLEX* f2 = LTFAT_NAME_COMPLEX(malloc)(L * W);
    LTFAT_COMPLEX* g2 = LTFAT_NAME_COMPLEX(malloc)(gl);
    for (ltfat_int ii = 0; ii < gl; ii++)
        g2[ii] = g[ii];


    const LTFAT_REAL* pcoef  = c;
    LTFAT_COMPLEX* pcoef2 = coef2;

    PREPROC_COMPLEX

    LTFAT_NAME_COMPLEX(idgt_fb)(coef2, g2, L, gl, W, M, 2 * M, LTFAT_FREQINV, f2);

    POSTPROC_REAL

    LTFAT_SAFEFREEALL(coef2, f2, g2);
}

#undef CH
#undef PREPROC_COMPLEX
#undef POSTPROC_REAL
#undef POSTPROC_COMPLEX
