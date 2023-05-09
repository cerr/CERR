function test_failed=test_nsdgt()
%-*- texinfo -*-
%@deftypefn {Function} test_nsdgt
%@verbatim
%TEST_NSDGT Simple test of nsdgt and associated functions
%  Usage: test_nsdgt()
% 
%  This function checks the exact reconstruction (up to numeric precision)
%  of the functions nsdgt and insdgt, when using dual windows computed with
%  nsgabdual, or tight windows computed with nsgabtight.
%
%  This test is done on a single short random signal, for only one given set
%  of windows.
%  A more systematic testing would be required for a complete validation of
%  these functions (in particular for inclusion of the functions in LTFAT)
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_nsdgt.html}
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

%  Author: Florent Jaillet, 2009-05

test_failed=0;

disp(' ===============  TEST_NSDGT ================');
% First case is even numbers, painless
% Second case is even numbers, non-painless
% Third case has odd numbers, painless
% Fouth case has odd numbers, non-painless
% Fifth case is even numbers, painless, window length less than M

ar ={[20,30,40],[20,30,40],[5,11,19],[5,11,19],[20,30,40]};
Mr ={[30,40,50],[30,40,50],[7,12,29],[7,12,29],[35,40,50]};
Lgr={[30,40,50],[60,80,60],[7,12,29],[9,19,33],[30,40,50]};

for tc=1:numel(ar)
    N=numel(ar{tc});
    M=Mr{tc};
    a=ar{tc};
    Lg=Lgr{tc};
    L=sum(a);


    g=cell(N,1);
    
    for ii=1:N
        g{ii}=randn(Lg(ii),1);
    end;

    % ----- non-uniform dual and inversion -----

    ispainless=all(cellfun(@length,g)<=M.');


    if ispainless
        gd=nsgabdual(g,a,M);
        gt=nsgabtight(g,a,M);
    end;

    for W=1:3
        
        f=randn(L,W);
        c=nsdgt(f,g,a,M);
        
        % ----- reference ---------------------
        
        c_ref=ref_nsdgt(f,g,a,M);
        
        res=sum(cellfun(@(x,y) norm(x-y,'fro'),c,c_ref));
        
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
        fprintf(['NSDGT REF  tc:%3i W:%3i %0.5g %s\n'],tc,W,res,fail);
        
        
        % ----- reference inverse ---------------
        
        f_syn=insdgt(c,g,a);
        
        f_ref=ref_insdgt(c,g,a,M);

        res=norm(f_ref-f_syn,'fro');
        
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
        fprintf(['NSDGT INV REF tc:%3i W:%3i %0.5g %s\n'],tc,W,res,fail);



        % ----- inversion ---------------------
        
        if ispainless
            
            r=insdgt(c,gd,a);
            res=norm(f-r);
            
            [test_failed,fail]=ltfatdiditfail(res,test_failed);
            fprintf(['NSDGT DUAL tc:%3i W:%3i %0.5g %s\n'],tc,W,res,fail);

            % ----- tight and inversion -----------------

            ct=nsdgt(f,gt,a,M);
            rt=insdgt(ct,gt,a);
            
            res=norm(f-rt);
            
            [test_failed,fail]=ltfatdiditfail(res,test_failed);
            fprintf(['NSDGT TIGHT tc:%3i %0.5g %s\n'],tc,res,fail);            
            
            % ----- non-uniform inversion, real -----
            
            c=nsdgtreal(f,g,a,M);
            r=insdgtreal(c,gd,a,M);
            
            res=norm(f-r);
            
            [test_failed,fail]=ltfatdiditfail(res,test_failed);
            fprintf(['NSDGTREAL DUAL  tc:%3i %0.5g %s\n'],tc,res,fail);
            
        end;

    end;

end;



ar ={[25,30,45],[25,30,45]};
Mr =[50,50];
Lgr={[50,50,50],[40,50,60]};

% Second test is disabled, it does not work yet.
for tc=1:1 %numel(ar)
    N=numel(ar{tc});
    M=Mr(tc);
    a=ar{tc};
    Lg=Lgr{tc};
    L=sum(a);

    g=cell(N,1);
    
    for ii=1:N
        g{ii}=randn(Lg(ii),1);
    end;

    gd=nsgabdual(g,a,M);
    gt=nsgabtight(g,a,M);

    for W=1:3
        
        L=sum(a);
        
        f=randn(L,1);
        
        
        % ----- uniform dual and inversion -----
            
        c=unsdgt(f,g,a,M);
        r=insdgt(c,gd,a);
        
        res=norm(f-r);
        
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
        fprintf(['UNSDGT DUAL tc:%3i W:%3i %0.5g %s\n'],tc,W,res,fail);
        
        % ----- uniform inversion, real -----
        
        cr=unsdgtreal(f,g,a,M);
        r=insdgtreal(cr,gd,a,M);
        
        res=norm(f-r);
        
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
        fprintf(['UNSDGTREAL DUAL tc:%3i W:%3i %0.5g %s\n'],tc,W,res,fail);
        
                
        % ----- uniform tight and inversion -----------------
        
        ct=unsdgt(f,gt,a,M);
        rt=insdgt(ct,gt,a);
        
        res=norm(f-rt);
        
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
        fprintf(['UNSDGT TIGHT tc:%3i W:%3i %0.5g %s\n'],tc,W,res,fail);
        
        % ----- framebounds -----------------
        if 0
            FB=nsgabframebounds(gt,a,M);
            
            res=norm(FB-1);
            
            [test_failed,fail]=ltfatdiditfail(res,test_failed);
            fprintf(['UNSDGT FRAMEBOUNDS tc:%3i %0.5g %s\n'],tc,res,fail);
        end;
        
    end;
end;
        
% ------ Reference DGT ----------------------
        
        if 0
a1=3;
M1=4;
N=8;
a=a1*ones(1,N);
M=M1*ones(1,N);
L=a1*N;
f=tester_crand(L,1);
g1=tester_crand(L,1);
for ii=1:N
  g{ii}=g1;
end;

c     = nsdgt(f,g,a,M);
c_ref = dgt(f,g1,a1,M1,'timeinv');

res=norm(reshape(cell2mat(c),M1,N)-c_ref,'fro');

[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['NSDGT REF %0.5g %s\n'],res,fail);
end;

