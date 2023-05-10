#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

struct LTFAT_NAME(heap)
{
    ltfat_int* h;
    ltfat_int heapsize;
    ltfat_int totalheapsize;
    const LTFAT_REAL* s;
};

LTFAT_API LTFAT_NAME(heap)*
LTFAT_NAME(heap_init)(ltfat_int initmaxsize, const LTFAT_REAL* s)
{
    LTFAT_NAME(heap)* h = (LTFAT_NAME(heap)*) ltfat_malloc(sizeof * h);

    h->totalheapsize  = initmaxsize;
    h->h              = (ltfat_int*) ltfat_malloc(h->totalheapsize * sizeof * h->h);
    h->s              = s;
    h->heapsize       = 0;
    return h;
}

LTFAT_API const LTFAT_REAL*
LTFAT_NAME(heap_getdataptr)(LTFAT_NAME(heap)* h)
{
    return h->s;
}

LTFAT_API void
LTFAT_NAME(heap_done)(LTFAT_NAME(heap)* h)
{
    ltfat_free(h->h);
    ltfat_free(h);
}

LTFAT_API void
LTFAT_NAME(heap_reset)(LTFAT_NAME(heap)* h, const LTFAT_REAL* news)
{
    h->s = news;
    h->heapsize = 0;
}

LTFAT_API void
LTFAT_NAME(heap_grow)(LTFAT_NAME(heap)* h, int factor)
{
    h->totalheapsize *= factor;
    h->h = (ltfat_int*)ltfat_realloc((void*)h->h,
                                    h->totalheapsize * sizeof * h->h / factor,
                                    h->totalheapsize * sizeof * h->h);
}

LTFAT_API void
LTFAT_NAME(heap_insert)(LTFAT_NAME(heap) *h, ltfat_int key)
{
    ltfat_int pos, pos2;

    /* Grow heap if necessary */
    if (h->totalheapsize == h->heapsize)
        LTFAT_NAME(heap_grow)( h, 2);

    pos = h->heapsize;
    h->heapsize++;

    LTFAT_REAL val = h->s[key];

    while (pos > 0)
    {
        /* printf("pos %i\n",pos); */
        pos2 = (pos - 1) >> 1;

        if (h->s[h->h[pos2]] < val )
            h->h[pos] = h->h[pos2];
        else
            break;

        pos = pos2;
    }

    h->h[pos] = key;
}

LTFAT_API ltfat_int
LTFAT_NAME(heap_get)(LTFAT_NAME(heap) *h)
{
    if (h->heapsize == 0) return LTFATERR_UNDERFLOW;
    return h->h[0];
}

LTFAT_API ltfat_int
LTFAT_NAME(heap_delete)(LTFAT_NAME(heap) *h)
{

    ltfat_int pos, pos2, retkey, key;
    LTFAT_REAL maxchildkey, val;

    if (h->heapsize == 0) return LTFATERR_UNDERFLOW;
    /* Extract first element */
    retkey = h->h[0];
    key = h->h[h->heapsize - 1];
    val = h->s[key];

    h->heapsize--;

    pos = 0;
    pos2 = 1;

    while (pos2 < h->heapsize)
    {
        if ( (pos2 + 2 > h->heapsize) ||
             (h->s[h->h[pos2]] >= h->s[h->h[pos2 + 1]]) )
            maxchildkey = h->s[h->h[pos2]];
        else
            maxchildkey = h->s[h->h[++pos2]];

        if (maxchildkey > val)
            h->h[pos] = h->h[pos2];
        else
            break;

        pos = pos2;
        pos2 = (pos << 1) + 1;
    }

    h->h[pos] = key;

    return retkey;
}

