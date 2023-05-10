#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"


LTFAT_API void
LTFAT_NAME(atrousfilterbank_td)(const LTFAT_TYPE* f, const LTFAT_TYPE* g[],
                                ltfat_int L, ltfat_int gl[],
                                ltfat_int W, ltfat_int a[],
                                ltfat_int skip[], ltfat_int M,
                                LTFAT_TYPE* c, ltfatExtType ext)
{
    for (ltfat_int m = 0; m < M; m++)
    {
        for (ltfat_int w = 0; w < W; w++)
        {
            LTFAT_NAME(atrousconvsub_td)(f + w * L, g[m], L, gl[m], a[m],
                                         skip[m], c + w * M * L + m * L, ext);
        }
    }
}

LTFAT_API void
LTFAT_NAME(iatrousfilterbank_td)(const LTFAT_TYPE* c, const LTFAT_TYPE* g[],
                                 ltfat_int L, ltfat_int gl[],
                                 ltfat_int W, ltfat_int a[],
                                 ltfat_int skip[], ltfat_int M,
                                 LTFAT_TYPE* f, ltfatExtType ext)
{
    // Set output array to zeros, since the array is used as an accumulator
    //memset(f,0,L*W*sizeof*f);
    LTFAT_NAME(clear_array)(f, L * W);

    for (ltfat_int m = 0; m < M; m++)
    {
        for (ltfat_int w = 0; w < W; w++)
        {
            LTFAT_NAME(atrousupconv_td)(c + w * M * L + m * L, g[m], L, gl[m], a[m],
                                        skip[m], f + w * L, ext);
        }
    }

}


LTFAT_API void
LTFAT_NAME(filterbank_td)(const LTFAT_TYPE* f, const LTFAT_TYPE* g[],
                          ltfat_int L, ltfat_int gl[],
                          ltfat_int W, ltfat_int a[],
                          ltfat_int skip[], ltfat_int M,
                          LTFAT_TYPE* c[], ltfatExtType ext)
{
    for (ltfat_int m = 0; m < M; m++)
    {
        ltfat_int N = filterbank_td_size(L, a[m], gl[m], skip[m], ext);
        for (ltfat_int w = 0; w < W; w++)
        {

            LTFAT_NAME(convsub_td)(f + w * L, g[m], L, gl[m], a[m],
                                   skip[m], c[m] + w * N, ext);
        }
    }
}


LTFAT_API void
LTFAT_NAME(ifilterbank_td)(const LTFAT_TYPE* c[], const LTFAT_TYPE* g[],
                           ltfat_int L, ltfat_int gl[],
                           ltfat_int W, ltfat_int a[],
                           ltfat_int skip[], ltfat_int M,
                           LTFAT_TYPE* f, ltfatExtType ext)
{
    /* memset(f, 0, L * W * sizeof * f); */
    LTFAT_NAME(clear_array)(f, L * W);

    for (ltfat_int m = 0; m < M; m++)
    {
        ltfat_int N = filterbank_td_size(L, a[m], gl[m], skip[m], ext);
        for (ltfat_int w = 0; w < W; w++)
        {

            LTFAT_NAME(upconv_td)(c[m] + w * N, g[m], L, gl[m], a[m],
                                  skip[m], f + w * L, ext);
        }
    }

}


LTFAT_API void
LTFAT_NAME(atrousconvsub_td)(const LTFAT_TYPE* f, const LTFAT_TYPE* g,
                             ltfat_int L, ltfat_int gl, ltfat_int ga,
                             ltfat_int skip, LTFAT_TYPE* c, ltfatExtType ext)
{
    /* memset(c, 0, L * sizeof * c); */
    LTFAT_NAME(clear_array)(c, L );

    ltfat_int skipLoc = -skip;
    LTFAT_TYPE* filtRev = LTFAT_NAME(malloc)(gl);
    LTFAT_NAME(reverse_array)(g, gl, filtRev);

    ltfat_int glUps = ga * gl - (ga - 1);

    LTFAT_TYPE* righExtbuff = 0;
    // number of output samples that can be calculated "painlessly"
    ltfat_int Nsafe = ltfat_imax((L - skipLoc), 0);

    // prepare cyclic buf of length of power of two (for effective modulo operations)
    ltfat_int bufgl = ltfat_nextpow2(glUps);
    // buf index
    ltfat_int buffPtr = 0;

    // allocating and initializing the cyclic buf
    LTFAT_TYPE* buf = LTFAT_NAME(calloc)(bufgl);

    // pointer for moving in the input data
    const LTFAT_TYPE* tmpIn = f;
    LTFAT_TYPE* tmpOut = c;
    LTFAT_TYPE* tmpg = filtRev;
    LTFAT_TYPE* tmpBuffPtr = buf;

    // fill buf with the initial values from the input signal according to the boundary treatment
    // last glUps buf samples are filled to keep buffPtr=0
    LTFAT_NAME(extend_left)(f, L, buf, bufgl, glUps, ext, 1);

    if (Nsafe < L)
    {
        // right extension is necessary, additional buf from where to copy
        righExtbuff = LTFAT_NAME(calloc)(bufgl);
        /* memset(righExtbuff, 0, bufgl * sizeof(LTFAT_TYPE)); */
        // store extension in the buf (must be done now to avoid errors when inplace calculation is done)
        LTFAT_NAME(extend_right)(f, L, righExtbuff, glUps, ext, 1);
    }

#define ONEOUTSAMPLE                                                    \
         tmpg = filtRev;                                           \
         ltfat_int revBufPtr = ltfat_modpow2(buffPtr-glUps,bufgl);             \
         ltfat_int loop1it = gl+1;                                         \
	      while(--loop1it)                                              \
	      {                                                             \
		     tmpBuffPtr = buf + ltfat_modpow2(revBufPtr,bufgl);          \
		     revBufPtr+=ga;                                         \
           *tmpOut += *(tmpBuffPtr) * *(tmpg++);                  \
         }                                                             \
         tmpOut++;


#define READNEXTDATA(samples,wherePtr)                                              \
	   buffOver = ltfat_imax(buffPtr+(samples)-bufgl, 0);                               \
   	memcpy(buf + buffPtr, wherePtr, ((samples)-buffOver)*sizeof(LTFAT_TYPE)); \
	   memcpy(buf,wherePtr+(samples)-buffOver,buffOver*sizeof(LTFAT_TYPE));      \
	   buffPtr = ltfat_modpow2(buffPtr += (samples),bufgl);

#define READNEXTSAMPLE(wherePtr)                               \
   	   *(buf + buffPtr) = *wherePtr;                        \
	   buffPtr = ltfat_modpow2(++buffPtr,bufgl);


    ltfat_int buffOver = 0;
    /*** initial buf fill ***/
    ltfat_int sampToRead = ltfat_imin((skipLoc + 1), L);
    READNEXTDATA(sampToRead, tmpIn);
    tmpIn += sampToRead;

    /*********** STEP 1: FREE LUNCH ( but also a hot-spot) *******************************/
    // Take the smaller value from "painless" output length and the user defined output length
    ltfat_int iiLoops = ltfat_imin(Nsafe - 1, L - 1);

    // loop trough all output samples, omit the very last one.
    for (ltfat_int ii = 0; ii < iiLoops; ii++)
    {
        ONEOUTSAMPLE
        READNEXTSAMPLE(tmpIn)
        tmpIn++;
    }

    /*********** STEP 2: FINALIZE FREE LUNCH ************************************/
    if (Nsafe > 0)
    {
        ONEOUTSAMPLE
    }
    /*********** STEP 3: NOW FOR THE TRICKY PART ************************************/
    if (Nsafe < L)
    {
        /************ STEP 3a: DEALING WITH THE REMAINING SAMPLES ******************/
        // CAREFULL NOW! possibly stepping outside of input signal
        // last index in the input signal for which reading next a samples reaches outside of the input signal
        ltfat_int rightExtBuffIdx = 0;
        if (Nsafe > 0)
        {
            ltfat_int lastInIdx = ((Nsafe - 1) + 1 + skipLoc);
            rightExtBuffIdx = lastInIdx + 1 - L;
            ltfat_int diff = ltfat_imax(0, L - lastInIdx);
            READNEXTDATA(diff, (f + lastInIdx))
        }
        else
        {
            rightExtBuffIdx = 1 + skipLoc - L;
        }

        // now copying samples that are outside
        READNEXTDATA(rightExtBuffIdx, righExtbuff)

        /************ STEP 3b: ALL OK, proceed reading input values from righExtbuff ******************/
        // loop for the remaining output samples
        for (ltfat_int ii = 0; ii < L - Nsafe; ii++)
        {
            ONEOUTSAMPLE
            READNEXTSAMPLE((righExtbuff + rightExtBuffIdx))
            ++rightExtBuffIdx;
            //rightExtBuffIdx = ltfat_modpow2(++rightExtBuffIdx,bufgl);
        }
    }


#undef READNEXTDATA
#undef READNEXTSAMPLE
#undef ONEOUTSAMPLE
    LTFAT_SAFEFREEALL(buf, filtRev, righExtbuff);
}

LTFAT_API void
LTFAT_NAME(atrousupconv_td)(const LTFAT_TYPE* c, const LTFAT_TYPE* g,
                            ltfat_int L, ltfat_int gl,
                            ltfat_int ga, ltfat_int skip,
                            LTFAT_TYPE* f, ltfatExtType ext)
{
    ltfat_int glUps = ga * gl - (ga - 1);
    ltfat_int skipLoc = -(1 - glUps - skip);

    // Copy, reverse and conjugate the imp resp.
    LTFAT_TYPE* gInv = LTFAT_NAME(malloc)(gl);
    memcpy(gInv, g, gl * sizeof * gInv);
    LTFAT_NAME(reverse_array)(gInv, gl, gInv);
    LTFAT_NAME(conjugate_array)(gInv, gl, gInv);


    // Running output pointer
    LTFAT_TYPE* tmpOut = f;
    // Running input pointer
    LTFAT_TYPE* tmpIn =  (LTFAT_TYPE*) c;

    /** prepare cyclic buf */
    ltfat_int bufgl = ltfat_nextpow2(glUps);
    LTFAT_TYPE* buf = LTFAT_NAME(calloc)(bufgl);
    ltfat_int buffPtr = 0;

    ltfat_int iiLoops = 0;
    ltfat_int remainsOutSamp = L;
    ltfat_int rightBuffPreLoad = 0;

    if (skipLoc >= L)
    {
        rightBuffPreLoad = (skipLoc + 1) - L;
        skipLoc = L;
    }
    else
    {
        iiLoops = ltfat_imin(L - skipLoc, L); // just in case L < L - inSkip
        remainsOutSamp = L - (iiLoops - 1);
    }

    LTFAT_TYPE* rightbuf = LTFAT_NAME(calloc)(bufgl);
    LTFAT_TYPE* rightbufTmp = rightbuf;

    if (ext == PER) // if periodic extension
    {
        LTFAT_NAME(extend_left)(c, L, buf, bufgl, glUps, PER,
                                0); // extension as a last (tmpgl-1) samples of the buf -> pointer dont have to be moved
        LTFAT_NAME(extend_right)(c, L, rightbuf, glUps, PER, 0);
    }

    ltfat_int iniStoCopy = ltfat_imin(skipLoc, bufgl);
    ltfat_int tmpInSkip = ltfat_imax(0, skipLoc - bufgl);
    memcpy(buf, tmpIn + tmpInSkip, iniStoCopy * sizeof * buf);
    tmpIn += (iniStoCopy + tmpInSkip);
    buffPtr = ltfat_modpow2(buffPtr += iniStoCopy, bufgl);


//LTFAT_TYPE* filtTmp = g;
#define ONEOUTSAMPLE(filtTmp,jjLoops)                                   \
	    for(ltfat_int jj=0;jj<(jjLoops);jj++)                                  \
		    {                                                            \
				ltfat_int idx = ltfat_modpow2((-jj*ga+buffPtr-1), bufgl);      \
				*tmpOut += *(buf+idx) * *((filtTmp) + jj);            \
		    }                                                            \
	    tmpOut++;

#define READNEXTSAMPLE(wherePtr)                               \
   	   *(buf + buffPtr) = *(wherePtr);                      \
	   buffPtr = ltfat_modpow2(++buffPtr,bufgl);


    /** STEP 2: MAIN LOOP */
    if (iiLoops > 0)
    {
        for (ltfat_int ii = 0; ii < iiLoops - 1; ii++)
        {
            READNEXTSAMPLE(tmpIn)
            tmpIn++;
            ONEOUTSAMPLE(gInv, gl)
        }
        READNEXTSAMPLE(tmpIn)
        //tmpIn++;
    }


    /** STEP 3b: load samples from right buf */
    while (rightBuffPreLoad--)
    {
        READNEXTSAMPLE((rightbufTmp))
        rightbufTmp++;
    }


    /*
    STEP 3b: calculate remaining output samples,
    Again, there can be shift/up misaligment thne shift>L
    */

    for (ltfat_int ii = 0; ii < remainsOutSamp; ii++)
    {
        if (ii != 0)
        {
            READNEXTSAMPLE((rightbufTmp))
            rightbufTmp++;
        }
        ONEOUTSAMPLE((gInv), (gl))
    }

#undef READNEXTDATA
#undef ONEOUTSAMPLE
    LTFAT_SAFEFREEALL(buf, rightbuf, gInv);
}


LTFAT_API void
LTFAT_NAME(convsub_td)(const LTFAT_TYPE* f, const LTFAT_TYPE* g, ltfat_int L,
                       ltfat_int gl, ltfat_int a, ltfat_int skip,
                       LTFAT_TYPE* c, ltfatExtType ext)
{
    ltfat_int N = filterbank_td_size(L, a, gl, skip, ext);
    // Since c is used as an accu
    LTFAT_NAME(clear_array)(c, N);//memset(c, 0, N * sizeof * c);
    // Reverse and conjugate the filter
    LTFAT_TYPE* filtRev = LTFAT_NAME(malloc)(gl);
    LTFAT_NAME(reverse_array)(g, gl, filtRev);

    LTFAT_TYPE* righExtbuff = 0;
    // number of output samples that can be calculated "painlessly"
    ltfat_int Nsafe = ltfat_imax((L + skip + a - 1) / a, 0);

    // prepare cyclic buf of length of power of two (for effective modulo operations)
    ltfat_int bufgl = ltfat_nextpow2(ltfat_imax(gl, a + 1));
    // buf index
    ltfat_int buffPtr = 0;

    // allocating and initializing the cyclic buf
    LTFAT_TYPE* buf = LTFAT_NAME(calloc)(bufgl);

    // pointer for moving in the input data
    const LTFAT_TYPE* tmpIn = f;
    LTFAT_TYPE* tmpOut = c;
    LTFAT_TYPE* tmpg = filtRev;
    LTFAT_TYPE* tmpBuffPtr = buf;

    // fill buf with the initial values from the input signal according to the boundary treatment
    // last glUps buf samples are filled to keep buffPtr=0
    LTFAT_NAME(extend_left)(f, L, buf, bufgl, gl, ext, a);

    if (Nsafe < N)
    {
        // right extension is necessary, additional buf from where to copy
        righExtbuff = LTFAT_NAME(calloc)(bufgl);
        // store extension in the buf (must be done now to avoid errors when inplace calculation is done)
        LTFAT_NAME(extend_right)(f, L, righExtbuff, gl, ext, a);
    }

#define ONEOUTSAMPLE                                                    \
          tmpg = filtRev;                                           \
          ltfat_int revBufPtr = ltfat_modpow2(buffPtr-gl,bufgl);                \
          ltfat_int loop1it = gl+1;                                         \
	      while(--loop1it)                                              \
	      {                                                             \
		     tmpBuffPtr = buf + ltfat_modpow2(revBufPtr++,bufgl);        \
             *tmpOut += *(tmpBuffPtr) * *(tmpg++);                  \
          }                                                             \
          tmpOut++;



#define READNEXTDATA(samples,wherePtr)                                              \
	   buffOver = ltfat_imax(buffPtr+(samples)-bufgl, 0);                               \
   	memcpy(buf + buffPtr, wherePtr, ((samples)-buffOver)*sizeof*buf); \
	   memcpy(buf,wherePtr+(samples)-buffOver,buffOver*sizeof*buf);      \
	   buffPtr = ltfat_modpow2(buffPtr += (samples),bufgl);


    ltfat_int buffOver = 0;
    /*** initial buf fill ***/
    ltfat_int sampToRead = ltfat_imin((-skip + 1), L);
    READNEXTDATA(sampToRead, tmpIn);
    tmpIn += sampToRead;

    /*********** STEP 1: FREE LUNCH ( but also a hot-spot) *******************************/
    // Take the smaller value from "painless" output length and the user defined output length
    ltfat_int iiLoops = ltfat_imin(Nsafe - 1, N - 1);

    // loop trough all output samples, omit the very last one.
    for (ltfat_int ii = 0; ii < iiLoops; ii++)
    {
        ONEOUTSAMPLE
        READNEXTDATA(a, tmpIn)
        tmpIn += a;
    }

    /*********** STEP 2: FINALIZE FREE LUNCH ************************************/
    if (Nsafe > 0)
    {
        ONEOUTSAMPLE
    }
    /*********** STEP 3: NOW FOR THE TRICKY PART ************************************/
    if (Nsafe < N)
    {
        /************ STEP 3a: DEALING WITH THE REMAINING SAMPLES ******************/
        // CAREFULL NOW! possibly stepping outside of input signal
        // last index in the input signal for which reading next a samples reaches outside of the input signal
        ltfat_int rightExtBuffIdx = 0;
        if (Nsafe > 0)
        {
            ltfat_int lastInIdx = (a * (Nsafe - 1) + 1 - skip);
            rightExtBuffIdx = lastInIdx + a - L;
            ltfat_int diff = ltfat_imax(0, L - lastInIdx);
            READNEXTDATA(diff, (f + lastInIdx))
        }
        else
        {
            rightExtBuffIdx = 1 - skip - L;
        }

        // now copying samples that are outside
        READNEXTDATA(rightExtBuffIdx, righExtbuff)

        /************ STEP 3b: ALL OK, proceed reading input values from righExtbuff ******************/
        // loop for the remaining output samples
        for (ltfat_int ii = 0; ii < N - Nsafe; ii++)
        {
            ONEOUTSAMPLE
            READNEXTDATA(a, (righExtbuff + rightExtBuffIdx))
            rightExtBuffIdx = ltfat_modpow2(rightExtBuffIdx += a, bufgl);
        }
    }


#undef READNEXTDATA
#undef ONEOUTSAMPLE
    LTFAT_SAFEFREEALL(buf, filtRev, righExtbuff);
}


LTFAT_API void
LTFAT_NAME(upconv_td)(const LTFAT_TYPE* c, const LTFAT_TYPE* g, ltfat_int L,
                      ltfat_int gl, ltfat_int a, ltfat_int skip,
                      LTFAT_TYPE* f, ltfatExtType ext)
{
    ltfat_int N = filterbank_td_size(L, a, gl, skip, ext);

    // Copy, reverse and conjugate the imp resp.
    LTFAT_TYPE* gInv = LTFAT_NAME(malloc)(gl);
    memcpy(gInv, g, gl * sizeof * gInv);
    LTFAT_NAME(reverse_array)(gInv, gl, gInv);
    LTFAT_NAME(conjugate_array)(gInv, gl, gInv);
    ltfat_int skipRev = -(1 - gl - skip);

    // Running output pointer
    LTFAT_TYPE* tmpOut = f;
    // Running input pointer
    const LTFAT_TYPE* tmpIn =  c;

    /** prepare cyclic buf */
    ltfat_int bufgl = ltfat_nextpow2(gl);
    LTFAT_TYPE* buf = LTFAT_NAME(calloc)(bufgl);
    ltfat_int buffPtr = 0;

    ltfat_int inSkip = (skipRev + a - 1) / a;
    ltfat_int skipModUp = skipRev % a;
    ltfat_int skipToNextUp = 0;
    if (skipModUp != 0)  skipToNextUp = a - skipModUp;
    ltfat_int outAlign = 0;

    ltfat_int iiLoops = 0;
    ltfat_int uuLoops = 0;
    ltfat_int remainsOutSamp = L;
    ltfat_int rightBuffPreLoad = 0;

    if (inSkip >= N)
    {
        inSkip = N;
        outAlign = skipModUp;
        rightBuffPreLoad = (skipRev + 1 + a - 1) / a - N;
    }
    else
    {
        uuLoops = skipToNextUp;
        iiLoops = ltfat_imin(N - inSkip,
                             (L - skipToNextUp + a - 1) / a); // just in case L/a < N - inSkip
        remainsOutSamp = L - (uuLoops + (iiLoops - 1) * a);
    }

    LTFAT_TYPE* rightbuf = LTFAT_NAME(calloc)(bufgl);
    LTFAT_TYPE* rightbufTmp = rightbuf;

    if (ext == PER) // if periodic extension
    {
        LTFAT_NAME(extend_left)(c, N, buf, bufgl, gl, PER,
                                0); // extension as a last (tmpgl-1) samples of the buf -> pointer dont have to be moved
        LTFAT_NAME(extend_right)(c, N, rightbuf, gl, PER, 0);
    }

    ltfat_int iniStoCopy = ltfat_imin(inSkip, bufgl);
    ltfat_int tmpInSkip = ltfat_imax(0, inSkip - bufgl);
    memcpy(buf, tmpIn + tmpInSkip, iniStoCopy * sizeof * buf);
    tmpIn += (iniStoCopy + tmpInSkip);
    buffPtr = ltfat_modpow2(buffPtr += iniStoCopy, bufgl);



#define ONEOUTSAMPLE(filtTmp,jjLoops)                                   \
	    for(ltfat_int jj=0;jj<(jjLoops);jj++)                                  \
		    {                                                            \
				ltfat_int idx = ltfat_modpow2((-jj+buffPtr-1), bufgl);             \
				*tmpOut += *(buf+idx) * *((filtTmp) +(jj*a));        \
		    }                                                            \
	    tmpOut++;

#define READNEXTSAMPLE(wherePtr)                               \
   	   *(buf + buffPtr) = *(wherePtr);                      \
	   buffPtr = ltfat_modpow2(++buffPtr,bufgl);


    /** STEP 1: Deal with the shift - upsampling misaligment */
    for (ltfat_int uu = 0; uu < uuLoops; uu++)
    {
        ONEOUTSAMPLE((gInv + skipModUp + uu), ((gl - (skipModUp + uu) + a - 1) / a))
    }

    /** STEP 2: MAIN LOOP */
    if (iiLoops > 0)
    {
        for (ltfat_int ii = 0; ii < iiLoops - 1; ii++)
        {
            READNEXTSAMPLE(tmpIn)
            tmpIn++;
            for (ltfat_int uu = 0; uu < a; uu++)
            {
                ONEOUTSAMPLE((gInv + uu), ((gl - uu + a - 1) / a))
            }
        }
        READNEXTSAMPLE(tmpIn)
        tmpIn++;
    }


    /** STEP 3b: load samples from right buf */
    while (rightBuffPreLoad--)
    {
        READNEXTSAMPLE((rightbufTmp))
        rightbufTmp++;
    }


    /*
    STEP 3b: calculate remaining output samples,
    Again, there can be shift/a misaligment thne shift>L
    */

    for (ltfat_int ii = outAlign; ii < remainsOutSamp + outAlign; ii++)
    {
        if (ii != outAlign && ii % a == 0)
        {
            READNEXTSAMPLE((rightbufTmp))
            rightbufTmp++;
        }
        ONEOUTSAMPLE((gInv + ii % a), ((gl - ii % a + a - 1) / a))
    }

#undef ONEOUTSAMPLE
#undef READNEXTSAMPLE
    LTFAT_SAFEFREEALL(buf, rightbuf, gInv);
}





// fills last buf samples
LTFAT_API
void LTFAT_NAME(extend_left)(const LTFAT_TYPE* in, ltfat_int L, LTFAT_TYPE* buf,
                             ltfat_int bufgl, ltfat_int gl, ltfatExtType ext, ltfat_int a)
{
    ltfat_int legalExtLen = (gl - 1) % L;
    ltfat_int LTimes = (gl - 1) / L;
    LTFAT_TYPE* buffTmp = buf + bufgl - legalExtLen;
    switch (ext)
    {
    case SYM: // half-point symmetry
    case EVEN:
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
            buffTmp[ii] = in[legalExtLen - ii - 1];
        break;
    case SYMW: // whole-point symmetry
        legalExtLen = ltfat_imin(gl - 1, L - 1);
        buffTmp = buf + bufgl - legalExtLen;
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
            buffTmp[ii] = in[legalExtLen - ii];
        break;
    case ASYM: // half-point antisymmetry
    case ODD:
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
            buffTmp[ii] = -in[legalExtLen - ii - 1];
        break;
    case ASYMW: // whole-point antisymmetry
        legalExtLen = ltfat_imin(gl - 1, L - 1);
        legalExtLen = ltfat_imin(gl - 1, L - 1);
        buffTmp = buf + bufgl - legalExtLen;
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
            buffTmp[ii] = -in[legalExtLen - ii];
        break;
    case PPD: // periodic padding
    case PER:
    {
        LTFAT_TYPE* bufPtr = buf + bufgl - (gl - 1);
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
        {
            *(bufPtr) = in[L - 1 - (legalExtLen - 1) + ii];
            bufPtr++;
        }

        for (ltfat_int ii = 0; ii < LTimes; ii++)
        {
            for (ltfat_int jj = 0; jj < L; jj++)
            {
                *(bufPtr) = in[jj];
                bufPtr++;
            }
        }

    }
    break;
    case SP0: // constant padding
        buffTmp = buf + bufgl - (gl - 1);
        for (ltfat_int ii = 0; ii < gl - 1; ii++)
            buffTmp[ii] = in[0];
        break;
    case PERDEC: // periodic padding with possible last sample repplication
    {
        ltfat_int rem = L % a;
        if (rem == 0)
        {
            for (ltfat_int ii = 0; ii < legalExtLen; ii++)
                buffTmp[ii] = in[L - 1 - (legalExtLen - 1) + ii];
        }
        else
        {
            ltfat_int remto = a - rem;

            // replicated
            for (ltfat_int ii = 0; ii < remto; ii++)
                buffTmp[legalExtLen - 1 - ii] = in[L - 1];

            // periodic extension
            for (ltfat_int ii = 0; ii < legalExtLen - remto; ii++)
                buffTmp[ii] = in[L - 1 - (legalExtLen - 1 - 1) + ii + remto - 1];
        }
    }
    break;
    case ZPD: // zero-padding by default
    case ZERO:
    case VALID:
    default:
        break;
    }
}

void LTFAT_NAME(extend_right)(const LTFAT_TYPE* in, ltfat_int L,
                              LTFAT_TYPE* buf, ltfat_int gl, ltfatExtType ext, ltfat_int a)
{
    ltfat_int legalExtLen = (gl - 1) % L;
    ltfat_int LTimes = (gl - 1) / L;
    switch (ext)
    {
    case SYM: // half-point symmetry
    case EVEN:
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
            buf[ii] = in[legalExtLen - ii];
        break;
    case SYMW: // whole-point symmetry
        legalExtLen = ltfat_imin(gl - 1, L - 1);
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
            buf[ii] = in[L - 1 - 1 - ii];
        break;
    case ASYM: // half-point antisymmetry
    case ODD:
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
            buf[ii] = -in[L - 1 - ii];
        break;
    case ASYMW: // whole-point antisymmetry
        legalExtLen = ltfat_imin(gl - 1, L - 1);
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
            buf[ii] = -in[L - 1 - 1 - ii];
        break;
    case PPD: // periodic padding
    case PER:
    {
        LTFAT_TYPE* bufPtr = buf;
        for (ltfat_int ii = 0; ii < LTimes; ii++)
        {
            for (ltfat_int jj = 0; jj < L; jj++)
            {
                *(bufPtr) = in[jj];
                bufPtr++;
            }
        }
        for (ltfat_int ii = 0; ii < legalExtLen; ii++)
        {
            *(bufPtr) = in[ii];
            bufPtr++;
        }
    }
    break;
    case SP0: // constant padding
        for (ltfat_int ii = 0; ii < gl; ii++)
            buf[ii] = in[L - 1];
        break;
    case PERDEC: // periodic padding with possible last sample repplication
    {
        ltfat_int rem = L % a;
        if (rem == 0)
        {
            for (ltfat_int ii = 0; ii < legalExtLen; ii++)
                buf[ii] = in[ii];
        }
        else
        {
            ltfat_int remto = a - rem;
            // replicated
            for (ltfat_int ii = 0; ii < remto; ii++)
                buf[ii] = in[L - 1];

            // periodized
            for (ltfat_int ii = 0; ii < legalExtLen - remto; ii++)
                buf[ii + remto] = in[ii];
        }
        break;
    }
    case ZPD: // zero-padding by default
    case ZERO:
    case VALID:
    default:
        break;
    }



}
