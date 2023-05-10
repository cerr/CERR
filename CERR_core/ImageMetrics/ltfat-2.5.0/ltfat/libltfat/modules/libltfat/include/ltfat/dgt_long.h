typedef struct LTFAT_NAME(dgt_long_plan) LTFAT_NAME(dgt_long_plan);

/** \defgroup dgt Discrete Gabor Transform 
 *  \addtogroup dgt
 * @{
 * For a detailed description see the dedicated page \ref dgttheory
 */

 /** \name DGT using factorization algorithm
  * @{ */

/** Computes DGT
 *
 * \param[in]      f  Multi-channel input signal, size L x W
 * \param[in]      g  Window, size L
 * \param[in]      L  Input signal length
 * \param[in]      W  Number of channels
 * \param[in]      a  Hop factor
 * \param[in]      M  Number of frequency channels (FFT size)
 * \param[in]  ptype  Number of frame diagonal samples
 * \param[out]     c  Output DGT coefficients, size M x N x W
 *
 * \returns Status code
 *
 *  Function versions
 *  -----------------
 *
 *  <tt>
 *  ltfat_dgt_long_d(const double f[], const double g[], ltfat_int L,
 *                   ltfat_int W,  ltfat_int a, ltfat_int M,
 *                   const ltfat_phaseconvention ptype, ltfat_complex_d c[]);
 *
 *  ltfat_dgt_long_s(const float f[], const float g[], ltfat_int L,
 *                   ltfat_int W,  ltfat_int a, ltfat_int M,
 *                   const ltfat_phaseconvention ptype, ltfat_complex_s c[]);
 *
 *  ltfat_dgt_long_dc(const ltfat_complex_d f[], const ltfat_complex_d g[],
 *                    ltfat_int L, ltfat_int W,  ltfat_int a,
 *                    ltfat_int M, const ltfat_phaseconvention ptype,
 *                    ltfat_complex_d c[]);
 *
 *  ltfat_dgt_long_sc(const ltfat_complex_s f[], const ltfat_complex_s g[],
 *                    ltfat_int L, ltfat_int W,  ltfat_int a,
 *                    ltfat_int M, const ltfat_phaseconvention ptype,
 *                    ltfat_complex_s c[]);
 *  </tt>
 */
LTFAT_API int
LTFAT_NAME(dgt_long)(const LTFAT_TYPE f[], const LTFAT_TYPE g[],
                     ltfat_int L, ltfat_int W,  ltfat_int a,
                     ltfat_int M, const ltfat_phaseconvention ptype,
                     LTFAT_COMPLEX c[]);

/** Inicialization of the DGT plan
 *
 * \param[in]      f  Multi-channel input signal, size L x W
 * \param[in]      g  Window, size L
 * \param[in]      L  Input signal length
 * \param[in]      W  Number of channels
 * \param[in]      a  Hop factor
 * \param[in]      M  Number of frequency channels (FFT size)
 * \param[in]   cout  Output DGT coefficients, size M x N x W
 * \param[in]  ptype  Number of frame diagonal samples
 * \param[in]  flags  FFTW planning flag
 * \param[out]     p  DGT plan
 *
 * \returns Status code
 *
 *  Function versions
 *  -----------------
 *
 *  <tt>
 *  ltfat_dgt_long_init_d(const double f[], const double g[], ltfat_int L,
 *                        ltfat_int W,  ltfat_int a, ltfat_int M,
 *                        ltfat_complex_d c[], const ltfat_phaseconvention ptype,
 *                        unsigned flags, dgt_long_plan_d** p);
 *
 *  ltfat_dgt_long_init_s(const float f[], const float g[], ltfat_int L,
 *                        ltfat_int W,  ltfat_int a, ltfat_int M,
 *                        ltfat_complex_s c[], const ltfat_phaseconvention ptype,
 *                        unsigned flags, dgt_long_plan_s** p);
 *
 *  ltfat_dgt_long_init_dc(const ltfat_complex_d f[], const ltfat_complex_d g[],
 *                         ltfat_int L, ltfat_int W,  ltfat_int a,
 *                         ltfat_int M, ltfat_complex_d c[],
 *                         const ltfat_phaseconvention ptype, unsigned flags,
 *                         dgt_long_plan_dc** p);
 *
 *  ltfat_dgt_long_init_sc(ltfat_complex_s f[], const ltfat_complex_s g[],
 *                         ltfat_int L, ltfat_int W,  ltfat_int a,
 *                         ltfat_int M, ltfat_complex_s c[],
 *                         const ltfat_phaseconvention ptype, unsigned flags,
 *                         dgt_long_plan_sc** p);
 *  </tt>
 */
LTFAT_API int
LTFAT_NAME(dgt_long_init)(const LTFAT_TYPE g[], ltfat_int L,
                          ltfat_int W, ltfat_int a, ltfat_int M,
                          const LTFAT_TYPE f[], LTFAT_COMPLEX c[],
                          const ltfat_phaseconvention ptype, unsigned flags,
                          LTFAT_NAME(dgt_long_plan)** p);

/** Execute DGT plan
 *
 * \param[in]     plan  DGT plan
 *
 *  Function versions
 *  -----------------
 *
 *  <tt>
 *  ltfat_dgt_long_execute_d(ltfat_dgt_long_plan_d* plan);
 *
 *  ltfat_dgt_long_execute_s(ltfat_dgt_long_plan_s* plan);
 *
 *  ltfat_dgt_long_execute_dc(ltfat_dgt_long_plan_dc* plan);
 *
 *  ltfat_dgt_long_execute_sc(ltfat_dgt_long_plan_sc* plan);
 *  </tt>
 */
LTFAT_API int
LTFAT_NAME(dgt_long_execute)(LTFAT_NAME(dgt_long_plan)* plan);

/** Execute DGT plan
 *
 * ... on arrays which might not have been used in init.
 *
 * \param[in]     plan  DGT plan
 * \param[in]        f  Input signal, size L x W
 * \param[out]       c  Coefficients, size M x N x W
 *
 *  Function versions
 *  -----------------
 *
 *  <tt>
 *  ltfat_dgt_long_execute_newarray_d(ltfat_dgt_long_plan_d* plan,
 *                                    const double f[], ltfat_complex_d c[]);
 *
 *  ltfat_dgt_long_execute_newarray_s(ltfat_dgt_long_plan_s* plan,
 *                                    const float f[], ltfat_complex_s c[]);
 *
 *  ltfat_dgt_long_execute_newarray_dc(ltfat_dgt_long_plan_cd* plan,
 *                                     const ltfat_complex_d f[], ltfat_complex_d c[]);
 *
 *  ltfat_dgt_long_execute_newarray_sc(ltfat_dgt_long_plan_cs* plan,
 *                                     const ltfat_complex_s f[], ltfat_complex_s c[]);
 *  </tt>
 */
LTFAT_API int
LTFAT_NAME(dgt_long_execute_newarray)(LTFAT_NAME(dgt_long_plan)* plan,
                                      const LTFAT_TYPE f[], LTFAT_COMPLEX c[]);


/** Destroy DGT plan
 *
 *  Function versions
 *  -----------------
 *
 *  <tt>
 *  ltfat_dgt_long_done_d(ltfat_dgt_long_plan_d** plan);
 *
 *  ltfat_dgt_long_done_s(ltfat_dgt_long_plan_s** plan);
 *
 *  ltfat_dgt_long_done_dc(ltfat_dgt_long_plan_dc** plan);
 *
 *  ltfat_dgt_long_done_sc(ltfat_dgt_long_plan_sc** plan);
 *  </tt>
 */

LTFAT_API int
LTFAT_NAME(dgt_long_done)(LTFAT_NAME(dgt_long_plan)** plan);

/** @}*/
/** @}*/

LTFAT_API int
LTFAT_NAME(dgt_walnut_execute)(LTFAT_NAME(dgt_long_plan)* plan, LTFAT_COMPLEX* cout);
