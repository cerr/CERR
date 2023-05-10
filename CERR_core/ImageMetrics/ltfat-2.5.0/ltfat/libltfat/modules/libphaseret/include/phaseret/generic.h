#ifndef _phaseret_generic_h
#define _phaseret_generic_h

#ifndef NOSYSTEMHEADERS
#include <stddef.h>
#include "ltfat.h"
#endif

typedef struct phaseret_binentry phaseret_binentry;
typedef struct phaseret_releasebin phaseret_releasebin;

typedef int
phaseret_destructor(void** p);

typedef enum
{
    phaseret_binentry_free,
    phaseret_binentry_destroy
} phaseret_binentry_type;

struct phaseret_binentry
{
    void** entry;
    phaseret_destructor* destructor;
};

struct phaseret_releasebin
{
    phaseret_binentry* bin;
    size_t binSize;
    size_t actSize;
};

phaseret_releasebin*
phaseret_releasebin_init(size_t initsize)
{
    phaseret_releasebin* bin = (phaseret_releasebin*) malloc(sizeof * bin);
    bin->bin = (phaseret_binentry*) calloc(initsize, sizeof * bin->bin);
    bin->binSize = initsize;
    bin->actSize = 0;
    return bin;
}

    int
phaseret_releasebin_add(phaseret_releasebin* bin, phaseret_binentry item)
{
    if (bin->actSize == bin->binSize)
    {
        bin->binSize *= 2;
        bin->bin = realloc(bin->bin, bin->binSize * sizeof * bin->bin);
    }

    bin->bin[bin->actSize] = item;
    bin->actSize++;

    return 0;
}

#define PHASERET_RELEASEBIN_ADDMORE(bin,...) do{ \
    phaseret_binentry list[] = {(phaseret_binentry)0,__VA_ARGS__}; \
    size_t len = sizeof(list)/sizeof(*list) - 1; \
    for(size_t ii=0;ii<len;ii++) phaseret_releasebin_add_memory_memory(bin,list[ii+1]); \
}while(0)

int
phaseret_releasebin_add_memory(phaseret_releasebin* bin, void* item)
{
    phaseret_binentry entry = { &item, NULL};
    phaseret_releasebin_add(bin, entry );
    return 0;
}

int
phaseret_releasebin_add_array(phaseret_releasebin* bin, void** items, size_t itemsSize)
{
    for(size_t ii=0;ii<itemsSize;ii++)
    {
        phaseret_binentry entry = { &items[ii], NULL};
        phaseret_releasebin_add(bin, entry );
    }
    phaseret_binentry entry = { items, NULL};
    phaseret_releasebin_add(bin, entry );

    return 0;
}

int
phaseret_releasebin_add_plan(phaseret_releasebin* bin, void* item, phaseret_destructor* destructor)
{
    phaseret_binentry entry = { &item, destructor};
    phaseret_releasebin_add(bin, entry );
    return 0;
}



int
phaseret_releasebin_releaseitems(phaseret_releasebin* bin)
{
    for (size_t ii = 0; ii < bin->binSize; ii++)
    {
        if (*bin->bin[ii].entry)
        {
            if (bin->bin[ii].destructor)
                bin->bin[ii].destructor(bin->bin[ii].entry);
            else
                ltfat_free(*bin->bin[ii].entry);
        }
    }
    return 0;
}

int
phaseret_releasebin_done(phaseret_releasebin* bin)
{
    phaseret_releasebin_releaseitems(bin);
    free(bin->bin);
    free(bin);
    return 0;
}



#endif
