int TEST_NAME(test_pgauss)()
{
    ltfatInt L[] = {  111,    1,  100 };
    double  w[] =  {  0.001,  0.1, 0.2 };
    double  c_t[] =  {  0.0,  0.1, -0.2 };
    double  c_f[] =  {  0.0,  0.1, -0.2 };


    for (unsigned int lId = 0; lId < ARRAYLEN(L); lId++)
    {
        LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[lId]);
        TEST_NAME(fillRand)(fin, L[lId]);
        LTFAT_COMPLEX* fincmplx = LTFAT_NAME_COMPLEX(malloc)(L[0]);
        TEST_NAME_COMPLEX(fillRand)(fincmplx, L[0]);


        for (unsigned int wId = 0; wId < ARRAYLEN(w); wId++)
        {
            for (unsigned int ctId = 0; ctId < ARRAYLEN(c_t); ctId++)
            {

                mu_assert(
                    LTFAT_NAME(pgauss)( L[lId], w[wId], c_t[ctId], fin) == LTFATERR_SUCCESS,
                    "pgauss");

                for (unsigned int cfId = 0; cfId < ARRAYLEN(c_f); cfId++)
                {
                    mu_assert(
                        LTFAT_NAME(pgauss_cmplx)( L[lId], w[wId], c_t[ctId], c_f[cfId],
                                                  fincmplx) == LTFATERR_SUCCESS,
                        "pgauss");
                }
            }
        }

        ltfat_free(fin);
        ltfat_free(fincmplx);
    }

    LTFAT_TYPE* fin = LTFAT_NAME(malloc)(L[0]);
    TEST_NAME(fillRand)(fin, L[0]);

    LTFAT_COMPLEX* fincmplx = LTFAT_NAME_COMPLEX(malloc)(L[0]);
    TEST_NAME_COMPLEX(fillRand)(fincmplx, L[0]);

    mu_assert(
        LTFAT_NAME(pgauss)( L[0], w[0], c_t[0], NULL) == LTFATERR_NULLPOINTER,
        "pgauss Array is null");

    mu_assert(
        LTFAT_NAME(pgauss)( 0, w[0], c_t[0], fin) == LTFATERR_BADSIZE,
        "pgauss L is wrong");

    mu_assert(
        LTFAT_NAME(pgauss)( L[0], 0.0,  c_t[0], fin) == LTFATERR_NOTPOSARG,
        "pgauss Wrong t-f ratio");

    mu_assert(
        LTFAT_NAME(pgauss_cmplx)( L[0], w[0], c_t[0], c_f[0],
                                  NULL) == LTFATERR_NULLPOINTER,
        "pgauss cmplx Array is null");

    mu_assert(
        LTFAT_NAME(pgauss_cmplx)( 0, w[0], c_t[0], c_f[0],
                                  fincmplx) == LTFATERR_BADSIZE,
        "pgauss cmplx L is wrong");

    mu_assert(
        LTFAT_NAME(pgauss_cmplx)( L[0], 0.0,  c_t[0], c_f[0],
                                  fincmplx) == LTFATERR_NOTPOSARG,
        "pgauss cmplx Wrong t-f ratio");

    ltfat_free(fin);
    ltfat_free(fincmplx);
    return 0;
}
