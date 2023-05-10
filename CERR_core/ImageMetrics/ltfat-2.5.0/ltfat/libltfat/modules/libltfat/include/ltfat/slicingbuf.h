/* \defgroup slicing_processor Slicing Window Stream Processor
 */
#ifndef _LTFAT_SLICINGBUF_H
#define _LTFAT_SLICINGBUF_H


#endif

typedef struct LTFAT_NAME(slicing_processor_state) LTFAT_NAME(slicing_processor_state);

LTFAT_API int
LTFAT_NAME(default_slicing_processor_callback)(void* userdata,
        const LTFAT_REAL in[], int winLen, int taperLen, int zpadLen, int W, LTFAT_REAL out[]);

/* \addtogroup slicing_processor
 * @{
 */
typedef int LTFAT_NAME(slicing_processor_callback)(void* userdata,
        const LTFAT_REAL in[], int winLen, int taperLen, int zpadLen, int W, LTFAT_REAL out[]);

/** \name Basic interface
 * @{ 
 * */
LTFAT_API int
LTFAT_NAME(slicing_processor_init)( ltfat_int winLen, ltfat_int taperLen, ltfat_int zpadLen,
                                    ltfat_int numChans, ltfat_int bufLenMax,
                                    LTFAT_NAME(slicing_processor_state)** pout);

LTFAT_API int
LTFAT_NAME(slicing_processor_execute)(
    LTFAT_NAME(slicing_processor_state)* p,
    const LTFAT_REAL** in, ltfat_int inLen, ltfat_int chanNo, LTFAT_REAL** out);

LTFAT_API int
LTFAT_NAME(slicing_processor_done)(LTFAT_NAME(slicing_processor_state)** p);

LTFAT_API int
LTFAT_NAME(slicing_processor_reset)(LTFAT_NAME(slicing_processor_state)* p);

LTFAT_API int
LTFAT_NAME(slicing_processor_setcallback)(
        LTFAT_NAME(slicing_processor_state)* p,
        LTFAT_NAME(slicing_processor_callback)* callback, void* userdata);
/** @} */

/** \name Advanced interface
 * @{ 
 * */
LTFAT_API ltfat_int
LTFAT_NAME(slicing_processor_getprocdelay)( LTFAT_NAME(slicing_processor_state)* p);

LTFAT_API int
LTFAT_NAME(slicing_processor_execute_gen)(
    LTFAT_NAME(slicing_processor_state)* p,
    const LTFAT_REAL** in, ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen,
    LTFAT_REAL** out);

LTFAT_API int
LTFAT_NAME(slicing_processor_execute_compact)(
    LTFAT_NAME(slicing_processor_state)* p,
    const LTFAT_REAL* in, ltfat_int inLen, ltfat_int chanNo, LTFAT_REAL* out);

LTFAT_API int
LTFAT_NAME(slicing_processor_execute_gen_compact)(
    LTFAT_NAME(slicing_processor_state)* p,
    const LTFAT_REAL* in, ltfat_int inLen, ltfat_int chanNo, ltfat_int outLen,
    LTFAT_REAL* out);

/** \name Setup interface
 * @{ 
 * */


LTFAT_API int
LTFAT_NAME(slicing_processor_settaperwin)(
    LTFAT_NAME(slicing_processor_state)* p, LTFAT_FIRWIN g, int do_analysis);

LTFAT_API int
LTFAT_NAME(slicing_processor_settaper)(
    LTFAT_NAME(slicing_processor_state)* p, const LTFAT_REAL g[], int do_analysis);
/** @} */
/** @} */

int
LTFAT_NAME(slicing_processor_execute_callback)(void* userdata,
        const LTFAT_REAL in[], int winLen, int W, LTFAT_REAL out[]);


