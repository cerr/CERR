#define NORTHFROMW(w,M,N) ((((w) + 1) % (M)) + (w) - (w) % (M))
#define SOUTHFROMW(w,M,N) (((w) - 1 + (M)) % (M) + (w) - (w) % (M))
#define EASTFROMW(w,M,N)  (((w) + (M)) % ((M) * (N)))
#define WESTFROMW(w,M,N)  (((w) - (M) + (M) * (N)) % ((M) * (N)))

#ifndef _ltfat_mask_element_defined
#define _ltfat_mask_element_defined

enum ltfat_mask_element
{
    LTFAT_MASK_BELOWTOL    = -1, // Do not compute phase, the coefficient is too small
    LTFAT_MASK_UNKNOWN     =  0, // Will compute phase for these
    LTFAT_MASK_KNOWN       =  1, // The phase was already known
    LTFAT_MASK_WENTNORTH   =  2, // Phase was spread from the south neighbor
    LTFAT_MASK_WENTSOUTH   =  3, // Phase was spread from the north neighbor
    LTFAT_MASK_WENTEAST    =  4, // Phase was spread from the west neighbor
    LTFAT_MASK_WENTWEST    =  5, // Phase was spread from the east neighbor
    LTFAT_MASK_STARTPOINT  =  6, // This is the initial point of integration. It gets zero phase
    LTFAT_MASK_BORDERPOINT =  7, // This is candidate border coefficient with known phase
};

#endif

struct LTFAT_NAME(heapinttask)
{
    ltfat_int height;
    ltfat_int N;
    int do_real;
    int* donemask;
    void (*intfun)(const  LTFAT_NAME(heapinttask)*,
                   const LTFAT_REAL*, const LTFAT_REAL*,
                   ltfat_int, LTFAT_REAL* );
    LTFAT_NAME(heap)* heap;
};


void
LTFAT_NAME(trapezheap)(const LTFAT_NAME(heapinttask) *heaptask,
                       const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                       ltfat_int w, LTFAT_REAL* phase);

void
LTFAT_NAME(trapezheapreal)(const LTFAT_NAME(heapinttask) *heaptask,
                           const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                           ltfat_int w, LTFAT_REAL* phase);

void
LTFAT_NAME(gradsamptorad)(const LTFAT_REAL* tgrad, const LTFAT_REAL* fgrad,
                          ltfat_int a, ltfat_int M, ltfat_int L, ltfat_int W,
                          ltfat_phaseconvention phasetype, int do_real,
                          LTFAT_REAL* tgradw, LTFAT_REAL* fgradw);

void
LTFAT_NAME(borderstoheap)(LTFAT_NAME(heap)* h,
                          ltfat_int height, ltfat_int N,
                          int * donemask);

void
LTFAT_NAME(borderstoheapreal)(LTFAT_NAME(heap)* h,
                              ltfat_int height, ltfat_int N,
                              int * donemask);
