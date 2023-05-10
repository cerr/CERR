
/** \addtogroup utils
 * @{
 */

/** Circshift in the Fourier domain via modulation
 *
 * The function modulates the Fourier coefficients which correcponds to the circular
 * shift in the time-domain.
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[in]  shift  Shift amount (can be non-integer)
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_fftcircshift_dc(const ltfat_complex_d in[], ltfat_int L,const double shift, ltfat_complex_d out[]);
 *
 *  ltfat_fftcircshift_sc(const ltfat_complex_s in[], ltfat_int L,const double shift, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE         | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(fftcircshift)(const LTFAT_COMPLEX in[], ltfat_int L, const double shift,
                                 LTFAT_COMPLEX out[]);

/** fftshift in the Fourier domain via modulation
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_fftfftshift_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_complex_d out[]);
 *
 *  ltfat_fftfftshift_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE         | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(fftfftshift)(const LTFAT_COMPLEX in[], ltfat_int L, LTFAT_COMPLEX out[]);

/** ifftshift in the Fourier domain via modulation
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_fftifftshift_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_complex_d out[]);
 *
 *  ltfat_fftifftshift_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE         | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(fftifftshift)(const LTFAT_COMPLEX in[], ltfat_int L, LTFAT_COMPLEX out[]);

/** circshift in the Fourier domain (fftreal) via modulation
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[in]  shift  Shift amount (can be non-integer)
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_fftrealcircshift_dc(const ltfat_complex_d in[], ltfat_int L,const double shift, ltfat_complex_d out[]);
 *
 *  ltfat_fftrealcircshift_sc(const ltfat_complex_s in[], ltfat_int L,const double shift, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE         | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(fftrealcircshift)( const LTFAT_COMPLEX in[], ltfat_int L, const double shift,
                                      LTFAT_COMPLEX out[]);

/** fftshift in the Fourier domain (fftreal) via modulation
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_fftrealfftshift_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_complex_d out[]);
 *
 *  ltfat_fftrealfftshift_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE         | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(fftrealfftshift)(const LTFAT_COMPLEX in[], ltfat_int L, LTFAT_COMPLEX out[]);

/** ifftshift in the Fourier domain (fftreal) via modulation
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_fftrealifftshift_dc(const ltfat_complex_d in[], ltfat_int L, ltfat_complex_d out[]);
 *
 *  ltfat_fftrealifftshift_sc(const ltfat_complex_s in[], ltfat_int L, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE         | Length of the arrays is less or equal to 0.
 */

LTFAT_API int
LTFAT_NAME_COMPLEX(fftrealifftshift)(const LTFAT_COMPLEX in[], ltfat_int L, LTFAT_COMPLEX out[]);


/** Real to complex array
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltfat_real2complex_array_dc(const double in[], ltfat_int L, ltfat_complex_d out[]);
 *
 *  ltfat_real2complex_array_sc(const float in[], ltfat_int L, ltfat_complex_s out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE         | Length of the arrays is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME(real2complex_array)(const LTFAT_REAL in[], ltfat_int L, LTFAT_COMPLEX out[]);

/** Complex to real array
 *
 * \param[in]     in  Input array
 * \param[in]      L  Length of arrays
 * \param[out]   out  Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltaft_complex2real_array_d(const ltfat_complex_d in[], ltfat_int L, double out[]);
 *
 *  ltfat_complex2real_array_s(const ltfat_complex_s in[], ltfat_int L, float out[]);
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
LTFAT_NAME(complex2real_array)(const LTFAT_COMPLEX in[], ltfat_int L, LTFAT_REAL out[]);

/** Convert coefficients from the dgtreal format to the dgt format
 * 
 * \param[in]     cdgtreal  Input array
 * \param[in]           M   Number of channels 
 * \param[in]           N   Number of time shifts
 * \param[out]       cdgt   Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltaft_dgtreal2dgt_d(const ltfat_complex_d in[], ltfat_int M, ltfat_int N, double out[]);
 *
 *  ltfat_dgtreal2dgt_s(const ltfat_complex_s in[], ltfat_int M, ltfat_int N, float out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less than 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(dgtreal2dgt)(const LTFAT_COMPLEX* cdgtreal, ltfat_int M,
                                ltfat_int N, LTFAT_COMPLEX* cdgt);

/** Convert coefficients from the dgt format to the dgtreal format
 *
 * Note this will discard the frequency channels beyond Nyquist channel M/2+1
 * 
 * \param[in]        cdgt   Input array
 * \param[in]           M   Number of channels 
 * \param[in]           N   Number of time shifts
 * \param[out]   cdgtreal   Output array
 *
 *  #### Function versions ####
 *  <tt>
 *  ltaft_dgt2dgtreal_d(const ltfat_complex_d in[], ltfat_int M, ltfat_int N, double out[]);
 *
 *  ltfat_dgt2dgtreal_s(const ltfat_complex_s in[], ltfat_int M, ltfat_int N, float out[]);
 *  </tt>
 *
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_BADSIZE      | Length of the arrays is less than 0.
 */

LTFAT_API int
LTFAT_NAME_COMPLEX(dgt2dgtreal)(const LTFAT_COMPLEX* cdgt, ltfat_int M,
                                ltfat_int N, LTFAT_COMPLEX* cdgtreal);


/** Change dgt phase convention from freq. invariant to time invariant
 *
 * N = L/a
 *
 * \param[in]  cFreqinv   Input coefficients, size M x N x W
 * \param[in]  L          Length of the signal
 * \param[in]  W          Number of signal channels
 * \param[in]  a          Time hop factor
 * \param[in]  M          Number of frequency channels
 * \param[out] cTimeinv   Output coefficients, size M x N x W
 *
 * #### Versions #
 * <tt>
 * dgt_phaselock_dc(const ltfat_complex_d cFreqinv[], ltfat_int L, ltfat_int W,
 *                  ltfat_int a, ltfat_int M, ltfat_complex_d cTimeinv[]);
 *
 * dgt_phaselock_sc(const ltfat_complex_s cFreqinv[], ltfat_int L, ltfat_int W,
 *                  ltfat_int a, ltfat_int M, ltfat_complex_s cTimeinv[]);
 * </tt>
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_NOTPOSARG    | Either of \a L, \a W, \a a, \a M is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(dgt_phaselock)(const LTFAT_COMPLEX cFreqinv[],
                                  ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                                  LTFAT_COMPLEX cTimeinv[]);

/** Change dgt phase convention from time invariant to freq. invariant
 *
 * N = L/a
 *
 * \param[in]  cFreqinv   Input coefficients, size M x N x W
 * \param[in]  L          Length of the signal
 * \param[in]  W          Number of signal channels
 * \param[in]  a          Time hop factor
 * \param[in]  M          Number of frequency channels
 * \param[out] cTimeinv   Output coefficients, size M x N x W
 *
 * #### Versions #
 * <tt>
 * dgt_phaseunlock_dc(const ltfat_complex_d cFreqinv[], ltfat_int L, ltfat_int W,
 *                    ltfat_int a, ltfat_int M, ltfat_complex_d cTimeinv[]);
 *
 * dgt_phaseunlock_sc(const ltfat_complex_s cFreqinv[], ltfat_int L, ltfat_int W,
 *                    ltfat_int a, ltfat_int M, ltfat_complex_s cTimeinv[]);
 * </tt>
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_NOTPOSARG    | Either of \a L, \a W, \a a, \a M is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(dgt_phaseunlock)(const LTFAT_COMPLEX cTimeinv[],
                                    ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                                    LTFAT_COMPLEX cFreqinv[]);

/** Change dgtreal phase convention from freq. invariant to time invariant
 *
 * N = L/a, M2 = M/2 + 1
 *
 * \param[in]  cFreqinv   Input coefficients, size M2 x N x W
 * \param[in]  L          Length of the signal
 * \param[in]  W          Number of signal channels
 * \param[in]  a          Time hop factor
 * \param[in]  M          Number of frequency channels
 * \param[out] cTimeinv   Output coefficients, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * dgtreal_phaselock_dc(const ltfat_complex_d cFreqinv[], ltfat_int L, ltfat_int W,
 *                      ltfat_int a, ltfat_int M, ltfat_complex_d cTimeinv[]);
 *
 * dgtreal_phaselock_sc(const ltfat_complex_s cFreqinv[], ltfat_int L, ltfat_int W,
 *                      ltfat_int a, ltfat_int M, ltfat_complex_s cTimeinv[]);
 * </tt>
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_NOTPOSARG    | Either of \a L, \a W, \a a, \a M is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(dgtreal_phaselock)(const LTFAT_COMPLEX cFreqinv[],
                                      ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                                      LTFAT_COMPLEX cTimeinv[]);

/** Change dgtreal phase convention from time invariant to freq. invariant
 *
 * N = L/a, M2 = M/2 + 1
 *
 * \param[in]  cFreqinv   Input coefficients, size M2 x N x W
 * \param[in]  L          Length of the signal
 * \param[in]  W          Number of signal channels
 * \param[in]  a          Time hop factor
 * \param[in]  M          Number of frequency channels
 * \param[out] cTimeinv   Output coefficients, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * dgtreal_phaseunlock_dc(const ltfat_complex_d cFreqinv[], ltfat_int L, ltfat_int W,
 *                        ltfat_int a, ltfat_int M, ltfat_complex_d cTimeinv[]);
 *
 * dgtreal_phaseunlock_sc(const ltfat_complex_s cFreqinv[], ltfat_int L, ltfat_int W,
 *                        ltfat_int a, ltfat_int M, ltfat_complex_s cTimeinv[]);
 * </tt>
 * \returns
 * Status code           | Description
 * ----------------------|--------------------------------------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL
 * LTFATERR_NOTPOSARG    | Either of \a L, \a W, \a a, \a M is less or equal to 0.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(dgtreal_phaseunlock)(const LTFAT_COMPLEX cTimeinv[],
                                        ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                                        LTFAT_COMPLEX cFreqinv[]);

/** @}*/
