#ifndef LTFAT_NOSYSTEMHEADERS
#include "ltfat.h"
#include "ltfat/types.h"
#endif

#ifndef _phaseret_gsrtisila_h
#define _phaseret_gsrtisila_h
// place for non-templated structs, enums, functions etc.
#endif /* _gsrtisila_h */

#include "phaseret/types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct PHASERET_NAME(gsrtisilaupdate_plan) PHASERET_NAME(gsrtisilaupdate_plan);

typedef struct PHASERET_NAME(gsrtisila_state) PHASERET_NAME(gsrtisila_state);

PHASERET_API int
PHASERET_NAME(gsrtisilaupdate_init)(const LTFAT_REAL* g, const LTFAT_REAL* gd,
                                    ltfat_int gl, ltfat_int a, ltfat_int M,
                                    ltfat_int gNo, int do_ifftrealfirst,
                                    PHASERET_NAME(gsrtisilaupdate_plan)** p);

PHASERET_API int
PHASERET_NAME(gsrtisilaupdate_done)(PHASERET_NAME(gsrtisilaupdate_plan)** p);

PHASERET_API void
PHASERET_NAME(gsrtisilaupdate_execute)(PHASERET_NAME(gsrtisilaupdate_plan)* p,
                                       const LTFAT_REAL* frames, const LTFAT_COMPLEX* cframes, ltfat_int N,
                                       const LTFAT_REAL* s, ltfat_int lookahead, ltfat_int maxit,
                                       LTFAT_REAL* frames2, LTFAT_COMPLEX* cframes2,
                                       LTFAT_COMPLEX* c);

PHASERET_API int
PHASERET_NAME(gsrtisila_init_win)(LTFAT_FIRWIN win, ltfat_int gl, ltfat_int W,
                                  ltfat_int a, ltfat_int M, ltfat_int lookahead, ltfat_int maxit,
                                  PHASERET_NAME(gsrtisila_state)** pout);

PHASERET_API int
PHASERET_NAME(gsrtisila_init)(const LTFAT_REAL* g, ltfat_int gl, ltfat_int W,
                              ltfat_int a, ltfat_int M, ltfat_int lookahead, ltfat_int maxit,
                              PHASERET_NAME(gsrtisila_state)** pout);

PHASERET_API int
PHASERET_NAME(gsrtisila_execute)(PHASERET_NAME(gsrtisila_state)* p,
                                 const LTFAT_REAL s[], LTFAT_COMPLEX c[]);

PHASERET_API int
PHASERET_NAME(gsrtisila_done)(PHASERET_NAME(gsrtisila_state)** p);


PHASERET_API int
PHASERET_NAME(gsrtisila_reset)(PHASERET_NAME(gsrtisila_state)* p,
                               const LTFAT_REAL** stinit);

PHASERET_API int
PHASERET_NAME(gsrtisila_set_lookahead)(PHASERET_NAME(gsrtisila_state)* p,
                                       ltfat_int lookahead);

PHASERET_API int
PHASERET_NAME(gsrtisila_set_itno)(PHASERET_NAME(gsrtisila_state)* p,
                                  ltfat_int it);

PHASERET_API int
PHASERET_NAME(gsrtisila_set_skipinitialization)(PHASERET_NAME(gsrtisila_state)* p,
        int do_skipinitialization);

PHASERET_API int
PHASERET_NAME(gsrtisilaoffline)(const LTFAT_REAL s[], const LTFAT_REAL g[],
                                ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
                                ltfat_int lookahead, ltfat_int maxit, LTFAT_COMPLEX c[]);


#ifdef __cplusplus
}
#endif
