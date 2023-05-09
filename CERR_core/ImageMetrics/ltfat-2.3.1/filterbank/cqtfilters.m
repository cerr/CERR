function [g,a,fc,L]=cqtfilters(fs,fmin,fmax,bins,Ls,varargin)
%-*- texinfo -*-
%@deftypefn {Function} cqtfilters
%@verbatim
%CQTFILTERS   CQT-spaced filters
%   Usage:  [g,a,fc]=cqtfilters(fs,fmin,fmax,bins,Ls,varargin);
%           
%
%   Input parameters:
%      fs    : Sampling rate (in Hz).
%      fmin  : Minimum frequency (in Hz)
%      fmax  : Maximum frequency (in Hz)
%      bins  : Vector consisting of the number of bins per octave.
%      Ls    : Signal length.
%   Output parameters:
%      g     : Cell array of filters.
%      a     : Downsampling rate for each channel.
%      fc    : Center frequency of each channel.
%      L     : Next admissible length suitable for the generated filters.
%
%   [g,a,fc]=CQTFILTERS(fs,fmin,fmax,bins,Ls) constructs a set of
%   band-limited filters g which cover the required frequency range
%   fmin-fmax with bins filters per octave starting at fmin. All
%   filters have (approximately) equal Q=f_c/f_b, hence constant-Q. The
%   remaining frequency intervals not covered by these filters are captured
%   by two additional filters (low-pass, high-pass). The signal length Ls*
%   is mandatory, since we need to avoid too narrow frequency windows.
%
%   By default, a Hann window on the frequency side is chosen, but the
%   window can be changed by passing any of the window types from
%   FIRWIN as an optional parameter.
%   Run getfield(getfield(arg_firwin,'flags'),'wintype') to get a cell
%   array of window types available.
%
%   Because the downsampling rates of the channels must all divide the
%   signal length, FILTERBANK will only work for multiples of the
%   least common multiple of the downsampling rates. See the help of
%   FILTERBANKLENGTH.
%
%   [g,a]=CQTFILTERS(...,'regsampling') constructs a non-uniform
%   filter bank. The downsampling rates are constant in the octaves but
%   can differ among octaves. This approach was chosen in order to minimize
%   the least common multiple of a, which determines a granularity of
%   admissible input signal lengths.
%
%   [g,a]=CQTFILTERS(...,'uniform') constructs a uniform filter bank
%   where the downsampling rate is the same for all the channels. This
%   results in most redundant representation, which produces nice plots.
%
%   [g,a]=CQTFILTERS(...,'fractional') constructs a filter bank with
%   fractional downsampling rates a. The rates are constructed such
%   that the filter bank can handle signal lengths that are multiples of
%   L, so the benefit of the fractional downsampling is that you get to
%   choose the value returned by FILTERBANKLENGTH. This results in the
%   least redundant system.
%
%   [g,a]=CQTFILTERS(...,'fractionaluniform') constructs a filter bank with
%   fractional downsampling rates a, which are uniform for all filters
%   except the "filling" low-pass and high-pass filters can have different
%   fractional downsampling rates. This is useful when uniform subsampling
%   and low redundancy at the same time are desirable.
%
%   The filters are intended to work with signals with a sampling rate of
%   fs.
%
%   CQTFILTERS accepts the following optional parameters:
%
%     'Qvar',Qvar           Bandwidth variation factor. Multiplies the
%                           calculated bandwidth. Default value is 1.
%                           If the value is less than one, the
%                           system may no longer be painless.
%
%     'subprec'             Allow subsample window positions and
%                           bandwidths to better approximate the constant-Q
%                           property.
%
%     'complex'             Construct a filter bank that covers the entire
%                           frequency range. When missing, only positive
%                           frequencies are covered.
%
%     'min_win',min_win     Minimum admissible window length (in samples).
%                           Default is 4. This restrict the windows not
%                           to become too narrow when L is low. This
%                           however brakes the constant-Q property for such
%                           windows and creates rippling in the overall
%                           frequency response.
%
%     'redmul',redmul       Redundancy multiplier. Increasing the value of
%                           this will make the system more redundant by
%                           lowering the channel downsampling rates. Default
%                           value is 1. If the value is less than one,
%                           the system may no longer be painless.
%
%   Examples:
%   ---------
%
%   In the first example, we construct a highly redundant uniform
%   filter bank and visualize the result:
%
%     [f,fs]=greasy;  % Get the test signal
%     [g,a,fc]=cqtfilters(fs,100,fs,32,length(f),'uniform');
%     c=filterbank(f,g,a);
%     plotfilterbank(c,a,fc,fs,90,'audtick');
%
%   In the second example, we construct a non-uniform filter bank with
%   fractional sampling that works for this particular signal length, and
%   test the reconstruction. The plot displays the response of the
%   filter bank to verify that the filters are well-behaved both on a
%   normal and an log scale. The second plot shows frequency responses of
%   filters used for analysis (top) and synthesis (bottom). :
%
%     [f,fs]=greasy;  % Get the test signal
%     L=length(f);
%     [g,a,fc]=cqtfilters(fs,100,fs,8,L,'fractional');
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
%   References:
%     N. Holighaus, M. Doerfler, G. A. Velasco, and T. Grill. A framework for
%     invertible, real-time constant-Q transforms. IEEE Transactions on
%     Audio, Speech and Language Processing, 21(4):775 --785, 2013.
%     
%     G. A. Velasco, N. Holighaus, M. Doerfler, and T. Grill. Constructing an
%     invertible constant-Q transform with non-stationary Gabor frames.
%     Proceedings of DAFX11, 2011.
%     
%     C. Schoerkhuber, A. Klapuri, N. Holighaus, and M. Doerfler. A Matlab
%     Toolbox for Efficient Perfect Reconstruction Time-Frequency Transforms
%     with Log-Frequency Resolution. In Audio Engineering Society Conference:
%     53rd International Conference: Semantic Audio. Audio Engineering
%     Society, 2014.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/cqtfilters.html}
%@seealso{erbfilters, cqt, firwin, filterbank}
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

% Authors: Nicki Holighaus, Gino Velasco
% Date: 10.04.13
% Modified by: Zdenek Prusa
% Date: 10.02.14

%% Check input arguments
complainif_notenoughargs(nargin,5,upper(mfilename));
complainif_notposint(fs,'fs',upper(mfilename));
complainif_notposint(fmin,'fmin',upper(mfilename));
complainif_notposint(fmax,'fmax',upper(mfilename));
complainif_notposint(bins,'bins',upper(mfilename));
complainif_notposint(Ls,'Ls',upper(mfilename));

if fmin>=fmax
    error('%s: fmin has to be less than fmax.',upper(mfilename));
end

definput.import = {'firwin'};
definput.keyvals.L=[];
definput.keyvals.Qvar = 1;
definput.keyvals.redmul=1;
definput.keyvals.min_win = 4;
definput.flags.real     = {'real','complex'};
definput.flags.subprec  = {'nosubprec','subprec'};
definput.flags.sampling = {'regsampling','uniform',...
                           'fractional','fractionaluniform'};

[flags,kv]=ltfatarghelper({},definput,varargin);

if flags.do_subprec
    error('%s: TO DO: Subsample window positioning is not implemented yet.',...
          upper(mfilename));
end
% Nyquist frequency
nf = fs/2;

% Limit fmax
if fmax > nf
    fmax = nf;
end

% Number of octaves
b = ceil(log2(fmax/fmin))+1;

if length(bins) == 1;
    % Constant number of bins in each octave
    bins = bins*ones(b,1);
elseif length(bins) < b
    % Pick bins for octaves for which it was not specified.
    bins = bins(:);
    bins( bins<=0 ) = 1;
    bins = [bins ; bins(end)*ones(b-length(bins),1)];
end

% Prepare frequency centers in Hz
fc = zeros(sum(bins),1);

ll = 0;
for kk = 1:length(bins);
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

M = length(fc);

% Add filter at zero and nf frequencies
fc = [0;fc;nf];
M2 = M + 2;

% Set bandwidths
fsupp = zeros(M2,1);

% Bandwidth of the low-pass filter around 0
fsupp(1) = 2*fmin;
fsupp(2) = (fc(2))*(2^(1/bins(1))-2^(-1/bins(1)));

for k = [3:M , M]
    fsupp(k) = (fc(k+1)-fc(k-1));
end

fsupp(M+1) = (fc(M+1))*(2^(1/bins(end))-2^(-1/bins(end)));
fsupp(M+2) = 2*(nf-fc(end-1));

% Keeping center frequency and changing bandwidth => Q=fbas/bw
% Do that only for the constant Q filters
fsupp(2:end-1) = kv.Qvar*fsupp(2:end-1);
% Lowpass and highpass filters has to be treated differently 
fsupp([1,end]) = fsupp([1,end]);

% Do not allow lower bandwidth than keyvals.min_win
fsuppmin = kv.min_win/Ls*fs;
for ii = 1:numel(fsupp)
    if fsupp(ii) < fsuppmin;
        fsupp(ii) = fsuppmin;
    end
end

% Find suitable channel subsampling rates
aprecise=fs./fsupp;
aprecise=aprecise(:);
if any(aprecise<1)
    error(['%s: Bandwidth of one of the filters is bigger than fs. ',...
           'Check fmin and fmax, number of bins and Qval'],upper(mfilename));
end

aprecise=aprecise/kv.redmul;
if any(aprecise<1)
    error('%s: The maximum redundancy mult. for this setting is %5.2f',...
         upper(mfilename), min(fs./fsupp));
end

%% Compute the downsampling rate
if flags.do_regsampling
        % Find minimum a in each octave and floor23 it.
        s = M-cumsum(bins);
        bins=bins(1:find(s<=0,1));
        bins(end) = bins(end)-(sum(bins)-M);
        aocts = mat2cell(aprecise(2:end-1),bins);
        aocts = [{aprecise(1)};aocts;aprecise(end)];
        %aocts{1} = [aprecise(1);aocts{1}];
        %aocts{end} = [aocts{end};aprecise(end)];
        a=cellfun(@(aEl) floor23(min(aEl)),aocts);

        % Determine the minimal transform length lcm(a)
        L = filterbanklength(Ls,a);

        % Heuristic trying to reduce lcm(a)
        while L>2*Ls && ~(all(a==a(1)))
            maxa = max(a);
            a(a==maxa) = 0;
            a(a==0) = max(a);
            L = filterbanklength(Ls,a);
        end

        % Deal the integer subsampling factors
        a = cell2mat(cellfun(@(aoEl,aEl) ones(numel(aoEl),1)*aEl,...
            aocts,mat2cell(a,ones(numel(a),1)),'UniformOutput',0));

elseif flags.do_fractional
        L = Ls;
        N=ceil(Ls./aprecise);
        a=[repmat(Ls,M2,1),N];
elseif flags.do_fractionaluniform
    L = Ls;
    aprecise(2:end-1) = min(aprecise(2:end-1));
    N=ceil(Ls./aprecise);
    a=[repmat(Ls,M2,1),N];
elseif flags.do_uniform
    a=floor(min(aprecise));
    L=filterbanklength(Ls,a);
    a = repmat(a,M2,1);
end;


% Get an expanded "a"
afull=comp_filterbank_a(a,M2,struct());

%% Compute the scaling of the filters
% Individual filter peaks are made square root of the subsampling factor
scal=sqrt(afull(:,1)./afull(:,2));

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
end;

% This is actually much faster than the vectorized call.
g = cell(1,numel(fc));
for m=1:numel(g)
  g{m} = blfilter(flags.wintype,fsupp(m),fc(m),'fs',fs,'scal',scal(m),...
                  'inf','min_win',kv.min_win);
end


% Middle-pad windows at 0 and Nyquist frequencies
% with constant region (tapering window) if the bandwidth is larger than
% of the next in line window.
kkpairs = [1,2;M2,M2-1];
for idx = 1:size(kkpairs,1)
    Mk = fsupp(kkpairs(idx,1));
    Mknext = fsupp(kkpairs(idx,2));
    if Mk > Mknext
         g{kkpairs(idx,1)} = blfilter({'hann','taper',Mknext/Mk},...
                             Mk,fc(kkpairs(idx)),'fs',fs,'scal',...
                             scal(kkpairs(idx)),'inf');
    end
end



