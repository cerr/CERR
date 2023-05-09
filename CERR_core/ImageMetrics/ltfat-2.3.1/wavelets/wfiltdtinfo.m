function wfiltdtinfo(dw,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wfiltdtinfo
%@verbatim
%WFILTDTINFO Plots dual-tree filters info
%   Usage: wfiltdtinfo(dw);
%
%   Input parameters:
%         dw     : Wavelet dual-tree filterbank
%
%   WFILTDTINFO(w) plots impulse responses, frequency responses and 
%   approximation of the scaling and of the wavelet function(s) associated
%   with the dual-tree wavelet filters defined by w in a single figure. 
%   Format of dw is the same as in DTWFB.
%
%   The figure is organized as follows:
%
%   First row shows impulse responses of the first (real) tree.
%
%   Second row shows impulse responses of the second (imag) tree.
%
%   Third row contains plots of real (green), imaginary (red) and absolute 
%   (blue) parts of approximation of scaling and wavelet function(s).
%
%   Fourth and fifth row show magnitude and phase frequency responses 
%   respectivelly of filters from rows 1 and 2 with matching colors.
%
%   Optionally it is possible to define scaling of the y axis of the
%   frequency seponses. Supported are:
%
%   'db','lin'   
%       dB or linear scale respectivelly. By deault a dB scale is used.
%
%   Examples:
%   ---------
%   :
%      wfiltdtinfo('qshift4');
%   
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfiltdtinfo.html}
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

complainif_notenoughargs(nargin,1,'WFILTDTINFO');


definput.flags.freqzscale = {'db','lin'};
[flags]=ltfatarghelper({},definput,varargin);


[dwstruct,info] = dtwfbinit({'strict',{dw,6,'dwt'}});
dw = info.dw;

filtNo = size(dw.g,1);
grayLevel = [0.6,0.6,0.6];
clf;

colorAr ={repmat('rbk',1,filtNo),repmat('cmg',1,filtNo)};

for ii=1:2
    subplot(5,filtNo,filtNo*(ii-1)+1);
    title(sprintf('Scaling imp. response, tree %i',ii));
    loAna = dw.g{1,ii}.h;
    loShift = -dw.g{1,ii}.offset;
    xvals = -loShift + (0:length(loAna)-1);
    hold on;
    if ~isempty(loAna(loAna==0))
       stem(xvals(loAna==0),loAna(loAna==0),'Color',grayLevel);
    end

    loAnaNZ = find(loAna~=0);
    stem(xvals(loAnaNZ),loAna(loAnaNZ),colorAr{ii}(1));
    axis tight;
    hold off;
end

for ii=1:2
    for ff=2:filtNo
        subplot(5,filtNo,ff+filtNo*(ii-1));
        title(sprintf('Wavelet imp. response no: %i, tree %i',ff-1,ii));
        filtAna = dw.g{ff,ii}.h;
        filtShift = -dw.g{ff,ii}.offset;
        xvals = -filtShift + (0:length(filtAna)-1);
        filtNZ = find(filtAna~=0);
        hold on;

        if ~isempty(filtAna(filtAna==0))
           stem(xvals(filtAna==0),filtAna(filtAna==0),'Color',grayLevel);
        end

        stem(xvals(filtNZ),filtAna(filtNZ),colorAr{ii}(ff));
        axis tight;
        hold off;
    end
end

L =  wfbtlength(1024,dwstruct,'per');
Lc = wfbtclength(L,dwstruct,'per');
c = wavpack2cell(zeros(sum([Lc;Lc(end:-1:1)]),1),...
                 [Lc;Lc(end:-1:1)]);
c{1}(1) = 1;
sfn = idtwfb(c,dwstruct,L);

subplot(5,filtNo,[2*filtNo+1]);
xvals = ((-floor(L/2)+1:floor(L/2)).');
plot(xvals,fftshift([abs(sfn),real(sfn),imag(sfn)],1));
axis tight;
title('Scaling function');

%legend({'abs','real','imag'},'Location','south','Orientation','horizontal')

for ff=2:filtNo
   subplot(5,filtNo,[2*filtNo+ff]);
   
   c{ff-1}(1) = 0;
   c{ff}(1) = 1;
   wfn = idtwfb(c,dwstruct,L);
   
   plot(xvals,fftshift([abs(wfn),real(wfn),imag(wfn)],1));
   axis tight;
   %legend({'abs','real','imag'},'Location','south','Orientation','horizontal')
   title(sprintf('Wavelet function: %i',ff-1));
end


subplot(5,filtNo,3*filtNo + (1:filtNo) );
title('Magnitude frequency response');
maxLen=max(cellfun(@(gEl) numel(gEl.h),dw.g));
Ls = nextfastfft(max([maxLen,1024]));
H = filterbankfreqz(dw.g(:),[dw.a(:);dw.a(:)],Ls);



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
for ii=1:2
for ff=1:filtNo
   plot(xVals,plotH(:,ff+(ii-1)*filtNo),colorAr{ii}(ff));
   axis tight;
end
end
if flags.do_db
    ylim([-30,max(plotH(:))])
end
ylabel('|\itH|[dB]');
xlabel('\omega [-]')
hold off;

subplot(5,filtNo,4*filtNo + (1:filtNo) );
title('Phase frequency response');
hold on;
for ii=1:2
for ff=1:filtNo
   plot(xVals,unwrap(angle((H(:,ff+(ii-1)*filtNo))))/pi,colorAr{ii}(ff));
   axis tight;
end
end
ylabel('arg H(\omega)[\pi rad]');
xlabel('\omega [-]')

axis tight;
% plot(unwrap(angle([H])));
% axis tight;
hold off;

