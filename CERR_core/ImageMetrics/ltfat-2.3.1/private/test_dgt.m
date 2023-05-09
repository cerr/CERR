function test_failed=test_dgt
%-*- texinfo -*-
%@deftypefn {Function} test_dgt
%@verbatim
%TEST_DGT  Test DGT
%
%  This script runs a throrough test of the DGT routine,
%  testing it on a range of input parameters.
%
%  The computational backend is tested this way, but the
%  interface is not.
%
%  The script tests dgt, idgt, gabdual and gabtight.
%
%  Use TEST_WFAC and TEST_DGT_FAC for more specific testing
%  of the DGT backend.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dgt.html}
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
      
Lr=[24,16,144,108,144,24,135,35,77,20];
ar=[ 4, 4,  9,  9, 12, 6,  9, 5, 7, 1];
Mr=[ 6, 8, 16, 12, 24, 8,  9, 7,11,20];

test_failed=0;

disp(' ===============  TEST_DGT ================');

disp('--- Used subroutines ---');

which comp_wfac
which comp_iwfac
which comp_sepdgt
which comp_isepdgt
which comp_sepdgtreal
which comp_isepdgtreal
which comp_gabdual_long
which comp_gabtight_long


for ii=1:length(Lr);

  L=Lr(ii);
  
  M=Mr(ii);
  a=ar(ii);
  
  b=L/M;
  N=L/a;
  c=gcd(a,M);
  d=gcd(b,N);
  p=a/c;
  q=M/c;
  

  for rtype=1:2
      
    if rtype==1
      rname='REAL ';	
      g=tester_rand(L,1);
    else
      rname='CMPLX';	
      g=tester_crand(L,1);
    end;
 
    global LTFAT_TEST_TYPE;
    if strcmpi(LTFAT_TEST_TYPE,'single')
        C = gabframebounds(g,a,M);
        while C>1e3
%             warning(sprintf(['The frame is too badly conditioned '...
%                              'for single precision. Cond. num. %d. '...
%                              ' Trying again.'],C));
                         
                         if rtype==1
                             rname='REAL ';
                             g=tester_rand(L,1);
                         else
                             rname='CMPLX';
                             g=tester_crand(L,1);
                         end;
                         C = gabframebounds(g,a,M);
        end
    end
    
    
    gd=gabdual(g,a,M);
    gt=gabtight(g,a,M);
    
    % --- Test windows against their reference implementations. ---
    
    ref_gd=ref_gabdual(g,a,M);
    res=norm(ref_gd-gd);
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    fprintf(['REFDUAL %s L:%3i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i '...
               '%0.5g %s\n'],rname,L,a,b,c,d,p,q,res,fail);

    ref_gt=ref_gabtight(g,a,M);
    res=norm(ref_gt-gt);
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['REFTIGHT %s L:%3i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i '...
               '%0.5g %s'],rname,L,a,b,c,d,p,q,res,fail);    
    disp(s);

    % ---- Test gabdualnorm --------------------------------------
    res=gabdualnorm(g,gd,a,M);
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['DUALNORM1 %s L:%3i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i '...
               '%0.5g %s'],rname,L,a,b,c,d,p,q,res,fail);    
    disp(s);

    [o1,o2]=gabdualnorm(g,gd,a,M);
    res=o1-1+o2;
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['DUALNORM2 %s L:%3i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i '...
               '%0.5g %s'],rname,L,a,b,c,d,p,q,res,fail);    
    disp(s);

    for W=1:3
          
      if rtype==1
        f=tester_rand(L,W);
      else
        f=tester_crand(L,W);
      end;

      
      % --- Test DGT against its reference implementation. ---
      
      cc=dgt(f,g,a,M);  
      cc2=ref_dgt(f,g,a,M);
      
      cdiff=cc-cast(cc2,class(cc));
      res=norm(cdiff(:));      
      [test_failed,fail]=ltfatdiditfail(res,test_failed);
      s=sprintf(['REF %s L:%3i W:%2i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i '...
                 '%0.5g %s'],rname,L,W,a,b,c,d,p,q,res,fail);
      disp(s)
      
      % --- Test reconstruction of IDGT using a canonical dual window. ---
      
      r=idgt(cc,gd,a);  
      res=norm(f-r,'fro');
      [test_failed,fail]=ltfatdiditfail(res,test_failed);
      s=sprintf(['REC %s L:%3i W:%2i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i ' ...
                 '%0.5g %s'],rname,L,W,a,b,c,d,p,q,res,fail);
      disp(s)
      
      % --- Test reconstruction of IDGT using a canonical tight window. ---
      
      res=norm(f-idgt(dgt(f,gt,a,M),gt,a),'fro');
      [test_failed,fail]=ltfatdiditfail(res,test_failed);
      s=sprintf(['TIG %s L:%3i W:%2i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i ' ...
                 '%0.5g %s'],rname,L,W,a,b,c,d,p,q,res,fail);
      disp(s);
      
      % Test the real valued transform
      if rtype==1
        
        % --- Reference test ---
        ccreal=dgtreal(f,g,a,M);
        M2=floor(M/2)+1;
        
        cdiff=cc(1:M2,:,:)-ccreal;
        res=norm(cdiff(:));
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
        s=sprintf(['REFREAL   L:%3i W:%2i a:%3i b:%3i c:%3i d:%3i p:%3i ' ...
                   'q:%3i %0.5g %s'],L,W,a,b,c,d,p,q,res,fail);
        disp(s);
        
        % --- Reconstruction test ---
        
        rreal=idgtreal(ccreal,gd,a,M);
        
        res=norm(f-rreal,'fro');
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
        s=sprintf(['RECREAL   L:%3i W:%2i a:%3i b:%3i c:%3i d:%3i p:%3i ' ...
                   'q:%3i %0.5g %s'],L,W,a,b,c,d,p,q,res,fail);
        disp(s)
        
      end;
    end;

  end;  

end;


