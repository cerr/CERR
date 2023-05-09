function wfiltinfo(w,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wfiltinfo
%@verbatim
%WFILTINFO Plots filters info
%   Usage: wfiltinfo(w);
%
%   Input parameters:
%         w     : Basic wavelet filterbank.
%
%   WFILTINFO(w) plots impulse responses, frequency responses and 
%   approximation of the scaling and of the wavelet function(s) associated
%   with the wavelet filters defined by w in a single figure. Format of 
%   w is the same as in FWT.
%
%   Optionally it is possible to define scaling of the y axis of the
%   frequency seponses. Supported are:
%
%   'db','lin'   
%       dB or linear scale respectivelly. By deault a dB scale is used.
%
%   Examples:
%   ---------
%   
%   Details of the 'syn:spline8:8' wavelet filters (see WFILT_SPLINE):
%   
%      wfiltinfo('syn:spline8:8');
%   
%   Details of the 'ana:spline8:8' wavelet filters:
%
%      wfiltinfo('ana:spline8:8');
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfiltinfo.html}
%@seealso{wfilt_db}
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

% AUTHOR: Zdenek Prusa

definput.flags.freqzscale = {'db','lin'};
[flags]=ltfatarghelper({},definput,varargin);


w = fwtinit({'strict',w});
clf;

filtNo = length(w.g);
grayLevel = [0.6,0.6,0.6];


colorAr = repmat('rbkcmg',1,filtNo);

subplot(4,filtNo,1);
title('Scaling imp. response');
loAna = w.g{1}.h;
loShift = -w.g{1}.offset;
xvals = -loShift + (0:length(loAna)-1);
hold on;
if ~isempty(loAna(loAna==0))
   stem(xvals(loAna==0),loAna(loAna==0),'Color',grayLevel);
end

loAnaNZ = find(loAna~=0);
stem(xvals(loAnaNZ),loAna(loAnaNZ),colorAr(1));
axis tight;
hold off;

for ff=2:filtNo
    subplot(4,filtNo,ff);
    title(sprintf('Wavelet imp. response no: %i',ff-1));
    filtAna = w.g{ff}.h;
    filtShift = -w.g{ff}.offset;
    xvals = -filtShift + (0:length(filtAna)-1);
    filtNZ = find(filtAna~=0);
    hold on;
    
    if ~isempty(filtAna(filtAna==0))
       stem(xvals(filtAna==0),filtAna(filtAna==0),'Color',grayLevel);
    end
    
    stem(xvals(filtNZ),filtAna(filtNZ),colorAr(ff));
    axis tight;
    hold off;
end

[wfn,sfn,xvals] = wavfun(w,'fft');
subplot(4,filtNo,[filtNo+1]);

plot(xvals(:,end),sfn,colorAr(1));
axis tight;
title('Scaling function');

for ff=2:filtNo
   subplot(4,filtNo,[filtNo+ff]);
   plot(xvals(:,ff-1),wfn(:,ff-1),colorAr(ff));
   axis tight;
   title(sprintf('Wavelet function: %i',ff-1));
end

subplot(4,filtNo,2*filtNo + (1:filtNo) );
title('Magnitude frequency response');
maxLen=max(cellfun(@(gEl) numel(gEl.h),w.g));
Ls = nextfastfft(max([maxLen,1024]));
H = filterbankfreqz(w.g,w.a,Ls);

%[H] = wtfftfreqz(w.g);
if flags.do_db
   plotH = 20*log10(abs(H));
elseif flags.do_lin
   plotH = abs(H);   
else
    error('%s: Unknown parameter',upper(mfilaname));
end
xVals = linspace(0,1,numel(H(:,1)));
hold on;
for ff=1:filtNo
   plot(xVals,plotH(:,ff),colorAr(ff));
   axis tight;
end
if flags.do_db
    ylim([-30,max(plotH(:))])
end
ylabel('|\itH|[dB]');
xlabel('\omega [-]')
hold off;

subplot(4,filtNo,3*filtNo + (1:filtNo) );
title('Phase frequency response');
hold on;
for ff=1:filtNo
   plot(xVals,unwrap(angle((H(:,ff))))/pi,colorAr(ff));
   axis tight;
end
ylabel('arg H(\omega)[\pi rad]');
xlabel('\omega [-]')

axis tight;
% plot(unwrap(angle([H])));
% axis tight;
hold off;

