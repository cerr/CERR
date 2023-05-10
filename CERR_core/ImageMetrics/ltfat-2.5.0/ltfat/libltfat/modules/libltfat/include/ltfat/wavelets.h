#ifndef _LTFAT_WAVELETS_H
#define _LTFAT_WAVELETS_H


typedef enum
{
    PER,
    PERDEC,
    PPD,
    SYM,
    EVEN,
    SYMW,
    ASYM,
    ODD,
    ASYMW,
    SP0,
    ZPD,
    ZERO,
    VALID,
    BAD_TYPE
} ltfatExtType;

LTFAT_API ltfatExtType
ltfatExtStringToEnum(const char* extType);

LTFAT_API ltfat_int
filterbank_td_size(ltfat_int L, ltfat_int a,
                   ltfat_int gl, ltfat_int offset,
                   const ltfatExtType ext);

#endif

// CAN BE INCLUDED MORE THAN ONCE


LTFAT_API void
LTFAT_NAME(extend_left)(const LTFAT_TYPE *in, ltfat_int inLen, LTFAT_TYPE *buffer, ltfat_int buffLen, ltfat_int filtLen, ltfatExtType ext, ltfat_int a);

LTFAT_API void
LTFAT_NAME(extend_right)(const LTFAT_TYPE *in, ltfat_int inLen, LTFAT_TYPE *buffer, ltfat_int filtLen, ltfatExtType ext, ltfat_int a);




LTFAT_API void
LTFAT_NAME(convsub_td)(const LTFAT_TYPE *f, const LTFAT_TYPE *g,
                       ltfat_int L, ltfat_int gl, ltfat_int a, ltfat_int skip,
                       LTFAT_TYPE *c, ltfatExtType ext);


LTFAT_API void
LTFAT_NAME(upconv_td)(const LTFAT_TYPE *c, const LTFAT_TYPE *g,
                      ltfat_int L,  ltfat_int gl, ltfat_int a, ltfat_int skip,
                      LTFAT_TYPE *f, ltfatExtType ext);


LTFAT_API void
LTFAT_NAME(filterbank_td)(const LTFAT_TYPE *f, const LTFAT_TYPE *g[],
                          ltfat_int L, ltfat_int gl[], ltfat_int W,
                          ltfat_int a[], ltfat_int skip[], ltfat_int M,
                          LTFAT_TYPE *c[], ltfatExtType ext);


LTFAT_API void
LTFAT_NAME(ifilterbank_td)(const LTFAT_TYPE *c[], const LTFAT_TYPE *g[],
                           ltfat_int L, ltfat_int gl[], ltfat_int W, ltfat_int a[],
                           ltfat_int skip[], ltfat_int M, LTFAT_TYPE *f,
                           ltfatExtType ext);

LTFAT_API void
LTFAT_NAME(atrousfilterbank_td)(const LTFAT_TYPE *f, const LTFAT_TYPE *g[],
                                ltfat_int L, ltfat_int gl[], ltfat_int W,
                                ltfat_int a[], ltfat_int skip[], ltfat_int M,
                                LTFAT_TYPE *c, ltfatExtType ext);

LTFAT_API void
LTFAT_NAME(iatrousfilterbank_td)(const LTFAT_TYPE *c, const LTFAT_TYPE *g[],
                                 ltfat_int L, ltfat_int gl[], ltfat_int W, ltfat_int a[],
                                 ltfat_int skip[], ltfat_int M, LTFAT_TYPE *f,
                                 ltfatExtType ext);


LTFAT_API void
LTFAT_NAME(atrousconvsub_td)(const LTFAT_TYPE *f, const LTFAT_TYPE *g,
                             ltfat_int L, ltfat_int gl,
                             ltfat_int ga, ltfat_int skip,
                             LTFAT_TYPE *c, ltfatExtType ext);

LTFAT_API void
LTFAT_NAME(atrousupconv_td)(const LTFAT_TYPE *c, const LTFAT_TYPE *g,
                            ltfat_int L, ltfat_int gl,
                            ltfat_int ga, ltfat_int skip,
                            LTFAT_TYPE *f, ltfatExtType ext);






