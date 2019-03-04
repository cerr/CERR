function [scanArray3M,mask3M] = perturbImageAndSeg(scanArray3M,mask3M,planC,scanNum,perturbString)
% function [scanArray3M,mask3M] = perturbImageAndSeg(scanArray3M,mask3M,planC,scanNum,perturbString)
%
% perturbString is a string containing perturbation operations. It can be a
% combination of any letters RNTVC.
%
% APA, 2/28/2019

% Noise
if ismember('N',perturbString)
    scanArray3M = perturbImageNoise(scanArray3M);
end

% Rotation
if ismember('R',perturbString)
    angl = normrnd(0,7);
    [scanArray3M,mask3M] = perturbImageRotation(scanArray3M,mask3M,angl);
end

% Volume adaptation
if ismember('V',perturbString)
    scale = normrnd(1,0.1);
    mask3M = perturbImageVolume(mask3M,scale);
end

% Contour randomization
if ismember('C',perturbString)
    superPixVol = 0.005;
    mask3M = perturbImageContourBySuperpix(mask3M,scanArray3M,superPixVol,planC,scanNum);
end


