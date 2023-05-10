/* 
 * ltfatresample.c 
 *
 * Copyright (C) 2014 Zdenek Prusa <zdenek.prusa@gmail.com>.
 * This file is part of LTFAT http://ltfat.github.io
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include "ltfatresample.h"
#include <math.h>

/* This is an actual structure used to hold info between consecutive blocks */
struct resample_plan_struct
{
   /* target to source sampling rates ratio */
   const double ratio;
   /* Type of polynomial interpolation */
   const resample_type restype;
   /* First sample in block global index */
   size_t inPos;
   size_t outPos;
   /* Buffer for holding overlap, length depend on interpoaltion technique */
   SAMPLE* overlap;
   /* Overlap length */
   size_t oLen;
   /* Function pointer to the block interpolation functon */
   resample_error (*executer)(const resample_plan,
                              const SAMPLE*, const size_t,
                              SAMPLE*, const size_t);

   /* Function pointer to one sample interpolating function */
   SAMPLE (*interp_sample)(const double, const SAMPLE *yin);

   /* Filters */
   EMQFfilters ef;

   /* Buffer, maxlength ceil(ratio) */
   SAMPLE* ebuf;

   const size_t ebufLen;

   /* Number of samples to be used from ebuf  */
   size_t ebufUsed;

};

void
resample_reset(const resample_plan rp)
{
   memset(rp->overlap,0,rp->oLen*sizeof*rp->overlap);
   rp->inPos = 0;
   rp->outPos = 0;
   rp->ebufUsed = 0;
}

resample_plan
resample_init(const resample_type restype, const double ratio)
{
   resample_plan rp = calloc(1, sizeof * rp);
   *(double*)&rp->ratio = ratio;
   *(resample_type*)&rp->restype = restype;

   if (restype == LINEAR)
   {
      rp->oLen = 1;
      rp->executer = &resample_execute_polynomial;
      rp->interp_sample = &linear_interp;
   }
   else if (restype == LAGRANGE)
   {
      rp->oLen = 5;
      rp->executer = &resample_execute_polynomial;
      rp->interp_sample = &lagrange_interp;
   }
   else if (restype == BSPLINE)
   {
      rp->oLen = 5;
      rp->executer = &resample_execute_polynomial;
      rp->interp_sample = &bspline_interp;
   }

   rp->overlap = calloc(rp->oLen, sizeof(SAMPLE));
   *(size_t*)&rp->ebufLen = ceil(ratio);
   rp->ebuf = malloc(rp->ebufLen * sizeof(SAMPLE));
   /*rp->ebufUsed = 0;  This was actually already set. */
   /* When subsampling, do the antialiasing filtering. */
   /* This is not exactly 1, because we do not want to filter when
    * subsampling only a little or not at all. */
   if (ratio < 0.95)
   {
      rp->ef = emqffilters_init(ratio * FPADJ);
   }

   return rp;
}

resample_error
resample_execute(const resample_plan rp,
                 SAMPLE* in, const size_t Lin,
                 SAMPLE* out, const size_t Lout)
{
   resample_error status;

   /* Do filtering if initialized */
   if (rp->ef)
   {
      /* Filtering is done inplace */
      emqffilters_dofilter(rp->ef, in, Lin, in);
   }

   /* Execute the computation */
   status = rp->executer(rp, in, Lin, out, Lout);

   if (status == RESAMPLE_OK)
   {
      /* All ok, advance both stream pointers */
      resample_advanceby(rp, Lin, Lout);
   }
   else
   {
      /* Overflow or underflow occured, resetting the stream */
      resample_reset(rp);
   }

   return status;
}

size_t
resample_nextoutlen(const resample_plan rp, size_t Lin)
{
   size_t retval = 0;
   const double outSpos = ceil( (rp->inPos) * rp->ratio );
   const double outEpos = ceil( (rp->inPos + Lin) * rp->ratio );
   retval =  (size_t)( outEpos - outSpos);

   return retval;
}

size_t
resample_nextinlen(const resample_plan rp, size_t Lout)
{
   size_t retval = 0;
   const double outSpos = ceil( (rp->outPos) / rp->ratio );
   const double outEpos = ceil( (rp->outPos + Lout) / rp->ratio );
   retval =  (size_t)( outEpos - outSpos);

   return retval;
}

/*  Be carefull, rp is effectivelly a double pointer. */
void
resample_done(resample_plan *rp)
{
   if ((*rp)->overlap) free((*rp)->overlap);
   if ((*rp)->ebuf) free((*rp)->ebuf);
   if ((*rp)->ef) emqffilters_done(&((*rp)->ef));

   free(*rp);
   /* This is the reason why it is passed by a double pointer */
   *rp = NULL;
}


void
resample_advanceby(const resample_plan rp, const size_t Lin, const size_t Lout)
{
   rp->inPos += Lin;
   rp->outPos += Lout;
}


/* INTERNALS */

/* This can handle any type of polynomial resampling. */
resample_error
resample_execute_polynomial(const resample_plan rp,
                            const SAMPLE* in, const size_t Lin,
                            SAMPLE* out, const size_t Lout)
{
#define ONESAMPLE(outVal)\
      truepos = (ii + outSpos) * oneOverRatio - rp->inPos;\
      highpos = ceil(truepos);\
      x = truepos - (highpos - 1);\
      memcpy(buf, &in[highpos - (oLen + 1)], (oLen + 1) * sizeof * buf);\
      (outVal) = rp->interp_sample(x, buf);

   double truepos, x;
   ptrdiff_t highpos = 0;
   SAMPLE* buf;
   size_t ii, jj, zz, *iiThre;
   resample_error retval = RESAMPLE_OK;

   size_t oLen = rp->oLen;
   size_t Louttmp = Lout - rp->ebufUsed;

   const double oneOverRatio = 1.0 / rp->ratio;
   /* Starting position in the output stream */
   //double outSpos = ceil( (rp->inPos) * rp->ratio )  ;
   double outSpos = rp->outPos + rp->ebufUsed  ;
   /* How many samples will this routine produce */
   size_t Louttrue = resample_nextoutlen(rp, Lin);
   size_t Loutvalid = Louttrue < Louttmp ? Louttrue : Louttmp;

   /* Copy buffered samples + update out */
   memcpy(out, rp->ebuf, rp->ebufUsed * sizeof * out);
   out += rp->ebufUsed;

   /* oLen +1 thresholds */
   iiThre = calloc(oLen + 1, sizeof * iiThre);
   /* Buffer for passing values to single sample interp. routine */
   buf = calloc(oLen + 1, sizeof * buf);

   /* First handle all samples which need overlap. */
   for (ii = 0; ii < oLen + 1; ii++)
   {
      iiThre[ii] = floor((rp->inPos + ((double) ii + 1) ) * rp->ratio - outSpos) + 1;
   }


   /* ii starts here */
   ii = 0;
   for (zz = 0; zz < oLen + 1; zz++)
   {
      for (; ii < iiThre[zz]; ii++)
      {
         truepos = (ii + outSpos) * oneOverRatio - rp->inPos;
         x = truepos - zz;
         memcpy(buf, rp->overlap + zz, (oLen - zz)*sizeof * buf);
         memcpy(buf + (oLen - zz), in, (zz + 1)*sizeof * buf );
         out[ii] = rp->interp_sample(x, buf);
      }
   }

   /* Handle samples safely inside.
    * ii continues */
   for (; ii < Loutvalid ; ii++)
   {
      ONESAMPLE(out[ii])
   }

   /* Handle samples overflowing the output buffer *
    * ii still continues */
   for (jj = 0; ii < Louttrue && jj < rp->ebufLen; ii++, jj++ )
   {
      ONESAMPLE(rp->ebuf[jj])
   }
   rp->ebufUsed = jj;

   if (Louttrue>Louttmp+rp->ebufUsed)
   {
      /* Some samples will be skipped.  */
      retval = RESAMPLE_OVERFLOW;
   }

   if (Louttrue < Louttmp)
   {
      /* Next iteration will probably access an uninitialized memory. */
      retval = RESAMPLE_UNDERFLOW;
      memset(out+Louttrue,0,(Louttmp-Louttrue)*sizeof*out);
   }

   /* Copy last oLen samples to overlap .*/
   memcpy(rp->overlap, in + Lin - oLen, oLen * sizeof * in);

   free(iiThre);
   free(buf);
   return retval;
#undef ONESAMPLE
}

SAMPLE
linear_interp(const double x, const SAMPLE* yin)
{
   const SAMPLE* y = yin;
   return (SAMPLE) ( y[0] + x * (y[1] - y[0]));
}


/* y = [y(-2),y(-1),y(0),y(1),y(2),y(3)] */
/* Taken from:
 * Olli Niemitalo: Polynomial Interpolators for High-Quality Resampling of
 * Oversampled Audio, URL: http://yehar.com/blog/?p=197  */
SAMPLE
lagrange_interp(const double x, const SAMPLE* yin)
{
   SAMPLE ym1py1, twentyfourthym2py2, c0, c1, c2, c3, c4, c5;
   const SAMPLE* y = yin + 2;
   ym1py1 = y[-1] + y[1];

   twentyfourthym2py2 = 1 / 24.0 * (y[-2] + y[2]);
   c0 = y[0];
   c1 = 1 / 20.0 * y[-2] - 1 / 2.0 * y[-1] - 1 / 3.0 * y[0] + y[1] -
        1 / 4.0 * y[2] + 1 / 30.0 * y[3];
   c2 = 2 / 3.0 * ym1py1 - 5 / 4.0 * y[0] - twentyfourthym2py2;
   c3 = 5 / 12.0 * y[0] - 7 / 12.0 * y[1] + 7 / 24.0 * y[2] -
        1 / 24.0 * (y[-2] + y[-1] + y[3]);
   c4 = 1 / 4.0 * y[0] - 1 / 6.0 * ym1py1 + twentyfourthym2py2;
   c5 = 1 / 120.0 * (y[3] - y[-2]) + 1 / 24.0 * (y[-1] - y[2]) +
        1 / 12.0 * (y[1] - y[0]);

   return (SAMPLE) ( ((((c5 * x + c4) * x + c3) * x + c2) * x + c1) * x + c0 );
}


/* y = [y(-2),y(-1),y(0),y(1),y(2),y(3)] */
/* Taken from:
 * Olli Niemitalo: Polynomial Interpolators for High-Quality Resampling of
 * Oversampled Audio, URL: http://yehar.com/blog/?p=197  */
SAMPLE
bspline_interp(const double x, const SAMPLE* yin)
{
   SAMPLE ym2py2, ym1py1, y2mym2, y1mym1, sixthym1py1, c0, c1, c2, c3, c4, c5;
   const SAMPLE* y = yin + 2;
   ym1py1 = y[-1] + y[1];
   y1mym1 = y[1]  - y[-1];
   ym2py2 = y[-2] + y[2];
   y2mym2 = y[2]  - y[-2];
   sixthym1py1 = 1.0 / 6.0 * ym1py1;
   c0 = 1 / 120.0 * ym2py2 + 13 / 60.0 * ym1py1 + 11 / 20.0 * y[0];
   c1 = 1 / 24.0 * y2mym2 + 5 / 12.0 * y1mym1;
   c2 = 1 / 12.0 * ym2py2 + sixthym1py1 - 1 / 2.0 * y[0];
   c3 = 1 / 12.0 * y2mym2 - 1 / 6.0 * y1mym1;
   c4 = 1 / 24.0 * ym2py2 - sixthym1py1 + 1 / 4.0 * y[0];
   c5 = 1 / 120.0 * (y[3] - y[-2]) + 1 / 24.0 * (y[-1] - y[2]) +
        1 / 12.0 * (y[1] - y[0]);

   return (SAMPLE) (((((c5 * x + c4) * x + c3) * x + c2) * x + c1) * x + c0);
}



/* This is actual structture used to hold info between consecutive blocks */
struct EMQFfilters_struct
{
   /* Passband edge 0-1 (Nyquist)  */
   const double fc;
   /* Branch 0 filters params */
   const SAMPLE* beta0;
   const SAMPLE* gamma0;
   /* For holding state variables */
   SAMPLE** d0;
   /* Number of 2nd order allpass filter in branch 0 */
   const size_t stages0;
   const SAMPLE* beta1;
   const SAMPLE* gamma1;
   /* For holding state variables */
   SAMPLE** d1;
   /* Number of 2nd order allpass filter in branch 1. */
   const size_t stages1;
   /* Coefficient of the 1st order allpas filter in branch 1. */
   const SAMPLE alpha1;
};




EMQFfilters
emqffilters_init(const double fc)
{
   double alpha, alpha1;
   size_t ii, stages0, stages1;
   SAMPLE *beta0, *gamma0, *beta1, *gamma1, **d0, **d1;
   EMQFfilters rv;

   /* Check valid fc */
   if (fc <= 0 || fc >= 1)
   {
      return NULL;
   }


   /* EMQFcoefs is a global variable, defined in filtcoefs.h
    * generated by a matlab script genfiltcoefs.m */
   const double* beta = EMQFcoefs;


   stages0 = (size_t) ceil(EMQFCOEFLEN / 2.0);
   stages1 = (size_t) floor(EMQFCOEFLEN / 2.0);


   beta0 = malloc(stages0 * sizeof * beta0);
   gamma0 = malloc(stages0 * sizeof * gamma0);

   if (stages1 > 0)
   {
      beta1 = malloc(stages1 * sizeof * beta1);
      gamma1 = malloc(stages1 * sizeof * gamma1);
   }

   d0 = malloc(stages0 * sizeof(SAMPLE*));
   d1 = malloc((stages1 + 1) * sizeof(SAMPLE*));

   alpha = -cos(M_PI * fc);
   alpha1 = (1.0 - sqrt(1.0 - alpha * alpha)) / alpha;

   for (ii = 0; ii < stages0; ii++)
   {
      beta0[ii] = (SAMPLE) ((beta[2 * ii] + alpha1 * alpha1) /
                            (beta[2 * ii] * alpha1 * alpha1 + 1.0) );
      gamma0[ii] = (SAMPLE) (alpha * (1.0 + beta0[ii]));
      d0[ii] = calloc(2, sizeof(SAMPLE));
   }

   for (ii = 0; ii < stages1; ii++)
   {
      beta1[ii] = (SAMPLE) ((beta[2 * ii + 1] + alpha1 * alpha1) /
                            (beta[2 * ii + 1] * alpha1 * alpha1 + 1.0) );
      gamma1[ii] = (SAMPLE) (alpha * (1.0 + beta1[ii]));
      d1[ii] = calloc(2, sizeof(SAMPLE));
   }

   d1[stages1] = calloc(1, sizeof(SAMPLE));

   rv = malloc(sizeof * rv);
   *(double*)&rv->fc = fc;
   *(SAMPLE*)&rv->alpha1 = alpha1;
   rv->beta0 = beta0;
   rv->gamma0 = gamma0;
   rv->beta1 = beta1;
   rv->gamma1 = gamma1;
   rv->d0 = d0;
   rv->d1 = d1;

   *(size_t*)&rv->stages0 = stages0;
   *(size_t*)&rv->stages1 = stages1;
   return rv;
}

/* All 2nd order IIR filters are treated as type II transposed canonical struct.
 * This can work inplace i.e. in==out */
void
emqffilters_dofilter(EMQFfilters ef, const SAMPLE* in, const size_t Lin,
                     SAMPLE* out)
{
   size_t ii, jj;
   SAMPLE startx, x, y = 0;

   for (ii = 0; ii < Lin; ii++)
   {
      /* Branch 0 */
      /* Feedig output of one stage to the input of the next stage */
      startx = in[ii];
      x = startx;
      for (jj = 0; jj < ef->stages0; jj++)
      {
         y = x * ef->beta0[jj] + ef->d0[jj][0];
         ef->d0[jj][0] = ef->gamma0[jj] * (x - y) +
                         ef->d0[jj][1];
         ef->d0[jj][1] = x - y * ef->beta0[jj];
         x = y;
      }
      /* Store the partial output */
      out[ii] = y;
      /* And start over with the second branch */
      x = startx;

      /* Branch 1 */
      for (jj = 0; jj < ef->stages1; jj++)
      {
         y = x * ef->beta1[jj] + ef->d1[jj][0];
         ef->d1[jj][0] = ef->gamma1[jj] * (x - y) +
                         ef->d1[jj][1];
         ef->d1[jj][1] = x - y * ef->beta1[jj];
         x = y;
      }

      /* Final all-pass filter in Branch 1  */
      y = x * ef->alpha1 + ef->d1[ef->stages1][0];
      ef->d1[ef->stages1][0] = x - y * ef->alpha1;

      /* Add output of the second branch to output */
      out[ii] += y;
      /* Normalize. Would it be faster to do it after for the whole array? */
      out[ii] /= 2.0;
   }

}

void
emqffilters_done(EMQFfilters* ef)
{
   size_t ii;
   free((void*)(*ef)->beta0);
   free((void*)(*ef)->gamma0);
   free((void*)(*ef)->beta1);
   free((void*)(*ef)->gamma1);

   for (ii = 0; ii < (*ef)->stages0; ii++)
   {
      free((*ef)->d0[ii]);
   }
   free((*ef)->d0);

   for (ii = 0; ii < (*ef)->stages1 + 1; ii++)
   {
      free((*ef)->d1[ii]);
   }
   free((*ef)->d1);


   free(*ef);
   *ef = NULL;
}
