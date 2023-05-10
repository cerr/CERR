#define TYPEDEPARGS 0
#define MATCHEDARGS 1
#define SINGLEARGS
#define COMPLEXINDEPENDENT
#define OCTFILENAME comp_gga // change to filename
#define OCTFILEHELP "This function calls the C-library \n\
                     c = comp_gga(f,indvec)\n Yeah."

#include "ltfat_oct_template_helper.h"

static inline void
fwd_gga(const Complex *fPtr, const double*  indVecPtr,
        const octave_idx_type L, const octave_idx_type W,
        const octave_idx_type M, Complex *cPtr )
{
   ltfat_gga_dc(reinterpret_cast<const ltfat_complex_d *>(fPtr),
          indVecPtr,L,W,M,
          reinterpret_cast<ltfat_complex_d *>(cPtr));
}

static inline void
fwd_gga(const FloatComplex *fPtr, const float*  indVecPtr,
        const octave_idx_type L, const octave_idx_type W,
        const octave_idx_type M, FloatComplex *cPtr )
{
   ltfat_gga_sc(reinterpret_cast<const ltfat_complex_s *>(fPtr),
          indVecPtr,L,W,M,
          reinterpret_cast<ltfat_complex_s *>(cPtr));
}

static inline void
fwd_gga(const double *fPtr, const double*  indVecPtr,
        const octave_idx_type L, const octave_idx_type W,
        const octave_idx_type M, Complex *cPtr )
{
   ltfat_gga_d(fPtr, indVecPtr,L,W,M,
         reinterpret_cast<ltfat_complex_d *>(cPtr));
}

static inline void
fwd_gga(const float *fPtr, const float*  indVecPtr,
        const octave_idx_type L, const octave_idx_type W,
        const octave_idx_type M, FloatComplex *cPtr )
{
   ltfat_gga_s(fPtr, indVecPtr,L,W,M,
         reinterpret_cast<ltfat_complex_s *>(cPtr));
}

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list
octFunction(const octave_value_list& args, int nargout)
{
   // Input data
   MArray<LTFAT_TYPE> f = ltfatOctArray<LTFAT_TYPE>(args(0));
   MArray<LTFAT_REAL> indVec = ltfatOctArray<LTFAT_REAL>(args(1));
    
   // Input length
   const octave_idx_type L  = f.rows();
   // Number of channels
   const octave_idx_type W  = f.columns();
   // Number of coefficients
   const octave_idx_type M = indVec.numel();

   //dims_out.chop_trailing_singletons();
   MArray<LTFAT_COMPLEX> c(dim_vector(M,W));
    
   fwd_gga(f.data(),indVec.data(),L,W,M,c.fortran_vec());

   return octave_value(c);
}
