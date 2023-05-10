#ifndef _PHASERET_GSRTISILA_PRIVATE_H
#define _PHASERET_GSRTISILA_PRIVATE_H


struct PHASERET_NAME(gsrtisilaupdate_plan)
{
    PHASERET_NAME(rtisilaupdate_plan)* p2;
    const LTFAT_REAL* g;
//    const LTFAT_REAL* gd;
    ltfat_int gl;
    ltfat_int M;
    ltfat_int a;
    ltfat_int gNo;
    int do_skipinitialization;
};

struct PHASERET_NAME(gsrtisila_state)
{
    PHASERET_NAME(gsrtisilaupdate_plan)* uplan;
    ltfat_int maxLookahead;
    ltfat_int lookahead;
    ltfat_int lookback;
    ltfat_int maxit;
    ltfat_int W;
    LTFAT_REAL* frames; //!< Buffer for time-domain frames
    LTFAT_COMPLEX* cframes; //!< Buffer for frequency-domain frames
    LTFAT_REAL* s; //!< Buffer for target magnitude
    void** garbageBin;
    ltfat_int garbageBinSize;
};


#endif
