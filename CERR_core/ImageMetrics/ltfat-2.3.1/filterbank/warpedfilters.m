function [g,a,fc,L]=warpedfilters(freqtoscale,scaletofreq,fs,fmin,fmax,bins,Ls,varargin)
%-*- texinfo -*-
%@deftypefn {Function} warpedfilters
%@verbatim
%WARPEDFILTERS   Frequency-warped band-limited filters
%   Usage:  [g,a,fc]=warpedfilters(freqtoscale,scaletofreq,fs,fmin,fmax,bins,Ls);
%
%   Input parameters:
%      freqtoscale  : Function converting frequency (Hz) to scale units
%      scaletofreq  : Function converting scale units to frequency (Hz)
%      fs           : Sampling rate (in Hz).
%      fmin         : Minimum frequency (in Hz)
%      fmax         : Maximum frequency (in Hz)
%      bins         : Vector consisting of the number of bins per octave.
%      Ls           : Signal length.
%   Output parameters:
%      g            : Cell array of filters.
%      a            : Downsampling rate for each channel.
%      fc           : Center frequency of each channel (in Hz).
%      L            : Next admissible length suitable for the generated filters.
%
%   [g,a,fc]=WARPEDFILTERS(freqtoscale,scaletofreq,fs,fmin,fmax,bins,Ls)
%   constructs a set of band-limited filters g which cover the required 
%   frequency range fmin-fmax with bins filters per scale unit. The 
%   filters are always centered at full (fractional k/bins) scale units, 
%   where the first filter is selected such that its center is lower than 
%   fmin. 
%
%   By default, a Hann window on the frequency side is choosen, but the
%   window can be changed by passing any of the window types from
%   FIRWIN as an optional parameter.
%   Run getfield(getfield(arg_firwin,'flags'),'wintype') to get a cell
%   array of window types available.
%
%   With respect to the selected scale, all filters have equal bandwidth 
%   and are uniformly spaced on the scale axis, e.g. if freqtoscale is 
%   log(x), then we obtain constant-Q filters with geometric spacing. 
%   The remaining frequency intervals not covered by these filters are 
%   captured one or two additional filters (high-pass always, low-pass if 
%   necessary). The signal length Ls is required in order to obtain the 
%   optimal normalization factors.
%   
%   Attention: When using this function, the user needs to be aware of a 
%   number of things: 
%
%       a)  Although the freqtoscale and scaletofreq can be chosen
%           freely, it is assumed that freqtoscale is an invertible,
%           increasing function from {R} or {R}^+ onto
%           {R} and that freqtoscale is the inverse function.
%       b)  If freqtoscale is from {R}^+ onto {R}, then
%           necessarily freqtoscale(0) = -infty.
%       c)  If the slope of freqtoscale is (locally) too steep, then
%           there is the chance that some filters are effectively 0 or
%           have extremely low bandwidth (1-3 samples), and consequently
%           very poor localization in time. If freqtoscale is from 
%           {R}^+ onto {R} then this usually occurs close
%           to the DC component and can be alleviated by increasing fmin.
%       d)  Since the input parameter bins is supposed to be integer, 
%           freqtoscale and scaletofreq have to be scaled
%           appropriately. Note that freqtoscale(fs) is in some sense
%           proportional to the resulting number of frequency bands and
%           inversely proportional to the filter bandwidths. For example,
%           the ERB scale defined by 21.4log_{10}(1+f/228.8) works
%           nicely out of the box, while the similar mel scale
%           2595log_{10}(1+f/700) most likely has to be rescaled in
%           order not to provide a filter bank with 1000s of channels.
%
%   If any of these guidelines are broken, this function is likely to break
%   or give undesireable results.  
% 
%   By default, a Hann window is chosen as the transfer function prototype, 
%   but the window can be changed by passing any of the window types from
%   FIRWIN as an optional parameter.
%
%   The integer downsampling rates of the channels must all divide the
%   signal length, FILTERBANK will only work for input signal lengths
%   being multiples of the least common multiple of the downsampling rates.
%   See the help of FILTERBANKLENGTH. 
%   The fractional downsampling rates restrict the filterbank to a single
%   length L=Ls.
%
%   [g,a]=WARPEDFILTERS(...,'regsampling') constructs a non-uniform
%   filterbank with integer subsampling factors. 
%
%   [g,a]=WARPEDFILTERS(...,'uniform') constructs a uniform filterbank
%   where the the downsampling rate is the same for all the channels. This
%   results in most redundant representation, which produces nice plots.
%
%   [g,a]=WARPEDFILTERS(...,'fractional') constructs a filterbank with
%   fractional downsampling rates a. This results in the
%   least redundant system.
%
%   [g,a]=WARPEDFILTERS(...,'fractionaluniform') constructs a filterbank
%   with fractional downsampling rates a, which are uniform for all filters
%   except the "filling" low-pass and high-pass filters can have different
%   fractional downsampling rates. This is usefull when uniform subsampling
%   and low redundancy at the same time are desirable.
%
%   The filters are intended to work with signals with a sampling rate of
%   fs.
%
%   WARPEDFILTERS accepts the following optional parameters:
%
%       'bwmul',bwmul 
%                           Bandwidth variation factor. Multiplies the
%                           calculated bandwidth. Default value is 1.
%                           If the value is less than one, the
%                           system may no longer be painless.
%
%       'complex'            
%                           Construct a filterbank that covers the entire
%                           frequency range. When missing, only positive
%                           frequencies are covered.
%
%       'redmul',redmul      
%                           Redundancy multiplier. Increasing the value of
%                           this will make the system more redundant by
%                           lowering the channel downsampling rates. Default
%                           value is 1. If the value is less than one,
%                           the system may no longer be painless.
%
%   Examples:
%   ---------
%
%   In the first example, we use the ERB scale functions freqtoerb and
%   erbtofreq to construct a filter bank and visualize the result:
%
%     [s,fs] = gspi; % Get a test signal
%     Ls = numel(gspi);
%
%     % Fix some parameters
%     fmax = fs/2;
%     bins = 1;
%
%     % Compute filters, using fractional downsampling
%     [g,a,fc]=warpedfilters(@freqtoerb,@erbtofreq,fs,0,fmax,bins,...
%                            Ls,'bwmul',1.5,'real','fractional');
%
%     % Plot the filter transfer functions
%     figure(1); 
%     filterbankfreqz(g,a,Ls,'plot','linabs','posfreq');
%     title('ERBlet filter transfer functions');
%
%     % Compute the frame bounds
%     gf=filterbankresponse(g,a,Ls,'real'); framebound_ratio = max(gf)/min(gf);
%     disp(['Painless system frame bound ratio of ERBlets: ',...
%          num2str(framebound_ratio)]);
%      
%     % Plot the filter bank coefficients of the test signal
%     figure(2);
%     c=filterbank(s,g,a);
%     plotfilterbank(c,a,fc,fs,60);
%     title('ERBlet transform of the test signal');
%
%   In the second example, we look at the same test signal using a 
%   constant-Q filter bank with 4 bins per scale unit and the standard 
%   (semi-regular) sampling scheme:
%
%     [s,fs] = gspi; % Get a test signal
%     Ls = numel(gspi);
%
%     % Fix some parameters
%     fmax = fs/2;
%     bins = 1;
%
%     % Define the frequency-to-scale and scale-to-frequency functions
%     warpfun_log = @(x) 10*log(x);
%     invfun_log = @(x) exp(x/10);
%
%     bins_hi = 4; % Select bins/unit parameter
%     fmin = 50; % The logarithm's derivative 1/x tends to Inf for x towards 0
%
%     % Compute filters, using fractional downsampling
%     [g,a,fc]=warpedfilters(warpfun_log,invfun_log,fs,fmin,fmax,bins_hi,Ls,'bwmul',1,'real');
%
%     % Plot the filter transfer functions
%     figure(1); 
%     filterbankfreqz(g,a,Ls,'plot','linabs','posfreq');
%     title('constant-Q filter transfer functions (4 bins)');
%
%     % Compute the frame bounds
%     gf=filterbankresponse(g,a,Ls,'real'); framebound_ratio = max(gf)/min(gf);
%     disp(['Painless system frame bound ratio (constant-Q - 4 bins): ', num2str(framebound_ratio)]);
%
%     % Plot the filter bank coefficients of the test signal
%     figure(2); 
%     c=filterbank(s,g,a);
%     plotfilterbank(c,a,fc,fs,60);
%     title('constant-Q transform of the test signal (4 bins)');
%
%
%   References:
%     N. Holighaus, Z. Průša, and C. Wiesmeyr. Designing tight filter bank
%     frames for nonlinear frequency scales. Sampling Theory and Applications
%     2015, submitted, 2015.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/warpedfilters.html}
%@seealso{erbfilters, cqtfilters, firwin, filterbank, warpedblfilter}
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

% Authors: Nicki Holighaus, Zdenek Prusa
% Date: 14.01.15 

%% Check input arguments
capmname = upper(mfilename);
complainif_notenoughargs(nargin,7,capmname);
complainif_notposint(fs,'fs',capmname);
complainif_notposint(fmin+1,'fmin',capmname);
complainif_notposint(fmax,'fmax',capmname);
complainif_notposint(bins,'bins',capmname);
complainif_notposint(Ls,'Ls',capmname);

if ~isa(freqtoscale,'function_handle')
    error('%s: freqtoscale must be a function handle',capmname)
end

if ~isa(scaletofreq,'function_handle')
    error('%s: scaletofreq must be a function handle',capmname)
end

if fmin>=fmax
    error('%s: fmin has to be less than fmax.',capmname);
end


definput.import = {'firwin'};
definput.keyvals.bwmul = 1;
definput.keyvals.redmul = 1;
definput.keyvals.min_win = 1;
definput.flags.real     = {'real','complex'};
definput.flags.sampling = {'regsampling','uniform',...
                           'fractional','fractionaluniform'};

[flags,kv]=ltfatarghelper({},definput,varargin);

if ~isscalar(kv.bwmul)
    error('%s: bwmul must be scalar',capmname)
end

if ~isscalar(kv.redmul)
    error('%s: redmul must be scalar',capmname)
end

if ~isscalar(kv.min_win)
    error('%s: min_win must be scalar',capmname)
end


% Nyquist frequency
nf = fs/2;

% Limit fmax
if fmax > nf
    fmax = nf;
end
% Limit fmin
if fmin <= 0 && freqtoscale(0) == -Inf
    fmin = scaletofreq(freqtoscale(1));
end

%Determine range/number of windows
chan_min = floor(bins*freqtoscale(fmin))/bins;
if chan_min >= fmax;
    error('%s: Invalid frequency scale, try lowering fmin',...
          upper(mfilename));
end
chan_max = chan_min;
while scaletofreq(chan_max) <= fmax
    chan_max = chan_max+1/bins;
end
while scaletofreq(chan_max+kv.bwmul) >= nf
    chan_max = chan_max-1/bins;
end

% Prepare frequency centers in Hz
scalevec = (chan_min:1/bins:chan_max)';
fc = [scaletofreq(scalevec);nf];
if fmin~=0 
    fc = [0;fc];
end

M = length(fc);
%% ----------------------------------
% Set bandwidths
fsupp = zeros(M,1);

% Bandwidth of the low-pass filter around 0 (Check whether floor and/or +1
% is sufficient!!!)
fsuppIdx = 1;
if fmin~=0
    fsupp(1) = ceil(2*scaletofreq(chan_min-1/bins+kv.bwmul))+2;
    fsuppIdx = 2;
end
fsupp(fsuppIdx:M-1) = ceil(scaletofreq(scalevec+kv.bwmul)-scaletofreq(scalevec-kv.bwmul))+2;
fsupp(M) = ceil(2*(nf-scaletofreq(chan_max+1/bins-kv.bwmul)))+2;

% Find suitable channel subsampling rates
% Do not apply redmul to channels 1 and M as it produces uneccesarily
% badly conditioned frames
aprecise=fs./fsupp;
aprecise(2:end-1)=aprecise(2:end-1)/kv.redmul;
aprecise=aprecise(:);
if any(aprecise<1)
    error('%s: The maximum redundancy mult. for this setting is %5.2f',...
         upper(mfilename), min(fs./fsupp));
end

%% Compute the downsampling rate
if flags.do_regsampling
    % Shrink "a" to the next composite number
    a=floor23(aprecise);

    % Determine the minimal transform length
    L=filterbanklength(Ls,a);

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
    N=ceil(Ls./min(aprecise));
    a= repmat([Ls,N],M,1);
elseif flags.do_uniform
    a=floor(min(aprecise));
    L=filterbanklength(Ls,a);
    a = repmat(a,M,1);
end;

% Get an expanded "a"
afull=comp_filterbank_a(a,M,struct());

%% Compute the scaling of the filters
% Individual filter peaks are made square root of the subsampling factor
scal=sqrt(afull(:,1)./afull(:,2));

if flags.do_real
    % Scale the first and last channels
    scal(1)=scal(1)/sqrt(2);
    scal(M)=scal(M)/sqrt(2);
else
    % Replicate the centre frequencies and sampling rates, except the first and
    % last
    a=[a;flipud(a(2:M-1,:))];
    scal=[scal;flipud(scal(2:M-1))];
    fc  =[fc; -flipud(fc(2:M-1))];
    fsupp=[fsupp;flipud(fsupp(2:M-1))];
end;

g = cell(1,numel(fc));

gIdxStart = 1;
if fmin~=0
    % Low-pass filter
    g{1} = zerofilt(flags.wintype,fs,chan_min,freqtoscale,scaletofreq,scal(1),kv.bwmul,bins,Ls);
    gIdxStart = gIdxStart + 1;
end

% High-pass filter
g{M} = nyquistfilt(flags.wintype,fs,chan_max,freqtoscale,scaletofreq,scal(M),kv.bwmul,bins,Ls);

symmetryflag = 'nonsymmetric';
if freqtoscale(0) < -1e10, symmetryflag = 'symmetric'; end;

% All the other filters
for gIdx = [gIdxStart:M-1,M+1:numel(fc)]
   g{gIdx}=warpedblfilter(flags.wintype,kv.bwmul*2,fc(gIdx),fs,freqtoscale,scaletofreq, ...
   'scal',scal(gIdx),'inf',symmetryflag);
end


function g = nyquistfilt(wintype,fs,chan_max,freqtoscale,scaletofreq,scal,bwmul,bins,Ls)
    % This function constructs a high-pass filter centered at the Nyquist
    % frequency such that the summation properties of the filter bank
    % remain intact.
    g=struct();
    
    % Inf normalization as standard
    g.H = @(L) comp_nyquistfilt(wintype,fs,chan_max,freqtoscale,scaletofreq,bwmul,bins,Ls)*scal;
    
    g.foff=@(L) floor(L/2)+1-(numel(g.H(L))+1)/2;
    g.fs=fs;


function g = zerofilt(wintype,fs,chan_min,freqtoscale,scaletofreq,scal,bwmul,bins,Ls)
    % This function constructs a low-pass filter centered at the zero
    % frequency such that the summation properties of the filter bank
    % remain intact.
    g=struct();
    
    % Inf normalization as standard
    g.H = @(L) comp_zerofilt(wintype,fs,chan_min,freqtoscale,scaletofreq,bwmul,bins,Ls)*scal;
    
    g.foff=@(L) -(numel(g.H(L))+1)/2+1;
    g.fs=fs;

