function [ROIIdxV,ROIDataM] = getRasterROI(DCEData3M)
% AI  09/28/16
% ========================================================================
% INPUTS
% DCEData3M : ( img rows x cols x time pts) 3-D matrix of masked DCE data 
% ========================================================================

%Get dimensions
nRows = size(DCEData3M,1);
nCols = size(DCEData3M,2);
nTimePts = size(DCEData3M,3);
nVox = nRows * nCols;

%Rasterize and concatenate scans
DCEData3M = rot90(flipud(DCEData3M),-1); 
dataPointsM = reshape(DCEData3M,[nVox,1,nTimePts]);
dataPointsM = squeeze(dataPointsM);

%Get ROI data
ROIIdxV = any(dataPointsM.');
ROIDataM = dataPointsM(ROIIdxV,:);

end