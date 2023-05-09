function [g,a,fc,L]=audfilters(fs,Ls,varargin)
%-*- texinfo -*-
%@deftypefn {Function} audfilters
%@verbatim
%AUDFILTERS Generates filters equidistantly spaced on auditory frequency scales
%   Usage:  [g,a,fc,L]=audfilters(fs,Ls);
%           [g,a,fc,L]=audfilters(fs,Ls,...);
%
%   Input parameters:
%      fs    : Sampling rate (in Hz).
%      Ls    : Signal length.
%   Output parameters:
%      g     : Cell array of filters.
%      a     : Downsampling rate for each channel.
%      fc    : Center frequency of each channel.
%      L     : Next admissible length suitable for the generated filters.
%
%   [g,a,fc,L]=AUDFILTERS(fs,Ls) constructs a set of filters g that are
%   equidistantly spaced on a perceptual frequency scale (see FREQTOAUD) between
%   0 and the Nyquist frequency. The filter bandwidths are proportional to the 
%   critical bandwidth of the auditory filters AUDFILTBW. The filters are intended 
%   to work with signals with a sampling rate of fs. The signal length Ls is 
%   mandatory, since we need to avoid too narrow frequency windows.
%
%   By default the ERB scale is chosen but other frequency scales are
%   possible. Currently supported scales are 'erb', 'erb83', 'bark', 'mel'
%   and 'mel1000', and can be changed by passing the associated string as 
%   an optional parameter. See FREQTOAUD for more information on the
%   supported frequency scales.
%
%   By default, a Hann window shape is chosen as prototype frequency 
%   response for all filters. The prototype frequency response can be 
%   changed by passing any of the window types from FIRWIN or FREQWIN 
%   as an optional parameter.
%
%   [g,a,fc,L]=AUDFILTERS(fs,Ls,fmin,fmax) constructs a set of filters 
%   between fmin and fmax. The filters are equidistantly spaced on the 
%   selected frequency scale. One additional filter will be positioned at 
%   the 0 and Nyquist frequencies each, so as to cover the full range of 
%   positive frequencies. 
%   The values of fmin and fmax can be instead specified using a 
%   key/value pair as:
%
%       [g,a,fc,L]=audfilters(fs,Ls,...,'fmin',fmin,'fmax',fmax)
%
%   Default values are fmin=0 and fmax=fs/2. 
%
%   For more details on the construction of the filters, please see the
%   given references.
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
%   [g,a]=AUDFILTERS(...,'regsampling') constructs a non-uniform
%   filterbank with integer subsampling factors.
%
%   [g,a]=AUDFILTERS(...,'uniform') constructs a uniform filterbank
%   where the integer downsampling rate is the same for all the channels. This
%   results in most redundant representation which produces nice plots.
%
%   [g,a]=AUDFILTERS(...,'fractional') constructs a filterbank with
%   fractional downsampling rates a. 
%   This results in the least redundant system.
%
%   [g,a]=AUDFILTERS(...,'fractionaluniform') constructs a filterbank with
%   fractional downsampling rates a, which are uniform for all filters
%   except the "filling" low-pass and high-pass filters which can have different
%   fractional downsampling rates. This is useful when uniform subsampling
%   and low redundancy at the same time are desirable.
%
%   Additional parameters
%   ---------------------
%
%   AUDFILTERS accepts the following optional parameters:
%
%     'spacing',b     Specify the spacing between the filters, measured in
%                     scale units. Default value is b=1 for the scales
%                     'erb', 'erb83' and 'bark'; the default is b=100 for
%                     'mel' and 'mel1000'.
%
%     'bwmul',bwmul   Bandwidth of the filters relative to the bandwidth
%                     returned by AUDFILTBW. Default value is bwmul=1 for 
%                     the scales 'erb', 'erb83' and 'bark'; the default is 
%                     b=100 for 'mel' and 'mel1000'.
%
%     'redmul',redmul  Redundancy multiplier. Increasing the value of this
%                      will make the system more redundant by lowering the
%                      channel downsampling rates. It is only used if the
%                      filterbank is a non-uniform filterbank. Default
%                      value is 1. If the value is less than one, the
%                      system may no longer be painless.
% 
%     'redtar',redtar Target redundancy. The downsampling factors will be
%                     adjusted to achieve a redundancy as close as possible
%                     to 'redtar'.
%
%     'M',M           Specify the total number of filters between fmin and 
%                     fmax. If this parameter is specified, it overwrites the
%                     'spacing' parameter.
%
%     'symmetric'     Create filters that are symmetric around their centre
%                     frequency. This is the default.
%
%     'warped'        Create asymmetric filters that are asymmetric on the
%                     auditory scale. 
%
%     'complex'       Construct a filterbank that covers the entire
%                     frequency range instead of just the positive 
%                     frequencies this allows the analysis of complex
%                     valued signals.
%
%     'trunc_at'      When using a prototype defined in FREQWIN, a hard 
%                     thresholding of the filters at the specified threshold 
%                     value is performed to reduce their support size. 
%                     The default value is trunc_at=10e-5. When no 
%                     truncation is desired, trunc_at=0 should be chosen.
%                     This value is ignored when a prototype shape from
%                     FIRWIN was chosen.
%
%     'min_win',min_win     Minimum admissible window length (in samples).
%                           Default is 4. This restrict the windows not
%                           to become too narrow when L is low.
%
%   Examples:
%   ---------
%
%   In the first example, we construct a highly redudant uniform
%   filterbank on the ERB scale and visualize the result:
%
%     [f,fs]=greasy;  % Get the test signal
%     [g,a,fc,L]=audfilters(fs,length(f),'uniform','M',100);
%     c=filterbank(f,g,a);
%     plotfilterbank(c,a,fc,fs,90,'audtick');
%
%   In the second example, we construct a non-uniform filterbank with
%   fractional sampling that works for this particular signal length, and
%   test the reconstruction. The plot displays the response of the
%   filterbank to verify that the filters are well-behaved both on a
%   normal and an ERB-scale. The second plot shows frequency responses of
%   filters used for analysis (top) and synthesis (bottom). :
%
%     [f,fs]=greasy;  % Get the test signal
%     L=length(f);
%     [g,a,fc]=audfilters(fs,L,'fractional');
%     c=filterbank(f,{'realdual',g},a);
%     r=2*real(ifilterbank(c,g,a));
%     norm(f-r)
%
%     % Plot the response
%     figure(1);
%     subplot(2,1,1);
%     R=filterbankresponse(g,a,L,fs,'real','plot');
%
%     subplot(2,1,2);
%     semiaudplot(linspace(0,fs/2,L/2+1),R(1:L/2+1));
%     ylabel('Magnitude');
%
%     % Plot frequency responses of individual filters
%     gd=filterbankrealdual(g,a,L);
%     figure(2);
%     subplot(2,1,1);
%     filterbankfreqz(gd,a,L,fs,'plot','linabs','posfreq');
%
%     subplot(2,1,2);
%     filterbankfreqz(g,a,L,fs,'plot','linabs','posfreq');
%
%
%
%   References:
%     T. Necciari, P. Balazs, N. Holighaus, and P. L. Soendergaard. The ERBlet
%     transform: An auditory-based time-frequency representation with perfect
%     reconstruction. In Proceedings of the 38th International Conference on
%     Acoustics, Speech, and Signal Processing (ICASSP 2013), pages 498--502,
%     Vancouver, Canada, May 2013. IEEE.
%     
%     T. Necciari, N. Holighaus, P. Balazs, Z. Průša, P. Majdak, and
%     O. Derrien. Audlet filter banks: A versatile analysis/synthesis
%     framework using auditory frequency scales. Applied Sciences, 8(1),
%     2018. [1]http ]
%     
%     References
%     
%     1. http://www.mdpi.com/2076-3417/8/1/96
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/audfilters.html}
%@seealso{filterbank, ufilterbank, ifilterbank, ceil23}
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

% Authors: Peter L. Soendergaard (original 'erbfilters' function)
% Modified by: Thibaud Necciari, Nicki Holighaus
% Date: 16.12.16

complainif_notenoughargs(nargin,2,upper(mfilename));
complainif_notposint(fs,'fs',upper(mfilename));
complainif_notposint(Ls,'Ls',upper(mfilename));

firwinflags=getfield(arg_firwin,'flags','wintype');
freqwinflags=getfield(arg_freqwin,'flags','wintype');

definput.flags.wintype = [ firwinflags, freqwinflags];
definput.keyvals.M=[];
definput.keyvals.redmul=1;
definput.keyvals.min_win = 4;
definput.keyvals.bwmul=[];
definput.keyvals.spacing=[];
definput.keyvals.trunc_at=10^(-5);
definput.keyvals.fmin=0;
definput.keyvals.fmax=fs/2;
definput.keyvals.redtar=[];
definput.flags.audscale={'erb','erb83','bark','mel','mel1000'};
definput.flags.warp     = {'symmetric','warped'};
definput.flags.real     = {'real','complex'};
definput.flags.sampling = {'regsampling','uniform','fractional',...
                           'fractionaluniform'};

% Search for window given as cell array
candCellId = cellfun(@(vEl) iscell(vEl) && any(strcmpi(vEl{1},definput.flags.wintype)),varargin);

winCell = {};
% If there is such window, replace cell with function name so that 
% ltfatarghelper does not complain
if ~isempty(candCellId) && any(candCellId)
    candCellIdLast = find(candCellId,1,'last');
    winCell = varargin{candCellIdLast};
    varargin(candCellId) = []; % But remove all
    varargin{end+1} = winCell{1};
end

[flags,kv]=ltfatarghelper({'fmin','fmax'},definput,varargin);
if isempty(winCell), winCell = {flags.wintype}; end

switch flags.audscale
    case {'mel','mel1000'} % The mel scales are very fine, therefore default spacing is adjusted
        definput.keyvals.bwmul=100;
        definput.keyvals.spacing=100;
    otherwise
        definput.keyvals.bwmul=1;
        definput.keyvals.spacing=1;
end
[flags,kv]=ltfatarghelper({'fmin','fmax','redtar'},definput,varargin);

if flags.do_bark && (fs > 44100)
    error(['%s: Bark scale is not suitable for sampling rates higher than 44.1 kHz. ',...
    'Please choose another scale.'],upper(mfilename));
end 

if ~isscalar(kv.bwmul) || kv.bwmul <= 0
    error('%s: bwmul must be a positive scalar.',upper(mfilename));
end

if ~isscalar(kv.redmul) || kv.redmul <= 0
    error('%s: redmul must be a positive scalar.',upper(mfilename));
end

if ~isempty(kv.redtar)
    if ~isscalar(kv.redtar) || kv.redtar <= 0
        error('%s: redtar must be a positive scalar.',upper(mfilename));
    end
end

if kv.redtar <= 1
    warning('%s: redtar is very low; the resulting system might be unstable.',upper(mfilename));
end

if kv.fmax <= kv.fmin || kv.fmin < 0 || kv.fmax > fs/2
    error('%s: fmax must be bigger than fmin and in the range [0,fs/2].',upper(mfilename));
end

if kv.trunc_at > 1 || kv.trunc_at < 0
    error('%s: trunc_at must be in range [0,1].',upper(mfilename));
end

if ~isscalar(kv.min_win) || rem(kv.min_win,1) ~= 0 || kv.min_win < 1
    error('%s: min_win must be an integer bigger or equal to 1.',upper(mfilename));
end

if ~isempty(kv.M)
    complainif_notposint(kv.M,'M',upper(mfilename));
    kv.spacing = (freqtoaud(kv.fmax,flags.audscale) - freqtoaud(kv.fmin,flags.audscale))/(kv.M-1);
end

probelen = 10000;

switch flags.wintype
    case firwinflags
        winbw=norm(firwin(flags.wintype,probelen)).^2/probelen;
        % This is the ERB-type bandwidth of the prototype

        if flags.do_symmetric
            filterfunc = @(fsupp,fc,scal)... 
                         blfilter(winCell,fsupp,fc,'fs',fs,'scal',scal,...
                                  'inf','min_win',kv.min_win);
        else
            fsupp_scale=1/winbw*kv.bwmul;
            filterfunc = @(fsupp,fc,scal)...
                         warpedblfilter(winCell,fsupp_scale,fc,fs,...
                                        @(freq) freqtoaud(freq,flags.audscale),@(aud) audtofreq(aud,flags.audscale),'scal',scal,'inf');
        end
        bwtruncmul = 1;
    case freqwinflags
        if flags.do_warped
            error('%s: TODO: Warping is not supported for windows from freqwin.',...
                upper(mfilename));
        end

        probebw = 0.01;

        % Determine where to truncate the window
        H = freqwin(winCell,probelen,probebw);
        winbw = norm(H).^2/(probebw*probelen/2);
        bwrelheight = 10^(-3/10);

        if kv.trunc_at <= eps
            bwtruncmul = inf;
        else
            try
                bwtruncmul = winwidthatheight(abs(H),kv.trunc_at)/winwidthatheight(abs(H),bwrelheight);
            catch
                bwtruncmul = inf;
            end
        end

        filterfunc = @(fsupp,fc,scal)...
                     freqfilter(winCell, fsupp, fc,'fs',fs,'scal',scal,...
                                'inf','min_win',kv.min_win,...
                                'bwtruncmul',bwtruncmul);        
end

% Construct the AUD filterbank
fmin = max(kv.fmin,audtofreq(kv.spacing,flags.audscale));
fmax = min(kv.fmax,fs/2);

innerChanNum = floor((freqtoaud(fmax,flags.audscale)-freqtoaud(fmin,flags.audscale))/kv.spacing)+1;

fmax = audtofreq(freqtoaud(fmin,flags.audscale)+(innerChanNum-1)*kv.spacing,flags.audscale);

% Make sure that fmax < fs/2, and F_ERB(fmax) = F_ERB(fmin)+k/spacing, for
% some k.
count = 0;
while fmax >= fs/2
    count = count+1;
    fmax = audtofreq(freqtoaud(fmin,flags.audscale)+(innerChanNum-count-1)*kv.spacing,flags.audscale);    
end
innerChanNum = innerChanNum-count;

if fmax <= fmin || fmin > fs/4 || fmax < fs/4
    error(['%s: Bad combination of fs, fmax and fmin.'],upper(mfilename));
end

fc=audspace(fmin,fmax,innerChanNum,flags.audscale).';
fc = [0;fc;fs/2];
M2 = innerChanNum+2;

ind = (2:M2-1)';
%% Compute the frequency support
% fsupp is measured in Hz 

fsupp=zeros(M2,1);
aprecise=zeros(M2,1);

if flags.do_symmetric
    fsupp(ind)=audfiltbw(fc(ind),flags.audscale)/winbw*kv.bwmul;
    
    % Generate lowpass filter parameters     
    fsupp(1) = 0;
    fps0 = audtofreq(freqtoaud(fc(2),flags.audscale)+3*kv.spacing,flags.audscale);% f_{p,s}^{-}
    fsupp_temp1 = audfiltbw(fps0,flags.audscale)/winbw*kv.bwmul;
    aprecise(1) = max(fs./(2*max(fps0,0)+fsupp_temp1*kv.redmul),1);  
    
    % Generate highpass filter parameters     
    fsupp(end) = 0;
    fps0 = audtofreq(freqtoaud(fc(end-1),flags.audscale)-3*kv.spacing,flags.audscale);% f_{p,s}^{+}
    fsupp_temp1 = audfiltbw(fps0,flags.audscale)/winbw*kv.bwmul;
    aprecise(end) = max(fs./(2*(fc(end)-min(fps0,fs/2))+fsupp_temp1*kv.redmul),1);
else    
    % fsupp_scale is measured on the selected auditory scale
    % The scaling is incorrect, it does not account for the warping (NH:
    % I do think it is correct.)
    fsupp_scale=1/winbw*kv.bwmul;

    % Convert fsupp into the correct widths in Hz, necessary to compute
    % "a" in the next if-statement
    fsupp(ind)=audtofreq(freqtoaud(fc(ind),flags.audscale)+fsupp_scale/2,flags.audscale)-...
               audtofreq(freqtoaud(fc(ind),flags.audscale)-fsupp_scale/2,flags.audscale);
    
    % Generate lowpass filter parameters     
    fsupp(1) = 0;
    fps0 = audtofreq(freqtoaud(fc(2),flags.audscale)+3*kv.spacing,flags.audscale);% f_{p,s}^{-}
    fsupp_temp1 = audfiltbw(fps0,flags.audscale)/winbw*kv.bwmul;
    aprecise(1) = max(fs./(2*max(fps0,0)+fsupp_temp1*kv.redmul),1);
    
    % Generate highpass filter parameters     
    fsupp(end) = 0;
    fps0 = audtofreq(freqtoaud(fc(end-1),flags.audscale)-3*kv.spacing,flags.audscale);% f_{p,s}^{+}
    fsupp_temp1 = audfiltbw(fps0,flags.audscale)/winbw*kv.bwmul;
    aprecise(end) = max(fs./(2*(fc(end)-min(fps0,fs/2))+fsupp_temp1*kv.redmul),1);
end;

% Do not allow lower bandwidth than keyvals.min_win
fsuppmin = kv.min_win/Ls*fs;
for ii = 1:numel(fsupp)
    if fsupp(ii) < fsuppmin;
        fsupp(ii) = fsuppmin;
    end
end

% Find suitable channel subsampling rates
aprecise(ind)=fs./fsupp(ind)/kv.redmul;
aprecise=aprecise(:);

if any(aprecise<1)
    error('%s: Invalid subsampling rates. Decrease redmul.',upper(mfilename))
end

%% Compute the downsampling rate
if flags.do_regsampling
    % Shrink "a" to the next composite number
    a=floor23(aprecise);

    % Determine the minimal transform length
    L=filterbanklength(Ls,a);

    % Heuristic trying to reduce lcm(a)
    while L>2*Ls && ~(all(a)==a(1))
        maxa = max(a);
        a(a==maxa) = 0;
        a(a==0) = max(a);
        L = filterbanklength(Ls,a);
    end

elseif flags.do_fractional
    L = Ls;
    N=ceil(Ls./aprecise);
    a=[repmat(Ls,M2,1),N];
elseif flags.do_fractionaluniform
    L = Ls;
    N=ceil(Ls./min(aprecise));
    a= repmat([Ls,N],M2,1);
elseif flags.do_uniform
    a=floor(min(aprecise));
    L=filterbanklength(Ls,a);
    a = repmat(a,M2,1);
end;

% Get an expanded "a"
afull=comp_filterbank_a(a,M2,struct());

%% Compute the scaling of the filters
scal=sqrt(afull(:,1)./afull(:,2));

%% Construct the real or complex filterbank

if flags.do_real
    % Scale the first and last channels
    scal(1)=scal(1)/sqrt(2);
    scal(M2)=scal(M2)/sqrt(2);
else
    % Replicate the centre frequencies and sampling rates, except the first and
    % last
    a=[a;flipud(a(2:M2-1,:))];
    scal=[scal;flipud(scal(2:M2-1))];
    fc  =[fc; -flipud(fc(2:M2-1))];
    fsupp=[fsupp;flipud(fsupp(2:M2-1))];
    ind = [ind;numel(fc)+2-(M2-1:-1:2)'];
end;


%% Compute the filters
% This is actually much faster than the vectorized call.
g = cell(1,numel(fc));
for m=ind.'
    g{m}=filterfunc(fsupp(m),fc(m),scal(m));
end

% Generate lowpass filter
g{1} = audlowpassfilter(g(1:M2),a(1:M2,:),fc(1:M2),fs,scal(1),kv,flags);

% Generate highpass filter
g{M2} = audhighpassfilter(g(1:M2),a(1:M2,:),fc(1:M2),fs,scal(M2),kv,flags);

% Adjust the downsampling rates in order to achieve 'redtar'
if ~isempty(kv.redtar)
    if flags.do_uniform
        % Compute and display redundancy for verification
        org_red = (M2-2)/a(1);
        a_new = floor(a*org_red/kv.redtar);
        scal_new = org_red/kv.redtar*ones(numel(g),1);
%         new_red = (M2-2)/a_new(1);
    else
%         Exactly as in the paper
        dk_old = a(:,1)./a(:,2);
        org_red = sum(2./dk_old(2:end-1));
        a_new = [a(1,:);[a(2:end-1,1),ceil(a(2:end-1,2)*kv.redtar/org_red)];a(end,:)];
%         %         Adjust d0 and dK to the new redundancy
        cbw = 2*sum(audfiltbw(fc(2:M2-1),flags.audscale)/winbw*kv.bwmul)/(kv.redtar*fs);
%         % Low-pass
        fps0 = audtofreq(freqtoaud(fc(2),flags.audscale)+3*kv.spacing,flags.audscale);% f_{p,s}^{-}
        fsupp_temp0 = audfiltbw(fps0,flags.audscale)/winbw*kv.bwmul;
        a_new(1,2) = ceil(Ls/max(fs./(2*fps0+fsupp_temp0/cbw),1));  
%         % High-pass
        fps1 = audtofreq(freqtoaud(fc(end-1),flags.audscale)-3*kv.spacing,flags.audscale);% f_{p,s}^{+}
        fsupp_temp1 = audfiltbw(fps1,flags.audscale)/winbw*kv.bwmul;
        a_new(end,2) = ceil(Ls/max(fs./(2*(fc(end)-fps1)+fsupp_temp1/cbw),1));
        % Finally re-scale all filters
        dk_new = a_new(:,1)./a_new(:,2);
        scal_new = dk_new./dk_old;
%         new_red = sum(2./dk_new)-sum(1./dk_new([1,end]));
    end
    g_new = filterbankscale(g,sqrt(scal_new)');
    a = a_new;
    g = g_new;
    % Compute and display redundancy for verification
%     fprintf('Original redundancy: %g \n', org_red);
%     fprintf('Target redundancy: %g \n', kv.redtar);
%     fprintf('Actual redundancy: %g \n', new_red);
end

function glow = audlowpassfilter(g,a,fc,fs,scal,kv,flags)    

% Make a probe, compute the restricted filter bank response to check if low-pass filter is needed
    Lprobe = 10000;
    FBresp0 = filterbankresponse(g(2:end-1),a(2:end-1,:),Lprobe,'real');
    eps_thr = 1e-3;
    ind_f1 = floor(fc(2)*Lprobe/fs);
    ind_fK = floor(fc(end-1)*Lprobe/fs);
    if ind_f1 == 0 || ...
        min(FBresp0(1:ind_f1)) >= (1-eps_thr)*min(FBresp0(ind_f1:ind_fK))
%       Not required
        glow.H = @(L) 0;
        glow.foff = @(L) 0;
        glow.realonly = 0;
        glow.delay = 0;
        glow.fs = g{2}.fs;
    else

%       Required
        % Compute the transition frequencies f_{p,s}^{-} and f_{p,e}^{-}
        % Determines the width of the plateau
        fps = audtofreq(freqtoaud(fc(2),flags.audscale)+3*kv.spacing,flags.audscale);
        % Determines the cosine transition frequency
        fpe = audtofreq(freqtoaud(fc(2),flags.audscale)+4*kv.spacing,flags.audscale);
        fsupp_LP = 2*fpe;
        ratio = 2*(fpe-fps)/fsupp_LP;
        Lw = @(L) min(ceil(fsupp_LP*L/fs),L);

        P0 = blfilter({'hann','taper',ratio},fsupp_LP,'fs',fs,'inf','min_win',kv.min_win);
        temp_fbresp = @(L) filterbankresponse(g(2:end-1),a(2:end-1,:),L,'real');
        Hinv = @(L) sqrt(max(temp_fbresp(L))-temp_fbresp(L));

    %     Compute the final low-pass filter
        glow.H = @(L) fftshift(long2fir(...
            filterbankfreqz(P0,a(1,:),L).*Hinv(L),Lw(L)))*scal;
        glow.foff = @(L) -floor(Lw(L)/2);
        glow.realonly = 0;
        glow.delay = 0;
        glow.fs = g{2}.fs;
    end
    
function ghigh = audhighpassfilter(g,a,fc,fs,scal,kv,flags)

% Make a probe, compute the restricted filter bank response to check if hi-pass filter is needed
    Lprobe = 10000;
    FBresp0 = filterbankresponse(g(2:end-1),a(2:end-1,:),Lprobe,'real');
    eps_thr = 1e-3;
    ind_f1 = floor(fc(2)*Lprobe/fs);
    ind_fK = floor(fc(end-1)*Lprobe/fs);
    if ind_f1 == 0 ||...
        min(FBresp0(ind_fK:floor(Lprobe/2))) >= (1-eps_thr)*min(FBresp0(ind_f1:ind_fK))
%       Not required
        ghigh.H = @(L) 0;
        ghigh.foff = @(L) 0;
        ghigh.realonly = 0;
        ghigh.delay = 0;
        ghigh.fs = g{2}.fs;
    else

%     Compute the transition frequencies f_{p,s}^{+} and f_{p,e}^{+}
    % Determines the width of the plateau
    fps = audtofreq(freqtoaud(fc(end-1),flags.audscale)-3*kv.spacing,flags.audscale);
    % Determines the cosine transition frequency
    fpe = audtofreq(freqtoaud(fc(end-1),flags.audscale)-4*kv.spacing,flags.audscale);

%     plateauWidth = 2*(fs/2-fps);
    fsupp_HP = 2*(fs/2-fpe);
    ratio = 2*(fps-fpe)/fsupp_HP;
    Lw = @(L) min(ceil(fsupp_HP*L/fs),L);
    
    PK = blfilter({'hann','taper',ratio},fsupp_HP,'fc',fs/2,'fs',fs,'inf','min_win',kv.min_win);
    temp_fbresp = @(L) filterbankresponse(g(2:end-1),a(2:end-1,:),L,'real');
    Hinv = @(L) sqrt(max(temp_fbresp(L))-temp_fbresp(L));
    
%     Compute the final high-pass filter
    ghigh.H = @(L) fftshift(long2fir(fftshift(...
        filterbankfreqz(PK,a(1,:),L).*Hinv(L)),Lw(L)))*scal;
    
    ghigh.foff = @(L) ceil(L/2)-floor(Lw(L)/2)-1;
    ghigh.realonly = 0;
    ghigh.delay = 0;
    ghigh.fs = g{2}.fs;
    end

function width = winwidthatheight(gnum,atheight)

width = zeros(size(atheight));
for ii=1:numel(atheight)
    gl = numel(gnum);
    gmax = max(gnum);
    frac=  1/atheight(ii);
    fracofmax = gmax/frac;
        
    ind =find(gnum(1:floor(gl/2)+1)==fracofmax,1,'first');
    if isempty(ind)
        %There is no sample exactly half of the height
        ind1 = find(gnum(1:floor(gl/2)+1)>fracofmax,1,'last');
        ind2 = find(gnum(1:floor(gl/2)+1)<fracofmax,1,'first');
        rest = 1-(fracofmax-gnum(ind2))/(gnum(ind1)-gnum(ind2));
        width(ii) = 2*(ind1+rest-1);
    else
        width(ii) = 2*(ind-1);
    end
end

