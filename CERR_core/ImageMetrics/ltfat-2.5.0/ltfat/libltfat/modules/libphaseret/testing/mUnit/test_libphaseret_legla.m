[~,structs]=libphaseretprotofile;


S = libstruct('phaseret_legla_init_params',struct()); 
calllib('libphaseret','phaseret_legla_init_params_defaults',S);


f = greasy;
a = 256;
M = 2*1024;
M2 = floor(M/2) + 1; 
gl = M;
L = dgtlength(size(f,1),a,M);
g = firwin('blackman',gl);
gd = long2fir(gabdual(g,a,M),gl);
N = L/a;
maxit = 200;

corig = dgtreal(f,{'blackman',gl},a,M);
s = abs(corig) + 1i*zeros(size(corig));
cinitPtr = libpointer('doublePtr',complex2interleaved(s));

cout = zeros(2*M2,N);
coutPtr = libpointer('doublePtr',cout);

tic;
calllib('libphaseret','phaseret_legla_d',cinitPtr,g,L,gl,1,a,M,maxit,coutPtr);
toc;
 cout2 = interleaved2complex(coutPtr.Value);
 %cout2 = phaselockreal(cout2,a,M);


frec = idgtreal(cout2,{'dual',{'blackman',gl}},a,M);
s2 = dgtreal(frec,{'blackman',gl},a,M);
magnitudeerrdb(s,s2)

tic;
cout2 = legla(s,g,a,M,'modtrunc','onthefly','flegla','maxit',maxit);
toc;

frec = idgtreal(cout2,{'dual',{'blackman',gl}},a,M);

s2 = dgtreal(frec,{'blackman',gl},a,M);
magnitudeerrdb(s,s2)

clear S;





%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libphaseret/testing/mUnit/test_libphaseret_legla.html

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

