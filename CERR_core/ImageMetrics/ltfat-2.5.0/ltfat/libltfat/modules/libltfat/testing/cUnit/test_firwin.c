int TEST_NAME(test_firwin)()
{
    ltfatInt L[] = {111, 1, 100};
    LTFAT_FIRWIN win[] = { LTFAT_HANN, LTFAT_HANNING, LTFAT_NUTTALL10, LTFAT_SQRTHANN,
                           LTFAT_COSINE, LTFAT_SINE, LTFAT_HAMMING, LTFAT_NUTTALL01,
                           LTFAT_SQUARE, LTFAT_RECT, LTFAT_TRIA, LTFAT_TRIANGULAR,
                           LTFAT_BARTLETT, LTFAT_SQRTTRIA, LTFAT_BLACKMAN, LTFAT_BLACKMAN2,
                           LTFAT_NUTTALL, LTFAT_NUTTALL12, LTFAT_OGG, LTFAT_ITERSINE,
                           LTFAT_NUTTALL20, LTFAT_NUTTALL11, LTFAT_NUTTALL02, LTFAT_NUTTALL30,
                           LTFAT_NUTTALL21, LTFAT_NUTTALL03
                         };

    for (unsigned int lId = 0; lId < ARRAYLEN(L); lId++)
    {
        LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[lId]);
        TEST_NAME(fillRand)(fin, L[lId]);


        for (unsigned int nId = 0; nId < ARRAYLEN(win); nId++)
        {
            mu_assert( LTFAT_NAME(firwin)( win[nId], L[lId],  fin) == LTFATERR_SUCCESS,
                       "firwin");
        }

        ltfat_free(fin);
    }

    LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(fin, L[0]);

    mu_assert( LTFAT_NAME(firwin)( win[0], L[0],  NULL) == LTFATERR_NULLPOINTER,
               "Array is null");

    mu_assert( LTFAT_NAME(firwin)( win[0], 0,  fin) == LTFATERR_BADSIZE,
               "gl is wrong");

    mu_assert( LTFAT_NAME(firwin)( 9999, L[0],  fin) == LTFATERR_CANNOTHAPPEN,
               "Wrong enum value");

    ltfat_free(fin);
    return 0;
}
