function [c,newphase,usedmask,tgrad,fgrad]=constructphasereal(s,g,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} constructphasereal
%@verbatim
%CONSTRUCTPHASEREAL  Construct phase for DGTREAL
%   Usage:  c=constructphasereal(s,g,a,M);
%           c=constructphasereal(s,g,a,M,tol);
%           c=constructphasereal(c,g,a,M,tol,mask);
%           c=constructphasereal(s,g,a,M,tol,mask,usephase);
%           [c,newphase,usedmask,tgrad,fgrad] = constructphasereal(...);
%
%   Input parameters:
%         s        : Initial coefficients.
%         g        : Analysis Gabor window.
%         a        : Hop factor.
%         M        : Number of channels.
%         tol      : Relative tolerance.
%         mask     : Mask for selecting known phase.
%         usephase : Explicit known phase.
%   Output parameters:
%         c        : Coefficients with the constructed phase.
%         newphase : Just the (unwrapped) phase.
%         usedmask : Mask for selecting coefficients with the new phase.
%         tgrad    : Relative time phase derivative.
%         fgrad    : Relative frequency phase derivative.
%
%   CONSTRUCTPHASEREAL(s,g,a,M) will construct a suitable phase for the 
%   positive valued coefficients s.
%
%   If s contains the absolute values of the Gabor coefficients of a signal
%   obtained using the window g, time-shift a and number of channels 
%   M, i.e.:
%
%     c=dgtreal(f,g,a,M);
%     s=abs(c);
%
%   then constuctphasereal(s,g,a,M) will attempt to reconstruct c.
%
%   The window g must be Gaussian, i.e. g must have the value 'gauss'
%   or be a cell array {'gauss',...}.
%
%   CONSTRUCTPHASEREAL(s,g,a,M,tol) does as above, but sets the phase of
%   coefficients less than tol to random values.
%   By default, tol has the value 1e-10. 
%
%   CONSTRUCTPHASEREAL(c,g,a,M,tol,mask) accepts real or complex valued
%   c and real valued mask of the same size. Values in mask which can
%   be converted to logical true (anything other than 0) determine
%   coefficients with known phase which is used in the output. Only the
%   phase of remaining coefficients (for which mask==0) is computed.
%
%   CONSTRUCTPHASEREAL(s,g,a,M,tol,mask,usephase) does the same as before
%   but uses the known phase values from usephase rather than from s.
%
%   In addition, tol can be a vector containing decreasing values. In 
%   that case, the algorithm is run numel(tol) times, initialized with
%   the result from the previous step in the 2nd and the further steps.
%
%   Further, the function accepts the following flags:
%
%      'freqinv'  The constructed phase complies with the frequency
%                 invariant phase convention such that it can be directly
%                 used in IDGTREAL.
%                 This is the default.
%
%      'timeinv'  The constructed phase complies with the time-invariant
%                 phase convention. The same flag must be used in the other
%                 functions e.g. IDGTREAL
%
%   This function requires a computational subroutine that is only
%   available in C. Use LTFATMEX to compile it.
%
%
%   References:
%     Z. Průša, P. Balazs, and P. L. Soendergaard. A Non-iterative Method for
%     STFT Phase (Re)Construction. IEEE/ACM Transactions on Audio, Speech,
%     and Language Processing, 2016. In preparation. Preprint will be
%     available at http://ltfat.github.io/notes/ltfatnote040.pdf.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/constructphasereal.html}
%@seealso{dgtreal, gabphasegrad, ltfatmex}
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

% AUTHOR: Peter L. Soendergaard, Zdenek Prusa

thismfilename = upper(mfilename);
complainif_notposint(a,'a',thismfilename);
complainif_notposint(M,'M',thismfilename);

definput.keyvals.tol=[1e-1,1e-10];
definput.keyvals.mask=[];
definput.keyvals.usephase=[];
definput.flags.phase={'freqinv','timeinv'};
definput.keyvals.tgrad = [];
definput.keyvals.fgrad = [];
[flags,kv,tol,mask,usephase]=ltfatarghelper({'tol','mask','usephase'},definput,varargin);

do_compgrad = 1;  

if ~any(cellfun(@isempty,{kv.tgrad,kv.fgrad}))
    do_compgrad = 0;
else
    if ~all(cellfun(@isempty,{kv.tgrad,kv.fgrad}))
        error('%s: Both fgrad nad tgrad must be defined.',upper(mfilename))
    end
end

if ~isnumeric(s) 
    error('%s: *s* must be numeric.',thismfilename);
end

if isempty(mask) 
    if ~isreal(s) || any(s(:)<0)
        error('%s: *s* must be real and positive when no mask is used.',...
              thismfilename);
    end
else 
    if any(size(mask) ~= size(s)) || ~isreal(mask)
        error(['%s: s and mask must have the same size and mask must',...
               ' be real.'],thismfilename)
    end
    % Sanitize mask (anything other than 0 is true)
    mask = cast(mask,'double');
    mask(mask~=0) = 1;
end

if ~isempty(usephase)
    if any(size(usephase) ~= size(s)) || ~isreal(usephase)
        error(['%s: s and usephase must have the same size and usephase must',...
               ' be real.'],thismfilename);
    end
else
    usephase = angle(s);
end

if ~isnumeric(tol) || ~isequal(tol,sort(tol,'descend'))
    error(['%s: *tol* must be a scalar or a vector sorted in a ',...
           'descending manner.'],thismfilename);
end


[M2,N,W] = size(s);

M2true = floor(M/2) + 1;

if M2true ~= M2
    error('%s: Mismatch between *M* and the size of *s*.',thismfilename);
end

L=N*a;

% Here we try to avoid calling gabphasegrad as it only works with full
% dgts.
abss = abs(s);

if do_compgrad
    [~,info]=gabwin(g,a,M,L,'callfun',upper(mfilename));

    if ~info.gauss && do_compgrad
        error(['%s: The window must be a Gaussian window (specified ',...
               'as a string or as a cell array)'],upper(mfilename));
    end

    logs=log(abss+realmin);
    tt=-11;
    logs(logs<max(logs(:))+tt)=tt;

    difforder = 2;
    fgrad = info.tfr*pderiv(logs,2,difforder)/(2*pi);
    % Undo the scaling done by pderiv and scale properly
    tgrad = pderiv(logs,1,difforder)/(2*pi*info.tfr)*(M/M2);

    % Fix the first and last rows .. the
    % borders are symmetric so the centered difference is 0
    tgrad(1,:) = 0;
    tgrad(end,:) = 0;
else
    if any(size(kv.tgrad) ~= size(s)) ||  any(size(kv.fgrad) ~= size(s))
        error('%s: tgrad and fgrad must have the same size as s',upper(mfilename));
    end
    L = N*a;
    b = L/M;
    tgrad = kv.tgrad*a;
    fgrad = kv.fgrad*b;
    flags.do_timeinv = 2;
end

[newphase, usedmask] = comp_constructphasereal(abss,tgrad,fgrad,a,M,tol,flags.do_timeinv,mask,usephase);

% Build the coefficients
c=abss.*exp(1i*newphase);



