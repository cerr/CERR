function [phased,c]=gabphasederiv(type,method,varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabphasederiv
%@verbatim
%GABPHASEDERIV   DGT phase derivatives
%   Usage:  [phased,c] = gabphasederiv(dflag,'dgt',f,g,a,M);
%            phased    = gabphasederiv(dflag,'cross',f,g,a,M)
%            phased    = gabphasederiv(dflag,'phase',cphase,a,difforder);
%            phased    = gabphasederiv(dflag,'abs',s,g,a);
%           [{phased1,phased2,...}] = gabphasederiv({dflag1,dflag2,...},...);
%           [{phased1,phased2,...},c] = gabphasederiv({dflag1,dflag2,...},'dgt',...);
%
%   phased=GABPHASEDERIV(dflag,method,...) computes the time-frequency
%   derivative dflag of the phase of the DGT of a signal using algorithm
%   method.
%
%   The following strings can be used in place of dflag:
%
%     't'   First phase derivative in time.
%
%     'f'   First phase derivative in frequency.
%
%     'tt'  Second phase derivative in time.
%
%     'ff'  Second phase derivative in frequency.
%
%     'tf' or 'ft'  Second order mixed phase derivative.
%
%   phased is scaled such that (possibly non-integer) distances are measured
%   in samples. Similarly, the frequencies are scaled such that the Nyquist
%   frequency (the highest possible frequency) corresponds to a value of L/2.
%
%   The computation of phased is inaccurate when the absolute
%   value of the Gabor coefficients is low. This is due to the fact the the
%   phase of complex numbers close to the machine precision is almost
%   random. Therefore, phased attain very large random values when abs(c)
%   is close to zero.
%
%   The phase derivative computation can be done using four different methods
%   depending on the string method:
%
%     'dgt'    Directly from the signal using algorithm by Auger and
%              Flandrin.
%
%     'cross'  Directly from the signal using algorithm by Nelson.
%
%     'phase'  From the unwrapped phase of a DGT of the signal using a
%              finite differences scheme. This is the classic method used
%              in the phase vocoder.
%
%     'abs'    From the absolute value of the DGT exploiting explicit
%              dependency between partial derivatives of log-magnitudes and
%              phase.
%              Currently this method works only for Gaussian windows.
%
%   phased=GABPHASEDERIV(dflag,'dgt',f,g,a,M) computes the time-frequency
%   derivative using a DGT of the signal f. The DGT is computed using the
%   window g on the lattice specified by the time shift a and the number
%   of channels M. The algorithm used to perform this calculation computes
%   several DGTs, and therefore this routine takes the exact same input
%   parameters as DGT.
%
%   [phased,c]=GABPHASEDERIV(dflag,'dgt',f,g,a,M) additionally returns
%   the Gabor coefficients c, as they are always computed as a byproduct
%   of the algorithm.
%
%   phased=GABPHASEDERIV(dflag,'cross',f,g,a,M) does the same as above
%   but this time using algorithm by Nelson which is based on computing
%   several DGTs.
%
%   phased=GABPHASEDERIV(dflag,'phase',cphase,a) computes the phase
%   derivative from the phase cphase of a DGT of the signal. The original DGT
%   from which the phase is obtained must have been computed using a
%   time-shift of a using the default phase convention ('freqinv') e.g.:
%
%        phased=gabphasederiv(dflag,'phase',angle(dgt(f,g,a,M)),a)
%
%   phased=GABPHASEDERIV(dflag,'abs',s,g,a) computes the phase derivative
%   from the absolute values of DGT coefficients s. The spectrogram must have
%   been computed using the window g and time-shift a e.g.:
%
%        phased=gabphasederiv(dflag,'abs',abs(dgt(f,g,a,M)),g,a)
%
%   Currently the 'abs' method only works if the window g is a Gaussian
%   window specified as a string or a cell array.
%
%   phased=GABPHASEDERIV(dflag,'abs',s,g,a,difforder) uses a centered finite
%   diffence scheme of order difforder to perform the needed numerical
%   differentiation. Default is to use a 4th order scheme.
%
%   Phase conventions
%   -----------------
%
%   First derivatives in either direction are subject to phase convention.
%   The following additional flags define the phase convention the original
%   phase would have had:
%
%     'freqinv'     Derivatives reflect the frequency-invariant phase of dgt.
%                   This is the default.
%
%     'timeinv'     Derivatives reflect the time-invariant phase of dgt.
%
%     'symphase'    Derivatives reflect the symmetric phase of dgt.
%
%     'relative'    This is a combination of 'freqinv' and 'timeinv'.
%                   It uses 'timeinv' for derivatives along frequency and
%                   and 'freqinv' for derivatives along time and for the
%                   mixed derivative.
%                   This is usefull for the reassignment functions.
%
%   Please see ltfatnote042 for the description of relations between the
%   phase derivatives with different phase conventions. Note that for the
%   'relative' convention, the following holds:
%
%      gabphasederiv('t',...,'relative') == gabphasederiv('t',...,'freqinv')
%      gabphasederiv('f',...,'relative') == -gabphasederiv('f',...,'timeinv')
%      gabphasederiv('tt',...,'relative') == gabphasederiv('tt',...)
%      gabphasederiv('ff',...,'relative') == -gabphasederiv('ff',...)
%      gabphasederiv('tf',...,'relative') == gabphasederiv('tf',...,'freqinv')
%
%   Several derivatives at once
%   ---------------------------
%
%   phasedcell=GABPHASEDERIV({dflag1,dflag2,...},...) computes several
%   phase derivatives at once while reusing some temporary computations thus
%   saving computation time.
%   {dflag1,dflag2,...} is a cell array of the derivative flags and
%   cell elements of the returned phasedcell contain the corresponding
%   derivatives i.e.:
%
%       [pderiv1,pderiv2,...] = deal(phasedcell{:});
%
%   [phasedcell,c]=GABPHASEDERIV({dflag1,dflag2,...},'dgt',...) works the
%   same as above but in addition returns coefficients c which are the
%   byproduct of the 'dgt' method.
%
%   Other flags and parameters work as before.
%
%
%   References:
%     F. Auger and P. Flandrin. Improving the readability of time-frequency
%     and time-scale representations by the reassignment method. IEEE Trans.
%     Signal Process., 43(5):1068--1089, 1995.
%     
%     E. Chassande-Mottin, I. Daubechies, F. Auger, and P. Flandrin.
%     Differential reassignment. Signal Processing Letters, IEEE,
%     4(10):293--294, 1997.
%     
%     J. Flanagan, D. Meinhart, R. Golden, and M. Sondhi. Phase Vocoder. The
%     Journal of the Acoustical Society of America, 38:939, 1965.
%     
%     K. R. Fitz and S. A. Fulop. A unified theory of time-frequency
%     reassignment. CoRR, abs/0903.3080, 2009.
%     
%     D. J. Nelson. Instantaneous higher order phase derivatives. Digital
%     Signal Processing, 12(2-3):416--428, 2002. [1]http ]
%     
%     F. Auger, E. Chassande-Mottin, and P. Flandrin. On phase-magnitude
%     relationships in the short-time fourier transform. Signal Processing
%     Letters, IEEE, 19(5):267--270, May 2012.
%     
%     Z. Průša. STFT and DGT phase conventions and phase derivatives
%     interpretation. Technical report, Acoustics Research Institute,
%     Austrian Academy of Sciences, 2015.
%     
%     References
%     
%     1. http://dx.doi.org/10.1006/dspr.2002.0456
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabphasederiv.html}
%@seealso{resgram, gabreassign, dgt, pderiv, gabphasegrad}
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


% AUTHOR: Peter L. Soendergaard, 2008; Zdenek Průša, 2015

% REMARK: There is no problem with phase conventions with the second
% derivatives.

complainif_notenoughargs(nargin,2,upper(mfilename));

definput.flags.type = {'t','f','tt','ff','tf','ft'};
definput.flags.method = {'dgt','phase','abs','cross'};
definput.import = {'gabphasederivconv'};

typewascell = 0;

if ischar(type)
    types = {type};
elseif iscell(type)
    %error('Multiple derivatives at once were not implemented yet.');
    types = type;
    typewascell = 1;
else
    error('%s: First argument must be either char or a cell array.',...
        upper(mfilename));
end

types = lower(types);

for ii=1:numel(types)
    type = types{ii};
    if ~ischar(type) || ~any(strcmpi(type, definput.flags.type))
        error(['%s: First argument must contain the type of the derivative: %s'],...
            upper(mfilename),...
            strjoin(cellfun(@(el) sprintf('"%s"',el),...
            definput.flags.type,'UniformOutput',0),', '));
    end
end

if ~ischar(method) || ~any(strcmpi(method, definput.flags.method))
    error(['%s: Second argument must be the method name: %s '], ...
        upper(mfilename),...
        strjoin(cellfun(@(el) sprintf('"%s"',el),...
        definput.flags.method,'UniformOutput',0),', '));
end;

diphaseconv = arg_gabphasederivconv;
foundFlags = cellfun(@(el)ischar(el) && any(strcmpi(el,diphaseconv.flags.phaseconv)),...
    varargin);
flags1 = ltfatarghelper({},definput,{types{1},method,varargin{foundFlags}});
definput = []; % Definput is used again later
varargin(foundFlags) = []; % Remove the phaseconv flags

switch flags1.method
    case {'phase','abs'}
        if nargout>1
            error('%s: Too many output arguments. ', upper(mfilename));
        end
end

% Change ft to tf as they are equal
if any(strcmpi('ft',types))
    types(strcmpi('ft',types)) = {'tf'};
end

% Get only unique flags
[~,tmpidx] = unique(types,'first');
dflagsUnique = types(sort(tmpidx));

% Find duplicates
dflagsDupl = cellfun(@(tEl) strcmpi(tEl,types),dflagsUnique,'UniformOutput',0);
% Sort the unique flags according to character count
[~,dflagsOrder]=sort(cellfun(@length,dflagsUnique));
% Sort
dflagsUnique = dflagsUnique(dflagsOrder);

% Allocate the output cell array
phased2 = cell(1,numel(dflagsUnique));

switch flags1.method
    case {'dgt','cross'}
        complainif_notenoughargs(numel(varargin),4,mfilename);
        [f,gg,a,M]=deal(varargin{1:4});

        definput.keyvals.L=[];
        definput.keyvals.minlvl=eps;
        definput.keyvals.lt=[0 1];
        [~,kv,L,minlvl]=ltfatarghelper({'L','minlvl'},definput,varargin(5:end));

        % Change f to correct shape.
        [f,Ls]=comp_sigreshape_pre(f,upper(mfilename),0);

        % Even though this check is also in dgt, we must do it here too
        if isempty(L)
            L = dgtlength(Ls,a,M,kv.lt);
        else
            Luser = dgtlength(L,a,M,kv.lt);
            if Luser~=L
                error(['%s: Incorrect transform length L=%i specified. Next valid length ' ...
                    'is L=%i. See the help of DGTLENGTH for the requirements.'],...
                    upper(mfilename),L,Luser);
            end
        end

        % Extend or crop f to correct length
        f=postpad(f,L);
        N = L/a;
        b = L/M;
end

switch flags1.method
    case 'dgt'
        % ---------------------------  DGT method ------------------------
        %
        % Naming conventions used here:
        % c    - dgt coefficients using window g
        % c_s  - second power of c with small values set to minlvl*max(c_s)
        % c_h  - dgt coefficietns computed using time-weighted window hg
        % c_d  - dgt coefficients computed using time-derived window dg
        % c_h2 - dgt coefficients computed using twice time-weighted window hg2
        % c_d2 - dgt coefficients computed using second derivative of window g: hg2
        % c_hd - dgt coefficients computed using time-weighted derivative of window g: hdg
        % c_dh - dgt coefficients computed using derivative of time-weighted window g: dhg
        %

        % Call dgt once to check all the parameters
        % This computes frequency invariant phase.
        [c,~,g] = dgt(f,gg,a,M,L,'lt',kv.lt);

        % Compute spectrogram and remove small values because we need to
        % divide by c_s.
        % This will also set the derivative to zeros in the regions
        % containing only small coefficients.
        c_s = abs(c).^2;
        c_s = max(c_s,minlvl*max(c_s(:)));

        % We also need info for info.gauss
        [~,info]=gabwin(gg,a,M,L,kv.lt,'callfun',upper(mfilename));

        % These could be shared
        dg = []; c_d = []; hg = []; c_h = [];

        for typedId=1:numel(dflagsUnique)
            typed = dflagsUnique{typedId};

            if info.gauss
                % TODO: Save computations for 2nd derivatives
            end

            switch typed
                case 't'
                    if info.gauss && ~isempty(c_h)
                        phased = -imag(c_h.*conj(c)./c_s)/info.tfr;
                    else

                        % fir2long is here to avoid possible boundary effects
                        % as the time support of the Inf derivative is not FIR
                        dg  = pderiv(fir2long(g,L),[],Inf)/(2*pi);
                        c_d = comp_dgt(f,flipwin(dg),a,M,kv.lt,0,0,0);

                        phased = imag(c_d.*conj(c)./c_s);
                    end

                    switch flags1.phaseconv
                        case {'freqinv','relative'}
                            % Do nothing
                        case 'timeinv'
                            phased = bsxfun(@plus,phased,fftindex(M)*b);
                        case 'symphase'
                            phased = bsxfun(@plus,phased,fftindex(M)*b/2);
                    end
                case 'f'
                    if info.gauss && ~isempty(c_d)
                        phased = -real(c_d.*conj(c)./c_s)*info.tfr;
                    else
                        % Compute the time weighted version of the window.
                        % g is already a column vector
                        hg = fftindex(size(g,1)).*g;
                        c_h = comp_dgt(f,flipwin(hg),a,M,kv.lt,0,0,0);

                        phased = real(c_h.*conj(c)./c_s);
                    end

                    switch flags1.phaseconv
                        case 'timeinv'
                            % Do nothing
                        case 'relative'
                            phased = -phased;
                        case 'freqinv'
                            phased = bsxfun(@plus,phased,-fftindex(N).'*a);
                        case 'symphase'
                            phased = bsxfun(@plus,phased,-fftindex(N).'*a/2);
                    end
                case 'tt'
                    if isempty(dg)
                        dg  = pderiv(fir2long(g,L),[],Inf)/(2*pi);
                        c_d = comp_dgt(f,flipwin(dg),a,M,kv.lt,0,0,0);
                    end
                    dg2 = pderiv(dg,[],Inf);
                    c_d2 = comp_dgt(f,flipwin(dg2),a,M,kv.lt,0,0,0);

                    phased = imag(c_d2.*conj(c)./c_s - 2*pi*(c_d.*conj(c)./c_s).^2)/L;
                    % Phase convention does not have any effect
                case 'ff'
                    if isempty(hg)
                        % Time weighted window
                        hg =  fftindex(size(g,1)).*g;
                        c_h = comp_dgt(f,flipwin(hg),a,M,kv.lt,0,0,0);
                    end
                    hg2 = fftindex(size(g,1)).^2.*g;
                    c_h2 = comp_dgt(f,flipwin(hg2),a,M,kv.lt,0,0,0);

                    phased = imag(-c_h2.*conj(c)./c_s + (c_h.*conj(c)./c_s).^2)*2*pi/L;

                    switch flags1.phaseconv
                        case 'relative'
                            phased = -phased;
                    end
                case {'ft','tf'}
                    if isempty(hg)
                        hg = fftindex(size(g,1)).*g;
                        c_h = comp_dgt(f,flipwin(hg),a,M,kv.lt,0,0,0);
                    end

                    if isempty(dg)
                        dg = pderiv(fir2long(g,L),[],Inf)/(2*pi);
                        c_d = comp_dgt(f,flipwin(dg),a,M,kv.lt,0,0,0);
                    end

                    hdg = (fftindex(size(dg,1))/L).*dg;
                    c_hd = comp_dgt(f,flipwin(hdg),a,M,kv.lt,0,0,0);

                    % This is mixed derivative tf for freq. invariant
                    phased = real(c_hd.*conj(c)./c_s - (1/L)*c_h.*c_d.*(conj(c)./c_s).^2)*2*pi;

                    switch flags1.phaseconv
                        case {'freqinv','relative'}
                            % Do nothing
                        case 'timeinv'
                            phased = phased + 1;
                        case 'symphase'
                            phased = phased + 1/2;
                    end
                otherwise
                    error('%s: This should never happen.',upper(mfilename));
            end
            phased2{typedId} = phased;
        end


    case 'phase'
        % ----------  Direct numerical derivative of the phase  ----------------
        complainif_notenoughargs(numel(varargin),2,mfilename);
        [cphase,a]=deal(varargin{1:2});
        complainif_notposint(a,'a',mfilename)

        if ~isreal(cphase)
            error(['%s: Input phase must be real valued. Use the "angle" ' ...
                'function to compute the argument of complex numbers.'],...
                upper(mfilename));
        end;

        % --- linear method ---
        [M,N,W]=size(cphase);
        L=N*a;
        b=L/M;

        tgrad = []; fgrad = [];

        for typedId=1:numel(dflagsUnique)
            typed = dflagsUnique{typedId};
            % REMARK: Second derivative in one direction does not need phase
            % unwrapping
            if isempty(tgrad) && any(strcmpi(typed,{'t','tt','ft','tf'}))
                % This is the classic phase vocoder algorithm by Flanagan modified to
                % yield a second order centered difference approximation.

                % Perform derivative along rows while unwrapping the phase by 2*pi
                tgrad = pderivunwrap(cphase,2,2*pi);
                % Normalize
                %tgrad = tgrad/(2*pi);
                % Normalize again using time step
                tgrad = tgrad/(a);
            end

            if isempty(fgrad) && any(strcmpi(typed,{'f','ff'}))
                % Phase-lock the angles.
                % We have the frequency invariant phase ...
                TimeInd = (0:(N-1))*a;
                FreqInd = (0:(M-1))/M;

                phl = FreqInd'*TimeInd;
                cphaseLock = cphase+2*pi.*phl;
                % ... and now the time-invariant phase.

                % Perform derivative along cols while unwrapping the phase by 2*pi
                fgrad = pderivunwrap(cphaseLock,1,2*pi);

                % Convert from radians to relative frequencies
                %fgrad = fgrad/(2*pi);
                % Normalize again using frequency step
                fgrad = fgrad/(b);
            end

            % tgrad fgrad here are relative quantites

            switch typed
                case 't'
                    phased = tgrad*L/(2*pi);

                    switch flags1.phaseconv
                        case {'freqinv','relative'}
                            % Do nothing
                        case 'timeinv'
                            phased = bsxfun(@plus,phased,fftindex(M)*b);
                        case 'symphase'
                            phased = bsxfun(@plus,phased,fftindex(M)*b/2);
                    end
                case 'f'
                    phased = fgrad*L/(2*pi);

                    switch flags1.phaseconv
                        case 'timeinv'
                            % Do nothing
                        case 'relative'
                            phased = -phased;
                        case 'freqinv'
                            phased = bsxfun(@plus,phased,-fftindex(N).'*a);
                        case 'symphase'
                            phased = bsxfun(@plus,phased,-fftindex(N).'*a/2);
                    end
                case 'tt'
                    % Second derivatives should be independent of the phase
                    % convention.
                    % tgrad is already unwrapped along time, we can call pderiv
                    % directly.
                    phased = pderiv(tgrad,2,2)/(2*pi);
                    % Phase convention does not have any effect.
                case 'ff'
                    % fgrad is already unwrapped along frequency
                    phased = pderiv(fgrad,1,2)/(2*pi);

                    switch flags1.phaseconv
                        case 'relative'
                            phased = -phased;
                    end
                case {'tf','ft'}
                    % Phase has not yet been unwrapped along frequency
                    phased = pderivunwrap(tgrad,1,2*pi)*M/(2*pi);

                    switch flags1.phaseconv
                        case 'timeinv'
                            phased = phased +1;
                        case {'freqinv','relative'}
                            % Do nothing
                        case 'symphase'
                            phased = phased +1/2;
                    end

                    % Phase has not yet been unwrapped along time
                    % phased = pderivunwrap(fgrad,2,2*pi)*N/(2*pi);
                otherwise
                    error('%s: This should never happen.',upper(mfilename));
            end
            phased2{typedId} = phased;
        end
    case 'abs'
        % ---------------------------  abs method ------------------------

        complainif_notenoughargs(numel(varargin),3,mfilename);
        [s,g,a]=deal(varargin{1:3});
        complainif_notposint(a,'a',mfilename)

        if numel(varargin)>3
            difforder=varargin{4};
        else
            difforder=4;
        end;

        if ~(all(s(:)>=0))
            error('%s: s must be positive or zero.',mfilename);
        end;

        [M,N,W]=size(s);

        L=N*a;

        [~,info]=gabwin(g,a,M,L,'callfun',upper(mfilename));

        if ~info.gauss
            error(['%s: The window must be a Gaussian window (specified as a string or ' ...
                'as a cell array).'],upper(mfilename));
        end;

        L=N*a;
        b=L/M;

        % We must avoid taking the log of zero.
        % Therefore we add the smallest possible
        % number
        logs=log(s+realmin);

        % XXX REMOVE Add a small constant to limit the dynamic range. This should
        % lessen the problem of errors in the differentiation for points close to
        % (but not exactly) zeros points.
        maxmax=max(logs(:));
        tt=-11; % This is equal to about 95dB of 'normal' dynamic range

        logs(logs<maxmax+tt)=tt;

        for typedId=1:numel(dflagsUnique)
            typed = dflagsUnique{typedId};

            tgrad = []; fgrad = [];
            if isempty(tgrad) && any(strcmpi(typed,{'t','tt','ft','tf'}))
                tgrad = pderiv(logs,1,difforder)/(2*pi);
            end

            if isempty(fgrad) && any(strcmpi(typed,{'f','ff'}))
                fgrad = -pderiv(logs,2,difforder)/(2*pi);
            end


            switch typed
                case 't'
                    % Derivative of log-magnitude along frequency gives phase
                    % time derivative
                    phased=tgrad/info.tfr;

                    switch flags1.phaseconv
                        case {'freqinv','relative'}
                            % Do nothing
                        case 'timeinv'
                            phased = bsxfun(@plus,phased,fftindex(M)*b);
                        case 'symphase'
                            phased = bsxfun(@plus,phased,fftindex(M)*b/2);
                    end

                case 'f'
                    % Derivative of log-magnitude along time gives phase frequency
                    % derivative
                    phased= fgrad*info.tfr;

                    switch flags1.phaseconv
                        case 'timeinv'
                            % Do nothing
                        case 'relative'
                            phased = - phased;
                        case 'freqinv'
                            phased = bsxfun(@plus,phased,-fftindex(N).'*a);
                        case 'symphase'
                            phased = bsxfun(@plus,phased,-fftindex(N).'*a/2);
                    end

                case 'ff'
                    % Mixed derivatives of log-magnitude give second derivative
                    % of phase
                    phased= info.tfr*pderiv(fgrad,1,difforder)/L;

                    switch flags1.phaseconv
                        case 'relative'
                            phased = -phased;
                    end
                case 'tt'
                    % Second phase derivatives are equal up to factor
                    % -info.tfr^2
                    phased=pderiv(tgrad,2,difforder)/(L*info.tfr);
                    % Phase convention does not have any effect
                case {'ft','tf'}
                    % (Both) second log-magnitude derivatives give mixed phase
                    % derivatives.
                    phased = pderiv(tgrad,1,difforder)/(info.tfr*L);

                    % This is equal
                    % phased = pderiv(logs,2,difforder)/(2*pi);
                    % phased = -info.tfr*pderiv(phased,2,difforder)/L - 1;

                    switch flags1.phaseconv
                        case {'freqinv','relative'}
                            % Do nothing
                        case 'timeinv'
                            phased = phased + 1;
                        case 'symphase'
                            phased = phased + 1/2;
                    end

                otherwise
                    error('%s: This should never happen.',upper(mfilename));
            end
            phased2{typedId} = phased;
        end

    case 'cross'
        % This is the Nelson's cross-spectral matrix algorithm modified to
        % do centered finite difference approximations of the derivatives

        [g,info] = gabwin(gg,a,M,L,kv.lt,'callfun',upper(mfilename));

        if info.gl<L-2
            % FIR case
            gtmp = fir2long(g,numel(g)+2);
        else
            % fir2long is here to cover gl == L-2 and L-1
            gtmp = fir2long(g,L);
        end


        cright = []; cleft = []; cabove = []; cbelow = []; ccenterfi = [];
        ccenterti = [];
        crightabove = []; crightbelow = []; cleftabove = []; cleftbelow = [];
        for typedId=1:numel(dflagsUnique)
            typed = dflagsUnique{typedId};

            if (isempty(cright) || isempty(cleft)) && any(strcmpi(typed,{'t','tt'}))
                cright = dgt(f,shiftwin(gtmp,1,0),a,M,L,'lt',kv.lt);
                cleft = dgt(f,shiftwin(gtmp,-1,0),a,M,L,'lt',kv.lt);
            end

            if (isempty(cabove) || isempty(cbelow)) && any(strcmpi(typed,{'f','ff'}))
                cabove = dgt(f,shiftwin(gtmp,0,1),a,M,L,'lt',kv.lt,'timeinv');
                cbelow = dgt(f,shiftwin(gtmp,0,-1),a,M,L,'lt',kv.lt,'timeinv');
            end

            if isempty(ccenterfi) && any(strcmpi(typed,{'tt','t'}))
                ccenterfi = dgt(f,gg,a,M,L,'lt',kv.lt);
            end

            if isempty(ccenterti) && any(strcmpi(typed,{'ff','f'}))
                ccenterti = dgt(f,gg,a,M,L,'lt',kv.lt,'timeinv');
            end

            if (isempty(crightabove) || isempty(crightbelow) || ...
                isempty(cleftabove) || isempty(cleftbelow)) ...
                && any(strcmpi(typed,{'tf','ft'}))
                % Get four DGTs shifted by one in time and in frequency
                frightabove = circshift(f,-1).*exp(-1i*2*pi*(0:L-1)'./L);
                crightabove = dgt(frightabove,gg,a,M,L,'lt',kv.lt);

                frightbelow = circshift(f,-1).*exp(1i*2*pi*(0:L-1)'./L);
                crightbelow = dgt(frightbelow,gg,a,M,L,'lt',kv.lt);

                fleftabove = circshift(f,1).*exp(-1i*2*pi*(0:L-1)'./L);
                cleftabove = dgt(fleftabove,gg,a,M,L,'lt',kv.lt);

                fleftbelow = circshift(f,1).*exp(1i*2*pi*(0:L-1)'./L);
                cleftbelow = dgt(fleftbelow,gg,a,M,L,'lt',kv.lt);
            end

            switch typed
                case 't'
                    % This way, the implicit phase unwrapping is done in
                    % both differences.
                    ccross1 = cright.*conj(ccenterfi);
                    ccross2 = ccenterfi.*conj(cleft);
                    phased = (angle(ccross1)+angle(ccross2))/(2*2*pi)*L;

                    switch flags1.phaseconv
                        case {'freqinv','relative'}
                            % Do nothing
                        case 'timeinv'
                            phased = bsxfun(@plus,phased,fftindex(M)*b);
                        case 'symphase'
                            phased = bsxfun(@plus,phased,fftindex(M)*b/2);
                    end

                case 'f'
                    ccross1 = cabove.*conj(ccenterti);
                    ccross2 = ccenterti.*conj(cbelow);
                    phased = (angle(ccross1)+angle(ccross2))/(2*2*pi)*L;

                    switch flags1.phaseconv
                        case 'timeinv'
                            % Do nothing
                        case 'relative'
                            phased = -phased;
                        case 'freqinv'
                            phased = bsxfun(@plus,phased,-fftindex(N).'*a);
                        case 'symphase'
                            phased = bsxfun(@plus,phased,-fftindex(N).'*a/2);
                    end
                case 'tt'
                    ccross = cright.*conj(ccenterfi).^2.*cleft;
                    phased = angle(ccross)/(2*pi)*L;
                case 'ff'
                    ccross = cabove.*conj(ccenterti).^2.*cbelow;
                    phased = angle(ccross)/(2*pi)*L;

                    switch flags1.phaseconv
                        case 'relative'
                            phased = -phased;
                    end
                case {'ft','tf'}
                    ccross = crightabove.*conj(crightbelow).*conj(cleftabove).*cleftbelow;
                    phased = angle(ccross)/(4*2*pi)*L;

                    switch flags1.phaseconv
                        case 'timeinv'
                            % Do nothing
                        case {'freqinv','relative'}
                            phased = phased - 1;
                        case 'symphase'
                            phased = phased - 1/2;
                    end

                otherwise
                    error('%s: This should never happen.',upper(mfilename));
            end
            phased2{typedId} = phased;
        end

end;



% Undo flag sort
phased2(dflagsOrder) = phased2;

% Distribute duplicate flags
phased = cell(1,numel(dflagsDupl{1}));
for ii=1:numel(phased2)
    phased(dflagsDupl{ii}) = phased2(ii);
end

if ~typewascell
    assert(numel(phased)==1,'phased should contain only 1 element');
    phased = phased{1};
end


function fd=pderivunwrap(f,dim,unwrapconst)
%PDERIVUNWRAP Periodic derivative with unwrapping
%
%  `pderivunwrap(f,dim,wrapconst)` performs derivative of *f* along
%  dimmension *dim* using second order centered difference approximation
%  including unwrapping by *unwrapconst*
%
%  This effectivelly is just
%  (circshift(f,-1)-circshift(f,1))/2

if nargin<2 || isempty(dim)
    dim = 1;
end

if nargin<3 || isempty(unwrapconst)
    unwrapconst = 2*pi;
end

shiftParam = {[1,0],[-1,0]};
if dim == 2
    shiftParam = {[0,1],[0,-1]};
end

% Forward approximation
fd_1 = f-circshift(f,shiftParam{1});
fd_1 = fd_1 - unwrapconst*round(fd_1/(unwrapconst));
% Backward approximation
fd_2 = circshift(f,shiftParam{2})-f;
fd_2 = fd_2 - unwrapconst*round(fd_2/(unwrapconst));
% Average
fd = (fd_1+fd_2)/2;


function g = flipwin(g)
% This function time-reverses a Gabor window g
% assuming periodic indexing.

g = [g(1,:);flipud(g(2:end,:))];

function g = shiftwin(g,tshift,fshift,timeshiftfirst)
% This function circularly shifts g by tshift in time and
% by fshift in frequency.

if nargin<2
    error('Not enough args');
elseif nargin<3
    fshift = 0;
    timeshiftfirst = 1;
elseif nargin<4
    timeshiftfirst = 1;
end

gl = size(g,1);

tshiftop = @(g) g;
fshiftop = @(g) g;

if abs(fshift)>0
    l = fftindex(gl)/gl;
    fshiftop = @(g) g.*exp(1i*2*pi*fshift*l);
end

if abs(tshift) >0
    tshiftop = @(g) circshift(g,tshift);
end

if timeshiftfirst
    g = fshiftop(tshiftop(g));
else
    g = tshiftop(fshiftop(g));
end








