#ifndef LTFAT_NOSYSTEMHEADERS
#include "ltfat.h"
#include "ltfat/types.h"
#endif

#ifndef _phaseret_rtisila_h
#define _phaseret_rtisila_h
// place for non-templated structs, enums, functions etc.
#endif /* _rtisila_h */

#include "phaseret/types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct PHASERET_NAME(rtisilaupdate_plan) PHASERET_NAME(rtisilaupdate_plan);

typedef struct PHASERET_NAME(rtisila_state) PHASERET_NAME(rtisila_state);

void
PHASERET_NAME(overlaynthframe)(const LTFAT_REAL* frames, ltfat_int gl, ltfat_int N, ltfat_int a, ltfat_int n, LTFAT_REAL* frame);

/** Overlay frames to get n-th frame.
 *  \param[in,out] p        RTISILA Update Plan, p.frame contains the overlaid frame
 *  \param[in]     frames   N frames M samples long
 *  \param[in]     g        Analysis window
 *  \param[in]     n        Which frame to overlap
 *  \param[in]     N        Number of frames
 */
void
PHASERET_NAME(rtisilaoverlaynthframe)(PHASERET_NAME(rtisilaupdate_plan)* p,
                                      const LTFAT_REAL* frames, const LTFAT_REAL* g, ltfat_int n, ltfat_int N);

/** Phase update of a frame.
 * \param[in,out] p         RTISILA Update Plan, p.fftframe contains
 * \param[in]     sframe    Target spectrum magnitude
 * \param[out]    frameupd  Updated frame
 */
void
PHASERET_NAME(rtisilaphaseupdate)(PHASERET_NAME(rtisilaupdate_plan)* p,
                                  const LTFAT_REAL* sframe, LTFAT_REAL* frameupd, LTFAT_COMPLEX* c);

void
PHASERET_NAME(rtisilaphaseupdatesyn)(PHASERET_NAME(rtisilaupdate_plan) * p,
                                     const LTFAT_COMPLEX* c, LTFAT_REAL* frameupd);

/** Create a RTISILA Update Plan.
 * \param[in]     g          Analysis window
 * \param[in]     specg1     Analysis window used in the first iteration
 *                           for the newest lookahead frame
 * \param[in]     specg2     Analysis window used in the other iterations
 *                           for the newest lookahead frame
 * \param[in]     gd         Synthesis window
 * \param[in]     a          Hop size
 * \param[in]     M          FFT length, also length of all the windows
 *                           (possibly zero-padded).
 * \returns RTISILA Update Plan
 */
PHASERET_API int
PHASERET_NAME(rtisilaupdate_init)(const LTFAT_REAL *g, const LTFAT_REAL* specg1,
                                  const LTFAT_REAL* specg2, const LTFAT_REAL* gd,
                                  ltfat_int gl, ltfat_int a, ltfat_int M,
                                  PHASERET_NAME(rtisilaupdate_plan)** p);

/** Destroy a RTISILA Update Plan.
 * \param[in] p  RTISILA Update Plan
 */
PHASERET_API int
PHASERET_NAME(rtisilaupdate_done)(PHASERET_NAME(rtisilaupdate_plan)** p);

/** Do maxit iterations of RTISI-LA for a single frame
 *
 * N = lookback + 1 + lookahead
 * M2 = M/2 + 1
 *
 *
 * <em>Note the function can be run inplace i.e. frames and frames2 can
 * point to the same memory location.</em>
 *
 * \param[in,out] p          RTISILA Update Plan
 * \param[in]     frames     N frames M samples long
 * \param[in]     N          Number of frames
 * \param[in]     s          N frames M2 samples long
 * \param[in]     lookahead  Number of lookahead frames
 * \param[in]     maxit      Number of iterations
 * \param[out]    frames2    N output frames M samples long
 */
PHASERET_API void
PHASERET_NAME(rtisilaupdate_execute)(PHASERET_NAME(rtisilaupdate_plan)* p, const LTFAT_REAL* frames, ltfat_int N,
                                     const LTFAT_REAL* s, ltfat_int lookahead, ltfat_int maxit, LTFAT_REAL* frames2,
                                     LTFAT_COMPLEX* c);

/** Do maxit iterations of RTISI-LA for a single frame
 *
 * This function just creates a plan, executes it and destroys it.
 *
 * <em>Note the function can be run inplace i.e. frames and frames2 can
 * point to the same memory location.</em>
 *
 * \param[in]     frames     N frames M samples long
 * \param[in]     g          Analysis window
 * \param[in]     specg1     Analysis window used in the first iteration
 *                           for the newest lookahead frame
 * \param[in]     specg2     Analysis window used in the other iterations
 *                           for the newest lookahead frame
 * \param[in]     gd         Synthesis window
 * \param[in]     a          Hop size
 * \param[in]     M          FFT length, also length of all the windows
 *                           (possibly zero-padded).
 * \param[in]     N          Number of frames N = lookback + 1 + lookahead
 * \param[in]     s          Target magnitude, N frames M samples long
 * \param[in]     lookahead  Number of lookahead frames
 * \param[in]     maxit      Number of iterations
 * \param[out]    frames2    N output frames M samples long
 */
void
PHASERET_NAME(rtisilaupdate)(const LTFAT_REAL* frames,
                             const LTFAT_REAL* g, const LTFAT_REAL* specg1, const LTFAT_REAL* specg2, const LTFAT_REAL* gd,
                             ltfat_int gl, ltfat_int a, ltfat_int M, ltfat_int N, const LTFAT_REAL* s, ltfat_int lookahead, ltfat_int maxit,
                             LTFAT_REAL* frames2);

void
PHASERET_NAME(rtisilaupdatecoef)(const LTFAT_REAL* frames,
                                 const LTFAT_REAL* g, const LTFAT_REAL* specg1, const LTFAT_REAL* specg2,
                                 const LTFAT_REAL* gd, ltfat_int gl,
                                 ltfat_int a, ltfat_int M, ltfat_int N, const LTFAT_REAL* s, ltfat_int lookahead, ltfat_int maxit,
                                 LTFAT_REAL* frames2, LTFAT_COMPLEX* c);

/** \addtogroup rtisila
 *  @{
 *
 */



/** Create a RTISILA state.
 *
 * \param[in]     g            Analysis window
 * \param[in]     gl           Window length
 * \param[in]     W            Number of signal channels
 * \param[in]     a            Hop size
 * \param[in]     M            Number of frequency channels (FFT length)
 * \param[in]     lookahead    (Maximum) number of lookahead frames
 * \param[in]     maxit        Number of iterations. The number of per-frame
 *                             iterations is (lookahead+1) * maxit.
 * \param[out]    p            RTISILA state
 *
 * #### Versions #
 * <tt>
 * phaseret_rtisila_init_d(const double g[], ltfat_int gl, ltfat_int W,
 *                         ltfat_int a, ltfat_int M, ltfat_int lookahead,
 *                         ltfat_int maxit, phaseret_rtisila_state_d** p);
 *
 * phaseret_rtisila_init_s(const float g[], ltfat_int gl, ltfat_int W,
 *                         ltfat_int a, ltfat_int M, ltfat_int lookahead,
 *                         ltfat_int maxit, phaseret_rtisila_state_s** p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | \a p or \a g was NULL
 * LTFATERR_BADARG          | \a lookahead was a negative number
 * LTFATERR_BADSIZE         | \a gl was not positive
 * LTFATERR_NOTPOSARG       | One of the following was not positive: \a W, \a a, \a M, \a maxit
 * LTFATERR_NOTAFRAME       | System is not a frame.
 * LTFATERR_NOTPAINLESS     | System is not painless.
 * LTFATERR_INITFAILED      | FFTW plan creation failed
 * LTFATERR_NOMEM           | Indentifies that heap allocation failed
 */
PHASERET_API int
PHASERET_NAME(rtisila_init)(const LTFAT_REAL g[], ltfat_int gl, ltfat_int W,
                            ltfat_int a, ltfat_int M, ltfat_int lookahead, ltfat_int maxit,
                            PHASERET_NAME(rtisila_state)** p);

/** Create a RTISILA Plan from a window.
 * \param[in]     win          Analysis window
 * \param[in]     gl           Window length
 * \param[in]     W            Number of signal channels
 * \param[in]     a            Hop size
 * \param[in]     M            Number of frequency channels (FFT length)
 * \param[in]     lookahead    (Maximum) number of lookahead frames
 * \param[in]     maxit        Number of iterations. The number of per-frame
 *                             iterations is (lookahead+1) * maxit.
 * \param[out]    p            RTISILA state
 *
 * #### Versions #
 * <tt>
 * phaseret_rtisila_init_win_d(LTFAT_FIRWIN win, ltfat_int gl, ltfat_int W,
 *                             ltfat_int a, ltfat_int M, ltfat_int lookahead,
 *                             ltfat_int maxit, phaseret_rtisila_state_d** p);
 *
 * phaseret_rtisila_init_win_s(LTFAT_FIRWIN win, ltfat_int gl, ltfat_int W,
 *                             ltfat_int a, ltfat_int M, ltfat_int lookahead,
 *                             ltfat_int maxit, phaseret_rtisila_state_s** p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_CANNOTHAPPEN    | \a win is not a valid value from the \a LTFAT_FIRWIN enum
 * LTFATERR_NULLPOINTER     | \a p or \a g was NULL
 * LTFATERR_BADARG          | \a lookahead was a negative number
 * LTFATERR_BADSIZE         | \a gl was not positive
 * LTFATERR_NOTPOSARG       | One of the following was not positive: \a W, \a a, \a M, \a maxit
 * LTFATERR_NOTAFRAME       | System is not a frame.
 * LTFATERR_NOTPAINLESS     | System is not painless.
 * LTFATERR_INITFAILED      | FFTW plan creation failed
 * LTFATERR_NOMEM           | Indentifies that heap allocation failed
 */
PHASERET_API int
PHASERET_NAME(rtisila_init_win)(LTFAT_FIRWIN win, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
                                ltfat_int lookahead, ltfat_int maxit, PHASERET_NAME(rtisila_state)** p);

/** Change number of lookahead frames
 *
 * The number of frames can only be less or equal to the number of lookahead frames
 * specified in the init function.
 *
 * \note This is not thread safe.
 *
 * \param[in] p          RTISILA Plan
 * \param[in] lookahead  Number of lookahead frame
 *
 * #### Versions #
 * <tt>
 * phaseret_rtisila_set_lookahead_d(phaseret_rtisila_state_d* p, ltfat_int lookahead);
 *
 * phaseret_rtisila_set_lookahead_s(phaseret_rtisila_state_s* p, ltfat_int lookahead);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | \a p was NULL
 * LTFATERR_BADARG          | \a lookahead was a negative number or greater than max lookahead
 */
PHASERET_API int
PHASERET_NAME(rtisila_set_lookahead)(PHASERET_NAME(rtisila_state)* p, ltfat_int lookahead);


PHASERET_API int
PHASERET_NAME(rtisila_set_itno)(PHASERET_NAME(rtisila_state)* p, ltfat_int it);

/** Execute RTISILA plan for a single time frame
 *
 *  The function is intedned to be called for consecutive stream of frames
 *  as it reuses some data from the previous frames stored in the state.
 *
 *  \a c is lagging behind \a s by \a lookahead frames.
 *
 *  M2=M/2+1
 *
 * \param[in]       p   RTISILA plan
 * \param[in]       s   Target magnitude, size M2 x W
 * \param[out]      c   Reconstructed coefficients, size M2 x W
 *
* #### Versions #
 * <tt>
 * phaseret_rtisila_execute_d(phaseret_rtisila_state_d* p, const double s[],
 *                            ltfat_complex_d c[]);
 *
 * phaseret_rtisila_execute_s(phaseret_rtisila_state_s* p, const float s[],
 *                            ltfat_complex_s c[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p, \a s and \a c
 */
PHASERET_API int
PHASERET_NAME(rtisila_execute)(PHASERET_NAME(rtisila_state)* p,
                               const LTFAT_REAL s[], LTFAT_COMPLEX c[]);

/** Reset buffers of rtisila_state
 *
 * #### Versions #
 * <tt>
 * phaseret_rtisila_reset_d(phaseret_rtisila_state_d* p);
 *
 * phaseret_rtisila_reset_s(phaseret_rtisila_state_s* p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | \a p or \a *p was NULL.
 */
PHASERET_API int
PHASERET_NAME(rtisila_reset)(PHASERET_NAME(rtisila_state)* p,
                             const LTFAT_REAL** sinit);

/** Destroy a RTISILA Plan.
 * \param[in] p  RTISILA Plan
 *
 * #### Versions #
 * <tt>
 * phaseret_rtisila_done_d(phaseret_rtisila_state_d** p);
 *
 * phaseret_rtisila_done_s(phaseret_rtisila_state_s** p);
 * </tt>
 *
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | \a p or \a *p was NULL.
 */
PHASERET_API int
PHASERET_NAME(rtisila_done)(PHASERET_NAME(rtisila_state)** p);

/** Do RTISI-LA for a complete magnitude spectrogram and compensate delay
 *
 * This function just creates a plan, executes it for each col in s and c
 * and destroys it.
 *
 * M2 = M/2 + 1, N = L/a
 * The total number of per-frame iterations is: maxit x (lookahead + 1)
 *
 * \param[in]     s          Magnitude spectrogram, size M2 x N x W
 * \param[in]     g          Analysis window, size gl x 1
 * \param[in]     L          Transform length
 * \param[in]     gl         Window length
 * \param[in]     W          Number of signal channels
 * \param[in]     a          Hop size
 * \param[in]     M          Number of frequency channels (FFT length)
 * \param[in]     lookahead  Number of lookahead frames
 * \param[in]     maxit      Number of per-frame iterations
 * \param[out]    c          Reconstructed coefficients M2 x N array
 *
 * #### Versions #
 * <tt>
 * phaseret_rtisilaoffline_d(const double s[], const double g[], ltfat_int L,
 *                           ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
 *                           ltfat_int lookahead, ltfat_int maxit,
 *                           ltfat_complex_d c[]);
 *
 * phaseret_rtisilaoffline_s(const float s[], const float g[], ltfat_int L,
 *                           ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
 *                           ltfat_int lookahead, ltfat_int maxit,
 *                           ltfat_complex_s c[]);
 * </tt>
 */
PHASERET_API int
PHASERET_NAME(rtisilaoffline)(const LTFAT_REAL s[], const LTFAT_REAL g[],
                              ltfat_int L, ltfat_int gl, ltfat_int W, ltfat_int a, ltfat_int M,
                              ltfat_int lookahead, ltfat_int maxit, LTFAT_COMPLEX c[]);
/** @} */

#ifdef __cplusplus
}
#endif
