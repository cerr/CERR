/** \defgroup version Version
 *
 *  Utility functions and constants for checking compatibility
 *  of the library and the header.
 *
 * \addtogroup version
 * @{
 */
#ifndef _LTFAT_VERSION_H
#define _LTFAT_VERSION_H

#define LTFAT_VERSION_MAJOR 0
#define LTFAT_VERSION_MINOR 1
#define LTFAT_VERSION_MICRO 0

#ifdef __cplusplus
extern "C"
{
#endif

typedef struct
{
    const char* version;
    const char* build_date;
    const unsigned int major;
    const unsigned int minor;
    const unsigned int micro;
    const int ltfat_int_size;
} ltfat_library_version;

/** \returns Pointer to an internal library version struct
 * (no memory allocation occurs).
 */
LTFAT_API const ltfat_library_version*
ltfat_get_version();

/** \returns 0 if passed version number is not compatible with
 * the binary version.
 * To check the compatibility of your version of ltfat.h with the library 
 * pass LTFAT_VERSION_MAJOR, LTFAT_VERSION_MINOR and LTFAT_VERSION_MICRO.
 */
LTFAT_API int
ltfat_is_compatible_version(unsigned int your_major,
                            unsigned int your_minor,
                            unsigned int your_micro);

/** \returns Size of ltfat_int used in compilation
 */
LTFAT_API int
ltfat_int_size();

/** \returns 0 if \t sizeofyour_ltfat_int is not equal to
 * sizeof(ltfat_int) used in compilation.
 */
LTFAT_API int
ltfat_int_is_compatible(int sizeofyour_ltfat_int);

/** @} */

#ifdef __cplusplus
}  // extern "C"
#endif


#endif
