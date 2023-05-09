function c = chirpzt(f,K,fdiff,foff,fs,dim)
%-*- texinfo -*-
%@deftypefn {Function} chirpzt
%@verbatim
%CHIRPZT Chirped Z-transform
%   Usage:  c = chirpzt(f,K,fdiff)
%           c = chirpzt(f,K,fdiff,foff)
%           c = chirpzt(f,K,fdiff,foff,fs)
%
%   Input parameters:
%         f      : Input data.
%         K      : Number of values.
%         fdiff  : Frequency increment.
%         foff   : Starting frequency. 
%         fs     : Sampling frequency. 
%
%   Output parameters:
%         c      : Coefficient vector.
%
%   c = CHIRPZT(f,K,fdiff,foff) computes K samples of the discrete-time 
%   fourier transform DTFT c of f at values c(k+1)=F(2pi(f_{off}+kf_{diff}))
%   for k=0,dots,K-1 where F=DTFT(f). Values foff and fdiff should
%   be in range of 0-1. If foff is ommited or empty, it is considered to
%   be 0. If fdiff is ommited or empty, K equidistant values 
%   c(k+1)=F(2pi k/K) are computed. If even K is ommited or empty, 
%   input length is used instead resulting in the same values as fft does.
%
%   c = CHIRPZT(f,K,fdiff,foff,fs) computes coefficients using frequency 
%   values relative to fs c(k+1)=F(2pi(f_{off}+kf_{diff})/fs) for k=0,dots,K-1.
%
%   The input f is processed along the first non-singleton dimension or
%   along dimension dim if specified.
%
%   Examples:
%   ---------
%   
%   Calculating DTFT samples of interest (aka zoom FFT):
% 
%     % Generate input signal
%     fs = 8000;
%     L = 2^10;
%     k = (0:L-1).';
%     f1 = 400;
%     f2 = 825;
%     f = 5*sin(2*pi*k*f1/fs + pi/4) + 2*sin(2*pi*k*f2/fs - pi/3);
%
%     % This is equal to fft(f)
%     ck = chirpzt(f,L);
%
%     %chirpzt to FFT error:
%     norm(ck-fft(f))
%
%     % Frequency "resolution" in Hz
%     fdiff = 0.4;
%     % Frequency offset in Hz
%     foff = 803.9;
%     % Number of frequency values
%     K = 125;
%     % DTFT samples. The frequency range of interest is 803.9-853.5 Hz
%     ckchzt = chirpzt(f,K,fdiff,foff,fs);
%
%     % Plot modulus of coefficients
%     figure(1);
%     fax=foff+fdiff.*(0:K-1);
%     hold on;
%     stem(k/L*fs,abs(ck),'k');
%     stem(fax,abs(ckchzt),'r:');
%     set(gca,'XLim',[foff,foff+K*fdiff]);
%     set(gca,'YLim',[0 1065]);
%     xlabel('f[Hz]');
%     ylabel('|ck|');
%
%     % Plot phase of coefficients
%     figure(2);
%     hold on;
%     stem(k/L*fs,angle(ck),'k');
%     stem(fax,angle(ckchzt),'r:');
%     set(gca,'XLim',[foff,foff+K*fdiff]);
%     set(gca,'YLim',[-pi pi]);
%     xlabel('f[Hz]');
%     ylabel('angle(ck)');
%
%
%   References:
%     L. Rabiner, R. Schafer, and C. Rader. The chirp Z-transform algorithm.
%     Audio and Electroacoustics, IEEE Transactions on, 17(2):86--92, 1969.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/chirpzt.html}
%@seealso{gga}
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

%% Check the input arguments
if nargin < 1
    error('%s: Not enough input arguments.',upper(mfilename))
end

if isempty(f)
    error('%s: X must be a nonempty vector or a matrix.',upper(mfilename))
end

if nargin<6
  dim=[];  
end;

[f,~,Ls,~,dim,permutedsize,order]=assert_sigreshape_pre(f,[],dim,'CHIRPZT');

if nargin > 1  && ~isempty(K)
   if ~isreal(K) || ~isscalar(K) || rem(K,1)~=0
      error('%s: K must be a real integer.',upper(mfilename))
   end
else
   K = size(f,1);
end

if nargin > 2  && ~isempty(fdiff)
   if ~isreal(K) || ~isscalar(K)
      error('%s: fdiff must be a real scalar.',upper(mfilename))
   end
else
   fdiff = 1/K;
end

if nargin > 3  && ~isempty(foff)
   if ~isreal(K) || ~isscalar(K)
      error('%s: foff must be a real scalar.',upper(mfilename))
   end
else
   foff = 0;
end

if nargin > 4  && ~isempty(fs)
   if ~isreal(fs) || ~isscalar(fs)
      error('%s: fs must be a real scalar.',upper(mfilename))
   end
else
   fs = 1;
end


c = comp_chirpzt(f,K,2*pi*fdiff/fs,2*pi*foff/fs);


permutedsize(1)=K;
c=assert_sigreshape_post(c,dim,permutedsize,order);


