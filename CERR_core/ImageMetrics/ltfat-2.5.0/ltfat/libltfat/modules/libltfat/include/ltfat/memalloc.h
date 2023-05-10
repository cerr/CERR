/** \defgroup memalloc Memory allocation
 *
 * Internally, heap memory allocation in libltfat is done using functions 
 * in this module.
 *
 * By default,
 * <a href="http://www.fftw.org/doc/Memory-Allocation.html">malloc/free</a>
 * functions from FFTW3 are used. FFTW malloc allocates memory properly aligned.
 *
 * A custom malloc/free can be registered using ltfat_set_memory_handler.
 *
 * For convenience, there are versions of functions ltfat_malloc() and ltfat_realloc() 
 * which allow allocating \c double, \c float, \c complex \c double and \c complex \c float arrays.
 *
 * \note According to the FFTW documentation, the allocated memory __is not required__
 * to be aligned, but it is __strongly recommended__ to do so.
 *
 * \addtogroup memalloc
 * @{
 */
#ifndef _LTFAT_MEMALLOC_H
#define _LTFAT_MEMALLOC_H


#ifdef __cplusplus
extern "C"
{
#endif

typedef struct
{
    void* (*malloc) (size_t n);
    void (*free) (void*);
} ltfat_memory_handler_t;

/** Set custom malloc/free functions
 \returns Old malloc/free
 */
ltfat_memory_handler_t
ltfat_set_memory_handler (ltfat_memory_handler_t new_handler);

/** Allocate memory block
 *
 * The function will allocate space for an \a n element array of the
 * corresponding type. The void* version of the function accepts
 * size of the memory block in bytes.
 *
 * \param[in]     n  Size of the block. 
 *
 *  #### Function versions ####
 *  <tt>
 *  void* ltfat_malloc(size_t nbytes);
 *
 *  double* ltfat_malloc_d(size_t n);
 *
 *  ltfat_complex_d* ltfat_malloc_dc(size_t n);
 *
 *  float* ltfat_malloc_s(size_t n);
 *
 *  ltfat_complex_s* ltfat_malloc_sc(size_t n);
 *  </tt>
 *  \returns Valid pointer or NULL if the memory allocation failed.
 */
LTFAT_API void*
ltfat_malloc (size_t n);

/** Allocate memory block and initialize to zero
 *
 * The function will allocate space for an \a nmemb element array of the
 * corresponding type and sets it to zeros. 
 * The void* version of the function additionally needs a size of the array
 * element in bytes \a size.
 *
 * \param[in] nmemb   Number of the elements. 
 * \param[in]  size   Size of a single element in bytes.
 *
 *  #### Function versions ####
 *  <tt>
 *  void* ltfat_calloc(size_t nmemb, size_t size);
 *
 *  double* ltfat_calloc_d(size_t nmemb);
 *
 *  ltfat_complex_d* ltfat_calloc_dc(size_t nmemb);
 *
 *  float* ltfat_calloc_s(size_t nmemb);
 *
 *  ltfat_complex_s* ltfat_calloc_sc(size_t nmemb);
 *  </tt>
 *  \returns Valid pointer or NULL if the memory allocation failed.
 */
LTFAT_API
void* ltfat_calloc (size_t nmemb, size_t size);

/** Re-allocate memory block
 *
 * The function will re-allocate \a nold element array to
 * \a nnew element array of the corresponding type. 
 * The void* version of the function accepts the sizes in bytes.
 * The input memory block \a ptr is freed if it is not NULL. 
 * The function works as \a ltfat_malloc(nnew) if \a ptr==NULL and \a nold is ignored. 
 *
 * \param[in]   ptr    Pointer to the input block  
 * \param[in]   nold   Size of the input block
 * \param[in]   nnew   Size of the output block 
 *
 *  #### Function versions ####
 *  <tt>
 *  void* ltfat_realloc(void *ptr, size_t noldbytes, size_t nnewbytes);
 *
 *  double* ltfat_realloc_d(double *ptr, size_t nold, size_t nnew);
 *
 *  ltfat_complex_d* ltfat_realloc_dc(ltfat_complex_d *ptr, size_t nold, size_t nnew);
 *
 *  float* ltfat_realloc_s(float *ptr, size_t nold, size_t nnew);
 *
 *  ltfat_complex_s* ltfat_realloc_sc(ltfat_complex_s *ptr, size_t nold, size_t nnew);
 *  </tt>
 *  \returns Valid pointer or NULL if the memory allocation failed.
 */
LTFAT_API
void* ltfat_realloc (void *ptr, size_t nold, size_t nnew);

/** Increase the size of a memory block
 *
 *  The function will call \a ltfat_realloc only if \a nnew > \a nold and
 *  sets the padded elements to 0. Otherwise it does nothing.
 *  The function works as \a ltfat_calloc if \a ptr==NULL and \a nold is ignored. 
 *
 *  #### Function versions ####
 *  <tt>
 *  void* ltfat_realloc(void *ptr, size_t noldbytes, size_t nnewbytes);
 *
 *  double* ltfat_realloc_d(double *ptr, size_t nold, size_t nnew);
 *
 *  ltfat_complex_d* ltfat_realloc_dc(ltfat_complex_d *ptr, size_t nold, size_t nnew);
 *
 *  float* ltfat_realloc_s(float *ptr, size_t nold, size_t nnew);
 *
 *  ltfat_complex_s* ltfat_realloc_sc(ltfat_complex_s *ptr, size_t nold, size_t nnew);
 *  </tt>
 *  \returns Valid pointer or NULL if the memory allocation failed.
 */
LTFAT_API void*
ltfat_postpad (void* ptr, size_t nold, size_t nnew);

LTFAT_API
void  ltfat_free(const void *ptr);

/** @} */



LTFAT_API
void  ltfat_safefree(const void *ptr);

#ifdef __cplusplus
}
#endif



#endif
