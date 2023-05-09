function [AF,BF]=framebounds(F,varargin);
%-*- texinfo -*-
%@deftypefn {Function} framebounds
%@verbatim
%FRAMEBOUNDS  Frame bounds
%   Usage: fcond=framebounds(F);
%          [A,B]=framebounds(F);
%          [...]=framebounds(F,Ls);
%
%   FRAMEBOUNDS(F) calculates the ratio B/A of the frame bounds of the
%   frame given by F. The length of the system the frame bounds are
%   calculated for is given by L=framelength(F,1).
%
%   FRAMEBOUNDS(F,Ls) additionally specifies a signal length for which
%   the frame should work. The actual length used is L=framelength(F,Ls).
%
%   [A,B]=FRAMEBOUNDS(F) returns the frame bounds A and B instead of
%   just their ratio.
%
%
%   'framebounds` accepts the following optional parameters:
%
%     'fac'        Use a factorization algorithm. The function will throw
%                  an error if no algorithm is available.
%
%     'iter'       Call eigs to use an iterative algorithm.
%
%     'full'       Call eig to solve the full problem.
%
%     'auto'       Choose the fac method if possible, otherwise
%                  use the full method for small problems and the
%                  iter method for larger problems. 
%                  This is the default. 
%
%     'crossover',c
%                  Set the problem size for which the 'auto' method
%                  switches between full and iter. Default is 200.
%
%   The following parameters specifically related to the iter method: 
%
%     'tol',t      Stop if relative residual error of eighs is less than the
%                  specified tolerance. Default is 1e-9 
%
%     'maxit',n    Do at most n iterations in eigs. Default is 100.
%
%     'pcgtol',t   Stop if relative residual error of pcg is less than the
%                  specified tolerance. Default is 1e-6 
%
%     'pcgmaxit',n Do at most n iterations in pcg. Default is 150.
%
%     'p',p        The number of Lanzcos basis vectors to use.  More vectors
%                  will result in faster convergence, but a larger amount of
%                  memory.  The optimal value of p is problem dependent and
%                  should be less than L.  The default value chosen 
%                  automatically by eigs.
% 
%     'print'      Display the progress.
%
%     'quiet'      Don't print anything, this is the default.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/framebounds.html}
%@seealso{frame, framered}
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

complainif_notenoughargs(nargin,1,'FRAMEBOUNDS');
complainif_notvalidframeobj(F,'FRAMEBOUNDS');

% We handle the container frames first
  if strcmp(F.type,'fusion')
      AF=0;
      BF=0;
      for ii=1:F.Nframes
          [A,B]=framebounds(F.frames{ii},varargin{:});
          AF=AF+(A*F.w(ii)).^2;
          BF=BF+(B*F.w(ii)).^2;
      end;
      AF=sqrt(AF);
      BF=sqrt(BF);
        
      return;
  end;    
  
  if strcmp(F.type,'tensor')
    AF=1;
    BF=1;
    for ii=1:F.Nframes
      [A,B]=framebounds(F.frames{ii},varargin{:});
      AF=AF*A;
      BF=BF*B;
    end;
    
    return;
  end;    
    
  definput.keyvals.Ls=1;
  definput.keyvals.maxit=100;
  definput.keyvals.tol=1e-9;
  definput.keyvals.pcgmaxit=150;
  definput.keyvals.pcgtol=1e-6;
  definput.keyvals.crossover=200;
  definput.keyvals.p=[];
  definput.flags.print={'quiet','print'};
  definput.flags.method={'auto','fac','iter','full'};
  
  [flags,kv]=ltfatarghelper({'Ls'},definput,varargin);
  
  F=frameaccel(F,kv.Ls);
  L=F.L;
  
  % Default values, works for the pure frequency transforms.
  AF=1;
  BF=1;
  
  % Simple heuristic: If F.g is defined, the frame uses windows.
  if isfield(F,'g')
      if isempty(F.g)
          error('%s: No analysis frame is defined.', upper(mfilename));
      end;
      g=F.g;
      op    = @frana;
      opadj = @frsyn;
  end;

  F_isfac = isfield(F,'isfac') && F.isfac;
  
  if flags.do_fac && ~F_isfac
    error('%s: The type of frame has no factorization algorithm.',upper(mfilename));
  end;
    
  if (flags.do_auto && F_isfac) || flags.do_fac
    switch(F.type)
     case 'gen'
      V=svd(g);
      AF=min(V)^2;
      BF=max(V)^2;
     case {'dgt','dgtreal'}
      [AF,BF]=gabframebounds(g,F.a,F.M,L); 
     case {'dwilt','wmdct'}
      [AF,BF]=wilbounds(g,F.M,L); 
     case {'filterbank','ufilterbank'}
      [AF,BF]=filterbankbounds(g,F.a,L);
     case {'filterbankreal','ufilterbankreal'}
      [AF,BF]=filterbankrealbounds(g,F.a,L); 
     case 'fwt'
      [AF,BF]=wfbtbounds({g,F.J,'dwt'},L);
     case 'wfbt'
      [AF,BF]=wfbtbounds(g,L);
     case 'ufwt'
      [AF,BF]=wfbtbounds({g,F.J,'dwt'},L,F.flags.scaling);
     case 'uwfbt'
      [AF,BF]=wfbtbounds(g,L,F.flags.scaling);
     case 'wpfbt'
      [AF,BF]=wpfbtbounds(g,L,F.flags.interscaling);
     case 'uwpfbt'
      [AF,BF]=wpfbtbounds(g,L,F.flags.interscaling,F.flags.scaling);
    end;  
  end;
  
  if (flags.do_auto && ~F_isfac && F.L>kv.crossover) || flags.do_iter
    
  
    if flags.do_print
      opts.disp=1;
    else
      opts.disp=0;
    end;
    opts.isreal = F.realinput;
    opts.maxit  = kv.maxit;
    opts.tol    = kv.tol;
    opts.issym  = 0;
    if ~isempty(kv.p)
       opts.p      = kv.p;
    end
    
    pcgopts.maxit = kv.pcgmaxit;
    pcgopts.tol = kv.pcgtol;

    % Upper frame bound
    frameop = @(x) F.frsyn(F.frana(x));
    BF = real(eigs(frameop,L,1,'LM',opts));
    
    % Lower frame bound
    frameop2 = @(x) F.frsyn(F.frana(x));
    invfrop = @(x) pcg(frameop2,x,pcgopts.tol,pcgopts.maxit);
    
    % Test convergence of pcg
    test = randn(L,1);
    if ~F.realinput, test = test +1i*randn(L,1); end
    [~,flag] = invfrop(test);
    
    % If PCG converges, estimate the smallest eigenvalue, otherwise assume
    % AF = 0;
    if ~flag
        AF = real(eigs(invfrop,L,1,'SM',opts));
    else 
        AF = 0;
    end

    
  end;
  
  if (flags.do_auto && ~F_isfac && F.L<=kv.crossover) || flags.do_full
    % Compute thee transform matrix.
    bigM=opadj(F,op(F,eye(L)));
    
    D=eig(bigM);
    
    % Clean the eigenvalues, we know they are real
    D=real(D);
    AF=min(D);
    BF=max(D);
  end;

  if nargout<2
    % Avoid the potential warning about division by zero.
    if AF==0
      AF=Inf;
    else
      AF=BF/AF;
    end;
  end;
  
end

% The function has been written in this way, because Octave (at the time
% of writing) does not accept additional parameters at the end of the
% line of input arguments for eigs
function y=afun(x,F_in,op_in,opadj_in)
  persistent F;
  persistent op;
  persistent opadj;
  
  if nargin>1
    F     = F_in; 
    op    = op_in;
    opadj = opadj_in;
  else
    y=opadj(F,op(F,x));
  end;

end

