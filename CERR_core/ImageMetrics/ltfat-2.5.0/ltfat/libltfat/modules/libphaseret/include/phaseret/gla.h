#ifndef LTFAT_NOSYSTEMHEADERS
#include "ltfat.h"
#include "ltfat/types.h"
#endif

#include "phaseret/types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct PHASERET_NAME(gla_plan) PHASERET_NAME(gla_plan);

/** \addtogroup gla
 * @{
 *
 */

/** Function prototype for status callback
 *
 *  The callback is executed at the end of each iteration.
 *
 *  M2 = M/2 + 1, N = L/a
 *
 *  \param[in]         p   DGTREAL analysis-synthesis plan
 *  \param[in]  userdata   User defined data
 *  \param[in,out]     c   Set of coefficients at the end of iteration, size M2 x N x W
 *  \param[in]         L   Signal length
 *  \param[in]         W   Number of signal channels
 *  \param[in]         a   Time hop factor
 *  \param[in]         M   Number of frequency channels
 *  \param[in]     alpha   Acceleration parameter
 *  \param[in]      iter   Current iteration
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_callback_status_d(ltfat_dgtreal_plan_d* p,
 *                                void* userdata, ltfat_complex_d c[],
 *                                ltfat_int L, ltfat_int W, ltfat_int a,
 *                                ltfat_int M, double* alpha, ltfat_int iter);
 *
 *
 * phaseret_gla_callback_status_s(ltfat_dgtreal_plan_s* p,
 *                                void* userdata, ltfat_complex_s c[],
 *                                ltfat_int L, ltfat_int W, ltfat_int a,
 *                                ltfat_int M, double* alpha, ltfat_int iter);
 * </tt>
 *  \returns
 *  Status code | Meaning
 *  ------------|---------------------------------------------------------------------------------------
 *   0          | Signalizes that callback exited without error
 *  >0          | Signalizes that callback exited without error but terminate the algorithm prematurely
 *  <0          | Callback exited with error
 *
 *  \see dgtreal_execute_proj dgtreal_execute_ana dgtreal_execute_syn
 */
typedef int
PHASERET_NAME(gla_callback_status)(LTFAT_NAME(dgtreal_plan)* p,
                                   void* userdata, LTFAT_COMPLEX c[],
                                   ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M, double* alpha, ltfat_int iter);

/** Function prototype for coefficient modification callback
 *
 *  M2 = M/2 + 1, N = L/a
 *
 *  \param[in]  userdata   User defined data
 *  \param[in,out]     c   Set of coefficients to by updated, size M2 x N x W
 *  \param[in]         L   Signal length
 *  \param[in]         W   Number of signal channels
 *  \param[in]         a   Time hop factor
 *  \param[in]         M   Number of frequency channels
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_callback_cmod_d(void* userdata, ltfat_complex_d c[],
 *                              ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M);
 *
 * phaseret_gla_callback_cmod_s(void* userdata, ltfat_complex_s c[],
 *                              ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M);
 * </tt>
 *  \returns
 *  Status code | Meaning
 *  ------------|-----------------
 *   0          | Signalizes that callback exited without error
 *  <0          | Callback exited with error
 */
typedef int
PHASERET_NAME(gla_callback_cmod)(void* userdata, LTFAT_COMPLEX c[], ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M);

/** Function prototype for signal modification callback
 *
 *  \param[in]  userdata   User defined data
 *  \param[in,out]     f   Time-domain signal to be updated, size L x W
 *  \param[in]         L   Signal length
 *  \param[in]         W   Number of signal channels
 *  \param[in]         a   Time hop factor
 *  \param[in]         M   Number of frequency channels
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_callback_fmod_d(void* userdata, double f[],
 *                              ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M);
 *
 * phaseret_gla_callback_fmod_s(void* userdata, float f[],
 *                              ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M);
 * </tt>
 *  \returns
 *  Status code | Meaning
 *  ------------|-----------------
 *   0          | Signalizes that callback exited without error
 *  <0          | Callback exited with error
 */
typedef int
PHASERET_NAME(gla_callback_fmod)(void* userdata, LTFAT_REAL f[], ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M);


/** Griffin-Lim algorithm
 *
 *  M2 = M/2 + 1, N = L/a
 *
 *  \param[in]  cinit   Initial set of coefficients, size M2 x N x W
 *  \param[in]      g   Analysis window, size gl x 1
 *  \param[in]      L   Signal length
 *  \param[in]     gl   Window length
 *  \param[in]      W   Number of signal channels
 *  \param[in]      a   Time hop factor
 *  \param[in]      M   Number of frequency channels
 *  \param[in]   iter   Number of iterations
 *  \param[out]  cout   Coefficients with reconstructed phase, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_d(const ltfat_complex_d cinit[], const double g[],
 *                ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
 *                ltfat_int iter, ltfat_complex_d c[]);
 *
 * phaseret_gla_s(const ltfat_complex_s cinit[], const float g[],
 *                ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
 *                ltfat_int iter, ltfat_complex_s c[]);
 * </tt>
 *  \returns
 *  Status code           | Description
 *  ----------------------|-----------------------
 *  LTFATERR_SUCCESS      | No error occurred
 *  LTFATERR_NULLPOINTER  | \a cinit or \a g or \a cout was NULL
 *  LTFATERR_BADSIZE      | Signal length L is less or equal to 0.
 *  LTFATERR_NOTPOSARG    | At least one of \f W, \f a, \f M, \f gl was less or equal to zero.
 *  LTFATERR_BADTRALEN    | \a L is not divisible by both \a a and \a M.
 *  LTFATERR_NOTAFRAME    | System does not form a frame
 *  LTFATERR_INITFAILED   | The FFTW plan creation failed
 *  LTFATERR_NOTSUPPORTED | This is a non-painless system but its support was not compiled
 *  LTFATERR_NOMEM        | Memory allocation error occurred
 */
PHASERET_API int
PHASERET_NAME(gla)(const LTFAT_COMPLEX cinit[], const int mask[], const LTFAT_REAL g[],
                   ltfat_int L, ltfat_int gl, ltfat_int W,
                   ltfat_int a, ltfat_int M, ltfat_int iter, LTFAT_COMPLEX c[]);

/** Initialize Griffin-Lim algorithm plan
 *
 *  M2 = M/2 + 1, N = L/a
 *
 *  \note \a cinit can be NULL if the plan is intended to be used wit the _newarray
 *  execute function. Similarly, \a c can also be NULL only if FFTW_ESTIMATE is passed in flags
 *  (the FFTW planning routine does not touch the array).
 *  On the other hand, the content of c might get overwritten if other FFTW planning flags are used.
 *
 *  \note In-place mode i.e. \a cinit == \a c is allowed.
 *
 *  \param[in]  cinit   Initial set of coefficients, size M2 x N x W or NULL
 *  \param[in]      g   Analysis window, size gl x 1
 *  \param[in]      L   Signal length
 *  \param[in]     gl   Window length
 *  \param[in]      W   Number of signal channels
 *  \param[in]      a   Time hop factor
 *  \param[in]      M   Number of frequency channels
 *  \param[in]  alpha   Acceleration constant
 *  \param[in]      c   Array for holding coefficients with reconstructed phase, size M2 x N x W or NULL if flags == FFTW_ESTIMATE
 *  \param[in]   hint   DGT algorithm hint
 *  \param[in]  flags   FFTW planning flag
 *  \param[out]     p   GLA Plan
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_init_d(const ltfat_complex_d cinit[], const double g[],
 *                     ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
 *                     double alpha, ltfat_complex_d c[], phaseret_dgtreal_hint hint,
 *                     unsigned flags, phaseret_gla_plan_d** p);
 *
 * phaseret_gla_init_s(const ltfat_complex_s cinit[], const double g[],
 *                     ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
 *                     double alpha, ltfat_complex_s c[], phaseret_dgtreal_hint hint,
 *                     unsigned flags, phaseret_gla_plan_s** p);
 * </tt>
 *  \returns
 *  Status code           | Description
 *  ----------------------|-----------------------
 *  LTFATERR_SUCCESS      | No error occurred
 *  LTFATERR_NULLPOINTER  | \a cinit or \a g or or \a p was NULL or \a c was NULL and flags != FFTW_ESTIMATE
 *  LTFATERR_BADSIZE      | Signal length L is less or equal to 0.
 *  LTFATERR_NOTPOSARG    | At least one of \f W, \f a, \f M, \f gl was less or equal to zero.
 *  LTFATERR_BADTRALEN    | \a L is not divisible by both \a a and \a M.
 *  LTFATERR_NOTAFRAME    | System does not form a frame
 *  LTFATERR_INITFAILED   | The FFTW plan creation failed
 *  LTFATERR_NOTSUPPORTED | This is a non-painless system but its support was not compiled
 *  LTFATERR_BADARG       | \a alpha was set to a negative number
 *  LTFATERR_CANNOTHAPPEN | \a hint does not have a valid value from \a phaseret_dgtreal_hint or \a ptype is not valid value from \a ltfat_phaseconvention enum
 *  LTFATERR_NOMEM        | Memory allocation error occurred
 */
PHASERET_API int
PHASERET_NAME(gla_init)(const LTFAT_COMPLEX cinit[], const LTFAT_REAL g[],
                        ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a,
                        ltfat_int M, const double alpha, LTFAT_COMPLEX c[],
                        ltfat_dgt_params* params,
                        PHASERET_NAME(gla_plan)** p);

/** Execute Griffin-Lim algorithm plan
 *
 *  M2 = M/2 + 1, N = L/a
 *
 *  \param[in]      p   Griffin-lim algorithm plan
 *  \patam[in]   iter   Number of iterations
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_execute_d(phaseret_gla_plan_d* p, ltfat_int iter);
 *
 * phaseret_gla_execute_s(phaseret_gla_plan_s* p, ltfat_int iter);
 * </tt>
 *  \returns
 *  Status code           | Description
 *  ----------------------|-----------------------
 *  LTFATERR_SUCCESS      | No error occurred
 *  LTFATERR_NULLPOINTER  | \a p was NULL or the plan was created with \a cinit or \a cout being NULL
 *  LTFATERR_NOTPOSARG    | \a iter was not positive
 *  LTFATERR_BADARG       | \a alpha was set to a negative number in the status callback
 *  LTFATERR_NOMEM        | Memory allocation error occurred
 *  any                   | Error code from some of the callbacks
 */
PHASERET_API int
PHASERET_NAME(gla_execute)(PHASERET_NAME(gla_plan)* p, const int mask[], ltfat_int iter);

/** Execute Griffin-Lim algorithm plan on a new array
 *
 *  M2 = M/2 + 1, N = L/a
 *
 *  \param[in]      p   Griffin-lim algorithm plan
 *  \param[in]  cinit   Initial set of coefficients, size M2 x N x W
 *  \patam[in]   iter   Number of iterations
 *  \param[in]   cout   Coefficients with reconstructed phase, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_execute_newarray_d(phaseret_gla_plan_d* p,
 *                                 const ltfat_complex_d cinit[],
 *                                 ltfat_int iter, ltfat_complex_d c[]);
 *
 * phaseret_gla_execute_newarray_s(phaseret_gla_plan_s* p,
 *                                 const ltfat_complex_s cinit[],
 *                                 ltfat_int iter, ltfat_complex_s c[]);
 * </tt>
 *  \returns
 *  Status code           | Description
 *  ----------------------|-----------------------
 *  LTFATERR_SUCCESS      | No error occurred
 *  LTFATERR_NULLPOINTER  | \a p or \a cinit or \a cout was NULL
 *  LTFATERR_NOTPOSARG    | \a iter was not positive
 *  LTFATERR_BADARG       | \a alpha was set to a negative number in the status callback
 *  LTFATERR_NOMEM        | Memory allocation error occurred
 *  any                   | Error code from some of the callbacks
 */
PHASERET_API int
PHASERET_NAME(gla_execute_newarray)(PHASERET_NAME(gla_plan)* p,
                                    const LTFAT_COMPLEX cinit[], 
                                    const int mask[], ltfat_int iter,
                                    LTFAT_COMPLEX c[]);

/** Destroy Griffin-Lim algorithm plan
 *
 *  \param[in]      p   Griffin-lim algorithm plan
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_done_d(phaseret_gla_plan_d** p);
 *
 * phaseret_gla_done_s(phaseret_gla_plan_s** p);
 * </tt>
 *  \returns
 *  Status code           | Description
 *  ----------------------|-----------------------
 *  LTFATERR_SUCCESS      | No error occurred
 *  LTFATERR_NULLPOINTER  | \a p or \a *p was NULL
 */
PHASERET_API int
PHASERET_NAME(gla_done)(PHASERET_NAME(gla_plan)** p);

/** Register status callback
 *
 *  \param[in]         p   Griffin-lim algorithm plan
 *  \param[in]  callback   Callback function
 *  \param[in]  userdata   User defined data
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_set_status_callback_d(phaseret_gla_plan_d* p,
 *                                    phaseret_gla_callback_status_d* callback,
 *                                    void* userdata);
 *
 * phaseret_gla_set_status_callback_s(phaseret_gla_plan_s* p,
 *                                    phaseret_gla_callback_status_s* callback,
 *                                    void* userdata);
 * </tt>
 *  \returns
 *  Status code           | Description
 *  ----------------------|-----------------------
 *  LTFATERR_SUCCESS      | No error occurred
 *  LTFATERR_NULLPOINTER  | \a p or \a callback was NULL
 */
PHASERET_API int
PHASERET_NAME(gla_set_status_callback)(PHASERET_NAME(gla_plan)* p,
                                       PHASERET_NAME(gla_callback_status)* callback,
                                       void* userdata);

/** Register coefficient modification callback
 *
 *  \param[in]         p   Griffin-lim algorithm plan
 *  \param[in]  callback   Callback function
 *  \param[in]  userdata   User defined data
 *
 * #### Versions #
 * <tt>
 * phaseret_gla_set_cmod_callback_d(phaseret_gla_plan_d* p,
 *                                  phaseret_gla_callback_cmod_d* callback,
 *                                  void* userdata);
 *
 * phaseret_gla_set_cmod_callback_s(phaseret_gla_plan_s* p,
 *                                  phaseret_gla_callback_cmod_s* callback,
 *                                  void* userdata);
 * </tt>
 *  \returns
 *  Status code           | Description
 *  ----------------------|-----------------------
 *  LTFATERR_SUCCESS      | No error occurred
 *  LTFATERR_NULLPOINTER  | \a p or \a callback was NULL
 */
PHASERET_API int
PHASERET_NAME(gla_set_cmod_callback)(PHASERET_NAME(gla_plan)* p,
                                     PHASERET_NAME(gla_callback_cmod)* callback,
                                     void* userdata);

/** Register signal modification callback
 *
 *  \param[in]         p   Griffin-lim algorithm plan
 *  \param[in]  callback   Callback function
 *  \param[in]  userdata   User defined data
 *
 * #### Versions #
 * <tt>
 * phaseret_set_fmod_callback_d(phaseret_gla_plan_d* p,
 *                              phaseret_gla_callback_fmod_d* callback,
 *                              void* userdata);
 *
 * phaseret_set_fmod_callback_s(phaseret_gla_plan_s* p,
 *                              phaseret_gla_callback_fmod_s* callback,
 *                              void* userdata);
 * </tt>
 *  \returns
 *  Status code           | Description
 *  ----------------------|-----------------------
 *  LTFATERR_SUCCESS      | No error occurred
 *  LTFATERR_NULLPOINTER  | \a p or \a callback was NULL
 */
PHASERET_API int
PHASERET_NAME(gla_set_fmod_callback)(PHASERET_NAME(gla_plan)* p,
                                     PHASERET_NAME(gla_callback_fmod)* callback,
                                     void* userdata);

/** @} */

int
PHASERET_NAME(fastupdate)(LTFAT_COMPLEX* c, LTFAT_COMPLEX* t, double alpha, ltfat_int L);

#ifdef __cplusplus
}
#endif
