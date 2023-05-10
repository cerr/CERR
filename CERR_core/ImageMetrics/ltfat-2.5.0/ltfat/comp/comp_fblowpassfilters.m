function [gout, info] = comp_fblowpassfilters(winCell, gout, a, L, info, scales, scal, delayvec, lowpass_at_zero, kv,flags)

scales_sorted = sort(scales,'descend');
lowpass_number = numel(delayvec);

if flags.do_single % Compute single lowpass from frequency response
    lowpass_bandwidth = 0.2/scales_sorted(4); % Twice the center frequency of the fourth scale
    taper_ratio = 1-scales_sorted(4)/scales_sorted(2); % Plateau width is twice the center frequency of the second scale
    [glow,infolow] = wavelet_lowpass(gout,a,L,lowpass_bandwidth,taper_ratio,scal(1),flags);
    glow.delay = delayvec(1);
    gout = [{glow},gout];
    fields = fieldnames(info);
    for kk = 1:length(fields) % Concatenate info and infolow
            info.(fields{kk}) = [infolow.(fields{kk}),info.(fields{kk})];
    end
elseif flags.do_repeat % Lowpass filters are created by repeating smallest scale wavelet with shifted center frequency
    
    [glow,infolow] = wavelet_lowpass_repeat(winCell,scales_sorted(1:2),L,delayvec,lowpass_number,lowpass_at_zero,scal(1:lowpass_number),kv,flags);
    gout = [glow,gout];
    fields = fieldnames(info);
    if flags.do_complex  
        [ghigh,infohigh] = wavelet_lowpass_repeat(winCell,-scales_sorted(1:2),L,delayvec,lowpass_number,lowpass_at_zero,scal(end:-1:end-lowpass_number+1),kv,flags);
        gout = [gout,ghigh];
        for kk = 1:length(fields) % Concatenate info with infolow and infohigh
                info.(fields{kk}) = [infolow.(fields{kk}),info.(fields{kk}),infohigh.(fields{kk})];
        end
    else
        for kk = 1:length(fields) % Concatenate info and infolow
                info.(fields{kk}) = [infolow.(fields{kk}),info.(fields{kk})];
        end
    end
elseif flags.do_none % No lowpass, do nothing
    %Do nothing
else
    error('%s: This should not happen.',upper(mfilename));
end
end

%% Lowpass filters
%
%   Url: http://ltfat.github.io/doc/comp/comp_fblowpassfilters.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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
function [glow,infolow] = wavelet_lowpass(g,a,L,lowpass_bandwidth,taper_ratio,scal,flags)

Lw = @(L) min(ceil(lowpass_bandwidth*L),L);

% Compute tapered window
P0 = blfilter({'hann','taper',taper_ratio},lowpass_bandwidth,'fs',2,'inf');
% Compute the necessary compensation of the filterbank response
if flags.do_real
    temp_fbresp = @(L) filterbankresponse(g,a(2:end,:),L,'real');
else
    temp_fbresp = @(L) filterbankresponse(g,a(2:end,:),L);
end
Hinv = @(L) sqrt(max(temp_fbresp(L))-temp_fbresp(L));

% Compute the final low-pass filter
glow.H = @(L) fftshift(long2fir(...
filterbankfreqz(P0,1,L).*Hinv(L),Lw(L)))*scal; 
glow.foff = @(L) -floor(Lw(L)/2);
glow.realonly = 0;
glow.delay = 0;

% Initialize and populate infolow
infolow = struct();
infolow.fc = 0;
infolow.foff = glow.foff(L);
infolow.fsupp = Lw(L);
infolow.basefc = 0; % This value has no meaning and is only assigned to prevent errors.
infolow.scale = 0; % This value has no meaning and is only assigned to prevent errors.
infolow.dilation = 0; % This value has no meaning and is only assigned to prevent errors.
infolow.bw = lowpass_bandwidth;
infolow.tfr = 1; % This value has no meaning and is only assigned to prevent errors.
infolow.aprecise = lowpass_bandwidth*L;
infolow.a_natural = [L ceil(infolow.aprecise)];
infolow.a_natural = infolow.a_natural';
infolow.cauchyAlpha = 1; % This value has no meaning and is only assigned to prevent errors.

end

function [glow,infolow] = wavelet_lowpass_repeat(winCell,scales_sorted,L,delayvec,lowpass_number,lowpass_at_zero,scal,kv,flags)

% Compute frequency range to be covered and step between lowpass filters
LP_range = 0.1/scales_sorted(1);
LP_step = abs(0.1/scales_sorted(2)-LP_range);

% Distinguish between positive and negative scales
if scales_sorted(1)>0
    [glow,infolow] = freqwavelet(winCell,L,repmat(scales_sorted(1),1,lowpass_number),...
        'asfreqfilter','efsuppthr',kv.trunc_at,'basefc',0.1,'scal',scal, flags.norm);
    %if ~iscell(glow)
    %    glow = {glow};
    %end
    for kk = 1:lowpass_number % Correct foff
        %Flooring sometimes introduces rounding problems when the filter is
        %too slim. 
        %glow{lowpass_number-kk+1}.foff = @(L) glow{lowpass_number-kk+1}.foff(L) - floor(L*kk*LP_step/2);
        glow{lowpass_number-kk+1}.foff = @(L) glow{lowpass_number-kk+1}.foff(L) - round(L*kk*LP_step/2);
        glow{kk}.delay = delayvec(kk);
        infolow.foff(lowpass_number-kk+1) = glow{lowpass_number-kk+1}.foff(L);
    end
    infolow.fc = LP_range-(lowpass_number:-1:1)*LP_step; % Correct fc
    %if infolow.fc(1) < LP_step/2 %Experimental
    %    glow{1}.H = @(L) glow{1}.H(L)/sqrt(2);
    %end
elseif scales_sorted(1)<0
    if lowpass_at_zero
        lowpass_number = lowpass_number-1;
    end
    [glow,infolow] = freqwavelet(winCell,L,repmat(scales_sorted(1),1,lowpass_number),...
        'asfreqfilter','efsuppthr',kv.trunc_at,'basefc',0.1,'scal',scal,'negative',flags.norm);
    if ~iscell(glow)
        glow = {glow};
    end
    for kk = 1:lowpass_number % Correct foff
        glow{kk}.foff = @(L) glow{kk}.foff(L) + floor(L*kk*LP_step/2);
        infolow.foff(kk) = glow{kk}.foff(L);
    end
    infolow.fc = LP_range+(1:lowpass_number)*LP_step; % Correct fc   
else
    error('%s: This should not happen.',upper(mfilename));
end

if numel(infolow.fc) == 0 % This value has no meaning and is only assigned to prevent errors.
    infolow.cauchyAlpha = [];
end

% Correction of TFR
%infolow.tfr = @(L) ones(LP_num,1); %This should be unnecessary, as infolow.tfr is expected to be correct.
  
end

