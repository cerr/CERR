function tmpS = importDose(doseFileName, tmpS, optS)
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


% OLD : function [doses3M, zValuesV] = importDose(doseFileName, tmpS, optS)
%function dose3M = importDose(doseFileName, sizeOfDimension1, sizeOfDimension2, sizeOfDimension3)
%Get an RTOG dose distribution given the size of raster dimensions.
%In the RTOG dose file, each transverse dose slice is given in order.  Within each transverse
%dose slice, dose values for increasing dimension 1 are given between null (ascii 0)
%characters.  Null characters signal the start of a new row (change in dimension 2)
%When converting to Matlab, dimension1 is the column number, dimension2 is the row number,
%and dimension3 is the third array dimension.
%When converting to AAPM coordinates, increasing dimension1 corresponds to increasing
%X-values, and increasing dimension2 corresponds to decreasing Y-values.  Increasing
%dimension3 corresponds to increasing Z-values.
%'type' can be ASCII or binary; 'endian' can be big or little.
%
%Storage:  requires twice the size of the dose distribution in double precision values.
%
%Author: J. O. Deasy, deasy@radonc.wustl.edu
%
%Rerences:
%1.  W. Harms, Specifications for Tape/Network Format for Exchange of Treatment Planning Information,
%    version 3.22., RTOG 3D QA Center, (http://rtog3dqa.wustl.edu), 1997.
%2.  J.O. Deasy, "A tool for distributing treatment planning software developments:
%    the Radiotherapy Toolbox for Matlab," Submitted for publication to Med Phys, Dec. 2001.
%
%Last Modified:  18 March 2002, by JOD.
%                 5 Sept 03, JOD, (a) fixed bug of not scaling dose distribution for ASCII input dose matrices.
%                                 (b) reduced memory requirements for reading dose
%                 4 Oct 07, APA, Use read_ascii_dose to read ASCII dose on windows platform.
%
%Copyright:
%This software is copyright J. O. Deasy and Washington University in St Louis.
%A free license is granted to use or modify but only for non-commercial non-clinical use.
%Any user-modified software must retain the original copyright and notice of changes if redistributed.
%Any user-contributed software retains the copyright terms of the contributor.
%No warranty or fitness is expressed or implied for any purpose whatsoever--use at your own risk.


if ~isempty(strfind(lower(tmpS.numberRepresentation),'complement'))  %binary?
    type = 'binary';
else
    type = 'ASCII';
end

CERRStatusString(['Dose file type is:  ' type '.'])

endian = optS.CTEndian;

sizeDoseV = [tmpS.sizeOfDimension1, tmpS.sizeOfDimension2, tmpS.sizeOfDimension3];

zValuesV = zeros(1,sizeDoseV(3));

switch type

    case 'ASCII'

        try
            fid = fopen(doseFileName,'r');
            if ~ispc
                textV = fread(fid,'uchar=>uchar');    %8-bit unsigned character vector
                if isempty(textV)
                    warning(['Failed to read dose file:' doseFileName ' is empty...'])
                    return
                end
                binaryFlag = 1;
            else
                dos(['"',getCERRPath,'Importing\readASCIIDose" "',doseFileName,'"'])

                [largeDose, doseArraySizeInMB] = isLargeDose(optS, sizeDoseV);
                zValFile = [cd,'\zValueRuby.txt'];
                binary_file_name = [cd,'\doseRuby.txt'];
                new_binary_file_name = [cd,'\doseRuby_noNull.txt'];
                %Remove null characters
                fidr = fopen(binary_file_name,'r');
                fidw = fopen(new_binary_file_name,'w');
                a = fread(fidr,500000);
                while ~isempty(a)
                    a(a==0) = [];
                    fwrite(fidw,a);
                    a = fread(fidr,500000);
                end
                clear a
                fclose(fidr);
                fclose(fidw);                                                                
                %Clean-up z-value file
                fidZr = fopen(zValFile,'r');                
                aa = fread(fidZr);
                aa(aa==0) = [];
                fclose(fidZr);
                fidZw = fopen(zValFile,'w');
                fwrite(fidZw,aa);
                clear aa                
                fclose(fidZw);
                zValuesV = textread(zValFile);                
                %clean-up of z-values ends
                fidr = fopen(new_binary_file_name,'r');
                if largeDose && strcmpi(optS.downsampleLargeDoses, 'yes')
                    CERRStatusString(['Dose file is very large (' num2str(doseArraySizeInMB) 'MB), downsampling dose slicewise.']);
                    tmpS.depthGridInterval = abs(zValuesV(2)-zValuesV(1));
                    tmpS.coord3OfFirstPoint = zValuesV(1);
                    [tmpV, sizeVoxelV] = loadAndDownsample(fidr, tmpS, sizeDoseV, optS, 'rtog', doseFileName);      

                    %Adjust dose coordinate variables for new downsampled matrix.
                    tmpS.sizeOfDimension1 = size(tmpV, 1);
                    tmpS.sizeOfDimension2 = size(tmpV, 2);
                    tmpS.sizeOfDimension3 = size(tmpV, 3);

                    sizeDoseV = [tmpS.sizeOfDimension1 tmpS.sizeOfDimension2 tmpS.sizeOfDimension3];

                    %Find old corners of dose matrix.
                    coord1Corner = (tmpS.coord1OFFirstPoint - tmpS.horizontalGridInterval/2);
                    coord2Corner = (tmpS.coord2OFFirstPoint - tmpS.verticalGridInterval/2);
                    coord3Corner = (tmpS.coord3OfFirstPoint - tmpS.depthGridInterval/2);

                    %Save new voxel size.
                    tmpS.horizontalGridInterval = sizeVoxelV(1);
                    tmpS.verticalGridInterval = -sizeVoxelV(2);
                    tmpS.depthGridInterval = sizeVoxelV(3);

                    %Calculate x,y,z starting points, at center of corner voxels.
                    tmpS.coord1OFFirstPoint = coord1Corner + tmpS.horizontalGridInterval/2;
                    tmpS.coord2OFFirstPoint = coord2Corner + tmpS.verticalGridInterval/2;
                    tmpS.coord3OfFirstPoint = coord3Corner + tmpS.depthGridInterval/2;
                    
                    doses3M = reshape(tmpV, sizeDoseV);

                    clear tmpV

                    %Rows and columns are reversed, permute.
                    doses3M = permute(doses3M, [2 1 3]);

                    %Fill-in z-values:
                    zStart = tmpS.coord3OfFirstPoint;
                    zWidth = tmpS.depthGridInterval;
                    zEnd   = zStart + zWidth * (sizeDoseV(3) - 1);
                    zValuesV = zStart : zWidth : zEnd;
                
                else %No downsampling required
                    
                    doseC = textscan(fidr,'%n','delimiter',',');    
                    doses3M = double(reshape(doseC{1},sizeDoseV));
                    doses3M = permute(doses3M,[2 1 3]);
                    clear doseC
                    
                end 
                fclose(fidr);
                delete(binary_file_name)
                delete(new_binary_file_name)
                delete(zValFile)
                binaryFlag = 0;                
            end
        catch
            %[doses3M, zValuesV] = readRTOG_ASCII(doseFileName, tmpS, sizeDoseV, optS);
            fclose all;
            try %try to delete temp files created by ruby-script
                delete(binary_file_name)
                delete(new_binary_file_name)
                delete(zValFile)
            end
            return;

            if isempty(zValuesV)
                warning(['Failed to read dose file:' doseFileName])
                doses3M = [];
                zValuesV = [];
                try
                    fclose(fid);
                end
                return
            end
        end

        if binaryFlag

            %First get the Z-values:
            indZV = find([textV == 90] | [textV == 122]); %Z or z.

            indV = find( textV == 13);   %endofline = 13

            for i = 1 : length(indZV)
                ind = 1;
                while textV(indZV(i)+ind)~=13 %Locate EOL
                    ind = ind +1;
                end
                tmpV = textV(indZV(i):indZV(i)+ind);
                tmpV(tmpV==34) = 32;  %Replace last '"' with a blank
                str = char(tmpV');    %Convert to a string
                tmp2 = word(str,words(str)); %Get the last word
                zValuesV(i) = str2num(tmp2);
            end

            %Now process the dose values:

            delV = [];
            try
                if any([textV(1:indV(1)) == 34])  %First line is a comment ( '"' = 34)
                    delV = [1:indV(1)];
                end
            end
            for i = 1 : length(indV) - 1
                if any([textV(indV(i)+1:indV(i+1)) == 34])
                    delV = [delV, indV(i)+1:indV(i+1)];
                end
            end
            clear indV
            textV(delV) = [];
            clear delV
            
            textV(textV == 13) = 32;    %Replace EOLs with spaces
            textV(textV<32) = []; %Delete non-printing characters
            
            textV(textV == 44) = []; %commas
            textV = char(textV');   %Inplace to reduce memory usage.

            doses3M = sscanf(textV','%f');  %convert to numbers
            
            clear textV

            doses3M = reshape(doses3M, sizeDoseV);

            [junk, junk, len] = size(doses3M);
            for i = 1 : len
                tmp(:,:,i) = doses3M(:,:,i)';
            end
            doses3M = tmp;
            clear tmp            

            % Downsample if necessary
            [largeDose, doseArraySizeInMB] = isLargeDose(optS, sizeDoseV);
            if largeDose && strcmpi(optS.downsampleLargeDoses, 'yes')
                CERRStatusString(['Dose file is very large (' num2str(doseArraySizeInMB) 'MB), downsampling dose slicewise.']);
                tmpS.depthGridInterval = abs(zValuesV(2)-zValuesV(1));
                tmpS.coord3OfFirstPoint = zValuesV(1);
                %[tmpV, sizeVoxelV] = loadAndDownsample(fidr, tmpS, sizeDoseV, optS, 'rtog');
                [tmpV, sizeVoxelV] = loadAndDownsample(doses3M, tmpS, sizeDoseV, optS, 'txt', doseFileName);

                %Adjust dose coordinate variables for new downsampled matrix.
                tmpS.sizeOfDimension1 = size(tmpV, 1);
                tmpS.sizeOfDimension2 = size(tmpV, 2);
                tmpS.sizeOfDimension3 = size(tmpV, 3);

                sizeDoseV = [tmpS.sizeOfDimension1 tmpS.sizeOfDimension2 tmpS.sizeOfDimension3];

                %Find old corners of dose matrix.
                coord1Corner = (tmpS.coord1OFFirstPoint - tmpS.horizontalGridInterval/2);
                coord2Corner = (tmpS.coord2OFFirstPoint - tmpS.verticalGridInterval/2);
                coord3Corner = (tmpS.coord3OfFirstPoint - tmpS.depthGridInterval/2);

                %Save new voxel size.
                tmpS.horizontalGridInterval = sizeVoxelV(1);
                tmpS.verticalGridInterval = -sizeVoxelV(2);
                tmpS.depthGridInterval = sizeVoxelV(3);

                %Calculate x,y,z starting points, at center of corner voxels.
                tmpS.coord1OFFirstPoint = coord1Corner + tmpS.horizontalGridInterval/2;
                tmpS.coord2OFFirstPoint = coord2Corner + tmpS.verticalGridInterval/2;
                tmpS.coord3OfFirstPoint = coord3Corner + tmpS.depthGridInterval/2;

                doses3M = reshape(tmpV, sizeDoseV);

                clear tmpV

                %Rows and columns are reversed, permute.
                doses3M = permute(doses3M, [2 1 3]);

                %Fill-in z-values:
                zStart = tmpS.coord3OfFirstPoint;
                zWidth = tmpS.depthGridInterval;
                zEnd   = zStart + zWidth * (sizeDoseV(3) - 1);
                zValuesV = zStart : zWidth : zEnd;
               
            end

        end

        fclose(fid);

    case 'binary'

        if strcmp(endian,'big')
            flag = 'b';
        elseif strcmp(endian,'little')
            flag = 'l';
        end

        try
            fid=fopen(doseFileName,'r',flag);

            [largeDose, doseArraySizeInMB] = isLargeDose(optS, sizeDoseV);

            if largeDose & strcmpi(optS.downsampleLargeDoses, 'yes')
                CERRStatusString(['Dose file is very large (' num2str(doseArraySizeInMB) 'MB), downsampling dose slicewise.']);
                [tmpV, sizeVoxelV] = loadAndDownsample(fid, tmpS, sizeDoseV, optS, [], doseFileName);

                %Adjust dose coordinate variables for new downsampled matrix.
                tmpS.sizeOfDimension1 = size(tmpV, 1);
                tmpS.sizeOfDimension2 = size(tmpV, 2);
                tmpS.sizeOfDimension3 = size(tmpV, 3);

                sizeDoseV = [tmpS.sizeOfDimension1 tmpS.sizeOfDimension2 tmpS.sizeOfDimension3];

                %Find old corners of dose matrix.
                coord1Corner = (tmpS.coord1OFFirstPoint - tmpS.horizontalGridInterval/2);
                coord2Corner = (tmpS.coord2OFFirstPoint - tmpS.verticalGridInterval/2);
                coord3Corner = (tmpS.coord3OfFirstPoint - tmpS.depthGridInterval/2);

                %Save new voxel size.
                tmpS.horizontalGridInterval = sizeVoxelV(1);
                tmpS.verticalGridInterval = -sizeVoxelV(2);
                tmpS.depthGridInterval = sizeVoxelV(3);

                %Calculate x,y,z starting points, at center of corner voxels.
                tmpS.coord1OFFirstPoint = coord1Corner + tmpS.horizontalGridInterval/2;
                tmpS.coord2OFFirstPoint = coord2Corner + tmpS.verticalGridInterval/2;
                tmpS.coord3OfFirstPoint = coord3Corner + tmpS.depthGridInterval/2;
            else
                tmpV = fread(fid,'ushort=>uint16');

                %Drop any padding:
                tmpV = tmpV(1: prod(sizeDoseV));
            end

        catch
            warning(['Failed to read dose file:' doseFileName])
            zValuesV = [];
            fclose(fid);
            return

        end

        doses3M = reshape(tmpV, sizeDoseV);

        clear tmpV

        %Rows and columns are reversed, permute.
        doses3M = permute(doses3M, [2 1 3]);

        %Fill-in z-values:
        zStart = tmpS.coord3OfFirstPoint;
        zWidth = tmpS.depthGridInterval;
        zEnd   = zStart + zWidth * (sizeDoseV(3) - 1);
        zValuesV = zStart : zWidth : zEnd;


    otherwise

        error('Could not determine dose data type.')

end

%Scale
if ~isempty(tmpS.doseScale)
    doses3M = double(doses3M) * tmpS.doseScale;
end
%Check for (-)ve dose values and ask user to clip or retain
minDose = min(doses3M(:));
if minDose<0
    ButtonName = questdlg(['Minimum Dose for fractionGroupID "', tmpS.fractionGroupID , '" is Negative.'], ...
        'Negative dose?',...
        'Clip min dose to 0','Accept dose as is','Clip min dose to 0');
    if strcmpi(ButtonName,'Clip min dose to 0')
        doses3M(doses3M<0) = 0;
    else
        doses3M = doses3M + abs(minDose);
        tmpS.doseOffset = abs(minDose);   
    end
end

tmpS.doseArray = doses3M;
clear doses3M;
tmpS.zValues = zValuesV;

function [bool, doseArraySizeInMB] = isLargeDose(optS, doseDims)
%"isLargeDose"
%   Returns true if dose is larger than the threshold set in optS.  Returns
%   false if optS value does not exist or if dose is smaller.
%
bool = 0;

%Each element is a double currently, 8 bytes per.
bytesPerDoseElement = 8;

bytesPerMB = 1024*1024;

doseArraySizeInMB = prod(doseDims)*8/bytesPerMB;

if ~isfield(optS, 'doseSizeThreshold')
    return;
end

if doseArraySizeInMB > optS.doseSizeThreshold
    bool = 1;
end

function [tmpM, newVoxSize] = loadAndDownsample(fid, doseStruct, originalSize, optS, importType, doseFileName)
%"loadAndDownsample"
%   Loads the dose in and downsamples it according to values found in optS,
%   using slicewise calculations.  Original size is [nx, ny, nz].

NslicePts = prod(originalSize(1:2));

nx = originalSize(1);
ny = originalSize(2);
nz = originalSize(3);

if isfield(optS, 'downsampledVoxelSize') & strcmpi(optS.promptForNewSize, 'no')
    downsampledVoxelSize = optS.downsampledVoxelSize;
else
    hFig = promptForVoxelSize(originalSize, [doseStruct.horizontalGridInterval, -doseStruct.verticalGridInterval, doseStruct.depthGridInterval], doseFileName);
    waitfor(hFig);
    downsampledVoxelSize = promptForVoxelSize('size');
end

%Get coordinates of rows, columns of large dose.
xV = doseStruct.coord1OFFirstPoint : doseStruct.horizontalGridInterval : (doseStruct.sizeOfDimension1-1)*doseStruct.horizontalGridInterval + doseStruct.coord1OFFirstPoint;
yV = doseStruct.coord2OFFirstPoint : doseStruct.verticalGridInterval : (doseStruct.sizeOfDimension2-1)*doseStruct.verticalGridInterval + doseStruct.coord2OFFirstPoint;
zV = doseStruct.coord3OfFirstPoint : doseStruct.depthGridInterval : (doseStruct.sizeOfDimension3-1)*doseStruct.depthGridInterval + doseStruct.coord3OfFirstPoint;

%Get corners of large dose.
dim1Corner = doseStruct.coord1OFFirstPoint - doseStruct.horizontalGridInterval/2;
dim2Corner = doseStruct.coord2OFFirstPoint - doseStruct.verticalGridInterval/2;
dim3Corner = doseStruct.coord3OfFirstPoint - doseStruct.depthGridInterval/2;

%Get coordinates of rows, columns of to-be-interpolated small dose.
xInterp = dim1Corner+downsampledVoxelSize(1)/2 : downsampledVoxelSize(1) : xV(end);
yInterp = dim2Corner-downsampledVoxelSize(2)/2 : -downsampledVoxelSize(2) : yV(end);
zInterp = dim3Corner+downsampledVoxelSize(3)/2 : downsampledVoxelSize(3) : zV(end);

[xMesh, yMesh] = meshgrid(xV, yV);

tmpM = zeros(length(yInterp), length(xInterp), nz);

for i = 1:nz
    if isempty(importType)
        sliceV = fread(fid, NslicePts, 'ushort=>uint16');
        sliceV = reshape(sliceV, [nx ny]);
        sliceV = sliceV';
        tmpM(:,:,i) = interp2(xMesh, yMesh, double(sliceV), xInterp', yInterp);
    elseif strcmpi(importType,'rtog')
        doseC = textscan(fid,'%n',NslicePts,'delimiter',',');
        sliceV = doseC{1};
        sliceV = reshape(sliceV, [nx ny]);
        sliceV = sliceV';
        tmpM(:,:,i) = interp2(xMesh, yMesh, double(sliceV), xInterp', yInterp);
    elseif strcmpi(importType,'txt')
        tmpM(:,:,i) = interp2(xMesh, yMesh, fid(:,:,i), xInterp', yInterp);
    end
end
clear xMesh;
clear yMesh;

%Now iterate over slices and interpolate.
if ~isequal(zInterp,zV)
    tmpM2 = zeros(length(yInterp), length(xInterp), length(zInterp));
    sliceWidth = doseStruct.depthGridInterval;
    for i = 1:length(zInterp)
        lower = max(find(zV <= zInterp(i)));
        upper = min(find(zV >= zInterp(i)));

        %Linear combination of upper and lower slice, based on distance
        %from the new slice zValue.
        if upper ~= lower
            slice = tmpM(:,:,upper) .* (1-(zV(upper) - zInterp(i))/sliceWidth) + tmpM(:,:,lower) .* (1-(zInterp(i) - zV(lower))/sliceWidth);
        else
            slice = tmpM(:,:,upper);
        end
        tmpM2(:,:,i) = slice;
    end
    tmpM = permute(tmpM2, [2 1 3]);
    clear tmpM2;
else
    tmpM = permute(tmpM, [2 1 3]);
end

newVoxSize = downsampledVoxelSize;