function test_failed = test_pebfun
test_failed = 0;

%-*- texinfo -*-
%@deftypefn {Function} test_pebfun
%@verbatim
% First, just test if functions run with various input parameters
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_pebfun.html}
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

M = 10;
a = 8;
L = 120;
incrange = 0:4:80;

g = pebfun(L,[1,-1]);
g = pebfun(L,[1,-1,9]);
%g = ptpfun(L,[1,-1,9],'inf');

gd = pebfundual([1,-1],a,M,L);
gd = pebfundual([1,-1],a,M,L,10);

gd = pebfundual({[1,-1],10},a,M,L);
gd = pebfundual({[1,-1],5},a,M,L,10);
% 
% [gd,nlen] = ptpfundual([1,-1],a,M,L,'inf');
% 
% [gd,nlen] = ptpfundual([1,-1],a,M,L,'inf','matchscale');


% This should fail, but be caught by some of the input checks.
% We will test if the error message starts with function name in allcaps
% followed by a colon e.g. PTPFUN:

% Too short w
try
    g = pebfun(L,[1]);
    gd = pebfundual([1],a,M,L);
    % We should have failed in g
    test_failed = test_failed + 1;
    failstr = 'FAILED';
catch
    err = lasterror;
    [test_failed,failstr]=dititfailedcorrectly(err.message,'pebfun',test_failed);
end
fprintf('PEBFUN Too short w test %s\n',failstr);

% This has been dealt with
% % Only pos weights
% try
%     g = ptpfun(L,[1,1]);
%     gd = ptpfundual(L,[1,1],a,M);
%     % We should have failed in g
%     test_failed = test_failed + 1;
%     failstr = 'FAILED';
% catch
%     err = lasterror;
%     [test_failed,failstr]=dititfailedcorrectly(err.message,'ptpfun',test_failed);
% end
% fprintf('PTPFUN Only positive w test %s\n',failstr);
% 
% % Only neg weights
% try
%     g = ptpfun(L,[-1,-1]);
%     gd = ptpfundual(L,[-1,-1],a,M);
%     % We should have failed in g
%     test_failed = test_failed + 1;
%     failstr = 'FAILED';
% catch
%     err = lasterror;
%     [test_failed,failstr]=dititfailedcorrectly(err.message,'ptpfun',test_failed);
% end
% fprintf('PTPFUN Only negative w test %s\n',failstr);

% One zero in weights
try
    g = pebfun(L,[-1,0,1]);
    gd = pebfundual([-1,0,1],a,M,L);
    % We should have failed in g
    test_failed = test_failed + 1;
    failstr = 'FAILED';
catch
    err = lasterror;
    [test_failed,failstr]=dititfailedcorrectly(err.message,'pebfun',test_failed);
end
fprintf('PEBFUN Zero in w test %s\n',failstr);


% Test if ptpfun and ptpfundual indeed fulfill the Waxler-Raz conditions
% (are dual windoes up to scaling) for a range of inc parameter
wcell = {[-1,1],[1,-1,3,4],[-1,-1],[1,1]};

for w = wcell
for inc =incrange
   g = pebfun(L,w{1});
   gd = pebfundual(w{1},a,M,L);
   [~,err] = gabdualnorm(g,gd,a,M,L);
   [test_failed,fail]=ltfatdiditfail(err,test_failed);
   fprintf('PEBFUN IS DUAL L=%i,a=%i,M=%i, inc=%i %s\n',L,a,M,inc,fail);
end
end

% Test ptpfun and ptpfundual individually (each uses canonical dual window)
f = tester_crand(L,1);

for w = wcell
   g = pebfun(L,w{1});
   c = dgt(f,g,a,M);
   fhat = idgt(c,{'dual',g},a);
   res = norm(f-fhat);
   [test_failed,fail]=ltfatdiditfail(res,test_failed);
   fprintf('PEBFUN REC L=%i,a=%i,M=%i, %s\n',L,a,M,fail);
end

for w = wcell
   g = pebfundual(w{1},a,M,L);
   c = dgt(f,g,a,M);
   fhat = idgt(c,{'dual',g},a);
   res = norm(f-fhat);
   [test_failed,fail]=ltfatdiditfail(res,test_failed);
   fprintf('PEBFUNDUAL REC L=%i,a=%i,M=%i, %s\n',L,a,M,fail);
end

% Test ptpfun and ptpfundual properly scaled
for w = wcell
  for inc =incrange
   g = pebfun(L,w{1});
   gd = pebfundual(w{1},a,M,L,inc);
   c = dgt(f,g,a,M);
   fhat = idgt(c,gd,a);
   res = norm(f-fhat);
   [test_failed,fail]=ltfatdiditfail(res,test_failed);
   fprintf('PEBFUN PEBFUNDUAL REC L=%i,a=%i,M=%i, inc=%i %s\n',L,a,M,inc,fail);
  end
end

% Disabled for now
% for w = wcell
%   for inc =incrange
%    g = ptpfun(L,w{1},'inf');
%    gd = ptpfundual(w{1},a,M,L,inc,'matchscale','inf');
%    c = dgt(f,g,a,M);
%    fhat = idgt(c,gd,a);
%    res = norm(f-fhat);
%    [test_failed,fail]=ltfatdiditfail(res,test_failed);
%    fprintf('PTPFUN PTPFUNDUAL REC PEAK L=%i,a=%i,M=%i, inc=%i %s\n',L,a,M,inc,fail);
%   end
% end
% 
% % Test using FIR duals
% wcell = {[-0.5,0.5]};
% for w = wcell
%   for inc =incrange
%    g = ptpfun(L,w{1});
%    [gd,nlen] = ptpfundual(w{1},a,M,L,inc,'matchscale');
%    c = dgt(f,g,a,M);
%    fhat = idgt(c,middlepad(gd,nlen),a);
%    res = norm(f-fhat);
%    [test_failed,fail]=ltfatdiditfail(res,test_failed);
%    fprintf('PTPFUN PTPFUNDUAL REC FIR L=%i,a=%i,M=%i, inc=%i %s\n',L,a,M,inc,fail);
%   end
% end


function [test_failed,failstr]=dititfailedcorrectly(errmsg,fname,test_failed)

if isempty(strfind(errmsg,strcat(upper(fname),':')))
    test_failed = test_failed + 1;
    failstr = 'FAILED';
else
    failstr = '';
end

