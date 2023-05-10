function [ fplanes,cplanes,info ] = tfjigsawsep( f, varargin )
%TFJIGSAWSEP Time frequency jigsaw puzzle tonal-transient separation
%   Usage:  fplanes = tfjigsawsep(f);
%           fplanes = tfjigsawsep(f,r1,r2);
%           fplanes = tfjigsawsep(f,r1,r2,p);
%           [fplanes, cplanes, info] = tfjigsawsep(...);
%
%   Input parameters:
%            f        : Input signal
%            r1       : Significance level of the tonal layer refered to
%                       a white noise reference
%            r2       : Same for the transient layer
%            p        : Proportionfactor of the supertilesizes relative 
%                       to the time-, and frequency stepsize 
%    
%   Output parameters:
%           fplanes   : signallength-by-3 array containing the 3 produced
%                       layers, tonal in fplanes(:,1), transient in
%                       fplanes(:,2) and the noisy residual in fplanes(:,3).
%           cplanes   : 3-by-1 cellarray containing the Gabor coefficients
%                       for the individual layers
%
%   TFJIGSAWSEP(f) applies the separation algorithm on the input signal f*
%   and returns the tonal, the transient and the residual parts.
%   The following default values are used, r1=r2=0.95, p=4 and for the 
%   3 Gabor systems:
%   
%       "Tonal" system:     g1 = {'hann',4096}; a1 = 512; M1 = 4096;
%   
%       "Transient" system: g2 = {'hann',256};  a2 = 32;  M2 = 256;
%
%       "Residual" system:  g3 = {'hann',2048}; a3 = 512; M3 = 2048;
%   
%   TFJIGSAWSEP(f,r1,r2) works as before, but allows changing threshold
%   parameters r1 and r2. Good values are in range [0.85,0.95]. 
%   t2 sometimes has to be chosen larger (~ 1.05), eg. for 
%   percussions in music signals.
%
%   TFJIGSAWSEP(f,r1,r2,p) (recommended) additionally allows changing the
%   size of the supertiles to a1*p in timesamples and b2*p in
%   frequencysamples. The choice of this particular proportion is
%   reasonable since it provides equal numbers of coefficients of the two
%   Gabor systems in each supertile. Good values are in the range of [1,10],
%   but it depends very much on the type of signal.
%   E.g. for speech signals, higher values yield better results.   
%
%   [fplanes, cplanes, info] = TFJIGSAWSEP(...) additionally returns
%   a 3 element cell array cplanes containing DGTREAL coefficients
%   of the respective separated layers and a structure info, with the
%   parameters used in the algorithm. The relationship between fplanes*
%   and cplanes is the following:
%
%   Url: http://ltfat.github.io/doc/sigproc/tfjigsawsep.html

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

%   Additional parameters:
%   ----------------------
%
%   The function accepts the following flags:
%
%       'ver2' Uses the second version of the algorithm.
%
%       'plot' Plots the separated waveforms and the coefficients.
%
%       'verbose' Information about the boundary condition.
%
%
%   and the following key-value pairs:
%      
%       'wintype' Requested windowtype
%
%       'winsize1' and 'winsize2' Windowlengths
%
%       'a1' and 'a2' Time stepsizes
%
%       'M1' and 'M2' Number of frequency channels
%
%       'T' and 'F' Supertile sizes in samples manually - alternative to p!
%
%       'maxit' Maximum number of iterations. The default value is 15.
%
%   Algorithm:
%   ----------
%
%   The algorithm is based on [1]. It transforms a signal into a two-windowed
%   Gabor expansion such that one wide window shall lead to a high frequency
%   resolution (tonal layer is represented well) and a narrow one to a high
%   time resolution (transient layer is repr. well). The resulting Gabor
%   coefficients are respectively considered within rectangular 'supertiles'
%   in the time-frequency plane. An entropy criterion chooses those tiles
%   respectively, where tonal and transient parts of the signal are
%   represented better and are below a estimated threshold. The rest is set
%   to zero. The leftover Gabor coefficients are transformed back and
%   subtracted from the original signal. By applying this procedure
%   iteratively on the residual, tonal and transient layers emerge.
%
%   Examples:
%   ---------
%   
%   The following example shows the basic usage of the function:::
%     
%     % Load the glockenspiel test signal and add some noise
%     [f,fs] = gspi; f = f + 0.001*randn(size(f));
%     % Setup the parameters
%     p = 2; r1 = 0.92; r2 = 0.93;
%     [fplanes,cplanes,info] = tfjigsawsep(f,r1,r2,p,'plot','ver2','fs',fs);
%     
%   See also: dgtreal plottfjigsawsep
%         
%   References: jato07

%AUTHOR: Daniel Haider, 2017 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Remarks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   The residual condition is computed very heuristically, designing it   %
%   more flexible would be a nice improvement of the algorithm.           %
%   It would also be useful to provide parameter settings for specific    %
%   types of signals (ie. speech, music,...) .                            %
%                                                                         %
%   Version 1 of the algorithm (default) works particularly well for      %
%   speech signals, but also for depicting the transient layer            %
%   (eg. percussive elements) nicely in musical signals.                  %
%   Version 2 works particularly well for depicting a nice tonal layer.   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[f,Ls,W,wasrow,remembershape]=comp_sigreshape_pre(f,upper(mfilename),0);

if W>1
    error('%s: Multichannel inputs are not supported.',upper(mfilename));
end

definput.keyvals.r1 = [];
definput.keyvals.r2 = [];
definput.keyvals.p = [];
definput.keyvals.T = [];
definput.keyvals.F = [];
definput.keyvals.wintype = 'hann';
definput.keyvals.winsize1 = 4096;
definput.keyvals.a1 = 512;
definput.keyvals.M1 = 4096;
definput.keyvals.winsize2 = 512;
definput.keyvals.a2 = 64;
definput.keyvals.M2 = 512;
definput.keyvals.maxit = 15;
definput.keyvals.fs = [];
definput.flags.algver = {'ver1','ver2'};
definput.flags.plot = {'noplot','plot'};
definput.flags.verbose = {'noverbose','verbose'};
[flags,kv] = ltfatarghelper({'r1','r2','p','T','F','wintype','winsize1','a1','M1','winsize2','a2','M2'},definput,varargin);

% significance level
r1 = kv.r1;
r2 = kv.r2;
% Gabor system settings
wintype = kv.wintype;
winsize1 = kv.winsize1;
a1 = kv.a1;
M1 = kv.M1;
winsize2 = kv.winsize2;
a2 = kv.a2;
M2 = kv.M2;
% supertile sizes
if isempty(kv.T) && isempty(kv.F)
    if isempty(kv.p)
        p = 4;
    else
        p = kv.p;
    end
    T = a1*p;
    F = dgtlength(Ls,a2,M2)/M2*p;
elseif isempty(kv.p)
    T = kv.T;
    F = kv.F;
else
    error('%s: Use EITHER the proportional setting OR set T and F manually.',upper(mfilename));
end

if winsize1 < winsize2
    error('%s: The tonal system uses a shorter window than the transient system!',upper(mfilename));
end

% why this and not setting the kv on top?
if xor(isempty(r1),isempty(r2))
    error('%s: Both r1 and r2 must be defined.',upper(mfilename));
else
    if isempty(r1), r1 = 0.95; end
    if isempty(r2), r2 = 0.95; end
end  

% windows
g1 = {wintype,winsize1};
g2 = {wintype,winsize2};

L1 = dgtlength(Ls,a1,M1);
L2 = dgtlength(Ls,a2,M2);
b1 = L1/M1;
b2 = L2/M2;

complainif_notposint(T,'T',mfilename);
if ~( T < min([L1,L2]) )
    error('%s: Supertile length must be smaller than the signal length [%i]',...
          upper(mfilename),min([L1,L2]));
elseif ~( F < min([L1/2+1,L2/2+1]) )
    error('%s: Supertile height must be smaller than the frequency range [%i]',...
      upper(mfilename),min([L1/2+1,L2/2+1]));
elseif ~( T > max([a1,a1]) )
    error('%s: Supertile length must be larger than the time stepsizes [%i]',...
          upper(mfilename),max([a1,a1]));
elseif ~( F > max([b1,b2]) )
    error('%s: Supertile height must be larger than the frequency stepsizes [%i]',...
          upper(mfilename),max([b1,b2]));
end

% entropy reference from noise signal
% thresholds tau1,tau2 for tonal resp. transient layer are chosen to have
% a certain significance with respect to the estimated reference
[ref1,ref2] = noisest(Ls,g1,g2,a1,a2,M1,M2,T,F);
tau1 = ref1*r1;
tau2 = ref2*r2;

% initialization of residual, layers, min and max number of iterations
% and epsilon, the upper limit for the residual condition, which is
% computed at the kmin-th iteration
% R = postpad(f,L);
R = f;
l1 = zeros(Ls,1);
l2 = zeros(Ls,1);
k = 1;
kmin = 5;
kmax = kv.maxit;
epsilon = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% main loop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% runs until all values in R are below epsilon to exclude single peaks 
while all(abs(R) < epsilon) ~= 1

    switch flags.algver
       case 'ver1'
        [x1,x2]=jigsaw1(R,g1,g2,a1,a2,M1,M2,T,F,tau1,tau2);
       case 'ver2'
        [x1,x2]=jigsaw2(R,g1,g2,a1,a2,M1,M2,T,F,tau1,tau2);
    end
    
    % residual parts of the signal
    R = R-x1-x2;
    l1 = l1+x1;
    l2 = l2+x2;
    
    if k == kmax
        break
    end
    
    if k == kmin
        % epsilon is computed as upper limit, corresponding to
        % an empirical p-quantile
        epsilon = sort(abs(R),'ascend');
        epsilon = 5/2*epsilon(round(0.998*numel(epsilon)));
        if flags.do_verbose
            disp(['The current maximum in the residual is ',num2str(max(abs(R)))])
            disp(['An upper bound is estimated to be ',num2str(epsilon)])
        end
    end
    
    k = k+1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flags.do_verbose
    disp('max. number of iteration reached: condition for residual is not fulfilled!')
    disp('Try to increase t2 slightly or change the size of the supertiles.')
end

% fplanes as Ls-by-3 array containing the layers
fplanes = [l1,l2,R];
fplanes = postpad(fplanes,Ls);

% info structure
info.g1 = {wintype, winsize1};
info.g2 = {wintype, winsize2};
info.g3 = {wintype, 2048};
info.M1 = M1;
info.M2 = M2;
info.M3 = 2048;
info.a1 = a1;
info.a2 = a2;
info.a3 = 512;
info.supertilesizes = [F,T];
info.noiseentropy_tonal = ref1;
info.threshold_tonal = tau1;
info.noiseentropy_transient = ref2;
info.threshold_transient = tau2;

% cplanes as 3-by-1 cell array containing
% the gabor coefficients corresp. to the layers
if nargout > 1 || flags.do_plot
    cplanes = cell(3,1);
    cplanes{1} = dgtreal(l1,g1,a1,M1);
    cplanes{2} = dgtreal(l2,g2,a2,M2);
    cplanes{3} = dgtreal(R,info.g3,info.a3,info.M3);
end

% option for plots
if flags.do_plot
    plottfjigsawsep(fplanes,cplanes,info,'fs',kv.fs,'showbuttons','equalyrange');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% compiling functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ r ] = renyi( t,alpha )

% computes the Renyi entropy for an array
% yields high values for peaky data and
% low values for almost constant

if isempty(t)
    r = inf;
elseif norm(t) == 0
    r = inf;
else
    switch nargin
        case 1
            alpha = 2.4;
            r = (1/(1-alpha))*log2(sum(sum(abs(t).^(2*alpha)))*(sum(sum(abs(t).^2)).^(-alpha)));
        case 2
            if alpha <= 0 || alpha == 1
                error('alpha must be chosen positive and unequal to 1.');
            else
                r = (1/(1-alpha))*log2(sum(sum(abs(t).^(2*alpha))).*norm(t(:),2)^(-2*alpha));
            end
        otherwise
            error('This function takes at least one input argument.');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ref1,ref2] = noisest (Ls,g1,g2,a1,a2,M1,M2,T,F)

% computes the entropy for a white noise signal within one supertile
% as estimation reference for the tresholds tau1,tau2

n = noise(Ls,'white');
n1 = dgtreal(n,g1,a1,M1);
n2 = dgtreal(n,g2,a2,M2);
r1 = n1(1:floor(F*M1/Ls),1:floor(T/a1));
r2 = n2(1:floor(F*M2/Ls),1:floor(T/a2));
ref1 = renyi(r1);
ref2 = renyi(r2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Version 1 of the jigsaw puzzle algorithm %%%%%%%%%%%%%%%%%%

function [x1,x2] = jigsaw1(R,g1,g2,a1,a2,M1,M2,T,F,tau1,tau2)

% error check?

% signal lengths
Ls = length(R);
L1 = dgtlength(Ls,a1,M1); 
L2 = dgtlength(Ls,a2,M2);

% gabor transformations
c1 = dgtreal(R,g1,a1,M1); % M1/2+1-by-L/a1
c2 = dgtreal(R,g2,a2,M2); % M2/2+1-by-L/a2

% frequency hop sizes
b1 = L1/M1;
b2 = L2/M2;

% indices on the TF plane (L/2+1 x L), where the coefficients belong to
aa1 = 1:a1:L1;
aa2 = 1:a2:L2;
bb1 = 1:b1:L1/2+1;
bb2 = 1:b2:L2/2+1;

L = max([L1,L2]);

% find the indices for the coefficients in every single TF-supertile
for m=0:floor((L/2+1)/F)-1
    for n=0:floor(L/T)-1
        f1 = find(bb1<=(m+1)*F & bb1>m*F);
        f2 = find(bb2<=(m+1)*F & bb2>m*F);
        t1 = find(aa1<=(n+1)*T & aa1>n*T);
        t2 = find(aa2<=(n+1)*T & aa2>n*T);
        % look for parts of c1,c2 where tonal/transient parts are repr well
        [c1,c2] = decision1(c1,c2,f1,f2,t1,t2,tau1,tau2);
    end
end

% last column of remaining supertiles 
for m=0:floor((L/2+1)/F-1)
    f1 = find(bb1<=(m+1)*F & bb1>m*F);
    f2 = find(bb2<=(m+1)*F & bb2>m*F);
    t1 = find(aa1<=L & aa1>floor(L/T)*T);
    t2 = find(aa2<=L & aa2>floor(L/T)*T);
    
    [c1,c2] = decision1(c1,c2,f1,f2,t1,t2,tau1,tau2);
end

% upper row of remaining supertiles
for n=0:floor(L/T-1)
    f1 = find(bb1<=L/2+1 & bb1>floor((L/2+1)/F)*F);
    f2 = find(bb2<=L/2+1 & bb2>floor((L/2+1)/F)*F);
    t1 = find(aa1<=(n+1)*T & aa1>n*T);
    t2 = find(aa2<=(n+1)*T & aa2>n*T);
    
    [c1,c2] = decision1(c1,c2,f1,f2,t1,t2,tau1,tau2);
end

% right upper remaining supertiles
f1 = find(bb1<=L/2+1 & bb1>floor((L/2+1)/F)*F);
f2 = find(bb2<=L/2+1 & bb2>floor((L/2+1)/F)*F);
t1 = find(aa1<=L & aa1>floor(L/T)*T);
t2 = find(aa2<=L & aa2>floor(L/T)*T);

[c1,c2] = decision1(c1,c2,f1,f2,t1,t2,tau1,tau2);


% synthesis with the canonical dual windows
x1 = idgtreal(c1,{'dual',g1},a1,M1,Ls);
x2 = idgtreal(c2,{'dual',g2},a2,M2,Ls);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [c1,c2] = decision1(c1,c2,f1,f2,t1,t2,tau1,tau2)

% decision procedure for version 1
%   case 1: both entropies are above their thresholds -> set them to zero
%   case 2: g1 has a better repr. and the entropy is below its
%           threshold -> set the tile corr. to g2 to zero
%   case 3: vice versa
%   case 4: g1 has a better repr. and its entropy is above its
%           threshold tau1 but despite of that, the entropy corr. to
%           g2 is below its threshold tau2 -> set the tile corr. to
%           g1 to zero
%   case 5: vice versa

E1 = renyi(c1(f1,t1));
E2 = renyi(c2(f2,t2));

if E1 > tau1 && E2 > tau2
    c1(f1,t1) = 0;               
    c2(f2,t2) = 0;
else
    if (min([E1,E2]) == E1 && E1 < tau1) || (min([E1,E2]) == E2 && E2 > tau2 && E1 < tau1)
        c2(f2,t2) = 0;
    elseif (min([E1,E2]) == E2 && E2 < tau2) || (min([E1,E2]) == E1 && E1 > tau1 && E2 < tau2)
        c1(f1,t1) = 0;
    else
        warning('something went wrong with the decision criteria!');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Version 2 of the jigsaw puzzle algorithm %%%%%%%%%%%%%%%%%%

function [x1,x2] = jigsaw2(R,g1,g2,a1,a2,M1,M2,T,F,tau1,tau2)

% signal lengths
Ls = length(R);
L1 = dgtlength(Ls,a1,M1); 
L2 = dgtlength(Ls,a2,M2);

% frequency hop sizes
b1 = L1/M1;
b2 = L2/M2;

% gabor transformation
c1 = dgtreal(R,g1,a1,M1); % M1/2+1-by-L/a1
c2 = dgtreal(R,g2,a2,M2); % M2/2+1-by-L/a2

% indices on the TF plane (L/2+1 x L), where the coefficients belong to
aa1 = 1:a1:L1;
aa2 = 1:a2:L2;
bb1 = 1:b1:L1/2+1;
bb2 = 1:b2:L2/2+1;

L = max([L1,L2]);

for m=0:floor((L/2+1)/F)-1
    for n=0:floor(L/T)-1
        % find the indices for the coefficients in each TF-supertile
        f1 = find(bb1<=(m+1)*F & bb1>m*F);
        f2 = find(bb2<=(m+1)*F & bb2>m*F);
        t1 = find(aa1<=(n+1)*T & aa1>n*T);
        t2 = find(aa2<=(n+1)*T & aa2>n*T);
        % keep the tonals
        [c1,c2] = decision2ton(c1,c2,f1,f2,t1,t2,tau1);
    end
end

% last column of remaining supertiles 
for m=0:floor((L/2+1)/F-1)
    f1 = find(bb1<=(m+1)*F & bb1>m*F);
    f2 = find(bb2<=(m+1)*F & bb2>m*F);
    t1 = find(aa1<=L & aa1>floor(L/T)*T);
    t2 = find(aa2<=L & aa2>floor(L/T)*T);
    % keep the tonals
    [c1,c2] = decision2ton(c1,c2,f1,f2,t1,t2,tau1);
end

% upper row of remaining supertiles
for n=0:floor(L/T-1)
    f1 = find(bb1<=L/2+1 & bb1>floor((L/2+1)/F)*F);
    f2 = find(bb2<=L/2+1 & bb2>floor((L/2+1)/F)*F);
    t1 = find(aa1<=(n+1)*T & aa1>n*T);
    t2 = find(aa2<=(n+1)*T & aa2>n*T);
    % keep the tonals
    [c1,c2] = decision2ton(c1,c2,f1,f2,t1,t2,tau1);
end

% right upper remaining supertile
f1 = find(bb1<=L/2+1 & bb1>floor((L/2+1)/F)*F);
f2 = find(bb2<=L/2+1 & bb2>floor((L/2+1)/F)*F);
t1 = find(aa1<=L & aa1>floor(L/T)*T);
t2 = find(aa2<=L & aa2>floor(L/T)*T);
% keep the tonals
[c1,~] = decision2ton(c1,c2,f1,f2,t1,t2,tau1);


% synthesis of the tonal parts with the canonical dual window of g1
x1 = idgtreal(c1,{'dual',g1},a1,M1,Ls);
RR = R-x1;

% the same procedure is now applied with respect to the narrow window g2

% gabor transformation
c1 = dgtreal(RR,g1,a1,M1); % M1/2+1-by-L/a1
c2 = dgtreal(RR,g2,a2,M2); % M2/2+1-by-L/a2

for m=0:floor((L/2+1)/F)-1
    for n=0:floor(L/T)-1
        % find the indices for the coefficients in each TF-supertile
        f1 = find(bb1<=(m+1)*F & bb1>m*F);
        f2 = find(bb2<=(m+1)*F & bb2>m*F);
        t1 = find(aa1<=(n+1)*T & aa1>n*T);
        t2 = find(aa2<=(n+1)*T & aa2>n*T);
        % keep the transients
        [~,c2] = decision2trans(c1,c2,f1,f2,t1,t2,tau2);
    end
end

% last column of remaining supertiles 
for m=0:floor((L/2+1)/F-1)
    f1 = find(bb1<=(m+1)*F & bb1>m*F);
    f2 = find(bb2<=(m+1)*F & bb2>m*F);
    t1 = find(aa1<=L & aa1>floor(L/T)*T);
    t2 = find(aa2<=L & aa2>floor(L/T)*T);
    % keep the transients
    [~,c2] = decision2trans(c1,c2,f1,f2,t1,t2,tau2);
end

% upper row of remaining supertiles
for n=0:floor(L/T-1)
    f1 = find(bb1<=L/2+1 & bb1>floor((L/2+1)/F)*F);
    f2 = find(bb2<=L/2+1 & bb2>floor((L/2+1)/F)*F);
    t1 = find(aa1<=(n+1)*T & aa1>n*T);
    t2 = find(aa2<=(n+1)*T & aa2>n*T);
    % keep the transients
    [~,c2] = decision2trans(c1,c2,f1,f2,t1,t2,tau2);
end

% right upper remaining supertile
f1 = find(bb1<=L/2+1 & bb1>floor((L/2+1)/F)*F);
f2 = find(bb2<=L/2+1 & bb2>floor((L/2+1)/F)*F);
t1 = find(aa1<=L & aa1>floor(L/T)*T);
t2 = find(aa2<=L & aa2>floor(L/T)*T);
% keep the transients
[~,c2] = decision2trans(c1,c2,f1,f2,t1,t2,tau2);


% synthesis of the transient parts with the canonical dual window of g2
x2 = idgtreal(c2,{'dual',g2},a2,M2,Ls);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [c1,c2] = decision2ton(c1,c2,f1,f2,t1,t2,tau1)
% decision procedure for tonals

E1 = renyi(c1(f1,t1));
E2 = renyi(c2(f2,t2));

if min([E1,E2]) == E2 || E1 > tau1
    c1(f1,t1) = 0;
end

function [c1,c2] = decision2trans(c1,c2,f1,f2,t1,t2,tau2)
% decision procedure for transients

E1 = renyi(c1(f1,t1));
E2 = renyi(c2(f2,t2));

if min([E1,E2]) == E1 || E2 > tau2
    c2(f2,t2) = 0;
end

