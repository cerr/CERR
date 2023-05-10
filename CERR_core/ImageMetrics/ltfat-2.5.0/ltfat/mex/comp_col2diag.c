#ifndef _LTFAT_MEX_FILE
#define _LTFAT_MEX_FILE

#define ISNARGINEQ 1
#define TYPEDEPARGS 0
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define NOCOMPLEXFMTCHANGE

#endif /* _LTFAT_MEX_FILE */

#define MEX_FILE comp_col2diag.c
#include "ltfat_mex_template_helper.h"

#if defined(LTFAT_SINGLE) || defined(LTFAT_DOUBLE)
#include "ltfat/types.h"

/*
  Defining forwarders since there is no simple way of unified call to
  col2diag since the real and imag planes are processed separatelly
*/
#ifdef LTFAT_DOUBLE
static inline void 
LTFAT_NAME(fwd_col2diag)(const double* cin, const mwSize L, double* cout)
{
   ltfat_col2diag_d(cin,L,cout);
}
#endif /* LTFAT_DOUBLE */

#ifdef LTFAT_SINGLE
static inline void
LTFAT_NAME(fwd_col2diag)(const float* cin, const int L, float* cout)
{
   ltfat_col2diag_s(cin,L,cout);
}
#endif /* LTFAT_SINGLE */

/* Calling convention:
 *  cout=comp_col2diag(cin);
 */
void LTFAT_NAME(ltfatMexFnc)(int UNUSED(nlhs), mxArray *plhs[],
                             int UNUSED(nrhs), const mxArray *prhs[] )
{
   mwSize L = mxGetM(prhs[0]);
   plhs[0] = ltfatCreateMatrix(L, L, LTFAT_MX_CLASSID, LTFAT_MX_COMPLEXITY);

   #if defined(NOCOMPLEXFMTCHANGE) && !(MX_HAS_INTERLEAVED_COMPLEX)
   LTFAT_REAL* cout_r = mxGetData(plhs[0]);
   LTFAT_REAL* cin_r =  mxGetData(prhs[0]);
   LTFAT_NAME(fwd_col2diag)(cin_r,L,cout_r);

   #ifdef LTFAT_COMPLEXTYPE
   // Treat the imaginary part
   LTFAT_REAL* cin_i= mxGetImagData(prhs[0]);
   LTFAT_REAL* cout_i= mxGetImagData(plhs[0]);
   LTFAT_NAME(fwd_col2diag)(cin_i, L,cout_i);
   #endif /* LTFAT_COMPLEXTYPE */
   #else /* not NOCOMPLEXFMTCHANGE */
   LTFAT_TYPE* cin_r=  mxGetData(prhs[0]);
   LTFAT_TYPE* cout_r= mxGetData(plhs[0]);
   LTFAT_NAME(col2diag)(cin_r, L,cout_r);
   #endif /* NOCOMPLEXFMTCHANGE */
}
#endif /* LTFAT_SINGLE or LTFAT_DOUBLE */
