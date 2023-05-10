#define TYPEDEPARGS 0, 4
#define SINGLEARGS
#define REALARGS
#define OCTFILENAME comp_filterbankphasegradfrommag // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                    [tgrad,fgrad,logs] = comp_filterbankphasegradfrommag(abss,N,a,M,tfr,fc,NEIGH,posInfo,gderivweight,do_tfrdiff); \n Yeah."

#include "ltfat_oct_template_helper.h"

static inline void
fwd_fbmagphasegrad(
        const double s[], const double tfr[], const ltfat_int NPtr[], const double a[],
        const double fc[], ltfat_int Nsum, ltfat_int M, const ltfat_int neighPtr[], const double posInfo[],
        double gderivweight, double logs[], int do_tfrdiff, double tgrad[], double fgrad[])
{
    ltfat_log_array_d(s, Nsum, logs);
    ltfat_fbmagphasegrad_d(logs, tfr, NPtr, a, fc, M, neighPtr, posInfo, gderivweight, do_tfrdiff,
                           tgrad, fgrad);
}

static inline void
fwd_fbmagphasegrad(
        const float s[], const float tfr[], const ltfat_int NPtr[], const double a[],
        const double fc[], ltfat_int Nsum, ltfat_int M, const ltfat_int neighPtr[], const double posInfo[],
        double gderivweight, float logs[], int do_tfrdiff, float tgrad[], float fgrad[])
{
    ltfat_log_array_s(s, Nsum, logs);
    ltfat_fbmagphasegrad_s(logs, tfr, NPtr, a, fc, M, neighPtr, posInfo, gderivweight, do_tfrdiff,
                           tgrad, fgrad);
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    // Input data
    MArray<LTFAT_REAL>         s = ltfatOctArray<LTFAT_REAL>(args(0));
    MArray<double>       NDouble = ltfatOctArray<double>(args(1));
    MArray<double>       aDouble = ltfatOctArray<double>(args(2));
    octave_idx_type            M = args(3).int_value();
    MArray<LTFAT_REAL>       tfr = ltfatOctArray<LTFAT_REAL>(args(4));
    MArray<double>      fcDouble = ltfatOctArray<double>(args(5));
    MArray<double>   neighDouble = ltfatOctArray<double>(args(6));
    MArray<double> posinfoDouble = ltfatOctArray<LTFAT_REAL>(args(7));
    double          gderivweight = args(8).double_value();
    int               do_tfrdiff = args(9).int_value();

    const octave_idx_type Nsum  = s.rows();
    octave_idx_type W = 1;
    octave_idx_type neighLen = neighDouble.numel();

    OCTAVE_LOCAL_BUFFER (ltfat_int, NPtr, M);
    for (octave_idx_type ii = 0; ii < M; ++ii)
        NPtr[ii] = (ltfat_int) NDouble.data()[ii];

    ltfat_int* neighPtr = new ltfat_int[neighLen];
    for (octave_idx_type ii = 0; ii < neighLen; ++ii)
        neighPtr[ii] = (ltfat_int) neighDouble.data()[ii];

    MArray<LTFAT_REAL> tgrad(dim_vector(Nsum, W));
    MArray<LTFAT_REAL> fgrad(dim_vector(Nsum, W));
    MArray<LTFAT_REAL> logs(dim_vector(Nsum, W));

    fwd_fbmagphasegrad(
            s.data(), tfr.data(), NPtr, aDouble.data(), fcDouble.data(),
            Nsum, M, neighPtr, posinfoDouble.data(), gderivweight,
            logs.fortran_vec(), do_tfrdiff, tgrad.fortran_vec(), fgrad.fortran_vec());

    delete [] neighPtr;
    octave_value_list retval;
    retval(0) = tgrad;
    retval(1) = fgrad;
    retval(2) = logs;
    return retval;
}
