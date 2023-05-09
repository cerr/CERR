function [V,D]=gabmuleigs(K,c,p3,varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabmuleigs
%@verbatim
%GABMULEIGS  Eigenpairs of Gabor multiplier
%   Usage:  h=gabmuleigs(K,c,g,a);
%           h=gabmuleigs(K,c,a);
%           h=gabmuleigs(K,c,ga,gs,a);
%
%   Input parameters:
%         K     : Number of eigenvectors to compute.
%         c     : symbol of Gabor multiplier
%         g     : analysis/synthesis window
%         ga    : analysis window
%         gs    : synthesis window
%         a     : Length of time shift.
%   Output parameters:
%         V     : Matrix containing eigenvectors.
%         D     : Eigenvalues.
%
%   GABMULEIGS has been deprecated. Please use construct a frame multiplier
%   and use FRAMEMULEIGS instead.
%
%   A call to GABMULEIGS(K,c,ga,gs,a) can be replaced by :
%
%     [Fa,Fs]=framepair('dgt',ga,gs,a,M);
%     [V,D]=framemuleigs(Fa,Fs,s,K);
%
%   Original help:
%   --------------
%
%   GABMULEIGS(K,c,g,a) computes the K largest eigenvalues and eigen-
%   vectors of the Gabor multiplier with symbol c and time shift a.  The
%   number of channels is deduced from the size of the symbol c.  The
%   window g will be used for both analysis and synthesis.
%
%   GABMULEIGS(K,c,ga,gs,a) does the same using the window the window ga*
%   for analysis and gs for synthesis.
%
%   GABMULEIGS(K,c,a) does the same using the a tight Gaussian window of
%   for analysis and synthesis.
%
%   If K is empty, then all eigenvalues/pairs will be returned.
%
%   GABMULEIGS takes the following parameters at the end of the line of input
%   arguments:
%
%     'tol',t      Stop if relative residual error is less than the
%                  specified tolerance. Default is 1e-9 
%
%     'maxit',n    Do at most n iterations.
%
%     'iter'       Call eigs to use an iterative algorithm.
%
%     'full'       Call eig to sole the full problem.
%
%     'auto'       Use the full method for small problems and the
%                  iterative method for larger problems. This is the
%                  default. 
%
%     'crossover',c
%                  Set the problem size for which the 'auto' method
%                  switches. Default is 200.
%
%     'print'      Display the progress.
%
%     'quiet'      Don't print anything, this is the default.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/deprecated/gabmuleigs.html}
%@seealso{gabmul, dgt, idgt, gabdual, gabtight}
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

warning(['LTFAT: GABMULEIGS has been deprecated, please use FRAMEMULEIGS ' ...
         'instead. See the help on FRAMEMULEIGS for more details.']);

% Change this to 1 or 2 to see the iterative method in action.
printopts=0;

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

if nargout==2
  doV=1;
else
  doV=0;
end;

M=size(c,1);
N=size(c,2);

istight=1;
if numel(p3)==1
  % Usage: h=gabmuleigs(c,K,a);  
  a=p3;
  L=N*a;
  ga=gabtight(a,M,L);
  gs=ga;
  arglist=varargin;
else 
  if numel(varargin{1})==1
    % Usage: h=gabmuleigs(c,K,g,a);  
    ga=p3;
    gs=p3;
    a=varargin{1};
    L=N*a;
    arglist=varargin(2:end);
  else 
    if numel(varargin{2})==1
      % Usage: h=gabmuleigs(c,K,ga,gs,a);  
      ga=p3;
      gs=varargin{1};
      a =varargin{2};
      L=N*a;
      istight=0;
      arglist=varargin(3:end);
    end;    
  end;
end;

definput.keyvals.maxit=100;
definput.keyvals.tol=1e-9;
definput.keyvals.crossover=200;
definput.flags.print={'quiet','print'};
definput.flags.method={'auto','iter','full'};


[flags,kv]=ltfatarghelper({},definput,arglist);


% Do the computation. For small problems a direct calculation is just as
% fast.

if (flags.do_iter) || (flags.do_auto && L>kv.crossover)
  
  if flags.do_print
    opts.disp=1;
  else
    opts.disp=0;
  end;
  opts.isreal = false;
  opts.maxit  = kv.maxit;
  opts.tol    = kv.tol;
  
  % Setup afun
  afun(1,c,ga,gs,a,M,L);
  
  if doV
    [V,D] = eigs(@afun,L,K,'LM',opts);
  else
    D     = eigs(@afun,L,K,'LM',opts);
  end;

else
  % Compute the transform matrix.
  bigM=tfmat('gabmul',c,ga,gs,a);

  if doV
    [V,D]=eig(bigM);
  else
    D=eig(bigM);
  end;


end;

% The output from eig and eigs is a diagonal matrix, so we must extract the
% diagonal.
D=diag(D);

% Sort them in descending order
[~,idx]=sort(abs(D),1,'descend');
D=D(idx(1:K));

if doV
  V=V(:,idx(1:K));
end;

% Clean the eigenvalues, if we know that they are real-valued
%if isreal(ga) && isreal(gs) && isreal(c)
%  D=real(D);
%end;

% The function has been written in this way, because Octave (at the time
% of writing) does not accept additional parameters at the end of the
% line of input arguments for eigs
function y=afun(x,c_in,ga_in,gs_in,a_in,M_in,L_in)
  persistent c;
  persistent ga;
  persistent gs;
  persistent a;
  persistent M;
  persistent L; 
  
  if nargin>1
    c  = c_in; 
    ga = ga_in;
    gs = gs_in;
    a  = a_in; 
    M  = M_in; 
    L  = L_in;
  else
    y=comp_idgt(c.*comp_dgt(x,ga,a,M,[0 1],0,0,0),gs,a,[0 1],0,0);
  end;

