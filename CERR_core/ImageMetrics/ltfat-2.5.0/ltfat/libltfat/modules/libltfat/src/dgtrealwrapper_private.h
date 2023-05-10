#ifndef _ltfat_dgtrealwrapper_private_h
#define _ltfat_dgtrealwrapper_private_h
#include "dgtwrapper_private.h"

typedef int LTFAT_NAME(complextorealtransform)(void* userdata, const LTFAT_COMPLEX* c, ltfat_int L, ltfat_int W, LTFAT_REAL* f);
typedef int LTFAT_NAME(realtocomplextransform)(void* userdata, const LTFAT_REAL* f, ltfat_int L, ltfat_int W, LTFAT_COMPLEX* c);

struct LTFAT_NAME(dgtreal_plan)
{
    ltfat_int L;
    ltfat_int W;
    ltfat_int a;
    ltfat_int M;
    LTFAT_REAL* f;
    LTFAT_COMPLEX* c;
    ltfat_phaseconvention ptype;
    LTFAT_NAME(complextorealtransform)* backtra;
    void* backtra_userdata;
    LTFAT_NAME(donefunc)* backdonefunc;
    LTFAT_NAME(realtocomplextransform)* fwdtra;
    void* fwdtra_userdata;
    LTFAT_NAME(donefunc)* fwddonefunc;
};

#endif

