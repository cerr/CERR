function test_failed = test_argfirwin
test_failed = 0;

disp('---------Testing arg_firwin---------');
%-*- texinfo -*-
%@deftypefn {Function} test_argfirwin
%@verbatim
% This test checks wheter all options from arg_firwin are actually
% treated in firwin.
% This is necessary as firwin itself does not use arg_firwin
% Also tests for duplicates
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_argfirwin.html}
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


% Get window types
g = getfield(getfield(arg_firwin,'flags'),'wintype');

for ii=1:numel(g)
    
        tryfailed = 0;
        fprintf('Testing %12s:',g{ii});
        try
            h = firwin(g{ii},64);
        catch
            test_failed = test_failed + 1;
            tryfailed = 1;
            fprintf('FAILED');
        end
        if ~tryfailed
            fprintf('SUCCESS');
        end
        
        if(sum(strcmp(g{ii},g))>1)
            fprintf(' has DUPLICATES');
        end
        fprintf('\n');
end

