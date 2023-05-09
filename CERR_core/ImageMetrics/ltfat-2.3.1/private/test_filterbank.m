function test_failed=test_filterbank
%-*- texinfo -*-
%@deftypefn {Function} test_filterbank
%@verbatim
%TEST_FILTERBANK test the filterbank codes
%  Usage: test_filterbank()
%
%  This function checks the exact reconstruction (up to numeric precision)
%  of the functions ufilterbank and ifilterbank, when using dual windows computed with
%  filterbankdual / filterbankrealdual, or tight windows computed with
%  filterbanktight / filterbankrealtight
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_filterbank.html}
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

disp(' ===============  TEST_FILTERBANK ================');

which comp_filterbank_td
which comp_filterbank_fft
which comp_filterbank
which comp_ifilterbank_td
which comp_ifilterbank_fft
which comp_ifilterbank

M=6;
a=3;
N=4;

L=a*N;

g=cell(1,M);
for ii=1:M
  g{ii}=tester_crand(L,1);
end;

gd = filterbankdual(g,a,L);
gt = filterbanktight(g,a,L);
gtreal=filterbankrealtight(g,a,L);

%% Check that filterbankbounds detect the tight frame
[AF,BF]=filterbankbounds(gt,a,L);

[test_failed,fail]=ltfatdiditfail(BF-1,test_failed);
s=sprintf(['FB FB B   %0.5g %s'],BF-1,fail);
disp(s)

[test_failed,fail]=ltfatdiditfail(AF-1,test_failed);
s=sprintf(['FB FB A   %0.5g %s'],AF-1,fail);
disp(s)

%% check filterbankrealbounds

[AF,BF]=filterbankrealbounds(gtreal,a,L);

[test_failed,fail]=ltfatdiditfail(BF-1,test_failed);
s=sprintf(['FB FBR B  %0.5g %s'],BF-1,fail);
disp(s)

[test_failed,fail]=ltfatdiditfail(AF-1,test_failed);
s=sprintf(['FB FBR A  %0.5g %s'],AF-1,fail);
disp(s)

for w=1:3

    f=tester_crand(L,w);
    
    c_u_td      = ufilterbank(f,g,a,'crossover',0);
    c_u_ref  = ref_ufilterbank(f,g,a);
    c_nu_td     = filterbank(f,g,a,'crossover',0);
    
    c_u_fft      = ufilterbank(f,g,a,'crossover',1e20);
    c_nu_fft     = filterbank(f,g,a,'crossover',1e20);
    
    %% check that filterbank and ufilterbank produce the same results.
    res=0;
    for m=1:M
        res=res+norm(c_nu_td{m}-squeeze(c_u_td(:,m,:)));  
    end;
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['FB MATCH  W:%2i %0.5g %s'],w,res,fail);
    disp(s)
    
    %% check that ufilterbank match its reference
    res=c_u_td-c_u_ref;
    res=norm(res(:));
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['FB RES    W:%2i %0.5g %s'],w,res,fail);
    disp(s)
    
    %% check that filterbank in time-side and frequency side match
    res=norm(cell2mat(c_nu_fft)-cell2mat(c_nu_td));
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['FB TD FD  W:%2i %0.5g %s'],w,res,fail);
    disp(s)
    
    %% check that ufilterbank in time-side and frequency side match
    res=norm(c_u_fft(:)-c_u_td(:));
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['UFB TD FD W:%2i %0.5g %s'],w,res,fail);
    disp(s)
    
    
    %% Check that ufilterbank is invertible using dual window
    r=ifilterbank(c_u_td,gd,a);
    
    res=norm(f-r);
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['FB DUAL   W:%2i %0.5g %s'],w,res,fail);
    disp(s)
    
    
    %% Test that ifilterbank returns the same for the uniform and non-uniform
    %% case
    %To avoid warning whrn w==1
    if w==1
       c_nu_td=mat2cell(c_u_td,size(c_u_td,1),ones(1,M));
    else
       c_nu_td=mat2cell(c_u_td,size(c_u_td,1),ones(1,M),w);
    end
    c_nu_td=cellfun(@squeeze,c_nu_td,'UniformOutput',false);
    
    r_nu=ifilterbank(c_nu_td,gd,a);
    
    res=norm(r_nu-r);
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['FB INV MATCH W:%2i %0.5g %s'],w,res,fail);
    disp(s)
    
    
    %% Check that filterbanktight gives a tight filterbank
    
    c_ut = ufilterbank(f,gt,a);
    r=ifilterbank(c_ut,gt,a);
    
    res=norm(f-r);
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['FB TIGHT  W:%2i %0.5g %s'],w,res,fail);
    disp(s)
        
    %% Check the real valued systems, dual
    
    fr=tester_rand(L,1);
    
    gdreal=filterbankrealdual(g,a,L);
    
    c_ur=ufilterbank(fr,g,a);
    rreal=2*real(ifilterbank(c_ur,gdreal,a));
    
    res=norm(fr-rreal);
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['FB RDUAL  W:%2i %0.5g %s'],w,res,fail);
    disp(s)
    
    
    %% Check the real valued systems, tight
        
    ct     = ufilterbank(fr,gtreal,a);
    rrealt = 2*real(ifilterbank(ct,gtreal,a));
    
    res=norm(fr-rrealt);
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['FB RTIGHT W:%2i %0.5g %s'],w,res,fail);
    disp(s)
        
    %% check filterbankwin
    
    r=ifilterbank(c_u_td,{'dual',g},a);
    
    res=norm(f-r);
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    s=sprintf(['FB WIN DUAL %0.5g %s'],res,fail);
    disp(s)
    
end;

