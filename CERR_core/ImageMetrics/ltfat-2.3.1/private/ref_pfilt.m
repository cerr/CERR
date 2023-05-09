function h=ref_pfilt(f,g,a)
%-*- texinfo -*-
%@deftypefn {Function} ref_pfilt
%@verbatim
%REF_PFILT  Reference pfilt handling structs
%   Usage:  h=pfilt(f,g);
%           h=pfilt(f,g,a,dim);
%
%   pfilt(f,g) applies the filter g to the input f. If f is a
%   matrix, the filter is applied along each column.
%
%   pfilt(f,g,a) does the same, but downsamples the output keeping only
%   every a'th sample (starting with the first one).
%
%   pfilt(f,g,a,dim) filters along dimension dim. The default value of
%   [] means to filter along the first non-singleton dimension.
%
%   The filter g can be a vector, in which case the vector is treated
%   as a zero-delay FIR filter.
%
%   The filter g can be a cell array. The following options are
%   possible:
%
%      If the first element of the cell array is the name of one of the
%       windows from FIRWIN, the whole cell array is passed onto
%       FIRFILTER.
%
%      If the first element of the cell array is 'bl', the rest of the
%     cell array is passed onto BLFILTER.
%
%      If the first element of the cell array is 'pgauss', 'psech',
%       the rest of the parameters is passed onto the respective
%       function. Note that you do not need to specify the length L.
%
%   The coefficients obtained from filtering a signal f by a filter g are
%   defined by
%
%               L-1
%      c(n+1) = sum f(l+1) * g(an-l+1)
%               l=0
%
%   where an-l is computed modulo L.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_pfilt.html}
%@seealso{pconv}
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

if nargin<3
    a=1;
end;

[L,W]=size(f);

l=(0:L-1).'/L;
if isstruct(g)
    if isfield(g,'h')
        g_time=circshift(postpad(g.h,L),g.offset).*exp(2*pi*1i*(round(g.fc*L/2))*l);
        G=fft(g_time);
    elseif isfield(g,'H')
        G=circshift(postpad(g.H(L),L),g.foff(L)).*exp(-2*pi*1i*round(g.delay)*l);  
    else
       error('%s: Unknown filter definition.',upper(mfilename));
    end;
    
else
    G=fft(fir2long(g,L));
end;

if numel(a) > 1
    % This is possibly a fractional subsampling
    
    afrac = a(1)/a(2);
    if a(1) ~= L
        error('%s: The length in a(1) is not equal to L.',upper(mfilename));
    end
    N = L/afrac;
    if abs(N-round(N))>1e-5
        error('%s: Output length is not integer.',upper(mfilename));
    else
        N = round(N);
    end
    
    foff = g.foff(L);
    
    h=zeros(N,W,assert_classname(f));
    for w=1:W
        h(:,w) = blfilt(f(:,w),G,N,foff,afrac);
         
        if isstruct(g) && isfield(g,'realonly') && g.realonly
            G2 = involute(G);
            supp = numel(g.H(L));
            foff2 = -L+mod(L-foff-supp,L)+1;
            h(:,w) = (h(:,w) + blfilt(f(:,w),G2,N,foff2,afrac))/2;
        end;
         
    end;   
    
    

    
else
    % This is regular subsampling case
    if isstruct(g) && isfield(g,'realonly') && g.realonly
        G=(G+involute(G))/2;
    end;
    
    N=L/a;
    h=zeros(N,W,assert_classname(f));
    for w=1:W
        F=fft(f(:,w));
        h(:,w)=ifft(sum(reshape(F.*G,N,a),2))/a;
    end;   
end
    

function h = blfilt(f,G,N,foff,afrac)
L = size(f,1);

align = foff - floor(foff/N)*N;

F = circshift(fft(f).*G,-foff);

F = postpad(F,ceil(L/N)*N); 

F = circshift(F,align);

F = sum(reshape(F,N,numel(F)/N),2);

h = ifft(F)/afrac;



