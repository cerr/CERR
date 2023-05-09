function sr=gabreassign(s,tgrad,fgrad,a)
%-*- texinfo -*-
%@deftypefn {Function} gabreassign
%@verbatim
%GABREASSIGN  Reassign time-frequency distribution
%   Usage:  sr = gabreassign(s,tgrad,fgrad,a);
%
%   GABREASSIGN(s,tgrad,fgrad,a) reassigns the values of the positive
%   time-frequency distribution s using the phase gradient given by fgrad*
%   and tgrad. The lattice is determined by the time shift a and the 
%   number of channels deduced from the size of s.
%
%   fgrad and tgrad can be obtained by the routine GABPHASEGRAD.
%
%   Examples:
%   ---------
%
%   The following example demonstrates how to manually create a
%   reassigned spectrogram. An easier way is to just call RESGRAM:
%
%     % Create reassigned vector field of the bat signal.
%     a=4; M=100;
%     [tgrad, fgrad, c] = gabphasegrad('dgt',bat,'gauss',a,M);
%
%     % Perform the actual reassignment
%     sr = gabreassign(abs(c).^2,tgrad,fgrad,a);
%
%     % Display it using plotdgt
%     plotdgt(sr,a,143000,50);
%  
%
%   References:
%     F. Auger and P. Flandrin. Improving the readability of time-frequency
%     and time-scale representations by the reassignment method. IEEE Trans.
%     Signal Process., 43(5):1068--1089, 1995.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabreassign.html}
%@seealso{resgram, gabphasegrad}
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

% AUTHOR: Peter L. Soendergaard, 2008.

thisname = upper(mfilename);
complainif_notenoughargs(nargin,4,thisname);
complainif_notposint(a,'a',thisname);


% Basic checks
if any(cellfun(@(el) isempty(el) || ~isnumeric(el),{s,tgrad,fgrad}))
    error('%s: s, tgrad, fgrad must be non-empty and numeric.',...
          upper(mfilename));
end

% Check if argument sizes are consistent
if ~isequal(size(s),size(tgrad),size(fgrad))
   error('%s: s, tgrad, fgrad must all have the same size.',...
          upper(mfilename));
end

% Check if any argument is not real
if any(cellfun(@(el) ~isreal(el),{tgrad,fgrad}))
   error('%s: tgrad, fgrad must be real.',...
          upper(mfilename));
end

% if any(s<0)
%     error('%s: s must contain positive numbers only.',...
%         upper(mfilename));
% end

sr=comp_gabreassign(s,tgrad,fgrad,a);


% The following code is currently not actived. It calculates the
% reassigment using anti-aliasing, but it make very little visual
% difference, and it is slower.
  %   [M,N,W]=size(s);
  %   L=N*a;
  %   b=L/M;
    
  %   freqpos=fftindex(M);  
  %   tgrad=bsxfun(@plus,tgrad/b,freqpos);
        
  %   timepos=fftindex(N);
  %   fgrad=bsxfun(@plus,fgrad/a,timepos.');
    
  %   tgrad=round(tgrad);
  %   fgrad=round(fgrad);
    
  %   tgrad=mod(tgrad,M);
  %   fgrad=mod(fgrad,N);  
    
  %   sr=zeros(M,N,W);
    
  %   fk=mod(floor(tgrad),M)+1;
  %   ck=mod(ceil(tgrad),M)+1;
  %   fn=mod(floor(fgrad),N)+1;
  %   cn=mod(ceil(fgrad),N)+1;
    
  %   alpha = fgrad-floor(fgrad);
  %   beta  = tgrad-floor(tgrad);
  %   m1 =(1-alpha).*(1-beta).*s;
  %   m2 =(1-alpha).*beta.*s;
  %   m3 =alpha.*(1-beta).*s;
  %   m4 =alpha.*beta.*s;
  %   for ii=1:M
  %     for jj=1:N
  %       sr(fk(ii,jj),fn(ii,jj))=sr(fk(ii,jj),fn(ii,jj))+m1(ii,jj);
  %       sr(ck(ii,jj),fn(ii,jj))=sr(ck(ii,jj),fn(ii,jj))+m2(ii,jj);
  %       sr(fk(ii,jj),cn(ii,jj))=sr(fk(ii,jj),cn(ii,jj))+m3(ii,jj);
  %       sr(ck(ii,jj),cn(ii,jj))=sr(ck(ii,jj),cn(ii,jj))+m4(ii,jj);
        
  %     end;
  %   end;
  % end;

