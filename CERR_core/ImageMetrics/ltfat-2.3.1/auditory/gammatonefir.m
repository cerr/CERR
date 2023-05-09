function b=gammatonefir(fc,fs,varargin);
%-*- texinfo -*-
%@deftypefn {Function} gammatonefir
%@verbatim
%GAMMATONEFIR  Gammatone filter coefficients
%   Usage: b = gammatonefir(fc,fs,n,betamul);
%          b = gammatonefir(fc,fs,n);
%          b = gammatonefir(fc,fs);
%
%   Input parameters:
%      fc    :  center frequency in Hz.
%      fs    :  sampling rate in Hz.
%      n     :  max. filter length.
%      beta  :  bandwidth of the filter.
%
%   Output parameters:
%      b     :  FIR filters as an cell-array of structs.
%
%   GAMMATONEFIR(fc,fs,n,betamul) computes the filter coefficients of a
%   digital FIR gammatone filter with length at most n, center 
%   frequency fc, 4th order rising slope, sampling rate fs and 
%   bandwith determined by betamul. The bandwidth beta of each filter
%   is determined as betamul times AUDFILTBW of the center frequency
%   of corresponding filter. The actual length of the inpulse response
%   depends on fc (the filter is longer for low center frequencies),
%   fs and betamul but it is never bigger than n.
%
%   GAMMATONEFIR(fc,fs,n) will do the same but choose a filter bandwidth
%   according to Glasberg and Moore (1990).  betamul is choosen to be 1.0183.
%
%   GAMMATONEFIR(fc,fs) will do as above and choose a sufficiently long
%   filter to accurately represent the lowest subband channel.
%
%   If fc is a vector, each entry of fc is considered as one center
%   frequency, and the corresponding coefficients are returned as column
%   vectors in the output.
%
%   The inpulse response of the gammatone filter is given by
%
%       g(t) = a*t^(4-1)*cos(2*pi*fc*t)*exp(-2*pi*beta*t)
%
%   The gammatone filters as implemented by this function generate
%   complex valued output, because the filters are modulated by the
%   exponential function. Using real on the output will give the
%   coefficients of the corresponding cosine modulated filters.
%
%   To create the filter coefficients of a 1-erb spaced filter bank using
%   gammatone filters use the following construction:
%
%     g = gammatonefir(erbspacebw(flow,fhigh),fs);
%
%
%  
%   References:
%     A. Aertsen and P. Johannesma. Spectro-temporal receptive fields of
%     auditory neurons in the grassfrog. I. Characterization of tonal and
%     natural stimuli. Biol. Cybern, 38:223--234, 1980.
%     
%     B. R. Glasberg and B. Moore. Derivation of auditory filter shapes from
%     notched-noise data. Hearing Research, 47(1-2):103, 1990.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/auditory/gammatonefir.html}
%@seealso{erbspace, audspace, audfiltbw, demo_auditoryfilterbank}
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
  
%   AUTHOR : Peter L. Soendergaard

% ------ Checking of input parameters ---------

if nargin<2
  error('Too few input arguments.');
end;

if ~isnumeric(fs) || ~isscalar(fs) || fs<=0
  error('%s: fs must be a positive scalar.',upper(mfilename));
end;

if ~isnumeric(fc) || ~isvector(fc) || any(fc<0) || any(fc>fs/2)
  error(['%s: fc must be a vector of positive values that are less than half ' ...
         'the sampling rate.'],upper(mfilename));
end;

definput.import={'normalize'};
definput.importdefaults={'null'};
definput.flags.real={'complex','real'};
definput.keyvals.n=[];
definput.flags.phase={'causalphase','peakphase'};

definput.keyvals.betamul=1.0183;

[flags,keyvals,n,betamul]  = ltfatarghelper({'n','betamul'},definput,varargin);

nchannels = length(fc);

% ourbeta is used in order not to mask the beta function.

ourbeta = betamul*audfiltbw(fc);

if isempty(n)
  % Calculate a good value for n
  % FIXME actually do this
  n=5000;
end;

b=cell(nchannels,1);

for ii = 1:nchannels

  delay = 3/(2*pi*ourbeta(ii));
  
  scalconst = 2*(2*pi*ourbeta(ii))^4/factorial(4-1)/fs;
  
  nfirst = ceil(fs*delay);
  
  if nfirst>n/2
    error(['%s: The desired filter length is too short to accomodate the ' ...
           'beginning of the filter. Please choose a filter length of ' ...
           'at least %i samples.'],upper(mfilename),nfirst*2);
  end;
  
  nlast = floor(n/2);

  t=[(0:nfirst-1)/fs-nfirst/fs+delay,(0:nlast-1)/fs+delay].';  

  % g(t) = a*t^(n-1)*cos(2*pi*fc*t)*exp(-2*pi*beta*t)
  if flags.do_real
    bwork = scalconst*t.^(4-1).*cos(2*pi*fc(ii)*t).*exp(-2*pi* ...
                                                      ourbeta(ii)*t);
  else
    bwork = scalconst*t.^(4-1).*exp(2*pi*i*fc(ii)*t).*exp(-2*pi* ...
                                                      ourbeta(ii)*t);
  end;

  if flags.do_peakphase
    bwork=bwork*exp(-2*pi*i*fc(ii)*delay);
  end;

  
  % Insert zeros before the start of the signal.
  %bwork = fftshift([bwork(1:nlast);zeros(n-nlast-nfirst,1);bwork(nlast+1:nlast+nfirst)]);
    
  bwork = normalize(bwork,flags.norm);  
  b{ii} = struct('h',bwork,'offset',-nfirst,'realonly',0);
end;


