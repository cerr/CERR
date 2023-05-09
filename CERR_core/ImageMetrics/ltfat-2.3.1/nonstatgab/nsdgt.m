function [c,Ls] = nsdgt(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} nsdgt
%@verbatim
%NSDGT  Non-stationary Discrete Gabor transform
%   Usage:  c=nsdgt(f,g,a,M);
%           [c,Ls]=nsdgt(f,g,a,M);
%
%   Input parameters:
%         f     : Input signal.
%         g     : Cell array of window functions.
%         a     : Vector of time shifts.
%         M     : Vector of numbers of frequency channels.
%   Output parameters:
%         c     : Cell array of coefficients.
%         Ls    : Length of input signal.
%
%   NSDGT(f,g,a,M) computes the non-stationary Gabor coefficients of the
%   input signal f. The signal f can be a multichannel signal, given in
%   the form of a 2D matrix of size Ls xW, with Ls the signal
%   length and W the number of signal channels.
%
%   The non-stationary Gabor theory extends standard Gabor theory by
%   enabling the evolution of the window over time. It is therefor necessary
%   to specify a set of windows instead of a single window.  This is done by
%   using a cell array for g. In this cell array, the n'th element g{n}
%   is a row vector specifying the n'th window.
%
%   The resulting coefficients also require a storage in a cell array, as
%   the number of frequency channels is not constant over time. More
%   precisely, the n'th cell of c, c{n}, is a 2D matrix of size 
%   M(n) xW and containing the complex local spectra of the signal channels
%   windowed by the n'th window g{n} shifted in time at position a(n).
%   c{n}(m,w) is thus the value of the coefficient for time index n,
%   frequency index m and signal channel w.
%
%   The variable a contains the distance in samples between two
%   consequtive blocks of coefficients. The variable M contains the
%   number of channels for each block of coefficients. Both a and M are
%   vectors of integers.
%
%   The variables g, a and M must have the same length, and the result c*
%   will also have the same length.
%   
%   The time positions of the coefficients blocks can be obtained by the
%   following code. A value of 0 correspond to the first sample of the
%   signal:
%
%     timepos = cumsum(a)-a(1);
%
%   [c,Ls]=NSDGT(f,g,a,M) additionally returns the length Ls of the input 
%   signal f. This is handy for reconstruction:
%
%     [c,Ls]=nsdgt(f,g,a,M);
%     fr=insdgt(c,gd,a,Ls);
%
%   will reconstruct the signal f no matter what the length of f is, 
%   provided that gd are dual windows of g.
%
%   Notes:
%   ------
%
%   NSDGT uses circular border conditions, that is to say that the signal is
%   considered as periodic for windows overlapping the beginning or the 
%   end of the signal.
%
%   The phaselocking convention used in NSDGT is different from the
%   convention used in the DGT function. NSDGT results are phaselocked (a
%   phase reference moving with the window is used), whereas DGT results are
%   not phaselocked (a fixed phase reference corresponding to time 0 of the
%   signal is used). See the help on PHASELOCK for more details on
%   phaselocking conventions.
%
%
%
%   References:
%     P. Balazs, M. Doerfler, F. Jaillet, N. Holighaus, and G. A. Velasco.
%     Theory, implementation and applications of nonstationary Gabor frames.
%     J. Comput. Appl. Math., 236(6):1481--1496, 2011.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/nonstatgab/nsdgt.html}
%@seealso{insdgt, nsgabdual, nsgabtight, phaselock, demo_nsdgt}
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
  
%   AUTHOR : Florent Jaillet and Nicki Holighaus
%   TESTING: TEST_NSDGT
%   REFERENCE: REF_NSDGT

% Notes:
% - The choice of a different phaselocking convention than the one used in
%   dgt is motivated by the will to keep a diagonal frame operator in the
%   painless case and to keep the circular border condition. With the other
%   convention, there is in general a problem for windows overlapping the
%   beginning and the end of the signal (except if time positions and
%   signal length have some special ratio properties).


if ~isnumeric(a)
  error('%s: a must be numeric.',upper(mfilename));
end;

if ~isnumeric(M)
  error('%s: M must be numeric.',upper(mfilename));
end;

%% ----- step 1 : Verify f and determine its length -------
% Change f to correct shape.
[f,Ls,W,wasrow,remembershape]=comp_sigreshape_pre(f,upper(mfilename),0);

L=nsdgtlength(Ls,a);
f=postpad(f,L);

[g,info]=nsgabwin(g,a,M);

timepos=cumsum(a)-a(1);

N=length(a); % Number of time positions

c=cell(N,1); % Initialisation of the result
    
% The actual transform
   
for ii = 1:N
    Lg = length(g{ii});
    
    % This is an explicit fftshift
    idx=[Lg-floor(Lg/2)+1:Lg,1:ceil(Lg/2)];

    win_range = mod(timepos(ii)+(-floor(Lg/2):ceil(Lg/2)-1),L)+1;
    if M(ii) < Lg 
        % if the number of frequency channels is too small, aliasing is introduced
        col = ceil(Lg/M(ii));
        
        temp = zeros(col*M(ii),W,assert_classname(f,g{1}));
        temp([end-floor(Lg/2)+1:end,1:ceil(Lg/2)],:) = bsxfun(@ ...
                                                          times,f(win_range,:),g{ii}(idx));
        
        temp = reshape(temp,M(ii),col,W);
        X = squeeze(fft(sum(temp,2)));
        
        c{ii}=X;
    else
        
        temp = zeros(M(ii),W,assert_classname(f,g{1}));
        temp([end-floor(Lg/2)+1:end,1:ceil(Lg/2)],:) = bsxfun(@times, ...
                                                          f(win_range,:),g{ii}(idx));
        
        
        c{ii} = fft(temp);
    end       
end

