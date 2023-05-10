#define TYPEDEPARGS 0, 1, 2
#define SINGLEARGS
#define REALARGS
#define OCTFILENAME comp_heapintreal
#define OCTFILEHELP "Computes heapint.\n\
                    Usage: c = comp_heapintreal(s, itime, ifreq, a, M, tol, do_timeinv);\n\
                    Yeah."


#include "ltfat_oct_template_helper.h"

static inline void
fwd_heapintreal(const double *s, const double *tgrad, const double *fgrad,
                const octave_idx_type a, const octave_idx_type M,
                const octave_idx_type L, const octave_idx_type W,
                double tol, int phasetype, double *phase)
{
    if (phasetype == 2)
        ltfat_heapintreal_d(s, tgrad, fgrad, a, M, L, W, tol, phase);
    else
        ltfat_heapintreal_relgrad_d(s, tgrad, fgrad, a, M, L, W, tol,
                              static_cast<ltfat_phaseconvention>(phasetype) , phase);
}

static inline void
fwd_heapintreal(const float *s, const float *tgrad, const float *fgrad,
                const octave_idx_type a, const octave_idx_type M,
                const octave_idx_type L, const octave_idx_type W,
                float tol, int phasetype, float *phase)
{
    if (phasetype == 2)
        ltfat_heapintreal_s(s, tgrad, fgrad, a, M, L, W, tol, phase);
    else
        ltfat_heapintreal_relgrad_s(s, tgrad, fgrad, a, M, L, W, tol,
                              static_cast<ltfat_phaseconvention>(phasetype), phase);
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    MArray<LTFAT_TYPE> s = ltfatOctArray<LTFAT_TYPE>(args(0));
    MArray<LTFAT_TYPE> tgrad = ltfatOctArray<LTFAT_TYPE>(args(1));
    MArray<LTFAT_TYPE> fgrad = ltfatOctArray<LTFAT_TYPE>(args(2));
    const octave_idx_type a  = args(3).int_value();
    const octave_idx_type M  = args(4).int_value();
    const double tol  = args(5).double_value();
    const int phasetype = args(6).int_value() == 1? LTFAT_TIMEINV: LTFAT_FREQINV;

    const octave_idx_type M2 = args(0).rows();
    const octave_idx_type N = args(0).columns();
    const octave_idx_type L = N * a;
    const octave_idx_type W = s.numel() / (M2 * N);

    MArray<LTFAT_TYPE> phase(dim_vector(M2, N, W));

    fwd_heapintreal(s.data(), tgrad.data(), fgrad.data(), a, M, L, W, tol,
                    phasetype, phase.fortran_vec());

    return octave_value(phase);
}
