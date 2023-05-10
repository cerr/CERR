/*   --- dgtreal_long class definition  --- */
typedef struct LTFAT_NAME(dgtreal_long_plan) LTFAT_NAME(dgtreal_long_plan);

/** 
 *  \addtogroup dgt
 * @{
 */

/** \name DGTREAL using factorization algorithm
 * @{ */

/** Compute Discrete Gabor Transform for real signals using the factorization algorithm
 *
 * \param[in]     f   Input signal, size L x W
 * \param[in]     g   Window, size L x 1
 * \param[in]     L   Signal length
 * \param[in]     W   Number of channels of the signal
 * \param[in]     a   Time hop factor
 * \param[in]     M   Number of frequency channels
 * \param[in] ptype   Phase convention
 * \param[out]    c   DGT coefficients, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtreal_long_d(const double f[], const double g[],
 *                      ltfat_int L, ltfat_int W,  ltfat_int a,
 *                      ltfat_int M, const ltfat_phaseconvention ptype, ltfat_complex_d c[]);
 *
 * ltfat_dgtreal_long_s(const float f[], const float g[],
 *                      ltfat_int L, ltfat_int W,  ltfat_int a,
 *                      ltfat_int M, const ltfat_phaseconvention ptype, ltfat_complex_s c[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a f, \a g, \a c
 * LTFATERR_BADSIZE         | length of the signal and of the window \a L was less or equal to 0.
 * LTFATERR_NOTPOSARG       | At least one of the following was less or equal to zero: \a W, \a a, \a M
 * LTFATERR_BADTRALEN       | \a L is not divisible by both \a a and \a M.
 * LTFATERR_INITFAILED      | FFTW plan creation failed
 * LTFATERR_CANNOTHAPPEN    | \a ptype does not have a valid value from the ltfat_phaseconvention enum
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
LTFAT_API int
LTFAT_NAME(dgtreal_long)(const LTFAT_REAL f[], const LTFAT_REAL g[],
                         ltfat_int L, ltfat_int W,  ltfat_int a,
                         ltfat_int M, const ltfat_phaseconvention ptype,
                         LTFAT_COMPLEX c[]);

/** Initialize plan for Discrete Gabor Transform for real signals for the factorization algorithm
 *
 * \note \a f can be NULL if the plan is intended to be used with the _newarray execute function.
 * Similarly, \a c can also be NULL, but only if FFTW_ESTIMATE is passed in \a flags
 * (the FFTW planning routine does not touch the array). On the other hand,
 * the content of \a c might get overwritten if other FFTW planning flags are used.
 *
 * \param[in]     f   Input signal, size L x W or NULL
 * \param[in]     g   Window, size L x 1
 * \param[in]     L   Signal length
 * \param[in]     W   Number of channels of the signal
 * \param[in]     a   Time hop factor
 * \param[in]     M   Number of frequency channels
 * \param[in]     c   DGT coefficients, size M2 x N x W or NULL if (flags & FFTW_ESTIMATE) is nonzero.
 * \param[in] ptype   Phase convention
 * \param[in] flags   FFTW plan flags
 * \param[out] plan   DGT plan
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtreal_long_init_d(const double f[], const double g[],
 *                           ltfat_int L, ltfat_int W,  ltfat_int a,
 *                           ltfat_int M,  ltfat_complex_d c[], const ltfat_phaseconvention ptype,
 *                           unsigned flags, ltfat_dgtreal_long_plan_d** plan);
 *
 * ltfat_dgtreal_long_init_s(const float f[], const float g[],
 *                           ltfat_int L, ltfat_int W,  ltfat_int a,
 *                           ltfat_int M,  ltfat_complex_d c[], const ltfat_phaseconvention ptype,
 *                           unsigned flags, ltfat_dgtreal_long_plan_s** plan);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | The plan pointer \a plan or window \a g were NULL or \a c was NULL and (flags & FFTW_ESTIMATE) is zero
 * LTFATERR_BADSIZE         | Signal and window length \a L is less or equal to 0.
 * LTFATERR_NOTPOSARG       | Either of \a W, \a a, \a M was less or equal to zero.
 * LTFATERR_BADTRALEN       | \a L is not divisible by both \a a and \a M.
 * LTFATERR_INITFAILED      | The FFTW plan creation failed
 * LTFATERR_CANNOTHAPPEN    | \a ptype does not have a valid value from the ltfat_phaseconvention enum
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
LTFAT_API int
LTFAT_NAME(dgtreal_long_init)(const LTFAT_REAL g[],
                              ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                              const LTFAT_REAL f[], LTFAT_COMPLEX c[],
                              const ltfat_phaseconvention ptype, unsigned flags,
                              LTFAT_NAME(dgtreal_long_plan)** plan);

/** Execute plan for Discrete Gabor Transform for real signals using the factorization algorithm
 *
 * \param[in]  plan   DGT plan
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtreal_long_execute_d(ltfat_dgtreal_long_plan_d* plan);
 *
 * ltfat_dgtreal_long_execute_s(ltfat_dgtreal_long_plan_s* plan);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | The \a plan was NULL or it was created with \a f == NULL or \a c == NULL
 */
LTFAT_API int
LTFAT_NAME(dgtreal_long_execute)(LTFAT_NAME(dgtreal_long_plan)* plan);

/** Execute plan for Discrete Gabor Transform for real signals using the factorization algorithm
 *
 * ... on arrays which might have not been used in the init function.
 *
 * \param[in]  plan   DGT plan
 * \param[in]     f   Input signal, size L x W
 * \param[out]    c   Coefficients, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtreal_long_execute_newarray_d(ltfat_dgtreal_long_plan_d* plan,
 *                                       const double f[], ltfat_complex_d c[]);
 *
 * ltfat_dgtreal_long_execute_newarray_s(ltfat_dgtreal_long_plan_s* plan
 *                                       const float f[], ltfat_complex_s c[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | Al least one of the arguments was NULL.
 */
LTFAT_API int
LTFAT_NAME(dgtreal_long_execute_newarray)(LTFAT_NAME(dgtreal_long_plan)* plan,
        const LTFAT_REAL* f, LTFAT_COMPLEX* c);

/** Destroy the plan
 *
 * \param[in]  plan   DGT plan
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtreal_long_done_d(ltfat_dgtreal_long_plan_d** plan);
 *
 * ltfat_dgtreal_long_done_s(ltfat_dgtreal_long_plan_s** plan);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|--------------------------------------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | plan or *plan was NULL.
 */
LTFAT_API int
LTFAT_NAME(dgtreal_long_done)(LTFAT_NAME(dgtreal_long_plan)** plan);

/** @}*/
/** @}*/

LTFAT_API int
LTFAT_NAME(dgtreal_walnut_plan)(LTFAT_NAME(dgtreal_long_plan)* plan);
