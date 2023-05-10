#ifndef _LTFAT_GOERTZEL_H
#define _LTFAT_GOERTZEL_H

typedef enum
{
    CZT_NEXTFASTFFT,
    CZT_NEXTPOW2
} czt_ffthint;

#endif


/*
Goertzel algorithm
*/
// This is opaque pointer
typedef struct LTFAT_NAME(gga_plan_struct) *LTFAT_NAME(gga_plan);

LTFAT_API LTFAT_NAME(gga_plan)
LTFAT_NAME(gga_init)(const LTFAT_REAL *indVecPtr,
                     ltfat_int M, ltfat_int L);

LTFAT_API void
LTFAT_NAME(gga_done)(LTFAT_NAME(gga_plan) plan);


LTFAT_API
void LTFAT_NAME(gga)(const LTFAT_TYPE *fPtr, const LTFAT_REAL *indVecPtr,
                     ltfat_int L, ltfat_int W, ltfat_int M,
                     LTFAT_COMPLEX *cPtr);

LTFAT_API void
LTFAT_NAME(gga_execute)(LTFAT_NAME(gga_plan) p,
                        const LTFAT_TYPE *fPtr,
                        ltfat_int W,
                        LTFAT_COMPLEX *cPtr);


/*
Chirped Z transform
*/
// This is opaque pointer
typedef struct LTFAT_NAME(chzt_plan_struct) *LTFAT_NAME(chzt_plan);

LTFAT_API void
LTFAT_NAME(chzt)(const LTFAT_TYPE *fPtr, ltfat_int L,
                      ltfat_int W, ltfat_int K,
                      const LTFAT_REAL deltao, const LTFAT_REAL o,
                      LTFAT_COMPLEX *cPtr);

LTFAT_API void
LTFAT_NAME(chzt_execute)(LTFAT_NAME(chzt_plan) p, const LTFAT_TYPE *fPtr,
                         ltfat_int W, LTFAT_COMPLEX *cPtr);

LTFAT_API LTFAT_NAME(chzt_plan)
LTFAT_NAME(chzt_init)(ltfat_int K, ltfat_int L,
                      const LTFAT_REAL deltao, const LTFAT_REAL o,
                      const unsigned fftw_flags, czt_ffthint hint);

LTFAT_API
void LTFAT_NAME(chzt_done)(LTFAT_NAME(chzt_plan) p);




LTFAT_API void
LTFAT_NAME(chzt_fac)(const LTFAT_TYPE *fPtr, ltfat_int L,
                     ltfat_int W, ltfat_int K,
                     const LTFAT_REAL deltao, const LTFAT_REAL o,
                     LTFAT_COMPLEX *cPtr);

LTFAT_API void
LTFAT_NAME(chzt_fac_execute)(LTFAT_NAME(chzt_plan) p, const LTFAT_TYPE *fPtr,
                             ltfat_int W, LTFAT_COMPLEX *cPtr);

LTFAT_API LTFAT_NAME(chzt_plan)
LTFAT_NAME(chzt_fac_init)(ltfat_int K, ltfat_int L,
                          const LTFAT_REAL deltao, const LTFAT_REAL o,
                          const unsigned fftw_flags, czt_ffthint hint);
