/* The 2nd row of this file will be used as additional parameters to gcc
../../thirdparty/Playrec/ltfatresample.c -lm -pedantic -std=c99
*/
#include "../../thirdparty/Playrec/ltfatresample.h"
#include "dbg.h"
#include "minunit.h"



void
fillrand(SAMPLE* a, size_t L)
{
   size_t m;
   srand (time(NULL));
   for (m = 0; m < L; m++)
   {
      a[m] = ((SAMPLE) (rand())) / RAND_MAX;
   }
}


char* test_filter()
{
   size_t L, ii;
   SAMPLE *in, *out, *out2, err;
   EMQFfilters ef;
   size_t bufNo = 10;
   size_t bufLen = 65;
   L = bufNo * bufLen;

   in = malloc(L * sizeof * in);
   fillrand(in, L);
   out = malloc(L * sizeof * out);
   out2 = malloc(L * sizeof * out);


   ef = emqffilters_init(0.1);

   /* Filter by blocks */
   for (ii = 0; ii < bufNo; ii++)
   {
      emqffilters_dofilter(ef, in + ii * bufLen, bufLen, out + ii * bufLen);
   }

   emqffilters_done(&ef);
   ef = emqffilters_init(0.1);
   /* Filter */
   emqffilters_dofilter(ef, in, L, out2);


   emqffilters_done(&ef);

   err = 0;
   for (ii = 0; ii < L; ii++)
   {
      err += abs(out[ii] - out2[ii]);
   }
   free(in);
   free(out);
   free(out2);

   mu_assert(err < 1e-10, "FILT BY BLOCKS")

   return NULL;
}

char* test_resample_fixedLin()
{
   size_t ii, bufNo = 1000, Lout, ratioId = 0, lInId = 0;
   double ratio[] = { 44100.0 / 8001.0, 8001.0 / 44100.0, 1, 0 };

   size_t Lin[] = {896, 63, 10, 478, 966, 7563, 0};
   SAMPLE* out, *in;
   resample_error re;
   resample_plan rp;

   while (Lin[lInId])
   {
      while (ratio[ratioId])
      {
         in = malloc(Lin[lInId] * sizeof * in);

         rp = resample_init(BSPLINE, ratio[ratioId]);

         for (ii = 0; ii < bufNo; ii++)
         {
            Lout = resample_nextoutlen(rp, Lin[lInId]);
            fillrand(in, Lin[lInId]);
            out = malloc(Lout * sizeof * out);

            re = resample_execute(rp, in, Lin[lInId], out, Lout);
            mu_assert(re == RESAMPLE_OK, "Overflow or undeflow in fixed Lin")

            free(out);
         }

         free(in);
         resample_done(&rp);
         ratioId++;
      }
      lInId++;
   }

   return NULL;
}

char* test_resample_altLin()
{
   size_t ii, bufNo = 1000, Lout, ratioId = 0, lInId = 0;
   double ratio[] = { 44100.0 / 8001.0, 8001.0 / 44100.0, 1, 0 };

   size_t Lin[] = {896, 63, 10, 478, 966, 7563, 0};
   SAMPLE* out, *in;
   resample_error re;
   resample_plan rp;

      while (ratio[ratioId])
      {
         in = malloc(Lin[lInId] * sizeof * in);

         rp = resample_init(BSPLINE, ratio[ratioId]);

         for (ii = 0; ii < bufNo; ii++)
         {
            Lout = resample_nextoutlen(rp, Lin[lInId]);
            fillrand(in, Lin[lInId]);
            out = malloc(Lout * sizeof * out);

            re = resample_execute(rp, in, Lin[lInId], out, Lout);
            mu_assert(re == RESAMPLE_OK, "Overflow or undeflow in alternating Lin")

            free(out);
         }

         free(in);
         resample_done(&rp);
         ratioId++;
         if(Lin[++lInId]==0)
         {
            lInId = 0;
         }
      }

   return NULL;
}

char* test_resample_fixedLout()
{
   size_t ii, bufNo = 1000, Lin, ratioId = 0, lInId = 0;
   double ratio[] = { 44100.0 / 8001.0, 8001.0 / 44100.0, 1, 0.99, 0.23, 3.333, 0 };

   size_t Lout[] = {896, 63, 40, 478, 966, 7563, 0};
   SAMPLE* out, *in;
   resample_error re;
   resample_plan rp;

   while (Lout[lInId])
   {
      while (ratio[ratioId])
      {
         rp = resample_init(BSPLINE, ratio[ratioId]);

         out = malloc(Lout[lInId] * sizeof * out);


         for (ii = 0; ii < bufNo; ii++)
         {
            Lin = resample_nextinlen(rp, Lout[lInId]);
            in = malloc(Lin * sizeof(SAMPLE));
            fillrand(in, Lin);

            re = resample_execute(rp, in, Lin, out, Lout[lInId]);
            mu_assert(re == RESAMPLE_OK, "Overflow or undeflow in fixed Lout")


            free(in);
         }

         free(out);
         resample_done(&rp);
         ratioId++;
      }
      lInId++;
   }

   return NULL;
}

char* test_resample_altLout()
{
   size_t ii, bufNo = 1000, Lin, ratioId = 0, lInId = 0;
   double ratio[] = { 44100.0 / 8001.0, 8001.0 / 44100.0, 1, 0.99, 0.23, 3.333, 0 };

   size_t Lout[] = {896, 63, 40, 478, 966, 7563, 0};
   SAMPLE* out, *in;
   resample_error re;
   resample_plan rp;

      while (ratio[ratioId])
      {
         rp = resample_init(BSPLINE, ratio[ratioId]);

         out = malloc(Lout[lInId] * sizeof * out);


         for (ii = 0; ii < bufNo; ii++)
         {
            Lin = resample_nextinlen(rp, Lout[lInId]);
            in = malloc(Lin * sizeof(SAMPLE));
            fillrand(in, Lin);

            re = resample_execute(rp, in, Lin, out, Lout[lInId]);
            mu_assert(re == RESAMPLE_OK, "Overflow or undeflow in alternating Lout")


            free(in);
         }

         free(out);
         resample_done(&rp);
         ratioId++;
         if(Lout[++lInId]==0)
         {
            lInId = 0;
         }
      }
      
  return NULL;
}

char *all_tests()
{
   mu_suite_start();

   mu_run_test(test_filter);
   mu_run_test(test_resample_fixedLin);
   mu_run_test(test_resample_fixedLout);
   mu_run_test(test_resample_altLout);
   mu_run_test(test_resample_altLin);

   return NULL;
}

RUN_TESTS(all_tests)

