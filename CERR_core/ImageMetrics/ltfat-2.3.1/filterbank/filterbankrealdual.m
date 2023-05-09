function gdout=filterbankrealdual(g,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} filterbankrealdual
%@verbatim
%FILTERBANKREALDUAL  Dual filters of filterbank for real signals only 
%   Usage:  gd=filterbankrealdual(g,a,L);
%           gd=filterbankrealdual(g,a);
%
%   FILTERBANKREALDUAL(g,a,L) computes the canonical dual filters of g*
%   for a channel subsampling rate of a (hop-size) and a system length L.
%   L must be compatible with subsampling rate a as 
%   L==filterbanklength(L,a). The dual filters work only for real-valued
%   signals. Use this function on the common construction where the filters
%   in g only covers the positive frequencies.
%
%   filterabankrealdual(g,a) does the same, but the filters must be FIR
%   filters, as the transform length is unspecified. L will be set to 
%   next suitable length equal or bigger than the longest impulse response.
%
%   The format of the filters g are described in the help of FILTERBANK.
%
%   In addition, the function recognizes a 'forcepainless' flag which
%   forces treating the filterbank g and a as a painless case
%   filterbank.  
%
%   To actually invert the output of a filterbank, use the dual filters
%   together with 2*real(ifilterbank(...)).
%
%   REMARK: Perfect reconstruction can be obtained for signals of length
%   L. In some cases, using dual system calculated for shorter L might
%   work but check the reconstruction error.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbankrealdual.html}
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

complainif_notenoughargs(nargin,2,'FILTERBANKREALDUAL');

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

      % This is the original code
      %for k=0:a-1
      %  Ha(k+1,:) =      G(mod(w-k*N,L)+1,:);
      %  Hb(k+1,:) = conj(G(mod(k*N-w,L)+1,:));
      %end;
    gd=zeros(M,N,thisclass);

    for w=0:N-1
        idx_a = mod(w-(0:a-1)*N,L)+1;
        idx_b = mod((0:a-1)*N-w,L)+1;
        Ha = G(idx_a,:);
        Hb = conj(G(idx_b,:));

        Ha=(Ha*Ha'+Hb*Hb')\Ha;

        gd(:,idx_a)=Ha.';
    end;
    % The gd was created transposed because the indexing gd(:,idx_a)
    % is much faster than gd(idx_a,:)
    gd=gd.';
    gd=ifft(gd)*a;

    gdout = cellfun(@(gdEl) cast(gdEl,thisclass), num2cell(gd,1),...
                      'UniformOutput',0);

    % All filters in gdout will be treated as FIR of length L. Convert them
    % to a struct with .h and .offset format.
    gdout = filterbankwin(gdout,a);            
  
elseif info.ispainless
    gdout = comp_painlessfilterbank(g,asan,L,'dual',1);
else
    error(['%s: The canonical dual frame of this system is not a ' ...
               'filterbank. You must call an iterative ' ...
               'method to perform the desired inversion. Please see ' ...
               'FRANAITER or FRSYNITER.'],upper(mfilename));                
        
end;  


