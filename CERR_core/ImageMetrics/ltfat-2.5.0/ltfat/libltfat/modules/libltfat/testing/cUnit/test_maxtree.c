ltfat_int      L[] = {  9 , 10, 100, 101 };
ltfat_int  depth[] = {  1, 2, 3, 4, 5 };
ltfat_int  rLen[]  = { 1, 2, 3, 4, 7, 8, 10, 19, 21};

for (unsigned int lId = 0; lId < ARRAYLEN(L); lId++)
{
    LTFAT_REAL* fin = LTFAT_NAME_REAL(malloc)(L[lId]);
    TEST_NAME(fillRand)(fin, L[lId]);

    for (unsigned int dId = 0; dId < ARRAYLEN(depth); dId++)
    {
        ltfat_int maxPos;
        LTFAT_REAL max;
        ltfat_int maxPos2;
        LTFAT_REAL max2;
        /* fin[L[lId]-1] = 100; */
        LTFAT_NAME(findmaxinarray)(fin, L[lId], &max, &maxPos);
        printf("max=%.2f, maxPos=%td\n", max, maxPos);

        LTFAT_NAME(maxtree)* p = NULL;
        LTFAT_NAME(maxtree_initwitharray)(L[lId], depth[dId], fin, &p);
        LTFAT_NAME(maxtree_findmax)(p, &max2, &maxPos2);
        printf("max=%.2f, maxPos=%td\n", max2, maxPos2);

        for (unsigned int idx = 0; idx < L[lId]; idx++)
        {
            for (unsigned int rIdx = 0; rIdx < ARRAYLEN(rLen); rIdx++)
            {

                max = -100; max2 = -101; maxPos = -1; maxPos2 = -1;
                TEST_NAME(fillRand)(fin, L[lId]);
                LTFAT_NAME(maxtree_reset)(p, fin);

                for (unsigned int ii = 0; ii < rLen[rIdx]; ii++)
                {
                    ltfat_int pos = idx + ii;
                    if (pos >= L[lId])
                        pos = pos%L[lId];

                    fin[pos] = 100 + ii;
                }

                LTFAT_NAME(findmaxinarray)(fin, L[lId], &max, &maxPos);
                /* printf("max=%.2f, maxPos=%td\n",max,maxPos); */

                LTFAT_NAME(maxtree_setdirty)(p, idx, idx + rLen[rIdx]);
                LTFAT_NAME(maxtree_findmax)(p, &max2, &maxPos2);

                /* printf("max=%.2f, maxPos=%td\n",max2,maxPos2);  */
                mu_assert( max == max2 && maxPos == maxPos2 ,
                           "TREEMAX L=%td, d=%td, idx=%d, r=%td",
                           L[lId], depth[dId], idx, rLen[rIdx] );
            }
        }


        LTFAT_NAME(maxtree_done)(&p);
    }

    ltfat_free(fin);
}
