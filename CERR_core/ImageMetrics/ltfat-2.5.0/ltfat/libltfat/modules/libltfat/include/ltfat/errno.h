/** \defgroup error Error handling
 *
 * Errors are negative numbers. Positive numbers are reserved for
 * other purposes (like returning number of samples written)
 *
 * \addtogroup error
 * @{
 */

#ifndef _LTFAT_ERRNO_H
#define _LTFAT_ERRNO_H
#include "basicmacros.h"

enum ltfaterr_status
{
// General
    LTFATERR_SUCCESS        =     0,
    LTFATERR_FAILED         =    -1,
    LTFATERR_NOMEM          =    -2,
    LTFATERR_INITFAILED     =    -3,
    LTFATERR_NULLPOINTER    =    -4,
    LTFATERR_EMPTY          =    -5,
    LTFATERR_BADARG         =    -6,
    LTFATERR_NOTPOSARG      =    -7,
    LTFATERR_NOTINRANGE     =    -8,
    LTFATERR_OVERFLOW       =    -9,
    LTFATERR_UNDERFLOW      =   -10,
    LTFATERR_CANNOTHAPPEN   =   -11,
    LTFATERR_BADSIZE        =   -12, // Array size is wrong
    LTFATERR_BADREQSIZE     =   -13, // Output array size is wrong
    LTFATERR_NOTSUPPORTED   =   -14,
// Specific
    LTFATERR_BADTRALEN      =   -99,
    LTFATERR_NOTAFRAME      =  -100,
    LTFATERR_NOTPAINLESS    =  -101,
    LTFATERR_NOTPOSDEFMATRIX=  -102,
// Missing components
    LTFATERR_NOBLASLAPACK   =  -200
};


/** Function signature for a custom error handler
 *
 * \param[in]   ltfat_errno    Status code of the error
 * \param[in]          file    Filename
 * \param[in]          line    Line
 * \param[in]      funcname    Function name
 * \param[out]       reason    Error message
 */
typedef void ltfat_error_handler_t (int ltfat_errno, const char* file, int line,
                                    const char* funcname, const char* reason);


/** Register a new error handler
 *
 * Default error handling behavior can be recovered by passing NULL.
 * \returns Old error handler
 */
LTFAT_API ltfat_error_handler_t*
ltfat_set_error_handler (ltfat_error_handler_t* new_handler);

/** Disable error handling
 * \returns Old error handler
 */
LTFAT_API ltfat_error_handler_t*
ltfat_set_error_handler_off (void);

/** @} */

LTFAT_API void
ltfat_error (int ltfat_errno,  const char * file, int line,
             const char* funcname, const char * format, ...);


#endif
