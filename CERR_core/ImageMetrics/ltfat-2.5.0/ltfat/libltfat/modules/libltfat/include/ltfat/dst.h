#ifndef _LTFAT_DST_H
#define _LTFAT_DST_H

typedef enum
{
    DSTI , DSTIII , DSTII, DSTIV
} dst_kind;

#endif

typedef struct LTFAT_NAME(dst_plan) LTFAT_NAME(dst_plan);

LTFAT_API LTFAT_NAME(dst_plan)*
LTFAT_NAME(dst_init)( ltfat_int L, ltfat_int W, LTFAT_TYPE *cout,
                      const dst_kind kind);

LTFAT_API void
LTFAT_NAME(dst)(const LTFAT_TYPE *f, ltfat_int L, ltfat_int W,
                LTFAT_TYPE *cout, const dst_kind kind);

LTFAT_API void
LTFAT_NAME(dst_execute)(LTFAT_NAME(dst_plan)* p, const LTFAT_TYPE *f,
                        ltfat_int L, ltfat_int W, LTFAT_TYPE *cout,
                        const dst_kind kind);

LTFAT_API void
LTFAT_NAME(dst_done)( LTFAT_NAME(dst_plan)* p);
