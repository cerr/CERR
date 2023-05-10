/* \defgroup block_processor Block Stream Processor
 *
 * A simple data stream blocking interface employing a pair of circular buffers.
 * It is intended for block-wise processing of audio streams or long audio files.
 * The blocks might be overlapping.
 *
 * The processor will invoke the registered callback function every \a hop
 * samples and will provide a block of samples of length \a winLen.
 *
 * The output data stream is delayed by \a procDelay samples behind the input stream.
 *
 * Optionally, the blocks can be weighted by pre- and post- windows.
 */
#ifndef _LTFAT_CIRCULARBUF_H
#define _LTFAT_CIRCULARBUF_H


#endif

typedef struct LTFAT_NAME(analysis_fifo_state) LTFAT_NAME(analysis_fifo_state);
typedef struct LTFAT_NAME(synthesis_fifo_state) LTFAT_NAME(synthesis_fifo_state);
typedef struct LTFAT_NAME(block_processor_state) LTFAT_NAME(block_processor_state);

int LTFAT_NAME(default_block_processor_callback)(void* userdata,
        const LTFAT_REAL in[], int winLen, int W, LTFAT_REAL out[]);

/* \addtogroup block_processor
 * @{
 */

/** Block processor callback template
 */
typedef int LTFAT_NAME(block_processor_callback)(void* userdata,
        const LTFAT_REAL in[], int winLen, int W, LTFAT_REAL out[]);

/** \name Basic interface
 * 
* @{
*/
LTFAT_API int
LTFAT_NAME(block_processor_init)(
    ltfat_int winLen, ltfat_int hop, ltfat_int numChans,
    ltfat_int bufLenMax, ltfat_int procDelay,
    LTFAT_NAME(block_processor_state)** p);

LTFAT_API int
LTFAT_NAME(block_processor_execute)(
        LTFAT_NAME(block_processor_state)* p,
        const LTFAT_REAL** in, ltfat_int inLen, ltfat_int chanNo,
        ltfat_int outLen, LTFAT_REAL** out);

LTFAT_API int
LTFAT_NAME(block_processor_done)( LTFAT_NAME(block_processor_state)** p);

LTFAT_API int
LTFAT_NAME(block_processor_reset)( LTFAT_NAME(block_processor_state)* p);

LTFAT_API int
LTFAT_NAME(block_processor_setcallback)(
        LTFAT_NAME(block_processor_state)* p,
        LTFAT_NAME(block_processor_callback)* callback, void* userdata);
/** @} */

/** \name Extended interface
* @{
*/
LTFAT_API int
LTFAT_NAME(block_processor_init_withbuffers)(
    ltfat_int winLen, ltfat_int hop, ltfat_int numChans,
    ltfat_int bufLenMax, ltfat_int procDelay,
    LTFAT_REAL* prebuf, LTFAT_REAL* postbuf,
    LTFAT_NAME(block_processor_state)** p);

LTFAT_API int
LTFAT_NAME(block_processor_execute_compact)(
    LTFAT_NAME(block_processor_state)* p,
    const LTFAT_REAL* in, ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen,
    LTFAT_REAL* out);
/** @} */

/** \name Advanced interface
* @{
*/
LTFAT_API int
LTFAT_NAME(block_processor_setprebufchanstride)(
    LTFAT_NAME(block_processor_state)* p, ltfat_int stride);

LTFAT_API int
LTFAT_NAME(block_processor_setpostbufchanstride)(
    LTFAT_NAME(block_processor_state)* p, ltfat_int stride);

LTFAT_API size_t
LTFAT_NAME(block_processor_nextinlen)(LTFAT_NAME(block_processor_state)* state, size_t Lout);

LTFAT_API size_t
LTFAT_NAME(block_processor_nextoutlen)(LTFAT_NAME(block_processor_state)* state, size_t Lin);


LTFAT_API int
LTFAT_NAME(block_processor_setprehop)(
        LTFAT_NAME(block_processor_state)* p, ltfat_int hop);

LTFAT_API int
LTFAT_NAME(block_processor_setposthop)(
        LTFAT_NAME(block_processor_state)* p, ltfat_int hop);

LTFAT_API int
LTFAT_NAME(block_processor_setwin)(
        LTFAT_NAME(block_processor_state)* p, LTFAT_REAL g[], int do_prewin);

LTFAT_API int
LTFAT_NAME(block_processor_setfirwin)(
        LTFAT_NAME(block_processor_state)* p, LTFAT_FIRWIN win, int do_prewin);
/** @} */
/** @} */

void
LTFAT_NAME(block_processor_advanceby)(
        LTFAT_NAME(block_processor_state)* p,
        size_t Lin, size_t Lout);

/** Create constant size output ring buffer
 *
 * The ring buffer works as usual when written to, but only constant
 * size (winLen) chunks can be read from it and the read pointer is
 * only advanced by hop after read.
 *
 * The buffer read and write pointers are initialized such that they
 * reflect the processing delay.
 *
 * \param[in]  fifoLen  Ring buffer size. This should be at least winLen + max. expected
 *                      buffer length.
 *                      One more slot is actually allocated for the "one slot open" implementation.
 * \param[in]  winLen   Window length
 * \param[in]  hop      Hop factor
 * \param[in]  numChans Maximum number of channels
 *
 * \returns RTDGTREAL_FIFO struct pointer
 */
LTFAT_API int
LTFAT_NAME(analysis_fifo_init)(ltfat_int fifoLen, ltfat_int procDelay, ltfat_int winLen, ltfat_int hop,
                               ltfat_int numChans, LTFAT_NAME(analysis_fifo_state)** p);

LTFAT_API int
LTFAT_NAME(analysis_fifo_reset)(LTFAT_NAME(analysis_fifo_state)* p);

LTFAT_API int
LTFAT_NAME(analysis_fifo_sethop)(LTFAT_NAME(analysis_fifo_state)* p, ltfat_int hop);

LTFAT_API int
LTFAT_NAME(analysis_fifo_setreadchanstride)(LTFAT_NAME(analysis_fifo_state)* p,
        ltfat_int stride);

/** Write bufLen samples to the analysis ring buffer
 *
 * The function returns number of samples written and a negative number if something went
 * wrong.
 * If there is not enough space for all bufLen samples, only available space is used
 * and the number of actually written samples is returned.
 *
 * \param[in]  p        Analysis ring buffer struct
 * \param[in]  buf      Channels to be written.
 * \param[in]  bufLen   Number of samples to be written
 * \param[in]  W        Number of channels
 *
 * \returns Number of samples written
 */
LTFAT_API ltfat_int
LTFAT_NAME(analysis_fifo_write)(LTFAT_NAME(analysis_fifo_state)* p, const LTFAT_REAL* buf[],
                                ltfat_int bufLen, ltfat_int W);

/** Read p->winLen samples from the analysis ring buffer
 *
 * The function attempts to read p->winLen samples from the buffer.
 *
 * The function does mothing and returns 0 if there is less than p->winLen samples available.
 *
 * \param[in]   p        Analysis ring buffer struct
 * \param[out]  buf      Output array, it is expected to be able to hold p->winLen*p->numChans samples.
 *
 * \returns Number of samples read
 */
LTFAT_API ltfat_int
LTFAT_NAME(analysis_fifo_read)(LTFAT_NAME(analysis_fifo_state)* p, LTFAT_REAL buf[]);

/** Destroy DGT analysis ring buffer
 * \param[in]  p      DGT analysis ring buffer
 */
LTFAT_API int
LTFAT_NAME(analysis_fifo_done)(LTFAT_NAME(analysis_fifo_state)** p);

/** Create constant size input ring buffer
 *
 * The ring buffer behaves as usual when read from, except it sets the read
 * samples to zero.
 * Only chunks of size winLen can be written to it and the write pointer is advanced
 * by hop. The samples are added to the existing values instead of the usual
 * overwrite.
 *
 * The buffer read and write pointers are both initialized to the same value.
 *
 * \param[in]  fifoLen  Ring buffer size. This should be at least winLen + max. expected
 *                      buffer length. (winLen+1) more slots are actually allocated
 *                      to accomodate the overlaps.
 * \param[in]  winLen       Window length
 * \param[in]  hop        Hop factor
 * \param[in]  numChans     Maximum number of channels
 *
 * \returns RTIDGTREAL_FIFO struct pointer
 */
LTFAT_API int
LTFAT_NAME(synthesis_fifo_init)(ltfat_int fifoLen, ltfat_int winLen,
                                ltfat_int hop, ltfat_int numChans,
                                LTFAT_NAME(synthesis_fifo_state)** p);

LTFAT_API int
LTFAT_NAME(synthesis_fifo_reset)(LTFAT_NAME(synthesis_fifo_state)* p);

LTFAT_API int
LTFAT_NAME(synthesis_fifo_sethop)(LTFAT_NAME(synthesis_fifo_state)* p, ltfat_int hop);

LTFAT_API int
LTFAT_NAME(synthesis_fifo_setwritechanstride)(LTFAT_NAME(synthesis_fifo_state)* p,
        ltfat_int stride);

/** Write p->winLen samples to DGT synthesis ring buffer
 *
 * The function returns 0 if there is not enough space to write all
 * p->winLen samples.
 *
 * \param[in]  p        Synthesis ring buffer struct
 * \param[in]  buf      Samples to be written
 *
 * \returns Number of samples written
 */
LTFAT_API ltfat_int
LTFAT_NAME(synthesis_fifo_write)(LTFAT_NAME(synthesis_fifo_state)* p,
                                 const LTFAT_REAL buf[]);

/** Read bufLen samples from DGT analysis ring buffer
 *
 * The function attempts to read bufLen samples from the buffer.
 *
 * \param[in]   p        Analysis ring buffer struct
 * \param[in]   bufLen   Number of samples to be read
 * \param[in]   W        Number of channels
 * \param[out]  buf      Output channels, each channel is expected to be able to
 *                       hold bufLen samples.
 *
 * \returns Number of samples read
 */
LTFAT_API ltfat_int
LTFAT_NAME(synthesis_fifo_read)(LTFAT_NAME(synthesis_fifo_state)* p,
                                ltfat_int bufLen, ltfat_int W,
                                LTFAT_REAL* buf[]);

/** Destroy DGT synthesis ring buffer
 * \param[in]  p      DGT synthesis ring buffer
 */
LTFAT_API int
LTFAT_NAME(synthesis_fifo_done)(LTFAT_NAME(synthesis_fifo_state)** p);

