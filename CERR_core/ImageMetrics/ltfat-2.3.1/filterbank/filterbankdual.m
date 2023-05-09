function gdout=filterbankdual(g,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} filterbankdual
%@verbatim
%FILTERBANKDUAL  Dual filters
%   Usage:  gd=filterbankdual(g,a,L);
%           gd=filterbankdual(g,a);
%           
%
%   FILTERBANKDUAL(g,a,L) computes the canonical dual filters of g for a
%   channel subsampling rate of a (hop-size) and system length L.
%   L must be compatible with subsampling rate a as 
%   L==filterbanklength(L,a). This will create a dual frame valid for 
%   signals of length L. 
%
%   filterabankrealdual(g,a) does the same, but the filters must be FIR
%   filters, as the transform length is unspecified. L will be set to 
%   next suitable length equal or bigger than the longest impulse response
%   such that L=filterbanklength(gl_longest,a).
%
%   The input and output format of the filters g are described in the
%   help of FILTERBANK.
%
%   In addition, the funtion recognizes a 'forcepainless' flag which
%   forces treating the filterbank g and a as a painless case
%   filterbank.  
%
%   To actually invert the output of a filterbank, use the dual filters
%   together with the IFILTERBANK function.
%
%   REMARK: In general, perfect reconstruction can be obtained for signals 
%   of length L. In some cases, using dual system calculated for shorter
%   L might work but check the reconstruction error.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbankdual.html}
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

complainif_notenoughargs(nargin,2,'FILTERBANKDUAL');

definput.import={'filterbankdual'};
[flags,~,L]=ltfatarghelper({'L'},definput,varargin);

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

% Force usage of the painless algorithm 
if flags.do_forcepainless
    info.ispainless = 1;
end

% Check user defined L
if L~=filterbanklength(L,a)
     error(['%s: Specified length L is incompatible with the length of ' ...
            'the time shifts.'],upper(mfilename));
end;

% Prioritize painless over uniform algorithm if both are suitable
if info.isuniform && info.ispainless
    info.isuniform = 0;
end

% Factorization of frame operator to block-diagonal matrix
if info.isuniform
  % Uniform filterbank, use polyphase representation
  a=a(1);
  
  % Transfer functions of individual filters as cols
  G = filterbankfreqz(g,a,L);
  
  N=L/a;
  
  gd=zeros(M,N,class(G));
  
  for w=0:N-1
    idx = mod(w-(0:a-1)*N,L)+1;
    H = G(idx,:);
    
    H=pinv(H)';
    
    gd(:,idx)=H.';
  end;
  % gd was created transposed because the indexing gd(:,idx_a)
  % is much faster than gd(idx_a,:)
  gd =  gd.';
  
  gd=ifft(gd)*a;
  
  % Matrix cols to cell elements + cast
  gdout = cellfun(@(gdEl) cast(gdEl,class(G)), num2cell(gd,1),...
                  'UniformOutput',0);
  % All filters in gdout will be treated as FIR of length L. Convert them
  % to a struct with .h and .offset format.
  gdout = filterbankwin(gdout,a); 
  
elseif info.ispainless
   % Factorized frame operator is diagonal.
   gdout = comp_painlessfilterbank(g,asan,L,'dual',0);
else
        error(['%s: The canonical dual frame of this system is not a ' ...
               'filterbank. You must either call an iterative ' ...
               'method to perform the desired inverstion or transform ',...
               'or transform the filterbank to uniform one. Please see ' ...
               'FRANAITER or FRSYNITER for the former and ',...
               'NONU2UFILTERBANK for the latter case.'],upper(mfilename));        

    
end;

