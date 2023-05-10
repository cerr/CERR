function [H,info] = freqwavelet(name,L, varargin)
%FREQWAVELET  Wavelet in the freq. domain
%   Usage: H=freqwavelet(name,L)
%          H=freqwavelet(name,L,scale)
%          [H,info]=freqwavelet(...)
%
%   Input parameters:
%         name  : Name of the wavelet
%         L     : System length
%   Output parameters:
%         H     : Frequency domain wavelet
%         info  : Struct with additional outputs
%
%   FREQWAVELET(name,L) returns peak-normalized "mother" frequency-domain
%   wavelet name for system length L. The basic scale is selected such
%   that the peak is positioned at the frequency 0.1 relative to the Nyquist
%   rate (fs/2).
%
%   The supported wavelets that can be used in place of name (the actual
%   equations can be found at the end of this help):
%
%     'cauchy'    Cauchy wavelet with alpha=100. Custom order=(alpha-1)/2
%                 (with alpha>1) can be set by {'cauchy',alpha}. The
%                 higher the order, the narrower and more symmetric the
%                 wavelet. A numericaly stable formula is used in order
%                 to allow support even for very high alpha e.g.
%                 10^6.
%
%     'morse'     Morse wavelet with alpha=100 and gamma=3. Both parameters
%                 can be set directly by {'morse',alpha,gamma}. alpha
%                 has the same role as for 'cauchy', gamma is the
%                 'skewness' parameter. 'morse' becomes 'cauchy' for
%                 gamma=1.
%
%     'morlet'    Morlet wavelet with sigma=4. The parameter sigma 
%                 is the center frequency to standard deviation ratio of
%                 the main generating Gaussian distribution. Note that the 
%                 true peak and standard deviation of the Morlet wavelet 
%                 differ, in particular for low values of sigma (<5). 
%                 This is a consequence of the correction factor. The 
%                 parameter can be set directly by {'morlet',sigma}.
% 
%    'fbsp'       Frequency B-spline wavelet of order m=3, center frequency
%                 to bandwidth ratio fb = 2. The parameters can be set
%                 by {'fbsp',m,fb}. Note that m must be integer and
%                 greater than or equal to 1, and fb must be greater than 
%                 or equal to 2. 
%
%    'analyticsp' Positive frequency part of cosine-modulated B-spline 
%                 wavelet of  order order=3, with center frequency to main 
%                 lobe width ratio fb = 1. The parameters can be set by 
%                 {'analyticsp',order,fb}. Note that order and fb 
%                 must be integer and greater than or equal to 1.
%
%    'cplxsp'     Complex-modulated B-spline of order order=3, with center
%                 frequency to main lobe width ratio fb = 1. The parameters 
%                 can be set by {'cplxsp',order,fb}. Note that order 
%                 and fb must be integer and greater than or equal to 1.
%
%   FREQWAVELET(name,L,scale) returns a "dilated" version of the wavelet.
%   The nonzero scalar scale controls both the bandwidth and the center
%   frequency. Values greater than 1 make the wavelet wider (and narrower 
%   in the frequency domain), values lower than 1 make the wavelet narrower.
%   The center frequency is moved to0.1/scale. The center frequency is 
%   limited to the range of "positive" frequencies ]0,1] (up to Nyquist rate).
%   If scale is a vector, the output is a L x numel(scale) matrix with 
%   the individual wavelets as columns.
%
%   The following additional flags and key-value parameters are available:
%
%     'scale'           Wavelet scale (relative to basic scale)
%
%     'waveletParams'   a vector containing the respective wavelet parameters
%                       [alpha, beta, gamma] for cauchy and morse wavelets
%                       [sigma] for morlet wavelets
%                       [order, fb] for splines 
%
%     'basefc',fc      Normalized center frequency of the mother wavelet
%                      (scale=1). The default is 0.1.
%
%     'bwthr',bwthr    The height at which the bandwidth is computed.
%                      The default value is 10^(-3/10) (~0.5).
%
%     'efsuppthr',thr  The threshold determining the effective support of
%                      the wavelet. The default value is 10^(-5).
%
%     'scal',s         Scale the filter by the constant s. This can be
%                      useful to equalize channels in a filter bank.
%
%     'delay',d        Set the delay of the filter. Can be either a scalar or
%                      a vector of the same length as scale. Default value is zero.
%
%   The admissible range of scales can be adjusted to handle different 
%   scenarios:
%
%     'positive'       Enables the construction of wavelets at postive
%                      center frequencies ]0,1]. If basefc=0.1, this 
%                      corresponds to scales larger than or equal to 0.1.
%                      This is the default.
%
%     'negative'       Enables the construction of wavelets at negative 
%                      center frequencies [-1,0[. If basefc=0.1, this 
%                      corresponds to scales smaller than or equal to -0.1.
%
%     'analytic'       Enables the construction of wavelets with center 
%                      frequencies in ]0,2] for analysis of analytic signals. 
%                      [! This feature is currently experimental and may not
%                      always work as intended. !]
%
%   The format of the output is controlled by the following flags:
%   'full' (default),'econ','asfreqfilter':
%
%     'full'           The output is a L x numel(scale) matrix.
%
%     'econ'           The output is a numel(scale) cell array with
%                      individual freq. domain wavelets truncated to the
%                      length of the effective support given by parameter 'efsuppthr'.
%                      Does not run stably for system lengths > 2000
%
%     'asfreqfilter'   As 'econ', but the elements of the cell-array are
%                      filter structs with fields .H and .foff as in 
%                      BLFILTER to be used in FILTERBANK and related. 
%
%   [H,info]=FREQWAVELET(...) additionally returns a struct with the
%   following fields:
%
%     .fc             Normalized center frequency.
%
%     .foff           Index of the first sample above the effective
%                     support threshold (minus one). 
%                     It can be directly used to convert the 'econ'
%                     output to 'full' by circshift(postpad(H,L),foff).
%
%     .fsupp          Length of the effective support (with values above 
%                     efsuppthr).
%
%     .basefc         Center frequency of the implied mother wavelet.
%
%     .scale          The scale used.
%
%     .dilation       The actual dilation used in the formula.
%
%     .bw             Relative bandwidth at -3 dB (half of the height).
%
%     .tfr            Time-frequency ratio of a Gaussian with the same
%                     bandwidth as the wavelet.
%
%     .aprecise       Exact natural subsampling factors (not rounded). 
%
%     .a_natural      Fractional natural subsampling factors in the
%                     format acceptable by FILTERBANK and related.
%
%     .cauchyAlpha    Alpha value of closest Cauchy wavelet [NOTE: Not 
%                     implemented for non-Morse wavelets.]
%
%   Additionally, the function accepts flags to normalize the output.
%   Please see the help of SETNORM. By default, no normaliazation is
%   applied.
%
%   Wavelet definitions
%   -------------------
%
%   C is a normalization constant.
%
%   Cauchy wavelet
%
%       H = C xi^{frac{alpha-1}{2}} exp( -2pixi )
%
%   Morse wavelet
%
%       H = C xi^{frac{alpha-1}{2gamma}} exp( -2pixi^{gamma} )
%
%   Morlet wavelet
%
%       H = C xi^{frac{alpha-1}{2gamma}} exp( -2pixi^{gamma} )
%
%   Frequency bandlimited spline wavelet
%
%       H = C B (xi - m frac{xi}{4})
%
%   Analytic spline wavelet
%
%       H = C exp(-j omega x) A(-exp(j omega)) H(exp(-j omega)
%
%   Complex spline wavelet
%
%       H = C exp(-j omega x + xi )
%
%
%   References:
%     O. Rioul and P. Duhamel. Fast algorithms for discrete and continuous
%     wavelet transforms. IEEE Transactions on Information Theory,
%     38(2):569--586, 1992.
%     
%     M. Unser, A. Aldroubi, and S. Schiff. B-spline signal processing. i.
%     theory. IEEE Trans. Signal Process., 42(12):3519 --3523, 1994.
%     
%
%   See also: setnorm, filterbank, blfilter
%
%   Url: http://ltfat.github.io/doc/sigproc/freqwavelet.html

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



complainif_notenoughargs(nargin,2,upper(mfilename));

%set default input parameters
if ~isscalar(L)
    error('%s: L must be a scalar',upper(mfilename));
end

if ~iscell(name), name = {name}; end

freqwavelettypes = getfield(arg_freqwavelet(),'flags','wavelettype');

if ~ischar(name{1}) || ~any(strcmpi(name{1},freqwavelettypes))
  error('%s: First input argument must be the name of a supported window.',...
        upper(mfilename));
end


definput.import={'setnorm', 'freqwavelet'};
definput.importdefaults={'null'};
definput.keyvals.scale = 1;
definput.keyvals.scal = [];
definput.keyvals.basefc = 0.1;
definput.keyvals.delay=0;
definput.keyvals.fc = [];
definput.keyvals.bwthr = 10^(-3/10);
definput.keyvals.efsuppthr = 10^(-5);
definput.flags.freqrange = {'positive','negative','analytic'};
definput.flags.outformat = {'full','econ','asfreqfilter'};
definput.keyvals.fs = 2;
definput.keyvals.alphaStep = definput.keyvals.fs/L;

if ~iscell(name)
    name = {name};
end


[flags,kv,scale]=ltfatarghelper({'scale'},definput,varargin,'freqwavelet');

%check L
if ~isscalar(L)
    error('%s: L must be a scalar',upper(mfilename));
end

%check basefc
if ~isscalar(kv.basefc)
    error('%s: basefc must be a positive scalar',upper(mfilename));
end

scale = scale(:).'; % Scale should always be a row vector
if ~isnumeric(scale), error('%s: scale must be numeric',upper(mfilename)); end

if isempty(kv.scal)
    kv.scal = scale;
elseif ~isnumeric(kv.scal)
    error('%s: scal must be numeric',upper(mfilename)); 
elseif numel(kv.scal) ~= numel(scale)
    error('%s: scal must have exactly as many entries as scale',upper(mfilename)); 
end

if kv.alphaStep > 0.02
    error('%s: wavelet sampling too small. increase system length.',upper(mfilename));
end

%if L/scale > 10
%   error('%s: scale too large.',upper(mfilename));
%end

% Check range of scales
if flags.do_positive && (any(scale <= 0) || any(kv.basefc./scale > 1))
    error('%s: Frequency range flag is set to positive. scale must be positive and not smaller than basefc.', upper(mfilename)); 
end
if flags.do_negative && (any(scale >= 0) || any(kv.basefc./scale < -1))
    error('%s: Frequency range flag is set to negative. scale must be negative and not larger than -basefc.', upper(mfilename)); 
end
if flags.do_analytic && (any(scale <= 0) || any(kv.basefc./scale > 2))
    error('%s: Frequency range flag is set to analytic. scale must be positive and not smaller than 2*basefc.', upper(mfilename)); 
end

% Check delay vector
if numel(kv.delay) == 1
    kv.delay = repmat(kv.delay, 1, numel(scale));
end
if numel(kv.delay) ~= numel(scale)
    error('%s: delay must have exactly as many entries as scale',upper(mfilename));
end
% Check other parameters
if kv.efsuppthr < 0, error('%s: efsuppthr must be nonnegative',upper(mfilename)); end
if kv.bwthr < 0, error('%s: bwthr must be nonnegative',upper(mfilename)); end
if kv.bwthr < kv.efsuppthr, error('%s: efsuppthr must be lower than bwthr.',upper(mfilename)); end

M = numel(scale);


if flags.do_full
    H = zeros(L,M);
else
    H = cell(1,M);
end

if flags.do_negative
    wltype = 'negative';
else
    wltype = 'positive';
end

%% generate the wavelet prototype
[fun, fsupp_, peakpos, cauchyAlpha] = helper_waveletgeneratorfunc(name, wltype);

%% calculate the support as f(scale)
fsupp = zeros(5,M);
fsupp(5,:) = kv.fs;
basedil = peakpos/(kv.basefc);

if kv.efsuppthr > 0
    fsupp(1,:) = max(0,(fsupp_(1)/basedil)./scale);
    fsupp(5,:) = min(kv.fs,(fsupp_(5)/basedil)./scale);
end
fsupp(2,:) = max(0,(fsupp_(2)/basedil)./scale);
fsupp(3,:) = (fsupp_(3)/basedil)./scale;
fsupp(4,:) = min(kv.fs,(fsupp_(4)/basedil)./scale);


if flags.do_negative
    fsupp = flip(fsupp);
end

fsuppL = fsuppL_inner(fsupp,kv.fs,L,1:5);


%% calculate H
if flags.do_full
    if ~flags.do_negative
        y = ((0:L-1)').*basedil*kv.alphaStep*scale;
    else
        y = ([0;(L-1:-1:1)']).*basedil*kv.alphaStep*scale;
    end
    H = abs(kv.scal).*setnorm(fun(y), flags.norm);    
elseif flags.do_econ
    for ii = 1:numel(scale)
        y = ((fsuppL(1,ii):fsuppL(end,ii)-1)').*basedil*kv.alphaStep*abs(scale(ii));
        H{ii} = abs(kv.scal(ii)).*setnorm(fun(y), flags.norm);%TODO: check output format: should be cell
    end
elseif flags.do_asfreqfilter
    for m = 1:numel(scale)
        y = @(L) ((fsuppL_inner(fsupp(:,m),kv.fs,L,1):fsuppL_inner(fsupp(:,m),kv.fs,L,5)-1)').*basedil*abs(scale(m))*kv.fs/L;
        H{m} = struct('H',@(L) abs(kv.scal(m))*setnorm(fun(y(L)),flags.norm),'foff',@(L)fsuppL_inner(fsupp(:,m),kv.fs,L,1),'realonly',0, 'delay', kv.delay(m));
   end
end

%% write info struct
info.basefc = kv.basefc;        
info.fc = fsupp(3,:);
info.scale = scale;%';
info.dilation = basedil.*scale;%';
info.fsupp = fsuppL(end,:) - fsuppL(1,:) + ones(1,numel(scale));
if info.fsupp <= 0, info.fsupp = 0; end
info.bw  = (fsupp(4,:) - fsupp(2,:));
bwinsamples = info.bw./kv.alphaStep;
info.aprecise = L./bwinsamples;
info.a_natural(:,2) = ceil(bwinsamples);
info.a_natural = info.a_natural';
info.tfr = (cauchyAlpha - 1)./(pi*info.fc.^2*L);
info.cauchyAlpha = cauchyAlpha;
info.foff = fsuppL(1,:);


%if M==1 && iscell(H)
%    H = H{1};
%end

end

function fsuppL = fsuppL_inner(fsupp,fs,L,idx)
    fsuppL_all = [ ceil(fsupp(1:2,:)/fs*L); round(fsupp(3,:)/fs*L); floor(fsupp(4:5,:)/fs*L) ];
    fsuppL = fsuppL_all(idx,:);
end 

