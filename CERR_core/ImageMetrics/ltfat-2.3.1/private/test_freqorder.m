function test_failed = test_freqorder
test_failed = 0;

disp('------------TEST_FREQORDER--------------');
%-*- texinfo -*-
%@deftypefn {Function} test_freqorder
%@verbatim
% This tests whether subbands of a wavelet filterbank tree are
% ordered according to frequency
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_freqorder.html}
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

wt = wfbtinit({'cmband3',1},'nat');
wt = wfbtput(1,1:2,'cmband3',wt);
wt = wfbtput(2,0,'cmband3',wt);

% Bark-like filterbank tree
% Creating tree depicted in Figure 8 in the reference. 
w = wfbtinit({'cmband3',1});
w = wfbtput(1,0,'cmband6',w);
w = wfbtput(1,1,'cmband3',w);
w = wfbtput(2,0:1,'cmband5',w);
w = wfbtput(2,2:3,'cmband2',w);

% Well-tempered musical scale filterbank tree
% Creating tree depicted in Figure 9 in the reference. 
w2 = wfbtinit({'cmband4',1});
w2 = wfbtput(1,0:1,'cmband6',w2);
w2 = wfbtput(2,0:1,'cmband4',w2);
w2 = wfbtput(3,1:4,'cmband4',w2);

w3 = wfbtinit({'cmband3',5,'full'});
w3 = wfbtremove(4,0,w3,'force');
w3 = wfbtremove(3,9,w3,'force');

testcases = { {'cmband3',5,'full'},...
              {'cmband2',5,'full'},...
              {'cmband5',4,'full'},...
              wt,w,w2,w3};


for ii = 1:numel(testcases)
    [g,a]=wfbt2filterbank(testcases{ii},'freq');
    glmax = max(cellfun(@(gEl)numel(gEl.h),g));
    F = filterbankfreqz(g,a,2*glmax);
    [~,Fidpeaks] = max(abs(F));
    fprintf('Tree %i:',ii)
    if any(Fidpeaks(2:end)-Fidpeaks(1:end-1) < 0)
        fprintf(' FAILED');
        test_failed=test_failed +1;
    else
        fprintf(' OK');
    end
    fprintf('\n');
    
end

