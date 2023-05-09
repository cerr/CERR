function [c,Ls,g]=dgtreal(f,g,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} dgtreal
%@verbatim
%DGTREAL  Discrete Gabor transform for real-valued signals
%   Usage:  c=dgtreal(f,g,a,M);
%           c=dgtreal(f,g,a,M,L);
%           [c,Ls]=dgtreal(f,g,a,M);
%           [c,Ls]=dgtreal(f,g,a,M,L);
%
%   Input parameters:
%         f     : Input data
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of modulations.
%         L     : Length of transform to do.
%   Output parameters:
%         c     : M*N array of coefficients.
%         Ls    : Length of input signal.
%
%   DGTREAL(f,g,a,M) computes the Gabor coefficients (also known as a
%   windowed Fourier transform) of the real-valued input signal f with
%   respect to the real-valued window g and parameters a and M. The
%   output is a vector/matrix in a rectangular layout.
%
%   As opposed to DGT only the coefficients of the positive frequencies
%   of the output are returned. DGTREAL will refuse to work for complex
%   valued input signals.
%
%   The length of the transform will be the smallest multiple of a and M*
%   that is larger than the signal. f will be zero-extended to the length of
%   the transform. If f is a matrix, the transformation is applied to each
%   column. The length of the transform done can be obtained by
%   L=size(c,2)*a.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of GABWIN for more details.
%
%   DGTREAL(f,g,a,M,L) computes the Gabor coefficients as above, but does
%   a transform of length L. f will be cut or zero-extended to length L before
%   the transform is done.
%
%   [c,Ls]=DGTREAL(f,g,a,M) or [c,Ls]=DGTREAL(f,g,a,M,L) additionally
%   returns the length of the input signal f. This is handy for
%   reconstruction:
%
%     [c,Ls]=dgtreal(f,g,a,M);
%     fr=idgtreal(c,gd,a,M,Ls);
%
%   will reconstruct the signal f no matter what the length of f is, provided
%   that gd is a dual window of g.
%
%   [c,Ls,g]=DGTREAL(...) additionally outputs the window used in the
%   transform. This is useful if the window was generated from a description
%   in a string or cell array.
%
%   See the help on DGT for the definition of the discrete Gabor
%   transform. This routine will return the coefficients for channel
%   frequencies from 0 to floor(M/2).
%
%   DGTREAL takes the following flags at the end of the line of input
%   arguments:
%
%     'freqinv'  Compute a DGTREAL using a frequency-invariant phase. This
%                is the default convention described in the help for DGT.
%
%     'timeinv'  Compute a DGTREAL using a time-invariant phase. This
%                convention is typically used in filter bank algorithms.
%
%   DGTREAL can be used to manually compute a spectrogram, if you
%   want full control over the parameters and want to capture the output
%   :
%
%     f=greasy;  % Input test signal
%     fs=16000;  % The sampling rate of this particular test signal
%     a=10;      % Downsampling factor in time
%     M=200;     % Total number of channels, only 101 will be computed
%
%     % Compute the coefficients using a 20 ms long Hann window
%     c=dgtreal(f,{'hann',0.02*fs'},a,M);
%
%     % Visualize the coefficients as a spectrogram
%     dynrange=90; % 90 dB dynamical range for the plotting
%     plotdgtreal(c,a,M,fs,dynrange);
%     
%
%   References:
%     K. Groechenig. Foundations of Time-Frequency Analysis. Birkhauser, 2001.
%     
%     H. G. Feichtinger and T. Strohmer, editors. Gabor Analysis and
%     Algorithms. Birkhauser, Boston, 1998.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/dgtreal.html}
%@seealso{dgt, idgtreal, gabwin, dwilt, gabtight, plotdgtreal}
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
%   REFERENCE: OK
  
% Assert correct input.

if nargin<4
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.L=[];
definput.flags.phase={'freqinv','timeinv'};
definput.keyvals.lt=[0 1];
[flags,kv]=ltfatarghelper({'L'},definput,varargin);

[f,g,~,Ls] = gabpars_from_windowsignal(f,g,a,M,kv.L);

if ~isreal(g)
    error('%s: The window must be real-valued.',upper(mfilename));  
end;

if kv.lt(2)>2
    error('%s: Only rectangular or quinqux lattices are supported.',...
          upper(mfilename));  
end;

if kv.lt(2)~=1 && flags.do_timeinv
    error(['%s: Time-invariant phase for quinqux lattice is not ',...
           'supported.'],upper(mfilename));
end

c=comp_dgtreal(f,g,a,M,kv.lt,flags.do_timeinv);


