function [gd,nlen] = pebfundual(w,a,M,L,varargin)
%-*- texinfo -*-
%@deftypefn {Function} pebfundual
%@verbatim
%PEBFUNDUAL Dual window of sampled, periodized EB-spline
%   Usage: g=pebfundual(w,a,M,L)
%          g=pebfundual({w,width},a,M,L)
%          g=pebfundual(...,inc)
%
%   Input parameters: 
%         w      : vector of weights of g
%         width  : integer stretching factor of the window g*
%         a      : time shift, given by an integer number of sampling points
%         M      : number of channels
%         L      : length of a period
%         inc    : number of additional columns to compute window function
%
%   Output parameters:
%         gd     : Periodized dual window for the discrete EB-spline
%
%   PEBFUNDUAL(w,a,M,L) computes samples of a dual window of EB spline
%   with weights w. Please see PEBFUN for definition of EB splines.
%   The lattice parameters a,M must satisfy M > a to ensure the
%   system is a frame.
%
%   PEBFUNDUAL({w,width},a,M,L) works as above but in addition the width*
%   parameter determines the integer stretching factor of the original EB
%   spline. For explanation see help of PEBFUN.
%
%   PEBFUNDUAL(...,inc) or PEBFUNDUAL(...,'inc',inc) works as above, 
%   but integer inc denotes number of additional columns to compute window 
%   function gd. 'inc'-many are added at each side. It should be smaller than
%   100 to have comfortable execution-time. The higher the number the
%   closer gd is to the canonical dual window.
%   The default value is 10.
%
%   Examples:
%   ---------
%
%   The following example compares dual windows computed using 2 different
%   approaches.:
%      
%     w = [-3,-1,1,3];a = 25; M = 31; inc = 1;
%     L = 1e6; L = dgtlength(L,a,M);
%     width = M;
% 
%     % Create the window
%     g = pebfun(L,w,width);
% 
%     % Compute a dual window using pebfundual
%     tic
%     [gd,nlen] = pebfundual({w,width},a,M,L,inc);
%     tebfundual=toc;
% 
%     % We know that gd has only nlen nonzero samples, lets shrink it.
%     gd = middlepad(gd,nlen);
% 
%     % Compute the canonical window using gabdual
%     tic
%     gdLTFAT = gabdual(g,a,M,L);
%     tgabdual=toc;
% 
%     fprintf('PEBFUNDUAL elapsed time %f sn',tebfundual);
%     fprintf('GABDUAL elapsed time    %f sn',tgabdual);
% 
%     % Test on random signal
%     f = randn(L,1);
% 
%     fr = idgt(dgt(f,g,a,M),gd,a,numel(f));
%     fprintf('Reconstruction error PEBFUNDUAL: %en',norm(f-fr)/norm(f));
% 
%     fr = idgt(dgt(f,g,a,M),gdLTFAT,a,numel(f));  
%     fprintf('Reconstruction error GABDUAL:    %en',norm(f-fr)/norm(f));
%   
%
%   References:
%     K. Groechenig and J. Stoeckler. Gabor frames and totally positive
%     functions. Duke Math. J., 162(6):1003--1031, 2013.
%     
%     S. Bannert, K. Groechenig, and J. Stoeckler. Discretized Gabor frames of
%     totally positive functions. Information Theory, IEEE Transactions on,
%     60(1):159--169, 2014.
%     
%     T. Kloos and J. Stockler. Full length article: Zak transforms and gabor
%     frames of totally positive functions and exponential b-splines. J.
%     Approx. Theory, 184:209--237, Aug. 2014. [1]http ]
%     
%     T. Kloos. Gabor frames total-positiver funktionen endlicher ordnung.
%     Master's thesis, University of Dortmund, Dortmund, Germany, 2012.
%     
%     T. Kloos, J. Stockler, and K. Groechenig. Implementation of discretized
%     gabor frames and their duals. IEEE Transactions on Information Theory,
%     62(5):2759--2771, May 2016.
%     
%     References
%     
%     1. http://dx.doi.org/10.1016/j.jat.2014.05.010
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/pebfundual.html}
%@seealso{dgt, idgt, pebfun}
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

% AUTHORS: (c) Joachim Stoeckler, Tobias Kloos, 2012-2016


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

complainif_notenoughargs(nargin,4,upper(mfilename));
complainif_notposint(L,'L',upper(mfilename));
complainif_notposint(a,'a',upper(mfilename));
complainif_notposint(M,'M',upper(mfilename));

% Check lattice
if M<=a
    error('%s: Lattice parameters must satisfy M>a.',upper(mfilename));
end

% Check w
if iscell(w)
    if numel(w)~=2
        error('%s: w must be a 2 element cell array.',upper(mfilename));
    end
    width = w{2};
    w = w{1};
    complainif_notposint(width,'width',upper(mfilename));
else
    width = floor(sqrt(L));
end

if isempty(w) || ~isnumeric(w) || numel(w)<2
    error(['%s: w must be a nonempty numeric vector with at least',...
           ' 2 elements.'], upper(mfilename));
end

if any(w==0)
    error('%s: All weights w must be nonzero.', upper(mfilename));
    % TO DO: Also add a warning if w is very small or big?
end

% Define initial value for flags and key/value pairs.
%definput.import={'normalize'};
definput.keyvals.inc = 10;
%definput.flags.scale = {'nomatchscale','matchscale'};
[flags,~,inc]=ltfatarghelper({'inc'},definput,varargin);
complainif_notnonnegint(inc,'inc',upper(mfilename));

w = sort(w(:)); % sort and make it a column vector
m = length(w);
alpha = a/width;
beta = width/M;

% check alpha beta
if (alpha<=0) || (beta<=0)
    error('lattice parameters alpha, beta must be positive')
end
if (alpha*beta>=1)
    error('lattice parameters must satisfy alpha*beta<1')
end
if (alpha >= m)
    error('a/width must be smaller than length(w)')
end
check = 1;
if (1/beta == floor(1/beta))
    check = 0;
elseif (alpha == floor(alpha))
    check = 0;
elseif (1/alpha == floor(1/alpha)) && (beta < 1)
    check = 0;
end
if check == 1
    warning('output may not be a dual window; M/width should be a small integer')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preparations specially for computation of gamma
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
k1 = -(ceil(beta*(1/2*(m+alpha)+alpha*inc)/(1-alpha*beta))-1);
k2 = ceil(beta*(1/2*(m+alpha)+alpha*inc)/(1-alpha*beta))-1;
i1 = floor(m/2/alpha+(k1-1)/(alpha*beta)-1);
i2 = ceil((k2+1)/(alpha*beta)-(m-alpha)/2/alpha+1);

% minimal values for x and y
x = (i1-1)*alpha:alpha:(i2+1)*alpha;
i0 = abs(i1-1)+1; % index of "central" row of P(x)
y = k1/beta:1/beta:k2/beta;
k0 = abs(k1)+1; % index of "central" column of P(x)
[yy,xx] = meshgrid(y,x);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = 0:1/width:(a-1)/width;% for stepping through the interval [0,alpha)
j0 = ceil((m*width-a)/2);
t = t + j0/width;
tt = i1*alpha:1/width:i2*alpha; % choose same stepsize for t and tt
% left and right bounds large enough for the support of gamma
tt0 = abs(i1*a)+1; % index for tt == 0
gd = zeros(1,length(tt)); % dual window
c0 = zeros(1,length(t));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% computation of gamma
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%wait = waitbar(0,'Computing dual windows. Please wait...');

for k = 1:length(t)
    % step through the interval [0,alpha)
    x0 = t(k); % compute dual window at points (x+j*alpha)

    k1x = -(ceil((beta*(m-x0+alpha*inc))/(1-alpha*beta))-1) + k0;
    k2x = ceil((beta*(x0+alpha*inc))/(1-alpha*beta))-1 + k0;

    i1x = ceil((m*beta+(k1x-k0)-1-x0*beta)/(alpha*beta)) + i0;
    i2x = floor(((k2x-k0)+1-x0*beta)/(alpha*beta)) + i0;

    % Computation of P0(x0)
    % z0 is the matrix of the abscissa x0+j*alpha-k/beta, j=i1:i2, k=k1:k2,
    % z1 puts all these abscissae into a row vector.
    % The computation of g(z1) is done as described above for the
    % vector tt.
    z0 = x0+xx(:,k1x:k2x)-yy(:,k1x:k2x);
    z1 = z0(:)';

    lz1 = length(z1);
    z1 = repmat(z1.',1,m) + repmat([-m+1:0],lz1,1);
    z1 = z1(:)';
    Y = zeros(m-1,length(z1));

    index = find( (z1>=0) & (z1<=2));
    zinit = z1(index);  % only these are needed for initialization of Y

    for q = 1:m-1
        if w(q) == w(q+1)
            Y(q,index) = zinit.*exp(w(q)*zinit).*(zinit<=1) + ...
                (2-zinit).*exp(w(q)*zinit).*(zinit>1);
        else
            Y(q,index) = (exp(w(q)*zinit)-exp(w(q+1)*zinit))/(w(q)-w(q+1)).*(zinit<=1) + ...
                (exp(w(q)-w(q+1))*exp(w(q+1)*zinit)-exp(w(q+1)-w(q))*exp(w(q)*zinit))/(w(q)-w(q+1)).*(zinit>1);
        end
    end
    
    for q = 2:m-1
        for j = 1:m-q
            if w(j) == w(j+q)
                Y(j,(q-1)*lz1+1:end) = z1((q-1)*lz1+1:end)/q .* Y(j,(q-1)*lz1+1:end) + ...
                    exp(w(j))*(q+1-z1((q-1)*lz1+1:end))/q .* Y(j,(q-2)*lz1+1:end-lz1);
            else
                Y(j,(q-1)*lz1+1:end) = ( Y(j,(q-1)*lz1+1:end) - Y(j+1,(q-1)*lz1+1:end) + ...
                    exp(w(j))*Y(j+1,(q-2)*lz1+1:end-lz1) - exp(w(j+q))*Y(j,(q-2)*lz1+1:end-lz1) )/ ...
                    (w(j)-w(j+q));
            end
        end
    end

    if m == 1
        index = find( (z1>=0) & (z1<=1));
        zinit = z1(index);  % only these are needed for m=1
        A0(index) = exp(w*zinit);
    else
        A0 = Y(1,end-lz1+1:end);
    end

    A0 = reshape(A0,size(z0));
    P0 = A0(i1x:i2x,:);

    % computation of pseudo-inverse matrix of P0
    P0inv = pinv(P0);

    gd(k-1+tt0+j0+a*(i1x-i0):a:k-1+tt0+j0+a*(i2x-i0)) = beta*P0inv(k0-k1x+1,:); % row index k0-k1a+1
    % points to the "j=0" row of P0inv
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% periodization of gamma
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nlen = numel(gd);
nr = ceil(length(gd)/L);
v = zeros(1,nr*L);
v(1:length(gd)) = gd;
v = [v(tt0:end),v(1:tt0-1)];

% Determine nlen
if nlen<L
    negsupp = tt0-1;
    possupp = nlen-tt0; % excluding zero pos.
    nlen = 2*max([negsupp,possupp])+1;
end
nlen = min([L,nlen]);

gd = sum(reshape(v,L,nr)',1);
gd = gd/sqrt(width);

% if flags.do_matchscale
%    g = pebfun(L,w,width,flags.norm);
%    [scal,err] = gabdualnorm(g,gd,a,M,L)
%     assert(err<1e-10,sprintf(['%s: Assertion failed. This is not a valid ',...
%                               ' dual window.'],upper(mfilename)));
%    gd = gd/scal;
% else
%    gd = normalize(gd,flags.norm);
% end

gd = gd(:);
%gd = circshift(gd,-floor(nlen/2));

