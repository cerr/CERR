function c = gga(f,fvec,fs,dim)
%-*- texinfo -*-
%@deftypefn {Function} gga
%@verbatim
%GGA Generalized Goertzel algorithm
%   Usage:  c = gga(x,fvec)
%           c = gga(x,fvec,fs)
%
%   Input parameters:
%         x      : Input data.
%         fvec   : Indices to calculate. 
%         fs     : Sampling frequency.
%
%   Output parameters:
%         c      : Coefficient vector.
%
%   c=GGA(f,fvec) computes the discrete-time fourier transform DTFT of
%   f at frequencies in fvec as c(k)=F(2pi f_{vec}(k)) where
%   F=DTFT(f), k=1,dots K and K=length(fvec) using the generalized
%   second-order Goertzel algorithm. Thanks to the generalization, values
%   in fvec can be arbitrary numbers in range 0-1 and not restricted to
%   l/Ls, l=0,dots Ls-1 (usual DFT samples) as the original Goertzel 
%   algorithm is. Ls is the length of the first non-singleton dimension
%   of f. If fvec is empty or ommited, fvec is assumed to be
%   (0:Ls-1)/Ls and results in the same output as fft.
%
%   c=GGA(f,fvec,fs) computes the same with fvec in Hz relative to fs.
%
%   The input f is processed along the first non-singleton dimension or
%   along dimension dim if specified.
%
%   *Remark:**
%   Besides the generalization the algorithm is also shortened by one
%   iteration compared to the conventional Goertzel.
%
%   Examples:
%   ---------
%   
%   Calculating DTFT samples of interest:
% 
%     % Generate input signal
%     fs = 8000;
%     L = 2^10;
%     k = (0:L-1).';
%     freq = [400,510,620,680,825];
%     phase = [pi/4,-pi/4,-pi/8,pi/4,-pi/3];
%     amp = [5,3,4,1,2];
%     f = arrayfun(@(a,f,p) a*sin(2*pi*k*f/fs+p),...
%                  amp,freq,phase,'UniformOutput',0);
%     f = sum(cell2mat(f),2);
% 
%     % This is equal to fft(f)
%     ck = gga(f);
% 
%     %GGA to FFT error:
%     norm(ck-fft(f))
% 
%     % DTFT samples at 400,510,620,680,825 Hz
%     ckgga = gga(f,freq,fs);
% 
%     % Plot modulus of coefficients
%     figure(1);clf;hold on;
%     stem(k/L*fs,2*abs(ck)/L,'k');
%     stem(freq,2*abs(ckgga)/L,'r:');
%     set(gca,'XLim',[freq(1)-50,freq(end)+50]);
%     set(gca,'YLim',[0 6]);
%     xlabel('f[Hz]');
%     ylabel('|c(k)|');
%     hold off;
% 
%     % Plot phase of coefficients
%     figure(2);clf;hold on;
%     stem(k/L*fs,angle(ck),'k');
%     stem(freq,angle(ckgga),'r:');
%     set(gca,'XLim',[freq(1)-50,freq(end)+50]);
%     set(gca,'YLim',[-pi pi]);
%     xlabel('f[Hz]');
%     ylabel('angle(c(k))');
%     hold off;
%
%
%   References:
%     P. Sysel and P. Rajmic. Goertzel algorithm generalized to non-integer
%     multiples of fundamental frequency. EURASIP Journal on Advances in
%     Signal Processing, 2012(1):56, 2012.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/gga.html}
%@seealso{chirpzt}
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
       
% The original copyright goes to
% 2013 Pavel Rajmic, Brno University of Technology, Czech Rep.


%% Check the input arguments
if nargin < 1
    error('%s: Not enough input arguments.',upper(mfilename))
end

if isempty(f)
    error('%s: X must be a nonempty vector or a matrix.',upper(mfilename))
end

if nargin<4
  dim=[];  
end;

if nargin<3 || isempty(fs)
  fs=1;  
end;

[f,~,Ls,~,dim,permutedsize,order]=assert_sigreshape_pre(f,[],dim,'GGA');

if nargin > 1 && ~isempty(fvec)
   if ~isreal(fvec) || ~isvector(fvec)
      error('%s: INDVEC must be a real vector.',upper(mfilename))
   end
else
   fvec = (0:Ls-1)/Ls;
end

c = comp_gga(f,fvec/fs*Ls);

permutedsize(1)=numel(fvec);

c=assert_sigreshape_post(c,dim,permutedsize,order);


