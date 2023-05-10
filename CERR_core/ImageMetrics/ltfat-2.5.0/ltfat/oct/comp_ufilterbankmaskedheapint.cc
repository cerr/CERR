#define TYPEDEPARGS 0, 1, 2, 3, 9
#define SINGLEARGS
#define REALARGS
#define OCTFILENAME comp_ufilterbankmaskedheapint // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                    phase=comp_ufilterbankmaskedheapint(s,tgrad,fgrad,cfreq,mask,a,do_real,tol,phasetype,usephase)\n Yeah."

#include "ltfat_oct_template_helper.h"

static inline void
fwd_ufilterbankmaskedheapint(
        const double s[], const double tgrad[], const double fgrad[], const double cfreq[], const int mask[],
        ltfat_int a,  ltfat_int M,  ltfat_int L, ltfat_int W,
        int do_real, double tol, int phasetype, double phase[])
{
    if (phasetype == 1)
        ltfat_ufilterbankmaskedheapint_d(
                s, tgrad, fgrad, cfreq, mask, a, M, L, W, do_real, tol, phase);
    else
        ltfat_ufilterbankmaskedheapint_relgrad_d(
                s, tgrad, fgrad, cfreq, mask, a, M, L, W, do_real, tol, phase);
}

static inline void
fwd_ufilterbankmaskedheapint(
        const float s[], const float tgrad[], const float fgrad[], const float cfreq[], const int mask[],
        ltfat_int a,  ltfat_int M,  ltfat_int L, ltfat_int W,
        int do_real, float tol, int phasetype, float phase[])
{
    if (phasetype == 1)
        ltfat_ufilterbankmaskedheapint_s(
                s, tgrad, fgrad, cfreq, mask, a, M, L, W, do_real, tol, phase);
    else
        ltfat_ufilterbankmaskedheapint_relgrad_s(
                s, tgrad, fgrad, cfreq, mask, a, M, L, W, do_real, tol, phase);
}


template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    // Input data
    MArray<LTFAT_REAL>      s = ltfatOctArray<LTFAT_REAL>(args(0));
    MArray<LTFAT_REAL>  tgrad = ltfatOctArray<LTFAT_REAL>(args(1));
    MArray<LTFAT_REAL>  fgrad = ltfatOctArray<LTFAT_REAL>(args(2));
    MArray<LTFAT_REAL>  cfreq = ltfatOctArray<LTFAT_REAL>(args(3));
    MArray<double> maskDouble = ltfatOctArray<double>(args(4));
    octave_idx_type         a = args(5).int_value();
    octave_idx_type   do_real = args(6).int_value();
    double                tol = args(7).double_value();
    octave_idx_type phasetype = args(8).int_value();
    MArray<LTFAT_REAL>  usephase = ltfatOctArray<LTFAT_REAL>(args(9));
    //phasetype--;

    octave_idx_type M  = s.columns();
    octave_idx_type N  = s.rows();
    octave_idx_type W  = 1;
    octave_idx_type L  = (octave_idx_type)( N * a);

    MArray<LTFAT_REAL> phase(dim_vector(N, M, W));

    int* mask = new int[M * N * W];
    for (octave_idx_type w = 0; w < M * N * W;++w)
        mask[w] = (int) maskDouble.data()[w];

    memcpy(phase.fortran_vec(), usephase.data(), M * N * W * sizeof(LTFAT_REAL));

    fwd_ufilterbankmaskedheapint(
            s.data(), tgrad.data(), fgrad.data(), cfreq.data(), mask,
            a, M, L, W, do_real, tol, phasetype, phase.fortran_vec());

    delete [] mask;
    return octave_value(phase);
}
