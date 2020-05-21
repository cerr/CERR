function [dice,tp,fp,p,q,c,volSimilarity,absRelVolDiff] = calc_DiceMetric(structNum1,structNum2,planC)
%function dice = calc_DiceMetric(structNum1,structNum2,planC)
%
%This function computes Dice similarity metric between structNum1 and structNum2
%
%APA, 03/09/2009
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

if ~exist('planC','var')
    global planC
end

[intersectVol, planC] = getIntersectionVolume(structNum1,structNum2,planC);
[vol1, planC] = getStructureVol(structNum1, planC);
[vol2, planC] = getStructureVol(structNum2, planC);

dice = 2 * intersectVol / (vol1 + vol2);


% Additional volumetric metrics
mask1M = getStrMask(structNum1,planC);
mask2M = getStrMask(structNum2,planC);

% intrsctMaskM = mask1M & mask2M;

maskTruePosM = mask1M & mask2M;
maskTrueNegM = ~mask1M & ~mask2M;
maskFalsePosM = mask2M & ~mask1M;
maskFalseNegM = ~mask2M & mask1M;


volSimilarity = 2*sum(abs(mask1M(:) - mask2M(:))) / (sum(mask1M(:)) + sum(mask2M(:)));
volSimilarity = 1 - volSimilarity;

absRelVolDiff = abs(sum(mask1M(:))/sum(mask2M(:)) - 1) * 100;

% True positive
tp = sum(maskTruePosM(:));

% False positive
fp = sum(maskFalsePosM(:));

% sensitivity
p = sum(maskTruePosM(:)) / (sum(maskTruePosM(:)) + sum(maskFalseNegM(:)));

% specificity
q = sum(maskTrueNegM(:)) / (sum(maskTrueNegM(:)) + sum(maskFalsePosM(:)));


% C-factor
d = 2*p*(1-q) / (p+1-q) + 2*(1-p)*q / (1-p+q);

c = NaN;
if p > 1-q && p >= q
    c = d;
elseif p > 1-q && p < q
    c = -d;
end




