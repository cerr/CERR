function [tc,relres,iter,frec,cd] = franalasso(F,f,lambda,varargin)
%-*- texinfo -*-
%@deftypefn {Function} franalasso
%@verbatim
%FRANALASSO  Frame LASSO regression
%   Usage: tc = franalasso(F,f,lambda)
%          tc = franalasso(F,f,lambda,C,tol,maxit)
%          [tc,relres,iter,frec,cd] = franalasso(...)
%
%   Input parameters:
%       F        : Frame definition
%       f        : Input signal
%       lambda   : Regularisation parameter, controls sparsity of the solution
%       C        : Step size of the algorithm.
%       tol      : Reative error tolerance.
%       maxit    : Maximum number of iterations.
%   Output parameters:
%       tc       : Thresholded coefficients
%       relres   : Vector of residuals.
%       iter     : Number of iterations done.  
%       frec     : Reconstructed signal
%       cd       : The min c||_2 solution using the canonical dual frame.
%
%   FRANALASSO(F,f,lambda) solves the LASSO (or basis pursuit denoising)
%   regression problem for a general frame: minimize a functional of the
%   synthesis coefficients defined as the sum of half the l^2 norm of the
%   approximation error and the l^1 norm of the coefficient sequence, with
%   a penalization coefficient lambda such that
%
%      argmin lambda||c||_1 + 1/2||Fc - f||_2^2
%
%   The solution is obtained via an iterative procedure, called Landweber
%   iteration, involving iterative soft thresholdings.
%
%   The following flags determining an algorithm to be used are recognized
%   at the end of the argument list:
%
%   'ista'
%     The basic (Iterative Soft Thresholding) algorithm given F and f 
%     and parameters C*>0, lambda >0 acts as follows:
%
%        Initialize c
%        repeat until stopping criterion is met
%          c <- soft(c + F*(f - Fc)/C,lambda/C)
%        end
%
%   'fista'
%     The fast version of the previous. This is the default option.
%     :
%
%        Initialize c(0),z,tau(0)=1,n=1
%        repeat until stopping criterion is met
%           c(n) <- soft(z + F*(f - Fz)/C,lambda/C)
%           tau(n) <- (1+sqrt(1+4*tau(n-1)^2))/2
%           z   <- c(n) + (c(n)-c(n-1))(tau(n-1)-1)/tau(n)
%           n   <- n + 1
%        end
%
%   [tc,relres,iter] = FRANALASSO(...) returns the residuals relres in 
%   a vector and the number of iteration steps done iter.
%
%   [tc,relres,iter,frec,cd] = FRANALASSO(...) returns the reconstructed
%   signal from the coefficients, frec and coefficients cd obtained by
%   analysing using the canonical dual system. 
%   Note that this requires additional computations.
%
%   The relationship between the output coefficients and frec is 
%   given by :
%
%     frec = frsyn(F,tc);
%
%   The function takes the following optional parameters at the end of
%   the line of input arguments:
%
%   'C',cval   
%      Landweber iteration parameter: must be larger than square of upper 
%      frame bound. Default value is the upper frame bound.
%
%   'tol',tol  
%      Stopping criterion: minimum relative difference between norms in 
%      two consecutive iterations. Default value is 1e-2.
%
%   'maxit',maxit
%      Stopping criterion: maximal number of iterations to do. Default 
%      value is 100.
%
%   'print'    
%      Display the progress.
%
%   'quiet'    
%      Don't print anything, this is the default.
%
%   'printstep',p
%      If 'print' is specified, then print every p'th iteration. Default 
%      value is 10;
%
%   'debias'
%      Performs debiasing (improves approximation accuracy) of the solution
%      using the conjugate gradient algorithm. This amounts to doing 
%      best-fit with respect to a subdictionary selected by ISTA. 
%
%   'pcgmaxit',pcgmaxit 
%      Maximum allowed number of iterations for pcg. Only used together
%      with the 'debias' flag. The default value is 100.
%   
%   'pcgtol',pcgtol 
%      Tolerance of pcg. Only used together with the 'debias' flag. 
%      The default value is 1e-6.
%
%   The parameters C, itermax and tol may also be specified on the
%   command line in that order: FRANALASSO(F,x,lambda,C,tol,maxit).
%
%   *Note**: If you do not specify C, it will be obtained as the upper
%   framebound. Depending on the structure of the frame, this can be an
%   expensive operation.
%
%   Examples:
%   ---------
%
%   The following example shows how FRANALASSO produces a sparse
%   representation of a test signal greasy*:
%
%      f = greasy;
%      % Gabor frame with redundancy 8
%      F = frame('dgtreal','gauss',64,512);
%      % Choosing lambda (weight of the sparse regularization param.)
%      lambda = 0.1;
%      % Solve the basis pursuit problem
%      [c1,~,~,frec1,cd] = franalasso(F,f,lambda);
%      % Solve again with debiasing enabled
%      [c2,~,~,frec2,cd] = franalasso(F,f,lambda,'debias');
%      % Plot sparse coefficients
%      figure(1); plotframe(F,c1,'dynrange',50);
%      % Plot debiased coefficients
%      figure(2); plotframe(F,c2,'dynrange',50);
%      % Plot coefficients obtained by applying an analysis operator of a
%      % dual Gabor system to f
%      figure(3); plotframe(F,cd,'dynrange',50);
%
%      % Normalized MSE of the approximation
%      % frec is obtained by applying the synthesis operator of frame F
%      % to sparse coefficients c.
%      fprintf('Normalized MSE:                  %.2f dBn',20*log10(norm(f-frec1)/norm(f)));
%      fprintf('Normalized MSE (with debiasing): %.2f dBn',20*log10(norm(f-frec2)/norm(f)));
%
%      % Compare decay of coefficients sorted by absolute values
%      % (compressibility of coefficients)
%      figure(3);
%      semilogx([sort(abs(c1),'descend')/max(abs(c1)),...
%      sort(abs(c2),'descend')/max(abs(c2)),...
%      sort(abs(cd),'descend')/max(abs(cd))]);
%      legend({'sparsified coefficients','with debiasing','dual system coefficients'});
%  
%
%   References:
%     I. Daubechies, M. Defrise, and C. De Mol. An iterative thresholding
%     algorithm for linear inverse problems with a sparsity constraint.
%     Communications in Pure and Applied Mathematics, 57:1413--1457, 2004.
%     
%     A. Beck and M. Teboulle. A fast iterative shrinkage-thresholding
%     algorithm for linear inverse problems. SIAM J. Img. Sci.,
%     2(1):183--202, Mar. 2009.
%     
%     M. A. T. Figueiredo, R. D. Nowak, and S. J. Wright. Gradient projection
%     for sparse reconstruction: Application to compressed sensing and other
%     inverse problems. IEEE Journal of Selected Topics in Signal Processing,
%     1(4):586--597, Dec 2007.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/franalasso.html}
%@seealso{frame, frsyn, framebounds, franabp, franagrouplasso}
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

%   AUTHOR : Bruno Torresani.  
%   TESTING: OK

%   XXX Removed Remark: When the frame is an orthonormal basis, the solution
%   is obtained by soft thresholding of the basis coefficients, with
%   threshold lambda.  When the frame is a union of orthonormal bases, the
%   solution is obtained by applying soft thresholding cyclically on the
%   basis coefficients (BCR algorithm)
%

complainif_notenoughargs(nargin,2,'FRANALASSO');
complainif_notvalidframeobj(F,'FRANALASSO');

if sum(size(f)>1)>1
  error('%s: Too many input channels.',upper(mfilename));
end


% Define initial value for flags and key/value pairs.
definput.keyvals.C=[];
definput.keyvals.tol=1e-2;
definput.keyvals.maxit=100;
definput.keyvals.printstep=10;
definput.flags.print={'print','quiet'};
definput.flags.algorithm={'fista','ista'};
definput.flags.debias = {'nodebias','debias'};
definput.keyvals.pcgmaxit=100;
definput.keyvals.pcgtol=1e-6;
[flags,kv]=ltfatarghelper({'C','tol','maxit'},definput,varargin);


% Accelerate frame, we will need it repeatedly
Ls = size(f,1);
F=frameaccel(F,Ls);
L=F.L;
f = postpad(f,L);

% Use the upper framebound as C
if isempty(kv.C)
  [~,kv.C] = framebounds(F,L);
end;

% Initialization of thresholded coefficients
% frana is used instead of F.frana to get the correct zero padding of f
c0 = frana(F,f);

% Various parameter initializations
threshold = lambda/kv.C;

tc0 = c0;
relres = 1e16;
iter = 0;

if flags.do_ista
   % Main loop
   while ((iter < kv.maxit)&&(relres >= kv.tol))
       tc = c0 - F.frana(F.frsyn(tc0));
       tc = tc0 + tc/kv.C;
       tc = thresh(tc,threshold,'soft');
       relres = norm(tc(:)-tc0(:))/norm(tc0(:));
       tc0 = tc;
       iter = iter + 1;
       if flags.do_print
         if mod(iter,kv.printstep)==0
           fprintf('Iteration %d: relative error = %f\n',iter,relres);
         end;
       end;
   end
elseif flags.do_fista
   tz0 = c0;
   tau0 = 1;
   % Main loop
   while ((iter < kv.maxit)&&(relres >= kv.tol))
       tc = c0 - F.frana(F.frsyn(tz0));
       tc = tz0 + tc/kv.C;
       tc = thresh(tc,threshold,'soft');

       tau = 1/2*(1+sqrt(1+4*tau0^2));
       tz0 = tc + (tau0-1)/tau*(tc-tc0);
       relres = norm(tc(:)-tc0(:))/norm(tc0(:));
       tc0 = tc;
       tau0 = tau;
       iter = iter + 1;
       if flags.do_print
         if mod(iter,kv.printstep)==0
           fprintf('Iteration %d: relative error = %f\n',iter,relres);
         end;
       end;
   end
end


if flags.do_debias
   mask = double(abs(tc)>0);

   % Simulate the pseudoinverse of the synthesis operator of the
   % reduced system
   if numel(find(mask>0)) >= L
       % Invert the frame matrix
       A=@(x) F.frsyn(mask.*F.frana(x));

       [fout,flag,~,iter,relres]=pcg(A,f,kv.pcgtol,kv.pcgmaxit);
       tc=mask.*F.frana(fout);
   else
       % Invert the Gram matrix
       A=@(x) mask.*F.frana(F.frsyn(mask.*x));
       [tc,flag,~,iter,relres]=pcg(A,mask.*F.frana(f),kv.pcgtol,kv.pcgmaxit);
       tc=mask.*tc;
   end
end

% Optional reconstruction
if nargout>3
   frec = postpad(F.frsyn(tc),Ls);
end;

% Calculate coefficients using the canonical dual system
% May be conviniently used for comparison
if nargout>4
  try
     Fd = framedual(F);
     cd = frana(Fd,f);
  catch
     warning(sprintf(['%s: Dual frame is not available. Using franaiter'],...
                     upper(mfilename)));
     cd = franaiter(F,f);
  end
end;



