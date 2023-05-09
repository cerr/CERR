function [c,Ls] = unsdgtreal(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} unsdgtreal
%@verbatim
%UNSDGTREAL  Uniform non-stationary Discrete Gabor transform
%   Usage:  c=unsdgtreal(f,g,a,M);
%           [c,Ls]=unsdgtreal(f,g,a,M);
%
%   Input parameters:
%         f     : Input signal.
%         g     : Cell array of window functions.
%         a     : Vector of time positions of windows.
%         M     : Vector of numbers of frequency channels.
%   Output parameters:
%         c     : Cell array of coefficients.
%         Ls    : Length of input signal.
%
%   UNSDGTREAL(f,g,a,M) computes the non-stationary Gabor coefficients of the
%   input signal f. The signal f can be a multichannel signal, given in
%   the form of a 2D matrix of size Ls xW, with Ls the signal
%   length and W the number of signal channels.
%
%   As opposed to NSDGT only the coefficients of the positive frequencies
%   of the output are returned. UNSDGTREAL will refuse to work for complex
%   valued input signals.
%
%   The non-stationary Gabor theory extends standard Gabor theory by
%   enabling the evolution of the window over time. It is therefore
%   necessary to specify a set of windows instead of a single window.  This
%   is done by using a cell array for g. In this cell array, the n'th
%   element g{n} is a row vector specifying the n'th window. The
%   uniformity means that the number of channels is not allowed to vary over
%   time.
%
%   The resulting coefficients is stored as a M/2+1 xN xW
%   array. c(m,n,l) is thus the value of the coefficient for time index n,
%   frequency index m and signal channel l.
%
%   The variable a contains the distance in samples between two
%   consecutive blocks of coefficients. The variable M contains the
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
%   [c,Ls]=UNSDGTREAL(f,g,a,M) additionally returns the length Ls of the input 
%   signal f. This is handy for reconstruction:
%
%     [c,Ls]=unsdgtreal(f,g,a,M);
%     fr=insdgtreal(c,gd,a,Ls);
%
%   will reconstruct the signal f no matter what the length of f is, 
%   provided that gd are dual windows of g.
%
%   Notes:
%   ------
%
%   UNSDGTREAL uses circular border conditions, that is to say that the signal is
%   considered as periodic for windows overlapping the beginning or the 
%   end of the signal.
%
%   The phaselocking convention used in UNSDGTREAL is different from the
%   convention used in the DGT function. UNSDGTREAL results are phaselocked (a
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
%@strong{Url}: @url{http://ltfat.github.io/doc/nonstatgab/unsdgtreal.html}
%@seealso{nsdgt, insdgtreal, nsgabdual, nsgabtight, phaselock, demo_nsdgt}
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
  
%   AUTHOR : Florent Jaillet
%   TESTING: TEST_NSDGTREAL
%   REFERENCE: 

if ~isnumeric(a)
  error('%s: a must be numeric.',upper(mfilename));
end;

if ~isnumeric(M)
  error('%s: M must be numeric.',upper(mfilename));
end;

L=sum(a);

[f,Ls,W,wasrow,remembershape]=comp_sigreshape_pre(f,'UNSDGTREAL',0);
f=postpad(f,L);

[g,info]=nsgabwin(g,a,M);

if ~info.isuniform
    error('%s: M must be a scalar or a constant vector.',upper(mfilename));    
end;
M=M(1);

timepos=cumsum(a)-a(1);
  
N=length(a); % Number of time positions

M2=floor(M/2)+1;
c=zeros(M2,N,W,assert_classname(f,g{1})); % Initialisation of the result

for ii=1:N
  shift=floor(length(g{ii})/2);
  temp=zeros(M,W,assert_classname(f,g{1}));
  
  % Windowing of the signal.
  % Possible improvements: The following could be computed faster by 
  % explicitely computing the indexes instead of using modulo and the 
  % repmat is not needed if the number of signal channels W=1 (but the time 
  % difference when removing it whould be really small)
  temp(1:length(g{ii}))=f(mod((1:length(g{ii}))+timepos(ii)-shift-1,L)+1,:).*...
    repmat(conj(circshift(g{ii},shift)),1,W);
  
  temp=circshift(temp,-shift);
  if M<length(g{ii}) 
    % Fft size is smaller than window length, some aliasing is needed
    x=floor(length(g{ii})/M);
    y=length(g{ii})-x*M;
    % Possible improvements: the following could probably be computed 
    % faster using matrix manipulation (reshape, sum...)
    temp1=temp;
    temp=zeros(M,size(temp,2),assert_classname(f,g{1}));
    for jj=0:x-1
      temp=temp+temp1(jj*M+(1:M),:);
    end
    temp(1:y,:)=temp(1:y,:)+temp1(x*M+(1:y),:);
  end
  
  % FFT of the windowed signal
  c(:,ii,:) = reshape(fftreal(temp),M2,1,W); 
end


