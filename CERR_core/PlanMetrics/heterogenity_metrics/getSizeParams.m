function [SRE,LRE,IV,RLV,RP,LIRE,HIRE,LISRE,HISRE,LILRE,HILRE] = getSizeParams(structNum,numLevels,planC)
%function getSizeParams(structNum)
%
%This function returns zone size based features for structure structNum.
%
%APA, 03/09/2015

if ~exist('planC')
    global planC
end
indexS = planC{end};

scanNum                             = getStructureAssociatedScan(structNum,planC);
[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(volToEval==0)             = NaN;

% Quantize using percentiles
%numLevels = 16;
qtlImage = zeros(size(volToEval));
minVal = min(volToEval(:));
maxVal = max(volToEval(:));
levelsV = linspace(minVal,maxVal,numLevels+1);
%qtlsV = 0:0.1:1;
qtlsV = 1:(numLevels+1);
qltCount = 1;
for qtl = 1:length(qtlsV)-1   
    %lowQtl = quantile(volToEval(:),qtlsV(qltCount));
    %hiQtl = quantile(volToEval(:),qtlsV(qltCount+1));
    lowQtl = levelsV(qltCount);
    hiQtl = levelsV(qltCount+1);
    qtlImage(volToEval > lowQtl & volToEval <= hiQtl) = qltCount;
    qltCount = qltCount + 1;
end

% Compute Zone-Size matrix
clear global run_length_matrix_all image_property
global run_length_matrix_all image_property
image_property.num_voxels = sum(~isnan(volToEval(:)));
run_length_matrix_all = zeros(max(qtlImage(:)), max(size(qtlImage)));
for idx_intensity = 1:max(qtlImage(:))
    mat_isintensity = (qtlImage==idx_intensity);
    mat_connection = bwlabeln(mat_isintensity, 26); % allow the max connectivity
    for idx_group = 1:max(mat_connection(:))
        if size(run_length_matrix_all,2)< length(find(mat_connection== idx_group))
            run_length_matrix_all(idx_intensity, length(find(mat_connection== idx_group))) = 1;
        else
            run_length_matrix_all(idx_intensity, length(find(mat_connection== idx_group))) = run_length_matrix_all(idx_intensity, length(find(mat_connection== idx_group))) +1;
        end
    end
end

% Compute scalar features
SRE = run_length_SRE();
LRE = run_length_LRE();
IV = run_length_IV();
RLV = run_length_RLV();
RP = run_length_RP();
LIRE = run_length_LIRE();
HIRE = run_length_HIRE();
LISRE = run_length_LISRE();
HISRE = run_length_HISRE();
LILRE = run_length_LILRE();
HILRE = run_length_HILRE();
