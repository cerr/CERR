#ifndef LTFAT_NOSYSTEMHEADERS
#include "ltfat.h"
#include "ltfat/types.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef _phaseret_spsi_h
#define _phaseret_spsi_h

#endif /* _spsi_h */

#include "phaseret/types.h"


/** \addtogroup spsi
 *  \{
 */

/** SPSI algorithm implementation
 *
 *  M2 = M/2 + 1, N = L/a
 *
 *  \param[in]             s   Target magnitude, size M2 x N x W
 *  \param[in]             L   Transform length
 *  \param[in]             W   Number of signal channels
 *  \param[in]             a   Hop factor
 *  \param[in]             M   Number of frequency channels
 *  \param[in,out] initphase   [in]  phase of -1 frame,
 *                             [out] phase of [N-1] frame, size M2 x W or NULL,
 *                             but then a memory allocation will occur.
 *  \param[out]            c   Coefficients with reconstructed phase, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * phaseret_spsi_d(const double s[], ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
 *                 double initphase[], ltfat_complex_d c[]);
 *
 * phaseret_spsi_s(const float s[], ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
 *                 float initphase[], ltfat_complex_s c[]);
 * </tt>
 *  \returns
 *  Status code          |  Description
 *  ---------------------|---------------------
 *  LTFATERR_SUCCESS     | No error occurred
 *  LTFATERR_NULLPOINTER | \a s or \a c was NULL
 *  LTFATERR_NOTPOSARG   | At least one of the following was not positive: \a L, \a W, \a a, \a M
 *  LTFATERR_NOMEM       | Heap allocation failed
 */
PHASERET_API int
PHASERET_NAME(spsi)(const LTFAT_REAL s[], ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M, LTFAT_REAL initphase[], LTFAT_COMPLEX c[]);

/** Masked SPSI algorithm implementation
 *
 *  Works as spsi() except c[ii]=cinit[ii] if mask[ii] evaluates to true.
 *
 *  M2 = M/2 + 1, N = L/a
 *
 *  \param[in]         cinit   Initial coefficients, size M2 x N x W
 *  \param[in]          mask   Mask of known coefficients
 *  \param[in]             L   Transform length
 *  \param[in]             W   Number of signal channels
 *  \param[in]             a   Hop factor
 *  \param[in]             M   Number of frequency channels
 *  \param[in,out] initphase   [in]  phase of -1 frame,
 *                             [out] phase of [N-1] frame, size M2 x W or NULL,
 *                             but then a memory allocation will occur.
 *  \param[out]            c   Coefficients with reconstructed phase, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * phaseret_spsi_withmask_d(const ltfat_complex_d cin[], const int mask[],
 *                          ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
 *                          double initphase[], ltfat_complex_d c[]);
 *
 * phaseret_spsi_withmask_s(const ltfat_complex_s cin[], const int mask[],
 *                          ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
 *                          float initphase[], ltfat_complex_s c[]);
 * </tt>
 *  \returns
 *  Status code          |  Description
 *  ---------------------|---------------------
 *  LTFATERR_SUCCESS     | No error occurred
 *  LTFATERR_NULLPOINTER | \a cinit, \a c or \a mask was NULL
 *  LTFATERR_NOTPOSARG   | At least one of the following was not positive: \a L, \a W, \a a, \a M
 *  LTFATERR_NOMEM       | Heap allocation failed
 */
PHASERET_API int
PHASERET_NAME(spsi_withmask)(const LTFAT_COMPLEX cin[], const int mask[], ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                             LTFAT_REAL initphase[], LTFAT_COMPLEX c[]);


/** \} */
void
PHASERET_NAME(spsiupdate)(const LTFAT_REAL* scol, ltfat_int stride, ltfat_int a, ltfat_int M, LTFAT_REAL* tmpphase);

#ifdef __cplusplus
}
#endif

