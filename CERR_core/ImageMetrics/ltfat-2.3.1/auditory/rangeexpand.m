function outsig = rangeexpand(insig,varargin);
%-*- texinfo -*-
%@deftypefn {Function} rangeexpand
%@verbatim
%RANGEEXPAND  Expand the dynamic range of a signal
%   Usage:  sig = rangeexpand(insig,mu,sigweight);
%
%   RANGEEXPAND(insig,mu,sigweight) inverts a previously
%   applied mu-law companding to the signal insig. The parameters
%   mu and sigweight must match those from the call to RANGECOMPRESS
%
%   RANGEEXPAND takes the following optional arguments:
%
%     'mulaw'   Do mu-law compression, this is the default.
%
%     'alaw'    Do A-law compression.
%
%     'mu',mu   mu-law parameter. Default value is 255.
%  
%   References:
%     S. Jayant and P. Noll. Digital Coding of Waveforms: Principles and
%     Applications to Speech and Video. Prentice Hall, 1990.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/auditory/rangeexpand.html}
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

% AUTHOR: Bruno Torresani and Peter L. Soendergaard

definput.flags.method={'mulaw','alaw'};
definput.keyvals.mu=255;
definput.keyvals.A=87.7;
[flags,kv]=ltfatarghelper({},definput,varargin);

if flags.do_mulaw

  cst = (1+kv.mu);
  outsig = cst.^(abs(insig));
  outsig = sign(insig) .* (outsig-1);
  outsig = outsig/kv.mu;

end;

if flags.do_alaw
  absx=abs(insig);
  tmp=1+log(kv.A);
  mask=absx<1/tmp;

  outsig = sign(insig).*(mask.*(absx*tmp/kv.A)+(1-mask).*exp(absx*tmp-1)/kv.A);
end;


