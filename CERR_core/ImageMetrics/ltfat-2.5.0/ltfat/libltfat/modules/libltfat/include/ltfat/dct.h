#ifndef _LTFAT_DCT_H
#define _LTFAT_DCT_H

typedef enum
{
    DCTI, DCTIII, DCTII, DCTIV
} dct_kind;

#endif

typedef struct LTFAT_NAME(dct_plan) LTFAT_NAME(dct_plan);

LTFAT_API LTFAT_NAME(dct_plan)*
LTFAT_NAME(dct_init)( ltfat_int L, ltfat_int W, LTFAT_TYPE *cout,
                      const dct_kind kind);

LTFAT_API void
LTFAT_NAME(dct)(const LTFAT_TYPE *f, ltfat_int L, ltfat_int W,
                LTFAT_TYPE *cout, const dct_kind kind);

LTFAT_API void
LTFAT_NAME(dct_execute)(const LTFAT_NAME(dct_plan)* p, const LTFAT_TYPE *f,
                        ltfat_int L, ltfat_int W,
                        LTFAT_TYPE *cout, const dct_kind kind);

LTFAT_API void
LTFAT_NAME(dct_done)( LTFAT_NAME(dct_plan)* p);
