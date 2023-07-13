function [initFlag,addPathC] = init_ML_DICOM
%"init_ML_DICOM"
%   Sets env variables necessary for operation of ML_DICOM.
%
%DK 09/20/06
%NAV 07/19/16 updated to dcm4che3
%
%Usage:
%   init_ML_DICOM
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

initFlag = 1;

if isdeployed
%     path1 = fullfile(getCERRPath,'bin','dcm4che-5.17.0','lib','dcm4che-core-5.17.0.jar');
%     path2 = fullfile(getCERRPath,'bin','dcm4che-5.17.0','lib','log4j-1.2.17.jar');
%     path3 = fullfile(getCERRPath,'bin','dcm4che-5.17.0','lib','slf4j-api-1.7.25.jar');
%     path4 = fullfile(getCERRPath,'bin','dcm4che-5.17.0','lib','slf4j-log4j12-1.7.25.jar');
%     path5 = fullfile(getCERRPath,'bin','dcm4che-5.17.0','lib','dcm4che-image-5.17.0.jar');
%     path6 = fullfile(getCERRPath,'bin','dcm4che-5.17.0','lib','dcm4che-imageio-5.17.0.jar');
%     path7 = fullfile(getCERRPath,'bin','dcm4che-5.17.0','lib','dcm4che-imageio-rle-5.17.0.jar');
%     %path8 = fullfile(getCERRPath,'bin','dcm4che-5.17.0','lib','dcm4che-iod-2.0.27.jar');
%     path9 = fullfile(getCERRPath,'bin','dcm4che-5.17.0','lib','dcm4che-net-5.17.0.jar');
%     addPathC = {path1,path2, path5,path6,path7,path9};
%     javaaddpath(addPathC);
    
    return
end

% apa commented Java version check since dcm4che3 is copatible with java >=
% 5 (Public support and security updates for Java 1.5 ended in November
% 2009).
% javaVersion = version('-java');
% if isempty(num2str(javaVersion(8))) || num2str(javaVersion(8)) < 5
%     warndlg('The current MATLAB Java VM is not compatible. Please see Export documentation on how to update Java VM to Java 1.5.0_06');
%     initFlag = 0;
% end

% MATLABVer = version;
% [num1,remain] = strtok(MATLABVer,'.');
% ML_main_version = str2num(num1);
%num2 = strtok(remain(2:end),'.');
%ML_sub_version = str2num(num2);

% if ML_main_version >= 7
%     path1 = which('dcm4che-core-5.17.0.jar');
%     path2 = which('log4j-1.2.17.jar');
%     path3 = which('slf4j-api-1.7.25.jar');
%     path4 = which('slf4j-log4j12-1.7.25.jar');
%     path5 = which('dcm4che-image-5.17.0.jar');
%     path6 = which('dcm4che-imageio-5.17.0.jar');
%     path7 = which('dcm4che-imageio-rle-5.17.0.jar');
%    % path8 = which('dcm4che-iod-3.3.8.jar'); %NOT FOUND IN LATEST BINARY
%     path9 = which('dcm4che-net-5.17.0.jar');
% else
%oldpath = pwd;
%ML_dcm = what(fullfile('dcm4che-5.17.0','lib'));
ML_dcm_path = fullfile(getCERRPath,'..','ML_Dicom','dcm4che-5.17.0','lib');
if ~exist(ML_dcm_path,'dir')
    warndlg('File "dcm4che-core-5.17.0.jar" is not added to MATLAB path. Add the folder "dcm4che-core-5.17.0" to MATLAB path and start again');
    initFlag = 0;
    return;
end
path1 = fullfile(ML_dcm_path,'dcm4che-core-5.17.0.jar');
path2 = fullfile(ML_dcm_path,'log4j-1.2.17.jar');
path3 = fullfile(ML_dcm_path,'slf4j-api-1.7.25.jar');
path4 = fullfile(ML_dcm_path,'slf4j-log4j12-1.7.25.jar');
path5 = fullfile(ML_dcm_path,'dcm4che-image-5.17.0.jar');
path6 = fullfile(ML_dcm_path,'dcm4che-imageio-5.17.0.jar');
path7 = fullfile(ML_dcm_path,'dcm4che-imageio-rle-5.17.0.jar');
%path8 = fullfile(ML_dcm.path,'dcm4che-iod-3.3.8.jar');
path9 = fullfile(ML_dcm_path,'dcm4che-net-5.17.0.jar');
path10 = fullfile(ML_dcm_path,'weasis-opencv-core-3.0.4.jar');
path11 = fullfile(ML_dcm_path,'dcm4che-imageio-opencv-5.17.0.jar');
path12 = fullfile(ML_dcm_path,'jai_imageio-1.2-pre-dr-b04.jar');
%cd(oldpath);
% end

mlVer = ver('Matlab');
octVer = ver('Octave');
if ~isempty(octVer)
    javaaddpath(path1,path2, path3, path4, path5,path6,path7,path9,path10,path11,path12);
elseif ~isempty(mlVer)
    javaaddpath({path1,path2,path3, path4, path5,path6,path7,path9,path10,path11,path12});
end
addPathC = {path1,path2, path3, path4, path5,path6,path7,path9,path10,path11,path12};

