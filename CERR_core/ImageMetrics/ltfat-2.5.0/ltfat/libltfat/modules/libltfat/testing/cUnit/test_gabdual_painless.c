int TEST_NAME(test_gabdual_painless)()
{
    ltfatInt gl[] =  {  5,  15, 111};
    ltfatInt a[]  =  {  2,  10,  16};
    ltfatInt M[]  =  { 10,  15, 200};

    for (unsigned int id = 0; id < ARRAYLEN(gl); id++)
    {
        LTFAT_TYPE* f = LTFAT_NAME(malloc)(gl[id]);
        TEST_NAME(fillRand)(f, gl[id]);
        LTFAT_TYPE* g = LTFAT_NAME(malloc)(gl[id]);
        TEST_NAME(fillRand)(g, gl[id]);

        mu_assert(
            LTFAT_NAME(gabdual_painless)(f, gl[id], a[id], M[id], g)
            == LTFATERR_SUCCESS, "gabdual_painless OP");

        mu_assert(
            LTFAT_NAME(gabdual_painless)(f, gl[id], a[id], M[id], f)
            == LTFATERR_SUCCESS, "gabdual_painless IP");

        mu_assert(
            LTFAT_NAME(gabtight_painless)(f, gl[id], a[id], M[id], g)
            == LTFATERR_SUCCESS, "gabtight_painless OP");

        mu_assert(
            LTFAT_NAME(gabtight_painless)(f, gl[id], a[id], M[id], f)
            == LTFATERR_SUCCESS, "gabtight_painless IP");

        ltfat_free(f);
        ltfat_free(g);
    }

    LTFAT_TYPE* f = LTFAT_NAME(malloc)(gl[0]);
    TEST_NAME(fillRand)(f, gl[0]);
    LTFAT_TYPE* g = LTFAT_NAME(malloc)(gl[0]);
    TEST_NAME(fillRand)(g, gl[0]);

    mu_assert(
        LTFAT_NAME(gabdual_painless)(NULL, gl[0], a[0], M[0], g)
        == LTFATERR_NULLPOINTER, "gabdual: Input is null");

    mu_assert(
        LTFAT_NAME(gabtight_painless)(NULL, gl[0], a[0], M[0], g)
        == LTFATERR_NULLPOINTER, "gabtight: Input is null");

    mu_assert(
        LTFAT_NAME(gabdual_painless)(f, gl[0], a[0], M[0], NULL)
        == LTFATERR_NULLPOINTER, "gabdual: Output is null");

    mu_assert(
        LTFAT_NAME(gabtight_painless)(f, gl[0], a[0], M[0], NULL)
        == LTFATERR_NULLPOINTER, "gabtight: Output is null");

    mu_assert(
        LTFAT_NAME(gabdual_painless)(f, 0, a[0], M[0], g)
        == LTFATERR_BADSIZE, "gabdual: bad input length");

    mu_assert(
        LTFAT_NAME(gabtight_painless)(f, 0, a[0], M[0], g)
        == LTFATERR_BADSIZE, "gabtight: bad input length");

    mu_assert(
        LTFAT_NAME(gabdual_painless)(f, gl[0], 0, M[0], g)
        == LTFATERR_NOTPOSARG, "gabdual: bad a");

    mu_assert(
        LTFAT_NAME(gabtight_painless)(f, gl[0], 0, M[0], g)
        == LTFATERR_NOTPOSARG, "gabtight: bad a");

    mu_assert(
        LTFAT_NAME(gabdual_painless)(f, gl[0], a[0], 0, g)
        == LTFATERR_NOTPOSARG, "gabdual: bad M");

    mu_assert(
        LTFAT_NAME(gabtight_painless)(f, gl[0], a[0], 0, g)
        == LTFATERR_NOTPOSARG, "gabtight: bad M");

    mu_assert(
        LTFAT_NAME(gabdual_painless)(f, gl[0], M[0] + 1, M[0], g)
        == LTFATERR_NOTAFRAME, "gabdual: not a frame");

    mu_assert(
        LTFAT_NAME(gabtight_painless)(f, gl[0], M[0] + 1, M[0], g)
        == LTFATERR_NOTAFRAME, "gabtight: not a frame");

    mu_assert(
        LTFAT_NAME(gabdual_painless)(f, a[0] - 1, a[0], M[0], g)
        == LTFATERR_NOTAFRAME, "gabdual: not a frame");

    mu_assert(
        LTFAT_NAME(gabtight_painless)(f, a[0] - 1, a[0], M[0], g)
        == LTFATERR_NOTAFRAME, "gabtight: not a frame");

    mu_assert(
        LTFAT_NAME(gabdual_painless)(f, gl[0], a[0], gl[0] - 1, g)
        == LTFATERR_NOTPAINLESS, "gabdual: not panless");

    mu_assert(
        LTFAT_NAME(gabtight_painless)(f, gl[0], a[0], gl[0] - 1, g)
        == LTFATERR_NOTPAINLESS, "gabtight: not painless");

    ltfat_free(f);
    ltfat_free(g);
    return 0;
}
