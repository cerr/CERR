#include "mex.h"
#include <stdlib.h>
#include "stddef.h"

void* ltfat_malloc(size_t n)
{
  return mxMalloc(n);
}

void* ltfat_calloc(size_t nmemb, size_t size)
{
  return mxCalloc(nmemb, size);
}

void* ltfat_realloc(void *ptr, size_t n)
{
  return mxRealloc(ptr, n);
}

void ltfat_free(void *ptr)
{
  mxFree(ptr);
}
