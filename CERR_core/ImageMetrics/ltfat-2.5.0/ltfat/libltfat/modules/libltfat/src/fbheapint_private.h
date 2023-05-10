void
LTFAT_NAME(borderstoheapneighs)(struct LTFAT_NAME(heap)* h,
                                ltfat_int Nsum, const ltfat_int neighs[], int* donemask);
/* Filter bank heap integration (uniform case)*/
inline void
LTFAT_NAME(trapezheap_ufb)(const struct LTFAT_NAME(heapinttask) *heaptask,
                           const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                           const LTFAT_REAL* cfreq,
                           ltfat_int w, LTFAT_REAL* phase);
inline void
LTFAT_NAME(trapezheapreal_ufb)(const struct LTFAT_NAME(heapinttask) *heaptask,
                               const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                               const LTFAT_REAL* cfreq,
                               ltfat_int w, LTFAT_REAL* phase);
void
LTFAT_NAME(gradsamptorad_ufb)(const LTFAT_REAL* tgrad, const LTFAT_REAL* fgrad,
                              const LTFAT_REAL* cfreq,
                              ltfat_int a, ltfat_int M, ltfat_int L, ltfat_int W,
                              LTFAT_REAL* tgradw, LTFAT_REAL* fgradw);
/* Filter bank heap integration (general case)*/
void LTFAT_NAME(trapezheap_fb)(const struct LTFAT_NAME(heapinttask_fb) *fbhit,
                               const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                               ltfat_int w, LTFAT_REAL* phase);
void
LTFAT_NAME(gradsamptorad_fb)(const LTFAT_REAL* tgrad, const LTFAT_REAL* fgrad,
                             const LTFAT_REAL* cfreq,
                             ltfat_int M,
                             const ltfat_int N[], ltfat_int Nsum,
                             ltfat_int W,
                             LTFAT_REAL* tgradw, LTFAT_REAL* fgradw);
