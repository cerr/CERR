function test_failed=test_gabmulappr
%-*- texinfo -*-
%@deftypefn {Function} test_gabmulappr
%@verbatim
%TEST_GABMULAPPR
%
%  This script runs a thorough test of the GABMULAPPR routine, comparting
%  it to a reference implementation, using canonical tight Gaussian
%  window, random complex window for both analysis and synthesis, and
%  using two different randowm complex windows.
%
%  Secondly, the script calculates the best approximation by a Gabor
%  multiplier to a Gabor multiplier using the same window.
%
%  The script tests TFMAT and GABMULAPPR.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_gabmulappr.html}
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
Lr=[24,16,36];
ar=[ 4, 4, 4];
Mr=[ 6, 8, 9];

test_failed=0;

disp(' ===============  TEST_GABMULAPPR =========');

for ii=1:length(Lr);

  L=Lr(ii);
  
  M=Mr(ii);
  a=ar(ii);

  N=L/a;
  
  % Random matrix
  T=tester_crand(L,L);
  
  % Random multiplier symbol.
  sym=tester_crand(M,N);
  
  % ---- Reference test, tight Gaussian window ------------
  
  sym1=ref_gabmulappr(T,a,M);
  sym2=gabmulappr(T,a,M);
  
  res=norm(sym1-sym2,'fro');
  [test_failed,fail]=ltfatdiditfail(res,test_failed);          
  s=sprintf('REF GAUSS L:%3i a:%3i M:%3i %0.5g',L,a,M,res);
  disp(s)
  
  % ---- Reconstruction test, tight Gaussian window ------------
  Tr = gabmulmatrix(frame('dgt',gabtight(a,M,L),a,M),sym);   
  %Tr=tfmat('gabmul',sym,a);
  symnew=gabmulappr(Tr,a,M);
  
  res=norm(sym-symnew,'fro');
  [test_failed,fail]=ltfatdiditfail(res,test_failed);          
  s=sprintf('REC GAUSS L:%3i a:%3i M:%3i %0.5g',L,a,M,res);
  disp(s)

  
  % ---- Reference test, same window for analysis and synthesis ------------
  
  g=tester_crand(L,1);
  
  sym1=ref_gabmulappr(T,g,a,M);
  sym2=gabmulappr(T,g,a,M);
  
  res=norm(sym1-sym2,'fro');
  
  [test_failed,fail]=ltfatdiditfail(res,test_failed);
  % if res>10e-10
    % disp('FAILED');
    % test_failed=test_failed+1;
  % end;
      
  s=sprintf('REF 1 WIN L:%3i a:%3i M:%3i %0.5g',L,a,M,res);
  disp(s)

  % ---- Reconstruction test, same window for analysis and synthesis ------------
  Tr = gabmulmatrix(frame('dgt',g,a,M),sym);
  %Tr=tfmat('gabmul',sym,g,a);
  symnew=gabmulappr(Tr,g,a,M);
  
  res=norm(sym-symnew,'fro');
  [test_failed,fail]=ltfatdiditfail(res,test_failed);          
  s=sprintf('REC 1 WIN L:%3i a:%3i M:%3i %0.5g',L,a,M,res);
  disp(s)

  % ---- Reference test, two different windows for analysis and synthesis ------------
    
  ga=tester_crand(L,1);
  gs=tester_crand(L,1);

  sym1=ref_gabmulappr(T,ga,gs,a,M);
  sym2=gabmulappr(T,ga,gs,a,M);

  res=norm(sym1-sym2,'fro');
  [test_failed,fail]=ltfatdiditfail(res,test_failed);          
  s=sprintf('REF 2 WIN L:%3i a:%3i M:%3i %0.5g',L,a,M,res);
  disp(s) 

  % ---- Reconstruction test, two different windows for analysis and synthesis ---------
  Tr = gabmulmatrix2(frame('dgt',ga,a,M),frame('dgt',gs,a,M),sym);     
  %Tr=tfmat('gabmul',sym,ga,gs,a);
  symnew=gabmulappr(Tr,ga,gs,a,M);
  
  res=norm(sym-symnew,'fro');
  [test_failed,fail]=ltfatdiditfail(res,test_failed);          
  s=sprintf('REC 2 WIN L:%3i a:%3i M:%3i %0.5g %s',L,a,M,res,fail);
  disp(s)


  
end;


function T = gabmulmatrix(F,sym)

T = operatormatrix(operatornew('framemul',F,F,framenative2coef(F,sym)));

function T = gabmulmatrix2(Fa,Fs,sym)

T = operatormatrix(operatornew('framemul',Fa,Fs,framenative2coef(Fs,sym)));

