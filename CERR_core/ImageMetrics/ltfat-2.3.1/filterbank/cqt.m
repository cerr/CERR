function [c,Ls,g,shift,M] = cqt(f,fmin,fmax,bins,fs,varargin)
%-*- texinfo -*-
%@deftypefn {Function} cqt
%@verbatim
%CQT  Constant-Q non-stationary Gabor filterbank
%   Usage: [c,Ls,g,shift,M] = cqt(f,fmin,fmax,bins,fs,M)
%          [c,Ls,g,shift,M] = cqt(f,fmin,fmax,bins,fs)
%          [c,Ls,g,shift] = cqt(...)
%          [c,Ls] = cqt(...)
%          c = cqt(...)
%
%   Input parameters: 
%         f         : The signal to be analyzed (For multichannel
%                     signals, input should be a matrix which each
%                     column storing a channel of the signal).
%         fmin      : Minimum frequency (in Hz)
%         fmax      : Maximum frequency (in Hz)
%         bins      : Vector consisting of the number of bins per octave
%         fs        : Sampling rate (in Hz)
%         M         : Number of time channels (optional)
%                     If M is constant, the output is converted to a
%                     matrix
%   Output parameters:
%         c         : Transform coefficients (matrix or cell array)
%         Ls        : Original signal length (in samples)
%         g         : Cell array of Fourier transforms of the analysis 
%                     windows
%         shift     : Vector of frequency shifts
%         M         : Number of time channels
%
%   This function computes a constant-Q transform via non-stationary Gabor
%   filterbanks. Given the signal f, the constant-Q parameters fmin,
%   fmax and bins, as well as the sampling rate fs of f, the
%   corresponding constant-Q coefficients c are given as output. For
%   reconstruction, the length of f and the filterbank parameters can
%   be returned also.
% 
%   The transform produces phase-locked coefficients in the
%   sense that each filter is considered to be centered at
%   0 and the signal itself is modulated accordingly.
%
%   Optional input arguments arguments can be supplied like this:
%       
%       cqt(f,fmin,fmax,bins,fs,'min_win',min_win)
%
%   The arguments must be character strings followed by an
%   argument:
%
%     'min_win',min_win        Minimum admissible window length 
%                              (in samples) 
%
%     'Qvar',Qvar              Bandwidth variation factor
%
%     'M_fac',M_fac            Number of time channels are rounded to 
%                              multiples of this
%
%     'winfun',winfun          Filter prototype (see FIRWIN for available 
%                              filters)
%     'fractional'             Allow fractional shifts and bandwidths
%
%
%   Example:
%   --------
%
%   The following example shows analysis and synthesis with CQT and ICQT:
%
%     [f,fs] = gspi;
%     fmin = 200;
%     fmax = fs/2;
%     [c,Ls,g,shift,M] = cqt(f,fmin,fmax,48,fs);
%     fr = icqt(c,g,shift,Ls);
%     rel_err = norm(f-fr)/norm(f);
%     plotfilterbank(c,Ls./M,[],fs,'dynrange',60);
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
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/cqt.html}
%@seealso{icqt, firwin}
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

%% Check input arguments
if nargin < 5
    error('Not enough input arguments');
end

[f,Ls,W]=comp_sigreshape_pre(f,upper(mfilename),0);

% Set defaults

definput.keyvals.usrM = [];
definput.keyvals.Qvar = 1;
definput.keyvals.M_fac = 1;
definput.keyvals.min_win = 4;
definput.keyvals.winfun = 'hann';
definput.flags.fractype = {'nofractional','fractional'};

% Check input arguments

[flags,keyvals,usrM]=ltfatarghelper({'usrM'},definput,varargin);

%% Create the CQ-NSGT dictionary

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
fbas = zeros(sum(bins),1);

ll = 0;
for kk = 1:length(bins);
    fbas(ll+(1:bins(kk))) = ...
        fmin*2.^(((kk-1)*bins(kk):(kk*bins(kk)-1)).'/bins(kk));
    ll = ll+bins(kk);
end

% Get rid of filters with frequency centers >=fmax and nf
temp = find(fbas>=fmax,1);
if fbas(temp) >= nf
    fbas = fbas(1:temp-1);
else
    fbas = fbas(1:temp);
end

Lfbas = length(fbas);

% Add filter at zero and nf frequencies
fbas = [0;fbas;nf];

% Mirror other filters
% Length of fbas is now 2*(Lfbas+1)
fbas(Lfbas+3:2*(Lfbas+1)) = fs-fbas(Lfbas+1:-1:2);

% Convert frequency to samples
fbas = fbas*(Ls/fs);

% Set bandwidths
bw = zeros(2*Lfbas+2,1);

% Bandwidth of the low-pass filter around 0
bw(1) = 2*fmin*(Ls/fs);
bw(2) = (fbas(2))*(2^(1/bins(1))-2^(-1/bins(1)));

for k = [3:Lfbas , Lfbas+2]
    bw(k) = (fbas(k+1)-fbas(k-1));
end

% Bandwidth of last filter before the one at the nf
bw(Lfbas+1) = (fbas(Lfbas+1))*(2^(1/bins(end))-2^(-1/bins(end)));

% Mirror bandwidths
bw(Lfbas+3:2*Lfbas+2) = bw(Lfbas+1:-1:2);

% Make frequency centers integers
posit = zeros(size(fbas));
posit(1:Lfbas+2) = floor(fbas(1:Lfbas+2));
posit(Lfbas+3:end) = ceil(fbas(Lfbas+3:end));

% Keeping center frequency and changing bandwidth => Q=fbas/bw
bw = keyvals.Qvar*bw;

% M - number of coefficients in output bands (number of time channels).
if flags.do_fractional
    % Be pedantic about center frequencies by
    % sub-sample precision positioning of the frequency window.
    warning(['Fractional sampling might lead to a warning when ', ...
        'computing the dual system']);
    fprintf('');
    corr_shift = fbas-posit;
    M = ceil(bw+1);
else
    % Using the integer frequency window position.
    bw = round(bw);
    M = bw;
end

% Do not allow lower bandwidth than keyvals.min_win
for ii = 1:numel(bw)
    if bw(ii) < keyvals.min_win;
        bw(ii) = keyvals.min_win;
        M(ii) = bw(ii);
    end
end

if flags.do_fractional
    % Generate windows, while providing the x values.
    % x - shift correction
    % y - window length
    % z - 'safe' window length
    g = arrayfun(@(x,y,z) ...
        firwin(keyvals.winfun,([0:ceil(z/2),-floor(z/2):-1]'-x)/y)/sqrt(y),corr_shift,...
        bw,M,'UniformOutput',0);
else
    % Generate window, normalize to
    g = arrayfun(@(x) firwin(keyvals.winfun,x)/sqrt(x),...
        bw,'UniformOutput',0);
end

% keyvals.M_fac is granularity of output bands lengths
% Round M to next integer multiple of keyvals.M_fac
M = keyvals.M_fac*ceil(M/keyvals.M_fac);

% Middle-pad windows at 0 and Nyquist frequencies
% with constant region (tapering window) if the bandwidth is larger than
% of the next in line window.
for kk = [1,Lfbas+2]
    if M(kk) > M(kk+1);
        g{kk} = ones(M(kk),1);
        g{kk}((floor(M(kk)/2)-floor(M(kk+1)/2)+1):(floor(M(kk)/2)+...
            ceil(M(kk+1)/2))) = firwin('hann',M(kk+1));
        g{kk} = g{kk}/sqrt(M(kk));
    end
end

% The number of frequency channels
N = length(posit);  

% Handle the user defined output bands lengths.
if ~isempty(usrM)
    if numel(usrM) == 1
        M = usrM*ones(N,1);
    elseif numel(usrM)==N
        M = usrM;
    else
        error(['%s: Number of enties of parameter M does not comply ',...
               'with the number of frequency channels.'],upper(mfilename));
    end    
end

%% The CQ-NSG transform

% some preparation
f = fft(f);

c=cell(N,1); % Initialisation of the result

% Obtain input type
ftype = assert_classname(f);
% The actual transform

for ii = 1:N
    Lg = length(g{ii});
    
    idx = [ceil(Lg/2)+1:Lg,1:ceil(Lg/2)];
    win_range = mod(posit(ii)+(-floor(Lg/2):ceil(Lg/2)-1),Ls)+1;
    
    if M(ii) < Lg % if the number of frequency channels is too small,
        % aliasing is introduced
        col = ceil(Lg/M(ii));
        temp = zeros(col*M(ii),W,ftype);
        
        temp([end-floor(Lg/2)+1:end,1:ceil(Lg/2)],:) = ...
            bsxfun(@times,f(win_range,:),g{ii}(idx));
        temp = reshape(temp,M(ii),col,W);
        
        c{ii} = squeeze(ifft(sum(temp,2)));
        
        % Using c = cellfun(@(x) squeeze(ifft(x)),c,'UniformOutput',0);
        % outside the loop instead does not provide speedup; instead it is
        % slower in most cases.
    else
        temp = zeros(M(ii),W,ftype);
        temp([end-floor(Lg/2)+1:end,1:ceil(Lg/2)],:) = ...
            bsxfun(@times,f(win_range,:),g{ii}(idx));
        
        c{ii} = ifft(temp);
    end
end

% Reshape to a matrix if coefficient bands have uniform lengths.
% This is maybe too confuzing.
if max(M) == min(M)
    c = cell2mat(c);
    c = reshape(c,M(1),N,W);
end

% Return relative shifts between filters in frequency in samples
% This does not correctly handle the fractional frequency positioning.
if nargout > 3
    shift = [mod(-posit(end),Ls); diff(posit)];
end

