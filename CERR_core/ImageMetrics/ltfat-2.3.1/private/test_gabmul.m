%-*- texinfo -*-
%@deftypefn {Function} test_gabmul
%@verbatim
% Compare approximation by Gabor Multiplier by LTFAT and XXL
%
% using
% LTFAT - this toolbox
% XXL   - the collection of MATLAB files by P. Balazs found at 
%         http://www.kfs.oeaw.ac.at/xxl/Dissertation/matlabPhDXXL.html
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_gabmul.html}
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
clear;

if exist('gabbaspIrr','file') ~= 2
    disp('In this test file the LTFAT implementation is compared to the one found at');
    disp('http://www.kfs.oeaw.ac.at/xxl/Dissertation/matlabPhDXXL.html .');
    disp('Please download and put in search path!');
    return
else
    disp(' ');
    disp('      Compare approximation by Gabor Multiplier by LTFAT and XXL      ');
    disp(' ');
end

L = 144; % vector length 
a = 8; % time parameter, hop size
b = 9; % frequency parameter
usetargetmult = 1; % use a multiplier as target?

N = L/a; 
M = L/b; % number of filters
red = L/(a*b); % redundancy
n_fram = N*M; % number of frame elements
xpo = lattp(L,a,b); % time-frequency sampling points

% Creation of Windows:
g = gabtight(a,M,L);
g = [zeros(1,ceil(L/3)) fftshift(gaussnk(floor(2*L/3)))].';
g = g + i*g;
% here tight, so dual = primal
% gs = pgauss(L);
% gs = gabdual(g,a,M);
% gs = eye(L,1);
% gs = [1 1 1 0 0 0];
% gs = g+10*eps;
gs = randc(L,1);

gd = gabdual(g,a,M);
gsd = gabdual(gs,a,M);

% Creation of target system
if usetargetmult == 0
    % random matrix as target
    T = randc(L,L)+i*randc(L,L);
else
    % random multiplier as target
    origsym = randc(M,N)+i*randc(M,N);
    T = gabmulmat(origsym,g,gs,a);
end

% Frame synthesis matrices:
G_xxl = gabbaspIrr(g,xpo); % XXL
Ga = tfmat('dgt',g,a,M);
Gs = tfmat('dgt',gs,a,M); 
Gd = tfmat('dgt',gd,a,M);

% check frame condition
if cond(Ga) == Inf
    disp('The analysis filterbank does not form a frame!');
else
    disp(sprintf('The analysis filterbank forms a frame with frame bound ratio %g.',cond(Ga)^2));
end

if cond(Gs) == Inf
    disp('The synthesis filterbank does not form a frame!'); % check if gabmulappr gives error!
else
    disp(sprintf('The synthesis filterbank forms a frame with frame bound ratio %g.',cond(Gs)^2));
end

Gram = (Gs'*Gs) .* conj(Ga'*Ga); 

% Frame matrix for tensor products
S_tensor = [];
for ii = 1:n_fram
    P = Ga(:,ii)*Gs(:,ii)';
    S_tensor = [S_tensor P(:)];
end;

% % Gram matrix in HS
if cond(S_tensor) == Inf
     disp('The tensor products do not form a frame sequence!');
else
    disp(sprintf('The tensor products form a frame sequence with frame bound ratio %g.',cond(S_tensor)));
    if det(Gram) ~= 0
        disp('They form a Riesz sequence!');
    end
end
disp(' ');

disp('--- Comparing Gabor systems: ---');
compnorm(G_xxl.',Ga);

lowsym_direct = zeros(M*N,1); %lower symbol as in GMAPPIR
for ii=1:n_fram
      lowsym_direct(ii) =  (Gs(:,ii)')*(T*Ga(:,ii));
end;
lowsym_direct = reshape(lowsym_direct,M,N);
% reordering (conj/invol.) due to TF structure
lowsym_xxl = reshape(diag(Gs'*(T*Ga)),M,N);

lowsym_ltfat = mat2low(T.',g,gs,a,M);
% lowsym_ltfat(T) = lowsym_xxl(T).' = lowsym_ltfat ( T.')

disp('--- Comparing lower symbols: ---');
compnorm(lowsym_xxl,lowsym_direct);
compnorm(lowsym_ltfat,lowsym_xxl);

% % upper symbol:
pinvGram = pinv(Gram);
uppsym_xxl = reshape(pinvGram*(lowsym_xxl(:)),M,N);
uppsym_direct = reshape(pinvGram*(lowsym_direct(:)),M,N);
% uppsym_new = low2upp(lowsym_xxl,g,gs,a);
uppsym_ltfat = gabmulappr(T,g,gs,a,M);

% new idea
% we know: reshape(dgt(T,g,a,M),M,N)-Ga'*T == 0
% so later use (also above) the faster dgt

[GM_irr,uppsym_irr] = GMAPPir(T.',xpo,g,gs);
uppsym_irr = reshape(uppsym_irr,M,N);

disp('--- Comparing upper symbols: ---');
compnorm(uppsym_xxl,uppsym_ltfat);
compnorm(uppsym_xxl,uppsym_direct);
compnorm(uppsym_irr,uppsym_direct);

% compnorm(uppsym_ltfat,uppsym_new);
% compnorm(uppsym_ltfat,uppsym_xxl);
if usetargetmult == 1
    disp('             - Comparing to original symbol: -');
    compnorm(uppsym_ltfat,origsym);
end
 
     % XXL
GM_ltfat = gabmulmat(uppsym_ltfat,g,gs,a);
% conjugation works for Gabor multiplier!!
GM_test = zeros(L,L);
for ii = 1:N*M
    P = Ga(:,ii)*Gs(:,ii)';
    GM_test = GM_test + uppsym_direct(ii)*P;
end;
% direct
GM_direct = Gs*(diag(uppsym_direct(:))*Ga');

disp('--- Comparing matrices: ---');
compnorm(GM_direct,GM_ltfat);
compnorm(GM_ltfat,GM_irr.');
% !!!!!!!!!!!!!!!!
% compnorm(GM_irr,GM_direct);

disp('--- Approximation error: ---');
compnorm(GM_ltfat,T);
compnorm(GM_irr.',T);
compnorm(GM_direct,T);

% %--------------------
% % new idea:
% % use matrix representation of operator
% % take the diagonal for multiplier:
% uppsym_soend = diag(reshape(dgt(T*Gd,g,a,M),9,9)); 
% GM_soend = Gs*(diag(uppsym_soend(:))*Ga');
%
% disp('----- Comparing new idea: -------');
% compnorm(uppsym_direct,uppsym_soend);
% compnorm(GM_direct,GM_soend);
% compnorm(GM_soend,T);





