
#ifndef LTFAT_NOSYSTEMHEADERS
#include "ltfat.h"
#include "ltfat/types.h"
#endif
#include "phaseret/types.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Shifts cols of height x N matrix by one to the left
 *
 *  \param[in,o]   cols     Input/output matrix
 *  \param[in]     height   Height
 *  \param[in]     N        No. of cols
 *  \param[in]     newcol   (optional) Length height vector to be used as the last col.
 *                          If it is NULL, it is set to zeros.
 */
int
PHASERET_NAME(shiftcolsleft)(LTFAT_REAL cols[], ltfat_int height, ltfat_int N, const LTFAT_REAL newcol[]);

int
PHASERET_NAME_COMPLEX(shiftcolsleft)(LTFAT_COMPLEX cols[], ltfat_int height, ltfat_int N, const LTFAT_COMPLEX newcol[]);

int
PHASERET_NAME(force_magnitude)(LTFAT_COMPLEX cin[], const LTFAT_REAL s[], ltfat_int L, LTFAT_COMPLEX cout[]);

void
PHASERET_NAME(realimag2absangle)(const LTFAT_COMPLEX cin[], ltfat_int L, LTFAT_COMPLEX c[]);

void
PHASERET_NAME(absangle2realimag)(const LTFAT_COMPLEX cin[], ltfat_int L, LTFAT_COMPLEX c[]);

PHASERET_API void
PHASERET_NAME(absangle2realimag_split2inter)(const LTFAT_REAL s[],
        const LTFAT_REAL phase[], ltfat_int L, LTFAT_COMPLEX c[]);

#ifdef __cplusplus
}
#endif


