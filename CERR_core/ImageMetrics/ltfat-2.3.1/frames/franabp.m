function [c,relres,iter,frec,cd] = franabp(F,f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} franabp
%@verbatim
%FRANABP Frame Analysis Basis Pursuit
%   Usage: c = franabp(F,f)
%          c = franabp(F,f,lambda,C,tol,maxit)
%          [c,relres,iter,frec,cd] = franabp(...)
%
%   Input parameters:
%       F        : Frame definition
%       f        : Input signal
%       lambda   : Regularisation parameter.
%       C        : Step size of the algorithm.
%       tol      : Reative error tolerance.
%       maxit    : Maximum number of iterations.
%   Output parameters:
%       c        : Sparse coefficients.
%       relres   : Last relative error.
%       iter     : Number of iterations done.
%       frec     : Reconstructed signal such that frec = frsyn(F,c)
%       cd       : The min c||_2 solution using the canonical dual frame.
%
%   c = FRANABP(F,f) solves the basis pursuit problem
%
%      argmin ||c||_1 subject to Fc = f
%
%   for a general frame F using SALSA (Split Augmented Lagrangian
%   Srinkage algorithm) which is an appication of ADMM (Alternating
%   Direction Method of Multipliers) to the basis pursuit problem.
%
%   The algorithm given F and f and parameters C >0, lambda >0 
%   (see below) acts as follows:
%
%     Initialize c,d
%     repeat
%       v <- soft(c+d,lambda/C) - d
%       d <- F*(FF*)^(-1)(f - Fv)
%       c <- d + v
%     end
%
%   When compared to other algorithms, Fc = f holds exactly (up to a num.
%   prec) in each iteration.
%
%   For a quick execution, the function requires analysis operator of the
%   canonical dual frame F*(FF*)^(-1). By default, the function attempts
%   to call FRAMEDUAL to create the canonical dual frame explicitly.
%   If it is not available, the conjugate gradient method algorithm is
%   used for inverting the frame operator in each iteration of the
%   algorithm.
%   Optionally, the canonical dual frame object or an anonymous function 
%   acting as the analysis operator of the canonical dual frame can be 
%   passed as a key-value pair 'Fd',Fd see below. 
%
%   Optional positional parameters (lambda,C,tol,maxit)
%   ---------------------------------------------------
%
%   lambda
%       A parameter for weighting coefficients in the objective
%       function. For lambda~=1 the basis pursuit problem changes to
%
%          argmin ||lambda c||_1 subject to Fc = f
%
%       lambda can either be a scalar or a vector of the same length
%       as c (in such case the product is carried out elementwise). 
%       One can obtain length of c from length of f by
%       FRAMECLENGTH. FRAMECOEF2NATIVE and FRAMENATIVE2COEF will
%       help with defining weights specific to some regions of
%       coefficients (e.g. channel-specific weighting can be achieved
%       this way).           
%       The default value of lambda is 1.
%
%   C
%      A step parameter of the SALSA algorithm. 
%      The default value of C is the upper frame bound of F. 
%      Depending on the structure of the frame, this can be an expensive
%      operation.
%
%   tol
%      Defines tolerance of relres which is a norm or a relative
%      difference of coefficients obtained in two consecutive iterations
%      of the algorithm.
%      The default value 1e-2.
%
%   maxit
%      Maximum number of iterations to do.
%      The default value is 100.
%
%   Other optional parameters
%   -------------------------
%
%   Key-value pairs:
%
%   'Fd',Fd
%      A canonical dual frame object or an anonymous function 
%      acting as the analysis operator of the canonical dual frame.
%
%   'printstep',printstep
%      Print current status every printstep iteration.
%
%   Flag groups (first one listed is the default):
%
%   'print','quiet'
%       Enables/disables printing of notifications.
%
%   'zeros','frana'
%      Starting point of the algorithm. With 'zeros' enabled, the
%      algorithm starts from coefficients set to zero, with 'frana'
%      the algorithm starts from c=frana(F,f).             
%
%   Returned arguments:
%   -------------------
%
%   [c,relres,iter] = FRANABP(...) returns the residuals relres in a
%   vector and the number of iteration steps done iter.
%
%   [c,relres,iter,frec,cd] = FRANABP(...) returns the reconstructed
%   signal from the coefficients, frec (this requires additional
%   computations) and a coefficients cd minimising the c||_2 norm
%   (this is a byproduct of the algorithm).
%
%   The relationship between the output coefficients frec and c is
%   given by :
%
%     frec = frsyn(F,c);
%
%   And cd and f by :
%
%     cd = frana(framedual(F),f);
%
%   Examples:
%   ---------
%
%   The following example shows how FRANABP produces a sparse
%   representation of a test signal greasy still maintaining a perfect
%   reconstruction:
%
%      f = greasy;
%      % Gabor frame with redundancy 8
%      F = frame('dgtreal','gauss',64,512);
%      % Solve the basis pursuit problem
%      [c,~,~,frec,cd] = franabp(F,f);
%      % Plot sparse coefficients
%      figure(1);
%      plotframe(F,c,'dynrange',50);
%
%      % Plot coefficients obtained by applying an analysis operator of a
%      % dual Gabor system to f*
%      figure(2);
%      plotframe(F,cd,'dynrange',50);
%
%      % Check the reconstruction error (should be close do zero).
%      % frec is obtained by applying the synthesis operator of frame F*
%      % to sparse coefficients c.
%      norm(f-frec)
%
%      % Compare decay of coefficients sorted by absolute values
%      % (compressibility of coefficients)
%      figure(3);
%      semilogx([sort(abs(c),'descend')/max(abs(c)),...
%      sort(abs(cd),'descend')/max(abs(cd))]);
%      legend({'sparsified coefficients','dual system coefficients'});
%
%
%   References:
%     S. Boyd, N. Parikh, E. Chu, B. Peleato, and J. Eckstein. Distributed
%     optimization and statistical learning via the alternating direction
%     method of multipliers. Found. Trends Mach. Learn., 3(1):1--122, Jan.
%     2011. [1]http ]
%     
%     I. Selesnick. L1-Norm Penalized Least Squares with SALSA. OpenStax_CNX,
%     Jan. 2014.
%     
%     References
%     
%     1. http://dx.doi.org/10.1561/2200000016
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/franabp.html}
%@seealso{frame, frana, frsyn, framebounds, franalasso}
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

%   AUTHOR: Zdenek Prusa
%   TO DO: Detect when F is a tight frame and simplify the algorithm. 
%   Maybe add a 'tight' flag to indicate the frame is already tight.

complainif_notenoughargs(nargin,2,'FRANABP');
complainif_notvalidframeobj(F,'FRANABP');

% Define initial value for flags and key/value pairs.
definput.keyvals.C=[];
definput.keyvals.lambda=[];
definput.keyvals.tol=1e-2;
definput.keyvals.maxit=100;
definput.keyvals.printstep=10;
definput.keyvals.Fd=[];
definput.flags.print={'print','quiet'};
definput.flags.startpoint={'zeros','frana'};
[flags,kv,lambda,C]=ltfatarghelper({'lambda','C','tol','maxit'},definput,varargin);

if isempty(lambda)
    lambda = 1;
end

if ~isnumeric(lambda) || any(lambda)<0
    error('%s: ''lambda'' parameter must be positive.',...
          upper(mfilename));
end

%% ----- step 1 : Verify f and determine its length -------
% Change f to correct shape.
[f,~,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],[],upper(mfilename));

if W>1
    error('%s: Input signal can be single channel only.',upper(mfilename));
end

% Do a correct postpad so that we can call F.frana and F.frsyn
% directly.
L = framelength(F,Ls);
f = postpad(f,L);

if isempty(C)
    % Use the upper framebound as C
   [~,C] = framebounds(F,L);
else
   if ~isnumeric(C) || C<=0
       error('%s: ''C'' parameter must be a positive scalar.',...
           upper(mfilename));
   end
end;


if isempty(kv.Fd)
    % If the dual frame was not explicitly passed try creating it
    try
       % Try to create and accelerate the dual frame
       Fd = frameaccel(framedual(F),L);
       Fdfrana = @(insig) Fd.frana(insig);
    catch
       warning(sprintf(['The canonical dual system is not available for a given ',...
           'frame.\n Using franaiter.'],upper(mfilename)));
        % err = lasterror.message;
        % The dual system cannot be created.
        % We will use franaiter instead
       Fdfrana = @(insig) franaiter(F,insig,'tol',1e-14);
    end
else
   if isstruct(kv.Fd) && isfield(kv.Fd,'frana') 
      % The canonical dual frame was passed explicitly as a frame object
      Fd = frameaccel(kv.Fd,L);
      Fdfrana = @(insig) Fd.frana(insig);
   elseif isa(kv.Fd,'function_handle')
      % The anonymous function is expected to do F*(FF*)^(-1)
      Fdfrana = kv.Fd;
   else
       error('%s: Invalid format of Fd.',upper(mfielname));
   end
end

% Accelerate the frame
F = frameaccel(F,L);

% Cache the constant part
cd = Fdfrana(f);

% Intermediate results
d = zeros(size(cd));
% Initial point
if flags.do_frana
   tc0 = F.frana(f);
elseif flags.do_zeros
   tc0 = zeros(size(cd));
end
c = tc0;

threshold = lambda./C;
relres = 1e16;
iter = 0;

if norm(f) == 0
    relres = 0;
    frec = zeros(size(f));
    return;
end

% Main loop
while ((iter < kv.maxit)&&(relres >= kv.tol))
   % Main part of the algorithm 
   v = thresh(c + d,threshold,'soft') - d;
   d = cd - Fdfrana(F.frsyn(v));
   c = d + v;
   
   % Bookkeeping
   relres = norm(c(:)-tc0(:))/norm(tc0(:));
   tc0 = c;
   iter = iter + 1;
   if flags.do_print
     if mod(iter,kv.printstep)==0
       fprintf('Iteration %d: relative error = %f\n',iter,relres);
     end;
   end;
end


if nargout>3
    % Do a reconstruction with the original frame
    frec = postpad(F.frsyn(c),Ls);
    % Reformat to the original shape
    frec = assert_sigreshape_post(frec,dim,permutedsize,order);
end

