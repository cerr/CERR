function [f,relres,iter,c]=frsynabs(F,s,varargin)
%-*- texinfo -*-
%@deftypefn {Function} frsynabs
%@verbatim
%FRSYNABS  Reconstruction from magnitude of coefficients
%   Usage:  f=frsynabs(F,s);
%           f=frsynabs(F,s,Ls);
%           [f,relres,iter,c]=frsynabs(...);
%
%   Input parameters:
%         F       : Frame
%         s       : Array of coefficients.
%         Ls      : length of signal.
%   Output parameters:
%         f       : Signal.
%         relres  : Vector of residuals.
%         iter    : Number of iterations done.
%         c       : Coefficients with the reconstructed phase
%
%   FRSYNABS(F,s) attempts to find a signal which has s as the absolute
%   value of its frame coefficients :
%
%     s = abs(frana(F,f));
%
%   using an iterative method.
%
%   FRSYNABS(F,s,Ls) does as above but cuts or extends f to length Ls.
%
%   If the phase of the coefficients s is known, it is much better to use
%   frsyn.
%
%   [f,relres,iter]=FRSYNABS(...) additionally returns the residuals in a
%   vector relres and the number of iteration steps iter. The residuals
%   are computed as:
%
%      relres = norm(abs(cn)-s,'fro')/norm(s,'fro')
%
%   where c_n is the Gabor coefficients of the signal in iteration n.
%
%   [f,relres,iter,c]=FRSYNABS(...,'griflim'|'fgriflim') additionally returns
%   coefficients c with the reconstructed phase prior to the final reconstruction.
%   This is usefull for determining the consistency (energy lost in the nullspace
%   of F) of the reconstructed spectrogram. c will only be equal to frana(F,f)
%   if the spectrogram is already consistent (i.e. already in the range space of F*).
%   This is possible only for 'griflim' and 'fgriflim' methods.
%
%   Generally, if the absolute value of the frame coefficients has not been
%   modified, the iterative algorithm will converge slowly to the correct
%   result. If the coefficients have been modified, the algorithm is not
%   guaranteed to converge at all.
%
%   FRSYNABS takes the following parameters at the end of the line of input
%   arguments.
%
%   Initial phase guess:
%
%     'input'      Choose the starting phase as the phase of the input
%                  s. This is the default
%
%     'zero'       Choose a starting phase of zero.
%
%     'rand'       Choose a random starting phase.
%
%   The Griffin-Lim algorithm related parameters:
%
%     'griflim'    Use the Griffin-Lim iterative method. This is the
%                  default.
%
%     'fgriflim'   Use the Fast Griffin-Lim iterative method.
%
%
%     'Fd',Fd      A canonical dual frame object or an anonymous function
%                  acting as the synthesis operator of the canonical dual frame.
%                  If not provided, the function attempts to create one using
%                  Fd=framedual(F).
%
%     'alpha',a    Parameter of the Fast Griffin-Lim algorithm. It is
%                  ignored if not used together with 'fgriflim' flag.
%
%   The BFGS method related paramaters:
%
%     'bfgs'       Use the limited-memory Broyden Fletcher Goldfarb
%                  Shanno (BFGS) method.
%
%     'p',p        Parameter for the compressed version of the obj. function
%                  in the l-BFGS method. It is ignored if not used together
%                  with 'bfgs' flag.
%
%   Other:
%
%     'tol',t      Stop if relative residual error is less than the
%                  specified tolerance.
%
%     'maxit',n    Do at most n iterations.
%
%     'print'      Display the progress.
%
%     'quiet'      Don't print anything, this is the default.
%
%     'printstep',p  If 'print' is specified, then print every p'th
%                    iteration. Default value is p=10;
%
%   The BFGS method makes use of the minFunc software. To use the BFGS method,
%   please install the minFunc software from:
%   http://www.cs.ubc.ca/~schmidtm/Software/minFunc.html.
%
%
%
%   References:
%     D. Griffin and J. Lim. Signal estimation from modified short-time
%     Fourier transform. IEEE Trans. Acoust. Speech Signal Process.,
%     32(2):236--243, 1984.
%     
%     N. Perraudin, P. Balazs, and P. L. Soendergaard. A fast Griffin-Lim
%     algorithm. In Applications of Signal Processing to Audio and Acoustics
%     (WASPAA), 2013 IEEE Workshop on, pages 1--4, Oct 2013.
%     
%     R. Decorsiere, P. Soendergaard, E. MacDonald, and T. Dau. Inversion of
%     auditory spectrograms, traditional spectrograms, and other envelope
%     representations. Audio, Speech, and Language Processing, IEEE/ACM
%     Transactions on, 23(1):46--56, Jan 2015.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/frsynabs.html}
%@seealso{frana, frsyn, demo_frsynabs, demo_phaseret}
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

%   AUTHOR : Remi Decorsiere and Peter L. Soendergaard.
%   REFERENCE: OK

% Check input paramameters.

complainif_notenoughargs(nargin,2,'FRSYNABS');
complainif_notvalidframeobj(F,'FRSYNABS');

definput.keyvals.Ls=[];
definput.keyvals.tol=1e-6;
definput.keyvals.Fd=[];
definput.keyvals.maxit=100;
definput.keyvals.printstep=10;
definput.keyvals.alpha=0.99;
definput.keyvals.p=2;
definput.flags.print={'quiet','print'};
definput.flags.startphase={'input','zero','rand'};
definput.flags.method={'griflim','bfgs','fgriflim'};

[flags,kv,Ls]=ltfatarghelper({'Ls','tol','maxit'},definput,varargin);

% Determine the proper length of the frame
L=framelengthcoef(F,size(s,1));
W=size(s,2);

if flags.do_input
  % Start with the phase given by the input.
  c=s;
end;

if flags.do_zero
  % Start with a phase of zero.
  c=abs(s);
end;

if flags.do_rand
  c=abs(s).*exp(2*pi*i*rand(size(s)));
end;

% Use only abs(s) in the residum evaluations
s = abs(s);

% For normalization purposes
norm_s=norm(s,'fro');

relres=zeros(kv.maxit,1);

if isempty(kv.Fd)
    try
       Fd=frameaccel(framedual(F),L);
       Fdfrsyn = @(insig) Fd.frsyn(insig);
    catch
        % Canonical dual frame cannot be creted explicitly
        % TO DO: use pcg
        error('%s: The canonical dual frame is not available.',upper(mfilename));
    end
else
   if isstruct(kv.Fd) && isfield(kv.Fd,'frsyn')
      % The canonical dual frame was passed explicitly as a frame object
      Fd = frameaccel(kv.Fd,L);
      Fdfrsyn = @(insig) Fd.frsyn(insig);
   elseif isa(kv.Fd,'function_handle')
      % The anonymous function is expected to do (FF*)^(-1)F
      Fdfrsyn = kv.Fd;
   else
       error('%s: Invalid format of Fd.',upper(mfielname));
   end

end

% Initialize windows to speed up computation
F=frameaccel(F,L);

if flags.do_griflim
  for iter=1:kv.maxit
    f=Fdfrsyn(c);
    c2=F.frana(f);

    c=s.*exp(1i*angle(c2));
    relres(iter)=norm(abs(c2)-s,'fro')/norm_s;

    if flags.do_print
      if mod(iter,kv.printstep)==0
        fprintf('FRSYNABS: Iteration %i, residual = %f.\n',iter,relres(iter));
      end;
    end;

    if relres(iter)<kv.tol
      relres=relres(1:iter);
      break;
    end;

  end;
end;

if flags.do_fgriflim
  told=c;

  for iter=1:kv.maxit
    f=Fdfrsyn(c);
    tnew=F.frana(f);

    relres(iter)=norm(abs(tnew)-s,'fro')/norm_s;

    tnew=s.*exp(1i*angle(tnew));
    c=tnew+kv.alpha*(tnew-told);


    if flags.do_print
      if mod(iter,kv.printstep)==0
        fprintf('FRSYNABS: Iteration %i, residual = %f.\n',iter,relres(iter));
      end;
    end;

    if relres(iter)<kv.tol
      relres=relres(1:iter);
      break;
    end;

    told=tnew;

  end;
end;

if flags.do_bfgs
    if exist('minFunc')~=2
      error(['To use the BFGS method in FRSYNABS, please install the minFunc ' ...
             'software from http://www.cs.ubc.ca/~schmidtm/Software/minFunc.html.']);
    end;

    if nargout>3
        error('%s: 4th argument cannot be returned when using the BFGS method.',...
              upper(mfilename));
    end

    % Setting up the options for minFunc
    opts = struct;
    if flags.do_quiet
          opts.Display = 'off';
    end


    opts.MaxIter = kv.maxit;
    opts.optTol = kv.tol;
    opts.progTol = kv.tol;

    if nargout>1
        % This custom function is called after each iteration.
        % We cannot use the objective function itself as it might be called
        % several times in a single iteration.
        % We use outputFcn to keep track of norm(abs(c)+s)
        % because the objective function is different: norm(abs(c).^p+s.^p)

        opts.outputFcn = @outputFcn;
        opts.outputFcn('init',kv.maxit,F,s);
    end

    % Don't limit the number of function evaluations, just the number of
    % time-steps.
    opts.MaxFunEvals = 1e9;
    opts.usemex = 0;
    f0 = Fdfrsyn(c);

    if kv.p ~= 2
      objfun = @(x) gradfunp(x,F,s,kv.p);
    else
      objfun = @(x) gradfun(x,F,s);
    end

    [f,~,~,output] = minFunc(objfun,f0,opts);

    if nargout > 1
        iter = output.iterations;
        res = opts.outputFcn('getRes');
        relres = res/norm_s;
    end
end;


% Cut or extend f to the correct length, if desired.
if ~isempty(Ls)
  f=postpad(f,Ls);
else
  Ls=L;
end;

f=comp_sigreshape_post(f,Ls,0,[0; W]);

%  Subfunction to compute the objective function for the BFGS method.
function [f,df]=gradfun(x,F,s)
  % f  obj function value
  % df gradient value
  c=F.frana(x);

  inner = abs(c).^2-s.^2;
  f = norm(inner,'fro')^2;
  df = 4*real(conj(F.frsyn(inner.*c)));

%  Subfunction to compute the p-compressed objective function for the BFGS method.
function [f,df]=gradfunp(x,F,s,p)
  c=F.frana(x);
  inner = abs(c).^p-s.^p;
  f = norm(inner,'fro')^2;
  df = 2*p*real(conj(F.frsyn( inner.*abs(c).^(p/2-1).*c)));

function stop = outputFcn(x,iterationType,itNo,funEvals,f,t,gtd,g,d,optCond)
% This is unfortunatelly a messy function.
% Moreover, it computes one more analysis

persistent res;
persistent F;
persistent s;

if ischar(x)
    switch x
        case 'init'
            res = zeros(iterationType,1);
            F = itNo;
            s = funEvals;
            return;
        case 'getRes'
            stop = res;
            F = []; s=[]; res = [];
            return;
    end
end

if isempty(res)
    error('OUTPUTFCN: Initialize res first!');
end

res(itNo+1) = norm(abs(F.frana(x)) - s,'fro');
stop = 0;




