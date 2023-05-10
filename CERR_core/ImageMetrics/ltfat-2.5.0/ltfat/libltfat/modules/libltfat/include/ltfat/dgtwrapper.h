#include "dgtwrapper_typeconstant.h"

typedef struct LTFAT_NAME(dgt_plan) LTFAT_NAME(dgt_plan);

/** \addtogroup dgtwrapper
 * @{
 *
 */

/** \name DGT wrapper interface
 * @{ */

/**
 * Note c can be NULL if FFTW_ESTIMATE is used in flags
 *
 * For versions _d and _s, if \f is not NULL, it should be casted to a
 * real array an populated as such.
 *
 * #### Versions #
 * <tt>
 * dgt_init_d(const double g[], ltfat_int gl, ltfat_int L, ltfat_int W,
 *            ltfat_int a, ltfat_int M, ltfat_complex_d f[], ltfat_complex_d c[],
 *            ltfat_dgt_params* params, dgt_plan_d** p);
 *
 * dgt_init_s(const float g[], ltfat_int gl, ltfat_int L, ltfat_int W,
 *            ltfat_int a, ltfat_int M, ltfat_complex_s f[], ltfat_complex_s c[],
 *            ltfat_dgt_params* params, dgt_plan_s** p);
 *
 * dgt_init_dc(const ltfat_complex_d g[], ltfat_int gl, ltfat_int L, ltfat_int W,
 *            ltfat_int a, ltfat_int M, ltfat_complex_d f[], ltfat_complex_d c[],
 *            ltfat_dgt_params* params, dgt_plan_d** p);
 *
 * dgt_init_sc(const ltfat_complex_s g[], ltfat_int gl, ltfat_int L, ltfat_int W,
 *            ltfat_int a, ltfat_int M, ltfat_complex_s f[], ltfat_complex_s c[],
 *            ltfat_dgt_params* params, dgt_plan_s** p);
 * </tt>
 *
 * \returns
 * Status code             | Description
 * ------------------------|--------------------------
 * LTFATERR_SUCCESS        | No error occurred
 * LTFATERR_NULLPOINTER    | \a g or \a p was NULL or \a c was NULL and flags != FFTW_ESTIMATE
 * LTFATERR_BADSIZE        | Signal length L is less or equal to 0.
 * LTFATERR_NOTPOSARG      | At least one of \f W, \f a, \f M, \f gl was less or equal to zero.
 * LTFATERR_NOTAFRAME      | System does not form a frame
 * LTFATERR_BADTRALEN      | \a L is not divisible by both \a a and \a M.
 * LTFATERR_INITFAILED     | The FFTW plan creation failed
 * LTFATERR_NOTSUPPORTED   | This is a non-painless system but its support was not compiled
 * LTFATERR_CANNOTHAPPEN   | \a hint does not have a valid value from \a ltfat_dgt_hint or \a ptype is not valid value from \a ltfat_phaseconvention enum
 * LTFATERR_NOMEM          | Signalizes memory allocation error
 */
LTFAT_API int
LTFAT_NAME(dgt_init)(const LTFAT_TYPE g[], ltfat_int gl,
                     ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                     LTFAT_COMPLEX f[], LTFAT_COMPLEX c[],
                     ltfat_dgt_params* params, LTFAT_NAME(dgt_plan)** p);

/**
 * Note c can be NULL if FFTW_ESTIMATE is used in flags
 *
 * #### Versions #
 * <tt>
 * dgt_init_gen_d(const double ga[], ltfat_int gal,
 *                const double gs[], ltfat_int gsl,
 *                ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
 *                ltfat_complex_d f[], ltfat_complex_d c[],
 *                ltfat_dgt_params* params, dgt_plan_d** p);
 *
 * dgt_init_gen_s(const float g[], ltfat_int gl, ltfat_int L, ltfat_int W,
 *            ltfat_int a, ltfat_int M, ltfat_complex_s f[], ltfat_complex_s c[],
 *            ltfat_dgt_params* params, dgt_plan_s** p);
 *
 * dgt_init_gen_dc(const ltfat_complex_d g[], ltfat_int gl, ltfat_int L, ltfat_int W,
 *            ltfat_int a, ltfat_int M, ltfat_complex_d f[], ltfat_complex_d c[],
 *            ltfat_dgt_params* params, dgt_plan_d** p);
 *
 * dgt_init_gen_ sc(const ltfat_complex_s g[], ltfat_int gl, ltfat_int L, ltfat_int W,
 *            ltfat_int a, ltfat_int M, ltfat_complex_s f[], ltfat_complex_s c[],
 *            ltfat_dgt_params* params, dgt_plan_s** p);
 * </tt>
 *
 * \returns
 * Status code             | Description
 * ------------------------|--------------------------
 * LTFATERR_SUCCESS        | No error occurred
 * LTFATERR_NULLPOINTER    | \a g or \a p was NULL or \a c was NULL and flags != FFTW_ESTIMATE
 * LTFATERR_BADSIZE        | Signal length L is less or equal to 0.
 * LTFATERR_NOTPOSARG      | At least one of \f W, \f a, \f M, \f gl was less or equal to zero.
 * LTFATERR_NOTAFRAME      | System does not form a frame
 * LTFATERR_BADTRALEN      | \a L is not divisible by both \a a and \a M.
 * LTFATERR_INITFAILED     | The FFTW plan creation failed
 * LTFATERR_NOTSUPPORTED   | This is a non-painless system but its support was not compiled
 * LTFATERR_CANNOTHAPPEN   | \a hint does not have a valid value from \a ltfat_dgt_hint or \a ptype is not valid value from \a ltfat_phaseconvention enum
 * LTFATERR_NOMEM          | Signalizes memory allocation error
 */
LTFAT_API int
LTFAT_NAME(dgt_init_gen)(const LTFAT_TYPE ga[], ltfat_int gal,
                         const LTFAT_TYPE gs[], ltfat_int gsl,
                         ltfat_int L, ltfat_int W, ltfat_int a, ltfat_int M,
                         LTFAT_COMPLEX f[], LTFAT_COMPLEX c[],
                         ltfat_dgt_params* params, LTFAT_NAME(dgt_plan)** p);

/** Perform DGTREAL synthesis followed by analysis
 *
 * \note This function CAN work inplace.
 *
 * M2 = M/2 + 1, N = L/a
 *
 * \param[in]    p  Transform plan
 * \param[in]  cin  Input coefficients, size M2 x N x W
 * \param[out]   c  Coefficients after projection, size M2 x N x W
 *
 * #### Versions #
 * <tt>
 *
 * ltfat_dgt_execute_proj_dc(ltfat_dgt_plan_dc* p,
 *                          const ltfat_complex_d cin[],
 *                          ltfat_complex_d c[]);
 *
 * ltfat_dgt_execute_proj_sc(ltfat_dgt_plan_sc* p,
 *                          const ltfat_complex_s cin[],
 *                          ltfat_complex_s c[]);
 * </tt>
 *
 * \returns
 */
#ifdef LTFAT_COMPLEXTYPE
LTFAT_API int
LTFAT_NAME(dgt_execute_proj)(LTFAT_NAME(dgt_plan)* p,
                             const LTFAT_COMPLEX cin[], LTFAT_COMPLEX fbuffer[], LTFAT_COMPLEX c[]);
#endif

/** Perform DGT synthesis
 *
 * M2 = M/2 + 1, N = L/a
 *
 * \param[in]    p  Transform plan
 * \param[in]    c  Input coefficients, size M2 x N x W
 * \param[out]   f  Reconstructed signal, size L x W
 *
 * #### Versions #
 * <tt>
 * ltfat_dgt_execute_syn_newarray_d(ltfat_dgt_plan_d* p,
 *                         const ltfat_complex_d c[], ltfat_complex_d f[]);
 *
 * ltfat_dgt_execute_syn_newarray_s(ltfat_dgt_plan_s* p,
 *                         const ltfat_complex_s c[], ltfat_complex_s f[]);
 *
 * ltfat_dgt_execute_syn_newarray_dc(ltfat_dgt_plan_dc* p,
 *                          const ltfat_complex_d c[], ltfat_complex_d f[]);
 *
 * ltfat_dgt_execute_syn_newarray_sc(ltfat_dgt_plan_sc* p,
 *                          const ltfat_complex_s c[], ltfat_complex_s f[]);
 * </tt>
 *
 * \returns
 */
LTFAT_API int
LTFAT_NAME(dgt_execute_syn_newarray)(LTFAT_NAME(dgt_plan)* p,
                                     const LTFAT_COMPLEX c[], LTFAT_COMPLEX f[]);

/** Perform DGT synthesis
 *
 * M2 = M/2 + 1, N = L/a
 *
 * \param[in]    p  Transform plan
 *
 * #### Versions #
 * <tt>
 * ltfat_dgt_execute_syn_d(ltfat_dgt_plan_d* p);
 *
 * ltfat_dgt_execute_syn_s(ltfat_dgt_plan_s* p);
 *
 * ltfat_dgt_execute_syn_dc(ltfat_dgt_plan_dc* p);
 *
 * ltfat_dgt_execute_syn_sc(ltfat_dgt_plan_sc* p);
 * </tt>
 *
 * \returns
 */
LTFAT_API int
LTFAT_NAME(dgt_execute_syn)(LTFAT_NAME(dgt_plan)* p);

/** Perform DGT analysis
 *
 * N = L/a
 *
 * \param[in]    p  Transform plan
 * \param[in]    f  Input signal, size L x W
 * \param[out]   c  Coefficients, size M x N x W
 *
 * #### Versions #
 * <tt>
 * ltfat_dgt_execute_ana_newarray_d(ltfat_dgt_plan_d* p,
 *                                  const double f[], ltfat_complex_d c[]);
 *
 * ltfat_dgt_execute_ana_newarray_s(ltfat_dgt_plan_s* p,
 *                                  const float f[], ltfat_complex_s c[]);
 *
 * ltfat_dgt_execute_ana_newarray_dc(ltfat_dgt_plan_dc* p,
 *                                   const ltfat_complex_d f[], ltfat_complex_d c[]);
 *
 * ltfat_dgt_execute_ana_newarray_sc(ltfat_dgt_plan_s* p,
 *                                   const ltfat_complex_s f[], ltfat_complex_s c[]);*
 * </tt>
 * \returns
 */
LTFAT_API int
LTFAT_NAME(dgt_execute_ana_newarray)(LTFAT_NAME(dgt_plan)* p,
                                     const LTFAT_TYPE f[], LTFAT_COMPLEX c[]);

/** Perform DGT analysis
 *
 *  N = L/a
 *
 * \param[in]    p  Transform plan
 * \param[in]    f  Input signal, size L x W
 * \param[out]   c  Coefficients, size M x N x W
 *
 * #### Versions #
 * <tt>
 * ltfat_dgt_execute_ana_d(ltfat_dgt_plan_d* p);
 *
 * ltfat_dgt_execute_ana_s(ltfat_dgt_plan_s* p);
 *
 * ltfat_dgt_execute_ana_dc(ltfat_dgt_plan_dc* p);
 *
 * ltfat_dgt_execute_ana_sc(ltfat_dgt_plan_s* p);
 * </tt>
 * \returns
 */
LTFAT_API int
LTFAT_NAME(dgt_execute_ana)(LTFAT_NAME(dgt_plan)* p);

/** Destroy transform plan
 *
 * \param[in]   p  Transform plan
 *
 * #### Versions #
 * <tt>
 * ltfat_dgt_done_d(ltfat_dgt_plan_d** p);
 *
 * ltfat_dgt_done_s(ltfat_dgt_plan_s** p);
 *
 * ltfat_dgt_done_dc(ltfat_dgt_plan_dc** p);
 *
 * ltfat_dgt_done_sc(ltfat_dgt_plan_sc** p);
 * </tt>
 * \returns
 */
LTFAT_API int
LTFAT_NAME(dgt_done)(LTFAT_NAME(dgt_plan)** p);

LTFAT_API ltfat_int
LTFAT_NAME(dgt_get_M)(LTFAT_NAME(dgt_plan)* p);

LTFAT_API ltfat_int
LTFAT_NAME(dgt_get_a)(LTFAT_NAME(dgt_plan)* p);

LTFAT_API ltfat_int
LTFAT_NAME(dgt_get_W)(LTFAT_NAME(dgt_plan)* p);

LTFAT_API ltfat_int
LTFAT_NAME(dgt_get_L)(LTFAT_NAME(dgt_plan)* p);

LTFAT_API int
LTFAT_NAME(dgt_get_phaseconv)(LTFAT_NAME(dgt_plan)* p);
/** @} */
/** @} */

int
LTFAT_NAME(idgt_long_execute_wrapper)(void* plan, const LTFAT_COMPLEX* c,
        ltfat_int L, ltfat_int W, LTFAT_COMPLEX* f);

int
LTFAT_NAME(dgt_long_execute_wrapper)(void* plan, const LTFAT_TYPE* f,
        ltfat_int L, ltfat_int W, LTFAT_COMPLEX* c);

int
LTFAT_NAME(idgt_fb_execute_wrapper)(void* plan, const LTFAT_COMPLEX* c, ltfat_int L,
        ltfat_int W, LTFAT_COMPLEX* f);

int
LTFAT_NAME(dgt_fb_execute_wrapper)(void* plan, const LTFAT_TYPE* f, ltfat_int L, ltfat_int W,
        LTFAT_COMPLEX* c);

int
LTFAT_NAME(idgt_long_done_wrapper)(void** plan);

int
LTFAT_NAME(dgt_long_done_wrapper)(void** plan);

int
LTFAT_NAME(idgt_fb_done_wrapper)(void** plan);

int
LTFAT_NAME(dgt_fb_done_wrapper)(void** plan);
