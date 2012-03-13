function metric = getStatisticDose(setDoseNumber1, setDoseNumber2, planC);
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


dose1 = planC{planC{end}.dose}(setDoseNumber1).doseArray;

[xV yV zV] = getDoseXYZVals(planC{planC{end}.dose}(setDoseNumber1));

[x,y,z] = meshgrid(xV,yV,zV);

[dose2] = getDoseAt(setDoseNumber2, x, y, z);

maxDose1 = max(dose1(:));
maxDose2 = max(dose2(:));

dose1(dose1 == 0) = NaN;
dose2(dose2 == 0) = NaN;

dose1Norm = dose1/maxDose1;
dose2Norm = dose2/maxDose2;

dose2CorMax = (maxDose1/maxDose2)*dose2;

diffAbsNorm = abs(dose1Norm - dose2Norm);

metric.Max_Abs_Diff_Norm = max(diffAbsNorm(:));

diffAbsNormPr = 100*diffAbsNorm;

Frac = diffAbsNormPr(~isnan(diffAbsNormPr));

metric.Mean_Abs_Diff_Norm = mean(Frac/100);

Frac2 = find(Frac > 2);

Frac5 = find(Frac > 5);

Frac10 = find(Frac > 10);

metric.Fr2Pr = 100*length(Frac2)/length(Frac);

metric.Fr5Pr = 100*length(Frac5)/length(Frac);

metric.Fr10Pr = 100*length(Frac10)/length(Frac);

diffNormSq = (dose1Norm - dose2Norm).^2;

FracSq = diffNormSq(~isnan(diffNormSq));

metric.rmse = 100*sqrt(sum(FracSq(:))/length(FracSq));