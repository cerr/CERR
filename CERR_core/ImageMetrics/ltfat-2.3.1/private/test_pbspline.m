function test_failed=test_pbspline

Lr=[15,16,18,20];
ar=[ 3, 4, 6, 5];
or=[1, 1.5, 2,3];

%-*- texinfo -*-
%@deftypefn {Function} test_pbspline
%@verbatim
%btypes={'ed','xd','stard','ec','xc','starc'};
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_pbspline.html}
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
btypes={'ed','xd','stard'};
centtypes={'wp','hp'};

test_failed=0;

disp(' ===============  TEST_PBSPLINE ============');

for ii=1:length(Lr)
  L=Lr(ii);
  a=ar(ii);
  N=L/a;
  
  for jj=1:length(or)
    order=or(jj);
    
    for kk=1:numel(btypes)
      btype=btypes{kk};
      
      for ll=1:2
        centstring=centtypes{ll};
        
        [g,nlen]=pbspline(L,order,a,btype,centstring);
        
        A=zeros(L,1);
        
        for n=0:N-1
          A=A+circshift(g,n*a);
        end;
        
        res=max(abs(A-1/sqrt(a)));
        [test_failed,fail]=ltfatdiditfail(res,test_failed);        
        s=sprintf('PBSPLINE PU   %2s %s L:%3i a:%3i o:%3.5g %0.5g %s', ...
                  btype,centstring,L,a,order,res,fail);
        disp(s);
        
        gcutextend=middlepad(middlepad(g,nlen,centstring),L,centstring);
        
        res=norm(g-gcutextend);

        [test_failed,fail]=ltfatdiditfail(res,test_failed);        
        s=sprintf('PBSPLINE NLEN %2s %s L:%3i a:%3i o:%3.5g %0.5g %s', ...
                  btype,centstring,L,a,order,res,fail);
        disp(s);

        
      end;
      
    end;        
  end;
  
end;    


