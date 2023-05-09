function [c,Ls,g]=dgt(f,g,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} dgt
%@verbatim
%DGT  Discrete Gabor transform
%   Usage:  c=dgt(f,g,a,M);
%           c=dgt(f,g,a,M,L);
%           c=dgt(f,g,a,M,'lt',lt);
%           [c,Ls]=dgt(...);
%
%   Input parameters:
%         f     : Input data.
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of channels.
%         L     : Length of transform to do.
%         lt    : Lattice type (for non-separable lattices).
%   Output parameters:
%         c     : M xN array of coefficients.
%         Ls    : Length of input signal.
%
%   DGT(f,g,a,M) computes the Gabor coefficients (also known as a windowed
%   Fourier transform) of the input signal f with respect to the window
%   g and parameters a and M. The output is a vector/matrix in a
%   rectangular layout.
%
%   The length of the transform will be the smallest multiple of a and M*
%   that is larger than the signal. f will be zero-extended to the length of
%   the transform. If f is a matrix, the transformation is applied to each
%   column. The length of the transform done can be obtained by
%   L=size(c,2)*a;
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of GABWIN for more details.
%
%   DGT(f,g,a,M,L) computes the Gabor coefficients as above, but does
%   a transform of length L. f will be cut or zero-extended to length L before
%   the transform is done.
%
%   [c,Ls]=DGT(f,g,a,M) or [c,Ls]=DGT(f,g,a,M,L) additionally returns the
%   length of the input signal f. This is handy for reconstruction:
%
%               [c,Ls]=dgt(f,g,a,M);
%               fr=idgt(c,gd,a,Ls);
%
%   will reconstruct the signal f no matter what the length of f is, provided
%   that gd is a dual window of g.
%
%   [c,Ls,g]=DGT(...) additionally outputs the window used in the
%   transform. This is useful if the window was generated from a description
%   in a string or cell array.
%
%   The Discrete Gabor Transform is defined as follows: Consider a window g*
%   and a one-dimensional signal f of length L and define N=L/a.
%   The output from c=DGT(f,g,a,M) is then given by:
%
%                   L-1 
%      c(m+1,n+1) = sum f(l+1)*conj(g(l-a*n+1))*exp(-2*pi*i*m*l/M), 
%                   l=0  
%
%   where m=0,...,M-1 and n=0,...,N-1 and l-an is computed
%   modulo L.
%
%   Non-separable lattices:
%   -----------------------
%
%   DGT(f,g,a,M,'lt',lt) computes the DGT for a non-separable lattice
%   given by the time-shift a, number of channels M and lattice type
%   lt. Please see the help of MATRIX2LATTICETYPE for a precise
%   description of the parameter lt.
%
%   The non-separable discrete Gabor transform is defined as follows:
%   Consider a window g and a one-dimensional signal f of length L and
%   define N=L/a.  The output from c=DGT(f,g,a,M,L,lt) is then given
%   by:
%
%                   L-1 
%      c(m+1,n+1) = sum f(l+1)*conj(g(l-a*n+1))*exp(-2*pi*i*(m+w(n))*l/M), 
%                   l=0  
%
%   where m=0,...,M-1 and n=0,...,N-1 and l-an are computed
%   modulo L.  The additional offset w is given by w(n)=mod(n*lt_1,lt_2)/lt_2
%   in the formula above.
%
%   Additional parameters:
%   ----------------------
%
%   DGT takes the following flags at the end of the line of input
%   arguments:
%
%     'freqinv'  Compute a DGT using a frequency-invariant phase. This
%                is the default convention described above.
%
%     'timeinv'  Compute a DGT using a time-invariant phase. This
%                convention is typically used in FIR-filter algorithms.
%
%   Examples:
%   ---------
%
%   In the following example we create a Hermite function, which is a
%   complex-valued function with a circular spectrogram, and visualize
%   the coefficients using both imagesc and PLOTDGT:
%
%     a=10;
%     M=40;
%     L=a*M;
%     h=pherm(L,4); % 4th order hermite function.
%     c=dgt(h,'gauss',a,M);
%
%     % Simple plot: The squared modulus of the coefficients on
%     % a linear scale
%     figure(1);
%     imagesc(abs(c).^2);
%
%     % Better plot: zero-frequency is displayed in the middle, 
%     % and the coefficients are show on a logarithmic scale.
%     figure(2);
%     plotdgt(c,a,'dynrange',50);
%
%
% 
%   References:
%     K. Groechenig. Foundations of Time-Frequency Analysis. Birkhauser, 2001.
%     
%     H. G. Feichtinger and T. Strohmer, editors. Gabor Analysis and
%     Algorithms. Birkhauser, Boston, 1998.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/dgt.html}
%@seealso{idgt, gabwin, dwilt, gabdual, phaselock, demo_dgt}
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

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: TEST_DGT
%   REFERENCE: REF_DGT
  
%% ---------- Assert correct input.

if nargin<4
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.L=[];
definput.keyvals.lt=[0 1];
definput.keyvals.dim=[];
definput.flags.phase={'freqinv','timeinv'};
[flags,kv,L]=ltfatarghelper({'L'},definput,varargin);


%% ----- step 1 : Verify f and determine its length -------
% Change f to correct shape.
%[f,Ls,W,wasrow,remembershape]=comp_sigreshape_pre(f,upper(mfilename),0);
[f,~,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],kv.dim,upper(mfilename));


%% ------ step 2: Verify a, M and L
if isempty(L)

    % ----- step 2b : Verify a, M and get L from the signal length f----------
    L=dgtlength(Ls,a,M,kv.lt);

else

    % ----- step 2a : Verify a, M and get L
    Luser=dgtlength(L,a,M,kv.lt);
    if Luser~=L
        error(['%s: Incorrect transform length L=%i specified. Next valid length ' ...
               'is L=%i. See the help of DGTLENGTH for the requirements.'],...
              upper(mfilename),L,Luser);
    end;

end;

%% ----- step 3 : Determine the window 

[g,info]=gabwin(g,a,M,L,kv.lt,'callfun',upper(mfilename));

if L<info.gl
  error('%s: Window is too long.',upper(mfilename));
end;

%% ----- step 4: final cleanup ---------------

f=postpad(f,L);

% If the signal is single precision, make the window single precision as
% well to avoid mismatches.
if isa(f,'single')
  g=single(g);
end;

%% ------ call the computation subroutines 

c=comp_dgt(f,g,a,M,kv.lt,flags.do_timeinv,0,0);

order=assert_groworder(order);
permutedsize=[M,L/a,permutedsize(2:end)];

c=assert_sigreshape_post(c,dim,permutedsize,order);

if numel(size(c)>2) && size(c,1)==1
   c = squeeze(c);
end


