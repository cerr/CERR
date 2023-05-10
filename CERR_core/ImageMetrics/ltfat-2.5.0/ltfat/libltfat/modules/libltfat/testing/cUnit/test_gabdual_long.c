int TEST_NAME(test_gabdual_long)()
{
    ltfatInt L[] =  {  10,  30, 300};
    ltfatInt a[]  =  {  2,  10,  15};
    ltfatInt M[]  =  { 10,  15, 150};

    for (unsigned int id = 0; id < ARRAYLEN(L); id++)
    {
        LTFAT_TYPE* f = LTFAT_NAME(malloc)(L[id]);
        TEST_NAME(fillRand)(f, L[id]);
        LTFAT_TYPE* g = LTFAT_NAME(malloc)(L[id]);
        TEST_NAME(fillRand)(g, L[id]);

        mu_assert(
            LTFAT_NAME(gabdual_long)(f, L[id], a[id], M[id], g)
            == LTFATERR_SUCCESS, "gabdual_long OP");

        mu_assert(
            LTFAT_NAME(gabdual_long)(f, L[id], a[id], M[id], f)
            == LTFATERR_SUCCESS, "gabdual_long IP");

        mu_assert(
            LTFAT_NAME(gabtight_long)(f, L[id], a[id], M[id], g)
            == LTFATERR_SUCCESS, "gabtight_long OP");

        mu_assert(
            LTFAT_NAME(gabtight_long)(f, L[id], a[id], M[id], f)
            == LTFATERR_SUCCESS, "gabtight_long IP");

        ltfat_free(f);
        ltfat_free(g);
    }

    LTFAT_TYPE* f = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(f, L[0]);
    LTFAT_TYPE* g = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(g, L[0]);

    mu_assert(
        LTFAT_NAME(gabdual_long)(NULL, L[0], a[0], M[0], g)
        == LTFATERR_NULLPOINTER, "gabdual: Input is null");

    mu_assert(
        LTFAT_NAME(gabtight_long)(NULL, L[0], a[0], M[0], g)
        == LTFATERR_NULLPOINTER, "gabtight: Input is null");

    mu_assert(
        LTFAT_NAME(gabdual_long)(f, L[0], a[0], M[0], NULL)
        == LTFATERR_NULLPOINTER, "gabdual: Output is null");

    mu_assert(
        LTFAT_NAME(gabtight_long)(f, L[0], a[0], M[0], NULL)
        == LTFATERR_NULLPOINTER, "gabtight: Output is null");

    mu_assert(
        LTFAT_NAME(gabdual_long)(f, 0, a[0], M[0], g)
        == LTFATERR_BADSIZE, "gabdual: bad input length");

    mu_assert(
        LTFAT_NAME(gabtight_long)(f, 0, a[0], M[0], g)
        == LTFATERR_BADSIZE, "gabtight: bad input length");

    mu_assert(
        LTFAT_NAME(gabdual_long)(f, L[0], 0, M[0], g)
        == LTFATERR_NOTPOSARG, "gabdual: bad a");

    mu_assert(
        LTFAT_NAME(gabtight_long)(f, L[0], 0, M[0], g)
        == LTFATERR_NOTPOSARG, "gabtight: bad a");

    mu_assert(
        LTFAT_NAME(gabdual_long)(f, L[0], a[0], 0, g)
        == LTFATERR_NOTPOSARG, "gabdual: bad M");

    mu_assert(
        LTFAT_NAME(gabtight_long)(f, L[0], a[0], 0, g)
        == LTFATERR_NOTPOSARG, "gabtight: bad M");

    mu_assert(
        LTFAT_NAME(gabdual_long)(f, L[0], M[0] + 1, M[0], g)
        == LTFATERR_NOTAFRAME, "gabdual: not a frame");

    mu_assert(
        LTFAT_NAME(gabtight_long)(f, L[0], M[0] + 1, M[0], g)
        == LTFATERR_NOTAFRAME, "gabtight: not a frame");

    mu_assert(
        LTFAT_NAME(gabdual_long)(f, a[0] - 1, a[0], M[0], g)
        == LTFATERR_BADTRALEN, "gabdual: Bad transform length");

    mu_assert(
        LTFAT_NAME(gabtight_long)(f, a[0] - 1, a[0], M[0], g)
        == LTFATERR_BADTRALEN, "gabtight: Bad transform length");

    ltfat_free(f);
    ltfat_free(g);
    return 0;
}
