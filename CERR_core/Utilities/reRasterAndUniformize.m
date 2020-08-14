function planC = reRasterAndUniformize(planC,scanNumV)
%reRasterAndUniformize.m
%script to delete all existing rasterSegments and re-uniformize the plan
%
%APA, 12/22/2006
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

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

if ~exist('scanNumV','var')
    scanNumV = 1:length(indexS.scan);
end

for scanNum = scanNumV
    planC{indexS.scan}(scanNum).uniformScanInfo         = [];
    planC{indexS.scan}(scanNum).scanArraySuperior       = [];
    planC{indexS.scan}(scanNum).scanArrayInferior       = [];
    planC{indexS.structureArray}(scanNum).indicesArray  = [];
    planC{indexS.structureArray}(scanNum).bitsArray     = [];
    planC{indexS.structureArrayMore}(scanNum).indicesArray  = [];
    planC{indexS.structureArrayMore}(scanNum).bitsArray     = [];    
end

%Read CERROptions.json to get import flags
pathStr = getCERRPath;
optName = fullfile(pathStr,'CERROptions.json');
optS    = opts4Exe(optName);
planC{indexS.CERROptions} = optS;

numStructs = length(planC{indexS.structures});
assocScanV = getStructureAssociatedScan(1:numStructs,planC);
strIndV = find(ismember(assocScanV,scanNumV));
%re-generate raster segments
if ~isempty(strIndV)
    [planC{indexS.structures}(strIndV).rasterized] = deal(0);
    planC = getRasterSegs(planC,strIndV);
end

%uniformize
planC = setUniformizedData(planC,[],scanNumV);
