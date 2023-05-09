function [c,Ls,g,shift,M] = erblett(f,bins,fs,varargin)
%-*- texinfo -*-
%@deftypefn {Function} erblett
%@verbatim
%ERBLETT  ERBlet non-stationary Gabor filterbank
%   Usage: [c,Ls,g,shift,M] = erblett(f,bins,fs,varargin)
%          [c,Ls,g,shift] = erblett(...)
%          [c,Ls] = erblett(...)
%          c = erblett(...)
%
%   Input parameters: 
%         f         : The signal to be analyzed (For multichannel
%                     signals, input should be a matrix which each
%                     column storing a channel of the signal)
%         bins      : Desired bins per ERB
%         fs        : Sampling rate of f (in Hz)
%         varargin  : Optional input pairs (see table below)
%   Output parameters:
%         c         : Transform coefficients (matrix or cell array)
%         Ls        : Original signal length (in samples)
%         g         : Cell array of Fourier transforms of the analysis 
%                     windows
%         shift     : Vector of frequency shifts
%         M         : Number of time channels
%
%   This function computes an ERBlet constant-Q transform via non-stationary 
%   Gabor filterbanks. Given the signal f, the ERBlet parameter bins, 
%   as well as the sampling rate fs of f, the corresponding ERBlet
%   coefficients c are given as output. For reconstruction, the length of
%   f and the filterbank parameters can be returned also.
% 
%   The transform produces phase-locked coefficients in the
%   sense that each filter is considered to be centered at
%   0 and the signal itself is modulated accordingly.
%
%   Optional input arguments arguments can be supplied like this:
%
%       erblett(f,bins,fs,'Qvar',Qvar)
%
%   The arguments must be character strings followed by an
%   argument:
%
%     'Qvar',Qvar              Bandwidth variation factor
%
%     'M_fac',M_fac            Number of time channels are rounded to 
%                              multiples of this
%
%     'winfun',winfun          Filter prototype (see FIRWIN for available 
%                              filters)
%
%   Examples:
%   ---------
%
%   The following example shows analysis and synthesis with ERBLETT and
%   IERBLETT:
%
%       [f,fs] = gspi;
%       binsPerERB = 4;
%       [c,Ls,g,shift,M] = erblett(f,binsPerERB,fs);
%       fr = ierblett(c,g,shift,Ls);
%       rel_err = norm(f-fr)/norm(f)
%       plotfilterbank(c,Ls./M,[],fs,'dynrange',60);
%
% 
%   References:
%     T. Necciari, P. Balazs, N. Holighaus, and P. L. Soendergaard. The ERBlet
%     transform: An auditory-based time-frequency representation with perfect
%     reconstruction. In Proceedings of the 38th International Conference on
%     Acoustics, Speech, and Signal Processing (ICASSP 2013), pages 498--502,
%     Vancouver, Canada, May 2013. IEEE.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/erblett.html}
%@seealso{ierblett, firwin}
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

% Authors: Thibaud Necciari, Nicki Holighaus
% Date: 10.04.13

%% Check input arguments
if nargin < 3
    error('Not enough input arguments');
end

[f,Ls,W]=comp_sigreshape_pre(f,upper(mfilename),0);

% Set defaults

definput.keyvals.usrM = [];
definput.keyvals.Qvar = 1;
definput.keyvals.M_fac = 1;
definput.keyvals.winfun = 'nuttall';

% Check input arguments

[flags,keyvals,usrM]=ltfatarghelper({'usrM'},definput,varargin);

%% Create the ERBlet dictionary

df = fs/Ls; % frequency resolution in the FFT

fmin = 0;
fmax = fs/2;

% Convert fmin and fmax into ERB
erblims = freqtoerb([fmin,fmax]);

% Determine number of freq. channels
Nf = bins*ceil(erblims(2)-erblims(1));

% Determine center frequencies
fc = erbspace(fmin,fmax,Nf)';

% Concatenate "virtual" frequency positions of negative-frequency windows
fc = [fc ; flipud(fc(1:end-1))];

gamma = audfiltbw(fc); % ERB scale

% Convert center frequencies in Hz into samples

posit = round(fc/df);% Positions of center frequencies in samples
posit(Nf+1:end) = Ls-posit(Nf+1:end);% Extension to negative freq.

% Compute desired essential (Gaussian) support for each filter
Lwin = 4*round(gamma/df);

% Nuttall windows are slightly broader than Gaussians, this is offset by 
% the factor 1.1

M = round(keyvals.Qvar*Lwin/1.1);

% Compute cell array of analysis filters
g = arrayfun(@(x) firwin(keyvals.winfun,x)/sqrt(x),M,'UniformOutput',0);

g{1}=1/sqrt(2)*g{1};
g{end}=1/sqrt(2)*g{end};

M = keyvals.M_fac*ceil(M/keyvals.M_fac);
N = length(posit);  % The number of frequency channels

if ~isempty(usrM)
    if numel(usrM) == 1
        M = usrM*ones(N,1);
    else
        M = usrM;
    end    
end

%% The ERBlet transform

% some preparation

f = fft(f);

c=cell(N,1); % Initialisation of the result

% The actual transform

for ii = 1:N
    Lg = length(g{ii});
    
    idx = [ceil(Lg/2)+1:Lg,1:ceil(Lg/2)];
    win_range = mod(posit(ii)+(-floor(Lg/2):ceil(Lg/2)-1),Ls)+1;
    
    if M(ii) < Lg % if the number of frequency channels is too small,
        % aliasing is introduced
        col = ceil(Lg/M(ii));
        temp = zeros(col*M(ii),W,assert_classname(f));
        
        temp([end-floor(Lg/2)+1:end,1:ceil(Lg/2)],:) = ...
            bsxfun(@times,f(win_range,:),g{ii}(idx));
        temp = reshape(temp,M(ii),col,W);
        
        c{ii} = squeeze(ifft(sum(temp,2)));
        
        % Using c = cellfun(@(x) squeeze(ifft(x)),c,'UniformOutput',0);
        % outside the loop instead does not provide speedup; instead it is
        % slower in most cases.
    else
        temp = zeros(M(ii),W,assert_classname(f));
        temp([end-floor(Lg/2)+1:end,1:ceil(Lg/2)],:) = ...
            bsxfun(@times,f(win_range,:),g{ii}(idx));
        
        c{ii} = ifft(temp);
    end
end

if max(M) == min(M)
    c = cell2mat(c);
    c = reshape(c,M(1),N,W);
end

if nargout > 3
    shift = [Ls-posit(end); diff(posit)];% Frequency hop sizes in samples
end

