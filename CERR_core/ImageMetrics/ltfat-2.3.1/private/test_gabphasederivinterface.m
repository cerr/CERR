function test_falied = test_gabphasederivinterface
test_failed = 0;

%-*- texinfo -*-
%@deftypefn {Function} test_gabphasederivinterface
%@verbatim
%Test whether the batch interface does the same thing as indivisual calls
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_gabphasederivinterface.html}
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

% TODO: test also wrong number of input arguments

disp('---------------test_gabphasederivinterface---------------------');

f = tester_rand(128,1);
a = 4;
M = 8;
g = 'gauss';

c = dgt(f,g,a,M);
algCell = {'dgt','abs','phase','cross'};
algArgs = {{'dgt',f,g,a,M}
    {'abs',abs(c),g,a}
    {'phase',angle(c),a}
    {'cross',f,g,a,M}
    };

phaseconvCell = {'freqinv','timeinv','symphase','relative'};

dtypecombCell = { {'t','t'},...
    {'t','f'},...
    {'f','t'},...
    {'t','f','t'},...
    {'tt','t'},...
    {'ff','f'},...
    {'tf','f'},...
    {'tf','f','tt'},...
    {'tf','f','tt','tf'},...
    {'t','f','tt','ff','ft','tf'},...
    {'t','f','t','ff','tt','tt','tt'},...
    };

for algId=1:numel(algArgs)
    alg = algArgs{algId};
    
    for dtypecombId=1:numel(dtypecombCell)
        dtypecomb = dtypecombCell{dtypecombId};
        for phaseconvId=1:numel(phaseconvCell)
            phaseconv=phaseconvCell{phaseconvId};
            
            
            individual = cell(1,numel(dtypecomb));
            for dtypecompId = 1:numel(dtypecomb)
                individual{dtypecompId} = ...
                    gabphasederiv(dtypecomb{dtypecompId},alg{:},phaseconv);
            end
            batch = gabphasederiv(dtypecomb,alg{:},phaseconv);
            
            
            res = sum(cellfun(@(iEl,bEl) norm(iEl(:)-bEl(:)),individual,batch))/numel(batch);
            [test_failed,failstring]=ltfatdiditfail( res,...
                           test_failed,1e-8);

            flagcompString = sprintf('%s, ',dtypecomb{:});
            fprintf('GABPHASEDERIV BATCH EQ alg:%s order:{%s} phaseconv:%s %d %s\n',alg{1},flagcompString(1:end-2),phaseconv,res,failstring);
        end
    end
end






