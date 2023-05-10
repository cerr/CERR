/** \addtogroup utils
 * @{
 * Utility functions
 *
 * \note All utility functions working with arrays can work inplace (i.e. in == out) without
 * allocating additional memory internally.
 */

#ifndef _ltfat_ciutils_h
#define _ltfat_ciutils_h

typedef enum
{
    /** Don't normalize */
    LTFAT_NORM_NULL = 0,
    /**  1 norm (divide by the sum of abs. values)  */
    /**@{*/
    LTFAT_NORM_AREA,
    LTFAT_NORM_1 = LTFAT_NORM_AREA,
    /**@}*/
    /**  2 norm (divide by the square root of sum of squares of abs. values) */
    /**@{*/
    LTFAT_NORM_ENERGY,
    LTFAT_NORM_2 = LTFAT_NORM_ENERGY,
    /**@}*/
    /**  inf norm (divide by the max abs. val.)*/
    /**@{*/
    LTFAT_NORM_INF,
    LTFAT_NORM_PEAK = LTFAT_NORM_INF,
    /**@}*/
    // LTFAT_NORM_RMS,
    // LTFAT_NORM_WAV,
} ltfat_norm_t;


typedef enum
{
    LTFAT_WHOLEPOINT = 0,
    LTFAT_HALFPOINT

} ltfat_symmetry_t;

#endif

/** Shift array circularly
 *
 *  Works exactly like
 *  <a href="http://de.mathworks.com/help/matlab/ref/circshift.html">circshift</a>
 *  from Matlab.
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[in]  shift  Shift amount (can be negative)
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_circshift_d(const double in[], ltfat_int L,ltfat_int shift, double out[]);
 *
 *  ltfat_circshift_s(const float in[], ltfat_int L,ltfat_int shift, float out[]);
 *
 *  ltfat_circshift_dc(const ltfat_complex_d in[], ltfat_int L,ltfat_int shift, ltfat_complex_d out[]);
 *
 *  ltfat_circshift_sc(const ltfat_complex_s in[], ltfat_int L,ltfat_int shift, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME(circshift)(const LTFAT_TYPE in[], ltfat_int L,
                      ltfat_int shift, LTFAT_TYPE out[]);

/** Shift columns of a matrix circularly
 *
 *  Works like circshift but with entire cols.
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of cols
 * \param[in]      W  Number of cols
 * \param[in]  shift  Shift amount (can be negative)
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_circshiftcols_d(const double in[], ltfat_int L, ltfat_int W, ltfat_int shift, double out[]);
 *
 *  ltfat_circshiftcols_s(const float in[], ltfat_int L, ltfat_int W, ltfat_int shift, float out[]);
 *
 *  ltfat_circshiftcols_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_int W, ltfat_int shift, ltfat_complex_d out[]);
 *
 *  ltfat_circshiftcols_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_int W, ltfat_int shift, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME(circshiftcols)(const LTFAT_TYPE in[], ltfat_int L, ltfat_int W,
                          ltfat_int shift, LTFAT_TYPE out[]);

/** 2D circshift
 *
 *  Works exactly like
 *  <a href="http://de.mathworks.com/help/matlab/ref/circshift.html">circshift</a>
 *  from Matlab for matrices.
 *
 * \param[in]             in  Input array
 * \param[in]              H  Number of rows
 * \param[in]              W  Number of columns
 * \param[in]      shift_row  Shift amount (can be negative)
 * \param[in]      shift_col  Shift amount (can be negative)
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_circshift2_d(const double in[], ltfat_int H, ltfat_int W, ltfat_int shift_row, ltfat_int shift_col, double out[]);
 *
 *  ltfat_circshift2_s(const float in[], ltfat_int H, ltfat_int W, ltfat_int shift_row, ltfat_int shift_col, float out[]);
 *
 *  ltfat_circshift2_dc(const ltfat_complex_d in[], ltfat_int H, ltfat_int W, ltfat_int shift_row, ltfat_int shift_col, ltfat_complex_d out[]);
 *
 *  ltfat_circshift2_sc(const ltfat_complex_s in[], ltfat_int H, ltfat_int W, ltfat_int shift_row, ltfat_int shift_col, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME(circshift2)(const LTFAT_TYPE in[], ltfat_int H, ltfat_int W,
                       ltfat_int shift_row, ltfat_int shift_col, LTFAT_TYPE out[]);

/** fftshift an array
 *
 *  Works exactly like
 *  <a href="http://de.mathworks.com/help/matlab/ref/fftshift.html">fftshift</a>
 *  form Matlab for vectors.
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_fftshift_d(const double in[], ltfat_int L, double out[]);
 *
 *  ltfat_fftshift_s(const float in[], ltfat_int L, float out[]);
 *
 *  ltfat_fftshift_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_complex_d out[]);
 *
 *  ltfat_fftshift_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME(fftshift)(const LTFAT_TYPE in[], ltfat_int L, LTFAT_TYPE out[]);

/** ifftshift an array
 *
 *  Works exactly like
 *  <a href="http://de.mathworks.com/help/matlab/ref/ifftshift.html">ifftshift</a>
 *  form Matlab for vectors. Undoes the action of fftshift
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_ifftshift_d(const double in[], ltfat_int L, double out[]);
 *
 *  ltfat_ifftshift_s(const float in[], ltfat_int L, float out[]);
 *
 *  ltfat_ifftshift_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_complex_d out[]);
 *
 *  ltfat_ifftshift_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME(ifftshift)(const LTFAT_TYPE in[], ltfat_int L, LTFAT_TYPE out[]);

/** Change signal length by inserting zeros in the middle
 *
 *  Works exactly like
 *  <a href="http://ltfat.github.io/doc/fourier/middlepad.html">middlepad</a>
 *  form LTFAT i.e. extends \a in by inserting zeros in the middle or
 *  removes the middle part such that the output is \a Lout.
 *
 *
 * \param[in]     in  Input array
 * \param[in]    Lin  Length of input array
 * \param[in]    sym  Which symmetry to preserve
 * \param[in]   Lout  Length of output array
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_middlepad_d(const double in[], ltfat_int Lin, ltfat_symmetry_t sym, ltfat_int Lout, double out[]);
 *
 *  ltfat_middlepad_s(const float in[], ltfat_int Lin, ltfat_symmetry_t sym, ltfat_int Lout, float out[]);
 *
 *  ltfat_middlepad_dc(const ltfat_complex_d in[], ltfat_int Lin, ltfat_symmetry_t sym, ltfat_int Lout, ltfat_complex_d out[]);
 *
 *  ltfat_middlepad_sc(const ltfat_complex_s in[], ltfat_int Lin, ltfat_symmetry_t sym, ltfat_int Lout, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 * LTFATERR_BADREQSIZE   | Output array is shorter than the input array: \a Llong < \a Lfir
 */
LTFAT_API int
LTFAT_NAME(middlepad)(const LTFAT_TYPE* in, ltfat_int Lin, ltfat_symmetry_t sym,
                      ltfat_int Lout, LTFAT_TYPE* out);


/** Change signal length by repeating in[0] from both ends
 *
 * Intended to be used on windows e.g. from firwin
 *
 * \param[in]     in  Input array
 * \param[in]    Lin  Length of input array
 * \param[in]   Lout  Length of output array
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_peakpad_d(const double in[], ltfat_int Lin, ltfat_int Lout, double out[]);
 *
 *  ltfat_peakpad_s(const float in[], ltfat_int Lin, ltfat_int Lout, float out[]);
 *
 *  ltfat_peakpad_dc(const ltfat_complex_d in[], ltfat_int Lin, ltfat_int Lout, ltfat_complex_d out[]);
 *
 *  ltfat_peakpad_sc(const ltfat_complex_s in[], ltfat_int Lin, ltfat_int Lout, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 * LTFATERR_BADREQSIZE   | Output array is shorter than the input array: \a Llong < \a Lfir
 */
LTFAT_API int
LTFAT_NAME(peakpad)(const LTFAT_TYPE* in, ltfat_int Lin, ltfat_int Lout, LTFAT_TYPE* out);

// LTFAT_API int
// LTFAT_NAME(middlepadcols)(const LTFAT_TYPE* in, ltfat_int Hin, ltfat_int Win, ltfat_symmetry_t sym,
//                           ltfat_int Wout, LTFAT_TYPE* out);
//
//
// LTFAT_API int
// LTFAT_NAME(middlepad2d)(const LTFAT_TYPE* in, ltfat_int Hin, ltfat_int Win, ltfat_symmetry_t sym,
//                         ltfat_int Hout, ltfat_int Wout, LTFAT_TYPE* out);


/** Extend FIR window to long window
 *
 *  Works exactly like
 *  <a href="http://ltfat.github.io/doc/sigproc/fir2long.html">fir2long</a>
 *  form LTFAT i.e. extends \a in by inserting zeros in the middle.
 *  \a Llong must be greater or equal to \a Lfir.
 *
 * \param[in]     in  Input array
 * \param[in]   Lfir  Length of input array
 * \param[in]  Llong  Length of output array
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_fir2long_d(const double in[], ltfat_int Lfir, ltfat_int Llong, double out[]);
 *
 *  ltfat_fir2long_s(const float in[], ltfat_int Lfir, ltfat_int Llong, float out[]);
 *
 *  ltfat_fir2long_dc(const ltfat_complex_d in[], ltfat_int Lfir, ltfat_int Llong, ltfat_complex_d out[]);
 *
 *  ltfat_fir2long_sc(const ltfat_complex_s in[], ltfat_int Lfir, ltfat_int Llong, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 * LTFATERR_BADREQSIZE   | Output array is shorter than the input array: \a Llong < \a Lfir
 */
LTFAT_API int
LTFAT_NAME(fir2long)(const LTFAT_TYPE in[], ltfat_int Lfir, ltfat_int Llong,
                     LTFAT_TYPE out[]);

/** Cut long window to a FIR window
 *
 *  Works exactly like
 *  <a href="http://ltfat.github.io/doc/sigproc/long2fir.html">long2fir</a>
 *  form LTFAT i.e. it removes the middle part.
 *  Llong must be greater or equal to Lfir.
 *
 * \param[in]     in  Input array
 * \param[in]  Llong  Length of input array
 * \param[in]   Lfir  Length of output array
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_long2fir_d(const double in[], ltfat_int Llong, ltfat_int Lfir, double out[]);
 *
 *  ltfat_long2fir_s(const float in[], ltfat_int Llong, ltfat_int Lfir, float out[]);
 *
 *  ltfat_long2fir_dc(const ltfat_complex_d in[], ltfat_int Llong, ltfat_int Lfir, ltfat_complex_d out[]);
 *
 *  ltfat_long2fir_sc(const ltfat_complex_s in[], ltfat_int Llong, ltfat_int Lfir, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 * LTFATERR_BADREQSIZE   | Output array is longer than the input array: \a Lfir > \a Llong
 */
LTFAT_API int
LTFAT_NAME(long2fir)(const LTFAT_TYPE in[], ltfat_int Llong, ltfat_int Lfir,
                     LTFAT_TYPE out[]);


/** Compute norm of a vector
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of input array
 * \param[in]   flag  Norm
 * \param[out]   out  Computed norm
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_norm_d(const double in[], ltfat_int L, ltfat_norm_t flag, double* out);
 *
 *  ltfat_norm_s(const float in[], ltfat_int L, ltfat_norm_t flag flag, float* out);
 *
 *  ltfat_norm_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_norm_t flag, double* out);
 *
 *  ltfat_norm_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_norm_t flag, float* out);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either in or norm is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 * LTFATERR_CANNOTHAPPEN | Wrong ltfat_norm_t flag
 */
LTFAT_API int
LTFAT_NAME(norm)(const LTFAT_TYPE* in, ltfat_int L,
                 ltfat_norm_t flag, LTFAT_REAL* norm);

/** Compute normalized signal-to-noise
 *
 * Such that snr=20*log10(norm(rec,2)/norm(in,2))
 *
 * \param[in]     in  Input array
 * \param[in]    rec  Reconstructed array
 * \param[in]      L  Length of the arrays
 * \param[out]   snr  Computed snr
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_snr_d(const double in[], const double rec[], ltfat_int L, double* out);
 *
 *  ltfat_snr_s(const float in[], const float rec[], ltfat_int L, float* out);
 *
 *  ltfat_snr_dc(const ltfat_complex_d in[], const ltfat_complex_d rec[], ltfat_int L, double* out);
 *
 *  ltfat_snr_sc(const ltfat_complex_s in[], const ltfat_complex_s rec[], ltfat_int L, float* out);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either in, rec or snr is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 */

LTFAT_API int
LTFAT_NAME(snr)(const LTFAT_TYPE* in, const LTFAT_TYPE* rec,
                ltfat_int L, LTFAT_REAL* snr);

/** Normalize a vector
 *
 * Normalizes the input array such that the chosen norm is 1.
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of the arrays
 * \param[in]   flag  Norm
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_normalize_d(const double in[], ltfat_int L, ltfat_norm_t flag, double out[]);
 *
 *  ltfat_normalize_s(const float in[], ltfat_int L, ltfat_norm_t flag, float out[]);
 *
 *  ltfat_normalize_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_norm_t flag, ltfat_complex_d out[]);
 *
 *  ltfat_normalize_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_norm_t flag, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 * LTFATERR_CANNOTHAPPEN | \a flag is not defined in ltfat_norm_t enum.
 */
LTFAT_API int
LTFAT_NAME(normalize)(const LTFAT_TYPE in[], ltfat_int L,
                      ltfat_norm_t flag, LTFAT_TYPE out[]);

/** Ensure the array has complex interleaved layout
 *
 * This is a convenience function.
 * Obviously the *_dc and *_sc versions of the function do nothing.
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[out]   out  Output array
 *
 * #### Function versions ####
 * <tt>
 * ltfat_ensurecomplex_array_d(const double in[], ltfat_int L, ltfat_complex_d out[]);
 *
 * ltfat_ensurecomplex_array_s(const float in[], ltfat_int L, ltfat_complex_s out[]);
 *
 * ltfat_ensurecomplex_array_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_complex_d out[]);
 *
 * ltfat_ensurecomplex_array_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_complex_s out[]);
 * </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME(ensurecomplex_array)(const LTFAT_TYPE *in, ltfat_int L, LTFAT_COMPLEX *out);

/** @}*/

LTFAT_API void
LTFAT_NAME(dgtphaselockhelper)(LTFAT_TYPE *cin, ltfat_int L,
                               ltfat_int W, ltfat_int a,
                               ltfat_int M, ltfat_int M2,
                               LTFAT_TYPE *cout);

LTFAT_API void
LTFAT_NAME(dgtphaseunlockhelper)(LTFAT_TYPE *cin, ltfat_int L,
                                 ltfat_int W, ltfat_int a,
                                 ltfat_int M, ltfat_int M2,
                                 LTFAT_TYPE *cout);

LTFAT_API int
LTFAT_NAME(reverse_array)(const LTFAT_TYPE *in, ltfat_int L, LTFAT_TYPE *out);

LTFAT_API int
LTFAT_NAME(conjugate_array)(const LTFAT_TYPE *in, ltfat_int L, LTFAT_TYPE *out);

LTFAT_API int
LTFAT_NAME(periodize_array)(const LTFAT_TYPE *in, ltfat_int Lin,
                            ltfat_int Lout, LTFAT_TYPE *out );

LTFAT_API int
LTFAT_NAME(fold_array)(const LTFAT_TYPE *in, ltfat_int Lin,
                       ltfat_int offset,
                       ltfat_int Lfold, LTFAT_TYPE *out);

LTFAT_API int
LTFAT_NAME(clear_array)(LTFAT_TYPE *in, ltfat_int L);

LTFAT_API int
LTFAT_NAME(log_array)(const LTFAT_TYPE in[], ltfat_int L, LTFAT_TYPE out[]);


LTFAT_API int
LTFAT_NAME(reflect)(const LTFAT_TYPE* in, ltfat_int L, LTFAT_TYPE* out);

LTFAT_API int
LTFAT_NAME(involute)(const LTFAT_TYPE* in, ltfat_int L, LTFAT_TYPE* out);

LTFAT_API void
LTFAT_NAME(findmaxinarray)(const LTFAT_TYPE *in, ltfat_int L, LTFAT_TYPE* max, ltfat_int* idx);

LTFAT_API int
LTFAT_NAME(findmaxinarraywrtmask)(const LTFAT_TYPE *in, const int *mask,
                                  ltfat_int L, LTFAT_TYPE* max, ltfat_int* idx);

LTFAT_API void
LTFAT_NAME(findmaxincols)(const LTFAT_TYPE* in, ltfat_int M, ltfat_int M2,
                          ltfat_int N, LTFAT_TYPE* max, ltfat_int* idx);
