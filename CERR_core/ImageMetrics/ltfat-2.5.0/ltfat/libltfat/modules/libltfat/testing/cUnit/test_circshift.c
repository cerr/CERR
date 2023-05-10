int TEST_NAME(test_circshift)()
{
    ltfatInt L[] = {111, 1, 100};
    ltfatInt shift[] = { -5, 0, 1, -1000, 10540, 5660};

    for (unsigned int lId = 0; lId < ARRAYLEN(L); lId++)
    {
        LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[lId]);
        TEST_NAME(fillRand)(fin, L[lId]);
        LTFAT_TYPE* fout = LTFAT_NAME(malloc)(L[lId]);
        TEST_NAME(fillRand)(fout, L[lId]);

        for (unsigned int shiftId = 0; shiftId < ARRAYLEN(shift); shiftId++)
        {
            mu_assert( LTFAT_NAME(circshift)(fin, L[lId], shift[shiftId], fout) == 0,
                       "circshift");
            mu_assert( LTFAT_NAME(circshift)(fin, L[lId], shift[shiftId], fin) == 0,
                       "circshift inplace");
        }
        ltfat_free(fin);
        ltfat_free(fout);
    }

    LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(fin, L[0]);
    LTFAT_TYPE* fout = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(fout, L[0]);


    // Inputs can be checked only once
    mu_assert( LTFAT_NAME(circshift)(NULL, L[0], shift[0], fin) == LTFATERR_NULLPOINTER,
               "First is null");
    mu_assert( LTFAT_NAME(circshift)(fin, L[0], shift[0], NULL) == LTFATERR_NULLPOINTER,
               "Last is null");
    mu_assert( LTFAT_NAME(circshift)(fin, 0, shift[0], fout) == LTFATERR_BADSIZE,
               "Zero length");
    mu_assert( LTFAT_NAME(circshift)(fin, -1, shift[0], fout) == LTFATERR_BADSIZE,
               "Negative length");

    mu_assert( LTFAT_NAME(circshift)(NULL, -1, shift[0], fout) < LTFATERR_SUCCESS,
               "Multiple wrong inputs");


    ltfat_free(fin);
    ltfat_free(fout);
    return 0;
}



