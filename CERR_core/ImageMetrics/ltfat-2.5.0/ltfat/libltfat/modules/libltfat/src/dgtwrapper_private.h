#ifndef _ltfat_dgtwrapper_private_h
#define _ltfat_dgtwrapper_private_h


struct ltfat_dgt_params
{
    ltfat_phaseconvention ptype;
    unsigned fftw_flags;
    ltfat_dgt_hint hint;
    int do_synoverwrites;
};

typedef int LTFAT_NAME(donefunc)(void** pla);

typedef int LTFAT_NAME(complextocomplextransform)(void* userdata, const LTFAT_COMPLEX* c, ltfat_int L, ltfat_int W, LTFAT_COMPLEX* f);
typedef int LTFAT_NAME(typetocomplextransform)(void* userdata, const LTFAT_TYPE* f, ltfat_int L, ltfat_int W, LTFAT_COMPLEX* c);

struct LTFAT_NAME(dgt_plan)
{
    ltfat_int L;
    ltfat_int W;
    ltfat_int a;
    ltfat_int M;
    LTFAT_COMPLEX* f;
    LTFAT_COMPLEX* c;
    ltfat_phaseconvention ptype;
    LTFAT_NAME(complextocomplextransform)* backtra;
    void* backtra_userdata;
    LTFAT_NAME(donefunc)* backdonefunc;
    LTFAT_NAME(typetocomplextransform)* fwdtra;
    void* fwdtra_userdata;
    LTFAT_NAME(donefunc)* fwddonefunc;
};

#endif

