function featureS = getHypoxiaCrispinOrtuzarFeatures(ctStructNumV,petStructNumV,planC)
% function feature = getHypoxiaCrispinOrtuzarFeatures(ctStructNumV,ctStructNumV,planC)
%
% The radiomic signature to predict TBRmax consists of
% (I) ‘P90’ for the PET High-SUV structure, (II) RLM ‘lrhgle’ for the High-SUV CT structure
%
% INPUTS:
% ctStructNumV: structure indices on contrast enhanced FDG-CT that represent
% the high SUV regions within the GTV.
% petStructNumV: structure indices on FDG-PET that represent the high SUV
% regions within the GTV.
%
% OUTPUT:
% featureS: structure array containing the P90 and LRHGLE features for the
% passed structure indices. It is of same length as the number of input
% structures.
% 
% EXAMPLE:
% ctStructNumV = 15;
% petStructNumV = 14;
% global planC
% featureS = getHypoxiaCrispinOrtuzarFeatures(ctStructNumV,petStructNumV,planC);
% P90_norm = (featureS(1).P90-11.5446)/5.1479;
% LRHGLE_norm = (featureS(1).lrhgle - 7254.5)/1122.1;
% TBRmax = 1.9061 + 0.32381*P90_norm+0.13032*LRHGLE_norm;
%
% Reference:
% Mireia Crispin-Ortuzar, Aditya Apte, Milan Grkovski, Jung Hun Oh, Nancy Y. Lee, Heiko SchÃ¶der, John L. Humm, Joseph O. Deasy,
% Predicting hypoxia status using a combination of contrast-enhanced computed tomography and [18F]-Fluorodeoxyglucose positron emission tomography radiomics features,
% Radiotherapy and Oncology, Volume 127, Issue 1, 2018, Pages 36-42.
% ISSN 0167-8140,
% https://doi.org/10.1016/j.radonc.2017.11.025.
%
% APA, 8/17/2018
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

indexS = planC{end};

% Statistics P90
for i = 1:length(petStructNumV)
    petStructNum = petStructNumV(i);
    ctOffset = 0;
    binwidth = 0.1;
    statsFeatureS = radiomics_first_order_stats(planC,petStructNum,ctOffset,binwidth);
    featureS(i).P90 = statsFeatureS.P90;
end

% RLM LRHGLE

% Parameters
numGrLevels = 100;
minIntensity = -100;
maxIntensity = 150;

for i = 1:length(ctStructNumV)
    ctStructNum = ctStructNumV(i);
    
    scanNum = getStructureAssociatedScan(ctStructNum, planC);
    
    % Get structure
    [rasterSegments, planC, isError]    = getRasterSegments(ctStructNum,planC);
    [mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
    scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
    scanArray3M                         = double(scanArray3M) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
    [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
    maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
    
    % Assign NaN to image outside mask
    volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
    volToEval(~maskBoundingBox3M)       = NaN;
    
    % Quantize the volume of interest
    quantizedM                          = imquantize_cerr(volToEval,numGrLevels,minIntensity,maxIntensity);
    quantizedM(~maskBoundingBox3M)      = NaN;
    numVoxels = sum(~isnan(quantizedM(:)));
    
    % Run-length features
    fieldsC = {'sre','lre','gln','glnNorm','rln','rlnNorm','rp','lglre',...
        'hglre','srlgle','srhgle','lrlgle','lrhgle','glv','rlv','re'};
    valsC = {0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0};
    rlmFlagS = cell2struct(valsC,fieldsC,2);
    
    % Original image
    dirctn = 1;
    rlmType = 2;
    rlmFeaturesS = get_rlm(dirctn, rlmType, quantizedM, ...
        numGrLevels, numVoxels, rlmFlagS);
        
    featureS(i).lrhgle = rlmFeaturesS.MaxS.lrhgle;
end
