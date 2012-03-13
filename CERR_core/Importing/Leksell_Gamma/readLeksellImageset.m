function [mat, scanInfo] = readLeksellImageset(imageDir,imageType)
%"readLeksellImageset"
%   Reads the images from a scan directory copied off a Leksell gamma knife
%   treatment planning system and returns a struct array with the image
%   data as well as a matrix of the image values.
%
%JRA 06/24/05
%
%LM: KRK, 06/06/07, changed gridUnits, voxel size, and slice thicknesses in
%                   convertLeksellToCERRScanInfo (function at the bottom of
%                   this file) to make the Leksell plans import correctly
%                   into CERR.
%    KRK, 06/08/07, added additional documentation
%
%Usage:
%   [mat, scanInfo] = readLeksellImageset(imageDir)
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

files = dir(imageDir);

%Compile the file names and keep only those that need to be read (.imh/.ima) 
filesToRead = {};
for i=1:length(files);
    [fpath, fname, fext] = fileparts(files(i).name);
    if strcmpi(fname, '.') | strcmpi(fname, '..')
    end
    if strcmpi(fext, '.imh') | strcmpi(fext, '.ima')
        filesToRead{end+1} = fname;
    end
end

filesToRead = unique(filesToRead);

if isempty(filesToRead)
    mat = [];
    scanInfo = [];
    return
end
%For each file, read in the pixel intensities from the .ima files, as well
%as the information about each .ima in the associated .imh file (.ima =
%image pixel intensities, .imh = header information for the associated
%image).
mat = [];
for i=1:length(filesToRead)
    fid = fopen([fullfile(imageDir, filesToRead{i}) '.ima'], 'r', 'b');
    slice = fread(fid, 'uint16');
    mat(:,:,i) = reshape(slice, sqrt(length(slice)), sqrt(length(slice)));
    %Use readLeksellImhFile to get the array of strings from the header
    %file
    str(i) = readLeksellImhFile([fullfile(imageDir, filesToRead{i}) '.imh']);
end

%Rearrange the pixel intensities so the images can be imported with the
%correct orientations in CERR
mat = permute(mat, [2 1 3]);
mat = flipdim(mat, 1);
%Use the convertLeksellToCERRScanInfo function to put the array of strings read from
%the header file into the scanInfo data structure for importing into CERR
scanInfo = convertLeksellToCERRScanInfo(str, imageType);

%sort the info and associated pixels by the slice number, put into order
[slcOrder, ind] = sort([scanInfo.sliceNum]);
scanInfo(1:end) = scanInfo(ind);
mat(:,:,1:end) = mat(:,:,ind);


function str = readLeksellImhFile(filename)
%"readLeksellImhFile"
%
% Reads a Leksell .imh into an array of strings to later be parsed by convertLeksellToCERRScanInfo 
%
% Usage:
%   str = readLeksellImhFile(filename)
fid = fopen(filename, 'r', 'b');

illegalChars = ['[]{}'];

while ~feof(fid)
    line = fgetl(fid);
    blankInds = strfind(line, ' ');
    fieldname = line(1:blankInds(1)-1);
    fielddata =line(blankInds(1)+3:end);
    
    badChars = ismember(uint16(fieldname), uint16(illegalChars));
    fieldname(badChars) = [];
    
    str.(fieldname) = fielddata;
end
fclose(fid);
return;

function scanInfo = convertLeksellToCERRScanInfo(str, imageType)
%"convertLeksellToCERRScanInfo"
%
% Parses the strings read from the header files and puts the data into the 
% CERR compliant planC{indexS.scan}.scanInfo data structure.       
%   
% Usage:
%   scanInfo = convertLeksellToCERRScanInfo(str)
scanInitS = initializeScanInfo;
                 
for i = 1:length(str)
%initilize the tmp variable
    tmp = scanInitS;
    
%get the slice number of the current image    
    tmp(1).sliceNum = str2num(str(i).z);
    
%initialize the grid units, which will then be uniformized in the import 
%code to find the uniform voxel sizes (divide them by 10 to convert mm->cm)
    voxSize3D = str2num(str(i).voxelSize) ./ 10;
    tmp.grid1Units = voxSize3D(1);
    tmp.grid2Units = voxSize3D(2);
%do the same for the zValues except make it negative to make the images go
%from head to foot rather than foot to head.
    tmp.zValue = -str2num(str(i).slicePos)/10;
    
%read in the type of scan (MR/CT/etc)
    tmp.scanType = str(i).stackId;
    
%All Leksell files have the bottom left of the image as the origin. To make
%this RTOG compliant the offset should then be half of the dimension sizes
%to make the origin at the center of the image.
    tmp.xOffset = str2num(str(i).im_sizeX) / 2 * voxSize3D(1);
    tmp.yOffset = str2num(str(i).im_sizeY) / 2 * voxSize3D(2);   
    
%dimension sizes of the current image
    tmp.sizeOfDimension1 = str2num(str(i).im_sizeY);
    tmp.sizeOfDimension2 = str2num(str(i).im_sizeX);
    
    if strcmpi(upper(imageType),'CT')
        tmp.CTAir = 0;
        tmp.CTWater = 1024;
        tmp.CTOffset = 1024;
    else
        tmp.CTAir = 0;
        tmp.CTWater = 1024;
        tmp.CTOffset = 0;
    end
    
    tmp.numberOfDimensions = 2;
    tmp.bytesPerPixel = str2num(str(i).pixsize)/8; %pixel size given in bits, divide by 8 to get bytes
    scanInfo(i) = tmp;
end
return;