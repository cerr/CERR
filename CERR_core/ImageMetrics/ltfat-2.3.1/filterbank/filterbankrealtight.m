function gtout=filterbankrealtight(g,a,L)
%-*- texinfo -*-
%@deftypefn {Function} filterbankrealtight
%@verbatim
%FILTERBANKREALTIGHT  Tight filters of filterbank for real signals only 
%   Usage:  gt=filterbankrealtight(g,a,L);
%           gt=filterbankrealtight(g,a);
%
%   filterabankrealtight(g,a,L) computes the canonical tight filters of 
%   g for a channel subsampling rate of a (hop-size) and a system 
%   length L. L must be compatible with subsampling rate a as 
%   L==filterbanklength(L,a). The tight filters work only for real-valued
%   signals. Use this function on the common construction where the filters
%   in g only covers the positive frequencies.
%
%   filterabankrealtight(g,a) does the same, but the filters must be FIR
%   filters, as the transform length is unspecified. L will be set to 
%   next suitable length equal or bigger than the longest impulse response.  
%
%   The format of the filters g are described in the help of FILTERBANK.
%
%   REMARK: The resulting system is tight for length L. In some cases, 
%   using tight system calculated for shorter L might work but check the
%   reconstruction error.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbankrealtight.html}
%@seealso{filterbank, ufilterbank, ifilterbank}
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

complainif_notenoughargs(nargin,2,'FILTERBANKREALTIGHT');

if nargin<3
   L = [];
end

[g,asan,info]=filterbankwin(g,a,L,'normal');
if isempty(L) 
    if info.isfir
        % Pick shortest possible length for FIR filterbank
        L = filterbanklength(info.longestfilter,asan);
    else
        % Just thow an error, nothing reasonable can be done without L
        error(['%s: L must be specified when not working with FIR ',...'
               'filterbanks.'], upper(mfilename));
    end
end
M=info.M;

if L~=filterbanklength(L,a)
     error(['%s: Specified length L is incompatible with the length of ' ...
            'the time shifts.'],upper(mfilename));
end;

% Prioritize painless over uniform algorithm
if info.isuniform && info.ispainless
    info.isuniform = 0;
end

if info.isuniform
  % Uniform filterbank, use polyphase representation
  a=a(1);
  
  % Transfer functions of individual filters as cols
  G = filterbankfreqz(g,a,L);
  thisclass = class(G);
  
  N=L/a;

  gt=zeros(M,N,thisclass);
  
  for w=0:N-1
    idx_a = mod(w-(0:a-1)*N,L)+1;
    idx_b = mod((0:a-1)*N-w,L)+1;
    Ha = G(idx_a,:);
    Hb = conj(G(idx_b,:));
    
    Ha=sqrtm(Ha*Ha'+Hb*Hb')\Ha;
    
    gt(:,idx_a)=Ha.';
  end;
  % gt was created transposed because the indexing gt(:,idx_a)
  % is much faster than gt(idx_a,:)
  gt =  gt.';
  
  gt=ifft(gt)*sqrt(a);
  
  % Matrix cols to cell elements + cast
  gtout = cellfun(@(gtEl) cast(gtEl,thisclass), num2cell(gt,1),...
                  'UniformOutput',0);
  
else
        
    if info.ispainless
        gtout = comp_painlessfilterbank(g,asan,L,'tight',1);

    else
        error(['%s: The canonical dual frame of this system is not a ' ...
               'filterbank. You must call an iterative ' ...
               'method to perform the desired inverstion. Please see ' ...
               'FRANAITER or FRSYNITER.'],upper(mfilename));        

    end;
  
end;

