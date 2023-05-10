/** \defgroup multidgtrealmp Matching pursuit with Multi-Gabor Dictionaries 
 *
 *
 * */
typedef struct LTFAT_NAME(dgtrealmp_state) LTFAT_NAME(dgtrealmp_state);
typedef struct LTFAT_NAME(dgtrealmp_parbuf) LTFAT_NAME(dgtrealmp_parbuf);

#ifndef _LTFAT_DGTREALMP_H
#define _LTFAT_DGTREALMP_H

/** \addtogroup multidgtrealmp  */
/**@{*/
enum ltfat_dgtmp_status
{
    LTFAT_DGTREALMP_STATUS_TOLREACHED   = 0,
    LTFAT_DGTREALMP_STATUS_MAXATOMS     = 1,
    LTFAT_DGTREALMP_STATUS_MAXITER      = 2,
    LTFAT_DGTREALMP_STATUS_STALLED      = 3,
    LTFAT_DGTREALMP_STATUS_ATPRODTOL    = 4,
    LTFAT_DGTREALMP_STATUS_EMPTY        = 5,
    LTFAT_DGTREALMP_STATUS_LOCOMP_NOTHERM = 6,
    LTFAT_DGTREALMP_STATUS_LOCOMP_ORTHFAILED = 7,
    LTFAT_DGTREALMP_STATUS_CANCONTINUE  = 100
};
/**@}*/

typedef enum
{
    ltfat_dgtmp_alg_mp              = 0,
    ltfat_dgtmp_alg_locomp          = 1,
    ltfat_dgtmp_alg_loccyclicmp     = 2,
    ltfat_dgtmp_alg_locselfprojmp   = 3,
} ltfat_dgtmp_alg;

typedef struct ltfat_dgtmp_params ltfat_dgtmp_params;

LTFAT_API ltfat_dgtmp_params*
ltfat_dgtmp_params_allocdef();

LTFAT_API int
ltfat_dgtmp_params_free(ltfat_dgtmp_params* params);

LTFAT_API int
ltfat_dgtmp_setpar_phaseconv(
    ltfat_dgtmp_params* params, ltfat_phaseconvention pconv);

// LTFAT_API int
// ltfat_dgtmp_setpar_hint(
//     ltfat_dgtmp_params* params, ltfat_dgtmp_hint hint);

LTFAT_API int
ltfat_dgtmp_setpar_atprodreltoldb(ltfat_dgtmp_params* params,
                                  double atprodreltoldb);

LTFAT_API int
ltfat_dgtmp_setpar_alg(
    ltfat_dgtmp_params* params, ltfat_dgtmp_alg alg);

LTFAT_API int
ltfat_dgtmp_setpar_maxatoms(
    ltfat_dgtmp_params* params, size_t maxatoms);

LTFAT_API int
ltfat_dgtmp_setpar_maxit(
    ltfat_dgtmp_params* params, size_t maxit);

LTFAT_API int
ltfat_dgtmp_setpar_kernrelthr(
    ltfat_dgtmp_params* p, double thr);

LTFAT_API int
ltfat_dgtmp_setpar_iterstep(
    ltfat_dgtmp_params* p, size_t iterstep);

LTFAT_API int
ltfat_dgtmp_setpar_errtoldb(
    ltfat_dgtmp_params* p, double errtoldb);

LTFAT_API int
ltfat_dgtmp_setpar_snrdb(
    ltfat_dgtmp_params* params, double snrdb);

LTFAT_API int
ltfat_dgtmp_setpar_pedanticsearch(
    ltfat_dgtmp_params* params, int do_pedanticsearch);

LTFAT_API int
ltfat_dgtmp_setpar_cycles(
        ltfat_dgtmp_params* params, size_t cycles);

// LTFAT_API int
// ltfat_dgtmp_setpar_checkerreverynit(
//     ltfat_dgtmp_params* p, ltfat_int itstep, double errtoldb);

int
ltfat_dgtmp_params_defaults(ltfat_dgtmp_params* params);

// int
// ltfat_dgtmp_hint_isvalid(ltfat_dgtmp_hint in);

int
ltfat_dgtmp_alg_isvalid(ltfat_dgtmp_alg in);

#endif

/** \addtogroup multidgtrealmp  */
/**@{*/

/** Callback template to be called every iterstep iteration.
 * \a c
 *
 * \see dgtrealmp_setparbuf_iterstep dgtrealmp_setparbuf_iterstepcallback dgtrealmp_get_dictno dgtrealmp_get_coefdims
 *
 * \param[in,out]  userdata   User defined struct
 * \param[in]      state      State struct
 * \param[in,out]  c          Selected coefficients
 *
 * #### Versions #
 * <tt>
 * typedef int 
 * ltfat_dgtrealmp_iterstep_callback_d(void* userdata, 
 *      ltfat_dgtrealmp_state_d* state, ltfat_complex_d* c[]);
 *
 * typedef int
 * ltfat_dgtrealmp_iterstep_callback_s(void* userdata, 
 *      ltfat_dgtrealmp_state_s* state, ltfat_complex_s* c[]);
 * </tt>
 * \returns Status code: =0 continue iterations, >0 stop, <0 stop with error
 */
typedef int
LTFAT_NAME(dgtrealmp_iterstep_callback)(
        void* userdata, LTFAT_NAME(dgtrealmp_state)* state,
        LTFAT_COMPLEX* c[]);

/** \name Basic interface */
/**@{*/

/** Initialize the DGTREAL Matching Pursuit state
 *
 * The signal length \a L must be compatible with the dictionaries defined in \a pb.
 * Having a signal of length \a Ls, one can get the next bigger compatible length \a L
 * using dgtrealmp_getparbuf_siglen()
 * 
 * \param[in]   pb  Parameter buffer
 * \param[in]    L  Signal length
 * \param[out]   p  DGTREALMP state
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_init_d( ltfat_dgtrealmp_parbuf_d* pb, ltfat_int L, ltfat_dgtrealmp_state_d** p);
 *
 * ltfat_dgtrealmp_init_s( ltfat_dgtrealmp_parbuf_s* pb, ltfat_int L, ltfat_dgtrealmp_state_s** p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a pb, \a p
 * LTFATERR_BADSIZE         | Length of the window \a gl was less or equal to 0.
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_init)(
    LTFAT_NAME(dgtrealmp_parbuf)* pb, ltfat_int L, LTFAT_NAME(dgtrealmp_state)** p);

/** Execute DGTREAL Matching Pursuit
 *
 * \param[in,out]    p DGTREALMP state
 * \param[in]        f Input signal, array of length L
 * \param[out]    cout Output coefficients, array of length equal to the number of dictionaries
 * \param[out]    fout Output signal, array of length L
 *
 * The required size of an array cout[dictid] can be obtained from dgtrealmp_getparbuf_coeflen(),
 * individual dimensions from dgtrealmp_get_coefdims()
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_execute_d( ltfat_dgtrealmp_state_d* p, const double f[],
 *                            ltfat_complex_d* cout[], double fout[]);
 *
 * ltfat_dgtrealmp_execute_s( ltfat_dgtrealmp_state_s* p, const float f[],
 *                            ltfat_complex_s* cout[], float fout[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a pb, \a p
 * LTFATERR_BADSIZE         | Length of the window \a gl was less or equal to 0.
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_execute)(
    LTFAT_NAME(dgtrealmp_state)* p, const LTFAT_REAL f[],
    LTFAT_COMPLEX* cout[], LTFAT_REAL fout[]);

/** Delete DGTREAL Matching Pursuit state
 *
 * \param[in]   p  DGTREALMP state
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_done_d( ltfat_dgtrealmp_parbuf_d** pb);
 *
 * ltfat_dgtrealmp_done_s( ltfat_dgtrealmp_parbuf_s** pb);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | \a p is NULL
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_done)(LTFAT_NAME(dgtrealmp_state)** p);

/**@}*/

/** \name Advanced interface */
/**@{*/

/** Execute DGTREAL Matching Pursuit with flat coefficient layout.
 *
 * \param[in,out]    p DGTREALMP state
 * \param[in]        f Input signal, length L
 * \param[out]    cout Output coefficients, length obtainable from dgtrealmp_getparbuf_coeflen_compact()
 * \param[out]    fout Output signal, length L 
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_execute_compact_d( ltfat_dgtrealmp_state_d* p, const double f[],
 *                                    ltfat_complex_d cout[], double fout[]);
 *
 * ltfat_dgtrealmp_execute_compact_s( ltfat_dgtrealmp_state_s* p, const float f[],
 *                                    ltfat_complex_s cout[], float fout[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a pb, \a p
 * LTFATERR_BADSIZE         | Length of the window \a gl was less or equal to 0.
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_execute_compact)(
        LTFAT_NAME(dgtrealmp_state)* p, const LTFAT_REAL f[],
        LTFAT_COMPLEX cout[], LTFAT_REAL fout[]);

/** Perform DGTREAL Matching Pursuit decomposition
 *
 * \param[in,out]    p DGTREALMP state
 * \param[in]        f Input signal, length L
 * \param[out]    cout Output coefficients, array of length equal to the number of dictionaries
 *
 * The required size of an array cout[dictid] can be obtained from dgtrealmp_getparbuf_coeflen(),
 * individual dimensions from dgtrealmp_get_coefdims()
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_execute_decompose_d( ltfat_dgtrealmp_state_d* p, 
 *                                      const double f[], ltfat_complex_d* c[]);
 *
 * ltfat_dgtrealmp_execute_decompose_s( ltfat_dgtrealmp_state_s* p, 
 *                                      const float f[], ltfat_complex_s* c[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a pb, \a p
 * LTFATERR_BADSIZE         | Length of the window \a gl was less or equal to 0.
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_execute_decompose)(
    LTFAT_NAME(dgtrealmp_state)* p, const LTFAT_REAL f[], LTFAT_COMPLEX* c[]);

/** Perform Multi-DGTREAL synthesis
 *
 * \param[in,out]        p DGTREALMP state
 * \param[in]            c Input coefficients, array of length equal to the number of dictionaries
 * \patam[in]    dict_mask Dictionary mask. NULL or array of length equal to the number of dictionaries.
 * \param[out]           f Output signal, length L 
 *
 * The function will synthesize only from dictionary coefficients for which \a dict_mask[dictid]
 * is not 0. If NULL all coefficients are used. 
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_execute_synthesize_d( ltfat_dgtrealmp_state_d* p, 
 *                                       const ltfat_complex_d* cout[],
 *                                       int dict_mask[], double f[]);
 *
 * ltfat_dgtrealmp_execute_synthesize_s( ltfat_dgtrealmp_state_s* p, 
 *                                       const ltfat_complex_s* cout[], 
 *                                       int dict_mask[], float f[]);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a pb, \a p
 * LTFATERR_BADSIZE         | Length of the window \a gl was less or equal to 0.
 * LTFATERR_NOMEM           | Indicates that heap allocation failed
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_execute_synthesize)(
    LTFAT_NAME(dgtrealmp_state)* p, const LTFAT_COMPLEX* c[], int dict_mask[], LTFAT_REAL f[]);

/** @}*/

/***********************************************************************/

/** \name Parameter setup struct */
/**@{*/

/** Initialize the parameter buffer with default values and no dictionary
 *
 * The default values are: 
 *  - Target SNR: 40 dB
 *  - Kernel relative threshold: 1e-4
 *  - Inner product relative tolerance: 80 dB
 *  - Phase convention: LTFAT_TIMEINV
 *  - Pedantic search: disabled
 *  - Max. number of iterations: 0.8*L
 *  - Max. number of atoms: 0.8*L
 *
 * \param[in]   p  DGTREALMP parameter buffer
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_parbuf_init_d( ltfat_dgtrealmp_parbuf_d** p);
 *
 * ltfat_dgtrealmp_parbuf_init_s( ltfat_dgtrealmp_parbuf_s** p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_init)( LTFAT_NAME(dgtrealmp_parbuf)** p);

/** Delete  DGTREALMP parameter buffer
 *
 * \param[in]   parbuf  DGTREALMP parameter buffer
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_parbuf_done_d( ltfat_dgtrealmp_parbuf_d** parbuf);
 *
 * ltfat_dgtrealmp_parbuf_done_s( ltfat_dgtrealmp_parbuf_s** parbuf);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_done)( LTFAT_NAME(dgtrealmp_parbuf)** p);

/** Add new Gabor dictionary
 *
 * \param[in]   parbuf  DGTREALMP parameter buffer
 * \param[in]      win  Window from enum ::LTFAT_FIRWIN
 * \param[in]       gl  Length of the window
 * \param[in]        a  Time hop factor
 * \param[in]        M  Number of frequency channels
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_parbuf_add_firwin_d( ltfat_dgtrealmp_parbuf_d* parbuf,
 *                                      LTFAT_FIRWIN win, ltfat_int gl, 
 *                                      ltfat_int a, ltfat_int M );
 *
 * ltfat_dgtrealmp_parbuf_add_firwin_s( ltfat_dgtrealmp_parbuf_s* parbuf,
 *                                      LTFAT_FIRWIN win, ltfat_int gl, 
 *                                      ltfat_int a, ltfat_int M );
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_add_firwin)(
        LTFAT_NAME(dgtrealmp_parbuf)* parbuf,
        LTFAT_FIRWIN win, ltfat_int gl, ltfat_int a, ltfat_int M);

/** Add new Gabor dictionary with truncated Gaussian window fitted to the sampling lattice
 *
 * \param[in]   parbuf  DGTREALMP parameter buffer
 * \param[in]        a  Time hop factor
 * \param[in]        M  Number of frequency channels
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_parbuf_add_gausswin_d( ltfat_dgtrealmp_parbuf_d* parbuf,
 *                                      ltfat_int a, ltfat_int M );
 *
 * ltfat_dgtrealmp_parbuf_add_gausswin_s( ltfat_dgtrealmp_parbuf_s* parbuf,
 *                                      ltfat_int a, ltfat_int M );
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_add_gausswin)(
        LTFAT_NAME(dgtrealmp_parbuf)* parbuf, ltfat_int a, ltfat_int M);

/** Add new general Gabor dictionary
 *
 * \param[in]   parbuf  DGTREALMP parameter buffer
 * \param[in]        g  Window
 * \param[in]       gl  Length of the window
 * \param[in]        a  Time hop factor
 * \param[in]        M  Number of frequency channels
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_parbuf_add_genwin_d( ltfat_dgtrealmp_parbuf_d* parbuf,
 *                                      double g[], ltfat_int gl, 
 *                                      ltfat_int a, ltfat_int M );
 *
 * ltfat_dgtrealmp_parbuf_add_genwin_s( ltfat_dgtrealmp_parbuf_s* parbuf,
 *                                      float g[], ltfat_int gl, 
 *                                      ltfat_int a, ltfat_int M );
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_add_genwin)(
        LTFAT_NAME(dgtrealmp_parbuf)* parbuf,
        const LTFAT_REAL g[], ltfat_int gl, ltfat_int a, ltfat_int M);

/** Get the number of dictionaries
 *
 * \param[in]   p  DGTREALMP parameter buffer
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_getparbuf_dictno_d( ltfat_dgtrealmp_parbuf_d* p);
 *
 * ltfat_dgtrealmp_getparbuf_dictno_s( ltfat_dgtrealmp_parbuf_s* p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API ltfat_int
LTFAT_NAME(dgtrealmp_getparbuf_dictno)( LTFAT_NAME(dgtrealmp_parbuf) * p);

/** Get next compatible signal length
 *
 * \param[in]   p  DGTREALMP parameter buffer
 * \param[in]  Ls  Signal length
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_getparbuf_siglen_d( ltfat_dgtrealmp_parbuf_d* p, ltfat_int Ls);
 *
 * ltfat_dgtrealmp_getparbuf_siglen_s( ltfat_dgtrealmp_parbuf_s* p, ltfat_int Ls);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API ltfat_int
LTFAT_NAME(dgtrealmp_getparbuf_siglen)(
    LTFAT_NAME(dgtrealmp_parbuf)* p, ltfat_int Ls);

/** Returns the length of the array to hold output coefficients for
 * dictionary \a dictid
 *
 * \param[in]      p  DGTREALMP parameter buffer
 * \param[in]     Ls  Signal length
 * \param[in] dictid  Dictionary id
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_getparbuf_coeflen_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                      ltfat_int Ls, ltfat_int dictid);
 *
 * ltfat_dgtrealmp_getparbuf_coeflen_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                      ltfat_int Ls, ltfat_int dictid);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API ptrdiff_t
LTFAT_NAME(dgtrealmp_getparbuf_coeflen)(
    LTFAT_NAME(dgtrealmp_parbuf) * p, ltfat_int Ls, ltfat_int dictid);

/** Returns the length of the array to hold output coefficients for
 * all dictionaries. This is useful with the *_compact function.  
 *
 * \param[in]      p  DGTREALMP parameter buffer
 * \param[in]     Ls  Signal length
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_getparbuf_coeflen_compact_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                              ltfat_int Ls);
 *
 * ltfat_dgtrealmp_getparbuf_coeflen_compact_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                              ltfat_int Ls);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API ptrdiff_t
LTFAT_NAME(dgtrealmp_getparbuf_coeflen_compact)(
    LTFAT_NAME(dgtrealmp_parbuf) * p, ltfat_int Ls);

// LTFAT_API int
// LTFAT_NAME(dgtrealmp_parbuf_add_hermwin)(
//         LTFAT_NAME(dgtrealmp_parbuf)* parbuf,
//         ltfat_int order, LTFAT_REAL tfr, ltfat_int a, ltfat_int M);

/** Set coefficient phase convention.
 * 
 * \param[in]   parbuf  DGTREALMP parameter buffer 
 * \param[in]    pconv  LTFAT_TIMEINV or LTFAT_FREQINV
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_phaseconv_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                         ltfat_phaseconvention pconv);
 *
 * ltfat_dgtrealmp_setparbuf_phaseconv_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                         ltfat_phaseconvention pconv);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_phaseconv)(
        LTFAT_NAME(dgtrealmp_parbuf)* parbuf, ltfat_phaseconvention pconv);

/** Set relative inner product tolerance in dB
 * 
 * Causes the algorithm to stop whenever the selected inner product becomes 
 * less than \a atprodreltoldb relative to the inner product selected in the first iteration.
 * E.g. -80 dB amouns to the absolute threshold of 10^-4*max(abs(c_0))
 * 
 * \param[in]   parbuf          DGTREALMP parameter buffer 
 * \param[in]   atprodreltoldb  Relative tolerance in dB
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_atprodreltoldb_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                             double atprodreltoldb);
 *
 * ltfat_dgtrealmp_setparbuf_atprodreltoldb_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                             double atprodreltoldb);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_atprodreltoldb)(
        LTFAT_NAME(dgtrealmp_parbuf)* parbuf, double atprodreltoldb);

/** Set maximum number of atoms
 * 
 * \param[in]     parbuf  DGTREALMP parameter buffer 
 * \param[in]   maxatoms  Number of atoms
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_maxatoms_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                       size_t maxatoms);
 *
 * ltfat_dgtrealmp_setparbuf_maxatoms_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                       size_t maxatoms);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_maxatoms)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, size_t maxatoms);

/** Set maximum number of iterations
 * 
 * \param[in]     parbuf  DGTREALMP parameter buffer 
 * \param[in]      maxit  Number of iterations
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_maxit_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                    size_t maxit);
 *
 * ltfat_dgtrealmp_setparbuf_maxit_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                    size_t maxit);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_maxit)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, size_t maxit);

/** Set target normalized MSE in dB
 * 
 * \a errtoldb must be less than 0. 
 * 
 * \param[in]     parbuf  DGTREALMP parameter buffer 
 * \param[in]   errtoldb  MSE in dB
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_errtoldb_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                       double errtoldb);
 *
 * ltfat_dgtrealmp_setparbuf_errtoldb_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                       double errtoldb);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_errtoldb)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, double errtoldb);

/** Set target SNR in dB
 *
 * \a snrdb must be larger than 0.
 * 
 * \param[in]     parbuf  DGTREALMP parameter buffer 
 * \param[in]      snrdb  SNR in dB
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_snrdb_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                       double snrdb);
 *
 * ltfat_dgtrealmp_setparbuf_snrdb_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                       double snrdb);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_snrdb)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, double snrdb);

/** Set kernel relative threshold
 * 
 * \param[in]     parbuf  DGTREALMP parameter buffer 
 * \param[in]        thr  Threshold
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_kernrelthr_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                         double thr);
 *
 * ltfat_dgtrealmp_setparbuf_kernrelthr_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                         double thr);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_kernrelthr)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, double thr);


/** Make the most recently added dictionary tight. 
 *
 * The dictionary must be painless.
 * 
 * \param[in]     parbuf  DGTREALMP parameter buffer 
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_modparbuf_lasttight_d( ltfat_dgtrealmp_parbuf_d* p);
 *
 * ltfat_dgtrealmp_modparbuf_lasttight_s( ltfat_dgtrealmp_parbuf_s* p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_modparbuf_lasttight)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf);


/** Sets iteration step.
 *  Prints results/ calls callback every \a iterstep iterations.
 * 
 * \param[in]     parbuf  DGTREALMP parameter buffer 
 * \param[in]   iterstep  Step
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_iterstep_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                       size_t iterstep);
 *
 * ltfat_dgtrealmp_setparbuf_iterstep_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                       size_t iterstep);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_iterstep)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, size_t iterstep);

/** Register callback function to be called every iterstep iteration 
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_iterstepcallback_d( 
 *      ltfat_dgtrealmp_parbuf_d* p,
 *      ltfat_dgtrealmp_execute_iterstep_callback_d* callback,
 *      void* userdata);
 *
 * ltfat_dgtrealmp_setparbuf_iterstepcallback_s( 
 *      ltfat_dgtrealmp_parbuf_s* p,
 *      ltfat_dgtrealmp_execute_iterstep_callback_s* callback,
 *      void* userdata);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_iterstepcallback)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf,
    LTFAT_NAME(dgtrealmp_iterstep_callback)* callback,
    void* userdata);

/** Enable/disable pedantic search
 * 
 * \param[in]       parbuf  DGTREALMP parameter buffer 
 * \param[in]  do_pedantic  0 - false, anything else - true
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_setparbuf_pedanticsearch_d( ltfat_dgtrealmp_parbuf_d* p,
 *                                             int do_pedantic);
 *
 * ltfat_dgtrealmp_setparbuf_pedanticsearch_s( ltfat_dgtrealmp_parbuf_s* p,
 *                                             int do_pedantic);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_pedanticsearch)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, int do_pedantic);

/* TODO:
LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_mod_chirpmod)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, LTFAT_REAL chirprate);

LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_mod_shiftby)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, LTFAT_REAL frac);

LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_mod_truncat)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, LTFAT_REAL relthr);

LTFAT_API int
LTFAT_NAME(dgtrealmp_parbuf_add_longwin)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf,
    LTFAT_LONGWIN win, LTFAT_REAL damp, ltfat_int a, ltfat_int M);

// Callback allows changing the values of energies of inner products which
// are used in the search for the maximally corellated atom with the residuum.
typedef int LTFAT_NAME(selectionmodcallback)(void* userdata,
        const LTFAT_COMPLEX* in, ltfat_int, ltfat_int, ltfat_int, LTFAT_REAL* out);

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_selectiomodcallback)(
    LTFAT_NAME(dgtrealmp_parbuf)* parbuf, LTFAT_NAME(selectionmodcallback)* callback);
*/

/** @}*/



/** \name Retrieving information from the state
 * @{
 */

/** Get current normalized error 
 * 
 * \param[in]       p  DGTREALMP state
 * \param[out]    err  Error in dB
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_get_errdb_d( ltfat_dgtrealmp_state_d* p, double* err);
 *
 * ltfat_dgtrealmp_get_errdb_s( ltfat_dgtrealmp_state_s* p, double* err);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_get_errdb)(
    const LTFAT_NAME(dgtrealmp_state)* p, double* err);

/** Get current number of selected atoms
 * 
 * \param[in]       p  DGTREALMP state
 * \param[out]  atoms  Number of selected atoms
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_get_numatoms_d( ltfat_dgtrealmp_state_d* p, size_t* atoms);
 *
 * ltfat_dgtrealmp_get_numatoms_s( ltfat_dgtrealmp_state_s* p, size_t* atoms);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p, \a atoms
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_get_numatoms)(
        const LTFAT_NAME(dgtrealmp_state)* p, size_t* atoms);

/** Get current number of iterations done
 * 
 * \param[in]       p  DGTREALMP state
 * \param[out]  iters  Number of iterations done
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_get_numiters_d( ltfat_dgtrealmp_state_d* p, size_t* iters);
 *
 * ltfat_dgtrealmp_get_numiters_s( ltfat_dgtrealmp_state_s* p, size_t* iters);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p, \a atoms
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_get_numiters)(
        const LTFAT_NAME(dgtrealmp_state)* p, size_t* iters);

/** Get pointer to an array of residual coefficients 
 * 
 * \param[in]        p  DGTREALMP state
 * \param[in]   dictid  Dictionary index
 * \param[out]    cres  Pointer to a pointer to be initialized
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_get_rescoefs_d( ltfat_dgtrealmp_state_d* p, 
 *                                 int dictid, ltfat_complex_d** cres);
 *
 * ltfat_dgtrealmp_get_rescoefs_s( ltfat_dgtrealmp_state_s* p,
 *                                 int dictid, ltfat_complex_s** cres);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p, \a M2, \a N
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_get_rescoefs)(
        const LTFAT_NAME(dgtrealmp_state)* p, int dictid,
        LTFAT_COMPLEX** cres);

/** Get dimensions of the coefficient matrix for dictionary dictid
 * 
 * \param[in]        p  DGTREALMP state
 * \param[in]   dictid  Dictionary index
 * \param[out]      M2  Number of rows
 * \param[out]       N  Number of cols
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_get_coefdims_d( ltfat_dgtrealmp_state_d* p, 
 *                                 int dictid, ltfat_int* M2, ltfat_int* N);
 *
 * ltfat_dgtrealmp_get_coefdims_s( ltfat_dgtrealmp_state_s* p,
 *                                 int dictid, ltfat_int* M2, ltfat_int* N);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p, \a M2, \a N
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_get_coefdims)(
        const LTFAT_NAME(dgtrealmp_state)* p, int dictid,
        ltfat_int* M2, ltfat_int* N);

/** Get the number of dictionaries
 *
 * \param[in]   p  DGTREALMP state
 *
 * #### Versions #
 * <tt>
 * ltfat_dgtrealmp_get_dictno_d( ltfat_dgtrealmp_state_d* p);
 *
 * ltfat_dgtrealmp_get_dictno_s( ltfat_dgtrealmp_state_s* p);
 * </tt>
 * \returns
 * Status code              | Description
 * -------------------------|------------
 * LTFATERR_SUCCESS         | Indicates no error
 * LTFATERR_NULLPOINTER     | At least one of the following was NULL: \a p
 */
LTFAT_API ltfat_int
LTFAT_NAME(dgtrealmp_get_dictno)(
        const LTFAT_NAME(dgtrealmp_state)* p);
/** @}*/

/** \name Changing state parameters
 * @{
 */
LTFAT_API int
LTFAT_NAME(dgtrealmp_set_iterstep)(
    LTFAT_NAME(dgtrealmp_state)* p, size_t iterstep);

LTFAT_API int
LTFAT_NAME(dgtrealmp_set_iterstepcallback)(
    LTFAT_NAME(dgtrealmp_state)* p,
    LTFAT_NAME(dgtrealmp_iterstep_callback)* callback, void* userdata);
/** @}*/
/** @}*/

LTFAT_API LTFAT_NAME(dgtreal_plan)**
LTFAT_NAME(dgtrealmp_getdgtrealplan)(LTFAT_NAME(dgtrealmp_state)* p);

LTFAT_API int
LTFAT_NAME(dgtrealmp_getresidualcoef_compact)(
    LTFAT_NAME(dgtrealmp_state)* p, LTFAT_COMPLEX* c);

LTFAT_API int
LTFAT_NAME(dgtrealmp_set_maxatoms)(
    LTFAT_NAME(dgtrealmp_state)* p, size_t maxatoms);

LTFAT_API int
LTFAT_NAME(dgtrealmp_set_errtoldb)(
    LTFAT_NAME(dgtrealmp_state)* p, double errtoldb);

LTFAT_API int
LTFAT_NAME(dgtrealmp_init_gen_compact)(
        const LTFAT_REAL g[], ltfat_int gl[], ltfat_int L, ltfat_int P,
        ltfat_int a[], ltfat_int M[], ltfat_dgtmp_params* params,
        LTFAT_NAME(dgtrealmp_state)** pout);

LTFAT_API int
LTFAT_NAME(dgtrealmp_init_gen)(
        const LTFAT_REAL* g[], ltfat_int gl[], ltfat_int L, ltfat_int P,
        ltfat_int a[], ltfat_int M[], ltfat_dgtmp_params* params,
        LTFAT_NAME(dgtrealmp_state)** p);

LTFAT_API int
LTFAT_NAME(dgtrealmp_execute_niters)(
        LTFAT_NAME(dgtrealmp_state)* p, size_t itno, LTFAT_COMPLEX** cout);

LTFAT_API int
LTFAT_NAME(dgtrealmp_execute_niters_compact)(
        LTFAT_NAME(dgtrealmp_state)* p, size_t itno, LTFAT_COMPLEX* cout);

LTFAT_API int
LTFAT_NAME(dgtrealmp_reset)(
    LTFAT_NAME(dgtrealmp_state)* p, const LTFAT_REAL* f);

LTFAT_API int
LTFAT_NAME(dgtrealmp_revert)(
        LTFAT_NAME(dgtrealmp_state)* p, LTFAT_COMPLEX** cout);

LTFAT_API int
LTFAT_NAME(dgtrealmp_revert_compact)(
        LTFAT_NAME(dgtrealmp_state)* p, LTFAT_COMPLEX* cout);

LTFAT_API int
LTFAT_NAME(dgtrealmp_setparbuf_alg)(
        LTFAT_NAME(dgtrealmp_parbuf)* parbuf, ltfat_dgtmp_alg alg);
