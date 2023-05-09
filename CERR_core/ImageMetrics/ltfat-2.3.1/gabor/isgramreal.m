function [f,relres,iter]=isgramreal(s,g,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} isgramreal
%@verbatim
%ISGRAMREAL  Spectrogram inversion (real signal)
%   Usage:  f=isgramreal(s,g,a,M);
%           f=isgramreal(s,g,a,M,Ls);
%           [f,relres,iter]=isgramreal(...);
%
%   Input parameters:
%         c       : Array of coefficients.
%         g       : Window function.
%         a       : Length of time shift.
%         M       : Number of channels.
%         Ls      : length of signal.
%   Output parameters:
%         f       : Signal.
%         relres  : Vector of residuals.
%         iter    : Number of iterations done.
%
%   ISGRAMREAL(s,g,a,M) attempts to invert a spectrogram computed by :
%
%     s = abs(dgtreal(f,g,a,M)).^2;
%
%   by an iterative method.
%
%   ISGRAMREAL(s,g,a,M,Ls) does as above but cuts or extends f to length Ls.
%
%   If the phase of the spectrogram is known, it is much better to use
%   DGTREAL
%
%   f,relres,iter]=ISGRAMREAL(...) additionally returns the residuals in a
%   vector relres and the number of iteration steps done.
%
%   Generally, if the spectrogram has not been modified, the iterative
%   algorithm will converge slowly to the correct result. If the
%   spectrogram has been modified, the algorithm is not guaranteed to
%   converge at all.  
%
%   ISGRAMREAL takes the following parameters at the end of the line of
%   input arguments:
%
%     'lt',lt      Specify the lattice type. See the help on
%                  MATRIX2LATTICETYPE. Only the rectangular or quinqux
%                  lattices can be specified.
%
%     'zero'       Choose a starting phase of zero. This is the default
%
%     'rand'       Choose a random starting phase.
%
%     'int'        Construct a starting phase by integration. Only works
%                  for Gaussian windows.
%
%     'griflim'    Use the Griffin-Lim iterative method, this is the
%                  default.
%
%     'bfgs'       Use the limited-memory Broyden Fletcher Goldfarb
%                  Shanno (BFGS) method.  
%
%     'tol',t      Stop if relative residual error is less than the specified tolerance.  
%
%     'maxit',n    Do at most n iterations.
%
%     'print'      Display the progress.
%
%     'quiet'      Don't print anything, this is the default.
%
%     'printstep',p
%                  If 'print' is specified, then print every p'th
%                  iteration. Default value is p=10.
%
%   The BFGS method makes use of the minFunc software. To use the BFGS method, 
%   please install the minFunc software from:
%   http://www.cs.ubc.ca/~schmidtm/Software/minFunc.html.
%
%
%   References:
%     R. Decorsiere and P. L. Soendergaard. Modulation filtering using an
%     optimization approach to spectrogram reconstruction. In Proceedings of
%     the Forum Acousticum, 2011.
%     
%     D. Griffin and J. Lim. Signal estimation from modified short-time
%     Fourier transform. IEEE Trans. Acoust. Speech Signal Process.,
%     32(2):236--243, 1984.
%     
%     D. Liu and J. Nocedal. On the limited memory BFGS method for large
%     scale optimization. Mathematical programming, 45(1):503--528, 1989.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/isgramreal.html}
%@seealso{dgtreal, idgtreal}
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

  if nargin<3
    error('%s: Too few input parameters.',upper(mfilename));
  end;
  
  if numel(g)==1
    error('g must be a vector (you probably forgot to supply the window function as input parameter.)');
  end;
  
  definput.keyvals.Ls=[];
  definput.keyvals.lt=[0 1];
  definput.keyvals.tol=1e-6;
  definput.keyvals.maxit=100;
  definput.keyvals.printstep=10;
  definput.flags.method={'griflim','bfgs'};
  definput.flags.print={'print','quiet'};
  definput.flags.startphase={'zero','rand','int'};
  
  [flags,kv,Ls]=ltfatarghelper({'Ls','tol','maxit'},definput,varargin);

  N=size(s,2);
  W=size(s,3);
  
  % Make a dummy call to test the input parameters
  Lsmallest=dgtlength(1,a,M,kv.lt);
  
  M2=floor(M/2)+1;
  
  if M2~=size(s,1)
      error('Mismatch between the specified number of channels and the size of the input coefficients.');
  end;
  
  L=N*a;
  
  if rem(L,Lsmallest)>0
      error('%s: Invalid size of coefficient array.',upper(mfilename));
  end;
  
  %% ----- step 3 : Determine the window 
  
  [g,info]=gabwin(g,a,M,L,kv.lt,'callfun',upper(mfilename));
  
  if L<info.gl
      error('%s: Window is too long.',upper(mfilename));
  end;
  
  if ~isreal(g)
      error('%s: Window must be real-valued.',upper(mfilename));
  end;
  
  %% Actual computation
  
  sqrt_s=sqrt(s);
  
  if flags.do_zero
    % Start with a phase of zero.
    c=sqrt(s);
  end;
  
  if flags.do_rand
    c=sqrt_s.*exp(2*pi*1i*rand(size(s)));
  end;
  
  if flags.do_int
      if kv.lt(2)>1
          error(['%s: The integration initilization is not implemented for ' ...
                 'non-sep lattices.'],upper(mfilename));
      end;

      
    s2=zeros(M,N);
    s2(1:M2,:)=s;
    if rem(M,2)==0
      s2(M2+1:M,:)=flipud(s(2:end-1,:));
    else
      s2(M2+1:M,:)=flipud(s(2:end));
    end;
    c=constructphase(s2,g,a);
    c=c(1:M2,:);
  end;
    
  gd = gabdual(g,a,M);
    
  % For normalization purposes
  norm_s=norm(s,'fro');
  
  relres=zeros(kv.maxit,1);
  if flags.do_griflim
    for iter=1:kv.maxit
      f=comp_idgtreal(c,gd,a,M,kv.lt,0);
      c=comp_dgtreal(f,g,a,M,kv.lt,0);
      
      relres(iter)=norm(abs(c).^2-s,'fro')/norm_s;
      
      c=sqrt_s.*exp(1i*angle(c));
      
      if flags.do_print
        if mod(iter,kv.printstep)==0
          fprintf('ISGRAMREAL: Iteration %i, residual = %f.\n',iter,relres(iter));
        end;    
      end;
      
      if relres(iter)<kv.tol
        relres=relres(1:iter);
        break;
      end;
      
    end;
    
  end;
  
  if flags.do_bfgs
    if exist('minFunc')~=2
      error(['To use the BFGS method in ISGRAMREAL, please install the minFunc ' ...
             'software from http://www.cs.ubc.ca/~schmidtm/Software/minFunc.html.']);
    end;
    
    % Setting up the options for minFunc
    opts = struct;
    opts.display = kv.printstep;
    opts.maxiter = kv.maxit;
    opts.usemex = 0;

    % Don't limit the number of function evaluations, just the number of
    % time-steps.
    opts.MaxFunEvals = 1e9;
    
    f0 = comp_idgtreal(c,gd,a,M,kv.lt,0);
    [f,fval,exitflag,output]=minFunc(@objfun,f0,opts,g,a,M,s,kv.lt);
    % First entry of output.trace.fval is the objective function
    % evaluated on the initial input. Skip it to be consistent.
    relres = sqrt(output.trace.fval(2:end))/norm_s;
    iter = output.iterations;
  end;
  
  % Cut or extend f to the correct length, if desired.
  if ~isempty(Ls)
    f=postpad(f,Ls);
  else
    Ls=L;
  end;
  
  f=comp_sigreshape_post(f,Ls,0,[0; W]);
  
%  Subfunction to compute the objective function for the BFGS method.
function [f,df]=objfun(x,g,a,M,s,lt);
  c=comp_dgtreal(x,g,a,M,lt,0);
  
  inner=abs(c).^2-s;
  f=norm(inner,'fro')^2;
  
  df=4*real(conj(comp_idgtreal(inner.*c,g,a,M,lt,0)));

