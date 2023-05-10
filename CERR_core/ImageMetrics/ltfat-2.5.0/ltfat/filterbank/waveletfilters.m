function [gout,a,fc,L,info] = waveletfilters(Ls, scales, varargin)
%WAVELETFILTERS Generates wavelet filters
%   Usage: [gout,a,fc,L,info] = waveletfilters(Ls,scales)
%          [gout,a,fc,L,info] = waveletfilters(Ls,'bins', fs, fmin, fmax, bins)
%          [gout,a,fc,L,info] = waveletfilters(Ls,'linear', fs, fmin, fmax, channels)
%
%   Input parameters:
%         Ls     : System length
%         scales : Vector of wavelet scales
%   Output parameters:
%         gout  : Cell arrary of wavelet filters
%         a     : Downsampling rate for each channel.
%         fc    : Center frequency of each channel.
%         L     : Next admissible length suitable for the generated filters.
%         info  : Struct with additional outputs
%
%   WAVELETFILTERS(Ls,scales) constructs a system of wavelet filters covering 
%   scales in the range scales for system length Ls. A scale of 1 corresponds 
%   to a wavelet filter with peak positioned at the frequency 0.1 relative 
%   to the Nyquist rate.
%
%   [g,a,fc]=WAVELETFILTERS(Ls, 'bins', fs,fmin,fmax,bins) constructs a set of
%   wavelets g which cover the required frequency range
%   fmin-fmax with bins filters per octave starting at fmin. All
%   filters have (approximately) equal Q=f_c/f_b. The
%   frequency interval below fmin not covered by these is captured
%   by additional lowpass filter(s) . The signal length Ls*
%   is mandatory, since we need to avoid too narrow frequency windows
%
%   [g,a,fc]=WAVELETFILTERS(Ls, 'linear', fs, fmin, fmax, channels) constructs 
%    a set of wavelets g which cover the required frequency range
%   fmin-fmax with channels equidistantly spaced filters starting at fmin.
%
%   Wavelet types
%   --------------------
%
%   The following wavelets can be passed as a flag:
%
%   'cauchy'     Cauchy wavelet (default parameters [alpha beta gamma] = [300 0 3])
%
%   'morse'      Generalized morse wavelet (default parameters [alpha beta gamma] = [300 0 3])
%
%   'morlet'     Morlet wavelet (default parameters sigma = [4])
%
%   'fbsp'       Frequency B-spline wavelet (default parameters [order fb] = [4 2])
%
%   'analyticsp' Analytic spline wavelet (default parameters [order fb] = [4 2])
%
%   'cplxsp'     Complex spline wavelet (default parameters [order fb] = [4 2])
%
%   A scale of 1 corresponds
%   to a wavelet filter with peak positioned at the frequency 0.1 relative
%   to the Nyquist rate. By default, this function does not allow center frequencies
%   exceeding the Nyquist rate, except with the optional parameter 'analytic',
%   see below. This implies that scales below 0.1 (or 0.05 for the 'analytic' scheme)
%   are not supported.
%   For more details on the construction of the wavelets and the available
%   wavelet types, please see FREQWAVELET. 
%
%   By default, wavelet filters are peak normalized before being adjusted
%   to the proposed downsampling factor. The peak normalization can be 
%   overridden by forwarding any norm flag accepted by SETNORM.
%
%   Downsampling factors
%   --------------------
%
%   The integer downsampling rates of the channels must all divide the
%   signal length, FILTERBANK will only work for input signal lengths
%   being multiples of the least common multiple of the downsampling rates.
%   See the help of FILTERBANKLENGTH. 
%   The fractional downsampling rates restrict the filterbank to a single
%   length L=Ls.
%
%   [gout,a]=WAVELETFILTERS(...,'regsampling') constructs a non-uniform
%   filterbank with integer subsampling factors. This is the default.
%
%   [gout,a]=WAVELETFILTERS(...,'uniform') constructs a uniform filterbank
%   where the integer downsampling rate is the same for all the channels. This
%   results in the most redundant representation which produces nice plots.
%
%   [gout,a]=WAVELETFILTERS(...,'fractional') constructs a filterbank with
%   fractional downsampling rates a. 
%   This results in the least redundant system.
%
%   [gout,a]=WAVELETFILTERS(...,'fractionaluniform') constructs a filterbank 
%   with fractional downsampling rates a, which are uniform for all filters
%   except the "filling" low-pass filter which can have different
%   fractional downsampling rates. This is useful when uniform subsampling
%   and low redundancy at the same time are desirable.
%
%   Lowpass filters
%   --------------------
%
%   [gout,a]=WAVELETFILTERS(...,'single') uses a single lowpass filter
%   for covering the range from zero frequency to the center frequency of the
%   largest scale specified. This is the default.
%
%   [gout,a]=WAVELETFILTERS(...,'repeat') constructs frequency-shifted
%   copies of the largest scale wavelet to cover the range from zero frequency 
%   to the center frequency of the largest scale specified.
%
%   [gout,a]=WAVELETFILTERS(...,'none') foregoes the construction of a
%   lowpass filter. This option cannot be expected to yield an invertible 
%   filterbank.
%
%   Additional parameters
%   ---------------------
%
%   waveletfilter accepts the following optional parameters:
%
%     'redmul',redmul    Redundancy multiplier. Increasing the value of this
%                        will make the system more redundant by lowering the
%                        channel downsampling rates. It is only used if the
%                        filterbank is a non-uniform filterbank. Default
%                        value is 1. If the value is less than one, the
%                        system may no longer be painless.
% 
%     'redtar',redtar    Target redundancy. The downsampling factors will be
%                        adjusted to achieve a redundancy as close as possible
%                        to 'redtar'.
%
%     'trunc_at',trunc_at     Applies hard thresholding of the wavelet filters 
%                             at the specified threshold value to reduce their 
%                             support size. 
%                             The default value is trunc_at=10e-5. When no 
%                             truncation is desired, trunc_at=0 should be chosen.
%
%     'delay',delay      A scalar, numeric vector of function handle that 
%                        specifies delays for the wavelet filters. A
%                        numeric vector must have at least as many entries
%                        as there are filters in the filterbank. A function
%                        handle must accept two inputs (k-1,a(k)), where 
%                        k is the channel index and a are the
%                        downsampling rates. If a function handle is given
%                        and 'redtar' is specified, delays are computed
%                        based on the final value of a.
%
%     'real'             Allows positive scales with center frequencies up 
%                        to Nyquist. This is the default.
%
%     'complex'          Allows positive scales with center frequencies up 
%                        to Nyquist, which are also mirrored to cover
%                        negative scales.
%
%     'analytic'         Allows positive scales with center frequencies up 
%                        to twice the Nyquist frequency. This setting is
%                        suitable for the analysis of analytic signals.
%
%     'startfreq'        Allows to manually set a starting frequency for
%                        the wavelet range. Can not be lower than fmin.
%
%   Examples:
%   ---------
%
%   In the first example, we analyze a glockenspiel signal with a
%   regularly sampled wavelet filterbank using a frequency B-spline
%   wavelet of order 4 and with parameter fb=3 and visualize the result:
%
%     [f,fs]=gspi;  % Get the test signal
%     Ls = length(f);
%     scales = linspace(10,0.1,100);
%     [g,a,fc,L]=waveletfilters(Ls,scales, {'fbsp', 4, 3}, 'repeat');
%     c=filterbank(f,g,a);
%     plotfilterbank(c,a,fc,fs,90);
%
%   In the second example, we construct a wavelet filterbank with a
%   lowpass channels based on a Cauchy wavelet and verify it.
%   The plot shows the frequency responses of
%   filters used for analysis (top) and synthesis (bottom). :
%
%     [f,fs]=greasy;  % Get the test signal
%     Ls = length(f);
%     M0 = 511; %Desired number of channels (without 0 Hz-lowpass channel)
%     max_freqDiv10 = 10;  % 10 corresponds to the nyquist frequency
%     freq_step = max_freqDiv10/M0;
%     rate = 44100;
%     start_index = 1;
%     min_freqHz = rate/10*freq_step
%     min_scale_freq = min_freqHz*start_index
%     min_freqDiv10 = freq_step*start_index; %1/25; % By default, the reference scale for freqwavelet has center frequency 0.1
%     scales = 1./linspace(min_freqDiv10,max_freqDiv10,M0);
%     alpha = 1-2/(1+sqrt(5)); % 1-1/(goldenratio) delay sequence
%     delays = @(n,a) a*(mod(n*alpha+.5,1)-.5);
%     CauchyAlpha = 600;
%     [g, a,fc,L,info] = waveletfilters(Ls,scales,{'cauchy',CauchyAlpha},'uniform','single','energy', 'delay',delays, 'redtar', 8);
%
%     c=filterbank(f,{'realdual',g},a);
%     r=2*real(ifilterbank(c,g,a));
%     if length(r) > length(f)
%         norm(r(1:length(f))-f)
%     else
%         norm(r-f(1:length(r)))
%      end
%     % Plot frequency responses of individual filters
%     gd=filterbankrealdual(g,a,L);
%     figure(1);
%     subplot(2,1,1);
%     filterbankfreqz(gd,a,L,fs,'plot','linabs','posfreq');
%
%     subplot(2,1,2);
%     filterbankfreqz(g,a,L,fs,'plot','linabs','posfreq');
% 
%   See also: freqwavelet, filterbank, setnorm
%
%   Url: http://ltfat.github.io/doc/filterbank/waveletfilters.html

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

% AUTHORS: Nicki Holighaus, Zdenek Prusa, Guenther Koliander, Clara Hollomey

complainif_notenoughargs(nargin,2,upper(mfilename));
complainif_notposint(Ls,'Ls',upper(mfilename));
                 
%parse input arguments:
if ~isnumeric(scales)
    fs = varargin{1};
    fmin = varargin{2};
    fmax = varargin{3};
    channels = varargin{4};
    switch scales
        case 'linear'
            definput.flags.inputmode = {'linear', 'logarithmic', 'bins', 'scales'};
        %case 'logarithmic'
        %    definput.flags.inputmode = {'logarithmic', 'bins', 'scales', 'linear'};
        case 'bins'
            definput.flags.inputmode = {'bins', 'scales', 'linear', 'logarithmic'};
        otherwise
            error('%s: second argument must either be a scales vector or define the f-mapping.',upper(mfilename))
    end
    %this is a slightly more efficient way to remove the first 4 args from
    %varargin
    varargin = circshift(varargin,-4);
    varargin = varargin(1:end-4);
else
    definput.flags.inputmode = {'scales', 'linear', 'logarithmic', 'bins'};
end

definput.import={'setnorm'};
definput.importdefaults={'null'};
definput.flags.real = {'real','complex','analytic'};
definput.flags.lowpass  = {'single','repeat','none'};
definput.flags.sampling = {'regsampling','uniform',...
                           'fractional','fractionaluniform'};
definput.flags.wavelettype = getfield(arg_freqwavelet(),'flags','wavelettype');
definput.keyvals.redmul=1;
definput.keyvals.redtar=[];
definput.keyvals.delay = 0;
definput.keyvals.trunc_at  = 10^(-5);
definput.keyvals.fs = 2;
definput.keyvals.startfreq = [];%only relevant if 'repeat'

[varargin,winCell] = arghelper_filterswinparser(definput.flags.wavelettype,varargin);
[flags,kv]=ltfatarghelper({},definput,varargin);

if isempty(winCell), winCell = {flags.wavelettype}; end

if ~isa(kv.delay,'function_handle') && ~isnumeric(kv.delay)
    error('%s: delay must be a function handle or numeric.',upper(mfilename));
end

if ~isscalar(kv.redmul) || kv.redmul <= 0
    error('%s: redmul must be a positive scalar.',upper(mfilename));
end

if ~isempty(kv.redtar)
    if ~isscalar(kv.redtar) || kv.redtar <= 0
        error('%s: redtar must be a positive scalar.',upper(mfilename));
    end
end

%parse the input format: map fmin and fmax to scales according to the input
%parameter specification
if ~flags.do_scales
    nf = fs/2;
    if flags.do_linear
        min_freq = fmin/nf *10;%map to freqwavelets nyquist f
        max_freq = fmax/nf * 10;
        scales = 1./linspace(min_freq,max_freq,channels);
  % elseif flags.do_logarithmic
%
%        fc = 2.^linspace(log2(fmin), log2(fmax), channels);    
%        fc = fc/nf * 10;   
%        scales = 1./fc;
        
    elseif flags.do_bins

        if isscalar(channels)
            % Number of octaves
            b = ceil(log2(fmax/fmin))+1;
            bins = channels*ones(b,1);
        else
            bins = channels;
        end
        
        fc = zeros(sum(bins),1);

        ll = 0;
        for kk = 1:length(bins)
            fc(ll+(1:bins(kk))) = ...
                fmin*2.^(((kk-1)*bins(kk):(kk*bins(kk)-1)).'/bins(kk));
            ll = ll+bins(kk);
        end

        % Get rid of filters with frequency centers >=fmax and nf
        % This will leave the first bigger than fmax it it is lower than nf
        temp = find(fc>=fmax ,1);
        if fc(temp) >= nf
            fc = fc(1:temp-1);
        else
            fc = fc(1:temp);
        end

        channels = length(fc);
        min_freq = fmin/nf *10;%map to freqwavelets nyquist f
        max_freq = fmax/nf * 10;
        scales = 1./linspace(min_freq,max_freq,channels);
    end
    scales_sorted = sort(scales,'descend');
    if ~isempty(kv.startfreq)%set the start frequency
        startfreq = kv.startfreq/nf * 10;
        scales_start = find(1./scales_sorted > startfreq,1,'first');%find first scale whose equiv. f is larger than fmin
        scales = scales(scales_start:end);
    end
end


if ~isnumeric(scales) || any(scales < 0.1)
   error('%s: scales must be positive and numeric.',upper(mfilename));
end
    
if size(scales,2)>1
    if size(scales,1)==1
        % scales was a row vector.
        scales=scales(:);
    else
        error('%s: scales must be a vector.',upper(mfilename));
    end
end


%% Generate mother wavelet to determine parameters from
[~,info] = freqwavelet(winCell,Ls,1,'asfreqfilter','efsuppthr',kv.trunc_at,'basefc',0.1);
basea = info.aprecise;


%% Determine total number of filters and natural subsampling factor for lowpass
%[aprecise, M, lowpass_number, lowpass_at_zero] = c_det_lowpass(Ls, scales, basea, flags, kv);
if numel(scales) < 4 && flags.do_single
    error('%s: Lowpass generation requires at least 4 scales.',upper(mfilename));
elseif numel(scales) < 2 && flags.do_repeat
    error('%s: Lowpass generation requires at least two scales.',upper(mfilename));
end

% Get number of scales and sort them
M = numel(scales);
scales_sorted = sort(scales,'descend');
%% Determine total number of filters and natural subsampling factor for lowpass
if flags.do_repeat
% Maybe adjust this to not guarantee some distance between first filter and zero frequency.
    lowpass_number = scales_sorted(2)/(scales_sorted(1)-scales_sorted(2)); 
        if abs(lowpass_number - round(lowpass_number)) < eps*10^3
            % determine if lowpass is centered around 0 Hz
            lowpass_number = round(lowpass_number);
            lowpass_at_zero = 1;
        else
            lowpass_at_zero = 0;
        end
        lowpass_number = floor(lowpass_number);
        if lowpass_number == 0
            lowpass_number = 1;
        end
        M = M + lowpass_number;
        aprecise = (basea.*scales_sorted(1))*ones(lowpass_number,1);

elseif flags.do_single
    lowpass_number = 1;
    lowpass_at_zero = 1;
    M = M+1;
    %this is an estimated value
    aprecise = (0.2./scales_sorted(4))*Ls; % This depends on how single lowpass is called (l.195ff). Maybe automate. Adapt if necessary!!!
else
    lowpass_number = 0;
    lowpass_at_zero = 0;
    aprecise = [];
end

%% Get subsampling factors
aprecise = [aprecise;basea.*scales];

if any(aprecise<1)
    error(['%s: Bandwidth of at least one of the filters is bigger than fs. '],upper(mfilename));
end

aprecise=aprecise/kv.redmul;
if any(aprecise<1)
    error('%s: The maximum redundancy mult. for this setting is %5.2f',...
         upper(mfilename), min(basea./scales));
end

%% Compute the downsampling rate
if flags.do_regsampling
    a = ones(M,1);
    
    [lower_scale,~] = max(scales);
    [upper_scale,~] = min(scales);
    lower_scale = floor(log2(1/lower_scale));
    upper_scale = floor(log2(1/upper_scale));
    
    % Find minimum a in each octave and floor23 it
    % to shrink "a" to the next composite number
    ct=1;
    for kk = lower_scale:upper_scale
        tempidx = find( floor(log2(1./scales)) == kk );
        [~,tempminidx] = min(1/scales(tempidx));
        idx = tempidx(tempminidx);
        
        % Deal the integer subsampling factors
        a(tempidx) = floor23(aprecise(idx));
        ct=ct+1;
    end   
    
    % Determine the minimal transform length lcm(a)
    L = filterbanklength(Ls,a);
    
    % Heuristic trying to reduce lcm(a)
    while L>2*Ls && ~(all(a==a(1)))
        maxa = max(a);
        a(a==maxa) = 0;
        a(a==0) = max(a);
        L = filterbanklength(Ls,a);
    end

elseif flags.do_fractional
    L = Ls;
    N=ceil(Ls./aprecise);
    a=[repmat(Ls,M,1),N];
elseif flags.do_fractionaluniform
    L = Ls;
    if lowpass_at_zero
        aprecise(2:end)= min(aprecise(2:end));
    else 
        aprecise= repmat(min(aprecise),numel(aprecise),1);
    end
    N=ceil(Ls./aprecise);
    a=[repmat(Ls,M,1),N];
elseif flags.do_uniform
    a=floor(min(aprecise));
    L=filterbanklength(Ls,a);
    a = repmat(a,M,1);
end
% Get an expanded "a" / Convert "a" to LTFAT 2-column fractional format
afull=comp_filterbank_a(a,M,struct());

%if flags.do_uniform
%    a = a(:,1);
%end
%==========================================================================
%% Adjust the downsampling rates in order to achieve 'redtar'    

if ~isempty(kv.redtar)
   if size(afull,2) == 2
        a = afull(:,1)./afull(:,2);
   else
       a = afull;
   end

    if ~flags.do_real
        org_red = sum(1./a);
    elseif lowpass_at_zero
        org_red = 1./a(1) + sum(2./a(2:end));
    else
        org_red = sum(2./a);
    end
    
    a = floor(a*org_red/kv.redtar);
    a(a==0) = 1;
    
    if ~flags.do_uniform
        N_new=ceil(L./a);
        if flags.do_complex
            N_new = [N_new;N_new(end:-1:2)];
        end
        a=[repmat(L,numel(N_new),1),N_new];
    else 
        L = filterbanklength(L,a);
        a=[a,ones(length(a), 1)];
    end
else
    a = afull;
end

%% Compute the scaling of the filters and the numeric delay vector
% Filters are scaled such that the energy of the subband coefficients
% remains approximately constant independent of the decimation factor
if isa(kv.delay,'function_handle')
    delayvec = zeros(M,1);
    for kk = 1:M
        delayvec(kk) = kv.delay(kk-1,a(kk,1)./a(kk,2));
    end
elseif numel(kv.delay) == 1
    delayvec = repmat(kv.delay,M,1);
elseif ~isempty(kv.delay) && size(kv.delay,2) > 1
    delayvec = kv.delay(:);
else
    error('%s: delay must be scaler or have enough elements to cover all channels.',upper(mfilename));
end
scal=sqrt(a(:,1)./a(:,2));

if flags.do_complex
    
    if lowpass_at_zero
       a=[a;flipud(a(2:end,:))];
       scal=[scal;flipud(scal(2:end))];
       delayvec=[delayvec;flipud(delayvec(2:end))];
    else
        a=[a;flipud(a)];
        scal=[scal;flipud(scal)];
        delayvec=[delayvec;flipud(delayvec)];
    end
    
    [gout_positive,info_positive] = freqwavelet(winCell,L,scales,...
        'asfreqfilter','efsuppthr',kv.trunc_at,'basefc',0.1,...
        'scal',scal(lowpass_number+1:M),'delay', delayvec(lowpass_number+1:M),flags.norm);
    [gout_negative,info_negative] = freqwavelet(winCell,L,-flipud(scales),...
        'asfreqfilter','efsuppthr',kv.trunc_at,'basefc',0.1,...
        'negative','scal',scal(M+1:M+numel(scales)),'delay', delayvec(M+1:M+numel(scales)), flags.norm);
    gout = [gout_positive,gout_negative];
    fields = fieldnames(info_positive);
    info = struct();
    for kk = 1:length(fields)
            info.(fields{kk}) = [info_positive.(fields{kk}),info_negative.(fields{kk})];
    end
elseif flags.do_analytic
    [gout,info] = freqwavelet(winCell,L,scales,...
        'asfreqfilter','efsuppthr',kv.trunc_at,'basefc',0.1,...
        'analytic','scal',scal(lowpass_number+1:M),'delay', delayvec(lowpass_number+1:M),flags.norm);
else
    if lowpass_at_zero
        % Scale the lowpass filters
        scal(1)=scal(1)/sqrt(2);
    end
    
    [gout,info] = freqwavelet(winCell,L,scales,'asfreqfilter','efsuppthr',...
        kv.trunc_at,'basefc',0.1,'scal',scal(lowpass_number+1:M),'delay', delayvec(lowpass_number+1:M),flags.norm);
end
    
%% Generate lowpass filters if desired
[gout, info] = comp_fblowpassfilters(winCell, gout, a, L, info, scales, scal, delayvec(1:lowpass_number), lowpass_at_zero, kv, flags);

info.lowpassstart = lowpass_number + 1;%startindex of actual wavelets (tentative)
% Assign fc and adjust for sampling rate 
if flags.do_scales
    fc = (kv.fs/2).*info.fc;
else
    fc = nf.*info.fc;
end

if flags.do_uniform || flags.do_regsampling
    a = a(:,1);
end


