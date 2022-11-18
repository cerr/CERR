function [data3M, infoS] = nrrd_read(fileName)
% function [data3M, infoS] = nrrd_read(fileName)
%
% Returns the scan matrix and the mha-like infoS data structure from the
% passed .nrrd file
%
% Examlpe usage:
% fileName = 'P:\to\file\brain_image.nrrd';
% [data3M, infoS] = nrrd_read(fileName);
% datamin = min(data3M(:));
% movScanOffset = 0;
% if datamin < 0
%     movScanOffset = -datamin;
% end
% movScanName = 'CT';
% 
% if ~exist('planC','var')
%     planC = initializeCERR;
% end
% 
% indexS = planC{end};
% save_flag = 1;
% planC  = mha2cerr(infoS,data3M,movScanOffset,movScanName, planC, save_flag);

% read nrrd file
[data3M,infoS] = nrrdread_opensrc(fileName);


% Get the scan dimension
[numRows,numCols] = strtok(infoS.sizes,' ');
[numCols,numSlcs] = strtok(numCols,' ');
numRows = str2double(numRows);
numCols = str2double(numCols);
numSlcs = str2double(numSlcs);


% Get the origin
[xOrigin,yOrigin] = strtok(infoS.spaceorigin(2:end),',');
xOrigin = str2double(xOrigin);
[yOrigin,zOrigin] = strtok(yOrigin(2:end),',');
yOrigin = str2double(yOrigin);
zOrigin = strtok(zOrigin(2:end),')');
zOrigin = str2double(zOrigin);


% Get the voxel spacing

[xStr, remStr] = strtok(infoS.spacedirections,'(');
[yStr, remStr] = strtok(remStr,'(');
zStr = remStr;

dx = strtok(xStr,',');
dx = abs(str2double(dx));

[~,yStr] = strtok(yStr,',');
dy = strtok(yStr,',');
dy = abs(str2double(dy));

[~,zStr] = strtok(zStr,',');
[~,zStr] = strtok(zStr,',');
dz = strtok(zStr(2:end),')');
dz = abs(str2double(dz));


infoS.Dimensions = [numCols, numRows, numSlcs];

infoS.Offset = [xOrigin, yOrigin, zOrigin];

infoS.PixelDimensions = [dx, dy, dz];

%data3M = permute(data3M,[2,1,3]);

