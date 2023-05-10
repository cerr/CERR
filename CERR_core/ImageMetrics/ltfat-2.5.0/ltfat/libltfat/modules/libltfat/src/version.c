#include "ltfat.h"
#include "ltfat/macros.h"

#define LTFAT_MAKEVESRIONSTRING(major,minor,patch) #major "." #minor "." #patch
#define LTFAT_VERSIONSTRING(major,minor,patch) LTFAT_MAKEVESRIONSTRING(major,minor,patch)


static const ltfat_library_version ltfat_version =
{
    LTFAT_VERSIONSTRING(LTFAT_VERSION_MAJOR,LTFAT_VERSION_MINOR,LTFAT_VERSION_PATCH),
    __DATE__  " "  __TIME__,
    LTFAT_VERSION_MAJOR, LTFAT_VERSION_MINOR , LTFAT_VERSION_MICRO, sizeof(ltfat_int)
};

LTFAT_API const ltfat_library_version*
ltfat_get_version()
{
    return &ltfat_version;
}

LTFAT_API int
ltfat_is_compatible_version(unsigned int your_major,
                            unsigned int UNUSED(your_minor),
                            unsigned int UNUSED(your_micro))
{
    const ltfat_library_version* dll_version = ltfat_get_version();
    return (int) ( dll_version->major == your_major);
}

LTFAT_API int
ltfat_int_size()
{
    return sizeof(ltfat_int);
}

LTFAT_API int
ltfat_int_is_compatible(int sizeofyourint)
{
    return ltfat_int_size() == sizeofyourint;
}

