function test_failed = test_blockfwt()
test_failed = 0;

disp('-------------TEST_BLOCKFWT--------------');

L = 567;
W = [1,3];

Lb = [78,64,58,1021];

wa = {'dden3','ana:symorth1'};
ws = {'dden3','syn:symorth1'};
J = [5];


for wId = 1:numel(W)
for lId = 1:numel(L)
f = tester_rand(L(lId),W(wId));
for lbId = 1:numel(Lb)
for waId=1:numel(wa)

Fa = blockframeaccel(frame('fwt',wa{waId},J),Lb(lbId),'segola');
Fs = blockframeaccel(frame('fwt',ws{waId},J),Lb(lbId),'segola');

a = Fa.g.a(1);
m = numel(Fa.g.g{1}.h);
rmax = (a^J-1)/(a-1)*(m-1);


f = postpad(f,L(lId)+rmax);
block(f,'offline','L',Lb(lbId));

colC = {};
colfhat = {};

for ii=1:ceil(L(lId)/Lb(lbId))
    fb = blockread();
    c  = blockana(Fa,fb);
    ccell = comp_fwtpack2cell(Fa,c);
    
    colC{end+1} = ccell;
    
    chat = cell2mat(ccell);
    
    fhat = blocksyn(Fs,chat,size(fb,1));
    colfhat{end+1} = fhat;
end

err = 0;
cwhole = fwt(f,wa{waId},J,'zero','cell');
for ii=1:numel(colC{1})
   cc{ii} = cell2mat(cellfun(@(cEl) cEl{ii},colC','UniformOutput',0));
   Ltmp = min([size(cwhole{ii},1),size(cc{ii},1)]);
   err = err + norm(cwhole{ii}(1:Ltmp,:)-cc{ii}(1:Ltmp,:));
end

[test_failed,fail]=ltfatdiditfail(err,test_failed);
fprintf('COEFS L:%3i, W:%3i, Lb=%3i, %s, err=%.4e %s\n',L(lId),W(wId),Lb(lbId),wa{waId},err,fail);


fhat = cell2mat(colfhat.');

fhat = fhat(rmax+1:end,:);

Lcrop = min([size(fhat,1),size(f,1)]);


res = norm([f(1:Lcrop,:)-fhat(1:Lcrop,:)]);
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf('REC   L:%3i, W:%3i, Lb=%3i, %s, err=%.4e %s\n',L(lId),W(wId),Lb(lbId),wa{waId},res,fail);

end
end
end
end

%-*- texinfo -*-
%@deftypefn {Function} test_blockfwt
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_blockfwt.html}
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

