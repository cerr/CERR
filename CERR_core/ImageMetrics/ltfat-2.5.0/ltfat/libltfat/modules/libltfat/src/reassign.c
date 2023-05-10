#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"
#include "ltfat/reassign_typeconstant.h"


LTFAT_API void
LTFAT_NAME(gabreassign)(const LTFAT_TYPE* s, const LTFAT_REAL* tgrad,
                        const LTFAT_REAL* fgrad, ltfat_int L, ltfat_int W,
                        ltfat_int a, ltfat_int M, LTFAT_TYPE* sr)
{

    ltfat_int ii, posi, posj;


    ltfat_int N = L / a;
    ltfat_int b = L / M;

    ltfat_int* timepos = (ltfat_int*) ltfat_malloc(N * sizeof * timepos);
    ltfat_int* freqpos = (ltfat_int*) ltfat_malloc(M * sizeof * freqpos);

    ltfat_fftindex(N, timepos);
    ltfat_fftindex(M, freqpos);

    /* Zero the output array. */
    LTFAT_NAME(clear_array)( sr, M * N * W);
    //memset(sr, 0, M * N * W * sizeof * sr);

    for (ltfat_int w = 0; w < W; w++)
    {
        for (ii = 0; ii < M; ii++)
        {
            for (ltfat_int jj = 0; jj < N; jj++)
            {
                /* Do a 'round' followed by a 'mod'. 'round' is not
                 * present in all libraries, so use trunc(x+.5) instead */
                /*posi=ltfat_positiverem((ltfat_int)trunc(tgrad[ii+jj*M]/b+freqpos[ii]+.5),M);
                  posj=ltfat_positiverem((ltfat_int)trunc(fgrad[ii+jj*M]/a+timepos[jj]+.5),N);*/
                posi = ltfat_positiverem(ltfat_round(tgrad[ii + jj * M] / b + freqpos[ii]), M);
                posj = ltfat_positiverem(ltfat_round(fgrad[ii + jj * M] / a + timepos[jj]), N);

                sr[posi + posj * M] += s[ii + jj * M];
            }
        }
    }

    LTFAT_SAFEFREEALL(freqpos, timepos);
}



LTFAT_API void
LTFAT_NAME(filterbankreassign)(const LTFAT_TYPE* s[],
                               const LTFAT_REAL* tgrad[],
                               const LTFAT_REAL* fgrad[],
                               ltfat_int N[], const double a[],
                               const double cfreq[], ltfat_int M,
                               LTFAT_TYPE* sr[],
                               fbreassHints hints,
                               fbreassOptOut*  repos)
{
#define CHECKZEROCROSSINGANDBREAK( CMP, SIGN) \
     { \
        if ( (tmptgrad) CMP 0.0 )\
        {\
           if (fabs(tmptgrad) < fabs(oldtgrad))\
           {\
              tgradIdx[jj] = ii;\
           }\
           else\
           {\
              tgradIdx[jj] = ii SIGN 1;\
           }\
           break;\
        }\
        oldtgrad = tmptgrad;\
     }

    ltfat_int* chan_pos = NULL;

    int doTimeWraparound = !(hints & REASS_NOTIMEWRAPAROUND);

    if (repos)
    {
        chan_pos = (ltfat_int*) ltfat_malloc((M + 1) * sizeof * chan_pos);

        chan_pos[0] = 0;
        for (ltfat_int ii = 0; ii < M; ii++)
        {
            chan_pos[ii + 1] = chan_pos[ii] + N[ii];
        }
    }

    /* Limit tgrad? */

    double oneover2 = 1.0 / 2.0;

    // This will hold center frequencies modulo 2.0
    LTFAT_REAL* cfreq2 = LTFAT_NAME_REAL(malloc)(M);

    for (ltfat_int m = 0; m < M; m++)
    {
        // Zero the output arrays
        /* memset(sr[m], 0, N[m]*sizeof * sr[m]); */
        LTFAT_NAME(clear_array)(sr[m], N[m]);
        // This is effectivelly modulo by 2.0
        cfreq2[m] = (LTFAT_REAL) ( cfreq[m] - floor(cfreq[m] * oneover2) * 2.0 );
    }

    ltfat_int* tgradIdx = NULL;
    ltfat_int* fgradIdx = NULL;
    ltfat_int Nold = 0;
    for (ltfat_int m = M - 1; m >= 0; m--)
    {
        // Ensure the temporary arrays have proper lengths
        if (N[m] > Nold)
        {
            if (tgradIdx)
            {
                ltfat_free(tgradIdx);
            }
            if (fgradIdx)
            {
                ltfat_free(fgradIdx);
            }

            tgradIdx = (ltfat_int*) ltfat_malloc(N[m] * sizeof * tgradIdx);
            fgradIdx = (ltfat_int*) ltfat_malloc(N[m] * sizeof * fgradIdx);
            Nold = N[m];
        }

        // We will use this repeatedly
        LTFAT_REAL cfreqm = cfreq2[m];

        /************************
         *
         * Calculating frequency reassignment
         *
         * **********************
         */
        for (ltfat_int jj = 0; jj < N[m]; jj++)
        {
            //
            LTFAT_REAL tmptgrad = 0.0;
            LTFAT_REAL tgradmjj = tgrad[m][jj] + cfreqm;
            LTFAT_REAL oldtgrad = 10; // 10 seems to be big enough
            // Zero this in case it falls trough, although it might not happen
            tgradIdx[jj] = 0;

            if (tgrad[m][jj] > 0)
            {
                ltfat_int ii;
                // Search for zero crossing

                // If the gradient is bigger than 0, start from m upward....
                for (ii = m; ii < M; ii++)
                {
                    tmptgrad = cfreq2[ii] - tgradmjj;
                    CHECKZEROCROSSINGANDBREAK( >=, -)
                }
                // If the previous for does not break, ii == M
                if (ii == M  && tmptgrad < 0.0)
                {
                    for (ii = 0; ii < m ; ii++)
                    {
                        tmptgrad = (LTFAT_REAL)( cfreq2[ii] - tgradmjj + 2.0 );
                        CHECKZEROCROSSINGANDBREAK( >=, -)
                    }
                }
                if (tgradIdx[jj] < 0)
                {
                    tgradIdx[jj] = M - 1;
                }
            }
            else
            {
                ltfat_int ii;
                for (ii = m; ii >= 0; ii--)
                {
                    tmptgrad = cfreq2[ii] - tgradmjj;
                    CHECKZEROCROSSINGANDBREAK( <=, +)
                }
                // If the previous for does not break, ii=-1
                if (ii == -1 && tmptgrad > 0.0)
                {
                    for (ii = M - 1; ii >= m; ii--)
                    {
                        tmptgrad = (LTFAT_REAL) ( cfreq2[ii] - tgradmjj - 2.0 );
                        CHECKZEROCROSSINGANDBREAK( <=, +)
                    }
                }
                if (tgradIdx[jj] >= M)
                {
                    tgradIdx[jj] = 0;
                }
            }
        }

        /**********************************
         *                                *
         * Calculating time-reassignment  *
         *                                *
         **********************************/

        for (ltfat_int jj = 0; jj < N[m]; jj++)
        {
            ltfat_int tmpIdx = tgradIdx[jj];
            ltfat_int fgradIdxTmp = ltfat_round( (fgrad[m][jj] + a[m] * jj) / a[tmpIdx]);

            if (doTimeWraparound)
            {
                fgradIdx[jj] = ltfat_positiverem( fgradIdxTmp, N[tmpIdx]);
            }
            else
            {
                fgradIdx[jj] = ltfat_rangelimit( fgradIdxTmp, 0, N[tmpIdx] - 1);
            }
        }


        for (ltfat_int jj = 0; jj < N[m]; jj++)
        {
            sr[tgradIdx[jj]][fgradIdx[jj]] += s[m][jj];
        }

        if (repos && chan_pos)
        {
            for (ltfat_int jj = 0; jj < N[m]; jj++)
            {
                ltfat_int tmpIdx =  chan_pos[tgradIdx[jj]] + fgradIdx[jj] ;
                ltfat_int* tmpl = &repos->reposl[tmpIdx];
                repos->repos[tmpIdx][*tmpl] = chan_pos[m] + jj;
                (*tmpl)++;
                if (*tmpl >= repos->reposlmax[tmpIdx])
                {
                    fbreassOptOut_expand(repos, tmpIdx);
                }
            }
        }

    }


    LTFAT_SAFEFREEALL(tgradIdx, fgradIdx, cfreq2, chan_pos);
#undef CHECKZEROCROSSINGANDBREAK
}
