function varargout=framemuleigs(Fa,Fs,s,varargin)
%-*- texinfo -*-
%@deftypefn {Function} framemuleigs
%@verbatim
%FRAMEMULEIGS  Eigenpairs of frame multiplier
%   Usage:  [V,D]=framemuleigs(Fa,Fs,s,K);
%           D=framemuleigs(Fa,Fs,s,K,...);
%
%   Input parameters:
%         Fa    : Analysis frame
%         Fs    : Synthesis frame
%         s     : Symbol of Gabor multiplier
%         K     : Number of eigenvectors to compute.
%   Output parameters:
%         V     : Matrix containing eigenvectors.
%         D     : Eigenvalues.
%
%   [V,D]=FRAMEMULEIGS(Fa,Fs,s,K) computes the K largest eigenvalues 
%   and eigen-vectors of the frame multiplier with symbol s, analysis 
%   frame Fa and synthesis frame Fs. The eigenvectors are stored as 
%   column vectors in the matrix V and the corresponding eigenvalues in 
%   the vector D.
%
%   If K is empty, then all eigenvalues/pairs will be returned.
%
%   D=FRAMEMULEIGS(...) computes only the eigenvalues.
%
%   FRAMEMULEIGS takes the following parameters at the end of the line of input
%   arguments:
%
%     'tol',t      Stop if relative residual error is less than the
%                  specified tolerance. Default is 1e-9 
%
%     'maxit',n    Do at most n iterations.
%
%     'iter'       Call eigs to use an iterative algorithm.
%
%     'full'       Call eig to solve the full problem.
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
%   Examples:
%   ---------
%
%   The following example calculates and plots the first eigenvector of the
%   Gabor multiplier given by the BATMASK function. Note that the mask
%   must be converted to a column vector to work with in this framework:
%
%     mask=batmask;
%     [Fa,Fs]=framepair('dgt','gauss','dual',10,40);
%     [V,D]=framemuleigs(Fa,Fs,mask(:));
%     sgram(V(:,1),'dynrange',90);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/framemuleigs.html}
%@seealso{framemul, framemulappr}
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

% Change this to 1 or 2 to see the iterative method in action.
printopts=0;

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

if nargout==2
  doV=1;
else
  doV=0;
end;

tolchooser.double=1e-9;
tolchooser.single=1e-5;

definput.keyvals.K=6;
definput.keyvals.maxit=100;
definput.keyvals.tol=tolchooser.(class(s));
definput.keyvals.crossover=200;
definput.flags.print={'quiet','print'};
definput.flags.method={'auto','iter','full'};


[flags,kv,K]=ltfatarghelper({'K'},definput,varargin);

% Do the computation. For small problems a direct calculation is just as
% fast.

L=framelengthcoef(Fa,size(s,1));

if (flags.do_iter) || (flags.do_auto && L>kv.crossover)
    
  if flags.do_print
    opts.disp=1;
  else
    opts.disp=0;
  end;
  opts.isreal = Fa.realinput;
  opts.maxit  = kv.maxit;
  opts.tol    = kv.tol;
    
  if doV
      [V,D] = eigs(@(x) framemul(x,Fa,Fs,s),L,K,'LM',opts);
  else
      D     = eigs(@(x) framemul(x,Fa,Fs,s),L,K,'LM',opts);
  end;

else
  % Compute the transform matrix.
  bigM=frsynmatrix(Fs,L)*diag(s)*frsynmatrix(Fa,L)'; 

  if doV
    [V,D]=eig(bigM);
  else
    D=eig(bigM);
  end;

end;

% The output from eig and eigs is sometimes a diagonal matrix, so we must
% extract the diagonal.
if doV
  D=diag(D);
end;

% Sort them in descending order
[~,idx]=sort(abs(D),1,'descend');
D=D(idx(1:K));

if doV
  V=V(:,idx(1:K));
  varargout={V,D};
else
  varargout={D};
end;

% Clean the eigenvalues, if we know that they are real-valued
%if isreal(ga) && isreal(gs) && isreal(c)
%  D=real(D);
%end;

