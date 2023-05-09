%-*- texinfo -*-
%@deftypefn {Function} README
%@verbatim
%
%
% __________________sparsify Version 0.5__________________
%
%
% __________________sparsify Version 0.4__________________
%
%
% Copyright (c) 2007 Thomas Blumensath
%
% The University of Edinburgh
% Email: thomas.blumensath@ed.ac.uk
% Comments and bug reports welcome
%
% This file is part of sparsity Version 0.4
% Created: January 2009
%
% Part of this toolbox was developed with the support of EPSRC Grant
% D000246/1
%
% Please read COPYRIGHT.m for terms and conditions.
%
%
% __________________INSTALLATION__________________
%
% 1) Copy the folder sparsify wherever you like. 
% 2) Include the folder sparsify and all sub-folders in the Matlab search path.
%
% __________________OVERVIEW__________________
%
% sparsify is a set of Matlab m files implementing a range of different algorithms 
% to calculate sparse signal approximations. See ALGORITHMS below for a list of 
% available algorithms.
%
% __________________COMPATIBILITY__________________
%
% sparsify was tested with Matlab 7.2 and 7.4.
% sparsify does not require any additional toolboxes.
%
% All functions are designed to work with different input formats.
% The specific formatting instructions can be found in function_format.m and
% object_format.m
%
% The function format is compatible to the l1-magic toolbox [1] and with the GPSR software [4].
% The object format is compatible with the l1_ls.m algorithm [3].
% Unfortunately, SparseLab [5] uses a different function format, however, this 
% can easily be converted into the format required for sparsify using: 
% D  =@(z) P(1, m, n, z, I, dim)
% and
% Dt =@(z) P(2, m, n, z, I, dim)
% where P is the function used in SparseLab. D and Dt are then the functions
% required for sparsify. See function_format.m for more information.
%
% 
% __________________STRUCTURE__________________
%
% sparsify contains four sub-folders with the following contents:
% GreedLab   : A range of greedy algorithms (see ALGORITHMS FOR DETAIL)
% HardLab    : A range of iterative hard-thresholding algorithms
% Examples   : Example code demonstrating the use of the algorithms
% TestMethod : A function to test the available algorithms
%
%
% The folder GreedLab contains:
%
% greed_omp.m
% greed_ols.m
% greed_mp.m
% greed_gp.m
% greed_nomp.m
% greed_nomppgc.m
% nonlin_gg.m
% The subfolder OMP_algos containing:
% 	greed_omp_qr.m
% 	greed_omp_chol.m
% 	greed_omp_cg.m
% 	greed_omp_cgp.m
% 	greed_omp_pinv.m
% 	greed_omp_linsolve.m
% 
% The folder HardLab contains:
%
% hard_l0_reg
% hard_lo_Mterm
% 
% The folder Examples contains:
%
% Example_object,m
% Example_function.m
% Example_matrix.m
% MyOp_witharg.m
% MyOpTranspose_witharg.m
% The subfolder @MyObjectName containing:
% 	mtimes.m
% 	MyObjectName.m
% 	ctranspose.m
%
% The folder TestMethod contains:
%
% Testsparsify.m
%
% The folder Papers contains:
%
% 
%
% __________________ALGORITHMS__________________
%
% For more information on each algorithm type "help ALGORITHMNAME.m"
%
% greed_omp.m	Orthogonal matching Pursuit algorithm. Different implementations are 
%		accessible through greed_omp.m. These are also available directly:
%   greed_omp_qr.m 		OMP using QR factorisation (Fastest algorithm but 
%				requires most storage.)
% 	greed_omp_chol.m	OMP using Cholesky factorisation (Slower than QR 
% 				based method but less storage required. Useful up 
%				to around 10 000 non-zero coefficients)
% 	greed_omp_cg.m 		OMP using full conjugate gradient solver in each
%				iteration (Only option if everything else fails. But 
%				can be slow.)
% 	greed_omp_cgp.m		OMP using Conjugate Gradient Pursuit algorithm [1] 
%				(Similar to QR based method)
% 	greed_omp_pinv.m	OMP using pinv command (NOT RECOMMENDED, for 
%				reference only.)	
% 	greed_omp_linsolve.m	OMP using linsolve command (NOT RECOMMENDED, for 
%				reference only.)
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/thirdparty/sparsify/README.html}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% greed_ols.m	Orthogonal Least Squares Algorithm (similar to OMP but with a 
% 		different element selection rule) see [6]. (Requires storage of Dictionary as matrix, so only applicable for small problems.)

% greed_mp.m	Matching Pursuit algorithm

% greed_gp.m 	Greedy Pursuit algorithm from [1] (Can be used if OMP is too costly.)

% greed_nomp.m  Approximate Conjugate Gradient Pursuit (ACGP) from [1] (Can be used 
%		if OMP is too costly. Slower but better than GP in general.)

% greed_nomppgc.m 	Nearly Orthogonal Matching Pursuit with partial Conjugate 
% 		Gradients (NOMPpCG) a mixture between Gradient Pursuit and 
% 		Approximate Conjugate Gradient Pursuit using a gradient step
% 		when a new element is selected and an ACGP step when no new 
% 		element is selected. This guarantees convergence in a finite
% 		number of steps but can give worse results in practice than ACGP. 
% 
% nonlin_gg Gradient based greedy algorithm to solve non-linear sparse problems [8].
%
% hard_l0_reg	Iterative hard thresholding algorithm keeping elements larger than fixed 
%		threshold in each iteration [7].
% hard_lo_Mterm Iterative hard thresholding algorithm keeping largest M elements
%		in each iteration [7, 9, 10]. This algorithm now includes an
%		automatic stepsize calculation as derived in [10]
%
%
% __________________NAMING CONVENTION__________________
%
% All algorithm names are preceded by the identifiers greed_ or hard_ (see above)
% This ensures that conflicts with other toolboxes implementing the same algorithm 
% are avoided. 
%
% __________________REFERENCES__________________
% [1] T. Blumensath and M.E. Davies, "Gradient Pursuits", submitted, 2007
% [2] E. Candes and J. Romberg "l1-magic" http://www.acm.caltech.edu/l1magic/
% [3] K. Koh, S-J Kim and S. Boyd, "l1_ls.m", http://www.stanford.edu/~boyd/l1_ls/
% [4] M. Figueiredo, R. D. Nowak and S. J. Wright "Gradient Projection  for Sparse 
%     Reconstruction (GPSR)", http://www.lx.it.pt/~mtf/GPSR/
% [5] D. Donoho et al., "SparseLab", http://sparselab.stanford.edu/
% [6] S. Chen and S. A. Billings Modelling and analysis of non-linear time series. 
%	International Journal of Control, 50 pp. 2151-2171, 1989
% [7] T. Blumensath and M. Davies "Iterative Thresholding for Sparse Approximations" accepted for publication, 2007
% [8] T. Blumensath and M. E. Davies; "Gradient Pursuit for Non-Linear Sparse Signal Modelling", submitted to EUSIPCO, 2008
% [9] T. Blumensath and M. Davies; "Iterative Hard Thresholding for Compressed Sensing" to appear Applied and Computational Harmonic Analysis 
% [10] T. Blumensath and M. Davies; "A modified Iterative Hard Thresholding algorithm with guaranteed performance and stability" in preparation (title may change) 

