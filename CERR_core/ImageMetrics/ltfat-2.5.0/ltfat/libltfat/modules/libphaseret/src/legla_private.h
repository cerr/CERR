#ifndef _phaseret_legla_private_h
#define _phaseret_legla_private_h
//#include "dgtrealwrapper_private.h"

#ifdef __cplusplus
extern "C" {
#endif

struct phaseret_legla_params
{
    double relthr; ///< Relative threshold for automatic determination of kernel size, default 1e-3
    phaseret_size ksize; ///< Maximum allowed kernel size (default 2*ceil(M/a) -1) or kernel size directly if relthr==0.0
    unsigned leglaflags; ///< LEGLA algorithm flags, default MOD_COEFFICIENTWISE | MOD_MODIFIEDUPDATE
    ltfat_dgt_params* dparams;
};



#ifdef __cplusplus
}
#endif

#endif
