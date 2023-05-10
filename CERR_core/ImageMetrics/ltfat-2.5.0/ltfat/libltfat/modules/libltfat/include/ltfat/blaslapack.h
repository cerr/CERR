#ifndef _ltfat_blaslapack
#define _ltfat_blaslapack
#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/thirdparty/cblas.h"

#ifdef __cplusplus
extern "C"
{
#endif


// LAPACK overwrites the input argument.
ltfat_int
LTFAT_NAME(posv)(const ptrdiff_t N, const ptrdiff_t NRHS,
                 LTFAT_COMPLEX *A, const ptrdiff_t lda,
                 LTFAT_COMPLEX *B, const ptrdiff_t ldb);

// LAPACK overwrites the input argument.
ltfat_int
LTFAT_NAME(gesvd)(const ptrdiff_t M, const ptrdiff_t N,
                  LTFAT_COMPLEX *A, const ptrdiff_t lda,
                  LTFAT_REAL *S, LTFAT_COMPLEX *U, const ptrdiff_t ldu,
                  LTFAT_COMPLEX *VT, const ptrdiff_t ldvt);

void
LTFAT_NAME(gemm)(const enum CBLAS_TRANSPOSE TransA,
                 const enum CBLAS_TRANSPOSE TransB,
                 const ptrdiff_t M, const ptrdiff_t N, const ptrdiff_t K,
                 const LTFAT_COMPLEX *alpha,
                 const LTFAT_COMPLEX *A, const ptrdiff_t lda,
                 const LTFAT_COMPLEX *B, const ptrdiff_t ldb,
                 const LTFAT_COMPLEX *beta,
                 LTFAT_COMPLEX *C, const ptrdiff_t ldc);


#ifdef __cplusplus
}
#endif

#endif
