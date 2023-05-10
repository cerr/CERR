/** Compute the first dl samples of the Gabor frame operator diagonal
 *
 * \param[in]   g    Original window
 * \param[in]  gl    Length of the windows
 * \param[in]   a    Hop factor
 * \param[in]   M    Number of channels
 * \param[in]  dl    Number of frame diagonal samples
 * \param[out]  d    Frame diagonal
 *
 * \returns Status code
 */
LTFAT_API int
LTFAT_NAME(gabframediag)(const LTFAT_TYPE* g, ltfat_int gl,
                         ltfat_int a, ltfat_int M, ltfat_int dl, LTFAT_REAL* d);

/** \addtogroup windows
 * @{ */

 /** \name Dual and tight windows
 * @{ 
 *
 * In order to be able to compute canonical dual or tight windows,
 * the system must be a frame i.e. M>=a && gl>=a where gl is length
 * of the window support.
 * In general, the canonical dual (tight) window support might not be the same
 * as of the original window.
 * The canonical dual (tight) window is guaranteed to have the same support
 * in the _painless case_ i.e. if M>=gl holds in addition to the frame condition.
 */

/** Compute canonical dual window for Gabor system
 *
 * \warning This function is not available if libltfat has been compiled with
 * NOBLASLAPACK.
 *
 * \param[in]   g    Original window(s), size L x R
 * \param[in]   L    Length of the system
 * \param[in]   a    Hop factor
 * \param[in]   M    Number of channels
 * \param[out] gd    Canonical dual window(s), size L x R
 *
 * #### Versions #
 * <tt>
 * ltfat_gabdual_long_d(const double g[], const ltfat_int L, 
 *                      ltfat_int a, ltfat_int M, double gd[]);
 *
 * ltfat_gabdual_long_s(const float g[], ltfat_int L, 
 *                      ltfat_int a, ltfat_int M, float gd[]);
 *
 * ltfat_gabdual_long_dc(const ltfat_complex_d g[], ltfat_int L, 
 *                       ltfat_int a, ltfat_int M, ltfat_complex_d gd[]);
 *
 * ltfat_gabdual_long_sc(const ltfat_complex_s g[], ltfat_int L, 
 *                       ltfat_int a, ltfat_int M, ltfat_complex_s gd[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | Either of the arrays is NULL
 * LTFATERR_BADSIZE         | Size of the array \a L is less or equal to 0.
 * LTFATERR_BADTRALEN       | \a L is not divisible by both \a a and \a M.
 * LTFATERR_NOTPOSARG       | Either of \a R, \a a, \a M is less or equal to 0.
 * LTFATERR_NOTAFRAME       | System does not form a frame i.e. M<a
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
LTFAT_API int
LTFAT_NAME(gabdual_long)(const LTFAT_TYPE g[],
                         ltfat_int L, ltfat_int a,
                         ltfat_int M, LTFAT_TYPE gd[]);

LTFAT_API int
LTFAT_NAME(multiwingabdual_long)(
        const LTFAT_TYPE* g, ltfat_int L, ltfat_int R, ltfat_int a,
        ltfat_int M, LTFAT_TYPE* gd);

/** Compute canonical tight window for Gabor system
 *
 * \warning This function is not available if libltfat has been compiled with
 * NOBLASLAPACK.
 * 
 * \see fir2long long2fir
 *
 * \param[in]   g    Original window(s), size L x R
 * \param[in]   L    Length of the system
 * \param[in]   a    Hop factor
 * \param[in]   M    Number of channels
 * \param[out] gt    Canonical tight window
 *
 * #### Versions #
 * ltfat_gabtight_long_d(const double g[], ltfat_int L, 
 *                       ltfat_int a, ltfat_int M, double gt[]);
 *
 * ltfat_gabtight_long_s(const float g[], ltfat_int L, 
 *                       ltfat_int a, ltfat_int M, float gt[]);
 *
 * ltfat_gabtight_long_dc(const ltfat_complex_d g[], ltfat_int L, 
 *                        ltfat_int a, ltfat_int M, ltfat_complex_d gt[]);
 *
 * ltfat_gabtight_long_sc(const ltfat_complex_s g[], ltfat_int L, 
 *                        ltfat_int a, ltfat_int M, ltfat_complex_s gt[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | Either of the arrays is NULL
 * LTFATERR_BADSIZE         | Size of the array \a L is less or equal to 0.
 * LTFATERR_BADTRALEN       | L is not divisible by both \a a and \a M.
 * LTFATERR_NOTPOSARG       | Either of \a R, \a a, \a M is less or equal to 0.
 * LTFATERR_NOTAFRAME       | System does not form a frame i.e. M<a
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
LTFAT_API int
LTFAT_NAME(gabtight_long)(const LTFAT_TYPE g[],
                          ltfat_int L, ltfat_int a,
                          ltfat_int M, LTFAT_TYPE gd[]);

LTFAT_API int
LTFAT_NAME(multiwingabtight_long)(const LTFAT_TYPE g[],
                          ltfat_int L, ltfat_int R, ltfat_int a,
                          ltfat_int M, LTFAT_TYPE gt[]);

/** Compute canonical dual window for painless Gabor system
 *
 * \param[in]   g    Original window
 * \param[in]  gl    Length of the windows
 * \param[in]   a    Hop factor
 * \param[in]   M    Number of channels
 * \param[out] gd    Canonical dual window
 *
 * #### Versions #
 * <tt>
 * ltfat_gabdual_painless_d(const double g[], ltfat_int gl, ltfat_int a, ltfat_int M, double gd[]);
 *
 * ltfat_gabdual_painless_s(const float g[], ltfat_int gl, ltfat_int a, ltfat_int M, float gd[]);
 *
 * ltfat_gabdual_painless_cd(const ltfat_complex_d g[], ltfat_int gl, ltfat_int a, ltfat_int M,
 *                           ltfat_complex_d gd[]);
 *
 * ltfat_gabdual_painless_cs(const ltfat_complex_s g[], ltfat_int gl, ltfat_int a, ltfat_int M,
 *                           ltfat_complex_s gd[]);
 * </tt>
 * \returns
 * Status code           | Description
 * ----------------------|------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL.
 * LTFATERR_BADSIZE      | Length of the windows is less or equal to 0.
 * LTFATERR_NOTPOSARG    | Either of \a a, \a M is less or equal to zero.
 * LTFATERR_NOTAFRAME    | System is not a frame.
 * LTFATERR_NOTPAINLESS  | System is not painless. 
 * LTFATERR_NOMEM        | Indicates that the heap allocation failed.
 */
LTFAT_API int
LTFAT_NAME(gabdual_painless)(const LTFAT_TYPE g[], ltfat_int gl, ltfat_int a,
                             ltfat_int M, LTFAT_TYPE gd[]);

/** Compute canonical tight window for painless Gabor system
 *
 * \param[in]   g    Original window
 * \param[in]  gl    Length of the windows
 * \param[in]   a    Hop factor
 * \param[in]   M    Number of channels
 * \param[out] gt    Canonical tight window
 *
 * #### Versions #
 * <tt>
 * ltfat_gabtight_painless_d(const double g[], ltfat_int gl, ltfat_int a, ltfat_int M, double gt[]);
 *
 * ltfat_gabtight_painless_s(const float g[], ltfat_int gl, ltfat_int a, ltfat_int M, float gt[]);
 *
 * ltfat_gabtight_painless_cd(const ltfat_complex_d g[], ltfat_int gl, ltfat_int a, ltfat_int M,
 *                            ltfat_complex_d gt[]);
 *
 * ltfat_gabtight_painless_cs(const ltfat_complex_s g[], ltfat_int gl, ltfat_int a, ltfat_int M,
 *                            ltfat_complex_s gt[]);
 * </tt>
 * \returns
 * Status code           | Description
 * ----------------------|------------
 * LTFATERR_SUCCESS      | Indicates no error
 * LTFATERR_NULLPOINTER  | Either of the arrays is NULL.
 * LTFATERR_BADSIZE      | Length of the windows is less or equal to 0.
 * LTFATERR_NOTPOSARG    | Either of \a a, \a M is less or equal to zero.
 * LTFATERR_NOTAFRAME    | System is not a frame.
 * LTFATERR_NOTPAINLESS  | System is not painless. 
 * LTFATERR_NOMEM        | Indicates that the heap allocation failed.
 */
LTFAT_API int
LTFAT_NAME(gabtight_painless)(const LTFAT_TYPE g[], ltfat_int gl, ltfat_int a,
                              ltfat_int M, LTFAT_TYPE gt[]);
/** @} */
/** @} */

/** Compute partition of unity window from any window
 *
 * Creates a window which is PU for given lattice.
 *
 * When using PU window for either analysis or synthesis, the other window can just be
 * rectangular.
 *
 * \param[in]   g    Original window
 * \param[in]  gl    Length of the windows
 * \param[in]   a    Hop factor
 * \param[in]   M    Number of channels
 * \param[out] gpu   Partition of unity window
 *
 * \returns Status code
 */
LTFAT_API int
LTFAT_NAME(gabpu_painless)(const LTFAT_TYPE* g, ltfat_int gl, ltfat_int a,
                           ltfat_int M, LTFAT_TYPE* gpu);
