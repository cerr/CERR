function test_failed=test_nonsepdgt
%-*- texinfo -*-
%@deftypefn {Function} test_nonsepdgt
%@verbatim
%TEST_NONSEPDGT  Test non-separable DGT
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
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_nonsepdgt.html}
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

Lr =[24,24,30,36,36,48,72];
ar =[ 4, 4, 3, 4, 4, 4, 4];
Mr =[ 6, 6, 5, 6, 6, 6, 6];
lt1=[ 0, 1, 1, 1, 2, 1, 1];
lt2=[ 1, 2, 2, 3, 3, 4, 2];
    
test_failed=0;
testmode=0;

disp(' ===============  TEST_NONSEPDGT ================');

disp('--- Used subroutines ---');

which comp_nonsepdgt_multi
which comp_nonsepdgt_shear
which comp_nonsepwin2multi

for ii=1:length(Lr);

  L=Lr(ii);
  
  M=Mr(ii);
  a=ar(ii);
  lt=[lt1(ii), lt2(ii)];
  
  b=L/M;
  N=L/a;
  c=gcd(a,M);
  d=gcd(b,N);
  p=a/c;
  q=M/c;
  
  for gtype=1:2
      if gtype==1
          Lw=L;
      else
          Lw=M;
      end;
      
      for rtype=1:2
          
          if rtype==1
              rname='REAL';
              g=tester_rand(Lw,1);
          else
              rname='CMPLX';	
              g=tester_crand(Lw,1);
          end;
                    
          gd=gabdual(g,a,M,'lt',lt);
          gd_multi=gabdual(g,a,M,'lt',lt,'nsalg',1);
          gd_shear=gabdual(g,a,M,'lt',lt,'nsalg',2);

          gt=gabtight(g,a,M,'lt',lt);
          gt_multi=gabtight(g,a,M,'lt',lt,'nsalg',1);
          gt_shear=gabtight(g,a,M,'lt',lt,'nsalg',2);

          % For testing, we need to call some computational subroutines directly.
          gsafe=fir2long(g,L);
          gdsafe=fir2long(gd,L);

          
          for W=1:3
              
              if rtype==1
                  f=tester_rand(L,W);
              else
                  f=tester_crand(L,W);
              end;      
              
              % --------- test reference comparison ------------
              
              cc = dgt(f,g,a,M,'lt',lt);
              
              cc_ref = ref_nonsepdgt(f,g,a,M,lt);
              
              res = norm(cc(:)-cc_ref(:))/norm(cc(:));
              stext=sprintf(['REF   %s L:%3i W:%2i LW:%3i a:%3i M:%3i lt1:%2i lt2:%2i' ...
                         ' %0.5g'], rname,L,W,Lw,a,M,lt(1),lt(2),res);
              test_failed=ltfatchecktest(res,stext,test_failed,testmode);
              
              % --------- test multiwindow ---------------------
              
              cc = comp_dgt(f,gsafe,a,M,lt,0,0,1);
              
              res = norm(cc(:)-cc_ref(:))/norm(cc(:));
              stext=sprintf('DGT MULTIW %s L:%3i W:%2i LW:%3i a:%3i M:%3i lt1:%2i lt2:%2i %0.5g ',...
                            rname,L,W,Lw,a,M,lt(1),lt(2),res);
              test_failed=ltfatchecktest(res,stext,test_failed,testmode);
              
              
              % --------- test shear DGT -------------------------------
              
              cc = comp_dgt(f,gsafe,a,M,lt,0,0,2);
              
              res = norm(cc(:)-cc_ref(:))/norm(cc(:));
              stext=sprintf(['DGT SHEAR   %s L:%3i W:%2i LW:%3i a:%3i ' ...
                             'M:%3i lt1:%2i lt2:%2i %0.5g'], rname,L,W, ...
                            Lw,a,M,lt(1),lt(2),res);
              test_failed=ltfatchecktest(res,stext,test_failed,testmode);
              
              % -------- test reconstruction using canonical dual -------
              
              r=idgt(cc,gd,a,'lt',lt);
              res=norm(f-r,'fro')/norm(f,'fro');
              
              stext=sprintf(['REC D %s L:%3i W:%2i LW:%3i a:%3i M:%3i ' ...
                             'lt1:%2i lt2:%2i %0.5g'], rname,L,W,Lw,a,M, ...
                            lt(1),lt(2),res);
              test_failed=ltfatchecktest(res,stext,test_failed,testmode);
              
              % -------- test reconstruction using canonical dual, multiwin algorithm -------
              
              r=comp_idgt(cc,gdsafe,a,lt,0,1);  
              res=norm(f-r,'fro')/norm(f,'fro');
              
              stext=sprintf(['REC MULTIW D %s L:%3i W:%2i LW:%3i a:%3i ' ...
                             'M:%3i lt1:%2i lt2:%2i %0.5g ' ], rname,L,W, ...
                            Lw,a,M,lt(1),lt(2),res);
              test_failed=ltfatchecktest(res,stext,test_failed,testmode);
              
              % -------- test reconstruction using canonical dual, shear algorithm -------
              
              r=comp_idgt(cc,gdsafe,a,lt,0,2);  
              res=norm(f-r,'fro')/norm(f,'fro');
              
              stext=sprintf(['REC SHEAR D %s L:%3i W:%2i LW:%3i a:%3i ' ...
                             'M:%3i lt1:%2i lt2:%2i %0.5g ' ], rname,L,W, ...
                            Lw,a,M,lt(1),lt(2),res);
              test_failed=ltfatchecktest(res,stext,test_failed,testmode);
              
              
              % -------- test reconstruction using canonical tight -------
              
              cc_t = dgt(f,gt,a,M,'lt',lt);
              r=idgt(cc_t,gt,a,'lt',lt);  
              res=norm(f-r,'fro')/norm(f,'fro');
              
              stext=sprintf(['REC T %s L:%3i W:%2i LW:%3i a:%3i M:%3i ' ...
                             'lt1:%2i lt2:%2i %0.5g ' ], rname,L,W,Lw,a, ...
                            M,lt(1),lt(2),res);
              test_failed=ltfatchecktest(res,stext,test_failed,testmode);

              % -------- test dgtreal-----------------------
              
              if (rtype==1) && (lt(2)<=2)
                  M2=floor(M/2)+1;
                  
                  cc_r = dgtreal(f,g,a,M,'lt',lt);
                  res=cc_r-cc(1:M2,:,:);
                  res=norm(res(:))/norm(cc_r(:));;

                  stext=sprintf(['REFREAL L:%3i W:%2i LW:%3i a:%3i ' ...
                                 'M:%3i lt1:%2i lt2:%2i %0.5g' ], ...
                                L,W,Lw,a,M,lt(1),lt(2),res);
                  test_failed=ltfatchecktest(res,stext,test_failed,testmode);
                  
                  
                  r_real = idgtreal(cc_r,gd,a,M,'lt',lt);
                  
                  res=norm(f-r_real,'fro')/norm(f,'fro');
                  
                  stext=sprintf(['RECREAL L:%3i W:%2i LW:%3i a:%3i ' ...
                                 'M:%3i lt1:%2i lt2:%2i %0.5g '], ...
                                L,W,Lw,a,M,lt(1),lt(2),res);
                  test_failed=ltfatchecktest(res,stext,test_failed,testmode);
                  
              end;
              
              
          end;
          
          % -------- test frame bounds for tight frame -------
          
          B=gabframebounds(gt,a,M,'lt',lt);
          res=B-1;
          stext=sprintf(['FRB   %s L:%3i LW:%3i a:%3i M:%3i lt1:%2i lt2:%2i ' ...
          '%0.5g'], rname,L,Lw,a,M,lt(1),lt(2),res);
          test_failed=ltfatchecktest(res,stext,test_failed,testmode);
          
          % -------- test multiwin dual -------
          
          res=norm(gd-gd_multi)/norm(g);
          stext=sprintf(['DUAL MULTI  %s L:%3i LW:%3i a:%3i M:%3i lt1:%2i ' ...
                         'lt2:%2i %0.5g' ], rname,L,Lw,a,M,lt(1),lt(2),res);
          test_failed=ltfatchecktest(res,stext,test_failed,testmode);
          
          % -------- test shear dual -------
          
          res=norm(gd-gd_shear)/norm(g);
          stext=sprintf(['DUAL SHEAR  %s L:%3i LW:%3i a:%3i M:%3i lt1:%2i ' ...
                         'lt2:%2i %0.5g'], rname,L,Lw,a,M,lt(1),lt(2),res);
          test_failed=ltfatchecktest(res,stext,test_failed,testmode);
          
          % -------- test shear tight -------
          
          res=norm(gt-gt_multi)/norm(g);
          stext=sprintf(['TIGHT MULTI %s L:%3i LW:%3i a:%3i M:%3i lt1:%2i ' ...
                         'lt2:%2i %0.5g' ], rname,L,Lw,a,M,lt(1),lt(2),res);
          test_failed=ltfatchecktest(res,stext,test_failed,testmode);

          % -------- test shear tight -------
          
          res=norm(gt-gt_shear)/norm(g);
          stext=sprintf(['TIGHT SHEAR %s L:%3i LW:%3i a:%3i M:%3i lt1:%2i ' ...
                         'lt2:%2i %0.5g' ], rname,L,Lw,a,M,lt(1),lt(2),res);
          test_failed=ltfatchecktest(res,stext,test_failed,testmode);

          % ---- Test gabdualnorm --------------------------------------
          res=gabdualnorm(g,gd,a,M,'lt',lt);
          stext=sprintf(['DUALNORM1 %s L:%3i LW:%3i a:%3i M:%3i lt1:%2i ' ...
                         'lt2:%2i %0.5g' ], rname,L,Lw,a,M,lt(1),lt(2),res);
          test_failed=ltfatchecktest(res,stext,test_failed,testmode);
          
          [o1,o2]=gabdualnorm(g,gd,a,M,'lt',lt);
          res=o1-1+o2;
          stext=sprintf(['DUALNORM2 %s L:%3i LW:%3i a:%3i M:%3i lt1:%2i ' ...
                         'lt2:%2i %0.5g' ], rname,L,Lw,a,M,lt(1),lt(2),res);
          test_failed=ltfatchecktest(res,stext,test_failed,testmode);


          
      end;  
      
  end;

end;


