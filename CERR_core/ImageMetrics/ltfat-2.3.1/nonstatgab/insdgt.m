function f=insdgt(c,g,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} insdgt
%@verbatim
%INSDGT  Inverse non-stationary discrete Gabor transform
%   Usage:  f=insdgt(c,g,a,Ls);
%
%   Input parameters:
%         c     : Cell array of coefficients.
%         g     : Cell array of window functions.
%         a     : Vector of time positions of windows.
%         Ls    : Length of input signal.
%   Output parameters:
%         f     : Signal.
%
%   INSDGT(c,g,a,Ls) computes the inverse non-stationary Gabor transform
%   of the input coefficients c.
%
%   INSDGT is used to invert the functions NSDGT and UNSDGT. Please
%   read the help of these functions for details of variables format and
%   usage.
%
%   For perfect reconstruction, the windows used must be dual windows of the
%   ones used to generate the coefficients. The windows can be generated
%   using NSGABDUAL or NSGABTIGHT.
%
%
%
%   References:
%     P. Balazs, M. Doerfler, F. Jaillet, N. Holighaus, and G. A. Velasco.
%     Theory, implementation and applications of nonstationary Gabor frames.
%     J. Comput. Appl. Math., 236(6):1481--1496, 2011.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/nonstatgab/insdgt.html}
%@seealso{nsdgt, nsgabdual, nsgabtight, demo_nsdgt}
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
%   REFERENCE: REF_INSDGT
%   Last changed 2009-05

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~isnumeric(a)
  error('%s: a must be numeric.',upper(mfilename));
end;

definput.keyvals.Ls=[];
[flags,kv,Ls]=ltfatarghelper({'Ls'},definput,varargin);

timepos=cumsum(a)-a(1);
L=sum(a);

if iscell(c)
    % ---- invert the non-uniform case ---------
    M=cellfun(@(x) size(x,1),c);
    N=length(c);
    W=size(c{1},2);   
    f=zeros(L,W,assert_classname(c{1}));
else
    % ---- invert the uniform case ----------------
    [M, N, W]=size(c);   
    f=zeros(L,W,assert_classname(c));
end

[g,info]=nsgabwin(g,a,M);



for ii = 1:N
    Lg = length(g{ii});
    gt = g{ii};
    
    % This is an explicit fftshift
    gt = gt([Lg-floor(Lg/2)+1:Lg,1:ceil(Lg/2)]);
    
    win_range = mod(timepos(ii)+(-floor(Lg/2):ceil(Lg/2)-1),L)+1;
    
    if iscell(c)
        M = size(c{ii},1);
        temp = ifft(c{ii},[],1)*M;
    else
        temp = ifft(c(:,ii,:),[],1)*M;
    end
    idx = mod([M-floor(Lg/2)+1:M,1:ceil(Lg/2)]-1,M)+1;
    temp = temp(idx,:);
    f(win_range,:) = f(win_range,:) + bsxfun(@times,temp,gt);
end

if ~isempty(Ls)
  f = f(1:Ls,:);
end;

