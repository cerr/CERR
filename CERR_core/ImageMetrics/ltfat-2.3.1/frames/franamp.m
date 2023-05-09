function [c, frec, info] = franamp(F,f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} franamp
%@verbatim
%FRANAMP  Frame Analysis by Matching Pursuit
%   Usage:  c = franamp(F,f)
%           c = franamp(F,f,errdb,maxit)
%           [c,frec,info] = franamp(...)
%
%   Input parameters:
%       F        : Frame definition
%       f        : Input signal
%       errdb    : Target normalized approximation error in dB
%       maxit    : Maximum number of iterations.
%   Output parameters:
%       c        : Sparse representation
%       frec     : Reconstructed signal
%       info     : Struct with additional output paramerets
%
%   FRANAMP(F,f) returns sparse representation of a signal in a
%   dictionary given by vectors of frame F using the orthogonal matching
%   pursuit algorithm.
%
%   FRANAMP(F,f,errdb,maxit) tries to reach normalized approximation error 
%   errdb dB in at most maxit iterations. 
%
%   [c,frec,info] = FRANAMP(...) in addition returns the aproximated
%   signal frec and a struct info with the following fields:
%
%     .iter    Number of iterations done.
%
%     .relres  Vector of length .iter with approximation error progress. 
%
%   The normalized approximation error is computed as 
%   err=norm(f-frec)/norm(f). The relationship between the output 
%   coefficients and the approximation is frec = frsyn(F,c).
%
%   The function takes the following optional parameters at the end of
%   the line of input arguments:
%
%     'print'    Display the progress.
%
%     'printstep',p
%                If 'print' is specified, then print every p'th
%                iteration. Default value is 10;
%
%   Algorithms
%   ----------
%
%   The implementation of OMP was taken from the sparsify_0.5 toolbox by
%   Thomas Blumensath 
%   http://www.personal.soton.ac.uk/tb1m08/sparsify/sparsify.html
%   See help of greed_omp.
%   In fact, the sparsify toolbox implements several flavors of OMP
%   implementation. They can be chosen using the following flags:
%
%     'auto'  Selects a suitable OMP algorithm according to the size of the problem.
%
%     'qr'    QR based method
%
%     'chol'  Cholesky based method
%
%     'cg'    Conjugate Gradient Pursuit
%
%   Additionally:
%
%     'mp'    Classical (non-orthogonal) matching pursuit.
%
%   Examples
%   --------
%
%   The following example show the development of the approx. error for the
%   MP and OMP algorithms. :
%
%       [f,fs] = greasy; F = frame('dgt','hann',256,1024);
%       maxit = 4000;
%       [c1,~,info1] = franamp(F,f,'omp','cg','maxit',maxit);
%       [c2,~,info2] = franamp(F,f,'mp','maxit',maxit);
%       plot(20*log10([info1.relres,info2.relres]));
%       legend({'OMP','MP'});
%
%
%   References:
%     S. Mallat and Z. Zhang. Matching pursuits with time-frequency
%     dictionaries. IEEE Trans. Signal Process., 41(12):3397--3415, 1993.
%     
%     Y. C. Pati, R. Rezaiifar, and P. S. Krishnaprasad. Orthogonal matching
%     pursuit: Recursive function approximation with applications to wavelet
%     decomposition. In Proc. 27th Asilomar Conference on Signals, Systems
%     and Computers, pages 40--44 vol.1, Nov 1993.
%     
%     T. Blumensath and M. E. Davies. Gradient pursuits. IEEE Tran. Signal
%     Processing, 56(6):2370--2382, 2008.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/franamp.html}
%@seealso{frame, frsyn, framevectornorms}
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

%AUTHOR: Zdenek Prusa, Thomas Blumensath

thismfile = upper(mfilename);
complainif_notenoughargs(nargin,2,thismfile);
complainif_notvalidframeobj(F,thismfile);

if F.realinput
    error('%s: Real-input-only frames not supported yet.',thismfile);
end
    
% Define initial value for flags and key/value pairs.
definput.keyvals.errdb=-40;
definput.keyvals.maxit=[];
definput.keyvals.printstep=100;
definput.flags.print={'quiet','print'};
definput.flags.algorithm={'omp','mp'};
definput.flags.ompver={'auto','qr','chol','cg'};
[flags,kv]=ltfatarghelper({'errdb','maxit'},definput,varargin);

%% ----- step 1 : Verify f and determine its length -------
% Change f to correct shape.
[f,~,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],[],upper(mfilename));

if W>1
    error('%s: Input signal can be single channel only.',upper(mfilename));
end

if kv.errdb > 0
    error('%s: Target error must be lower than 0 dB.',upper(mfilename));
end

L=framelength(F,Ls);

if isempty(kv.maxit), kv.maxit = L; end
info.iter = 0;
info.relres = [];

fpad = postpad(f,L);
fnorm = norm(fpad);

% Initialize solution
r0 = fpad;
info.relres = zeros(kv.maxit,1);
relresiter = fnorm;
info.iter = 0;

if fnorm == 0
    c = zeros(frameclength(F,Ls),1);
    frec = zeros(size(f));
    info.relres = [];
    return;
end

F=frameaccel(F,Ls);

vectnfact = 1./(framevectornorms(F,L,'ana'));

if flags.do_mp
    errtol =  fnorm*10^(kv.errdb/20);
    z = F.frana(r0).*vectnfact;
    c = zeros(size(z));
    while info.iter < kv.maxit && relresiter > errtol
        [~,idx]=max(abs(  z ));
        c(idx(1)) = c(idx(1))+ z(idx(1))*vectnfact(idx(1));
        % F.frsyn(tc) is inconvenient since the approximation can
        % be build incrementally using single atom in each iteration.
        % We however do not have access to indivitual atoms.
        r0 = fpad - F.frsyn(c);
        z = F.frana(r0).*vectnfact;
      
        info.iter = info.iter+1;
        relresiter = norm(r0); 
        info.relres(info.iter) = relresiter;

        if flags.do_print
           if mod(info.iter,kv.printstep)==0        
              fprintf('Iteration %d: relative error = %f\n',...
                      info.iter,relresiter);
           end
        end
    end
    info.relres = postpad(info.relres,info.iter)./fnorm;
elseif flags.do_omp
    [c, relres] = greed_omp(r0,F.frsyn,frameclength(F,L),...
                             'stopCrit','mse',...
                             'stopTol',norm(r0)^2*10^(kv.errdb/10)/L,...
                             'maxIter',kv.maxit,...
                             'solver',flags.ompver,...
                             'P_trans',F.frana,...
                             'vecNormFac',vectnfact);
    info.relres = sqrt(relres*L)./fnorm;
    info.iter = numel(info.relres);
end

% Reconstruction
if nargout>1
  frec = F.frsyn(c);
  frec = frec(1:Ls,:);
  frec = assert_sigreshape_post(frec,dim,permutedsize,order);
end

