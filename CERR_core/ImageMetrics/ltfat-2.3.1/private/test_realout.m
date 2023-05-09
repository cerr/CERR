function test_failed=test_realout
%-*- texinfo -*-
%@deftypefn {Function} test_realout
%@verbatim
%TEST_REALOUT  Test if functions produce real-valued output
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_realout.html}
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
  
  test_failed=0;
  
  disp(' ===============  TEST_REALOUT ================');

  a = 7;
  M = 19;
  W = 3;
  L = a*M*4;
  Nwil = L/(2*M);
  Nmd  = L/M;
  Ngab = L/a;
  
  Nfft = 19;
  
  test_failed=realhelper(test_failed,'dwilt',randn(L,W),randn(L,1),M);
  test_failed=realhelper(test_failed,'dwilt',randn(L,W),randn(2*M,1),M);
  
  test_failed=realhelper(test_failed,'wmdct',randn(L,W),randn(L,1),M);
  test_failed=realhelper(test_failed,'wmdct',randn(L,W),randn(2*M,1),M);
        
  test_failed=realhelper(test_failed,'idwilt',randn(2*M,Nwil),randn(L,1));
  test_failed=realhelper(test_failed,'idwilt',randn(2*M,Nwil),randn(2*M,1));

  test_failed=realhelper(test_failed,'iwmdct',randn(M,Nmd),randn(L,1));
  test_failed=realhelper(test_failed,'iwmdct',randn(M,Nmd),randn(2*M,1));
  
  test_failed=realhelper(test_failed,'gabdual',randn(L,1),a,M);
  test_failed=realhelper(test_failed,'gabdual',randn(L,1),a,M);
  test_failed=realhelper(test_failed,'gabtight',randn(M,1),a,M);
  test_failed=realhelper(test_failed,'gabtight',randn(M,1),a,M);
  
  test_failed=realhelper(test_failed,'dcti',randn(Nfft,1));
  test_failed=realhelper(test_failed,'dctii',randn(Nfft,1));
  test_failed=realhelper(test_failed,'dctiii',randn(Nfft,1));
  test_failed=realhelper(test_failed,'dctiv',randn(Nfft,1));
  test_failed=realhelper(test_failed,'dsti',randn(Nfft,1));
  test_failed=realhelper(test_failed,'dstii',randn(Nfft,1));
  test_failed=realhelper(test_failed,'dstiii',randn(Nfft,1));
  test_failed=realhelper(test_failed,'dstiv',randn(Nfft,1));

  test_failed=realhelper(test_failed,'pfilt',randn(L,1),randn(L,1));

  c=dgtreal(randn(L,W),randn(L,1),a,M);
  test_failed=realhelper(test_failed,'idgtreal',c,randn(L,1),a,M);
  test_failed=realhelper(test_failed,'idgtreal',c,randn(M,1),a,M);

  c=fftreal(randn(Nfft,1));
  test_failed=realhelper(test_failed,'ifftreal',c,Nfft);


  
  
  
  
  
  
  
function test_failed=realhelper(test_failed,funname,varargin)
  
  outres=feval(funname,varargin{:});
  res=~isreal(outres);
  
  if res>0
      outres
  end;
  [test_failed,fail]=ltfatdiditfail(res,test_failed);

  fprintf('REAL %s %i %s\n',funname,res,fail);



