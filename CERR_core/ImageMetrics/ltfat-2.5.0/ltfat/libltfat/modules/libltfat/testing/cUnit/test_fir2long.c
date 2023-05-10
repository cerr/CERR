int TEST_NAME(test_fir2long)()
{
    ltfatInt Lfir[] =  {111, 1, 100};
    ltfatInt Llong[] = {111, 2, 102};

    for (unsigned int lId = 0; lId < ARRAYLEN(Lfir); lId++)
    {
        LTFAT_TYPE* fin = LTFAT_NAME(malloc)(Lfir[lId]);
        TEST_NAME(fillRand)(fin, Lfir[lId]);
        LTFAT_TYPE* fout = LTFAT_NAME(malloc)(Llong[lId]);
        TEST_NAME(fillRand)(fout, Llong[lId]);

        mu_assert( LTFAT_NAME(fir2long)(fin, Lfir[lId], Llong[lId], fout) == 0,
                   "fir2long");
        mu_assert( LTFAT_NAME(fir2long)(fout, Lfir[lId], Llong[lId], fout) == 0,
                   "fir2long inplace");

        ltfat_free(fin);
        ltfat_free(fout);
    }

    LTFAT_TYPE* fin = LTFAT_NAME(malloc)(Lfir[0]);
    TEST_NAME(fillRand)(fin, Lfir[0]);
    LTFAT_TYPE* fout = LTFAT_NAME(malloc)(Llong[0]);
    TEST_NAME(fillRand)(fout, Llong[0]);


    // Inputs can be checked only once
    mu_assert( LTFAT_NAME(fir2long)(NULL, Lfir[0], Llong[0],
                                    fin) == LTFATERR_NULLPOINTER,
               "First is null");
    mu_assert( LTFAT_NAME(fir2long)(fin, Lfir[0], Llong[0],
                                    NULL) == LTFATERR_NULLPOINTER,
               "Last is null");
    mu_assert( LTFAT_NAME(fir2long)(fin, 0, Llong[0], fout) == LTFATERR_BADSIZE,
               "Zero length");
    mu_assert( LTFAT_NAME(fir2long)(fin, -1, Llong[0], fout) == LTFATERR_BADSIZE,
               "Negative length");

    mu_assert( LTFAT_NAME(fir2long)(fin, 10, 9 , fout) == LTFATERR_BADREQSIZE,
               "Output shorter than input");

    mu_assert( LTFAT_NAME(fir2long)(NULL, -1, Llong[0], fout) < LTFATERR_SUCCESS,
               "Multiple wrong inputs");


    ltfat_free(fin);
    ltfat_free(fout);
    return 0;
}


