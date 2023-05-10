#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"


#define CH(name) LTFAT_COMPLEXH(name)

#define POSTPROC_REAL \
  for (ltfat_int n=0;n<N*W;n+=2) \
  { \
     for (ltfat_int m=0;m<M;m+=2) \
     { \
       pcoef[m]=ltfat_real(pcoef2[m])+ltfat_imag(pcoef2[m]); \
       pcoef[m+M]=ltfat_real(pcoef2[m+M2])-ltfat_imag(pcoef2[m+M2]); \
     } \
     \
     for (ltfat_int m=1;m<M;m+=2) \
     { \
       pcoef[m]=ltfat_real(pcoef2[m])-ltfat_imag(pcoef2[m]); \
       pcoef[m+M]=ltfat_real(pcoef2[m+M2])+ltfat_imag(pcoef2[m+M2]); \
     } \
 \
     pcoef+=M2; \
     pcoef2+=M4; \
  }

#define POSTPROC_COMPLEX \
  for (ltfat_int n=0;n<N*W;n+=2) \
  { \
     for (ltfat_int m=0;m<M;m+=2) \
     { \
         pcoef[m] =   scalconst*(emipi4*pcoef2[m]  +eipi4*pcoef2[M2-1-m]); \
         pcoef[m+M] = scalconst*(eipi4*pcoef2[m+M2]+emipi4*pcoef2[M4-1-m]); \
     } \
 \
     for (ltfat_int m=1;m<M;m+=2) \
     { \
       pcoef[m] = scalconst*(eipi4*pcoef2[m]    +emipi4*pcoef2[M2-1-m]); \
       pcoef[m+M]=scalconst*(emipi4*pcoef2[m+M2]+eipi4*pcoef2[M4-1-m]); \
     } \
 \
     pcoef+=M2; \
     pcoef2+=M4; \
  }

#define PREPROC \
   for(ltfat_int n=0;n<L;n++) \
      f2[n] = (LTFAT_COMPLEX) exp(-I*(LTFAT_REAL) M_PI * (LTFAT_REAL)(n/(2.0*M))); \
   for(ltfat_int w=W-1;w>=0;w--) \
      for(ltfat_int n=0;n<L;n++) \
         f2[n+w*L] = f2[n]*f[n+w*L];


LTFAT_API void
LTFAT_NAME_COMPLEX(dwiltiii_long)(const LTFAT_COMPLEX* f,
                                  const LTFAT_COMPLEX* g,
                                  ltfat_int L, ltfat_int W,
                                  ltfat_int M, LTFAT_COMPLEX* cout)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / sqrt(2.0) );
    const LTFAT_COMPLEX eipi4 =  exp( I * (LTFAT_REAL) ( M_PI / 4.0 ));
    const LTFAT_COMPLEX emipi4 = exp(-I * (LTFAT_REAL) ( M_PI / 4.0 ));

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(malloc)(2 * M * N * W);
    LTFAT_COMPLEX* f2 = LTFAT_NAME_COMPLEX(malloc)(L * W);

    PREPROC

    LTFAT_NAME_COMPLEX(dgt_long)(f2, g, L, W, M, 2 * M, LTFAT_FREQINV, coef2);

    LTFAT_COMPLEX* pcoef  = cout;
    LTFAT_COMPLEX* pcoef2 = coef2;

    POSTPROC_COMPLEX

    LTFAT_SAFEFREEALL(coef2, f2);
}

LTFAT_API void
LTFAT_NAME_REAL(dwiltiii_long)(const LTFAT_REAL* f, const LTFAT_REAL* g,
                               ltfat_int L, ltfat_int W,
                               ltfat_int M, LTFAT_REAL* cout)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(malloc)(2 * M * N * W);
    LTFAT_COMPLEX* f2 = LTFAT_NAME_COMPLEX(malloc)(L * W);
    LTFAT_COMPLEX* g2 = LTFAT_NAME_COMPLEX(malloc)(L);

    // Real to complex
    for (ltfat_int ii = 0; ii < L; ii++)
        g2[ii] = g[ii];

    PREPROC

    LTFAT_NAME_COMPLEX(dgt_long)(f2, g2, L, W, M, 2 * M, LTFAT_FREQINV, coef2);


    LTFAT_REAL* pcoef  = cout;
    LTFAT_COMPLEX* pcoef2 = coef2;

    POSTPROC_REAL

    LTFAT_SAFEFREEALL(coef2, f2, g2);

}

LTFAT_API void
LTFAT_NAME_COMPLEX(dwiltiii_fb)(const LTFAT_COMPLEX* f, const LTFAT_COMPLEX* g,
                                ltfat_int L, ltfat_int gl,
                                ltfat_int W, ltfat_int M,
                                LTFAT_COMPLEX* cout)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;
    const LTFAT_REAL scalconst = (LTFAT_REAL)( 1.0 / sqrt(2.0) );
    const LTFAT_COMPLEX eipi4 = exp(I * (LTFAT_REAL)(M_PI / 4.0));
    const LTFAT_COMPLEX emipi4 = exp(-I * (LTFAT_REAL)(M_PI / 4.0));

    // XXX: This might allocate too much memory
    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(malloc)(2 * M * N * W);
    LTFAT_COMPLEX* f2 = LTFAT_NAME_COMPLEX(malloc)(L * W);

    PREPROC

    /* coef2=comp_dgt(f,g,a,2*M,L); */
    LTFAT_NAME_COMPLEX(dgt_fb)(f2, g, L, gl, W, M, 2 * M, LTFAT_FREQINV, coef2);


    LTFAT_COMPLEX* pcoef  = cout;
    LTFAT_COMPLEX* pcoef2 = coef2;

    POSTPROC_COMPLEX

    LTFAT_SAFEFREEALL(coef2, f2);

}

LTFAT_API void
LTFAT_NAME_REAL(dwiltiii_fb)(const LTFAT_REAL* f, const LTFAT_REAL* g,
                             ltfat_int L, ltfat_int gl,
                             ltfat_int W, ltfat_int M,
                             LTFAT_REAL* cout)
{
    ltfat_int N = L / M;
    ltfat_int M2 = 2 * M;
    ltfat_int M4 = 4 * M;

    LTFAT_COMPLEX* coef2 = LTFAT_NAME_COMPLEX(malloc)(2 * M * N * W);
    LTFAT_COMPLEX* f2 = LTFAT_NAME_COMPLEX(malloc)(L * W);
    LTFAT_COMPLEX* g2 = LTFAT_NAME_COMPLEX(malloc)(gl);

    //Real to complex
    for (ltfat_int ii = 0; ii < gl; ii++)
        g2[ii] = g[ii];

    PREPROC

    LTFAT_NAME_COMPLEX(dgt_fb)(f2, g2, L, gl, W, M, 2 * M, LTFAT_FREQINV, coef2);

    LTFAT_REAL* pcoef  = cout;
    LTFAT_COMPLEX* pcoef2 = coef2;

    POSTPROC_REAL

    LTFAT_SAFEFREEALL(coef2, f2, g2);
}

#undef CH
#undef POSTPROC_REAL
#undef POSTPROC_COMPLEX
#undef PREPROC
