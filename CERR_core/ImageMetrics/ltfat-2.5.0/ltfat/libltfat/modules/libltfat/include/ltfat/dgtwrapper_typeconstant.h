#ifndef _ltfat_dgtwrapper_typeconstant_h
#define _ltfat_dgtwrapper_typeconstant_h

/** \defgroup dgtwrapper Discrete Gabor Transform analysis-synthesis
*/
typedef struct ltfat_dgt_params ltfat_dgt_params;

/** \addtogroup dgtwrapper
 * @{ */
typedef enum
{
    ltfat_dgt_auto,
    ltfat_dgt_long,
    ltfat_dgt_fb
} ltfat_dgt_hint;

/** \name Parameter setup struct
 * @{ */

/** Allocate dgt_params structure and initialize to default values
 *
 * \warning The structure must be freed using ltfat_dgt_params_free()
 *
 * \returns Allocated struct (or NULL if the memory allocation failed
 * \see ltfat_dgt_params_free
 */
LTFAT_API ltfat_dgt_params*
ltfat_dgt_params_allocdef();

/** Set DGT phase convention
 *
 * \returns
 * Status code          |  Description
 * ---------------------|----------------
 * LTFATERR_SUCESS      |  No error occured
 * LTFATERR_NULLPOINTER |  \a params was NULL
 */
LTFAT_API int
ltfat_dgt_setpar_phaseconv(ltfat_dgt_params* params, ltfat_phaseconvention ptype);

LTFAT_API int
ltfat_dgt_getpar_phaseconv(ltfat_dgt_params* params);

/** Set FFTW flags
 *
 * \returns
 * Status code          |  Description
 * ---------------------|----------------
 * LTFATERR_SUCESS      |  No error occured
 * LTFATERR_NULLPOINTER |  \a params was NULL
 */
LTFAT_API int
ltfat_dgt_setpar_fftwflags(ltfat_dgt_params* params, unsigned fftw_flags);

/** Set algorithm hint
 *
 * \returns
 * Status code          |  Description
 * ---------------------|----------------
 * LTFATERR_SUCESS      |  No error occured
 * LTFATERR_NULLPOINTER |  \a params was NULL
 */
LTFAT_API int
ltfat_dgt_setpar_hint(ltfat_dgt_params* params, ltfat_dgt_hint hint);

LTFAT_API int
ltfat_dgt_setpar_synoverwrites(ltfat_dgt_params* params, int do_synoverwrites);

/** Destroy struct
 *
 * \returns
 * Status code          |  Description
 * ---------------------|----------------
 * LTFATERR_SUCESS      |  No error occured
 * LTFATERR_NULLPOINTER |  \a params was NULL
 */
LTFAT_API int
ltfat_dgt_params_free(ltfat_dgt_params* params);

/** @} */
/** @} */

// The following function is not part of API
int
ltfat_dgt_params_defaults(ltfat_dgt_params* params);

#endif
