function [AF,BF]=filterbankrealbounds(g,a,L);
%-*- texinfo -*-
%@deftypefn {Function} filterbankrealbounds
%@verbatim
%FILTERBANKREALBOUNDS  Frame bounds of filter bank for real signals only
%   Usage: fcond=filterbankrealbounds(g,a,L);
%          [A,B]=filterbankrealbounds(g,a,L);
%          [...]=filterbankrealbounds(g,a);
%
%   FILTERBANKREALBOUNDS(g,a,L) calculates the ratio B/A of the frame
%   bounds of the filterbank specified by g and a for a system of length
%   L. The ratio is a measure of the stability of the system.  Use this
%   function on the common construction where the filters in g only covers
%   the positive frequencies.
%
%   FILTERBANKREALBOUNDS(g,a) does the same, but the filters must be FIR
%   filters, as the transform length is unspecified. L will be set to 
%   next suitable length equal or bigger than the longest impulse response
%   such that L=filterbanklength(gl_longest,a).
%
%   [A,B]=FILTERBANKREALBOUNDS(g,a) returns the lower and upper frame
%   bounds explicitly.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbankrealbounds.html}
%@seealso{filterbank, filterbankdual}
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
  
complainif_notenoughargs(nargin,2,'FILTERBANKREALBOUNDS');
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

if L~=filterbanklength(L,asan)
    error(['%s: Specified length L is incompatible with the length of ' ...
           'the time shifts.'],upper(mfilename));
end;

AF=Inf;
BF=0;

% Prioritize painless over uniform algorithm
if info.isuniform && info.ispainless
    info.isuniform = 0;
end
  
if info.isuniform
  % Uniform filterbank, use polyphase representation
  a=a(1);
  
  N=L/a;

  % G1 is done this way just so that we can determine the data type.
  G1=comp_transferfunction(g{1},L);
  thisclass=assert_classname(G1);
  G=zeros(L,M,thisclass);
  G(:,1)=G1;
  for ii=2:M
    G(:,ii)=cast(comp_transferfunction(g{ii},L),thisclass);
  end;
  
  Ha=zeros(a,M,thisclass);
  Hb=zeros(a,M,thisclass);
  
  for w=0:N-1
    idx_a = mod(w-(0:a-1)*N,L)+1;
    idx_b = mod((0:a-1)*N-w,L)+1;
    Ha = G(idx_a,:);
    Hb = conj(G(idx_b,:));
    
    % A 'real' is needed here, because the matrices are known to be
    % Hermitian, but sometimes Matlab/Octave does not recognize this.  
    work=real(eig(real(Ha*Ha'+Hb*Hb')));
    
    AF=min(AF,min(work));
    BF=max(BF,max(work));
    
  end;
  
  AF=AF/a;
  BF=BF/a;
  
else
    if info.ispainless
        % Compute the diagonal of the frame operator.
        f=comp_filterbankresponse(g,asan,L,1);
        
        AF=min(f);
        BF=max(f);
    else
        error(['%s: There is no fast method to find the frame bounds of ' ...
               'this filterbank as it is neither uniform nor painless. ' ...
               'Please see FRAMEBOUNDS for an iterative method that can ' ...
               'solve the problem.'],upper(mfilename));                        
    end;        
end;

if nargout<2
  % Avoid the potential warning about division by zero.
  if AF==0
    AF=Inf;
  else
    AF=BF/AF;
  end;
end;
  


