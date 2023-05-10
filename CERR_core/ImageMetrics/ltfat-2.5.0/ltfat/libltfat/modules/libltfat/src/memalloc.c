#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/memalloc.h"

#ifdef FFTW
#include "ltfat/thirdparty/fftw3.h"
#endif

#include <stdlib.h>
/* #include "ltfat/macros.h" */


void* (*ltfat_custom_malloc)(size_t) = NULL;
void (*ltfat_custom_free)(void*) = NULL;

ltfat_memory_handler_t
ltfat_set_memory_handler (ltfat_memory_handler_t new_handler)
{
    ltfat_memory_handler_t retVal = { ltfat_custom_malloc, ltfat_custom_free };

    ltfat_custom_malloc = new_handler.malloc;
    ltfat_custom_free = new_handler.free;
    return retVal;
}

#ifdef KISS
#define ALIGNBOUNDARY 64

static void*
ltfat_aligned_malloc(size_t size)
{
    void* mem = malloc(size + sizeof(void*) + ALIGNBOUNDARY - 1);
    void* ptr = (void**)
                (((size_t)mem + (ALIGNBOUNDARY - 1) + sizeof(void*)) &
                 ~(ALIGNBOUNDARY - 1));

    ((void**) ptr)[-1] = mem;
    return ptr;
}

static void
ltfat_aligned_free(void* ptr)
{
    free(((void**) ptr)[-1]);
}
#endif

LTFAT_API void*
ltfat_malloc (size_t n)
{
    void* outp;

    if (ltfat_custom_malloc)
        outp = (*ltfat_custom_malloc)(n);
    else
#ifdef FFTW
        outp = LTFAT_FFTW(malloc)(n);
#elif KISS
        outp = ltfat_aligned_malloc(n);
#else
#error "No FFT backend specified. Use -DKISS or -DFFTW"
#endif
    return outp;
}


LTFAT_API void*
ltfat_postpad (void* ptr, size_t nold, size_t nnew)
{
    if(!ptr)
        return ltfat_calloc(nnew, 1);

    if (nnew > nold)
    {
        void* outp = ltfat_realloc (ptr, nold, nnew);
        if (!outp) return NULL;

        memset(((unsigned char*)outp) + nold, 0, nnew - nold);
        return outp;
    }
    return ptr;
}

LTFAT_API void*
ltfat_realloc (void* ptr, size_t nold, size_t nnew)
{
    void* outp = ltfat_malloc(nnew);

    if (!outp) return NULL;

    if (ptr)
    {
        memcpy(outp, ptr, nold < nnew ? nold : nnew);
        ltfat_free(ptr);
    }

    return outp;
}

LTFAT_API void*
ltfat_calloc (size_t nmemb, size_t size)
{
    void* outp = ltfat_malloc(nmemb * size);

    if (!outp)
        return NULL;

    memset(outp, 0, nmemb * size);

    return outp;
}

LTFAT_API void
ltfat_free(const void* ptr)
{
    if (ltfat_custom_free)
        (*ltfat_custom_free)((void*)ptr);
    else
#ifdef FFTW
        LTFAT_FFTW(free)((void*)ptr);
#elif KISS
        ltfat_aligned_free((void*)ptr);
#endif
}

LTFAT_API void
ltfat_safefree(const void* ptr)
{
    if (ptr)
        ltfat_free((void*)ptr);
}
