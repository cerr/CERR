/** \addtogroup windows
 * @{
 */

/** Compute real, periodized Gaussian window
 *
 * \param[in]   L      Window length
 * \param[in]   w      Time-freqency support ratio
 * \param[in]   c_t    Time center offset
 * \param[out]  g      Window
 *
 * #### Function versions #
 * <tt>
 * ltfat_pgauss_d(ltfat_int L,const double w, const double c_t, double* g);
 *
 * ltfat_pgauss_s(ltfat_int L,const double w, const double c_t, float* g);
 * </tt>
 * \returns
 * Status code           | Description
 * ----------------------|------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | The output array is NULL.
 * LTFATERR_BADSIZE         | Window length is less or equal to 0.
 * LTFATERR_NOTPOSARG    | \a w is less or equal to zero.
 */
LTFAT_API int
LTFAT_NAME(pgauss)(ltfat_int L, const double w, const double c_t,
                   LTFAT_REAL *g);

/** Compute complex, periodized Gaussian window
 *
 * \param[in]   L      Window length
 * \param[in]   w      Time-freqency support ratio
 * \param[in]   c_t    Time center offset
 * \param[in]   c_f    Frequency center offset
 * \param[out]  g      Window
 *
 * #### Function versions #
 *
 * <tt>
 * ltfat_pgauss_cd(ltfat_int L, const double w, const double c_t,
 *                      const double c_f, ltfat_complex_d* g);
 *
 * ltfat_pgauss_cs(ltfat_int L, const double w, const double c_t,
 *                      const double c_f, ltfat_complex_s* g);
 * </tt>
 * \returns
 * Status code           | Description
 * ----------------------|------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | The output array is NULL.
 * LTFATERR_BADSIZE         | Window length is less or equal to 0.
 * LTFATERR_NOTPOSARG    | \a w is less or equal to zero.
 */
LTFAT_API int
LTFAT_NAME_COMPLEX(pgauss)(ltfat_int L, const double w, const double c_t,
                           const double c_f, LTFAT_COMPLEX *g);

/** @} */
