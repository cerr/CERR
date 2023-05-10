LTFAT_API void
LTFAT_NAME(fbmagphasegrad)(const LTFAT_REAL logs[], const LTFAT_REAL sqtfr[],
                           const ltfat_int N[], const double a[], const double fc[], ltfat_int M,
                           const ltfat_int neigh[], const double posInfo[], LTFAT_REAL gderivweight,
                           int do_tfrdiff, LTFAT_REAL tgrad[], LTFAT_REAL fgrad[]);

/* Filter bank heap integration (uniform case) - Start */
struct LTFAT_NAME(heapinttask_ufb)
{
    struct LTFAT_NAME(heapinttask) * hit;
    void (*intfun)(const struct LTFAT_NAME(heapinttask) *,
                   const LTFAT_REAL*, const LTFAT_REAL*, const LTFAT_REAL*,
                   ltfat_int, LTFAT_REAL* );
};

LTFAT_API
struct LTFAT_NAME(heapinttask_ufb)*
LTFAT_NAME(heapinttask_init_ufb)(ltfat_int height, ltfat_int N,
                                 ltfat_int initheapsize,
                                 const LTFAT_REAL* s, int do_real);
LTFAT_API
void LTFAT_NAME(heapint_execute_ufb)(struct LTFAT_NAME(heapinttask_ufb)* fbhit,
                                     const LTFAT_REAL* tgradw,
                                     const LTFAT_REAL* fgradw,
                                     const LTFAT_REAL* cfreq,
                                     LTFAT_REAL* phase);
LTFAT_API void
LTFAT_NAME(ufilterbankheapint)(const LTFAT_REAL *s,
                        const LTFAT_REAL *tgradw,
                        const LTFAT_REAL *fgradw,
                        const LTFAT_REAL* cfreq,
                        ltfat_int a, ltfat_int M,
                        ltfat_int L, ltfat_int W,
                        const int do_real,
                        const LTFAT_REAL tol, LTFAT_REAL *phase);
LTFAT_API void
LTFAT_NAME(ufilterbankmaskedheapint)(const LTFAT_REAL  *c,
                              const LTFAT_REAL *tgradw,
                              const LTFAT_REAL *fgradw,
                              const LTFAT_REAL* cfreq,
                              const int* mask,
                              ltfat_int a, ltfat_int M,
                              ltfat_int L, ltfat_int W,
                              const int do_real, const LTFAT_REAL tol, 
			      LTFAT_REAL *phase);
// The same as the previous but with gradient adjustment
LTFAT_API void
LTFAT_NAME(ufilterbankheapint_relgrad)(const LTFAT_REAL *s,
                                const LTFAT_REAL *tgrad,
                                const LTFAT_REAL *fgrad,
                                const LTFAT_REAL* cfreq,
                                ltfat_int a, ltfat_int M,
                                ltfat_int L, ltfat_int W,
                                const int do_real, const LTFAT_REAL tol,
                                LTFAT_REAL *phase);
LTFAT_API void
LTFAT_NAME(ufilterbankmaskedheapint_relgrad)(const LTFAT_REAL  *c,
                                      const LTFAT_REAL *tgrad,
                                      const LTFAT_REAL *fgrad,
                                      const LTFAT_REAL* cfreq,
                                      const int* mask,
                                      ltfat_int a, ltfat_int M,
                                      ltfat_int L, ltfat_int W,
                				      const int do_real,
                                      const LTFAT_REAL tol,
                                      LTFAT_REAL *phase);

LTFAT_API
void LTFAT_NAME(filterbankheapint)(const LTFAT_REAL* s,
                            const LTFAT_REAL* tgradw,
                            const LTFAT_REAL* fgradw,
                            const ltfat_int neigh[],
                            const LTFAT_REAL posInfo[],
                            const LTFAT_REAL cfreq[],
                            const double a[], const ltfat_int M, const ltfat_int N[],
                            const ltfat_int Nsum, const ltfat_int W,
                            LTFAT_REAL tol,  LTFAT_REAL* phase);

LTFAT_API void
LTFAT_NAME(filterbankmaskedheapint)(const LTFAT_REAL* s,
                             const LTFAT_REAL* tgradw,
                             const LTFAT_REAL* fgradw,
                             const int* mask,
                             const ltfat_int neigh[],
                             const LTFAT_REAL posInfo[],
                             const LTFAT_REAL* cfreq,
                             const double* a,
                             const ltfat_int M,
                             const ltfat_int N[], const ltfat_int Nsum,
                             const ltfat_int W,
                             LTFAT_REAL tol,  LTFAT_REAL* phase);

LTFAT_API void
LTFAT_NAME(filterbankheapint_relgrad)(const LTFAT_REAL* s,
                               const LTFAT_REAL* tgrad,
                               const LTFAT_REAL* fgrad,
                               const ltfat_int* neigh,
                               const LTFAT_REAL* posInfo,
                               const LTFAT_REAL* cfreq,
                               const double* a, const ltfat_int M,
                               const ltfat_int N[], const ltfat_int Nsum,
                               const ltfat_int W,
                               LTFAT_REAL tol,  LTFAT_REAL* phase);

LTFAT_API void
LTFAT_NAME(filterbankmaskedheapint_relgrad)(const LTFAT_REAL* s,
                                     const LTFAT_REAL* tgrad,
                                     const LTFAT_REAL* fgrad,
                                     const int* mask,
                                     const ltfat_int neigh[],
                                     const LTFAT_REAL posInfo[],
                                     const LTFAT_REAL* cfreq,
                                     const double* a,
                                     const ltfat_int M,
                                     const ltfat_int N[], const ltfat_int Nsum,
                                     const ltfat_int W,
                                     LTFAT_REAL tol,  LTFAT_REAL* phase);


/* Filter bank heap integration (uniform case) - End */
/* Heapint for NUFB - Start */
struct LTFAT_NAME(heapinttask_fb)
{
    struct LTFAT_NAME(heapinttask) * hit;
    void (*intfun)(const struct LTFAT_NAME(heapinttask_fb) *,
                   const LTFAT_REAL*, const LTFAT_REAL*, ltfat_int, LTFAT_REAL* );
    ltfat_int* N;
    double* a;
    LTFAT_REAL* cfreq;
    ltfat_int* neigh;
    LTFAT_REAL* posInfo;
};
LTFAT_API
struct LTFAT_NAME(heapinttask_fb)*
LTFAT_NAME(heapinttask_init_fb)(ltfat_int height,
                                ltfat_int initheapsize,
                                const LTFAT_REAL* s,
                                const ltfat_int* N,
                                const double* a,
                                const LTFAT_REAL* cfreq,
                                const ltfat_int* neigh,
                                const LTFAT_REAL* posInfo,
                                int do_real);
LTFAT_API
void LTFAT_NAME(heapint_execute_fb)(struct LTFAT_NAME(heapinttask_fb)* fbhit,
                                    const LTFAT_REAL* tgradw, const LTFAT_REAL* fgradw,
                                    LTFAT_REAL* phase);
LTFAT_API void
LTFAT_NAME(heapint_fb)(const LTFAT_REAL* s,
                       const LTFAT_REAL* tgradw,
                       const LTFAT_REAL* fgradw,
                       const ltfat_int neigh[],
                       const LTFAT_REAL posInfo[],
                       const LTFAT_REAL* cfreq,
                       const double a[], ltfat_int M,
                       const ltfat_int N[], ltfat_int Nsum,
                       ltfat_int W,
                       LTFAT_REAL tol,  LTFAT_REAL* phase);
// Does the same as the previous but
LTFAT_API void
LTFAT_NAME(heapint_relgrad_fb)(const LTFAT_REAL* s,
                               const LTFAT_REAL* tgrad,
                               const LTFAT_REAL* fgrad,
                               const ltfat_int neigh[],
                               const LTFAT_REAL posInfo[],
                               const LTFAT_REAL* cfreq,
                               const double a[], ltfat_int M,
                               const ltfat_int N[], ltfat_int Nsum,
                               ltfat_int W,
                               LTFAT_REAL tol,  LTFAT_REAL* phase);
LTFAT_API void
LTFAT_NAME(maskedheapint_fb)(const LTFAT_REAL* s,
                             const LTFAT_REAL* tgradw,
                             const LTFAT_REAL* fgradw,
                             const int* mask,
                             const ltfat_int neigh[],
                             const LTFAT_REAL posInfo[],
                             const LTFAT_REAL* cfreq,
                             const double* a,
                             ltfat_int M,
                             const ltfat_int N[], ltfat_int Nsum,
                             ltfat_int W,
                             LTFAT_REAL tol,  LTFAT_REAL* phase);
LTFAT_API void
LTFAT_NAME(maskedheapint_relgrad_fb)(const LTFAT_REAL* s,
                                     const LTFAT_REAL* tgrad,
                                     const LTFAT_REAL* fgrad,
                                     const int* mask,
                                     const ltfat_int neigh[],
                                     const LTFAT_REAL posInfo[],
                                     const LTFAT_REAL* cfreq,
                                     const double* a,
                                     ltfat_int M,
                                     const ltfat_int N[], ltfat_int Nsum,
                                     ltfat_int W,
                                     LTFAT_REAL tol,  LTFAT_REAL* phase);
/* Heapint for NUFB - End */

