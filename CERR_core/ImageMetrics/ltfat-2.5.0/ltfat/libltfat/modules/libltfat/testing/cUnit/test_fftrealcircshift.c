int TEST_NAME(test_fftrealcircshift)()
{
    ltfatInt L[] = {111, 1, 100};
    ltfatInt shift[] = { -5, 0, 1, -1000, 10540, 5660};

    for (unsigned int lId = 0; lId < ARRAYLEN(L); lId++)
    {
        LTFAT_COMPLEX* fin = LTFAT_NAME_COMPLEX(malloc)(L[lId]);
        TEST_NAME_COMPLEX(fillRand)(fin, L[lId]);
        LTFAT_COMPLEX* fout = LTFAT_NAME_COMPLEX(malloc)(L[lId]);
        TEST_NAME_COMPLEX(fillRand)(fout, L[lId]);

        for (unsigned int shiftId = 0; shiftId < ARRAYLEN(shift); shiftId++)
        {
            mu_assert( LTFAT_NAME_COMPLEX(fftrealcircshift)(fin, L[lId], shift[shiftId],
                       fout) == 0,
                       "fftrealcirschift");
            mu_assert( LTFAT_NAME_COMPLEX(fftrealcircshift)(fin, L[lId], shift[shiftId],
                       fin) == 0,
                       "fftrealcirschift inplace");
        }

        ltfat_free(fin);
        ltfat_free(fout);
    }

    LTFAT_COMPLEX* fin = LTFAT_NAME_COMPLEX(malloc)(L[0]);
    TEST_NAME_COMPLEX(fillRand)(fin, L[0]);
    LTFAT_COMPLEX* fout = LTFAT_NAME_COMPLEX(malloc)(L[0]);
    TEST_NAME_COMPLEX(fillRand)(fout, L[0]);


    // Inputs can be checked only once
    mu_assert( LTFAT_NAME_COMPLEX(fftrealcircshift)(NULL, L[0], shift[0],
               fin) == LTFATERR_NULLPOINTER,
               "First is null");
    mu_assert( LTFAT_NAME_COMPLEX(fftrealcircshift)(fin, L[0], shift[0],
               NULL) == LTFATERR_NULLPOINTER,
               "Last is null");
    mu_assert( LTFAT_NAME_COMPLEX(fftrealcircshift)(fin, 0, shift[0],
                                        fout) == LTFATERR_BADSIZE,
               "Zero length");
    mu_assert( LTFAT_NAME_COMPLEX(fftrealcircshift)(fin, -1, shift[0],
               fout) == LTFATERR_BADSIZE,
               "Negative length");

    mu_assert( LTFAT_NAME_COMPLEX(fftrealcircshift)(NULL, -1, shift[0],
               fout) < LTFATERR_SUCCESS,
               "Multiple wrong inputs");


    ltfat_free(fin);
    ltfat_free(fout);
    return 0;
}
