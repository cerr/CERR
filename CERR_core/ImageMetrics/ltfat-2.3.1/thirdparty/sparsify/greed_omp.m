function [s, err_norm, iter_time]=greed_omp(x,A,m,varargin)
%-*- texinfo -*-
%@deftypefn {Function} greed_omp
%@verbatim
% greed_omp: Orthogonal Matching Pursuit using a range of implementations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage
%	[s, cost, iter_time ]=greed_omp(x,P,m,'option_name','option_value')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input
%   Mandatory:
%               x   Observation vector to be decomposed
%               P   Either:
%                       1) An nxm matrix (n must be dimension of x)
%                       2) A function handle (type "help function_format" 
%                          for more information)
%                       3) An object handle (type "help object_format" for 
%                          more information)
%               m   length of s 
%
%   Possible additional options:
%   (specify as many as you want using 'option_name','option_value' pairs)
%   See below for explanation of options:
%__________________________________________________________________________
%   option_name         AVAILABLE OPTION_VALUES                 default
%--------------------------------------------------------------------------
%   solver          AUTO, QR, CHOL, CGP, CG, PINV, LINSOLVE     auto
%   stopCrit        M, CORR, MSE, MSE_CHANGE                    M
%   stopTol         NUMBER (SEE BELOW)                          n/4
%   P_trans         FUNCTION_HANDLE (SEE BELOW)                 
%   maxIter         POSITIVE INTEGER (SEE BELOW)                n
%   verbose         TRUE, FALSE                                 false
%   start_val       VECTOR OF LENGTH M                          zeros
%
%
% Explanation of possible option
%
%   solver: different implementations of OMP are available. The fastest
%           method is the QR algorithm, followed by the Cholesky based 
%           approach. The QR based algorithm requires storage of an nxM
%           matrix and an MxM triangular matrix, for long signals or 
%           large M, this can be too much. The Cholesky based approach
%           requires storage of an upper triangular matrix of size MxM,
%           however, it also requires repeated solutions of inverse systems
%           involving this matrix, which for large M can become slow.
%           Available options are:
%               auto        -   selects from qr, chol or cg depending on
%                               problem size
%               qr          -   uses QR based method
%               chol        -   Uses Cholesky based method
%               cgp         -   Uses Conjugate Gradient Pursuit 
%                               implementation (See [1] for details)
%               cg          -   Solves the inverse problem in each
%                               iteration using Conjugate Gradient
%                               algorithm. This is the only viable option
%                               to solve OMP for very large problems. 
%               pinv        -   Uses matlab PINV command to solve inverse
%                               problem in OMP iteration. (For
%                               reference only.)
%               linsolve    -   Uses matlab LINSOLVE command to solve 
%                               inverse problem in OMP iteration. (For
%                               reference only.)
%
%   stopCrit: Stopping criterion for the algorithm.
%               M           -   Extracts exactly M = stopTol elements.
%               corr        -   Stops when maximum correlation between
%                               residual and atoms is below stopTol value.
%               mse         -   Stops when mean squared error of residual 
%                               is below stopTol value.
%               mse_change  -   Stops when the change in the mean squared 
%                               error falls below stopTol value.
%
%   stopTol: Value for stopping criterion.
%
%   P_trans: If P is a function handle, then P_trans has to be specified and 
%            must be a function handle. 
%
%   maxIter: Maximum number of allowed iterations.
%
%   verbose: Logical value to allow algorithm progress to be displayed.
%
%   start_val: Allows algorithms to start from partial solution.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Outputs
%    s              Solution vector 
%    err_norm       Vector containing norm of approximation error for each 
%                   iteration
%    iter_time      Vector containing computation times for each iteration
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description
%   greed_omp performs a greedy signal decomposition. 
%   In each iteration a new element is selected depending on the inner
%   product between the current residual and columns in P.
%   The non-zero elements of s are approximated by orthogonally projecting 
%   x onto the selected elements in each iteration.
%   Different algorithms are possible to solve this projection. 
%   greed_omp has access to the following implementations (see options):
%   1) QR decomposition based algorithm.
%   2) Cholesky factorisation based algorithm.
%   3) Single Step Conjugate Gradient implementation as described in [1].
%   4) Full Conjugate Gradient solver in each iteration.
%   4) Pseudo Inverse solution in each iteration. (Not recommended!)
%   5) Use of matlab linsolve in each iteration. (Not recommended!)
%
% References
%   [1] T. Blumensath and M.E. Davies, "Gradient Pursuits", submitted, 2007
%
% See Also
%   greed_mp, greed_gp, greed_nomp, greed_omp, greed_pcgp
%
% Copyright (c) 2007 Thomas Blumensath
%
% The University of Edinburgh
% Email: thomas.blumensath@ed.ac.uk
% Comments and bug reports welcome
%
% This file is part of sparsity Version 0.1
% Created: April 2007
%
% Part of this toolbox was developed with the support of EPSRC Grant
% D000246/1
%
% Please read COPYRIGHT.m for terms and conditions.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/thirdparty/sparsify/greed_omp.html}
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           Default values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[n1 n2]=size(x);
if n2 == 1
    n=n1;
elseif n1 == 1
    x=x';
    n=n2;
else
   error('x must be a vector.');
end
    
sigsize     = x'*x/n;
initial_given=0;
err_mse     = [];
iter_time   = [];
SOLVER      = 'auto';
STOPCRIT    = 'M';
STOPTOL     = ceil(n/4);
MAXITER     = n;
verbose     = false;
s_initial   = zeros(m,1);
vectnfact   = ones(m,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           Output variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch nargout 
    case 3
        comp_err=true;
        comp_time=true;
    case 2 
        comp_err=true;
        comp_time=false;
    case 1
        comp_err=false;
        comp_time=false;
    case 0
        error('Please assign output variable.')
    otherwise
        error('Too many output arguments specified')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Look through options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Put option into nice format
Options={};
OS=nargin-3;
c=1;
for i=1:OS
    if isa(varargin{i},'cell')
        CellSize=length(varargin{i});
        ThisCell=varargin{i};
        for j=1:CellSize
            Options{c}=ThisCell{j};
            c=c+1;
        end
    else
        Options{c}=varargin{i};
        c=c+1;
    end
end
OS=length(Options);
if rem(OS,2)
   error('Something is wrong with argument name and argument value pairs.') 
end
for i=1:2:OS
   switch Options{i}
        case {'solver'}  
            if isa(Options{i+1},'char'); SOLVER      = Options{i+1};
            else error('solver must be char string [auto, qr, chol, cgp, cg, pinv, linsolve]. Exiting.'); end
        case {'stopCrit'}
            if (strmatch(Options{i+1},{'M'; 'corr'; 'mse'; 'mse_change'},'exact'));
                STOPCRIT    = Options{i+1};  
            else error('stopCrit must be char string [M, corr, mse, mse_change]. Exiting.'); end 
        case {'stopTol'}
            if isa(Options{i+1},'numeric') ; STOPTOL     = Options{i+1};   
            else error('stopTol must be number. Exiting.'); end
        case {'P_trans'} 
            if isa(Options{i+1},'function_handle'); Pt = Options{i+1};   
            else error('P_trans must be function _handle. Exiting.'); end
        case {'maxIter'}
            if isa(Options{i+1},'numeric'); MAXITER     = Options{i+1};             
            else error('maxIter must be a number. Exiting.'); end
        case {'verbose'}
            if isa(Options{i+1},'logical'); verbose     = Options{i+1};   
            else error('verbose must be a logical. Exiting.'); end 
        case {'vecNormFac'}
            if isa(Options{i+1},'numeric')& length(Options{i+1}) == m , vectnfact = Options{i+1};   
            else error('verbose must be a logical. Exiting.'); end 
        case {'start_val'}
            if isa(Options{i+1},'numeric') & length(Options{i+1}) == m ;
                s_initial     = Options{i+1};   
            else error('start_val must be a vector of length m. Exiting.'); end
         otherwise
            error('Unrecognised option. Exiting.') 
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Make P and Pt functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if          isa(A,'float')      P =@(z) A*z;  Pt =@(z) A'*z;
elseif      isobject(A)         P =@(z) A*z;  Pt =@(z) A'*z;
elseif      isstruct(A) && isfield(A,'frana')
            F = frameaccel(A,n); P = @(z) F.frsyn(z);  Pt = @(z) F.frana(z);
elseif      isa(A,'function_handle')
    try
        if          isa(Pt,'function_handle'); P=A;
        else        error('If P is a function handle, Pt also needs to be a function handle. Exiting.'); end
    catch error('If P is a function handle, Pt needs to be specified. Exiting.'); end
else        error('P is of unsupported type. Use matrix, function_handle or object. Exiting.'); end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 Random Check to see if dictionary is normalised 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%         mask=zeros(m,1);
%         mask(ceil(rand*m))=1;
%         nP=norm(P(mask));
%         if abs(1-nP)>1e-3;
%             display('Dictionary appears not to have unit norm columns.')
%         end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Select algorithm to use
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~any(strcmp(SOLVER,{'auto','qr','chol','cgp','cg','pinv','linsolve'})) 
    display('Unknown solver specified, using automatic selection')
    SOLVER = 'auto';
end
if strcmp(SOLVER,'auto')
    % determine problem size and fastest algo to use
    if strcmp(STOPCRIT,'M') 
        maxM=STOPTOL;
    else
        maxM=MAXITER;
    end
        
	if maxM*n < 1e7 && isa(A,'float')
        try TESTMAT1=zeros(n,maxM);TESTMAT2=zeros(maxM); 
        catch
            try TESTMAT2=zeros(maxM);
            catch
                SOLVER='cg';
                display('Memory requirements too large. Using full conjugate solver in each iteration.')
            end
            clear TESTMAT2
            SOLVER='chol';
            display('Memory requirements too large for QR. Using Cholesky solver.')
        end
            clear TESTMAT1 TESTMAT2
            SOLVER = 'qr';
            display ('Memory requirement acceptable. Using QR method')
	elseif maxM^2 < 1e7
        try TESTMAT2=zeros(maxM);
        catch
            SOLVER='cg';
            display('Memory requirements too large. Using full conjugate solver in each iteration. Reduce maxIter to use other solver.')
        end
        clear TESTMAT2
        SOLVER='chol';
        display('Memory requirements possibly too large for QR. Using Cholesky solver. Reduce maxIter to use QR.')
    else
        SOLVER='cg';
        display('Memory requirements too large. Using full conjugate solver in each iteration.')
    end

end
if strcmp(SOLVER,'qr')
    display('Trying to use QR OMP implementation.')
    try 
        if comp_err
            if comp_time
                [s, err_norm, iter_time]    = greed_omp_qr(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});
            else 
                [s, err_norm]               = greed_omp_qr(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});  
            end
        else
                [s]                         = greed_omp_qr(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});           
        end
     catch 
         display('Error using QR algorithm. Trying Cholesky instead.')
         SOLVER = 'chol';
     end
end
if strcmp(SOLVER,'cgp') 
    error('cgp has been disabled, since it does not work.');
    display('Trying to use CGP implementation.')
     try 
        if comp_err
            if comp_time
                [s, err_norm, iter_time]    = greed_omp_cgp(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});
            else 
                [s, err_norm]               = greed_omp_cgp(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});  
            end
        else
                [s]                         = greed_omp_cgp(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});           
        end
     catch 
         display('Error using CG algorithm. Trying Cholesky instead.')
         SOLVER = 'chol';
     end
end
if strcmp(SOLVER,'chol') 
    display('Trying to use Cholesky OMP implementation.')
     try 
        if comp_err
            if comp_time
                [s, err_norm, iter_time]    = greed_omp_chol(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});
            else 
                [s, err_norm]               = greed_omp_chol(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});  
            end
        else
                [s]                         = greed_omp_chol(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});           
        end
     catch 
         display('Error using Cholesky algorithm. Problem instance probably too large. We recommend the use of greed_gp or greed_acgp.')
     end
end   
if strcmp(SOLVER,'cg') 
    display('Trying to use Full CG OMP implementation. This can take a while....')
     try 
        if comp_err
            if comp_time
                [s, err_norm, iter_time]    = greed_omp_cg(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});
            else 
                [s, err_norm]               = greed_omp_cg(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});  
            end
        else
                [s]                         = greed_omp_cg(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});           
        end
     catch 
         display('Something wrong. Full CG did not work.')
     end
end 
if strcmp(SOLVER,'pinv') 
    display('Trying to use pinv OMP implementation. This can take a while....')
     try 
        if comp_err
            if comp_time
                [s, err_norm, iter_time]    = greed_omp_pinv(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});
            else 
                [s, err_norm]               = greed_omp_pinv(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});  
            end
        else
                [s]                         = greed_omp_pinv(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});           
        end
     catch 
         display('Something wrong. pinv did not work.')
     end
end 
if strcmp(SOLVER,'linsolve') 
    display('Trying to use linsolve OMP implementation. This can take a while....')
     try 
        if comp_err
            if comp_time
                [s, err_norm, iter_time]    = greed_omp_linsolve(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});
            else 
                [s, err_norm]               = greed_omp_linsolve(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});  
            end
        else
                [s]                         = greed_omp_linsolve(x,P,m,{'start_val',s_initial,'stopCrit',STOPCRIT,'stopTol',STOPTOL,'P_trans',Pt,'maxIter',MAXITER,'verbose',verbose,'vecNormFac',vectnfact});           
        end
     catch 
         display('Something wrong. linsolve did not work.')
     end
end 

if ~exist('s','var')
    error('Something is wrong in the code. We should have an answer by now. Exiting.')
end
    
% Change history
%
% 8 of Februray: Algo does no longer stop if dictionary is not normaliesd.
%                Changed automatic selection of QR and Cholesky method.

