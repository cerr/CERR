function [c,newphase,usedmask,tgrad,fgrad]=filterbankconstphase(s,a,fc,tfr,varargin)
%FILTERBANKCONSTPHASE Construct phase from FILTERBANK or UFILTERBANK magnitude 
%   Usage:  c=filterbankconstphase(s,a,fc,tfr);
%           c=filterbankconstphase(c,a,fc,tfr,mask);
%           c=filterbankconstphase(s,a,fc,tfr,mask,usephase);
%           c=filterbankconstphase(s,a,fc,{tgrad,fgrad},...);
%           [c,newphase,usedmask,tgrad,fgrad] = filterbankconstphase(...);
%
%   Input parameters:
%         s        : Initial coefficients.
%         a        : Downsampling factor(s).
%         fc       : Center frequencies (normalized to the Nyquist rate)
%         tfr      : ERB of the filters (normalized to the Nyquist rate)
%         mask     : Mask for selecting known phase.
%         usephase : Explicit known phase.
%   Output parameters:
%         c        : Coefficients with the constructed phase.
%         newphase : Just the (unwrapped) phase.
%         usedmask : Mask for selecting coefficients with the new phase.
%         tgrad    : Relative time phase derivative.
%         fgrad    : Relative frequency phase derivative.
%
%   FILTERBANKCONSTPHASE(s,a,tfr,fc) will construct a suitable phase for 
%   the positive valued coefficients s. 
%
%   If s is the absolute value of filterbank coefficients comming from
%   a filterbank with filters with center frequencies fc and time-frequency
%   ratios tfr and subsampling factors a i.e.:
%
%       [g,a,~,~,info] = ...filters(...);
%       c = filterbank(f,g,a);
%       s = abs(c);
%
%   then FILTERBANKCONSTPHASE(s,a,info.fc,info.tfr) will attempt to 
%   reconstruct c.
%
%   FILTERBANKCONSTPHASE(c,a,fc,tfr,mask) accepts real or complex valued
%   c and real valued mask of the same size. Values in mask which can
%   be converted to logical true (anything other than 0) determine
%   coefficients with known phase which is used in the output. Only the
%   phase of remaining coefficients (for which mask==0) is computed.
%
%   FILTERBANKCONSTPHASE(c,a,fc,tfr,mask,usephase) does the same as before
%   but uses the known phase values from usephase rather than from c.
%
%   FILTERBANKCONSTPHASE(s,a,fc,{tgrad,fgrad},...) accepts the phase 
%   gradient {tgrad,fgrad} explicitly instead of computing it from
%   the magnitude using tfr and the phase-magnitude relationship.
%   This is directly compatible with FILTERBANKPHASEGRAD.
%
%   Addition parameters
%   -------------------
%
%   The function accepts the following additional paramaters:
%
%   'tol',tol 
%           The phase is computed only for coefficients above tol. The
%           rest is set to random values.
%           In addition, tol can be a vector containing decreasing values. 
%           In that case, the algorithm is run numel(tol) times, 
%           initialized with the result from the previous step in the 2nd 
%           and the further steps. 
%           The default value is tol=[1e-1, 1e-10].
%
%   'real' (default) or 'complex'
%           By default, the coefficients are expected to come from a real
%           filterbank i.e. the filters cover only the positive
%           frequencies. For filterbanks which cover the whole frequency
%           range, pass 'complex' instead.
%
%   'naturalscaling' (default) or 'peakscaling' or 'custscaling',scal
%           Relative scaling of the filter frequency responses. 
%           'naturalscaling' deduces the scaling of the filters from the
%           subsampling factors a. 
%           'peakscaling' assumes all frequency responses were notmalized 
%           to have peaks of equal height.
%           'custscaling',scal allows passing a custom scaling vector scal. 
%
%   'filterbank' (default) or 'wavelet'
%           Version of the phase-magnitude relationship to be used. In
%           contrast to 'filterbank', the 'wavelet' option does not contain the
%           term involving the derivative of sqrt(tfr). 
%           See the references for more details.
%           
%   This function requires a computational subroutine that is only
%   available in C. Use LTFATMEX to compile it.
%
%   Example
%   -------
%
%   The following example shows basic usage
%
%       
%
%   See also:  ltfatmex filterbank ufilterbank audfilters cqtfilters gabfilters
%
%
%   References:
%     N. Holighaus, G. Koliander, and Z. Průša. On the derivatives of the
%     continuous wavelet transform - with application to phaseless
%     reconstruction. Submitted., 2018.
%     
%     Z. Průša and N. Holighaus. Non-iterative filter bank phase
%     (re)construction. In Proc. 25th European Signal Processing Conference
%     (EUSIPCO--2017), pages 952--956, Aug 2017.
%     
%
%
%   Url: http://ltfat.github.io/doc/filterbank/filterbankconstphase.html

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

% AUTHOR: Nicki Holighaus, Zdenek Prusa

thismfilename = upper(mfilename);
complainif_notenoughargs(nargin,4,thismfilename);

if ~(isnumeric(s) || iscell(s)) || isempty(s)
    error('%s: *s* must be numeric or cell.',thismfilename);
 end

if ~isnumeric(a) || isempty(a)
    error('%s: a must be non-empty numeric.',upper(mfilename));
end

definput.keyvals.tol=[1e-1,1e-10];
definput.keyvals.gderivweight=1/2;
definput.keyvals.mask=[];
definput.keyvals.usephase=[];
definput.keyvals.custscaling=[];
definput.flags.real = {'real','complex'};
definput.flags.scaling = {'naturalscaling','peakscaling','custscaling'};
definput.flags.phasemagrel = {'gabor','wavelet'};
[flags,kv,mask,usephase]=ltfatarghelper({'mask','usephase'},definput,varargin);
tol = kv.tol;

if ~isnumeric(tol) || ~isequal(tol,sort(tol,'descend'))
    error(['%s: *tol* must be a scalar or a vector sorted in a ',...
          'descending manner.'],thismfilename);
end

if ~isempty(usephase) && isempty(mask)
    error('%s: Both mask and usephase must be used at the same time.',...
          upper(mfilename));
end

if ~isempty(usephase)
    complainif_notequalsize('usephase',usephase,'s',s,mfilename);
    complainif_notreal('usephase',usephase,mfilename);
end

if ~isempty(mask)
    complainif_notequalsize('mask',mask,'s',s,mfilename);
    complainif_notreal('mask',mask,mfilename);
end

if iscell(s)
    M = numel(s);
    N = cellfun(@(sEl) size(sEl,1),s);
    W = size(s{1},2);
else
    [N,M,W] = size(s);
end

do_uniform = 1;
wasCell = 0;
tgrad = []; fgrad = [];

asan = comp_filterbank_a(a,M);
a = asan(:,1)./asan(:,2);
L = N.*a;

%TODO: Check all L?
if isa(fc,'function_handle'), fc = fc(L(1)); end
if isa(tfr,'function_handle'), tfr = tfr(L(1)); end
if isscalar(tfr), tfr = repmat(tfr,M,1); end

if ~isnumeric(fc) || isempty(fc) || numel(fc) ~= M
  error('%s: fc must be non-empty numeric.',upper(mfilename));
end

if  ~( (isvector(tfr) && ~isempty(tfr) && numel(tfr) == M ) || ...
       (iscell(tfr) && numel(tfr) == 2 ...
       && all(cellfun(@(tEl) isequal(size(tEl),size(s)),tfr))))
    error(['%s: tfr must be either a vector of length %d or a ',...
           '2 element cell array containing phase derivatives such that ',...
           '{tgrad,fgrad}.'],upper(mfilename),M);
end

if flags.do_naturalscaling
    scal = 1./(sqrt(asan(:,1)./asan(:,2)));
elseif flags.do_peakscaling
    scal = ones(M,1);
elseif flags.do_custscaling
    if isempty(kv.custscaling) || ~isvector(kv.custscaling) ...
       || ~isnumeric(kv.custscaling) || numel(kv.custscaling) ~= M
        error(['%s: value for key custscaling must be a numeic vector',...
               ' of length %d.'],thismfilename,M);
    end
    scal = kv.custscaling(:);
end

if iscell(s)
    if iscell(tfr)
        complainif_notequalsize('tgrad',tfr{1},'s',s,mfilename);
        complainif_notreal('tgrad',tfr{1},mfilename);
        complainif_notequalsize('fgrad',tfr{2},'s',s,mfilename);
        complainif_notreal('fgrad',tfr{2},mfilename);
    end

    wasCell = 1;

    if any( N ~= N(1)) && any( a ~= a(1) )
        do_uniform = 0;
        abss = abs(cell2mat(cellfun(@times,s,num2cell(scal),'UniformOutput',0)));
        swork = cell2mat(s);
        if ~isempty(mask),         mask = cell2mat(mask);  end
        if ~isempty(usephase), usephase = cell2mat(usephase); end
        if iscell(tfr)
            tgrad = cell2mat(tfr{1});
            fgrad = cell2mat(tfr{2});
        end
    else
        swork = zeros(N(1),M,W);
        for m=1:M, swork(:,m,:)=s{m}; end
        if iscell(tfr)
            tgrad = zeros(N(1),M,W);
            fgrad = zeros(N(1),M,W);
            for m=1:M
                tgrad(:,m,:)=tfr{1}{m}; 
                fgrad(:,m,:)=tfr{2}{m}; 
            end
        end

        a = a(1);
    end
else
    swork = s;
    a = a(1);
end

if do_uniform
    abss = abs(bsxfun(@times,swork,scal(:).'));
end

if isempty(usephase)
    usephase = angle(swork);
else
    if ~isreal(usephase)
        error('%s: usephase must be real.',thismfilename);
    end
end

if ~isempty(mask) 
    if ~isreal(mask)
        error('%s: mask must be real.',thismfilename);
    end
    mask = cast(mask,'double');
    mask(mask~=0) = 1;
end

if isempty(tgrad) && isempty(fgrad)
    tfr = sqrt(tfr);% sqrt(1./( (tfr./1.875657).^2*L(1) ));
end

if do_uniform
    if isempty(tgrad) && isempty(fgrad)
        [tgrad,fgrad] = ...
            comp_ufilterbankphasegradfrommag(...
            abss,N(1),a,M,tfr,fc,flags.do_real,flags.do_gabor);
    end

    [newphase,usedmask] = ...
        comp_ufilterbankconstphase(...
        abss,tgrad,fgrad,fc,mask,usephase,a,tol,0,flags.do_real);
else
    [NEIGH, posInfo] = comp_filterbankneighbors(a,M,N,flags.do_real);
    NEIGH = NEIGH-1;

    if isempty(tgrad) && isempty(fgrad)
        [tgrad,fgrad] = ...
            comp_filterbankphasegradfrommag(...
            abss,N,a,M,tfr,fc,NEIGH,posInfo,kv.gderivweight,flags.do_gabor);
    end

    [newphase,usedmask] = ...
        comp_filterbankconstphase(...
        abss,tgrad,fgrad,NEIGH,posInfo,fc,mask,usephase,a,M,N,tol,0);
end

c = abs(swork).*exp(1i*newphase);

if wasCell
    % Apply the phase and convert back to cell array 
    c = mat2cell(c(:),N,W);
    newphase = mat2cell(newphase(:),N,W);
    usedmask = mat2cell(usedmask(:),N,W);
    tgrad = mat2cell(tgrad(:),N,W);
    fgrad = mat2cell(fgrad(:),N,W);
end


function complainif_notequalsize(aname,a,bname,b,thismfilename)

if ~isequal(class(a), class(b))
    error('%s: %s and %s must be of the same type.',...
          aname, bname, thismfilename);
end

if ~isequal(size(a), size(b))
    error('%s: %s and %s must have equal sizes.',...
          aname, bname,thismfilename);
end

if iscell(a)
    if ~all(cellfun(@(aEl,bEl) isequal(size(aEl),size(bEl)),a,b))
        error('%s: %s and %s must have equal sizes.',...
              aname, bname,thismfilename);
    end
end

function complainif_notreal(aname,a,thismfilename)

if iscell(a)
    isareal = all(cellfun(@isreal,a));
else
    isareal = isreal(a);
end

if ~isareal
    error('%s: %s must be real.',thismfilename,aname);
end


