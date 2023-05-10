#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_cellcoef2tf // change to filename
#define OCTFILEHELP "Cell to tf-layout.\n" \
                    "Usage: coef = comp_cellcoef2tf(coef,maxLen)\n Yeah."

#include "ltfat_oct_template_helper.h"

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list
octFunction(const octave_value_list& args, int nargout)
{
    int nargin = args.length();

    Cell c = args(0).cell_value();

    double maxLen = 0.0;

    if (nargin > 1)
    {
        maxLen = args(1).double_value();
    }
    octave_idx_type M = c.numel();
    OCTAVE_LOCAL_BUFFER(const LTFAT_TYPE*, cPtrs, M);
    OCTAVE_LOCAL_BUFFER(octave_idx_type, cLens, M);
    octave_idx_type maxClen = 0;
    for (octave_idx_type m = 0; m < M; m++)
    {
        cLens[m] = c.elem(m).rows();
        if (cLens[m] > maxClen)
        {
            maxClen = cLens[m];
        }

        MArray<LTFAT_TYPE> cTmp = ltfatOctArray<LTFAT_TYPE>(c.elem(m));
        cPtrs[m] = cTmp.data();
    }

    if (maxLen > 0.0)
    {
        maxClen = maxLen < maxClen ? maxLen : maxClen;
    }


    MArray<LTFAT_TYPE> cout(dim_vector(M, maxClen));
    LTFAT_TYPE* coutPtr = (LTFAT_TYPE*) cout.fortran_vec();

    for (octave_idx_type m = 0; m < M; m++)
    {
        const LTFAT_TYPE* coefElPtrTmp = cPtrs[m];
        LTFAT_TYPE* coefOutPtrTmp = coutPtr + m;
        double lenRatio = ((double)cLens[m] - 1) / ((double)maxClen - 1);
        for (octave_idx_type ii = 0; ii < maxClen; ii++)
        {
            *coefOutPtrTmp = coefElPtrTmp[(octave_idx_type)((ii * lenRatio) + 0.5)];
            coefOutPtrTmp += M;
        }
    }



    return octave_value(cout);
}
