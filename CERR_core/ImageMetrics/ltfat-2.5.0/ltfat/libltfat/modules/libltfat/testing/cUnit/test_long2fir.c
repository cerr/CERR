int TEST_NAME(test_long2fir)()
{
    ltfatInt Lfir[] =  {111, 1, 100};
    ltfatInt Llong[] = {111, 2, 102};

    for (unsigned int lId = 0; lId < ARRAYLEN(Lfir); lId++)
    {
        LTFAT_TYPE* fin = LTFAT_NAME(malloc)(Llong[lId]);
        TEST_NAME(fillRand)(fin, Llong[lId]);
        LTFAT_TYPE* fout = LTFAT_NAME(malloc)(Lfir[lId]);
        TEST_NAME(fillRand)(fout, Lfir[lId]);

        mu_assert( LTFAT_NAME(long2fir)(fin, Llong[lId], Lfir[lId], fout) == 0,
                   "long2fir");
        mu_assert( LTFAT_NAME(long2fir)(fin, Llong[lId], Lfir[lId], fin) == 0,
                   "long2fir inplace");

        ltfat_free(fin);
        ltfat_free(fout);
    }

    LTFAT_TYPE* fin = LTFAT_NAME(malloc)(Llong[0]);
    TEST_NAME(fillRand)(fin, Llong[0]);
    LTFAT_TYPE* fout = LTFAT_NAME(malloc)(Lfir[0]);
    TEST_NAME(fillRand)(fout, Lfir[0]);


    // Inputs can be checked only once
    mu_assert( LTFAT_NAME(long2fir)(NULL, Llong[0], Lfir[0],
                                    fin) == LTFATERR_NULLPOINTER,
               "First is null");
    mu_assert( LTFAT_NAME(long2fir)(fin, Llong[0], Lfir[0],
                                    NULL) == LTFATERR_NULLPOINTER,
               "Last is null");
    mu_assert( LTFAT_NAME(long2fir)(fin, 0, Lfir[0], fout) == LTFATERR_BADSIZE,
               "Zero length");
    mu_assert( LTFAT_NAME(long2fir)(fin, -1, Lfir[0], fout) == LTFATERR_BADSIZE,
               "Negative length");

    mu_assert( LTFAT_NAME(long2fir)(fin, 9, 10 , fout) == LTFATERR_BADREQSIZE,
               "Output longer than input");

    mu_assert( LTFAT_NAME(long2fir)(NULL, -1, Lfir[0], fout) < LTFATERR_SUCCESS,
               "Multiple wrong inputs");


    ltfat_free(fin);
    ltfat_free(fout);
    return 0;
}


