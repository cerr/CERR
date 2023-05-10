#define TYPEDEPARGS 0, 1, 2, 3
#define SINGLEARGS
#define REALARGS
#define OCTFILENAME comp_ufilterbankheapint // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                    phase=comp_ufilterbankheapint(s,tgrad,fgrad,cfreq,a,do_real,tol,phasetype)\n Yeah."

#include "ltfat_oct_template_helper.h"

static inline void
fwd_ufilterbankheapint(
        const double s[], const double tgrad[], const double fgrad[], const double cfreq[],
        ltfat_int a,  ltfat_int M,  ltfat_int L, ltfat_int W,
        int do_real, double tol, int phasetype, double phase[])
{
    if (phasetype == 1)
        ltfat_ufilterbankheapint_d(
                s, tgrad, fgrad, cfreq, a, M, L, W, do_real, tol, phase);
    else
        ltfat_ufilterbankheapint_relgrad_d(
                s, tgrad, fgrad, cfreq, a, M, L, W, do_real, tol, phase);
}

static inline void
fwd_ufilterbankheapint(
        const float s[], const float tgrad[], const float fgrad[], const float cfreq[],
        ltfat_int a,  ltfat_int M,  ltfat_int L, ltfat_int W,
        int do_real, float tol, int phasetype, float phase[])
{
    if (phasetype == 1)
        ltfat_ufilterbankheapint_s(
                s, tgrad, fgrad, cfreq, a, M, L, W, do_real, tol, phase);
    else
        ltfat_ufilterbankheapint_relgrad_s(
                s, tgrad, fgrad, cfreq, a, M, L, W, do_real, tol, phase);
}


template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    // Input data
    MArray<LTFAT_REAL>      s = ltfatOctArray<LTFAT_REAL>(args(0));
    MArray<LTFAT_REAL>  tgrad = ltfatOctArray<LTFAT_REAL>(args(1));
    MArray<LTFAT_REAL>  fgrad = ltfatOctArray<LTFAT_REAL>(args(2));
    MArray<LTFAT_REAL>  cfreq = ltfatOctArray<LTFAT_REAL>(args(3));
    octave_idx_type         a = args(4).int_value();
    octave_idx_type   do_real = args(5).int_value();
    double                tol = args(6).double_value();
    octave_idx_type phasetype = args(7).int_value();

    octave_idx_type M  = s.columns();
    octave_idx_type N  = s.rows();
    octave_idx_type W  = 1;
    octave_idx_type L  = (octave_idx_type)( N * a);

   // phasetype--;

    MArray<LTFAT_REAL> phase(dim_vector(N, M, W));

    fwd_ufilterbankheapint(
            s.data(), tgrad.data(), fgrad.data(), cfreq.data(),
            a, M, L, W, do_real, tol, phasetype, phase.fortran_vec());

    return octave_value(phase);
}
