LTFAT_API LTFAT_TYPE*
LTFAT_NAME(malloc)(size_t n);

LTFAT_API LTFAT_TYPE*
LTFAT_NAME(calloc)(size_t n);

LTFAT_API LTFAT_TYPE*
LTFAT_NAME(realloc)(LTFAT_TYPE *ptr, size_t nold, size_t nnew);

LTFAT_API LTFAT_TYPE*
LTFAT_NAME(postpad) (LTFAT_TYPE* ptr, size_t nold, size_t nnew);
