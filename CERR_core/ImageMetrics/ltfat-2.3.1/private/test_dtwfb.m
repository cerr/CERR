function test_failed = test_dtwfb()
test_failed = 0;
disp('========= TEST DTWFB ============');
global LTFAT_TEST_TYPE;
tolerance = 2e-8;
if strcmpi(LTFAT_TEST_TYPE,'single')
   tolerance = 1e-5;
end


Larray = [603];
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
dualwt{10} = {'dden2',3};
dualwt{11} = {'optsym3',3};

tolerance = ones(numel(dualwt),1)*tolerance;
%-*- texinfo -*-
%@deftypefn {Function} test_dtwfb
%@verbatim
% decrease the tolerance for oddeven filters
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dtwfb.html}
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
tolerance([4,6,7,8,9]) = 1e-5;

% Perfect reconstruction
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
    
    
    for cmplx = {'real','complex'}
        for order = {'freq','nat'}
          for L = Larray
              for W = Warray

                if strcmp(cmplx{1},'real') 
                   f = tester_rand(L,W);
                else
                   f = tester_crand(L,W);
                end
                
                if strcmp(cmplx{1},'real') 
                    [c,info] = dtwfbreal(f,dualwtana,order{1});
                    fhat1 = idtwfbreal(c,dualwtsyn,L,order{1});
                    fhat2 = idtwfbreal(c,info);
                    
                    res = norm(f-fhat1);
                    [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
                    s=sprintf(['DUAL-TREE REC         %i L:%i W:%i %s %s %0.5g %s'],ii,L,W,cmplx{1},order{1},  res,fail);
                    disp(s)
                    
                    res = norm(f-fhat2);
                    [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
                    s=sprintf(['DUAL-TREE REC INFO    %i L:%i W:%i %s %s %0.5g %s'],ii,L,W,cmplx{1},order{1}, res,fail);
                    disp(s)
                end
                    [c,info] = dtwfb(f,dualwtana,order{1});
                    fhat1 = idtwfb(c,dualwtsyn,L,order{1});
                    fhat2 = idtwfb(c,info);
                    
                    res = norm(f-fhat1);
                    [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
                    s=sprintf(['DUAL-TREE REC         %i L:%i W:%i %s %s %0.5g %s'],ii,L,W,cmplx{1},order{1}, res,fail);
                    disp(s)
                    
                    res = norm(f-fhat2);
                    [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance(ii));
                    s=sprintf(['DUAL-TREE REC INFO    %i L:%i W:%i %s %s %0.5g %s'],ii,L,W,cmplx{1},order{1}, res,fail);
                    disp(s)   
                    
                    if strcmp(order{1},'freq')
                        cnat = dtwfb(f,dualwtana,'nat');
                        % Is there a subband in c with exactly the same
                        % coefficients?
                        for cnatId=1:numel(cnat)
                            for cId=1:numel(c)
                               if numel(c{cId}) == numel(cnat{cnatId})
                                   res = norm(c{cId}-cnat{cnatId});
                                   if res<1e-10
                                       break;
                                   end
                               end
                            end
                            if any(res)<1e-10
                                continue;
                            else
                                 [test_failed,fail]=ltfatdiditfail(1,test_failed);
                                  s=sprintf(['DUAL-TREE FREQ NAT    %i L:%i W:%i %s %s %s'],ii,L,W,cmplx{1},order{1}, fail);
                                  disp(s)
                                  break;
                            end
                        end
                        
                    end
              end
          end
        end
    end
    
    
    
end

% Nat vs. freq (Are te actual subbands equal?)



