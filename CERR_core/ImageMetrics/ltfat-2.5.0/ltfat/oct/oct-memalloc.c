#include <stdlib.h>
#include <stdio.h>
#include "stddef.h"
#include "fftw3.h"

void* ltfat_malloc (size_t n)
{
  void *outp;
  outp = fftw_malloc(n);
  if (outp == NULL)
  {
     puts("ltfat_malloc failed.");
     exit(1);
  }
  return outp;
}

void* ltfat_realloc (void *ptr, size_t n)
{
  void *outp;
  outp = realloc(ptr, n);
  if (outp == NULL)
  {
     puts("ltfat_realloc failed.");
     exit(1);
  }
  return outp;
}

void* ltfat_calloc (size_t nmemb, size_t size)
{
  void *outp;
  outp = calloc(nmemb, size);
  if (outp == NULL)
  {
     puts("ltfat_calloc failed.");
     exit(1);
  }
  return outp;
}

void ltfat_free(void *ptr)
{
  fftw_free(ptr);
}

