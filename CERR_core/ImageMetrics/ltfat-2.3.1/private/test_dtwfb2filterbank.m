function test_failed = test_dtwfb2filterbank
%-*- texinfo -*-
%@deftypefn {Function} test_dtwfb2filterbank
%@verbatim
% This test only 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dtwfb2filterbank.html}
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
test_failed = 0;
disp('========= TEST DTWFB ============');
global LTFAT_TEST_TYPE;
tolerance = 3e-8;
if strcmpi(LTFAT_TEST_TYPE,'single')
   tolerance = 1e-5;
end

L = 1000;
Larray = [1100,1701];
Warray = [1,3];

dualwt{1} = {'qshift1',1};
dualwt{2} = {'qshift3',5,'first','symorth1'};
dualwt{3} = {{'qshift3',5,'full','first','ana:symorth3','leaf','db4'},...
              {'qshift3',5,'full','first','syn:symorth3','leaf','db4'}};
dualwt{4} = {{'ana:oddeven1',5},{'syn:oddeven1',5}};
dualwt{5} = {'qshift3',3,'first','db4'};
dualwt{6} = {{'syn:oddeven1',2,'doubleband'},{'ana:oddeven1',2,'doubleband'}};
dualwt{7} = {dtwfbinit({'syn:oddeven1',2,'doubleband'}),dtwfbinit({'ana:oddeven1',2,'doubleband'})};
dualwt{8} = {{'dual',{'syn:oddeven1',2,'doubleband'}},{'syn:oddeven1',2,'doubleband'}};
dualwt{9} = {dtwfbinit({'syn:oddeven1',3,'full'},'nat'),dtwfbinit({'ana:oddeven1',3,'full'},'nat')};
tmp= dtwfbinit({'qshift1',6,'full'});
tmp = wfbtremove(4,0,tmp,'force');
tmp = wfbtremove(4,3,tmp,'force');
tmp = wfbtremove(3,6,tmp,'force');
dualwt{10} = {tmp,tmp};
dualwt{11} = {'dden2',3};
dualwt{12} = {'optsym3',3};

tolerance = ones(numel(dualwt),1)*tolerance;
% decrease the tolerance for oddeven filters
tolerance([4,6,7,8,9]) = 4e-5;


for ii = 1:numel(dualwt)
    if isempty(dualwt{ii})
        continue;
    end
    if iscell(dualwt{ii}{1}) || isstruct(dualwt{ii}{1}) && numel(dualwt{ii})==2
        dualwtana = dualwt{ii}{1};
        dualwtsyn = dualwt{ii}{2};
    else
        dualwtana = dualwt{ii};
        dualwtsyn = dualwtana;
    end
        
    for order = {'nat','freq'}
        [g,a,info] = dtwfb2filterbank( dualwtana, 'real', order{1});
        [gd,ad] = dtwfb2filterbank( dualwtsyn, 'real', order{1});
        
        G = filterbankfreqz(g,a,L);
        
        
        if strcmp(order{1},'freq')
            % Test if is analytic..
            % Except for the lowpass and highpass filters, energy in 
            % negative frequency region should be negligible
            for iii=1:size(G,2)
                posfreqEn = norm(G(1:end/2,iii))^2;
                negfreqEn = norm(G(end/2+1:end,iii))^2;
             
             dtw = dtwfbinit(dualwtana);
             fno = numel(dtw.nodes{1}.h);
             if iii==1 || any(iii == [size(G,2)-fno-1:size(G,2)])
                 res = negfreqEn>posfreqEn/2; % No justification
             else
                 res = negfreqEn>posfreqEn/100;
                 if res>0
                    % Uncomment to see frequency response
                    % G = filterbankfreqz(g,a,L,'plot','linabs'); 
                 end
             end
             if res
                 break;
             end
            end
             [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
             s=sprintf(['DUAL-TREE IS ANALYTIC %i %s %0.5g %s'],ii, order{1},res,fail);
             disp(s)
        end
        

        Greal = filterbankfreqz(info.g1,a,L);
        Ghilb = filterbankfreqz(info.g2,a,L);

        G2 = (Greal+1i*Ghilb);

        res = norm(G(:)-G2(:));
        [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
        s=sprintf(['DUAL-TREE %i %s %0.5g %s'],ii, order{1},res,fail);
        disp(s)

        [gc,ac,info] = dtwfb2filterbank( dualwtana, 'complex', order{1});
        [gcd,acd] = dtwfb2filterbank( dualwtsyn, 'complex', order{1});
        
        % Compare coefficients
        for LL = Larray 
        for W = Warray 
        for cmplx = {'real','complex'}
           if strcmp(cmplx{1},'real') 
               f = tester_rand(LL,W);
           else
               f = tester_crand(LL,W);
           end
        
        if strcmp(cmplx{1},'real')   
           c = dtwfbreal(f,dualwtana,order{1});
           cfb = filterbank(f,g,a);
           
           res = cell2mat(c)-cell2mat(cfb);
           res = norm(res(:));
           [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
           s=sprintf(['DUAL-TREE COEFF         %i L:%i W:%i %s %s %0.5g %s'],ii,LL,W,cmplx{1}, order{1},res,fail);
           disp(s)
           
           
           fhat = 2*real(ifilterbank(c,gd,ad,LL));
           res= norm(f(:)-fhat(:));
           [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
           s=sprintf(['DUAL-TREE REC           %i L:%i W:%i %s %s %0.5g %s'],ii,LL,W,cmplx{1}, order{1},res,fail);
           disp(s)
           
           
           
           cc = dtwfb(f,dualwtana,order{1});
           cfbc = filterbank(f,gc,ac);
           
           res = cell2mat(cc)-cell2mat(cfbc);
           res = norm(res(:));
           [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
           s=sprintf(['DUAL-TREE COEFF COMPLEX %i L:%i W:%i %s %s %0.5g %s'],ii,LL,W,cmplx{1}, order{1},res,fail);
           disp(s)
           
           fhat = ifilterbank(cc,gcd,acd,LL);
           res= norm(f(:)-fhat(:));
           [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
           s=sprintf(['DUAL-TREE REC  COMPLEX  %i L:%i W:%i %s %s %0.5g %s'],ii,LL,W,cmplx{1}, order{1},res,fail);
           disp(s)
           
           
           res = cell2mat(c)-cell2mat(cc(1:end/2));
           res = norm(res(:));
           [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
           s=sprintf(['DUAL-TREE COEFF EQ      %i L:%i W:%i %s %s %0.5g %s'],ii,LL,W,cmplx{1}, order{1},res,fail);
           disp(s)
        else
           c = dtwfb(f,dualwtana,order{1});
           cfb = filterbank(f,gc,ac);
           
           res = cell2mat(c)-cell2mat(cfb);
           res = norm(res(:));
           [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
           s=sprintf(['DUAL-TREE COEFF         %i L:%i W:%i %s %s %0.5g %s'],ii,LL,W,cmplx{1}, order{1},res,fail);
           disp(s)
           
           fhat = ifilterbank(c,gcd,acd,LL);
           res= norm(f(:)-fhat(:));
           [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
           s=sprintf(['DUAL-TREE REC           %i L:%i W:%i %s %s %0.5g %s'],ii,LL,W,cmplx{1}, order{1},res,fail);
           disp(s)
           
           
           
            
        end
        
           
        
        
        end
        end
        end
    end
end

