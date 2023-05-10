int TEST_NAME(test_fftrealfftshift)()
{
    ltfatInt L[] = {111, 1, 100};

    for (unsigned int lId = 0; lId < ARRAYLEN(L); lId++)
    {
        LTFAT_COMPLEX* fin = LTFAT_NAME_COMPLEX(malloc)(L[lId]);
        TEST_NAME_COMPLEX(fillRand)(fin, L[lId]);
        LTFAT_COMPLEX* fout = LTFAT_NAME_COMPLEX(malloc)(L[lId]);
        TEST_NAME_COMPLEX(fillRand)(fout, L[lId]);

        mu_assert( LTFAT_NAME_COMPLEX(fftrealfftshift)(fin, L[lId], fout) == 0,
                   "fftrealfftshift");
        mu_assert( LTFAT_NAME_COMPLEX(fftrealfftshift)(fin, L[lId], fin) == 0,
                   "fftrealfftshift inplace");

        ltfat_free(fin);
        ltfat_free(fout);
    }

    LTFAT_COMPLEX* fin = LTFAT_NAME_COMPLEX(malloc)(L[0]);
    TEST_NAME_COMPLEX(fillRand)(fin, L[0]);
    LTFAT_COMPLEX* fout = LTFAT_NAME_COMPLEX(malloc)(L[0]);
    TEST_NAME_COMPLEX(fillRand)(fout, L[0]);


    // Inputs can be checked only once
    mu_assert( LTFAT_NAME_COMPLEX(fftrealfftshift)(NULL, L[0],
               fin) == LTFATERR_NULLPOINTER, "First is null");
    mu_assert( LTFAT_NAME_COMPLEX(fftrealfftshift)(fin, L[0],
               NULL) == LTFATERR_NULLPOINTER, "Last is null");
    mu_assert( LTFAT_NAME_COMPLEX(fftrealfftshift)(fin, 0, fout) == LTFATERR_BADSIZE,
               "Zero length");
    mu_assert( LTFAT_NAME_COMPLEX(fftrealfftshift)(fin, -1, fout) == LTFATERR_BADSIZE,
               "Negative length");
    mu_assert( LTFAT_NAME_COMPLEX(fftrealfftshift)(NULL, -1, fout) < LTFATERR_SUCCESS,
               "Multiple wrong inputs");


    ltfat_free(fin);
    ltfat_free(fout);
    return 0;
}
