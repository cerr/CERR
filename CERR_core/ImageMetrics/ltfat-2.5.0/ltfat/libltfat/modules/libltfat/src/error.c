#include "ltfat.h"
#include "ltfat/errno.h"
#include "ltfat/macros.h"
#include "stdarg.h"

/* Global custom error handler */
ltfat_error_handler_t* ltfat_error_handler = NULL;

static void
no_error_handler ( int UNUSED(ltfat_errno), const char* UNUSED(file),
                   int UNUSED(line), const char* UNUSED(funcname),
                   const char* UNUSED(reason) ) {}

LTFAT_API void
ltfat_error (int ltfat_errno, const char* file, int line,
             const char* funcname, const char* format, ...)
{
    // Shortcut when no_error_handler is used
    if (ltfat_error_handler && ltfat_error_handler == no_error_handler )
        return;

    // Print to a string
    char reason[500] = {0};

    va_list ap;
    va_start (ap, format);
    vsnprintf(reason, 500, format, ap );
    va_end(ap);

    // Call the registered error handler or do the default behavior
    if (ltfat_error_handler)
    {
        (*ltfat_error_handler) (ltfat_errno, file, line, funcname, reason );
    }
    else
    {
        fprintf (stderr, "[ERROR %d]: (%s:%d): [%s]: %s\n", -ltfat_errno, file, line,
                 funcname, reason);

        fflush (stderr);
    }
}

LTFAT_API ltfat_error_handler_t*
ltfat_set_error_handler (ltfat_error_handler_t* new_handler)
{
    ltfat_error_handler_t* previous_handler = ltfat_error_handler;
    ltfat_error_handler = new_handler;
    return previous_handler;
}

LTFAT_API ltfat_error_handler_t*
ltfat_set_error_handler_off (void)
{
    ltfat_error_handler_t* previous_handler = ltfat_error_handler;
    ltfat_error_handler = no_error_handler;
    return previous_handler;
}

