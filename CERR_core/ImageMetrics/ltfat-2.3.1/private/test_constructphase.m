function test_failed=test_constructphase
%-*- texinfo -*-
%@deftypefn {Function} test_constructphase
%@verbatim
%TEST_CONSTRUCTPHASE  
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_constructphase.html}
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

disp(' =================== TEST_CONSTRUCTPHASE ====================== ');

forig = greasy;
g = 'gauss';
a = 16;
M = 1024;

tolcell = {1e-10,[1e-1 1e-10],[1e-1 1e-3 1e-10]};
Warray = [1, 3];

for W=Warray
    f = repmat(forig,1,W);
    f = bsxfun(@times,f,[1:W]);
    
    global LTFAT_TEST_TYPE;
    if strcmpi(LTFAT_TEST_TYPE,'single')
        f = cast(f,'single');
    end
    
    for pcId = 1:2
        % Complex case
        phaseconv = getat({'timeinv','freqinv'},pcId);

        for tId = 1:numel(tolcell)
            tol = getat(tolcell,tId);
            tolstr = sprintf('%.2e, ',tol);
            tolstr = tolstr(1:end-2);


            tra = @(f) dgt(f,g,a,M,phaseconv);
            itra = @(c) idgt(c,{'dual',g},a,phaseconv);
            proj = @(c) tra(itra(c));
            c = tra(f);
            s = abs(c);


            % Normal call
            chat = constructphase(s,g,a,tol,phaseconv);

            E = comperr(s,proj(chat));

            fail = '';            
            if E>-19
            test_failed = test_failed + 1;
            fail = 'FAILED';
            end

            fprintf('CONSTRUCTPHASE %s tol=[%s] W=%d E=%.2f %s\n',phaseconv,tolstr,W,E,fail);
            
            % Known part
            mask = zeros(size(s));
            mask(:,1:floor(size(s,2)/2),:) = 1;
            chat = constructphase(s,g,a,tol,mask,angle(c),phaseconv);
            E = comperr(s,proj(chat));
            chat2 = constructphase(c,g,a,tol,mask,phaseconv);
            E2 = comperr(s,proj(chat2));

            fail = '';
            if E>-19 || abs(E-E2) > 0.1
            test_failed = test_failed + 1;
            fail = 'FAILED';
            end

            fprintf('CONSTRUCTPHASE MASK %s tol=[%s] W=%d E=%.2f %s\n',phaseconv,tolstr,W,E,fail);


            tra = @(f) dgtreal(f,g,a,M,phaseconv);
            itra = @(c) idgtreal(c,{'dual',g},a,M,phaseconv);
            proj = @(c) tra(itra(c));
            c = tra(f);
            s = abs(c);

            chat = constructphasereal(s,g,a,M,tol,phaseconv);

            E = comperr(s,proj(chat));

            fail = '';
            if E>-18
            test_failed = test_failed + 1;
            fail = 'FAILED';
            end

            fprintf('CONSTRUCTPHASEREAL %s tol=[%s] W=%d E=%.2f %s\n',phaseconv,tolstr,W,E,fail);
            
            
            % Known part
            mask = zeros(size(s));
            mask(:,1:floor(size(s,2)/2),:) = 1;
            chat = constructphasereal(s,g,a,M,tol,mask,angle(c),phaseconv);
            E = comperr(s,proj(chat));
            chat2 = constructphasereal(c,g,a,M,tol,mask,phaseconv);
            E2 = comperr(s,proj(chat2));

            fail = '';
            if E>-19 || abs(E-E2) > 0.1
            test_failed = test_failed + 1;
            fail = 'FAILED';
            end

            fprintf('CONSTRUCTPHASEREAL MASK %s tol=[%s] W=%d E=%.2f %s\n',phaseconv,tolstr,W,E,fail);
        end
    end
end


function el = getat(collection,id)
if iscell(collection)
    el = collection{id};
else    
    el = collection(id);
end


function E = comperr(s,c)


E = 20*log10(norm(abs(s(:))-abs(c(:)),'fro')/norm(abs(s(:)),'fro'));



