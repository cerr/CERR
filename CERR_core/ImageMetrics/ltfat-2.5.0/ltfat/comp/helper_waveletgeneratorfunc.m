function [fun, fsupp, peakpos, cauchyAlpha] = helper_waveletgeneratorfunc(name, varargin)
%HELPER_WAVELETGENERATORFUNC returns a mother wavelet
%   Usage: [fun, fsupp, peakpos, cauchyAlpha] = helper_waveletgeneratorfunc(name)
%    [fun, fsupp, peakpos, cauchyAlpha] = helper_waveletgeneratorfunc(name, 'negative')
%
%   Input parameters:
%         name  : Name of the wavelet
%
%   Output parameters:
%         fun     : Frequency domain wavelet function handle
%         fsupp  : Vector containing the (relative) support of the wavelet
%         peakpos : Peak position of the wavelet
%         cauchyAlpha : the equivalent cauchy alpha of the wavelet
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
%   See also: freqwavelet, waveletfilters
%
%   Url: http://ltfat.github.io/doc/comp/helper_waveletgeneratorfunc.html

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

%% output wavelet function fun + f-support

if ~iscell(name), name = {name}; end

freqwavelettypes = getfield(arg_freqwavelet(),'flags','wavelettype');

if ~ischar(name{1}) || ~any(strcmpi(name{1},freqwavelettypes))
  error('%s: First input argument must the name of a supported wavelet.',...
        upper(mfilename));
end


winArgs = name(2:end);
definput.keyvals.bwthr = 10^(-3/10);
definput.keyvals.efsuppthr = 10^(-5);


if ~isempty(varargin)
    if strcmp(varargin{1}, 'negative')
        flags.do_negative = 1;
    else
        flags.do_negative = 0;
    end
else
    flags.do_negative = 0;
end


switch name{1}
    case {'cauchy', 'morse'}

       if size(winArgs,2) > 1
        definput.keyvals.alpha = winArgs(1);
       else
         definput.keyvals.alpha = 300;
       end
       if size(winArgs,2) > 2
        definput.keyvals.beta = winArgs(2);
       else
         definput.keyvals.beta = 0;
       end
       if size(winArgs,2) > 3
        definput.keyvals.gamma = winArgs(3);
       else
         definput.keyvals.gamma = 3;
       end


        [~,kv,alpha,beta,gamma]=ltfatarghelper({'alpha','beta','gamma'},definput, winArgs);

        if alpha <= 1
            error('%s: Alpha must be larger than 1 (passed alpha=%.2f).',...
            upper(mfilename),alpha);
        end

        if gamma <= 0
            error('%s: Gamma must be larger than 0 (passed gamma=%.2f).',...
            upper(mfilename),gamma);
        end

        if kv.efsuppthr < 0, error('%s: efsuppthr must be nonnegative',upper(mfilename)); end
        if kv.bwthr < 0, error('%s: bwthr must be nonnegative',upper(mfilename)); end
        if kv.bwthr < kv.efsuppthr, error('%s: efsuppthr must be lower than bwthr.',upper(mfilename)); end

        order = (alpha-1)/(2*gamma);
        peakpos = ( order/(2*pi*gamma) )^(1/(gamma));

        freqatheightasc = @(thr) real( (-order/(2*pi*gamma) * octave_lambertw( 0, ...
        -thr^(gamma/order)/exp(1)))^(1/(gamma)) );%/basedil/scale;

        freqatheightdesc= @(thr) real( (-order/(2*pi*gamma)*octave_lambertw(-1, ...
        -thr^(gamma/order)/exp(1)))^(1/gamma) );%/basedil/scale;

    
        if ~flags.do_negative                
            fun = @(y) (y > 0).*exp(-2*pi*y.^gamma + (order - 1i*beta)*log(y) ...
                    + ( order/gamma - order/gamma*log(order/(2*pi*gamma)) ));
        else
            fun = @(y) (y < 0).*exp(-2*pi*abs(y).^gamma + (order - 1i*beta)*log(abs(y)) ...
                    + ( order/gamma - order/gamma*log(order/(2*pi*gamma)) ));
        end

        
        if strcmpi(name{1}, 'morse')
            cauchyAlpha = wpghi_findalpha({'morse',order},0.2);
        else
            cauchyAlpha = alpha;
        end
        
    case 'morlet'
        
        if size(winArgs,2) > 1
            definput.keyvals.sigma = winArgs(1);
        else
            definput.keyvals.sigma = 4;
        end

        [~,kv,sigma]=ltfatarghelper({'sigma'},definput,winArgs);
        
        if sigma <= 1
            error('%s: Sigma must be larger than 1 (passed sigma=%.2f).',...
                upper(mfilename),sigma);
        end
        
        %fixed point iteration to find the maximum of the Morlet wavelet
        peakpos = sigma;
        peakpos_tmp = 0;
        while abs(peakpos-peakpos_tmp) > 1e-6
            peakpos_tmp = peakpos;
            peakpos = sigma./(1-exp(-sigma*peakpos));
        end

        fun = @(y) ( exp(-0.5*(sigma-abs(y)).^2) - exp(-0.5*( sigma.^2+abs(y).^2 )) )...
                ./ ( exp(-0.5*(sigma-peakpos).^2) - exp(-0.5*( sigma.^2+peakpos.^2 )) );
            
        freqatheightdesc = @(thr) determine_freqatheight(fun,peakpos,thr,1);
        freqatheightasc= @(thr) determine_freqatheight(fun,peakpos,thr,0);
        
        cauchyAlpha = wpghi_findalpha({'morlet',sigma},0.2);
        
    case 'fbsp'
        if size(winArgs,2) > 1
            definput.keyvals.order = winArgs(1);
        else
            definput.keyvals.order = 4;
        end
       if size(winArgs,2) > 2
            definput.keyvals.fb = winArgs(2);
        else
            definput.keyvals.fb = 2;
       end
        [~,kv,order,fb]=ltfatarghelper({'order','fb'},definput,winArgs);
        
        if order < 1 || order > 5 || round(order) ~= order
            error('%s: order must be integer and between 1 and 5 (passed order=%.2f).',...
                upper(mfilename),order);
        end
        
        if fb < 2
                error('%s: fb must be at least 2 (passed fb=%.2f).',...
                      upper(mfilename),fb);
        end
        
        peakpos = 1;
        
        switch order
            case 1
                prefun = @(x) ( x >= 0 ).*( x < 1 ) .* 1;

            case 2
                prefun = @(x) ( x >= 0 ).*( x < 1 ) .* ...
                    (x) ...
                    + ( x >= 1 ).*( x < 2 ) .* ...
                    (2-x);

            case 3
                prefun = @(x)  ( x >= 0 ).*( x < 1 ) .* ...
                    (.5*x.^2) ...
                    + ( x >= 1 ).*( x < 2 ) .* ...
                    (-x.^2 + 3.*x -1.5) ...
                    + ( x >= 2 ).*( x < 3 ) .* ...
                    (.5*x.^2 - 3.*x + 4.5);
            case 4
                prefun = @(x)  ( x >= 0 ).*( x < 1 ) .* ...
                    (x.^3./6) ...
                    + ( x >= 1 ).*( x < 2 ) .* ...
                    (-x.^3./2 + 2.*x.^2 - 2.*x + 2/3) ...
                    + ( x >= 2 ).*( x < 3 ) .* ...
                    (x.^3./2 - 4.*x.^2 + 10.*x - 22/3) ...
                    + ( x >= 3 ).*( x < 4 ) .* ...
                    (-x.^3./6 + 2.*x.^2 - 8.*x + 32/3);
            case 5
                prefun = @(x) ( x >= 0 ).*( x < 1 ) .* ...
                    (x.^4./24) ...
                    + ( x >= 1 ).*( x < 2 ) .* ...
                    (-x.^4./6 + 5.*x.^3./6 - 5.*x.^2./4 + 5.*x./6 - 5/24) ...
                    + ( x >= 2 ).*( x < 3 ) .* ...
                    (x.^4./4 - 5.*x.^3./2 + 35.*x.^2./4 - 25.*x./2 + 155/24) ...
                    + ( x >= 3 ).*( x < 4 ) .* ...
                    (-x.^4./6 + 5.*x.^3./2 - 55.*x.^2./4 + 65.*x./2 - 655/24) ...
                    + ( x >= 4 ).*( x < 5 ) .* ...
                    (x.^4./24 -5.*x.^3./6 + 25.*x.^2./4 - 125.*x./6 + 625/24);

        end
        
        fun = @(y) prefun((abs(y)-1).*fb.*order./2+order./2)./prefun(order./2);
        
        freqatheightdesc = @(thr) determine_freqatheight(fun,peakpos,thr,1);%/basedil/scale(m);
        freqatheightasc= @(thr) determine_freqatheight(fun,peakpos,thr,0);%/basedil/scale(m);
        cauchyAlpha = wpghi_findalpha({'fbsp',order,fb},0.2);
        
    case 'analyticsp'
        
        if size(winArgs,2) > 1
            definput.keyvals.order = winArgs(1);
        else
            definput.keyvals.order = 4;
        end
       if size(winArgs,2) > 2
            definput.keyvals.fb = winArgs(2);
        else
            definput.keyvals.fb = 2;
       end

        [~,kv,order,fb]=ltfatarghelper({'order','fb'},definput,winArgs);
        
        if order < 1 || order > 5 || round(order) ~= order
            error('%s: order must be integer and between 1 and 5 (passed order=%.2f).',...
                upper(mfilename),order);
        end
        
        if fb < 1 || round(fb) ~= fb
            error('%s: fb must be an integer and at least 1 (passed fb=%.2f).',...
                upper(mfilename),fb);
        end
        
        peakpos = 1;

       if ~flags.do_negative
            fun = @(y) (y>0).* (sinc( fb.*(y - 1) ).^order + sinc( fb.*( y + 1) ).^order);
       else
            fun = @(y) (y<0).* (sinc( fb.*(abs(y) - 1) ).^order + sinc( fb.*( abs(y) + 1) ).^order);
       end

        
        heightfun = @(y) min(1,(y>0).* ( 1./abs(fb.*(pi.*y - pi)+eps).^order + 1./abs(fb.*( pi.*y + pi )).^order ));
        freqatheightdesc = @(thr) determine_freqatheight(heightfun,peakpos,thr,1);%/basedil/scale(m);
        freqatheightasc= @(thr) determine_freqatheight(heightfun,peakpos,thr,0);%/basedil/scale(m);
                    
        cauchyAlpha = wpghi_findalpha({'analyticsp',order,fb},0.2);
    
    case 'cplxsp' 
   
        if size(winArgs,2) > 1
            definput.keyvals.order = winArgs(1);
        else
            definput.keyvals.order = 4;
        end
       if size(winArgs,2) > 2
            definput.keyvals.fb = winArgs(2);
        else
            definput.keyvals.fb = 2;
       end

        [~,kv,order,fb]=ltfatarghelper({'order','fb'},definput,winArgs);
        
        if order < 1 || order > 5 || round(order) ~= order
            error('%s: order must be integer and between 1 and 5 (passed order=%.2f).',...
                upper(mfilename),order);
        end
        
        if fb < 1 || round(fb) ~= fb
            error('%s: fb must be an integer and at least 1 (passed fb=%.2f).',...
                upper(mfilename),fb);
        end
        
        peakpos = 1;
        
        if ~flags.do_negative
            fun = @(y) sinc( fb.*(y - 1) ).^order;
        else
            fun = @(y) sinc( fb.*(abs(y) - 1) ).^order;
        end
       
        heightfun = @(y) min(1,1./abs(fb.*(pi*y - pi)+eps).^order);
        freqatheightdesc = @(thr) determine_freqatheight(heightfun,peakpos,thr,1);%/(basedil+eps)/scale(m);
        freqatheightasc= @(thr) determine_freqatheight(heightfun,peakpos,thr,0);%/(basedil+eps)/scale(m);
        
        cauchyAlpha = wpghi_findalpha({'cplxsp',order,fb},0.2);
    otherwise
        fun = [];
        disp('wavelet not yet implemented.')
end


% determine the frequency support
fsupp = [-inf -inf peakpos inf inf];
if kv.efsuppthr > 0
    fsupp(1) = freqatheightasc(kv.efsuppthr);
    fsupp(5) = freqatheightdesc(kv.efsuppthr);
end
fsupp(2) = freqatheightasc(kv.bwthr);
fsupp(4) = freqatheightdesc(kv.bwthr);
        
end


function w = octave_lambertw(b,z)
% Copyright (C) 1998 by Nicol N. Schraudolph <schraudo@inf.ethz.ch>
%
% @deftypefn {Function File} {@var{x} = } lambertw (@var{z})
% @deftypefnx {Function File} {@var{x} = } lambertw (@var{n}, @var{z})
% Compute the Lambert W function of @var{z}.
%
% This function satisfies W(z).*exp(W(z)) = z, and can thus be used to express%
% solutions of transcendental equations involving exponentials or logarithms.%%
% @var{n} must be integer, and specifies the branch of W to be computed;
% W(z) is a shorthand for W(0,z), the principal branch.  Branches
% 0 and -1 are the only ones that can take on non-complex values.
%
% If either @var{n} or @var{z} are non-scalar, the function is mapped to each
% element; both may be non-scalar provided their dimensions agree.
%
% This implementation should return values within 2.5*eps of its
% counterpart in Maple V, release 3 or later.  Please report any
% discrepancies to the author, Nici Schraudolph <schraudo@@inf.ethz.ch>.

if (nargin == 1)
    z = b;
    b = 0;
else
    % some error checking
    if (nargin ~= 2)
        print_usage;
    else
        if (any(round(real(b)) ~= b))
            usage('branch number for lambertw must be integer')
        end
    end
end

%% series expansion about -1/e
%
% p = (1 - 2*abs(b)).*sqrt(2*e*z + 2);
% w = (11/72)*p;
% w = (w - 1/3).*p;
% w = (w + 1).*p - 1
%
% first-order version suffices:
%
w = (1 - 2*abs(b)).*sqrt(2*exp(1)*z + 2) - 1;

%% asymptotic expansion at 0 and Inf
%
v = log(z + double(~(z | b))) + 2*pi*1i*b;
v = v - log(v + double(v==0));

%% choose strategy for initial guess
%
c = abs(z + 1/exp(1));
c = (c > 1.45 - 1.1*abs(b));
c = c | (b.*imag(z) > 0) | (~imag(z) & (b == 1));
w = (1 - c).*w + c.*v;

%% Halley iteration
%%
for n = 1:10
    p = exp(w);
    t = w.*p - z;
    f = (w ~= -1);
    t = f.*t./(p.*(w + f) - 0.5*(w + 2.0).*t./(w + f));
    w = w - t;
    if (abs(real(t)) < (2.48*eps)*(1.0 + abs(real(w))) ...
        && abs(imag(t)) < (2.48*eps)*(1.0 + abs(imag(w))))
        return
    end
end

end 
%%error('PRECISION:iteration limit reached, result of lambertw may be inaccurate');
