function [tgrad,fgrad,s,c]=filterbankphasegrad(f,g,a,L,minlvl)
%-*- texinfo -*-
%@deftypefn {Function} filterbankphasegrad
%@verbatim
%FILTERBANKPHASEGRAD   Phase gradient of a filterbank representation
%   Usage:  [tgrad,fgrad,s,c] = filterbankphasegrad(f,g,a,L,minlvl);
%           [tgrad,fgrad,s,c] = filterbankphasegrad(f,g,a,L);
%           [tgrad,fgrad,s,c] = filterbankphasegrad(f,g,a,minlvl);
%           [tgrad,fgrad,s,c] = filterbankphasegrad(f,g,a);
%           [tgrad,fgrad,s] = filterbankphasegrad(...)
%           [tgrad,fgrad]  = filterbankphasegrad(...)
% 
%   Input parameters:
%      f     : Signal to be analyzed.
%      g     : Cell array of filters
%      a     : Vector of time steps.
%      L     : Signal length (optional).
%      minlvl: Regularization parameter (optional, required < 1).
%   Output parameters:
%      tgrad : Instantaneous frequency relative to original position.
%      fgrad : The negative of the local group delay. 
%      cs    : Filterbank spectrogram.
%      c     : Filterbank coefficients.
%
%   [tgrad,fgrad,s,c] = FILTERBANKPHASEGRAD(f,g,a,L) computes the 
%   relative instantaneous frequency tgrad and the negative of the group
%   delay fgrad of the filterbank spectrogram s obtained from the 
%   signal f and filterbank parameters g and a. 
%   Both tgrad and fgrad are specified relative to the original 
%   coefficient position entirely similar to GABPHASEGRAD.
%   fgrad is given in samples, while tgrad is given in normalised
%   frequencies such that the absolute frequencies are in the range of ]-1,1]. 
%
%   This routine uses the equivalence of the filterbank coefficients in 
%   each channel with coefficients obtained from an STFT obtained with a
%   certain window (possibly different for every channel). As a consequence
%   of this equivalence, the formulas derived in the reference apply. 
%
%
%   References:
%     F. Auger and P. Flandrin. Improving the readability of time-frequency
%     and time-scale representations by the reassignment method. IEEE Trans.
%     Signal Process., 43(5):1068--1089, 1995.
%     
%     N. Holighaus, Z. Průša, and P. L. Soendergaard. Reassignment and
%     synchrosqueezing for general time-frequency filter banks, subsampling
%     and processing. Signal Processing, 125:1--8, 2016. [1]http ]
%     
%     References
%     
%     1. http://www.sciencedirect.com/science/article/pii/S0165168416000141
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbankphasegrad.html}
%@seealso{gabphasegrad}
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

%   AUTHOR : Nicki Holighaus.

complainif_notenoughargs(nargin,3,'FILTERBANKPHASEGRAD');

% Reshape input signal
[f,~,W]=comp_sigreshape_pre(f,'FILTERBANKPHASEGRAD',0);
Ls = size(f,1);

if W>1
    error('%s: Only one-channel signals supported.',upper(mfilename));
end

if nargin < 5 
    if nargin < 4
        L = filterbanklength(Ls,a);
        minlvl = eps;
    else
        if ~(isscalar(L) && isnumeric(L) ) && L>0
            error('%s: Fourth argument shoud be a positive number.',...
                  upper(mfilename));
        end
        if L >= 1
            minlvl = eps;
        else
            minlvl = L;
        end;
    end
end;

complainif_notposint(L,'L','FILTERBANKPHASEGRAD');

Luser = filterbanklength(L,a);
if Luser~=L
    error(['%s: Incorrect transform length L=%i specified. ', ...
           'Next valid length is L=%i. See the help of ',...
           'FILTERBANKLENGTH for the requirements.'],...
           upper(mfilename),L,Luser);
end


% Unify format of coefficients
[g,asan]=filterbankwin(g,a,L,'normal');

% Precompute filters
[gh, gd, g] = comp_phasegradfilters(g, asan, L);

f=postpad(f,L);

c=comp_filterbank(f,g,asan); 
% Compute filterbank coefficients with frequency weighted window
ch=comp_filterbank(f,gh,asan);
% Compute filterbank coefficients with time weighted window
cd=comp_filterbank(f,gd,asan);

% Run the computation
[tgrad,fgrad,s] = comp_filterbankphasegrad(c,ch,cd,L,minlvl);

