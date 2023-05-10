#if defined(OCTFILENAME) && defined(OCTFILEHELP)
#ifndef _LTFAT_OCT_TEMPLATE_HELPER_H
#define _LTFAT_OCT_TEMPLATE_HELPER_H
#include "ltfat.h"
#include <octave/oct.h>

#define IS_OCTAVE_NEWAPI ((OCTAVE_MAJOR_VERSION > 4) || (OCTAVE_MAJOR_VERSION == 4 && OCTAVE_MINOR_VERSION >= 4))

#ifdef _DEBUG
#define DEBUGINFO  octave_stdout << __PRETTY_FUNCTION__ << "\n"
#else
#define DEBUGINFO
#endif

bool checkIsSingle(const octave_value& ov);
octave_value recastToSingle(const octave_value& ov);

bool checkIsComplex(const octave_value& ov);
octave_value recastToComplex(const octave_value& ov);

template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout);

template <class LTFAT_TYPE>
MArray<LTFAT_TYPE> ltfatOctArray(const octave_value& ov);

template <class LTFAT_TYPE>
MArray<LTFAT_TYPE> ltfatOctArray(const octave_value& ov)
{
   error("Casting to unknown type. "
         "Everything should be handled in the specialized functions."
         ,__PRETTY_FUNCTION__);
   return MArray<LTFAT_TYPE>();
}

template <>
MArray<double> ltfatOctArray(const octave_value& ov)
{
    if(ov.is_double_type())
    {
       return (ov.array_value());
    }
    else
    {
       error("Unsupported data type..");
    }
    return MArray<double>();
}

template <>
MArray<float> ltfatOctArray(const octave_value& ov)
{
#if IS_OCTAVE_NEWAPI
    if(ov.isfloat())
#else
    if(ov.is_float_type())
#endif
    {
       return (ov.float_array_value());
    }
    else
    {
       error("Unsupported data type..");
    }
    return MArray<float>();
}

template <>
MArray<Complex> ltfatOctArray(const octave_value& ov)
{
    if(ov.is_double_type())
    {
       return (ov.complex_array_value());
    }
    else
    {
       error("Unsupported data type..");
    }
    return MArray<Complex>();
}

template <>
MArray<FloatComplex> ltfatOctArray(const octave_value& ov)
{
#if IS_OCTAVE_NEWAPI
    if(ov.isfloat())
#else
    if(ov.is_float_type())
#endif
    {
       return (ov.float_complex_array_value());
    }
    else
    {
       error("Unsupported data type..");
    }
    return MArray<FloatComplex>();
}

bool checkIsSingle(const octave_value& ov)
{
#if IS_OCTAVE_NEWAPI
   if(ov.iscell())
#else
   if(ov.is_cell())
#endif
   {
      Cell ov_cell = ov.cell_value();
      for(int jj=0;jj<ov_cell.numel();jj++)
      {
         if(checkIsSingle(ov_cell.elem(jj)))
            return true;
      }
      return false;
   }
   return ov.is_single_type();
}

bool checkIsComplex(const octave_value& ov)
{
#if IS_OCTAVE_NEWAPI
   if(ov.iscell())
#else
   if(ov.is_cell())
#endif
   {
      Cell ov_cell = ov.cell_value();
      for(int jj=0;jj<ov_cell.numel();jj++)
      {
         if(checkIsComplex(ov_cell.elem(jj)))
            return true;
      }
      return false;
   }

#if IS_OCTAVE_NEWAPI
   return ov.iscomplex();
#else
   return ov.is_complex_type();
#endif
}

octave_value recastToSingle(const octave_value& ov)
{

#if IS_OCTAVE_NEWAPI
   if(ov.iscell())
#else
   if(ov.is_cell())
#endif
   {
      Cell ov_cell = ov.cell_value();
      Cell ovtmp_cell(ov.dims());
      for(int jj=0;jj<ovtmp_cell.numel();jj++)
      {
         ovtmp_cell(jj) = recastToSingle(ov_cell.elem(jj));
      }
      return ovtmp_cell;
   }

   if(ov.is_single_type())
   {
      return ov;
   }

   /*
   TODO: ov is struct
   */
   // just copy pointer if the element is not numeric
#if IS_OCTAVE_NEWAPI
   if(!ov.isnumeric())
#else
   if(!ov.is_numeric_type())
#endif
   {
      return ov;
   }

#if IS_OCTAVE_NEWAPI
   if(ov.iscomplex())
#else
   if(ov.is_complex_type())
#endif
   {
      return ltfatOctArray<FloatComplex>(ov);
   }
   else
   {
      return ltfatOctArray<float>(ov);
   }
}

octave_value recastToComplex(const octave_value& ov)
{
#if IS_OCTAVE_NEWAPI
   if(ov.iscell())
#else
   if(ov.is_cell())
#endif
   {
      Cell ov_cell = ov.cell_value();
      Cell ovtmp_cell(ov.dims());
      for(int jj=0;jj<ovtmp_cell.numel();jj++)
      {
         ovtmp_cell(jj) = recastToComplex(ov_cell.elem(jj));
      }
      return ovtmp_cell;
   }

 #if IS_OCTAVE_NEWAPI
   if(ov.iscomplex())
#else
   if(ov.is_complex_type())
#endif
   {
      return ov;
   }

   /*
   TODO: ov is struct
   */
   // just copy pointer if the element is not numeric
#if IS_OCTAVE_NEWAPI
   if(!ov.isnumeric())
#else
   if(!ov.is_numeric_type())
#endif
   {
      return ov;
   }

   if(ov.is_single_type())
   {
      return ltfatOctArray<FloatComplex>(ov);
   }
   else
   {
      return ltfatOctArray<Complex>(ov);
   }
}


DEFUN_DLD (OCTFILENAME, args, nargout, OCTFILEHELP)
{
octave_value_list argsCopy(args);

#define ENSURESINGLE                                               \
    for(int ii=0;ii<tdArgsIfSingle.length();ii++)                  \
        tdArgsIfSingle(ii) = octave_value(recastToSingle(tdArgsIfSingle(ii)));

#define ENSURECOMPLEX                                               \
for(int ii=0;ii<tdArgsIfComplex.length();ii++)                      \
    tdArgsIfComplex(ii) = octave_value(recastToComplex(tdArgsIfComplex(ii)));


bool isAnySingle = false;
bool isAnyComplex = false;
#ifndef TYPEDEPARGS
return octFunction<double,double,Complex>(argsCopy,nargout);
#else
// Arguments, which will be matched by complexity
// If at least one is complex, the others are cast to complex
int prhsToCheckIfComplex[] = { TYPEDEPARGS };
int prhsToCheckIfComplexLen = sizeof(prhsToCheckIfComplex)/sizeof(*prhsToCheckIfComplex);

// Arguments, which will be matchd by data type
// If at least one is single, the others are cast to single
#ifndef MATCHEDARGS
   int prhsToCheckIfSingle[] = { TYPEDEPARGS };
#else
   int prhsToCheckIfSingle[] = { TYPEDEPARGS, MATCHEDARGS };
#endif
int prhsToCheckIfSingleLen = sizeof(prhsToCheckIfSingle)/sizeof(*prhsToCheckIfSingle);

// WORKAROUND Incorrect detection of the single data type of complex diag. matrices
for(int ii=0;ii<prhsToCheckIfSingleLen;ii++)
    if(argsCopy(prhsToCheckIfSingle[ii]).is_diag_matrix())
       argsCopy(prhsToCheckIfSingle[ii])= argsCopy(prhsToCheckIfSingle[ii]).full_value();


// Reference arrays holding arguments to be checked
octave_value_list tdArgsIfComplex;
octave_value_list tdArgsIfSingle;

// copy refenrences
for(int ii=0;ii<prhsToCheckIfComplexLen;ii++)
   tdArgsIfComplex.append(argsCopy(prhsToCheckIfComplex[ii]));

for(int ii=0;ii<prhsToCheckIfComplexLen;ii++)
   tdArgsIfSingle.append(argsCopy(prhsToCheckIfSingle[ii]));

// Check if any of the parameters is single
for(int ii=0;ii<tdArgsIfSingle.length();ii++)
    if((isAnySingle=checkIsSingle(tdArgsIfSingle(ii)))) break;

// Check if any of the parameters is complex
for(int ii=0;ii<tdArgsIfComplex.length();ii++)
    if((isAnyComplex=checkIsComplex(tdArgsIfComplex(ii)))) break;

#if defined(REALARGS)&& !(defined(COMPLEXARGS) || defined(COMPLEXINDEPENDENT))
if(isAnyComplex)
{
   error("Only real inputs are accepted.");
   return octave_value_list();
}
#endif

#ifndef SINGLEARGS
if(isAnySingle)
{
   error("Only double inputs are accepted.");
   return octave_value_list();
}
#endif


/****************** HANDLING COMPLEXINDEPENDENT *************************/
#if defined(COMPLEXINDEPENDENT) || (defined(COMPLEXARGS)&&defined(REALARGS))
if(isAnyComplex) ENSURECOMPLEX
#  ifndef SINGLEARGS
if(isAnyComplex)
{
   return octFunction<Complex,double,Complex>(argsCopy,nargout);
}
else
{
   return octFunction<double,double,Complex>(argsCopy,nargout);
}
#  else
if(isAnySingle) ENSURESINGLE

if(isAnyComplex&&isAnySingle)
{
    return octFunction<FloatComplex,float,FloatComplex>(argsCopy,nargout);
}
else if(!isAnyComplex&&isAnySingle)
{
    return octFunction<float,float,FloatComplex>(argsCopy,nargout);
}
else if(isAnyComplex&&!isAnySingle)
{
    return octFunction<Complex,double,Complex>(argsCopy,nargout);
}
else
{
    return octFunction<double,double,Complex>(argsCopy,nargout);
}
#  endif
/****************** HANDLING ONLY COMPLEX *************************/
#elif defined(COMPLEXARGS) && !defined(REALARGS)
ENSURECOMPLEX
#  ifndef SINGLEARGS
   return octFunction<Complex,double,Complex>(argsCopy,nargout);
#  else
if(isAnySingle)
{
   ENSURESINGLE
   return octFunction<FloatComplex,float,FloatComplex>(argsCopy,nargout);
}
else
{
   return octFunction<Complex,double,Complex>(argsCopy,nargout);
}
#  endif
/****************** HANDLING ONLY REAL *************************/
#elif !defined(COMPLEXARGS) && defined(REALARGS)
#  ifndef SINGLEARGS
   return octFunction<double,double,Complex>(argsCopy,nargout);
#  else
if(isAnySingle)
{
   ENSURESINGLE
   return octFunction<float,float,FloatComplex>(argsCopy,nargout);
}
else
{
   return octFunction<double,double,Complex>(argsCopy,nargout);
}
#  endif
#else
error("Something wrong in the template system. My bad....\n");
#endif



#endif // TYPEDEPARGS


error("Something fishy is going on in...\n");

#undef ENSURESINGLE
#undef ENSURECOMPLEX

return octave_value_list();
}


#endif // _LTFAT_OCT_TEMPLATE_HELPER_H
#endif // defined(OCTFILENAME) && defined(OCTFILEHELP)
