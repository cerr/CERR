int TEST_NAME(test_idgtreal_long)()
{
    ltfatInt L[]  =  {120,  90, 160};
    ltfatInt a[]  =  {  2,  10,  16};
    ltfatInt M[]  =  { 10,   9, 160};
    ltfatInt W[]  =  {  1,   3,   5};

    for (unsigned int id = 0; id < ARRAYLEN(L); id++)
    {
        ltfatInt N = L[id] / a[id];
        ltfatInt M2 = M[id] / 2 + 1;
        LTFAT_TYPE* f = LTFAT_NAME(malloc)(L[id] * W[id]);
        TEST_NAME(fillRand)(f, L[id] * W[id]);
        LTFAT_TYPE* g = LTFAT_NAME(malloc)(L[id]);
        TEST_NAME(fillRand)(g, L[id]);


        LTFAT_COMPLEX* c = LTFAT_NAME_COMPLEX(malloc)(M2 * N * W[id]);
        TEST_NAME_COMPLEX(fillRand)(c, M2 * N * W[id]);

        mu_assert(
            LTFAT_NAME(idgtreal_long)(c, g, L[id], W[id], a[id], M[id], LTFAT_FREQINV, f)
            == LTFATERR_SUCCESS, "idgtreal_long FREQINV");

        mu_assert(
            LTFAT_NAME(idgtreal_long)(c, g, L[id], W[id], a[id], M[id], LTFAT_TIMEINV, f)
            == LTFATERR_SUCCESS, "idgtreal_long TIMEINV");

        ltfat_free(f);
        ltfat_free(g);
        ltfat_free(c);
    }

    ltfatInt N = L[0] / a[0];
    ltfatInt M2 = M[0] / 2 + 1;
    LTFAT_TYPE* f = LTFAT_NAME(malloc)(L[0] * W[0]);
    TEST_NAME(fillRand)(f, L[0]*W[0]);
    LTFAT_TYPE* g = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(g, L[0]);


    LTFAT_COMPLEX* c = LTFAT_NAME_COMPLEX(malloc)(M2 * N * W[0]);
    TEST_NAME_COMPLEX(fillRand)(c, M2 * N * W[0]);


    // Inputs can be checked only once
    mu_assert(
        LTFAT_NAME(idgtreal_long)(NULL, g, L[0], W[0], a[0], M[0], LTFAT_FREQINV,
                                f) == LTFATERR_NULLPOINTER,
        "Coefficients array is null");

    mu_assert(
        LTFAT_NAME(idgtreal_long)(c, NULL, L[0], W[0], a[0], M[0], LTFAT_FREQINV,
                                f) == LTFATERR_NULLPOINTER,
        "Window is null");


    mu_assert(
        LTFAT_NAME(idgtreal_long)(c, g, L[0], W[0], a[0], M[0], LTFAT_FREQINV,
                                NULL) == LTFATERR_NULLPOINTER,
        "Signal is null");

    mu_assert(
        LTFAT_NAME(idgtreal_long)(c, g, L[0], 0, a[0], M[0], LTFAT_FREQINV,
                                f) == LTFATERR_NOTPOSARG,
        "W is not positive");

    mu_assert(
        LTFAT_NAME(idgtreal_long)(c, g, 0, W[0], a[0], M[0], LTFAT_FREQINV,
                                f) == LTFATERR_BADSIZE,
        "L is not positive");

    mu_assert(
        LTFAT_NAME(idgtreal_long)(c, g, L[0], W[0], 0, M[0], LTFAT_FREQINV,
                                f) == LTFATERR_NOTPOSARG,
        "a is not positive");

    mu_assert(
        LTFAT_NAME(idgtreal_long)(c, g, L[0], W[0], a[0], 0, LTFAT_FREQINV,
                                f) == LTFATERR_NOTPOSARG,
        "M is not positive");

    mu_assert(
        LTFAT_NAME(idgtreal_long)(c, g, L[0] - 1, W[0], a[0], L[0] - 1, LTFAT_FREQINV,
                                f) == LTFATERR_BADTRALEN,
        "Bad transform length, not divisible by M");

    mu_assert(
        LTFAT_NAME(idgtreal_long)(c, g, L[0], W[0], L[0] - 1, M[0], LTFAT_FREQINV,
                                f) == LTFATERR_BADTRALEN,
        "Bad transform length, not divisible by a");

    mu_assert(
        LTFAT_NAME(idgtreal_long)(c, g, L[0], W[0], a[0], M[0], 5,
                                f) == LTFATERR_CANNOTHAPPEN,
        "Wrong enum value");


    ltfat_free(f);
    ltfat_free(g);
    ltfat_free(c);
    return 0;
}
