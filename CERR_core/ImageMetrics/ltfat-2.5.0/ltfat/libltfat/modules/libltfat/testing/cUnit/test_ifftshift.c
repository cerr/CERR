int TEST_NAME(test_ifftshift)()
{
    ltfatInt L[] = {111, 1, 100};

    for (unsigned int lId = 0; lId < ARRAYLEN(L); lId++)
    {
        LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[lId]);
        TEST_NAME(fillRand)(fin, L[lId]);
        LTFAT_TYPE* fout = LTFAT_NAME(malloc)(L[lId]);
        TEST_NAME(fillRand)(fout, L[lId]);

        mu_assert( LTFAT_NAME(ifftshift)(fin, L[lId], fout) == 0,
                   "fftshift");
        mu_assert( LTFAT_NAME(ifftshift)(fin, L[lId], fin) == 0,
                   "fftshift inplace");

        ltfat_free(fin);
        ltfat_free(fout);
    }

    LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(fin, L[0]);
    LTFAT_TYPE* fout = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(fout, L[0]);


    // Inputs can be checked only once
    mu_assert( LTFAT_NAME(ifftshift)(NULL, L[0], fin) == LTFATERR_NULLPOINTER,
               "First is null");
    mu_assert( LTFAT_NAME(ifftshift)(fin, L[0], NULL) == LTFATERR_NULLPOINTER,
               "Last is null");
    mu_assert( LTFAT_NAME(ifftshift)(fin, 0, fout) == LTFATERR_BADSIZE,
               "Zero length");
    mu_assert( LTFAT_NAME(ifftshift)(fin, -1, fout) == LTFATERR_BADSIZE,
               "Negative length");

    mu_assert( LTFAT_NAME(ifftshift)(NULL, -1, fout) < LTFATERR_SUCCESS,
               "Multiple wrong inputs");


    ltfat_free(fin);
    ltfat_free(fout);
    return 0;
}
