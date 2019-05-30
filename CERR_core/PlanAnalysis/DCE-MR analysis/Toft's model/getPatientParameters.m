function [paramS, shiftS] = getPatientParameters(patientfName,shiftfName)
% Create input structures from .txt patient parameter file.
% INPUTS
% fName : Path and name of text file containing (tab-delimited) patient parameters.
% -------------------------------------------------------------------------

% Get patient parameters
fid = fopen(patientfName);
if fid == -1
error('File %s could not be opened',patientfName);    
else
patInputC = textscan(fid, '%s %s');
end
numInputIdx = find(strcmp('displayImgNum', patInputC{1}));
patInputC{2}(numInputIdx:end) = cellfun(@str2double,patInputC{2}(numInputIdx:end),'un',0);
paramS = cell2struct(patInputC{2}, patInputC{1}, 1);

% Get shift parameters
fid = fopen(shiftfName);
if fid == -1
error('File %s could not be opened',shiftfName);    
else
shiftInputC = textscan(fid,'%s %s');
end
numInputIdx = find(strcmp('ETROIPointShift', shiftInputC{1}));
shiftInputC{2}(numInputIdx:end) = cellfun(@str2double,shiftInputC{2}(numInputIdx:end),'un',0);
shiftS = cell2struct(shiftInputC{2}, shiftInputC{1}, 1);

end