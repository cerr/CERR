/** \defgroup windows Gabor Windows
 * \addtogroup windows
 * @{
 *
 * \note Please note that the window format is slightly unusual i.e.
 * the (unique) peak of the window is at index [0] of the array and the 
 * left tail is circularly wrapped such that the ends of both tails 
 * meet in the middle of the array. 
 * fftshift() can be used to format the array to the usual format
 * with peak in the middle. 
 *
 */

#ifndef _LTFAT_CI_WINDOWS_H
#define _LTFAT_CI_WINDOWS_H

/**
 *Codes for finite support windows
 */
typedef enum
{
    LTFAT_HANN, LTFAT_HANNING=LTFAT_HANN, LTFAT_NUTTALL10=LTFAT_HANN,
    LTFAT_SQRTHANN, LTFAT_COSINE=LTFAT_SQRTHANN, LTFAT_SINE=LTFAT_SQRTHANN,
    LTFAT_HAMMING,
    LTFAT_NUTTALL01,
    LTFAT_SQUARE, LTFAT_RECT=LTFAT_SQUARE,
    LTFAT_TRIA, LTFAT_TRIANGULAR=LTFAT_TRIA, LTFAT_BARTLETT=LTFAT_TRIA,
    LTFAT_SQRTTRIA,
    LTFAT_BLACKMAN,
    LTFAT_BLACKMAN2,
    LTFAT_NUTTALL, LTFAT_NUTTALL12=LTFAT_NUTTALL,
    LTFAT_OGG, LTFAT_ITERSINE=LTFAT_OGG,
    LTFAT_NUTTALL20,
    LTFAT_NUTTALL11,
    LTFAT_NUTTALL02,
    LTFAT_NUTTALL30,
    LTFAT_NUTTALL21,
    LTFAT_NUTTALL03,
    LTFAT_TRUNCGAUSS01,
    LTFAT_TRUNCGAUSS005
} LTFAT_FIRWIN;

/** Convert lowercase string to a firwin enum
 *
 * E.g. "hann" returns LTFAT_HANN etc.
 *
 * \param[in]   win  Window type
 * \returns
 * LTFAT_FIRWIN integer or
 *
 * Status code           | Description
 * ----------------------|------------
 * LTFATERR_BADARG       | Unsupported string
 */
LTFAT_API int
ltfat_str2firwin(const char* name);

/** Get the array length for mtgauss()
 *
 * \param[in]     a   Time hop factor
 * \param[in]     M   Number of frequency channels
 * \param[in]   thr   Threshold ]0,1[ where to truncate
 * \returns ltfaterr_status
 */
LTFAT_API ltfat_int
ltfat_mtgausslength(ltfat_int a, ltfat_int M, double thr);
#endif /* _CI_WINDOWS_H */



/** Creates real, whole-point symmetric, zero delay window.
 *
 * \see normalize fftshift
 *
 * \param[in]   win  Window type
 * \param[in]   gl   Window length
 * \param[out]  g    Window
 *
 * #### Function versions #
 * <tt>
 * ltfat_firwin_d(LTFAT_FIRWIN win, ltfat_int gl, double* g);
 *
 * ltfat_firwin_s(LTFAT_FIRWIN win, ltfat_int gl, float* g);
 *
 * ltfat_firwin_dc(LTFAT_FIRWIN win, ltfat_int gl, ltfat_complex_d* g);
 *
 * ltfat_firwin_sc(LTFAT_FIRWIN win, ltfat_int gl, ltfat_complex_s* g);
 * </tt>
 * \returns
 * Status code           | Description
 * ----------------------|------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | The output array is NULL
 * LTFATERR_BADSIZE      | Length of the array is less or equal to 0.
 * LTFATERR_CANNOTHAPPEN | \a win is not a valid value from the LTFAT_FIRWIN enum
 */
LTFAT_API int
LTFAT_NAME(firwin)(LTFAT_FIRWIN win, ltfat_int gl, LTFAT_TYPE* g);

/** Truncated Gaussian window optimally matched to the lattice
 *
 * Computes peak-normalized Gaussian window scaled such that the time-
 * frequency support is circular with respect to the lattice given by parameters
 * \a a and \a M.
 *
 * \see normalize fftshift ltfat_mtgausslength
 *
 * \param[in]     a   Time hop factor
 * \param[in]     M   Number of frequency channels
 * \param[in]   thr   Threshold ]0,1[ where to truncate
 * \param[out]    g   Window. ltfat_mtgausslength
 *
 * #### Function versions #
 * <tt>
 * ltfat_mtgauss_d(ltfat_int a, ltfat_int M, double thr, double g[]);
 *
 * ltfat_mtgauss_s(ltfat_int a, ltfat_int M, double thr, float g[]);
 *
 * ltfat_mtgauss_dc(ltfat_int a, ltfat_int M, double thr, ltfat_complex_d g[]);
 *
 * ltfat_mtgauss_ds(ltfat_int a, ltfat_int M, double thr, ltfat_complex_s g[]);
 * </tt>
 * \returns ltfaterr_status
 */
LTFAT_API int
LTFAT_NAME(mtgauss)(ltfat_int a, ltfat_int M, double thr, LTFAT_TYPE* g);

/** @} */
