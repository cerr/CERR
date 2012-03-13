%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

[influenceM1] = getInfluenceM(IM, 15);
[influenceM2] = getInfluenceM(IM, 12);
[influenceM3] = getInfluenceM(IM, 13);


Inf = [influenceM1;influenceM2;influenceM3];


Task1 = zeros(size(influenceM1,1),1);
Task2 = ones(size(influenceM2,1),1);
Task3 = ones(size(influenceM3,1),1);

TskF = [Task1;Task2;Task3];

H = Inf' * Inf;

H = H + 1e-10 * eye(size(H));

w = inv(H) * (Inf' * TskF);

w(w<0)  = 0;

y = 0;
for i = 1:11,
    y(i) = 0.2*(i-1);
    w = 0.5*inv((Inf'*Inf))*(2*Inf'*TskF + y(i));
    J(i) = (TskF - Inf*w)^2 + y(i)*w;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% QP   %%%
numPBs=size(Inf,2);
H =  Inf' * Inf;

H = H + 1e-10 * eye(size(H));

% f =  s_t2 * f_t2/size(infl_t2,1) +  s_sc * f_sc/size(infl_sc,1) + s_margin * f_t2_margin/size(infl_t2_margin,1)
f = - Inf'*TskF;
A = []; b = []; Aeq = []; beq = []; UB = [];

LB = zeros(numPBs,1);

UB = ones(numPBs,1) * 400;

optimset('tolfun',0.00000001,'maxiter',200,'display','iter')

[w, feval, exit, outputflag, lambda] = quadprog(H,f,A,b,Aeq,beq,LB,UB)