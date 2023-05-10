typedef struct LTFAT_NAME_COMPLEX(hermsystemsolver_plan) LTFAT_NAME_COMPLEX(hermsystemsolver_plan);

LTFAT_API int
LTFAT_NAME_COMPLEX(hermsystemsolver_init)(ltfat_int M,
        LTFAT_NAME_COMPLEX(hermsystemsolver_plan)** p);


LTFAT_API int
LTFAT_NAME_COMPLEX(hermsystemsolver_execute)(
        LTFAT_NAME_COMPLEX(hermsystemsolver_plan)* p,
        const LTFAT_COMPLEX* A, ltfat_int M, LTFAT_COMPLEX* b);

LTFAT_API int
LTFAT_NAME_COMPLEX(hermsystemsolver_done)(
    LTFAT_NAME_COMPLEX(hermsystemsolver_plan)** p);
