function [dvfXm, dvfYm, dvfZm, infoS] = readImSimQAdff(dvfFileName)
% function [dvfXm, dvfYm, dvfZXm, infoS] = readImSimQAdff(dvfFileName)
%
% Function to read the ImSimQA deformation field file.
%
% INPUT:
% dvfFileName: ImSimQA deformation field file. 
% 
% OUTPUTS:
% dvfXm: 3d matrix containing the x deformations, 
% dvfYm: 3d matrix containing the y deformations, 
% dvfZm: 3d matrix containing the z deformations, 
% infoS: 3d matrix containing the x deformations, 
%
% APA, 2/9/2018

% Open the input file
fid = fopen(dvfFileName, 'rb');

% Read the DVF metadata into infoS structure
infoS.patientName = fread(fid, 66, 'uint8=>char');
infoS.patientID = fread(fid, 66, 'uint8=>char');
infoS.patientPosition = fread(fid, 36, 'uint8=>char');
infoS.seriesUID = fread(fid, 68, 'uint8=>char');
infoS.numCols = double(fread(fid, 1, 'int=>int'));
infoS.numRows = double(fread(fid, 1, 'int=>int'));
infoS.numSlcs = double(fread(fid, 1, 'int=>int'));
infoS.dx = fread(fid, 1, 'double=>double');
infoS.dy = fread(fid, 1, 'double=>double');
infoS.dz = fread(fid, 1, 'double=>double');

% Read the DVF matrices
numElems = infoS.numCols * infoS.numRows * infoS.numSlcs * 3;
dvfV = fread(fid, numElems, 'float=>single');

% Close the dff file
fclose(fid);

% reshape dvf arrays into 3d matrices
dvfXm = reshape(dvfV(1:3:end),numRows, numCols, numSlcs);
dvfYm = reshape(dvfV(2:3:end),numRows, numCols, numSlcs);
dvfZm = reshape(dvfV(3:3:end),numRows, numCols, numSlcs);

