typedef struct LTFAT_NAME(heap) LTFAT_NAME(heap);

LTFAT_API LTFAT_NAME(heap)*
LTFAT_NAME(heap_init)(ltfat_int initmaxsize, const LTFAT_REAL* s);

LTFAT_API const LTFAT_REAL*
LTFAT_NAME(heap_getdataptr)(LTFAT_NAME(heap)* h);

LTFAT_API void
LTFAT_NAME(heap_done)(LTFAT_NAME(heap)* h);

LTFAT_API void
LTFAT_NAME(heap_grow)(LTFAT_NAME(heap)* h, int factor);

LTFAT_API void
LTFAT_NAME(heap_reset)(LTFAT_NAME(heap)* h, const LTFAT_REAL* news);

LTFAT_API ltfat_int
LTFAT_NAME(heap_get)(LTFAT_NAME(heap) *h);

LTFAT_API ltfat_int
LTFAT_NAME(heap_delete)(LTFAT_NAME(heap) *h);

LTFAT_API void
LTFAT_NAME(heap_insert)(LTFAT_NAME(heap) *h, ltfat_int key);
