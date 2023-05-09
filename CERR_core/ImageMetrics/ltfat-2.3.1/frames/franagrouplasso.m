function [tc,relres,iter,frec] = franagrouplasso(F,f,lambda,varargin)
%-*- texinfo -*-
%@deftypefn {Function} franagrouplasso
%@verbatim
%FRANAGROUPLASSO  Group LASSO regression in the TF-domain
%   Usage: tc = franagrouplasso(F,f,lambda)
%          tc = franagrouplasso(F,f,lambda,C,tol,maxit)
%          [tc,relres,iter,frec] = franagrouplasso(...)
%
%   Input parameters:
%      F        : Frame definition
%      f        : Input signal
%      lambda   : Regularisation parameter, controls sparsity of the solution
%      C        : Step size of the algorithm.
%      tol      : Reative error tolerance.
%      maxit    : Maximum number of iterations.
%   Output parameters:
%      tc        : Thresholded coefficients
%      relres    : Vector of residuals.
%      iter      : Number of iterations done.
%      frec      : Reconstructed signal
%
%   FRANAGROUPLASSO(F,f,lambda) solves the group LASSO regression problem
%   in the time-frequency domain: minimize a functional of the synthesis
%   coefficients defined as the sum of half the l^2 norm of the
%   approximation error and the mixed l^1 / l^2 norm of the coefficient
%   sequence, with a penalization coefficient lambda.
%  
%   The matrix of time-frequency coefficients is labelled in terms of groups
%   and members.  By default, the obtained expansion is sparse in terms of
%   groups, no sparsity being imposed to the members of a given group. This
%   is achieved by a regularization term composed of l^2 norm within a
%   group, and l^1 norm with respect to groups. See the help on
%   GROUPTHRESH for more information.
%
%   *Note* the involved frame F must support regular time-frequency
%   layout of coefficients.   
%
%   [tc,relres,iter] = FRANAGROUPLASSO(...) returns the residuals relres in
%   a vector and the number of iteration steps done, maxit.
%
%   [tc,relres,iter,frec] = FRANAGROUPLASSO(...) returns the reconstructed
%   signal from the coefficients, frec. Note that this requires additional
%   computations.
%
%   The function takes the following optional parameters at the end of
%   the line of input arguments:
%
%     'freq'     Group in frequency (search for tonal components). This is the
%                default.
%
%     'time'     Group in time (search for transient components). 
%
%     'C',cval   Landweber iteration parameter: must be larger than
%                square of upper frame bound. Default value is the upper
%                frame bound.
%
%     'maxit',maxit
%                Stopping criterion: maximal number of iterations. 
%                Default value is 100.
%
%     'tol',tol  Stopping criterion: minimum relative difference between
%                norms in two consecutive iterations. Default value is
%                1e-2.
%
%     'print'    Display the progress.
%
%     'quiet'    Don't print anything, this is the default.
%
%     'printstep',p
%                If 'print' is specified, then print every p'th
%                iteration. Default value is 10;
%
%   In addition to these parameters, this function accepts all flags from
%   the GROUPTHRESH and THRESH functions. This makes it possible to
%   switch the grouping mechanism or inner thresholding type.
%
%   The parameters C, maxit and tol may also be specified on the
%   command line in that order: FRANAGROUPLASSO(F,x,lambda,C,tol,maxit).
%
%   The solution is obtained via an iterative procedure, called Landweber
%   iteration, involving iterative group thresholdings.
%
%   The relationship between the output coefficients is given by :
%
%     frec = frsyn(F,tc);
%
%
%   References:
%     M. Kowalski. Sparse regression using mixed norms. Appl. Comput. Harmon.
%     Anal., 27(3):303--324, 2009.
%     
%     M. Kowalski and B. Torresani. Sparsity and persistence: mixed norms
%     provide simple signal models with dependent coefficients. Signal, Image
%     and Video Processing, 3(3):251--264, 2009.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/franagrouplasso.html}
%@seealso{franalasso, framebounds}
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

complainif_notenoughargs(nargin,3,'FRANAGROUPLASSO');
complainif_notvalidframeobj(F,'FRANAGROUPLASSO');

if ~isvector(f)
    error('Input signal must be a vector.');
end

% Define initial value for flags and key/value pairs.
definput.import={'thresh','groupthresh'};
definput.flags.group={'freq','time'};

definput.keyvals.C=[];
definput.keyvals.maxit=100;
definput.keyvals.tol=1e-2;
definput.keyvals.printstep=10;
definput.flags.print={'quiet','print'};

[flags,kv]=ltfatarghelper({'C','tol','maxit'},definput,varargin);

L=framelength(F,length(f));

F=frameaccel(F,L);

if isempty(kv.C)
  [~,kv.C] = framebounds(F,L);
end;

% Initialization of thresholded coefficients
c0 = frana(F,f);

% We have to convert the coefficients to time-frequency layout to
% discover their size
tc = framecoef2tf(F,c0);

% [M,N]=size(tc);
% Normalization to turn lambda to a value comparable to lasso
%if flags.do_time
%  lambda = lambda*sqrt(N);
%else
%  lambda = lambda*sqrt(M);
%end

% Various parameter initializations
threshold = lambda/kv.C;



tc0 = c0;
relres = 1e16;
iter = 0;

% Choose the dimension to group along
if flags.do_freq
  kv.dim=2;
else
  kv.dim=1;
end;

if F.red==1
        
    tc=groupthresh(tc,threshold,kv.dim,flags.iofun);

    % Convert back from TF-plane
    tc=frametf2coef(F,tc);        

else

    % Main loop
    while ((iter < kv.maxit)&&(relres >= kv.tol))
        tc = c0 - frana(F,frsyn(F,tc0));
        tc = tc0 + tc/kv.C;
        
        %  ------------ Convert to TF-plane ---------
        tc = framecoef2tf(F,tc);
        
        tc = groupthresh(tc,threshold,'argimport',flags,kv);
        
        % Convert back from TF-plane
        tc=frametf2coef(F,tc);
        % -------------------------------------------
        
        relres = norm(tc(:)-tc0(:))/norm(tc0(:));
        tc0 = tc;
        iter = iter + 1;
        if flags.do_print
            if mod(iter,kv.printstep)==0        
                fprintf('Iteration %d: relative error = %f\n',iter,relres);
            end;
        end;
    end
    
end;

% Reconstruction
if nargout>3
  frec = frsyn(F,tc);
end;


