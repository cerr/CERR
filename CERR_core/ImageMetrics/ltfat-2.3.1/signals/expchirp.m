function [outsig]=expchirp(L,fstart,fend,varargin)
%-*- texinfo -*-
%@deftypefn {Function} expchirp
%@verbatim
%EXPCHIRP  Exponential chirp
%   Usage: outsig=expchirp(L,fstart,fend)
%
%   EXPCHIRP(L,fstart,fend) computes an exponential chirp of length L*
%   starting at frequency fstart and ending at frequency fend. The
%   freqencies are assumed to be normalized to the Nyquist frequency.
%
%   EXPCHIRP takes the following parameters at the end of the line of input
%   arguments:
%
%     'fs',fs    Use a sampling frequency of fs Hz. If this option is
%                specified, fstart and fend will be measured in Hz.
%
%     'phi',phi  Starting phase of the chirp. Default value is 0.
%
%     'fc',fc    Shift the chirp by fc in frequency. Default values is 0.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/expchirp.html}
%@seealso{pchirp}
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

% AUTHORS:  Piotr Majdak, Peter L. Soendergaard.

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

thismfilename = upper(mfilename);
complainif_notposint(L,'L',thismfilename);

if ~all(cellfun(@isscalar,{fstart,fend})) || ...
    any(cellfun(@(el) el<=0,{fstart,fend}))
    error('%s: fstart and fend must be scalars strictly greater than 0.',...
          thismfilename);
end

definput.keyvals.phi=0;
definput.keyvals.fs=[];
definput.keyvals.fc=0;

[~,kv]=ltfatarghelper({},definput,varargin);

if ~isempty(kv.fs)
  fstart=fstart/kv.fs*2;
  fend  =  fend/kv.fs*2;
  kv.fc = kv.fc/kv.fs*2;
end;

w1=pi*fstart*L;
w2=pi*fend*L;

ratio = w2/w1;

A=w1/log(ratio);
tau=1/log(ratio);

l = 0:L-1; l = l(:);
t= l./L;
outsig=exp(1i*A*(exp(t/tau)-1)+kv.phi + 1i*pi*l*kv.fc);


