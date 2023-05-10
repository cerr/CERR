#ifndef _LTFAT_RTDGTREAL_H
#define _LTFAT_RTDGTREAL_H

typedef enum
{
    LTFAT_RTDGTPHASE_ZERO,
    LTFAT_RTDGTPHASE_HALFSHIFT
} rtdgt_phasetype;

typedef enum
{
    LTFAT_FORWARD,
    LTFAT_INVERSE
} ltfat_transformdirection;

#endif /* _RTDGTREAL_H */


typedef struct LTFAT_NAME(rtdgtreal_plan) LTFAT_NAME(rtdgtreal_plan);
// For now, the inverse plan is the same
typedef LTFAT_NAME(rtdgtreal_plan) LTFAT_NAME(rtidgtreal_plan);

int
LTFAT_NAME(rtdgtreal_commoninit)(const LTFAT_REAL* g, ltfat_int gl,
                                 ltfat_int M, const rtdgt_phasetype ptype,
                                 const  ltfat_transformdirection tradir,
                                 LTFAT_NAME(rtdgtreal_plan)** p);

/** Create RTDGTREAL plan
 *
 * The function returns NULL if the FFTW plan cannot be crated or there is not enough
 * memory to allocate internal buffers.
 *
 * \param[in]  g      Window
 * \param[in]  gl     Window length
 * \param[in]  M      Number of FFT channels
 * \param[in]  ptype  Phase convention
 *
 * \returns RTDGTREAL plan
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_init)(const LTFAT_REAL g[], ltfat_int gl,
                           ltfat_int M, const rtdgt_phasetype ptype,
                           LTFAT_NAME(rtdgtreal_plan)** p);

/** Execute RTDGTREAL plan
 * \param[in]  p      RTDGTREAL plan
 * \param[in]  f      Input buffer (gl x W)
 * \param[in]  W      Number of channels
 * \param[out] c      Output DGT coefficients (M2 x W)
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_execute)(const LTFAT_NAME(rtdgtreal_plan)* p,
                              const LTFAT_REAL f[], ltfat_int W,
                              LTFAT_COMPLEX c[]);

/** Destroy RTDGTREAL plan
 * \param[in]  p      RTDGTREAL plan
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_done)(LTFAT_NAME(rtdgtreal_plan)** p);

/** Create RTIDGTREAL plan
 *
 * The function returns NULL if the FFTW plan cannot be crated or there is not enough
 * memory to allocate internal buffers.
 *
 * \param[in]  g      Window
 * \param[in]  gl     Window length
 * \param[in]  M      Number of FFT channels
 * \param[in]  ptype  Phase convention
 *
 * \returns RTIDGTREAL plan
 */
LTFAT_API int
LTFAT_NAME(rtidgtreal_init)(const LTFAT_REAL g[], ltfat_int gl,
                            ltfat_int M, const rtdgt_phasetype ptype,
                            LTFAT_NAME(rtdgtreal_plan)** p);

/** Execute RTIDGTREAL plan
 * \param[in]  p      RTDGTREAL plan
 * \param[int] c      Input DGT coefficients (M2 x W)
 * \param[in]  W      Number of channels
 * \param[out] f      Output buffer (gl x W)
 */
LTFAT_API int
LTFAT_NAME(rtidgtreal_execute)(const LTFAT_NAME(rtidgtreal_plan)* p,
                               const LTFAT_COMPLEX c[], ltfat_int W,
                               LTFAT_REAL f[]);

/** Destroy RTIDGTREAL plan
 * \param[in]  p      RTIDGTREAL plan
 */
LTFAT_API int
LTFAT_NAME(rtidgtreal_done)(LTFAT_NAME(rtidgtreal_plan)** p);



typedef struct LTFAT_NAME(rtdgtreal_processor_state) LTFAT_NAME(rtdgtreal_processor_state);

/* \defgroup rtdgtrealprocessor Real-Time Discrete Gabor Transform Processor
 *  \addtogroup rtdgtrealprocessor
 *  @{
 *  The real-time DGT processor wraps the analysis-modify-synthesis loop for
 *  audio streams. It provides a callback interface which allows user-defined
 *  coefficient manipulation.
 *
 *  Example:
 *  ~~~~~~~~~~~~~~~{.c}
 *  // Simple coefficient modification
 *  void process(void *userdata, const ltfat_complex_s inCoef[], const int M2, const int W, ltfat_complex_s outCoef[])
 *  {
 *      for(int w=0; w<W; w++) // Loop over channels
 *          for(int m=0; m<M2; m++) // Loop over frequencies
 *              out[m+w*M2] = 2.0f*in[m+w*M2];
 *  }
 *
 *  // Initialize
 *  ltfat_rtdgtreal_processor_state_s* procstate = NULL;
 *  ltfat_rtdgtreal_processor_init_win_s( LTFAT_HANN, 1024, 256, 1024, maxChanNo, &process, NULL, &procstate);
 *
 *  // In the audio loop
 *  void audioCallback(float** data, int dataLen, int chanNo)
 *  {
 *      ltfat_rtdgtreal_processor_execute_s(procstate, data, dataLen, chanNo, data);
 *  }
 *
 *  // Teardown
*   ltfat_rtdgtreal_processor_done_s(&procstate);
 *  ~~~~~~~~~~~~~~~
 */

/** Processor callback signature
 *
 * User defined processor callback must comply with this signature.
 *
 * It is safe to assume that out and in are not aliased.
 *
 * \param[in]  userdata   User defined data
 * \param[in]        in   Input coefficients, M2 x W array
 * \param[in]        M2   Length of the arrays; number of unique FFT channels; equals to M/2 + 1
 * \param[in]         W   Number of channels
 * \param[out]      out   Output coefficients, M2 x W array
 *
 *  #### Function versions #
 *  <tt>
 *  typedef void ltfat_rtdgtreal_processor_callback_d(void* userdata, const ltfat_complex_d in[], int M2,
 *                                                    int W, ltfat_complex_d out[]);
 *
 *  typedef void ltfat_rtdgtreal_processor_callback_s(void* userdata, const ltfat_complex_s in[], ltfat_int M2,
 *                                                    int W, ltfat_complex_s out[]);
 *  </tt>
 *
 */
typedef void LTFAT_NAME(rtdgtreal_processor_callback)(void* userdata,
        const LTFAT_COMPLEX in[], int M2, int W, LTFAT_COMPLEX out[]);

/** Create DGTREAL processor state struct
 *
 * The processor wraps DGTREAL analysis-modify-synthesis loop suitable for
 * stream of data. The -modify- part is user definable via callback.
 * If the callback is NULL, no coefficient modification occurs.
 *
 * \param[in]          ga   Analysis window
 * \param[in]         gal   Length of the analysis window
 * \param[in]          gs   Synthesis window
 * \param[in]       ' gsl   Length of the synthesis window
 * \param[in]           a   Hop size
 * \param[in]           M   Number of FFT channels
 * \param[in]        Wmax   Maximum number of channels
 * \param[in]   bufLenMax   Maximum buffer length expected in execute
 * \param[out]       plan   DGTREAL processor state
 *
 * #### Function versions #
 * <tt>
 * ltfat_rtdgtreal_processor_init_d(const double ga[], ltfat_int gal, const double gs[], ltfat_int gsl,
 *                                  ltfat_int a, ltfat_int M, ltfat_int Wmax, ltfat_int bufLenMax,
 *                                  rtdgtreal_processor_state_d** plan);
 *
 * ltfat_rtdgtreal_processor_init_s(const float ga[], ltfat_int gal, const float gs[], ltfat_int gsl,
 *                                  ltfat_int a, ltfat_int M, ltfat_int Wmax, ltfat_int bufLenMax,
 *                                  rtdgtreal_processor_state_s** plan);
 * </tt>
 *
 * \returns
 * Status code           |  Description
 * ----------------------|----------------------
 * LTFATERR_SUCCESS      |  No error occured
 * LTFATERR_NULLPOINTER  |  One of the following was NULL: \a ga, \a gs, \a plan
 * LTFATERR_BADSIZE      |  \a gla or \a gls was less or equal to 0
 * LTFATERR_NOTPOSARG    |  At least one of the following was less or equal to zero: \a a, \a M, \a Wmax
 * LTFATERR_CANNOTHAPPEN |  \a win was not valid value from the LTFAT_FIRWIN enum.
 * LTFATERR_NOMEM        |  Heap memory allocation failed
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_init)(const LTFAT_REAL ga[], ltfat_int gal,
                                     const LTFAT_REAL gs[], ltfat_int gsl,
                                     ltfat_int a, ltfat_int M, ltfat_int Wmax,
                                     ltfat_int bufLenMax, ltfat_int procDelay,
                                     LTFAT_NAME(rtdgtreal_processor_state)** plan);

/** Reset processor state
 *
 * Whenever there is a break in the continuity of the input stream, the state 
 * should be reset before feeding new data.
 *
 * \param[in]    p   Processor state
 *
 * #### Function versions #
 * <tt>
 * ltfat_rtdgtreal_processor_reset_d(rtdgtreal_processor_state_d* p);
 *
 * ltfat_rtdgtreal_processor_reset_s(rtdgtreal_processor_state_s* p);
 * </tt>
 *
 * \returns
 * Status code           |  Description
 * ----------------------|----------------------
 * LTFATERR_SUCCESS      |  No error occured
 * LTFATERR_NULLPOINTER  |  \a p was NULL
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_reset)(LTFAT_NAME(rtdgtreal_processor_state)* p);

/** Create DGTREAL processor state struct
 *
 * This function provides an alternative way of creating DGTREAL processor
 * state struct. The function accepts only the analysis window and the synthesis
 * window is computed internally.
 *
 * \param[in]         win   Analysis window
 * \param[in]          gl   Length of the windows
 * \param[in]           a   Hop size
 * \param[in]           M   Number of FFT channels
 * \param[in]        Wmax   Maximum number of channels
 * \param[in]   bufLenMax   Maximum buffer length expected in execute
 * \param[out]       plan   DGTREAL processor state
 *
 * #### Function versions #
 * <tt>
 * ltfat_rtdgtreal_processor_init_win_d(LTFAT_FIRWIN win, ltfat_int gl, ltfat_int a, ltfat_int M,
 *                                      ltfat_int Wmax, ltfat_int bufLenMax,
 *                                      rtdgtreal_processor_state_d** plan);
 *
 * ltfat_rtdgtreal_processor_init_win_s(LTFAT_FIRWIN win, ltfat_int gl, ltfat_int a, ltfat_int M,
 *                                      ltfat_int Wmax, ltfat_int bufLenMax,
 *                                      rtdgtreal_processor_state_s** plan);
 * </tt>
 *
 * \returns
 * Status code           |  Description
 * ----------------------|----------------------
 * LTFATERR_SUCCESS      |  No error occured
 * LTFATERR_NULLPOINTER  |  \a plan was NULL.
 * LTFATERR_BADSIZE      |  \a gl was less or equal to 0
 * LTFATERR_NOTPOSARG    |  At least one of the following was less or equal to zero: \a a, \a M, \a Wmax
 * LTFATERR_CANNOTHAPPEN |  \a win was not valid value from the LTFAT_FIRWIN enum.
 * LTFATERR_NOMEM        |  Heap memory allocation failed
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_init_win)(LTFAT_FIRWIN win,
        ltfat_int gl, ltfat_int a, ltfat_int M,
        ltfat_int Wmax, ltfat_int bufLenMax, ltfat_int procDelay,
        LTFAT_NAME(rtdgtreal_processor_state)** plan);

/** Process samples
 *
 * Process multichannel input samples. Channels are stored as an array of
 * pointers to the actual data arrays.
 *
 * This function is mean to be called from the audio loop.
 *
 * Output is lagging behind the input by (gl-1) samples.
 * The function can run inplace i.e. in==out.
 *
 * \param[in]      p  DGTREAL processor
 * \param[in]     in  Input channels
 * \param[in]    len  Length of the channels
 * \param[in] chanNo  Number of channels
 * \param[out]   out  Output frame
 *
 * #### Function versions #
 * <tt>
 * ltfat_rtdgtreal_processor_execute_d(ltfat_rtdgtreal_processor_state_d* p, const double* in[],
 *                                     ltfat_int L, ltfat_int W, double* out[]);
 *
 * ltfat_rtdgtreal_processor_execute_s(ltfat_rtdgtreal_processor_state_d* p, const float* in[],
 *                                     ltfat_int L, ltfat_int W, float* out[]);
 * </tt>
 *
 * \returns
 * Status code           |  Description
 * ----------------------|----------------------
 * LTFATERR_SUCCESS      |  No error occured
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_execute)(LTFAT_NAME(rtdgtreal_processor_state)* p,
                                        const LTFAT_REAL* in[],
                                        ltfat_int L, ltfat_int W,
                                        LTFAT_REAL* out[]);

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_execute_gen)(
    LTFAT_NAME(rtdgtreal_processor_state)* p,
    const LTFAT_REAL** in, ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen,
    LTFAT_REAL** out);

/** Process samples
 *
 * Works exactly like rtdgtreal_processor_execute except that the multichannel
 * buffers are stored one after the other in the memory.
 *
 * \param[in]      p  DGTREAL processor
 * \param[in]     in  Input channels
 * \param[in]    len  Length of the channels
 * \param[in] chanNo  Number of channels
 * \param[out]   out  Output frame
 *
 * #### Function versions #
 * <tt>
 * ltfat_rtdgtreal_processor_execute_compact_d(ltfat_rtdgtreal_processor_state_d* p, const double in[],
 *                                             ltfat_int L, ltfat_int W, double out[]);
 *
 * ltfat_rtdgtreal_processor_execute_compact_s(ltfat_rtdgtreal_processor_state_d* p, const float in[],
 *                                             ltfat_int L, ltfat_int W, float out[]);
 * </tt>
 *
 * \returns
 * Status code           |  Description
 * ----------------------|----------------------
 * LTFATERR_SUCCESS      |  No error occured
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_execute_compact)(
    LTFAT_NAME(rtdgtreal_processor_state)* p,
    const LTFAT_REAL in[],
    ltfat_int len, ltfat_int chanNo,
    LTFAT_REAL out[]);

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_execute_gen_compact)(
    LTFAT_NAME(rtdgtreal_processor_state)* p, const LTFAT_REAL* in,
    ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen, LTFAT_REAL* out);


/** Destroy DGTREAL processor state
 * \param[in]  p      DGTREAL processor
 *
 * #### Function versions #
 * <tt>
 * ltfat_rtdgtreal_processor_done_d(ltfat_rtdgtreal_processor_state_d** plan);
 *
 * ltfat_rtdgtreal_processor_done_s(ltfat_rtdgtreal_processor_state_s** plan);
 * </tt>
 *
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | plan or *plan was NULL.
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_done)(LTFAT_NAME(rtdgtreal_processor_state)** plan);

/** Set DGTREAL processor callback
 *
 * Function replaces the callback in the struct. This is not thread safe.
 * Only call this if there is no chance that the execute function is called
 * simultaneously in a different thread.
 *
 * \param[in]            p   DGTREAL processor state
 * \param[in]     callback   Custom function to process the coefficients
 * \param[in]     userdata   Custom callback data. Will be passed to the callback.
 *                           Useful for storing state between callback calls.
 *
 * #### Function versions #
 * <tt>
 * ltfat_rtdgtreal_processor_setcallback_d(ltfat_rtdgtreal_processor_state_d* p,
 *                                         ltfat_rtdgtreal_processor_callback_d* callback,
 *                                         void* userdata);
 *
 * ltfat_rtdgtreal_processor_setcallback_s(ltfat_rtdgtreal_processor_state_s* p,
 *                                         ltfat_rtdgtreal_processor_callback_s* callback,
 *                                         void* userdata);
 * </tt>
 */
LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_setcallback)(LTFAT_NAME(rtdgtreal_processor_state)* p,
        LTFAT_NAME(rtdgtreal_processor_callback)* callback,
        void* userdata);

/** Default processor callback
 *
 * The callback just copies data from input to the output.
 *
 * It is used when no other processor callback is registered.
 *
 */
LTFAT_API void
LTFAT_NAME(default_rtdgtreal_processor_callback)(void* userdata, const LTFAT_COMPLEX in[],
        int M2, int W, LTFAT_COMPLEX out[]);

/** @}*/

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_setanaa)(LTFAT_NAME(rtdgtreal_processor_state)* p, ltfat_int a);

LTFAT_API int
LTFAT_NAME(rtdgtreal_processor_setsyna)(LTFAT_NAME(rtdgtreal_processor_state)* p, ltfat_int a);


int
LTFAT_NAME(rtdgtreal_execute_wrapper)(void* p,
                                      const LTFAT_REAL* f, ltfat_int W,
                                      LTFAT_COMPLEX* c);

int
LTFAT_NAME(rtidgtreal_execute_wrapper)(void* p,
                                       const LTFAT_COMPLEX* c, ltfat_int W,
                                       LTFAT_REAL* f);
