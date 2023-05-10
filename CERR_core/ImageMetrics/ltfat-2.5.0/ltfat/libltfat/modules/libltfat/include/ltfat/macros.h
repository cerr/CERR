#ifndef _LTFAT_MACROS_H
#define _LTFAT_MACROS_H

#ifndef M_PI
#define M_PI 3.1415926535897932384626433832795
#endif /* defined(M_PI) */

// To help muting the unused variable compiler warning
// Only works for GCC and Clang
#ifdef __GNUC__
#  define UNUSED(x) UNUSED_ ## x __attribute__((__unused__))
#elif __cplusplus
#  define UNUSED(x) 
#else
#  define UNUSED(x) UNUSED_ ## x
#endif

// "Vectorizes" a function call
#define LTFAT_APPLYFN(type,fn,...) do{ \
   const type list[] = {(const type)0,__VA_ARGS__}; \
   size_t len = sizeof(list)/sizeof(*list) - 1; \
   for(size_t ltfat_applyfn_ii=0;ltfat_applyfn_ii<len;ltfat_applyfn_ii++) \
      fn((const type)list[ltfat_applyfn_ii+1]); \
}while(0)

// Vectorized free
#define LTFAT_SAFEFREEALL(...) LTFAT_APPLYFN(void*,ltfat_safefree,__VA_ARGS__)

// s is evaluated twice, but it is supposed to be a type anyway
#define LTFAT_NEW(s)        ( (s*) ltfat_calloc( 1, sizeof(s)) )
#define LTFAT_NEWARRAY(s,N) ( (s*) ltfat_calloc( (N), sizeof(s)) )
#define LTFAT_POSTPADARRAY(s,ptr,Nold,Nnew) ( (s*) ltfat_postpad( (void*)(ptr), (Nold) * sizeof(s) , (Nnew) * sizeof(s) ) )

#ifdef NDEBUG
#define DEBUG( M, ... )
#define DEBUGNOTE( M )
#else
#define DEBUG(M, ...) fprintf(stderr, "[DEBUG]: (%s:%d:) " M "\n", __FILE__, __LINE__, __VA_ARGS__)
#define DEBUGNOTE(M) fprintf(stderr, "[DEBUG]: (%s:%d:) " M "\n", __FILE__, __LINE__)

#endif


#define CHECK(errcode, A, ...) do{ if(!(A)){status=(errcode); ltfat_error(status, __FILE__, __LINE__,__func__ , __VA_ARGS__); goto error;}}while(0)
#define CHECKSTATUS(A) do{ ptrdiff_t checkstatustmp=(ptrdiff_t)(A); if(checkstatustmp<0){ status = (int)checkstatustmp; goto error;}}while(0)

// The following cannot be just
// #define CHECKSTATUS(errcode, M)  CHECK(errcode,!(errcode), M)
// it evaluates errcode twice!
// #define CHECKSTATUS(errcode, M) do{ status = (errcode); CHECK(status,!(status), M);}while(0)
//#define CHECKSTATUSNOMESG(errcode) do{if((errcode)){status=errcode; goto error;}}while(0)

#define CHECKMEM(A) CHECK(LTFATERR_NOMEM,(A), "Out of memory.")
#define CHECKNULL(A) CHECK(LTFATERR_NULLPOINTER,(A), "%s is a null-pointer.",#A)
#define CHECKINIT(A, M) CHECK(LTFATERR_INITFAILED,(A), M)
#define CHECKCANTHAPPEN(M) CHECK(LTFATERR_CANNOTHAPPEN, 0, M)

#if defined(__cplusplus)
#define LTFAT_STRUCT_BRACKETS(s) s
#else
#define LTFAT_STRUCT_BRACKETS(s) (s)
#endif // defined(__cplusplus)

#define LTFAT_STRUCTINIT(s,...)  (LTFAT_STRUCT_BRACKETS(s){__VA_ARGS__})

#endif /* _LTFAT_MACROS_H */
