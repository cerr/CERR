function test_failed=test_lconv
Lf=[9, 10  9, 9, 1];
Wf=[1,  1, 3, 1, 1];

Lg=[9, 10  9, 9, 1];
Wg=[1,  1, 1, 3, 1];


ctypes={'default','r','rr'};

test_failed=0;

disp(' ===============  TEST_LCONV ==============');

for jj=1:length(Lf)

    for ii=1:3
        for type = {'real','complex'}
            ctype=ctypes{ii};
            
            
            if strcmp(type{1},'complex')
                f=tester_crand(Lf(jj), Wf(jj));
                g=tester_crand(Lg(jj), Wg(jj));
            else
                f=tester_rand(Lf(jj), Wf(jj));
                g=tester_rand(Lg(jj), Wg(jj));
            end
            
            h1=lconv(f,g,ctype);
            h2cell = {};

            if Wf(jj) == 1
                for wId = 1:Wg(jj)
                    h2cell{end+1}=ref_lconv(f,g(:,wId),ctype);
                end
            else
                for wId = 1:Wf(jj)
                    h2cell{end+1}=ref_lconv(f(:,wId),g,ctype);
                end
            end
             

            h2 = cell2mat(h2cell);
            
            res=norm(h1(:)-h2(:));
            [test_failed,fail]=ltfatdiditfail(res,test_failed);
            s=sprintf('PCONV %3s %6s  %0.5g %s',ctype,type{1},res,fail);
            disp(s);
        end
    end
end


%-*- texinfo -*-
%@deftypefn {Function} test_lconv
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_lconv.html}
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

