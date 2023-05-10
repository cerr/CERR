typedef struct LTFAT_NAME(idgt_long_plan) LTFAT_NAME(idgt_long_plan);

/**
 *  \addtogroup dgt
 * @{
 * For a detailed description see the dedicated page \ref dgttheory
 */
 /** \name IDGT using factorization algorithm
  * @{ */

/** Computes inverse Discrete Gabor Transform using the factorization algorithm
 *
 * \param[in]       c   Input coefficients, M x N x W array
 * \param[in]       g   Window to be used, array of length L
 * \param[in]       L   Signal length
 * \param[in]       W   Number of channels of the signal
 * \param[in]       a   Time hop factor
 * \param[in]       M   Number of frequency channels
 * \param[in]   ptype   Phase convention
 * \param[out]      f   Reconstructed signal, L x W array
 * \returns Status code
 *
 * #### Versions #
 * <tt>
 * ltfat_idgt_long_d(const ltfat_complex_d c[], const double g[], ltfat_int L,
 *                   ltfat_int W, ltfat_int a, ltfat_int M,
 *                   const ltfat_phaseconvention ptype, ltfat_complex_d f[]);
 *
 * ltfat_idgt_long_s(const ltfat_complex_s c[], const float g[], ltfat_int L,
 *                   ltfat_int W, ltfat_int a, ltfat_int M,
 *                   const ltfat_phaseconvention ptype, ltfat_complex_s f[]);
 *
 * ltfat_idgt_long_dc(const ltfat_complex_d c[], const ltfat_complex_d g[], ltfat_int L,
 *                    ltfat_int W, ltfat_int a, ltfat_int M,
 *                    const ltfat_phaseconvention ptype, ltfat_complex_d f[]);
 *
 * ltfat_idgt_long_sc(const ltfat_complex_s c[], const ltfat_complex_s g[], ltfat_int L,
 *                    ltfat_int W, ltfat_int a, ltfat_int M,
 *                    const ltfat_phaseconvention ptype, ltfat_complex_s f[]);
 * </tt>
 */
LTFAT_API int
LTFAT_NAME(idgt_long)(const LTFAT_COMPLEX c[], const LTFAT_TYPE g[],
                      ltfat_int L, ltfat_int W,
                      ltfat_int a, ltfat_int M,
                      const ltfat_phaseconvention ptype, LTFAT_COMPLEX f[]);

/** Initialize inverse Discrete Gabor Transform plan for the factorization algorithm
 *
 * \note Please note that the input and output arrays will be overwritten when
 * anything else than FFTW_ESTIMATE is used in flags.
 *
 * \param[in]       c   Input coefficient array, M x N x W array
 * \param[in]       g   Window to be used, array of length L
 * \param[in]       L   Signal length
 * \param[in]       W   Number of channels of the signal
 * \param[in]       a   Time hop factor
 * \param[in]       M   Number of frequency channels
 * \param[in]       f   Reconstructed signal array, L x W array
 * \param[in]   flags   FFTW plan flags
 * \param[in]   ptype   Phase convention
 * \param[out]  plan    Initialized plan
 * \returns Status code
 *
 * #### Versions #
 * <tt>
 * ltfat_idgt_long_init_d(ltfat_complex_d c[], const double g[], ltfat_int L,
 *                        ltfat_int W, ltfat_int a, ltfat_int M,
 *                        ltfat_complex_d f[], const ltfat_phaseconvention ptype, unsigned flags,
 *                        ltfat_idgt_long_plan_d** plan);
 *
 * ltfat_idgt_long_init_s(ltfat_complex_s c[], const float g[], ltfat_int L,
 *                        ltfat_int W, ltfat_int a, ltfat_int M,
 *                        ltfat_complex_s f[], const ltfat_phaseconvention ptype, unsigned flags,
 *                        ltfat_idgt_long_plan_s** plan);
 *
 * ltfat_idgt_long_init_dc(ltfat_complex_d c[], const ltfat_complex_d g[], ltfat_int L,
 *                         ltfat_int W, ltfat_int a, ltfat_int M,
 *                         ltfat_complex_d f[], const ltfat_phaseconvention ptype, unsigned flags,
 *                         ltfat_idgt_long_plan_dc** plan);
 *
 * ltfat_idgt_long_init_sc(ltfat_complex_s c[], const ltfat_complex_s g[], ltfat_int L,
 *                         ltfat_int W, ltfat_int a, ltfat_int M,
 *                         ltfat_complex_s f[], const ltfat_phaseconvention ptype, unsigned flags,
 *                         ltfat_idgt_long_plan_sc** plan);
 * </tt>
 */
LTFAT_API int
LTFAT_NAME(idgt_long_init)( const LTFAT_TYPE g[],
                            ltfat_int L, ltfat_int W,
                            ltfat_int a, ltfat_int M, LTFAT_COMPLEX c[], LTFAT_COMPLEX f[],
                            const ltfat_phaseconvention ptype, unsigned flags,
                            LTFAT_NAME(idgt_long_plan)** plan);


/** Execute the Inverse Discrete Gabor Transform plan
 *
 * \param[in]       p   Plan
 * \returns Status code
 *
 * #### Versions #
 * <tt>
 * ltfat_idgt_long_execute_d(ltfat_idgt_long_plan_d* p);
 *
 * ltfat_idgt_long_execute_s(ltfat_idgt_long_plan_s* p);
 *
 * ltfat_idgt_long_execute_dc(ltfat_idgt_long_plan_dc* p);
 *
 * ltfat_idgt_long_execute_sc(ltfat_idgt_long_plan_sc* p);
 * </tt>
 */
LTFAT_API int
LTFAT_NAME(idgt_long_execute)(LTFAT_NAME(idgt_long_plan)* p);


/** Execute the Inverse Discrete Gabor Transform plan
 *
 * ... on arrays which might not have been used in init.
 *
 * \param[in]       p   Plan
 * \param[in]       c   Coefficients, size M x N xW
 * \param[out]      f   Output signal, size L x W
 * \returns Status code
 *
 * #### Versions #
 * <tt>
 * ltfat_idgt_long_execute_newarray_d(ltfat_idgt_long_plan_d* p, const ltfat_complex_d c[],
 *                                    ltfat_complex_d f[]);
 *
 * ltfat_idgt_long_execute_newarray_s(ltfat_idgt_long_plan_s* p, const ltfat_complex_d c[],
 *                                    ltfat_complex_d f[]);
 *
 * ltfat_idgt_long_execute_newarray_dc(ltfat_idgt_long_plan_dc* p, const ltfat_complex_d c[],
 *                                     ltfat_complex_d f[]);
 *
 * ltfat_idgt_long_execute_newarray_sc(ltfat_idgt_long_plan_sc* p, const ltfat_complex_d c[],
 *                                     ltfat_complex_d f[]);
 * </tt>
 */
LTFAT_API int
LTFAT_NAME(idgt_long_execute_newarray)(LTFAT_NAME(idgt_long_plan)* p,
                                       const LTFAT_COMPLEX c[],
                                       LTFAT_COMPLEX f[]);


/** Destroy the Discrete Gabor Transform plan
 *
 * \param[in]       plan   Plan
 * \returns Status code
 *
 * #### Versions #
 * <tt>
 * ltfat_idgt_long_done_d(ltfat_idgt_long_plan_d** p);
 *
 * ltfat_idgt_long_done_s(ltfat_idgt_long_plan_s** p);
 *
 * ltfat_idgt_long_done_dc(ltfat_idgt_long_plan_dc** p);
 *
 * ltfat_idgt_long_done_sc(ltfat_idgt_long_plan_sc** p);
 * </tt>
 */
LTFAT_API int
LTFAT_NAME(idgt_long_done)(LTFAT_NAME(idgt_long_plan)** plan);
/** @}*/
/** @}*/

// LTFAT_API void
// LTFAT_NAME(idgt_fac)(const LTFAT_COMPLEX *c, const LTFAT_COMPLEX *gf,
//                      ltfat_int L,
//                      ltfat_int W, ltfat_int a, ltfat_int M,
//                      const ltfat_phaseconvention ptype, LTFAT_COMPLEX *f);

LTFAT_API void
LTFAT_NAME(idgt_walnut_execute)(LTFAT_NAME(idgt_long_plan)* p);
