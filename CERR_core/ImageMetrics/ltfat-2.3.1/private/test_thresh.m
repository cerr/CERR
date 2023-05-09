function test_failed=test_thresh
%-*- texinfo -*-
%@deftypefn {Function} test_thresh
%@verbatim
%TEST_THRESH  Compare sparse and full thesholding
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_thresh.html}
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
disp(' ===============  TEST_THRESH ================');
global LTFAT_TEST_TYPE;
if ~strcmpi(LTFAT_TEST_TYPE,'double')
   disp(sprintf('Skipping. Cannot work with sparse matrices of type %s.',LTFAT_TEST_TYPE));
   return;
end

lambda=0.1;

ttypes={'hard','soft','wiener'};

for ii=1:2
  
  if ii==1
    g=tester_rand(3,4);
    field='REAL  ';
    g(2,2)=lambda;
  else
    g=tester_crand(3,4);
    field='CMPLX ';
    g(2,2)=lambda;
  end;
  
  for jj=1:3
    ttype=ttypes{jj};
    
    [xo_full, Nfull] = thresh(g,lambda,ttype,'full');
    [xo_sparse, Nsp] = thresh(g,lambda,ttype,'sparse');
    
    res = xo_full-xo_sparse;
    res = norm(res(:));
    
    res2 = Nfull-Nsp;
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['THRESH   %s %s %0.5g %s'],field,ttype,res,fail);
    disp(s);      
    
    [test_failed,fail]=ltfatdiditfail(res2,test_failed);
    s=sprintf(['THRESH N %s %s %0.5g %s'],field,ttype,res2,fail);      
    disp(s);
    
    % Extend lambda to:
    % a) Vector
    lambdavec = lambda*ones(numel(g),1);
    
    [xo_full2, Nfull2] = thresh(g,lambdavec,ttype,'full');
    [xo_sparse2, Nsp2] = thresh(g,lambdavec,ttype,'sparse');
    
    res_full = xo_full2-xo_full;
    res_sparse = xo_sparse2-xo_sparse;
    res_full = norm(res_full(:));
    res_sparse = norm(res_sparse(:));
    
    res_nfull = Nfull2-Nfull;
    res_nsparse = Nfull2-Nfull;
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['THRESH VEC FULL  %s %s %0.5g %s'],field,ttype,res_full,fail);
    disp(s);     
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['THRESH VEC SPARSE  %s %s %0.5g %s'],field,ttype,res_sparse,fail);
    disp(s); 
    
    [test_failed,fail]=ltfatdiditfail(res2,test_failed);
    s=sprintf(['THRESH VEC N FULL %s %s %0.5g %s'],field,ttype,res_nfull,fail);      
    disp(s);

    [test_failed,fail]=ltfatdiditfail(res2,test_failed);
    s=sprintf(['THRESH VEC N SPARSE %s %s %0.5g %s'],field,ttype,res_nsparse,fail);      
    disp(s);
    
    % b) Same shape as g 
    lambdamat = lambda*ones(size(g));
    
    [xo_full3, Nfull3] = thresh(g,lambdamat,ttype,'full');
    [xo_sparse3, Nsp3] = thresh(g,lambdamat,ttype,'sparse');
    
    res_full = xo_full3-xo_full;
    res_sparse = xo_sparse3-xo_sparse;
    res_full = norm(res_full(:));
    res_sparse = norm(res_sparse(:));
    
    res_nfull = Nfull3-Nfull;
    res_nsparse = Nfull3-Nfull;
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['THRESH MAT FULL  %s %s %0.5g %s'],field,ttype,res_full,fail);
    disp(s);   

    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['THRESH MAT SPARSE %s %s %0.5g %s'],field,ttype,res_sparse,fail);
    disp(s); 
    
    [test_failed,fail]=ltfatdiditfail(res2,test_failed);
    s=sprintf(['THRESH MAT N FULL %s %s %0.5g %s'],field,ttype,res_nfull,fail);      
    disp(s);
    
     [test_failed,fail]=ltfatdiditfail(res2,test_failed);
    s=sprintf(['THRESH MAT N SPARSE %s %s %0.5g %s'],field,ttype,res_nsparse,fail);      
    disp(s);
    
    
  end;
  
end;


