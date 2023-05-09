function test_failed = test_wtfft_undec;
%-*- texinfo -*-
%@deftypefn {Function} test_wtfft_undec
%@verbatim
%TEST_COMP_FWT_ALL
%
% Checks perfect reconstruction of the wavelet transform
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_wtfft_undec.html}
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



load vonkoch;
f=vonkoch;
f = 0:2^7-1;
f = f';

J = 3;
w = waveletfb('db',2);

 wh = w.h;
 for ii=1:numel(wh)
     wh{ii}=w.h{ii}./sqrt(w.a(ii));
 end

[h,a] = multid(wh,J);
H = freqzfb(h,length(f),a,'wtfft');
tic; c1 = wtfft(f,H,[]);toc;
tic; c2 = fwt(f,w,J,'undec'); toc;
printCoeffs(c1,c2);

wg = w.g;
 for ii=1:numel(wh)
     wg{ii}=w.g{ii}./sqrt(w.a(ii));
 end
[g,a] = multid(wg,J);
G = freqzfb(g,length(f),a,'syn','wtfft');
fhat = iwtfft(c1,G,[],length(f));toc;
stem([f,fhat]);

hlens = zeros(numel(h),1);
for jj = 1:numel(h)
    hlens(jj) = length(h{jj});
end

shifts=zeros(numel(c1),1);
% check coefficients and find
for jj = 1:numel(c1)
    if(norm(c1{jj}-c2{jj})>1e-6)
        
        for sh=1:floor(length(c1{jj})/2)
           if(norm(c1{jj}-circshift(c2{jj},sh))<1e-6)
             shifts(jj)=sh;
             continue;
           end 
           
           if(norm(c1{jj}-circshift(c2{jj},-sh))<1e-6)
             shifts(jj)=-sh;
             continue;
           end 
        end
        
        if(shifts(jj)~=0)  continue; end;
        % even all coefficients shifts are not equal
     shifts(jj)=Inf;
    end
end

shifts
 
function printCoeffs( x,y)

[J,N1] = size(x);

for j=1:J
    subplot(J,1,j);
    % err = x{j}(:) - y{j}(:);
      stem([x{j}(:),y{j}(:)]);
      lh = line([0 length(x{j})],[eps eps]);
      set(lh,'Color',[1 0 0]);
      lh =line([0 length(x{j})],[-eps -eps]);
      set(lh,'Color',[1 0 0]);

end






 
   

