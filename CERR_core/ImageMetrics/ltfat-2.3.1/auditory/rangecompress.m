function [outsig, sigweight] = rangecompress(insig,varargin)
%-*- texinfo -*-
%@deftypefn {Function} rangecompress
%@verbatim
%RANGECOMPRESS   Compress the dynamic range of a signal 
%   Usage: [outsig, sigweight] = rangecompress(insig,mu);
%   
%   [outsig, sigweight]=RANGECOMPRESS(insig,mu) range-compresss the input
%   signal insig using mu-law range-compression with parameter mu.
%
%   RANGECOMPRESS takes the following optional arguments:
%
%     'mulaw'  Do mu-law compression, this is the default.
%
%     'alaw'   Do A-law compression.
%
%     'mu',mu  mu-law parameter. Default value is 255.
%
%     'A',A    A-law parameter. Default value is 87.7.
%
%   The following plot shows how the output range is compressed for input
%   values between 0 and 1:
%
%     x=linspace(0,1,100);
%     xc=rangecompress(x);
%     plot(x,xc);
%     xlabel('input');
%     ylabel('output');
%     title('mu-law compression');
%  
%   References:
%     S. Jayant and P. Noll. Digital Coding of Waveforms: Principles and
%     Applications to Speech and Video. Prentice Hall, 1990.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/auditory/rangecompress.html}
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

if nargin<1
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.flags.method={'mulaw','alaw'};
definput.keyvals.mu=255;
definput.keyvals.A=87.7;
[flags,kv]=ltfatarghelper({},definput,varargin);

if flags.do_mulaw
  tmp = log(1+kv.mu);
  
  sigweight = max(abs(insig(:)));
  outsig = sign(insig) .* log(1+kv.mu*abs(insig))/tmp;

end;

if flags.do_alaw
  absx=abs(insig);
  tmp=1+log(kv.A);
  mask=absx<1/kv.A;

  outsig = sign(insig).*(mask.*kv.A.*absx./tmp+(1-mask).*(1+log(kv.A*absx))/tmp);
end;


