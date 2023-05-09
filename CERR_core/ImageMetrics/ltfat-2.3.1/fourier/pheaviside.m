function h=pheaviside(L)
%-*- texinfo -*-
%@deftypefn {Function} pheaviside
%@verbatim
%PHEAVISIDE  Periodic Heaviside function
%   Usage: h=pheaviside(L);
%
%   PHEAVISIDE(L) returns a periodic Heaviside function. The periodic
%   Heaviside function takes on the value 1 for indices corresponding to
%   positive frequencies, 0 corresponding to negative frequencies and the
%   value .5 for the zero and Nyquist frequencies.
%
%   To get a function that weights the negative frequencies by 1 and the
%   positive by 0, use involute(PHEAVISIDE(L))
%
%   As an example, the PHEAVISIDE function can be use to calculate the
%   Hilbert transform for a column vector f*:
%
%     h=2*ifft(fft(f).*pheaviside(length(f)));
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/pheaviside.html}
%@seealso{middlepad, involute, fftindex}
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

%   AUTHOR : Peter L. Soendergaard.
%   REFERENCE: OK
%   TESTING: OK

complainif_argnonotinrange(nargin,1,1,mfilename);

h=zeros(L,1);
if L>0
    % First term is .5
    h(1)=.5;

    % Set positive frequencies to 1.
    h(2:ceil(L/2))=1;

    % Last term (Nyquist frequency) is also .5, if it exists.
    if rem(L,2)==0
        h(L/2+1)=.5;
  end;
end;


