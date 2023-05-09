function [gd,nlen]=ptpfundual(w,a,M,L,varargin)
%-*- texinfo -*-
%@deftypefn {Function} ptpfundual
%@verbatim
%PTPFUNDUAL Sampled, periodized dual TP function of finite type
%   Usage: gd=ptpfundual(w,a,M,L)
%          gd=ptpfundual({w,width},a,M,L)
%          gd=ptpfundual(...,inc)
%          [gd,nlen]=ptpfundual(...)
%
%   Input parameters:
%         w      : Vector of reciprocals w_j=1/delta_j in Fourier representation of g*
%         width  : Integer stretching factor for the essential support
%         a      : Length of time shift.
%         M      : Number of channels.
%         L      : Window length.
%         inc    : Extension parameter
%
%   Output parameters:
%         gd    : The periodized totally positive function dual window.
%         nlen  : Number of non-zero elements in gd.
%
%   PTPFUNDUAL(w,a,M,L) computes samples of a dual window of totally
%   positive function of finite type >=2 with weights w. Please see
%   PTPFUN for definition of totally positive functions.
%   The lattice parameters a,M must satisfy M > a to ensure the
%   system is a frame.
%
%   PTPFUNDUAL({w,width},a,M,L) works as above but in addition the width*
%   parameter determines the integer stretching factor of the original TP
%   function. For explanation see help of PTPFUN.
%
%   PTPFUNDUAL(...,inc) or PTPFUNDUAL(...,'inc',inc) works as above, 
%   but integer inc denotes number of additional columns to compute window
%   function gd. 'inc'-many are added at each side. It should be smaller 
%   than 100 to have comfortable execution-time. The higher the number the 
%   closer gd is to the canonical dual window.
%   The default value is 10.
%
%   [gd,nlen]=PTPFUNDUAL(...) as gd might have a compact support,
%   nlen contains a number of non-zero elements in gd. This is the case
%   when gd is symmetric. If gd is not symmetric, nlen is extended
%   to twice the length of the longer tail.
%
%   If nlen = L, gd has a 'full' support meaning it is a periodization
%   of a dual TP function.
%
%   If nlen < L, additional zeros can be removed by calling
%   gd=middlepad(gd,nlen).
%
%   Examples:
%   ---------
%
%   The following example compares dual windows computed using 2 different
%   approaches.:
% 
%     w = [-3,-1,1,3];a = 25; M = 31; inc = 10;
%     L = 1e6; L = dgtlength(L,a,M);
%     width = M;
% 
%     % Create the window
%     g = ptpfun(L,w,width);
% 
%     % Compute a dual window using pebfundual
%     tic
%     [gd,nlen] = ptpfundual({w,width},a,M,L,inc);
%     ttpfundual=toc;
% 
%     % We know that gd has only nlen nonzero samples, lets shrink it.
%     gd = middlepad(gd,nlen);
% 
%     % Compute the canonical window using gabdual
%     tic
%     gdLTFAT = gabdual(g,a,M,L);
%     tgabdual=toc;
% 
%     fprintf('PTPFUNDUAL elapsed time %f sn',ttpfundual);
%     fprintf('GABDUAL elapsed time    %f sn',tgabdual);
% 
%     % Test on random signal
%     f = randn(L,1);
% 
%     fr = idgt(dgt(f,g,a,M),gd,a,numel(f));
%     fprintf('Reconstruction error PTPFUNDUAL: %en',norm(f-fr)/norm(f));
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
%     References
%     
%     1. http://dx.doi.org/10.1016/j.jat.2014.05.010
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/ptpfundual.html}
%@seealso{dgt, idgt, ptpfun}
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

% AUTHORS: Joachim Stoeckler, Tobias Kloos, 2012-2014

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

% TP functions are scale invariant so we do scaling directly on w.
wloc = w/width;
% Converting a, M to alpha, beta
alpha = a;
beta = 1/M;

% check alpha beta
if (alpha<=0) || (beta<=0)
    error('lattice parameters alpha, beta must be positive')
end
if (width*beta > 10)
    warning('width/M should be smaller than 10: numerical instability may occur')
end

% compute m n and check that a has nonzero entries
if all(wloc<0)
    wloc = -wloc;
    case0 = 2;
else
    case0 = 0;
end
m = length(find(wloc>0));
n = length(find(wloc<0));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preparations specially for computation of gd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r = floor(1/(1-alpha*beta)+eps);

% check special cases according to n and m
if n == 0
    if m >= 2
        k2 = (m-1)*(r+1)-1;
        k1 = -k2;
        if case0 == 0
            case0 = 1;
        end
    end
elseif n == 1
    N = m*(r+1)+1;       % minimal column size
    k1 = -m*(r+1)+1;     % column index k1 from the paper
    k2 = k1+N-1;         % column index k2 from the paper
else
    N = (m+n-1)*(r+1);   % minimal column size
    k1 = -m*(r+1)+1;     % column index k1 from the paper
    k2 = k1+N-1;         % column index k2 from the paper
end

k1 = k1-inc;
k2 = k2+inc;

% minimal values for x and y
varl = floor((k1+m-1)/(alpha*beta))-1;
varr = ceil((k2-n+1)/(alpha*beta))+1;
x = varl*alpha:alpha:varr*alpha;
i0 = abs(varl)+1; % index of "central" row of P(x)
y = (k1-1)/beta:(1/beta):(k2+1)/beta;
k0 = abs(k1-1)+1; % index of "central" column of P(x)

[yy,xx] = meshgrid(y,x);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = 0:(a-1); % for stepping through the interval [0,alpha)
tt = varl*alpha:varr*alpha; % choose same stepsize for t and tt
% left and right bounds large enough for the support of gamma
tt0 = abs(varl*a)+1; % index for tt == 0
gd = zeros(1,length(tt)); % dual window


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% computation of gamma
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

k1 = k1+k0;
k2 = k2+k0;

for k=1:length(t)
    % step through the interval [0,alpha)
    x0 = t(k); % compute dual window at points (x+j*alpha)

    % row indices for rectangular P0
    i1 = floor((k1-k0+m-1)/alpha/beta-x0/alpha)+1+i0;
    i2 = ceil((k2-k0-n+1)/alpha/beta-x0/alpha)-1+i0;

    % Computation of P0(x0)
    % z0 is the matrix of the abscissa x0+j*alpha-k/beta, j=i1:i2, k=k1:k2,
    % z1 puts all these abscissae into a row vector.
    % The computation of g(z1) is done as described above for the
    % vector tt.
    z0 = x0+xx(:,k1:k2)-yy(:,k1:k2);
    z1 = z0(:)';

    Y = zeros((n+m)-1,length(z1));
    for q = 1:(n+m)-1
        if wloc(q) == wloc(q+1)
            Y(q,:) = abs(wloc(q))^2*abs((z1.*((wloc(q)*z1)>=0))).*exp(-wloc(q)*(z1.*((wloc(q)*z1)>=0))).*((wloc(q)*z1)>=0);
        else
            if wloc(q)*wloc(q+1) < 0
                Y(q,:) = abs(wloc(q)*wloc(q+1))/(abs(wloc(q))+abs(wloc(q+1)))*(exp(-wloc(q)*(z1.*((wloc(q)*z1)>=0))).*((wloc(q)*z1)>=0) + ...
                exp(-wloc(q+1)*(z1.*((wloc(q+1)*z1)>=0))).*((wloc(q+1)*z1)>0));
            else
                Y(q,:) = wloc(q)*wloc(q+1)/(abs(wloc(q+1))-abs(wloc(q)))*(exp(-wloc(q)*(z1.*((wloc(q)*z1)>=0)))-exp(-wloc(q+1)*(z1.*((wloc(q)*z1)>=0)))).*((wloc(q)*z1)>=0);
            end
        end
    end

    for q = 2:(n+m)-1
        for j = 1:(n+m)-q
            if wloc(j) == wloc(j+q)
                Y(j,:) = Y(j,:).*abs(z1)/q*abs(wloc(j));
            else
                Y(j,:) = (wloc(j)*Y(j+1,:)-wloc(j+q)*Y(j,:))/(wloc(j)-wloc(j+q));
            end
        end
    end

    if (n+m) == 1
        A0 = abs(wloc)*exp(-wloc*(z1.*((wloc*z1)>=0))).*((wloc*z1)>=0);
    else
        A0 = Y(1,:);
    end

    A0 = reshape(A0,size(z0))*sqrt(width);%*L^(1/4);
    P0 = A0(i1:i2,:);

    % computation of pseudo-inverse matrix of P0
    P0inv = pinv(P0);
    gd(k-1+tt0-a*(i0-i1):a:k-1+tt0+a*(i2-i0)) = beta*P0inv(k0-k1+1,:); % row index k0-k1a+1
    % points to the "j=0" row of P0inv
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% periodization of gamma
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nlen = length(gd);
nr = ceil(nlen/L);
v = zeros(1,nr*L);
v(1:length(gd)) = gd;
v = [v(tt0:end),v(1:tt0-1)];

gd = sum(reshape(v,L,nr),2);
gd = gd(:);
if case0 == 2
    gd =  flipud(gd);
    gd = [gd(end);gd(1:end-1)];
end

% Determine nlen
if nlen<L
    negsupp = tt0-1;
    possupp = nlen-tt0; % excluding zero pos.
    nlen = 2*max([negsupp,possupp])+1;
end
nlen = min([L,nlen]);

% if flags.do_matchscale
%    g = ptpfun(L,w,width,flags.norm);
%    [scal,err] = gabdualnorm(g,gd,a,M,L);
%     assert(err<1e-10,sprintf(['%s: Assertion failed. This is not a valid ',...
%                               ' dual window.'],upper(mfilename)));
%    gd = gd/scal;
% else
%    gd = normalize(gd,flags.norm);
% end

gd = gd(:);

end

