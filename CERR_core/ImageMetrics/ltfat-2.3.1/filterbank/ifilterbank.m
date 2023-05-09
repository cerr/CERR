function [f,Ls]=ifilterbank(c,g,a,varargin);  
%-*- texinfo -*-
%@deftypefn {Function} ifilterbank
%@verbatim
%IFILTERBANK  Filter bank inversion
%   Usage:  f=ifilterbank(c,g,a);
%
%   IFILTERBANK(c,g,a) synthesizes a signal f from the coefficients c*
%   using the filters stored in g for a channel subsampling rate of a (the
%   hop-size). The coefficients has to be in the format returned by
%   either FILTERBANK or UFILTERBANK.
%
%   The filter format for g is the same as for FILTERBANK.
%
%   If perfect reconstruction is desired, the filters must be the duals
%   of the filters used to generate the coefficients. See the help on
%   FILTERBANKDUAL.
%
%
%   References:
%     H. Boelcskei, F. Hlawatsch, and H. G. Feichtinger. Frame-theoretic
%     analysis of oversampled filter banks. Signal Processing, IEEE
%     Transactions on, 46(12):3256--3268, 2002.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/ifilterbank.html}
%@seealso{filterbank, ufilterbank, filterbankdual}
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
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.import={'pfilt'};
definput.keyvals.Ls=[];
[flags,kv,Ls]=ltfatarghelper({'Ls'},definput,varargin);

L=filterbanklengthcoef(c,a);


if iscell(c)
  M=numel(c);
else
  M=size(c,2);
end;

[g,asan]=filterbankwin(g,a,L,'normal');

if numel(g)~=M
  error(['%s: Number of filters must be equal to the number of channels ' ...
            'of coefficients.'],upper(mfilename));
end

 if size(a,1)>1 
   if  size(a,1)~=M
     error(['%s: The number of entries in "a" must match the number of ' ...
            'filters.'],upper(mfilename));
   end;
 end;

g = comp_filterbank_pre(g,asan,L,kv.crossover);

% Handle ufilterbank output format here
if isnumeric(c)
   ctmp = c;
   c = cell(M,1);
   for m=1:M    
      c{m}=squeeze(ctmp(:,m,:));
   end;
end


f = comp_ifilterbank(c,g,asan,L);
  
% Cut or extend f to the correct length, if desired.
if ~isempty(Ls)
  f=postpad(f,Ls);
else
  Ls=L;
end;

