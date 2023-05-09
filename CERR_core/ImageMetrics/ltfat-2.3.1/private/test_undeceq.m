function test_failed=test_undeceq
%-*- texinfo -*-
%@deftypefn {Function} test_undeceq
%@verbatim
% This function test whether fwt is just a subsampled version of ufwt, wfbt
% of uwfbt etc.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_undeceq.html}
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

J = 5;

L = 128;

f = tester_rand(L,1);

wav = {'db4','spline4:4'};

for ii = 1:numel(wav)
    
   w = fwtinit(wav{ii});
    
   [c,info] = fwt(f,wav{ii},J,'cell');
   cu = ufwt(f,wav{ii},J,'noscale');
   
   err = 0;
   suFac = size(cu,1)./info.Lc;
   
   for jj = 1:numel(c)
       err = err + norm(c{jj}-cu(1:suFac(jj):end,jj));
   end
   
   [test_failed,fail]=ltfatdiditfail(err,test_failed);
    fprintf('DWT J=%d, %6.6s, L=%d, err=%.4e %s \n',J,wav{ii},length(f),err,fail);
end
   
for ii = 1:numel(wav)
   [c,info] = wfbt(f,{wav{ii},J});
   cu = uwfbt(f,{wav{ii},J},'noscale');
   
   err = 0;
   suFac = size(cu,1)./info.Lc;
   
   for jj = 1:numel(c)
       err = err + norm(c{jj}-cu(1:suFac(jj):end,jj));
   end
   
   [test_failed,fail]=ltfatdiditfail(err,test_failed);
    fprintf('WFBT J=%d, %6.6s, L=%d, err=%.4e %s \n',J,wav{ii},length(f),err,fail);
end

for ii = 1:numel(wav)
   [c,info] = wpfbt(f,{wav{ii},J});
   cu = uwpfbt(f,{wav{ii},J},'noscale');
   
   err = 0;
   suFac = size(cu,1)./info.Lc;
   
   for jj = 1:numel(c)
       err = err + norm(c{jj}-cu(1:suFac(jj):end,jj));
   end
   
   [test_failed,fail]=ltfatdiditfail(err,test_failed);
    fprintf('WPFBT J=%d, %6.6s, L=%d, err=%.4e %s \n',J,wav{ii},length(f),err,fail);
end

