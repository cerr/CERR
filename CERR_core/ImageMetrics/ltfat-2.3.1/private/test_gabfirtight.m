function test_failed = test_gabfirtight()
%-*- texinfo -*-
%@deftypefn {Function} test_gabfirtight
%@verbatim
%TEST_GABFIRTIGHT Some of the windows returned from firwin are tight
%   immediatelly. This function tests for that
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_gabfirtight.html}
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



disp(' ===============  TEST_GABFIRTIGHT ================');

disp('--- Used subroutines ---');

which gabwin
which comp_window


shouldBeTight = [...
    struct('g','sine','a',10,'M',40,'L',[]),...
    struct('g',{{'sine',40}},'a',10,'M',40,'L',[]),...
    struct('g',{{'sine',28}},'a',14,'M',40,'L',[]),...
    struct('g','sine','a',20,'M',40,'L',[]),...
    struct('g',{{'sine',60}},'a',20,'M',60,'L',[]),...
    struct('g',{{'sine',54}},'a',18,'M',60,'L',[]),...
    struct('g',{{'sine',54,'inf'}},'a',18,'M',60,'L',[]),...
    struct('g','sine','a',5,'M',40,'L',[]),...
    struct('g','sqrttria','a',5,'M',40,'L',[]),...
];

shouldNotBeTight = [...
    struct('g','sine','a',16,'M',40,'L',[]),...
    struct('g',{{'sine',41}},'a',10,'M',40,'L',[]),...
    struct('g',{{'sine',26}},'a',10,'M',40,'L',[]),...
    struct('g','sqrttria','a',40,'M',40,'L',[]),...
];


for ii=1:numel(shouldBeTight)
    gw = shouldBeTight(ii);
    
    [~,info] = gabwin(gw.g,gw.a,gw.M,gw.L);
    [test_failed,fail]=ltfatdiditfail(~info.istight,test_failed,0);
    fprintf(['GABFIRISTIGHT g= a=%i M=%i %s\n'],gw.a,gw.M,fail);
    
end

for ii=1:numel(shouldNotBeTight)
    gw = shouldNotBeTight(ii);
    
    [~,info] = gabwin(gw.g,gw.a,gw.M,gw.L);
    [test_failed,fail]=ltfatdiditfail(info.istight,test_failed,0);
    fprintf(['GABFIRISNOTTIGHT g= a=%i M=%i %s\n'],gw.a,gw.M,fail);
    
end
