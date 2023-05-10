#include "ltfat.h"
#include "ltfat/types.h"

LTFAT_API LTFAT_TYPE*
LTFAT_NAME(malloc) (size_t n)
{
    return (LTFAT_TYPE*)ltfat_malloc(n * sizeof(LTFAT_TYPE));
}

LTFAT_API LTFAT_TYPE*
LTFAT_NAME(realloc) (LTFAT_TYPE* ptr, size_t nold, size_t nnew)
{
    return (LTFAT_TYPE*)ltfat_realloc(ptr, nold * sizeof(LTFAT_TYPE), nnew * sizeof(LTFAT_TYPE));
}

LTFAT_API LTFAT_TYPE*
LTFAT_NAME(postpad) (LTFAT_TYPE* ptr, size_t nold, size_t nnew)
{
    return (LTFAT_TYPE*)ltfat_postpad(ptr, nold * sizeof(LTFAT_TYPE), nnew * sizeof(LTFAT_TYPE));
}

LTFAT_API LTFAT_TYPE*
LTFAT_NAME(calloc) (size_t n)
{
    return (LTFAT_TYPE*) ltfat_calloc( n, sizeof(LTFAT_TYPE));
}
