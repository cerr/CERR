int TEST_NAME(test_normalize)()
{
    ltfatInt L[] = {111, 1, 100};
    ltfat_normalize_t norm[] = { LTFAT_NORM_NULL, LTFAT_NORM_AREA,
                                 LTFAT_NORM_1, LTFAT_NORM_ENERGY,
                                 LTFAT_NORM_2, LTFAT_NORM_INF, LTFAT_NORM_PEAK
                               };

    for (unsigned int lId = 0; lId < ARRAYLEN(L); lId++)
    {
        LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[lId]);
        TEST_NAME(fillRand)(fin, L[lId]);
        LTFAT_TYPE* fout = LTFAT_NAME(malloc)(L[lId]);
        TEST_NAME(fillRand)(fout, L[lId]);


        for (unsigned int nId = 0; nId < ARRAYLEN(norm); nId++)
        {

            mu_assert( LTFAT_NAME(normalize)(fin, L[lId], norm[nId], fout) == 0,
                       "normalize");
            mu_assert( LTFAT_NAME(normalize)(fin, L[lId], norm[nId], fin) == 0,
                       "normalize inplace");
        }

        ltfat_free(fin);
        ltfat_free(fout);
    }

    LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(fin, L[0]);
    LTFAT_TYPE* fout = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(fout, L[0]);


    // Inputs can be checked only once
    mu_assert( LTFAT_NAME(normalize)(NULL, L[0], norm[0],
                                     fin) == LTFATERR_NULLPOINTER,
               "First is null");
    mu_assert( LTFAT_NAME(normalize)(fin, L[0], norm[0],
                                     NULL) == LTFATERR_NULLPOINTER,
               "Last is null");
    mu_assert( LTFAT_NAME(normalize)(fin, 0, norm[0], fout) == LTFATERR_BADSIZE,
               "Zero length");
    mu_assert( LTFAT_NAME(normalize)(fin, -1, norm[0],  fout) == LTFATERR_BADSIZE,
               "Negative length");

    mu_assert( LTFAT_NAME(normalize)(NULL, -1, norm[0], fout) < LTFATERR_SUCCESS,
               "Multiple wrong inputs");

    mu_assert( LTFAT_NAME(normalize)(fin, L[0], 10000,
                                     fout) == LTFATERR_CANNOTHAPPEN,
               "Wrong flag");


    ltfat_free(fin);
    ltfat_free(fout);
    return 0;
}
