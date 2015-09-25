#ifndef MeshContour_h
#define MeshContour_h

/* This is from shrhelp.h */
#ifndef SHRHELP
#define SHRHELP

#ifdef _WIN32
#ifdef EXPORT_FCNS
#define EXPORTED_FUNCTION __declspec(dllexport)
#else
#define EXPORTED_FUNCTION __declspec(dllimport)
#endif
#else
#define EXPORTED_FUNCTION
#endif

#endif
/* end shrhelp.h section */

#ifdef __cplusplus
extern "C"
{
#endif

EXPORTED_FUNCTION void loadVolumeData( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
EXPORTED_FUNCTION void generateSurface( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
//EXPORTED_FUNCTION void generateSurfaceStrictZ( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
EXPORTED_FUNCTION void getContours( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
EXPORTED_FUNCTION void getSurface( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
EXPORTED_FUNCTION void loadSurface( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );

EXPORTED_FUNCTION void clear( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
EXPORTED_FUNCTION void clearAll( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );

EXPORTED_FUNCTION void loadVolumeAndGenerateSurface( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
//EXPORTED_FUNCTION void loadVolumeAndGenerateSurfaceStrictZ( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );

#ifdef __cplusplus
}
#endif

#endif /* MeshContour_h */
