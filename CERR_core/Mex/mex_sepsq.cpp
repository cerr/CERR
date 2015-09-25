
#define USAGE_STRING "Usage: S = mex_sepsq(X,Y)"

#include <mex.h>
#include <math.h>

void usage()
{
	printf("%s\n", USAGE_STRING);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

	//
	//	Compute ||x-y||^2 for each pairing x,y of X,Y.
	//
	//	X and Y should be matrices of column vectors, hence D x M and D x N
	//

	if (nrhs != 2) { usage(); mexErrMsgTxt("Requires two input arguments"); }
	if (!mxIsDouble(prhs[0]) || !mxIsDouble(prhs[1])) { usage(); mexErrMsgTxt("Input arguments must be double type"); }

	//
	//	Get Sizes
	//
	
	int D = mxGetM(prhs[0]);
	int M = mxGetN(prhs[0]);
	int N = mxGetN(prhs[1]);
	if (D != mxGetM(prhs[1])) { usage(); mexErrMsgTxt("Input arguments must have same number of rows"); }

	//
	//	Construct output matrix
	//

	plhs[0] = mxCreateDoubleMatrix(M,N,mxREAL);

	//
	//	Do Job
	//

	double temp, accum;
	double *X = mxGetPr(prhs[0]);
	double *Y = mxGetPr(prhs[1]);
	double *S = mxGetPr(plhs[0]);

	for (int m=0; m<M; m++)
	{
		for (int n=0; n<N; n++)
		{
			accum = 0.0;
			for (int d=0; d<D; d++)
			{
				temp = X[d + m * D] - Y[d + n * D];
				accum += temp * temp;
			}
			S[m + n * M] = accum;
		}
	}

}
