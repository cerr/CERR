function [dcmdirS] = scandir_mldcm(dirPath, hWaitbar, dirNum)
%"scandir_mldcm"
%   Scans a passed directory for DICOM files, checking each file in the
%   directory for properly formatted DICOM regardless of file extension.
%   Builds an output struct containing info on each DICOM file found,
%   including filename, filetype, patient name etc.
%
%   An optional waitbar handle can be passed if a graphical representation
%   of progress is desired.

%
%JRA 6/1/06
%YWU Modified 03/01/08
%
%Usage:
%   infoS = scandir_mldcm(directoryName, hWaitbar)
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

%Check that dirPath is a string

switch lower(class(dirPath))
    case 'char'
    otherwise
        error('Input to scandir_mldcm must be a string.');
end

%Check that it's a real dirPath.
if ~isdir(dirPath)
    error('Input to scandir_mldcm must be a directory.');
end

% if ispc
%     %Get directory contents
%     filesV = dir([dirPath '\*.*']);
% else
%     %filesV = dir([dirPath '/*.*']);
%     filesV = dir([dirPath]);
% end

filesV = dir(dirPath);

%Remove directories from the fileList.
filesV([filesV.isdir]) = [];

%Scan each file, returning
dcmdirS = [];

for i=1:length(filesV)

    filename = fullfile(dirPath, filesV(i).name);
    [dcmObj, isDcm] = scanfile_mldcm(filename);

    if isDcm
        dcmdirS = dcmdir_add(filename, dcmObj, dcmdirS);
        %         [isValid, errMsg] = validate_patient_module(dcmObj);
        dcmObj.clear;
    end
    [pathstr, name, ext] = fileparts(filename);
    waitbar(i/length(filesV),hWaitbar, ['Scanning Directory ' num2str(dirNum) ' Please wait...']);
    %['file: ' name ext]});
end

% Remove the MRI field, since it stores temporary information for matching
% / separating images into different series
%%%%% 4/18/16 ADDED : skipping non-DICOM files %%%%%%%%%%%
if ~isempty(dcmdirS)
    for patNum = 1:length(dcmdirS.PATIENT)
    dcmdirS.PATIENT(patNum).STUDY = rmfield(dcmdirS.PATIENT(patNum).STUDY, 'MRI');
    end
end




