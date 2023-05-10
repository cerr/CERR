#define TYPEDEPARGS 0, 1, 2, 4, 5, 12
#define SINGLEARGS
#define REALARGS
#define OCTFILENAME comp_filterbankmaskedheapint // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                     phase=comp_filterbankmaskedheapintreal(s,tgrad,fgrad,neigh,posInfo,cfreq, mask, a,M,N,tol,phasetype,usephase)\n Yeah."

#include "ltfat_oct_template_helper.h"

static inline void
fwd_filterbankmaskedheapint(
        const double s[], const double tgrad[], const double fgrad[], const int mask[], const ltfat_int neighPtr[],
        const double posinfoPtr[], const double cfreq[], const double a[], ltfat_int M, const ltfat_int NPtr[],
        ltfat_int Nsum, ltfat_int W, double tol, int phasetype, double phase[])
{
    if (phasetype == 1)
        ltfat_filterbankmaskedheapint_d(s, tgrad, fgrad, mask, neighPtr, posinfoPtr, cfreq,
                               a, M, NPtr, Nsum, W, tol, phase);
    else
        ltfat_filterbankmaskedheapint_relgrad_d(s , tgrad, fgrad, mask, neighPtr, posinfoPtr, cfreq,
                                       a, M, NPtr, Nsum, W, tol, phase);
}

static inline void
fwd_filterbankmaskedheapint(
        const float s[], const float tgrad[], const float fgrad[], const int mask[], const ltfat_int neighPtr[],
        const float posinfoPtr[], const float cfreq[], const double a[], ltfat_int M, const ltfat_int NPtr[],
        ltfat_int Nsum, ltfat_int W, float tol, int phasetype, float phase[])
{
    if (phasetype == 1)
        ltfat_filterbankmaskedheapint_s(s, tgrad, fgrad, mask, neighPtr, posinfoPtr, cfreq,
                               a, M, NPtr, Nsum, W, tol, phase);
    else
        ltfat_filterbankmaskedheapint_relgrad_s(s, tgrad, fgrad, mask, neighPtr, posinfoPtr, cfreq,
                                       a, M, NPtr, Nsum, W, tol, phase);
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    // Input data
    MArray<LTFAT_REAL>         s = ltfatOctArray<LTFAT_REAL>(args(0));
    MArray<LTFAT_REAL>     tgrad = ltfatOctArray<LTFAT_REAL>(args(1));
    MArray<LTFAT_REAL>     fgrad = ltfatOctArray<LTFAT_REAL>(args(2));
    MArray<double>   neighDouble = ltfatOctArray<double>(args(3));
    MArray<LTFAT_REAL>   posinfo = ltfatOctArray<LTFAT_REAL>(args(4));
    MArray<LTFAT_REAL>     cfreq = ltfatOctArray<LTFAT_REAL>(args(5));
    MArray<double>    maskDouble = ltfatOctArray<double>(args(6));
    MArray<double>       aDouble = ltfatOctArray<double>(args(7));
    octave_idx_type            M = args(8).int_value();
    MArray<double>       NDouble = ltfatOctArray<double>(args(9));
    double                   tol = args(10).double_value();
    octave_idx_type    phasetype = args(11).int_value();
    MArray<LTFAT_REAL>  usephase = ltfatOctArray<LTFAT_REAL>(args(12));

    const octave_idx_type Nsum  = s.rows();
    const octave_idx_type W  = 1;
    octave_idx_type neighLen = neighDouble.numel();

    OCTAVE_LOCAL_BUFFER (ltfat_int, NPtr, M);
    for (octave_idx_type ii = 0; ii < M; ++ii)
        NPtr[ii] = (ltfat_int) NDouble.data()[ii];

    ltfat_int* neighPtr = new ltfat_int[neighLen];
    for (octave_idx_type ii = 0; ii < neighLen; ++ii)
        neighPtr[ii] = (ltfat_int) neighDouble.data()[ii];

    int* mask = new int[Nsum*W];
    for (ltfat_int w = 0; w < Nsum * W; w++ )
        mask[w] = (int) maskDouble.data()[w];

    MArray<LTFAT_REAL> phase(dim_vector(Nsum, W));
    memcpy(phase.fortran_vec(), usephase.data(),  Nsum * W * sizeof(LTFAT_REAL));

    fwd_filterbankmaskedheapint(
            s.data(), tgrad.data(), fgrad.data(), mask,
            neighPtr, posinfo.data(), cfreq.data(), aDouble.data(),
            M, NPtr, Nsum, W, tol, phasetype, phase.fortran_vec());

    delete [] neighPtr;
    delete [] mask;
    return octave_value(phase);
}
