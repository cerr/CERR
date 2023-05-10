#include "ltfat/types.h"

#include "fftw_wrappers.h"
#include "dgtreal_long.h"
#include "idgtreal_long.h"
#include "dgtreal_fb.h"
#include "idgtreal_fb.h"
#include "dgt_multi.h"
#include "dgt_shear.h"
#include "tiutils.h"
#include "circularbuf.h"
#include "slicingbuf.h"
#include "rtdgtreal.h"
#include "heap.h"
#include "dgtrealwrapper.h"
#include "dgtrealmp.h"
#include "slidgtrealmp.h"
#include "linalg.h"
#include "maxtree.h"
#include "ti_windows.h"
#include "filterbankphaseret.h"

/*  --------- factorizations --------------- */

LTFAT_API void
LTFAT_NAME(wfacreal)(const LTFAT_REAL *g, ltfat_int L, ltfat_int R,
                     ltfat_int a, ltfat_int M, LTFAT_COMPLEX *gf);

LTFAT_API void
LTFAT_NAME(iwfacreal)(const LTFAT_COMPLEX *gf, ltfat_int L, ltfat_int R,
                      ltfat_int a, ltfat_int M, LTFAT_REAL *g);

/* --------- DGT by factorization ------------ */

// LTFAT_API void
// LTFAT_NAME(dgt_fac)(const LTFAT_COMPLEX *f, const LTFAT_COMPLEX *gf,
//                     ltfat_int L, ltfat_int W,  ltfat_int a,
//                     ltfat_int M, LTFAT_COMPLEX *cout);


// LTFAT_API void
// LTFAT_NAME(dgtreal_long)(const LTFAT_REAL *f, const LTFAT_REAL *g,
//                          ltfat_int L, ltfat_int W,  ltfat_int a,
//                          ltfat_int M, const ltfat_phaseconvention ptype,
//                          LTFAT_COMPLEX *cout);

// LTFAT_API void
// LTFAT_NAME(dgt_fac_r)(const LTFAT_REAL *f, const LTFAT_COMPLEX *gf,
//                       ltfat_int L, ltfat_int W,  ltfat_int a,
//                       ltfat_int M, const ltfat_phaseconvention ptype,
//                       LTFAT_COMPLEX *cout);

// LTFAT_API
// void LTFAT_NAME(dgtreal_fac)(const LTFAT_REAL *f, const LTFAT_COMPLEX *gf,
//                              ltfat_int L,
//                              ltfat_int W,  ltfat_int a,
//                              ltfat_int M, LTFAT_COMPLEX *cout);

// LTFAT_API void
// LTFAT_NAME(dgt_walnut_r)(const LTFAT_REAL *f, const LTFAT_COMPLEX *gf,
//                          ltfat_int L, ltfat_int W,
//                          ltfat_int a, ltfat_int M, LTFAT_COMPLEX *cout);





/* --------- dual windows etc. --------------- */

LTFAT_API void
LTFAT_NAME(gabdual_fac)(const LTFAT_COMPLEX *g, ltfat_int L, ltfat_int R,
                        ltfat_int a, ltfat_int M, LTFAT_COMPLEX *gdualf);

LTFAT_API void
LTFAT_NAME(gabdualreal_fac)(const LTFAT_COMPLEX *g, ltfat_int L, ltfat_int R,
                            ltfat_int a, ltfat_int M, LTFAT_COMPLEX *gdualf);

LTFAT_API void
LTFAT_NAME(gabtight_fac)(const LTFAT_COMPLEX *gf, ltfat_int L, ltfat_int R,
                         ltfat_int a, ltfat_int M,
                         LTFAT_COMPLEX *gtightf);

LTFAT_API void
LTFAT_NAME(gabtightreal_fac)(const LTFAT_COMPLEX *gf, ltfat_int L, ltfat_int R,
                             ltfat_int a, ltfat_int M,
                             LTFAT_COMPLEX *gtightf);


// LTFAT_API void
// LTFAT_NAME(dgtreal_fb)(const LTFAT_REAL *f, const LTFAT_REAL *g,
//                        ltfat_int L, ltfat_int gl,
//                        ltfat_int W,  ltfat_int a, ltfat_int M,
//                        const ltfat_phaseconvention ptype, LTFAT_COMPLEX *cout);

// LTFAT_API void
// LTFAT_NAME(idgt_fb)(const LTFAT_COMPLEX *cin, const LTFAT_COMPLEX *g,
//                     ltfat_int L, ltfat_int gl,
//                     ltfat_int W, ltfat_int a, ltfat_int M,
//                     const ltfat_phaseconvention ptype, LTFAT_COMPLEX *f);
//
// LTFAT_API void
// LTFAT_NAME(idgt_fb_r)(const LTFAT_COMPLEX *cin, const LTFAT_REAL *g,
//                       ltfat_int L, ltfat_int gl,
//                       ltfat_int W, ltfat_int a, ltfat_int M,
//                       LTFAT_COMPLEX *f);

/* ---------- OLA DGTs ------------- */
LTFAT_API void
LTFAT_NAME(dgt_ola)(const LTFAT_COMPLEX *f, const LTFAT_COMPLEX *g,
                    ltfat_int L, ltfat_int gl,
                    ltfat_int W, ltfat_int a,
                    ltfat_int M, ltfat_int bl,
                    const ltfat_phaseconvention ptype,
                    LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(dgtreal_ola)(const LTFAT_REAL *f, const LTFAT_REAL *g,
                        ltfat_int L, ltfat_int gl,
                        ltfat_int W, ltfat_int a, ltfat_int M,
                        ltfat_int bl, const ltfat_phaseconvention ptype,
                        LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(dgt_shearola)(const LTFAT_COMPLEX *f, const LTFAT_COMPLEX *g,
                         ltfat_int L, ltfat_int gl, ltfat_int W,
                         ltfat_int a, ltfat_int M,
                         ltfat_int s0, ltfat_int s1, ltfat_int br,
                         ltfat_int bl, LTFAT_COMPLEX *cout);

/* --------- FFT ------------------*/
// LTFAT_API LTFAT_FFTW(plan)
// LTFAT_NAME(fftreal_init)(LTFAT_REAL *f, ltfat_int L, ltfat_int W,
//                          LTFAT_COMPLEX *cout, unsigned flag);
//
// LTFAT_API void
// LTFAT_NAME(fftreal_execute)(LTFAT_FFTW(plan) p, LTFAT_REAL *f,
//                             LTFAT_COMPLEX *cout);
//
// LTFAT_API void
// LTFAT_NAME(fftreal)(LTFAT_REAL *f, ltfat_int L, ltfat_int W,
//                     LTFAT_COMPLEX *cout);
//
// LTFAT_API LTFAT_FFTW(plan)
// LTFAT_NAME(ifftreal_init)(LTFAT_COMPLEX *c, ltfat_int L, ltfat_int W,
//                           LTFAT_REAL *f, unsigned flag);
//
// LTFAT_API void
// LTFAT_NAME(ifftreal_execute)(LTFAT_FFTW(plan), LTFAT_COMPLEX *c,
//                              ltfat_int L, ltfat_int W,
//                              LTFAT_REAL *f);
//
// LTFAT_API void
// LTFAT_NAME(ifftreal)(LTFAT_COMPLEX *c, ltfat_int L, ltfat_int W,
//                      LTFAT_REAL *f);


/* --------- filterbank codes ------------*/

typedef struct LTFAT_NAME(convsub_fft_plan_struct) *LTFAT_NAME(convsub_fft_plan);
typedef struct LTFAT_NAME(convsub_fftbl_plan_struct) *LTFAT_NAME(convsub_fftbl_plan);

typedef struct LTFAT_NAME(upconv_fft_plan_struct) *LTFAT_NAME(upconv_fft_plan);
typedef struct LTFAT_NAME(upconv_fftbl_plan_struct) *LTFAT_NAME(upconv_fftbl_plan);

LTFAT_API void
LTFAT_NAME(ufilterbank_fft)(const LTFAT_COMPLEX *f, const LTFAT_COMPLEX *g,
                            ltfat_int L, ltfat_int gl,
                            ltfat_int W, ltfat_int a, ltfat_int M,
                            LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(filterbank_fft)(const LTFAT_COMPLEX *F, const LTFAT_COMPLEX *G[],
                           ltfat_int L, ltfat_int W,
                           ltfat_int a[], ltfat_int M,
                           LTFAT_COMPLEX *cout[]);

LTFAT_API void
LTFAT_NAME(filterbank_fft_execute)(LTFAT_NAME(convsub_fft_plan) p[],
                                   const LTFAT_COMPLEX *F, const LTFAT_COMPLEX *G[],
                                   ltfat_int M, LTFAT_COMPLEX *cout[]);


LTFAT_API LTFAT_NAME(convsub_fft_plan)
LTFAT_NAME(convsub_fft_init)(ltfat_int L, ltfat_int W,
                             ltfat_int a, LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(convsub_fft_done)(LTFAT_NAME(convsub_fft_plan) p);

LTFAT_API void
LTFAT_NAME(convsub_fft_execute)(const LTFAT_NAME(convsub_fft_plan) p,
                                const LTFAT_COMPLEX *F, const LTFAT_COMPLEX *G,
                                LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(convsub_fft)(const LTFAT_COMPLEX *F, const LTFAT_COMPLEX *G,
                        ltfat_int L, ltfat_int W, ltfat_int a,
                        LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(filterbank_fftbl)(const LTFAT_COMPLEX *F, const LTFAT_COMPLEX *G[],
                             ltfat_int L, ltfat_int Gl[],
                             ltfat_int W, const double a[], ltfat_int M,
                             ltfat_int foff[], const int realonly[],
                             LTFAT_COMPLEX *cout[]);

LTFAT_API void
LTFAT_NAME(filterbank_fftbl_execute)(LTFAT_NAME(convsub_fftbl_plan) p[],
                                     const LTFAT_COMPLEX *F,
                                     const LTFAT_COMPLEX *G[],
                                     ltfat_int M, ltfat_int foff[],
                                     const int realonly[], LTFAT_COMPLEX *cout[]);

LTFAT_API LTFAT_NAME(convsub_fftbl_plan)
LTFAT_NAME(convsub_fftbl_init)( ltfat_int L, ltfat_int Gl,
                                ltfat_int W, const double a,
                                LTFAT_COMPLEX *cout);

LTFAT_API LTFAT_NAME(convsub_fftbl_plan)
LTFAT_NAME(convsub_fftbl_init_no_ifft_plan)( ltfat_int L, ltfat_int Gl,
        ltfat_int W, const double a);

LTFAT_API void
LTFAT_NAME(convsub_fftbl_done)( LTFAT_NAME(convsub_fftbl_plan) p);


LTFAT_API void
LTFAT_NAME(convsub_fftbl_execute)(const LTFAT_NAME(convsub_fftbl_plan) p,
                                  const LTFAT_COMPLEX *F,
                                  const LTFAT_COMPLEX *G,
                                  ltfat_int foff,
                                  const int realonly,
                                  LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(convsub_fftbl)(const LTFAT_COMPLEX *F,  const LTFAT_COMPLEX *G,
                          ltfat_int L, ltfat_int Gl, ltfat_int W,
                          const double a, ltfat_int foff,
                          const int realonly, LTFAT_COMPLEX *cout);



// Inverse
LTFAT_API void
LTFAT_NAME(ifilterbank_fft)(const LTFAT_COMPLEX *cin[], const LTFAT_COMPLEX *G[],
                            ltfat_int L, ltfat_int W,
                            ltfat_int a[], ltfat_int M,
                            LTFAT_COMPLEX *F);

LTFAT_API void
LTFAT_NAME(ifilterbank_fft_execute)(LTFAT_NAME(upconv_fft_plan) p[],
                                    const LTFAT_COMPLEX *cin[],
                                    const LTFAT_COMPLEX *G[],
                                    ltfat_int M,
                                    LTFAT_COMPLEX *F );


LTFAT_API void
LTFAT_NAME(upconv_fft)(const LTFAT_COMPLEX *cin, const LTFAT_COMPLEX *G,
                       ltfat_int L, ltfat_int W, ltfat_int a,
                       LTFAT_COMPLEX *F);

LTFAT_API LTFAT_NAME(upconv_fft_plan)
LTFAT_NAME(upconv_fft_init)(ltfat_int L, ltfat_int W, ltfat_int a);


LTFAT_API void
LTFAT_NAME(upconv_fft_execute)(LTFAT_NAME(upconv_fft_plan) p,
                               const LTFAT_COMPLEX *cin, const LTFAT_COMPLEX *G,
                               LTFAT_COMPLEX *F);

LTFAT_API void
LTFAT_NAME(upconv_fft_done)(LTFAT_NAME(upconv_fft_plan) p);



LTFAT_API void
LTFAT_NAME(ifilterbank_fftbl)(const LTFAT_COMPLEX *cin[], const LTFAT_COMPLEX *G[],
                              ltfat_int L, const ltfat_int Gl[],
                              ltfat_int W, const double a[], ltfat_int M,
                              const ltfat_int foff[], const int realonly[],
                              LTFAT_COMPLEX *F);

LTFAT_API void
LTFAT_NAME(ifilterbank_fftbl_execute)(LTFAT_NAME(upconv_fftbl_plan) p[],
                                      const LTFAT_COMPLEX *cin[],
                                      const LTFAT_COMPLEX *G[],
                                      ltfat_int M, ltfat_int foff[],
                                      const int realonly[],
                                      LTFAT_COMPLEX *F);



LTFAT_API void
LTFAT_NAME(upconv_fftbl)(const LTFAT_COMPLEX *cin, const LTFAT_COMPLEX *G,
                         ltfat_int L, ltfat_int Gl, ltfat_int W,
                         const double a, const ltfat_int foff,
                         const int realonly, LTFAT_COMPLEX *F);

LTFAT_API LTFAT_NAME(upconv_fftbl_plan)
LTFAT_NAME(upconv_fftbl_init)( ltfat_int L, ltfat_int Gl,
                               ltfat_int W, const double a);

LTFAT_API void
LTFAT_NAME(upconv_fftbl_done)(LTFAT_NAME(upconv_fftbl_plan) p);

LTFAT_API void
LTFAT_NAME(upconv_fftbl_execute)(const LTFAT_NAME(upconv_fftbl_plan) p,
                                 const LTFAT_COMPLEX *cin,
                                 const LTFAT_COMPLEX *G,
                                 const ltfat_int foff, const int realonly,
                                 LTFAT_COMPLEX *F);

/* --------- pfilt and filterbanks ------------- */
LTFAT_API void
LTFAT_NAME(pfilt_fir_rr)(const LTFAT_REAL *f, const LTFAT_REAL *g,
                         ltfat_int L, ltfat_int gl,
                         ltfat_int W, ltfat_int a,
                         LTFAT_REAL *cout);


/* --------- other stuff -------- */



typedef struct LTFAT_NAME(heapinttask) LTFAT_NAME(heapinttask);

LTFAT_API LTFAT_NAME(heapinttask)*
LTFAT_NAME(heapinttask_init)(ltfat_int height, ltfat_int N,
                             ltfat_int initheapsize,
                             const LTFAT_REAL* s, int do_real);

LTFAT_API void
LTFAT_NAME(heapint_execute)(LTFAT_NAME(heapinttask)* hit,
                            const LTFAT_REAL* s,
                            const LTFAT_REAL* tgradw,
                            const LTFAT_REAL* fgradw,
                            LTFAT_REAL* phase);

LTFAT_API void
LTFAT_NAME(heapinttask_done)(LTFAT_NAME(heapinttask)* hit);

LTFAT_API void
LTFAT_NAME(heapinttask_resetmax)(LTFAT_NAME(heapinttask)* hit,
                                 const LTFAT_REAL* news,
                                 const LTFAT_REAL tol);


LTFAT_API void
LTFAT_NAME(heapinttask_resetmask)(LTFAT_NAME(heapinttask)* hit,
                                  const int* mask,
                                  const LTFAT_REAL* news,
                                  const LTFAT_REAL tol,
                                  const int do_log);

LTFAT_API int*
LTFAT_NAME(heapinttask_get_mask)( LTFAT_NAME(heapinttask)* hit);

LTFAT_API void
LTFAT_NAME(heapint)(const LTFAT_REAL *s,
                    const LTFAT_REAL *tgradw,
                    const LTFAT_REAL *fgradw,
                    ltfat_int a, ltfat_int M,
                    ltfat_int L, ltfat_int W,
                    const LTFAT_REAL tol, LTFAT_REAL *phase);

// Does the same as the previous but
LTFAT_API void
LTFAT_NAME(heapint_relgrad)(const LTFAT_REAL *s,
                            const LTFAT_REAL *tgrad,
                            const LTFAT_REAL *fgrad,
                            ltfat_int a, ltfat_int M,
                            ltfat_int L, ltfat_int W,
                            const LTFAT_REAL tol, ltfat_phaseconvention phasetype,
                            LTFAT_REAL *phase);


LTFAT_API void
LTFAT_NAME(maskedheapint)(const LTFAT_REAL  *c,
                          const LTFAT_REAL *tgradw,
                          const LTFAT_REAL *fgradw,
                          const int* mask,
                          ltfat_int a, ltfat_int M,
                          ltfat_int L, ltfat_int W,
                          LTFAT_REAL tol, LTFAT_REAL *phase);

LTFAT_API void
LTFAT_NAME(maskedheapint_relgrad)(const LTFAT_REAL  *c,
                                  const LTFAT_REAL *tgrad,
                                  const LTFAT_REAL *fgrad,
                                  const int* mask,
                                  ltfat_int a, ltfat_int M,
                                  ltfat_int L, ltfat_int W,
                                  LTFAT_REAL tol, ltfat_phaseconvention phasetype,
                                  LTFAT_REAL *phase);

LTFAT_API void
LTFAT_NAME(heapintreal)(const LTFAT_REAL *s,
                        const LTFAT_REAL *tgradw,
                        const LTFAT_REAL *fgradw,
                        ltfat_int a, ltfat_int M,
                        ltfat_int L, ltfat_int W,
                        const LTFAT_REAL tol,
                        LTFAT_REAL *phase);

LTFAT_API void
LTFAT_NAME(heapintreal_relgrad)(const LTFAT_REAL *s,
                                const LTFAT_REAL *tgradw,
                                const LTFAT_REAL *fgradw,
                                ltfat_int a, ltfat_int M,
                                ltfat_int L, ltfat_int W,
                                const LTFAT_REAL tol, ltfat_phaseconvention phasetype,
                                LTFAT_REAL *phase);

LTFAT_API void
LTFAT_NAME(maskedheapintreal)(const LTFAT_REAL * s,
                              const LTFAT_REAL * tgrad,
                              const LTFAT_REAL * fgrad,
                              const int* mask,
                              ltfat_int a, ltfat_int M,
                              ltfat_int L, ltfat_int W,
                              LTFAT_REAL tol,
                              LTFAT_REAL * phase);

LTFAT_API void
LTFAT_NAME(maskedheapintreal_relgrad)(const LTFAT_REAL* s,
                                      const LTFAT_REAL* tgradw,
                                      const LTFAT_REAL* fgradw,
                                      const int* mask,
                                      ltfat_int a, ltfat_int M,
                                      ltfat_int L, ltfat_int W,
                                      LTFAT_REAL tol, ltfat_phaseconvention phasetype,
                                      LTFAT_REAL* phase);

LTFAT_API void
LTFAT_NAME(filterbankphasegrad)(const LTFAT_COMPLEX* c [],
                                const LTFAT_COMPLEX* ch[],
                                const LTFAT_COMPLEX* cd[],
                                ltfat_int          M,
                                ltfat_int        N[],
                                ltfat_int          L,
                                const LTFAT_REAL   minlvl,
                                LTFAT_REAL*        tgrad[],
                                LTFAT_REAL*        fgrad[],
                                LTFAT_REAL*           cs[]);


/* ----- internal routines for calling BLAS and LAPACK ----- */

/*
// LAPACK overwrites the input argument.
ltfat_int
LTFAT_NAME(ltfat_posv)(ltfat_int N, ltfat_int NRHS,
             LTFAT_COMPLEX *A, ltfat_int lda,
             LTFAT_COMPLEX *B, ltfat_int ldb);

// LAPACK overwrites the input argument.
ltfat_int
LTFAT_NAME(ltfat_gesvd)(ltfat_int M, ltfat_int N,
              LTFAT_COMPLEX *A, ltfat_int lda,
              LTFAT_REAL *S, LTFAT_COMPLEX *U, ltfat_int ldu,
              LTFAT_COMPLEX *VT, ltfat_int ldvt);

void
LTFAT_NAME(ltfat_gemm)(const enum CBLAS_TRANSPOSE TransA,
             const enum CBLAS_TRANSPOSE TransB,
             ltfat_int M, ltfat_int N, ltfat_int K,
             const LTFAT_COMPLEX *alpha,
             const LTFAT_COMPLEX *A, ltfat_int lda,
             const LTFAT_COMPLEX *B, ltfat_int ldb,
             const LTFAT_COMPLEX *beta,
             LTFAT_COMPLEX *C, ltfat_int ldc);
*/


// // LAPACK overwrites the input argument.
// ltfat_int
// LTFAT_NAME(ltfat_posv)(const ptrdiff_t N, const ptrdiff_t NRHS,
//                        LTFAT_COMPLEX *A, const ptrdiff_t lda,
//                        LTFAT_COMPLEX *B, const ptrdiff_t ldb);
//
// // LAPACK overwrites the input argument.
// ltfat_int
// LTFAT_NAME(ltfat_gesvd)(const ptrdiff_t M, const ptrdiff_t N,
//                         LTFAT_COMPLEX *A, const ptrdiff_t lda,
//                         LTFAT_REAL *S, LTFAT_COMPLEX *U, const ptrdiff_t ldu,
//                         LTFAT_COMPLEX *VT, const ptrdiff_t ldvt);
//
// void
// LTFAT_NAME(ltfat_gemm)(const enum CBLAS_TRANSPOSE TransA,
//                        const enum CBLAS_TRANSPOSE TransB,
//                        const ptrdiff_t M, const ptrdiff_t N, const ptrdiff_t K,
//                        const LTFAT_COMPLEX *alpha,
//                        const LTFAT_COMPLEX *A, const ptrdiff_t lda,
//                        const LTFAT_COMPLEX *B, const ptrdiff_t ldb,
//                        const LTFAT_COMPLEX *beta,
//                        LTFAT_COMPLEX *C, const ptrdiff_t ldc);


/*   --- dgtreal_fb class definition  --- */

// typedef struct
// {
//     ltfat_int a;
//     ltfat_int M;
//     ltfat_int gl;
//     ltfat_phaseconvention ptype;
//     LTFAT_FFTW(plan) p_small;
//     LTFAT_REAL    *sbuf;
//     LTFAT_COMPLEX *cbuf;
//     LTFAT_REAL *fw;
//     LTFAT_REAL *gw;
//     LTFAT_COMPLEX *cout;
// } LTFAT_NAME(dgtreal_fb_plan);
//
//
// LTFAT_API LTFAT_NAME(dgtreal_fb_plan)
// LTFAT_NAME(dgtreal_fb_init)(const LTFAT_REAL *g,
//                             ltfat_int gl, ltfat_int a,
//                             ltfat_int M, const ltfat_phaseconvention ptype,
//                             unsigned flags);
//
// LTFAT_API void
// LTFAT_NAME(dgtreal_fb_execute)(const LTFAT_NAME(dgtreal_fb_plan) plan,
//                                const LTFAT_REAL *f, ltfat_int L,
//                                ltfat_int W, LTFAT_COMPLEX *cout);
//
// LTFAT_API void
// LTFAT_NAME(dgtreal_fb_done)(LTFAT_NAME(dgtreal_fb_plan) plan);


/*   --- dgt_ola class definition  --- */
typedef struct
{
    LTFAT_NAME_COMPLEX(dgt_long_plan)* plan;
    ltfat_int bl;
    ltfat_int gl;
    ltfat_int W;
    LTFAT_COMPLEX *buf;
    LTFAT_COMPLEX *gext;
    LTFAT_COMPLEX *cbuf;

} LTFAT_NAME(dgt_ola_plan);


LTFAT_API LTFAT_NAME(dgt_ola_plan)
LTFAT_NAME(dgt_ola_init)(const LTFAT_COMPLEX *g, ltfat_int gl,
                         ltfat_int W, ltfat_int a,
                         ltfat_int M, ltfat_int bl,
                         const ltfat_phaseconvention ptype, unsigned flags);

LTFAT_API void
LTFAT_NAME(dgt_ola_execute)(const LTFAT_NAME(dgt_ola_plan) plan,
                            const LTFAT_COMPLEX *f, ltfat_int L,
                            LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(dgt_ola_done)(LTFAT_NAME(dgt_ola_plan) plan);


// LTFAT_API void
// LTFAT_NAME(dgt_walnut_plan)(LTFAT_NAME(dgt_long_plan)* plan);


/*   --- dgtreal_ola class definition  --- */
typedef struct
{
    LTFAT_NAME(dgtreal_long_plan)* plan;
    ltfat_int bl;
    ltfat_int gl;
    ltfat_int W;
    LTFAT_REAL *buf;
    LTFAT_REAL *gext;
    LTFAT_COMPLEX *cbuf;

} LTFAT_NAME(dgtreal_ola_plan);


LTFAT_API LTFAT_NAME(dgtreal_ola_plan)
LTFAT_NAME(dgtreal_ola_init)(const LTFAT_REAL *g, ltfat_int gl,
                             ltfat_int W, ltfat_int a,
                             ltfat_int M, ltfat_int bl,
                             const ltfat_phaseconvention ptype,
                             unsigned flags);

LTFAT_API void
LTFAT_NAME(dgtreal_ola_execute)(const LTFAT_NAME(dgtreal_ola_plan) plan,
                                const LTFAT_REAL *f, ltfat_int L,
                                LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(dgtreal_ola_done)(LTFAT_NAME(dgtreal_ola_plan) plan);


// LTFAT_API void
// LTFAT_NAME(dgtreal_walnut_plan)(LTFAT_NAME(dgtreal_long_plan) plan);

/* -----  dgt_shearola class definition ------ */

typedef struct
{
    LTFAT_NAME(dgt_shear_plan) plan;
    ltfat_int bl;
    ltfat_int gl;
    ltfat_int W;
    LTFAT_COMPLEX *buf;
    LTFAT_COMPLEX *gext;
    LTFAT_COMPLEX *cbuf;

} LTFAT_NAME(dgt_shearola_plan);


LTFAT_API LTFAT_NAME(dgt_shearola_plan)
LTFAT_NAME(dgt_shearola_init)(const LTFAT_COMPLEX *g, ltfat_int gl,
                              ltfat_int W, ltfat_int a, ltfat_int M,
                              ltfat_int s0, ltfat_int s1, ltfat_int br,
                              ltfat_int bl,
                              unsigned flags);

LTFAT_API void
LTFAT_NAME(dgt_shearola_execute)(const LTFAT_NAME(dgt_shearola_plan) plan,
                                 const LTFAT_COMPLEX *f, ltfat_int L,
                                 LTFAT_COMPLEX *cout);

LTFAT_API void
LTFAT_NAME(dgt_shearola_done)(LTFAT_NAME(dgt_shearola_plan) plan);
