function [h,relres,iter]=iframemul(f,Fa,Fs,s,varargin)
%-*- texinfo -*-
%@deftypefn {Function} iframemul
%@verbatim
%IFRAMEMUL  Inverse of frame multiplier
%   Usage: h=iframemul(f,Fa,Fs,s);
%         [h,relres,iter]=iframemul(...);
%
%   Input parameters:
%          Fa   : Analysis frame
%          Fs   : Synthesis frame
%          s    : Symbol
%          f    : Input signal
%
%   Output parameters: 
%          h    : Output signal
%
%   IFRAMEMUL(f,F,s) applies the inverse of the frame multiplier with
%   symbol s to the signal f. The frame Fa is used for analysis
%   and the frame Fs for synthesis.
%
%   Because the inverse of a frame multiplier is not necessarily again a
%   frame multiplier for the same frames, the problem is solved using an 
%   iterative algorithm.
%
%   [h,relres,iter]=IFRAMEMUL(...) additionally returns the relative
%   residuals in a vector relres and the number of iteration steps iter.
%
%   IFRAMEMUL takes the following parameters at the end of the line of
%   input arguments:
%
%     'tol',t      Stop if relative residual error is less than the
%                  specified tolerance. Default is 1e-9 
%
%     'maxit',n    Do at most n iterations.
%
%     'print'      Display the progress.
%
%     'quiet'      Don't print anything, this is the default.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/iframemul.html}
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

%   See also: iframemul
  
% Author: Peter L. Soendergaard

if nargin < 4
    error('%s: Too few input parameters.',upper(mfilename));
end;

tolchooser.double=1e-9;
tolchooser.single=1e-5;

definput.keyvals.tol=tolchooser.(class(f));
definput.keyvals.maxit=100;
definput.keyvals.printstep=10;
definput.flags.print={'quiet','print'};

[flags,kv]=ltfatarghelper({},definput,varargin);

% Check for compatibility
L1=framelength(Fa,size(f,1));
L2=framelengthcoef(Fs,size(s,1));
if L1~=L2
    error(['%s: The symbol and signal lengths are incompatible.'],upper(mfilename));
end;

% This is not *strictly* necessary, but we cannot check that the symbol
% is complex-valued in just the right way.
if Fa.realinput && ~isreal(s)
    error(['%s: For real-valued-input-only frames, the symbol must also ' ...
           'be real.'],upper(mfilename));
end;

% The frame multiplier is not positive definite, so we cannot solve it
% directly using pcg.
% Apply the multiplier followed by its adjoint. 
A=@(x) framemuladj(framemul(x,Fa,Fs,s),Fa,Fs,s);

[h,flag,dummytilde,iter1,relres]=pcg(A,framemuladj(f,Fa,Fs,s),kv.tol,kv.maxit);




