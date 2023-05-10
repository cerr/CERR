#ifndef _LTFAT_SLIDGTREALMP_PRIVATE_H
#define _LTFAT_SLIDGTREALMP_PRIVATE_H


#endif

struct LTFAT_NAME(slidgtrealmp_state)
{
    LTFAT_NAME(dgtrealmp_state)* mpstate;
    int owning_mpstate;
    LTFAT_NAME(slicing_processor_state)* slistate;
    int owning_slistate;
    LTFAT_COMPLEX** couttmp;
    ltfat_int P;
    void* userdata;
    LTFAT_NAME(slidgtrealmp_processor_callback)* callback;
};


