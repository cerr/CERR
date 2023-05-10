#define TYPEDEPARGS 0, 1
#define SINGLEARGS
#define REALARGS
#define OCTFILENAME comp_multidgtrealmp // change to filename
#define OCTFILEHELP "This function calls the C-library\n\
                     c=comp_multidgtrealmp(f,g,a,M,ptype,kernthr,errdb,maxit,maxat,do_pedanticsearch);\n Yeah."

#include "ltfat_oct_template_helper.h"

static void
fwd_dgtrealmp_decompose(const float f[], ltfat_int L,
                        const float* g[], ltfat_int gl[],
                        double a[], double M[], ltfat_int dictno,
                        int ptype, int do_pedanticsearch, ltfat_dgtmp_alg alg,
                        double errdb,
                        double kernthr, size_t maxit, size_t maxat,
                        size_t& atoms, size_t& iters, int &dec_status,
                        FloatComplex* c[])
{
    ltfat_dgtrealmp_parbuf_s* pbuf = NULL;
    ltfat_dgtrealmp_state_s*  plan = NULL;
    ltfat_dgtrealmp_parbuf_init_s(&pbuf);

    for(int dIdx=0;dIdx<dictno;dIdx++)
    {
        ltfat_dgtrealmp_parbuf_add_genwin_s(pbuf,
                g[dIdx], gl[dIdx], (ltfat_int) a[dIdx], (ltfat_int) M[dIdx]);
    }

    ltfat_dgtrealmp_setparbuf_phaseconv_s(pbuf, static_cast<ltfat_phaseconvention>( ptype));
    ltfat_dgtrealmp_setparbuf_pedanticsearch_s(pbuf, do_pedanticsearch);
    ltfat_dgtrealmp_setparbuf_alg_s(pbuf, alg);
    ltfat_dgtrealmp_setparbuf_snrdb_s(pbuf, -errdb);
    ltfat_dgtrealmp_setparbuf_kernrelthr_s(pbuf, kernthr);
    ltfat_dgtrealmp_setparbuf_maxatoms_s(pbuf, maxat);
    ltfat_dgtrealmp_setparbuf_maxit_s(pbuf, maxit);
    ltfat_dgtrealmp_setparbuf_iterstep_s(pbuf, L);

    ltfat_dgtrealmp_init_s( pbuf, L, &plan);
    dec_status = ltfat_dgtrealmp_execute_decompose_s(plan, f, c);

    ltfat_dgtrealmp_get_numatoms_s(plan, &atoms);
    ltfat_dgtrealmp_get_numiters_s(plan, &iters);

    if(pbuf) ltfat_dgtrealmp_parbuf_done_s(&pbuf);
    if(plan) ltfat_dgtrealmp_done_s(&plan);
}


static void
fwd_dgtrealmp_decompose(const double f[], ltfat_int L,
                        const double* g[], ltfat_int gl[],
                        double a[], double M[], ltfat_int dictno,
                        int ptype, int do_pedanticsearch, ltfat_dgtmp_alg alg,
                        double errdb,
                        double kernthr, size_t maxit, size_t maxat,
                        size_t& atoms, size_t& iters, int &dec_status,
                        Complex* c[])
{
    ltfat_dgtrealmp_parbuf_d* pbuf = NULL;
    ltfat_dgtrealmp_state_d*  plan = NULL;
    ltfat_dgtrealmp_parbuf_init_d(&pbuf);

    for(int dIdx=0;dIdx<dictno;dIdx++)
    {
        ltfat_dgtrealmp_parbuf_add_genwin_d(pbuf,
                g[dIdx], gl[dIdx], (ltfat_int) a[dIdx], (ltfat_int) M[dIdx]);
    }

    ltfat_dgtrealmp_setparbuf_phaseconv_d(pbuf, static_cast<ltfat_phaseconvention>( ptype));
    ltfat_dgtrealmp_setparbuf_pedanticsearch_d(pbuf, do_pedanticsearch);
    ltfat_dgtrealmp_setparbuf_alg_d(pbuf, alg);
    ltfat_dgtrealmp_setparbuf_snrdb_d(pbuf, -errdb);
    ltfat_dgtrealmp_setparbuf_kernrelthr_d(pbuf, kernthr);
    ltfat_dgtrealmp_setparbuf_maxatoms_d(pbuf, maxat);
    ltfat_dgtrealmp_setparbuf_maxit_d(pbuf, maxit);
    ltfat_dgtrealmp_setparbuf_iterstep_d(pbuf, L);

    ltfat_dgtrealmp_init_d( pbuf, L, &plan);
    dec_status = ltfat_dgtrealmp_execute_decompose_d(plan, f, c);

    ltfat_dgtrealmp_get_numatoms_d(plan, &atoms);
    ltfat_dgtrealmp_get_numiters_d(plan, &iters);

    if(pbuf) ltfat_dgtrealmp_parbuf_done_d(&pbuf);
    if(plan) ltfat_dgtrealmp_done_d(&plan);
}


template <class LTFAT_TYPE, class LTFAT_REAL, class LTFAT_COMPLEX>
octave_value_list octFunction(const octave_value_list& args, int nargout)
{
    size_t atoms = 0;
    size_t iters = 0;
    int dec_status = 0;
    ltfat_dgtmp_alg alg = ltfat_dgtmp_alg_mp;

    // Input data
    MArray<LTFAT_REAL> f = ltfatOctArray<LTFAT_TYPE>(args(0));
    // Cell aray containing impulse responses
    Cell g = args(1).cell_value();
    // Subsampling factors
    Matrix aDouble = args(2).matrix_value();
    Matrix MDouble = args(3).matrix_value();
    int ptype = args(4).int_value() == 1? LTFAT_TIMEINV: LTFAT_FREQINV;
    double kernthr = args(5).double_value();
    double errdb = args(6).double_value();
    size_t maxit = (size_t)args(7).double_value();
    size_t maxat = (size_t)args(8).double_value();
    int do_pedanticsearch = args(9).int_value();
    const char* algstr = args(10).char_matrix_value().row_as_string(0).c_str();

    if( 0 == strcmp("cyclicmp", algstr))
        alg = ltfat_dgtmp_alg_loccyclicmp;
    else if( 0 == strcmp("selfprojmp",algstr))
        alg = ltfat_dgtmp_alg_locselfprojmp;

    // Input length
    const octave_idx_type L  = f.rows();
    const octave_idx_type dictno = g.numel();
    // Allocating temporary arrays
    // Output subband lengths
    // Impulse responses pointers
    OCTAVE_LOCAL_BUFFER (const LTFAT_REAL*, gPtrs, dictno);
    OCTAVE_LOCAL_BUFFER (ltfat_int, glPtr, dictno);
    // Output subbands pointers
    OCTAVE_LOCAL_BUFFER (LTFAT_COMPLEX*, cPtrs, dictno);
    // Output cell elements array,
    OCTAVE_LOCAL_BUFFER (MArray<LTFAT_REAL>, gElems, dictno);
    OCTAVE_LOCAL_BUFFER (MArray<LTFAT_COMPLEX>, c_elems, dictno);

    for (octave_idx_type m = 0; m < dictno; m++)
    {
        gElems[m] = ltfatOctArray<LTFAT_REAL>(g.elem(m));
        glPtr[m] = g.elem(m).numel();
        gPtrs[m] = gElems[m].data();
        octave_idx_type outRows = ((octave_idx_type) MDouble(m))/2 + 1;
        octave_idx_type outCols = (octave_idx_type) ceil( L / aDouble(m) );
        c_elems[m] = MArray<LTFAT_COMPLEX>(dim_vector(outRows, outCols));
        cPtrs[m] = c_elems[m].fortran_vec();
    }

    fwd_dgtrealmp_decompose(f.fortran_vec(), L, gPtrs, glPtr,
                         aDouble.fortran_vec(), MDouble.fortran_vec(),
                         dictno, ptype, do_pedanticsearch, alg,
                         errdb, kernthr, maxit, maxat,
                         atoms, iters, dec_status, cPtrs);

    Cell c(dim_vector(dictno, 1));
    for (octave_idx_type m = 0; m < dictno; ++m)
        c.elem(m) = c_elems[m];

    octave_value_list retlist;
    retlist(0) = c;
    if(nargout > 1) retlist(1) = octave_value((double)atoms);
    if(nargout > 2) retlist(2) = octave_value((double)iters);
    if(nargout > 3) retlist(3) = octave_value((double)dec_status);
    return retlist;
}
