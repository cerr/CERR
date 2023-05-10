#ifndef _CONFIG_H
#define _CONFIG_H

/* The mx class equivalent to SAMPLE */
#define mxSAMPLE    mxSINGLE_CLASS

/* Format to be used for samples with PortAudio = 32bit */
typedef float SAMPLE;

/* This controls type of polynomial resampling.
 *
 * See enum resample_type in ltfatresample.h for 
 * possible values. */
#define RESAMPLING_TYPE BSPLINE

/* This is a constant used to adjust the critical frequency of the
 * anti-aliasing low-pass filter.
 * The filtering is done only when subsampling is performed.
 */
#define FPADJ           0.92



#endif

