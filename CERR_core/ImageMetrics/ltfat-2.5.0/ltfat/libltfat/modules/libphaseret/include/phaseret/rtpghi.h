#ifndef LTFAT_NOSYSTEMHEADERS
#include "ltfat.h"
#include "ltfat/types.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

#include "phaseret/types.h"

#ifndef _phaseret_rtpghi_h
#define _phaseret_rtpghi_h
/** \addtogroup rtpghi
 *  @{
 */

/** Computes \a gamma parameter given window type and its length
 *
 * \param[in]   win  LTFAT Gabor window
 * \param[in]    gt  Window length
 *
 * \returns \a gamma or NAN if \a win was not recognized
 */
PHASERET_API double
phaseret_firwin2gamma(LTFAT_FIRWIN win, ltfat_int gl);

/** @} */

#endif


/** Plan for rtpghi
 *
 * Serves for storing state between calls to rtpghi_execute.
 *
 */
typedef struct PHASERET_NAME(rtpghi_state) PHASERET_NAME(rtpghi_state);
typedef struct PHASERET_NAME(rtpghiupdate_plan) PHASERET_NAME(rtpghiupdate_plan);

/** \addtogroup rtpghi
 *  @{
 */

/** Create a RTPGHI state.
 *
 * \param[in]     gamma        Window-specific constant Cg*gl^2
 * \param[in]     W            Number of channels
 * \param[in]     a            Hop size
 * \param[in]     M            Number of frequency channels (FFT length)
 * \param[in]     tol          Relative coefficient tolerance.
 * \param[in]     do_causal    Zero delay (1) or 1 frame delay (0) version of the alg.
 * \param[out]    p            RTPGHI state
 *
 * #### Versions #
 * <tt>
 * phaseret_rtpghi_init_d(double gamma, ltfat_int W, ltfat_int a, ltfat_int M,
 *                        double tol, int do_causal, phaseret_rtpghi_state_d** p);
 *
 * phaseret_rtpghi_init_s(double gamma, ltfat_int W, ltfat_int a, ltfat_int M,
 *                        double tol, int do_causal, phaseret_rtpghi_state_s** p);
 * </tt>
 * \returns
 *
 * \see phaseret_firwin2gamma
 */
PHASERET_API int
PHASERET_NAME(rtpghi_init)(ltfat_int W, ltfat_int a, ltfat_int M,
                           double gamma, double tol, int do_causal,
                           PHASERET_NAME(rtpghi_state)** p);

/** Reset RTPGHI state.
 *
 * Resets RTPGHI state struct to the initial state
 *
 * \param[out]    p            RTPGHI state
 *
 * #### Versions #
 * <tt>
 * phaseret_rtpghi_reset_d(phaseret_rtpghi_state_d* p);
 *
 * phaseret_rtpghi_reset_s(phaseret_rtpghi_state_s* p);
 * </tt>
 * \returns
 *
 */
PHASERET_API int
PHASERET_NAME(rtpghi_reset)(PHASERET_NAME(rtpghi_state)* p, const LTFAT_REAL** sinit );

/** Change the version of the algorithm
 *
 * Either to one-frame-delay version (do_causal==0) or to the
 * no-delay version (do_causal anything else).
 *
 * \note This is not thread safe
 *
 * \param[in] p         RTPGHI plan
 * \param[in] do_causal Causal flag
 *
 * #### Versions #
 * <tt>
 * phaseret_rtpghi_set_causal_d(phaseret_rtpghi_state_d* p, int do_causal);
 *
 * phaseret_rtpghi_set_causal_s(phaseret_rtpghi_state_s* p, int do_causal);
 * </tt>
 * \returns Status code
 */
PHASERET_API int
PHASERET_NAME(rtpghi_set_causal)(PHASERET_NAME(rtpghi_state)* p, int do_causal);

/** Change tolerance
 *
 * \note This is not thread safe
 *
 * \param[in] p     RTPGHI plan
 * \param[in] tol   Relative tolerance
 *
 * #### Versions #
 * <tt>
 * phaseret_rtpghi_set_tol_d(phaseret_rtpghi_state_d* p, double tol);
 *
 * phaseret_rtpghi_set_tol_s(phaseret_rtpghi_state_s* p, double tol);
 * </tt>
 * \returns Status code
 */
PHASERET_API int
PHASERET_NAME(rtpghi_set_tol)(PHASERET_NAME(rtpghi_state)* p, double tol);

/** Execute RTPGHI plan for a single frame
 *
 *  The function is intedned to be called for consecutive stream of frames
 *  as it reuses some data from the previous frames stored in the plan.
 *
 *  if do_causal is enebled, c is not lagging, else c is lagging by one
 *  frame.
 *
 * \param[in]       p   RTPGHI plan
 * \param[in]       s   Target magnitude
 * \param[out]      c   Reconstructed coefficients
 *
 * #### Versions #
 * <tt>
 * phaseret_rtpghi_execute_d(phaseret_rtpghi_state_d* p, const double s[],
 *                           ltfat_complex_d c[]);
 *
 * phaseret_rtpghi_execute_s(phaseret_rtpghi_state_s* p, const float s[],
 *                           ltfat_complex_s c[]);
 * </tt>
 */
PHASERET_API int
PHASERET_NAME(rtpghi_execute)(PHASERET_NAME(rtpghi_state)* p,
                              const LTFAT_REAL s[], LTFAT_COMPLEX c[]);

/** Destroy a RTPGHI Plan.
 * \param[in] p  RTPGHI Plan
 *
 * #### Versions #
 * <tt>
 * phaseret_rtpghi_done_d(phaseret_rtpghi_state_d** p);
 *
 * phaseret_rtpghi_done_s(phaseret_rtpghi_state_s** p);
 * </tt>
 */
PHASERET_API int
PHASERET_NAME(rtpghi_done)(PHASERET_NAME(rtpghi_state)** p);

/** Do RTPGHI for a complete magnitude spectrogram and compensate delay
 *
 * This function just creates a plan, executes it for each col in s and c
 * and destroys it.
 *
 * \param[in]     s          Magnitude spectrogram  M2 x N array
 * \param[in]     gamma      Window-specific constant Cg*gl^2
 * \param[in]     L          Transform length (possibly zero-padded).
 * \param[in]     W          Number of signal channels.
 * \param[in]     a          Hop size
 * \param[in]     M          FFT length, also length of all the windows
 * \param[out]    c          Reconstructed coefficients M2 x N array
 *
 * #### Versions #
 * <tt>
 * phaseret_rtpghioffline_d(const double s[], double gamma,
 *                          ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
 *                          double tol, int do_causal, ltfat_complex_d c[]);
 *
 * phaseret_rtpghioffline_s(const float s[], double gamma,
 *                          ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
 *                          double tol, int do_causal, ltfat_complex_s c[]);
 * </tt>
 *
 * \see phaseret_firwin2gamma ltfat_dgtreal_phaseunlock
 */
PHASERET_API int
PHASERET_NAME(rtpghioffline)(const LTFAT_REAL s[],
                             ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                             double gamma, double tol, int do_causal,
                             LTFAT_COMPLEX c[]);

/** @}*/

/** Compute phase frequency gradient by differentiation in time
 *
 * \param[in]     logs       Log-magnitude of a 3 x M2 buffer
 * \param[in]     a          Hop size
 * \param[in]     M          FFT length, also length of all the windows
 * \param[in]     gamma      Window-specific constant Cg*gl^2
 * \param[in]     do_causal  If true, fgrad is relevant for 3rd buffer col, else it
 *                           is relevant for 2nd buffer.
 * \param[out]    fgrad      Frequency gradient, array of length M2
 */
void
PHASERET_NAME(rtpghifgrad)(const LTFAT_REAL logs[], ltfat_int a, ltfat_int M, double gamma,
                           int do_causal, LTFAT_REAL fgrad[]);

/** Compute phase time gradient by differentiation in frequency
 *
 * \param[in]     logs       Log-magnitude, array of length M2
 * \param[in]     a          Hop size
 * \param[in]     M          FFT length, also length of all the windows
 * \param[in]     gamma      Window-specific constant Cg*gl^2
 * \param[out]    tgrad      Time gradient, array of length M2
 */
void
PHASERET_NAME(rtpghitgrad)(const LTFAT_REAL logs[], ltfat_int a, ltfat_int M, double gamma,
                           LTFAT_REAL tgrad[]);

/** Compute log of input
 * \param[in]   in  Input array of length L
 * \param[in]    L  Length of the arrays
 * \param[out] out  Output array of length L
 */
void
PHASERET_NAME(rtpghilog)(const LTFAT_REAL in[], ltfat_int L, LTFAT_REAL out[]);

/** Combine magnitude and phase to a complex array
 * \param[in]        s      Magnitude, array of length L
 * \param[in]    phase      Phase in rad, array of length L
 * \param[in]        L      Length of the arrays
 * \param[out]       c      Output array of length L
 */
void
PHASERET_NAME(rtpghimagphase)(const LTFAT_REAL s[], const LTFAT_REAL phase[], ltfat_int L, LTFAT_COMPLEX c[]);

PHASERET_API int
PHASERET_NAME(rtpghiupdate_init)(ltfat_int M, ltfat_int W, double tol,
                                 PHASERET_NAME(rtpghiupdate_plan)** pout);

PHASERET_API int
PHASERET_NAME(rtpghiupdate_execute)(PHASERET_NAME(rtpghiupdate_plan)* p,
                                    const LTFAT_REAL slog[],
                                    const LTFAT_REAL tgrad[],
                                    const LTFAT_REAL fgrad[],
                                    const LTFAT_REAL startphase[],
                                    LTFAT_REAL phase[]);

PHASERET_API int
PHASERET_NAME(rtpghiupdate_execute_withmask)(PHASERET_NAME(rtpghiupdate_plan)* p,
                                             const LTFAT_REAL slog[],
                                             const LTFAT_REAL tgrad[],
                                             const LTFAT_REAL fgrad[],
                                             const LTFAT_REAL startphase[],
                                             const int mask[], LTFAT_REAL phase[]);

PHASERET_API int
PHASERET_NAME(rtpghiupdate_execute_common)(PHASERET_NAME(rtpghiupdate_plan)* p,
                                             const LTFAT_REAL slog[],
                                             const LTFAT_REAL tgrad[],
                                             const LTFAT_REAL fgrad[],
                                             const LTFAT_REAL startphase[],
                                             LTFAT_REAL phase[]);

PHASERET_API int
PHASERET_NAME(rtpghiupdate_done)(PHASERET_NAME(rtpghiupdate_plan)** p);




#ifdef __cplusplus
}
#endif

