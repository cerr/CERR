function getDT(str1, str2)
%"getDT"
%   Displays a bidirectional dose map with the max and min dose for all
%   pixels x, y distance away from the surface of each structure.
%
%JRA Sept 1, 04
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

global planC
global stateS

indexS = planC{end};
optS = stateS.optS;

resolution = .20;
minDistance = 3;

nBins = 60;

[dist3M1, xV1, yV1, zV1] = getDistanceXForm(str1, minDistance, resolution);

[dist3M2, xV2, yV2, zV2] = getDistanceXForm(str2, minDistance, resolution, xV1, yV1, zV1);
 

[xMesh, yMesh, zMesh] = meshgrid(xV1, fliplr(yV1), zV1);
doses = getDoseAt(stateS.doseSet, planC, indexS, optS, xMesh, yMesh, zMesh);


bins = getBins(min([dist3M1(:);dist3M2(:)]), max([dist3M1(:);dist3M2(:)]), nBins);

[n,bin1] = histc(dist3M1(:), bins);
[n,bin2] = histc(dist3M2(:), bins);

maxD = zeros(length(bins), length(bins));
minD = maxD;

for i=1:length(bins)
    for j=1:length(bins)
        
        allDoses = doses(bin1==i & bin2==j);
        if ~isempty(allDoses)           
            maxD(i,j) = max(allDoses);
            minD(i,j) = min(allDoses);
        else
            maxD(i,j) = NaN;
            minD(i,j) = NaN;
        end
        
    end
end

cM = CERRColorMap(stateS.optS.doseColormap);

binSep = bins(2)-bins(1);

figure;
hold on;
colormap(cM);
imagesc([bins(1)+binSep/2 bins(end)+binSep/2], [bins(1)+binSep/2 bins(end)+binSep/2], maxD, [0 stateS.doseArrayMaxValue]);
colorbar;
image([bins(1)+binSep/2 bins(end)+binSep/2], [bins(1)+binSep/2 bins(end)+binSep/2], colorize(maxD, cM, stateS.doseArrayMaxValue));
line([bins(1) bins(end)], [0 0], 'linestyle', '--');
line([0 0], [bins(1) bins(end)], 'linestyle', '--');
axis xy
xlabel(['Distance from ' planC{indexS.structures}(str2).structureName ' surface']);
ylabel(['Distance from ' planC{indexS.structures}(str1).structureName ' surface']);

figure;
hold on;
colormap(cM);
imagesc([bins(1)+binSep/2 bins(end)+binSep/2], [bins(1)+binSep/2 bins(end)+binSep/2], minD, [0 stateS.doseArrayMaxValue]);
colorbar;
image([bins(1)+binSep/2 bins(end)+binSep/2], [bins(1)+binSep/2 bins(end)+binSep/2], colorize(minD, cM, stateS.doseArrayMaxValue));
line([bins(1) bins(end)], [0 0], 'linestyle', '--');
line([0 0], [bins(1) bins(end)], 'linestyle', '--');
axis xy
xlabel(['Distance from ' planC{indexS.structures}(str2).structureName ' surface']);
ylabel(['Distance from ' planC{indexS.structures}(str1).structureName ' surface']);


% figure;
% hold on;
% cM = CERRColorMap(stateS.optS.doseColormap);
% n = size(cM,1);
% range = [0 stateS.doseArrayMaxValue];
% for i=1:length(dist3M1(:))
%     color = round(doses(i)/stateS.doseArrayMaxValue*(n-1))+1;
%     plot(dist3M1(i), dist3M2(i), 'color', cM(color,:));              
% end


function bins = getBins(minVal, maxVal, nBins);
    binWidth = (maxVal - minVal) / nBins;
    bins = minVal:binWidth:maxVal;
    
function cData3M = colorize(data, cM, maxVal);
    n = size(cM, 1);
    cIndV = round(data./maxVal*(n-1)) + 1;
	cIndV(isnan(cIndV)) = 1;
	colorized = cM(cIndV, :);
	colorShaped = reshape(colorized, [size(data) 3]);
	for i=1:3
        inds = find(isnan(data));
        slic = colorShaped(:,:,i);
        slic(inds) = 1;
        colorShaped(:,:,i) = slic;
	end
    cData3M = colorShaped;