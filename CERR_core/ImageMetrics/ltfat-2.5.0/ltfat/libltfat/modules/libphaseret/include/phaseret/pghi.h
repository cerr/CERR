#ifndef LTFAT_NOSYSTEMHEADERS
#include "ltfat.h"
#include "ltfat/types.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

#include "phaseret/types.h"

typedef struct PHASERET_NAME(pghi_plan) PHASERET_NAME(pghi_plan);

/** \addtogroup pghi
 * @{
 */

/** Reconstruct complex coefficients from the magnitude using PGHI algorithm
 *
 * M2 = M/2 + 1, N = L/a
 *
 * \param[in]        s  Target magnitude, size M2 x N x W
 * \param[in]    gamma  Window specific constant
 * \param[in]        L  Signal length
 * \param[in]        W  Number of channels
 * \param[in]        a  Hop factor
 * \param[in]        M  Number of frequency channels (FFT length)
 * \param[out]       c  Reconstructed coefficients, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * phaseret_pghi_d(const double s[], double gamma, ltfat_int L, ltfat_int W,
 *                 ltfat_int a, ltfat_int M, ltfat_complex_d c[]);
 *
 * phaseret_pghi_s(const double s[], double gamma, ltfat_int L, ltfat_int W,
 *                 ltfat_int a, ltfat_int M, ltfat_complex_s c[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | Indicates that at least one of the following was NULL: \a c, \a s
 * LTFATERR_NOTPOSARG       | At least one of the followig was not positive: \a L, \a W, \a a
 * LTFATERR_BADARG          | \a gamma was not positive or it was NAN.
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 *
 * \see firwin2gamma
 */
PHASERET_API int
PHASERET_NAME(pghi)(const LTFAT_REAL s[], ltfat_int L, ltfat_int W,
                    ltfat_int a, ltfat_int M, double gamma, LTFAT_COMPLEX c[]);

/** Reconstruct complex coefficients from the magnitude using PGHI algorithm
 * ... using some known coefficients.
 *
 * M2 = M/2 + 1, N = L/a
 *
 * \param[in]      cin  Coefficients with initial phase, size M2 x N X W
 * \param[in]     mask  Mask used to select coefficients with known phase, size  M2 x N X W
 * \param[in]    gamma  Window specific constant
 * \param[in]        L  Signal length
 * \param[in]        W  Number of signal channels
 * \param[in]        a  Hop factor
 * \param[in]        M  Number of frequency channels (FFT length)
 * \param[out]       c  Reconstructed coefficients, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * phaseret_pghi_withmask_d(const ltfat_complex_d s[], const int mask[],
 *                          double gamma, ltfat_int L, ltfat_int W,
 *                          ltfat_int a, ltfat_int M, ltfat_complex_d c[]);
 *
 * phaseret_pghi_withmask_s(const ltfat_complex_s s[], const int mask[],
 *                          double gamma, ltfat_int L, ltfat_int W,
 *                          ltfat_int a, ltfat_int M, ltfat_complex_s c[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | Indicates that at least one of the following was NULL: \a cin, \a c, \a mask
 * LTFATERR_NOTPOSARG       | At least one of the followig was not positive: \a L, \a W, \a a
 * LTFATERR_BADARG          | \a gamma was not positive or it was NAN.
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 *
 * \see firwin2gamma
 */
PHASERET_API int
PHASERET_NAME(pghi_withmask)(const LTFAT_COMPLEX cin[], const int mask[],
                             ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                             double gamma, LTFAT_COMPLEX c[]);

/** Initialize PGHI plan
 *
 * M2 = M/2 + 1, N = L/a
 *
 * \param[in]    gamma  Window specific constant
 * \param[in]        L  Signal length
 * \param[in]        W  Number of channels
 * \param[in]        a  Hop factor
 * \param[in]        M  Number of frequency channels (FFT length)
 * \param[in]     tol1  Relative tolerance for the first pass, must be in range [0-1]
 * \param[in]     tol2  Relative tolernace for the second pass, must be in range [0-1] and
 *                      lower or equal to \a tol1. If \a tol2 is NAN or it is equal to
 *                      \a tol1, only the first pass will be done.
 * \param[out]       p  PGHI plan
 *
 * #### Versions #
 * <tt>
 * phaseret_pghi_init_d(double gamma, ltfat_int L, ltfat_int W,
 *                      ltfat_int a, ltfat_int M, double tol1, double tol2,
 *                      phaseret_pghi_plan_d** p);
 *
 * phaseret_pghi_init_s(double gamma, ltfat_int L, ltfat_int W,
 *                      ltfat_int a, ltfat_int M, double tol1, double tol2,
 *                      phaseret_pghi_plan_s** p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | \a p was NULL.
 * LTFATERR_NOTPOSARG       | At least one of the followig was not positive: \a L, \a W, \a a
 * LTFATERR_BADARG          | \a gamma was not positive
 * LTFATERR_NOTINRANGE      | \a tol1 and \a tol2 were not in range [0-1] or \a tol1 < \a tol2
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 *
 * \see firwin2gamma
 */
PHASERET_API int
PHASERET_NAME(pghi_init)(ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                         double gamma, double tol1, double tol2,
                         PHASERET_NAME(pghi_plan)** p);

/** Execute PGHI plan
 *
 * M2 = M/2 + 1, N = L/a
 *
 * \param[in]      p  PGHI plan
 * \param[in]      s  Target magnitude of coefficients, size M2 x N X W
 * \param[out]     c  Output coefficients with reconstructed phase, size M2 x N X W
 *
 * #### Versions #
 * <tt>
 * phaseret_pghi_execute_d(phaseret_pghi_plan_d* p,
 *                         const double s[], ltfat_complex_d c[]);
 *
 * phaseret_pghi_execute_s(phaseret_pghi_plan_s* p,
 *                         const float s[], ltfat_complex_s c[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | Indicates that at least one of the following was NULL: \a p, \a c, \a s
 */
PHASERET_API int
PHASERET_NAME(pghi_execute)(PHASERET_NAME(pghi_plan)* p, const LTFAT_REAL s[], LTFAT_COMPLEX c[]);

/** Execute PGHI plan with respect to mask
 *
 * M2 = M/2 + 1, N = L/a
 *
 * Nonzero values in \a mask represent known coefficient in \cin
 *
 * \param[in]      p  PGHI plan
 * \param[in]    cin  Coefficients with initial phase, size M2 x N X W
 * \param[in]   mask  Mask used to select coefficients with known phase, size  M2 x N X W
 * \param[in] buffer  Work buffer, size M2 x N. Internal heap allocation occurs if it is NULL
 * \param[out]  cout  Output coefficients with reconstructed phase, size M2 x N X W
 *
 * #### Versions #
 * <tt>
 * phaseret_pghi_execute_withmask_d(phaseret_pghi_plan_d* p,
 *                                  const ltfat_complex_d cin[], const int mask[],
 *                                  double buffer[], ltfat_complex_d c[]);
 *
 * phaseret_pghi_execute_withmask_s(phaseret_pghi_plan_s* p,
 *                                  const ltfat_complex_s cin[], const int mask[],
 *                                  double buffer[], ltfat_complex_s c[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | Indicates that at least one of the following was NULL: \a p, \a cin, \a mask, \a cout
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
PHASERET_API int
PHASERET_NAME(pghi_execute_withmask)(PHASERET_NAME(pghi_plan)* p,
                                     const LTFAT_COMPLEX cin[], const int mask[],
                                     LTFAT_REAL buffer[], LTFAT_COMPLEX c[]);

/** Destroy PGHI plan
 *
 * \param[in]   p  PGHI plan
 *
 * #### Versions #
 * <tt>
 * phaseret_pghi_done_d(phaseret_pghi_plan_d** p);
 *
 * phaseret_pghi_done_s(phaseret_pghi_plan_s** p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | \a p was NULL
 */
PHASERET_API int
PHASERET_NAME(pghi_done)(PHASERET_NAME(pghi_plan)** p);
/** @} */

PHASERET_API int*
PHASERET_NAME(pghi_get_mask)(PHASERET_NAME(pghi_plan)* p);

void
PHASERET_NAME(pghimagphase)(const LTFAT_REAL s[], const LTFAT_REAL phase[],
                            ltfat_int L, LTFAT_COMPLEX c[]);

void
PHASERET_NAME(pghilog)(const LTFAT_REAL in[], ltfat_int L, LTFAT_REAL out[]);

void
PHASERET_NAME(pghitgrad)(const LTFAT_REAL logs[], double gamma, ltfat_int a, ltfat_int M, ltfat_int N, LTFAT_REAL tgrad[]);

void
PHASERET_NAME(pghifgrad)(const LTFAT_REAL logs[], double gamma, ltfat_int a, ltfat_int M, ltfat_int N, LTFAT_REAL fgrad[]);


#ifdef __cplusplus
}
#endif
