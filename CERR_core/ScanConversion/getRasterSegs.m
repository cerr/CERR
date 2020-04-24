function [planC,maskM] = getRasterSegs(planC, structsV, slicesV)
%"getRasterSegs"
%   Creates raster scan format versions of the structures, based on the
%   structure contours.  Raster scan format is is a list of row mask
%   segments, for all the row segments of the structure mask.  This is
%   a memory efficient way of storing ROI masks.  3-D or 2-D masks can
%   be rapidly constructed from this information. Regions where different
%   segments overlap are taken as *holes* and set equal to zero
%   (non-members).
%
%   In planC the field planC{indexS.structures}(structureNum).rasterSegments
%   has the format:
%
%   [z value, y value, x segment start, x segment stop, x increment, slice, ...
%   row, column start, column stop, voxel thickness for that slice]
%       .
%       .
%   with one scan segment per row.
%
%   To update a selection of structures, or a selection of slices, fill the
%   structsV and slicesV field with the structure numbers and slice numbers
%   to update.  If using the slicesV field, BE SURE THAT THE SLICES SPECIFIED
%   ARE IN THE SCANSET ASSOCIATED WITH ALL STRUCTURES IN STRUCTSV. This means
%   that when using slicesV,  all structures in structsV have to be associated
%   with the same scan--the scan that slicesV relates to.
%
%By J.O.Deasy, deasy@radonc.wustl.edu
%
%LM: JOD, 22 Nov 02.
%    JOD, 08 May 03, now using voxelThickness field to store voxel thicknesses
%                    for later DVH analysis.
%    JOD, 16 Oct 03, catch case of archives which do not have voxel
%                    thicknesses computed.
%    JRA, 15 Feb 05, updated comment, modified to handle multiple scanSets.
%    JOD, 16 Jun 05, updated to utilize much faster poly fill algorithm.
%                    ALSO: changed policy to leave alone small self-intersecting contours,
%                    on theory that if they don't look bad in original planning system
%                    they are acceptable to use here.
%    DK,  13 Mar 06, reverting back to scanPoly for generating masks
%Usage:
%   function planC = getRasterSegs(planC, structsV, slicesV);
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

indexS = planC{end};

if exist('structsV','var') && isnumeric(structsV)
    %Use structsV.
else
    %Rasterize all structures.
    structsV = 1:length(planC{indexS.structures});
end

if exist('slicesV','var') && isnumeric(slicesV)
    %Use slicesV, but check to be sure that all structsV have the same
    %associatedScan.
    sliceMode = 'User';
    scanNum = unique(getStructureAssociatedScan(structsV,planC));
    if length(scanNum) > 1
        error('Cannot use slicesV argument to getRasterSegs if passed structsV do not all have the same associatedScan.');
    end
else
    %Rasterize on all slices.
    sliceMode = 'All';
end

%Loop over structures
for i = 1:length(structsV)
    structNum   = structsV(i);
    structName  = lower(planC{indexS.structures}(structNum).structureName);
    scanNum     = getStructureAssociatedScan(structNum, planC);
    if strcmpi(sliceMode, 'all')
        slicesV = 1:length(planC{indexS.scan}(scanNum).scanInfo);
    end
    
    outString   = ['Creating raster-scan representation of ' structName ' contour.'];
    %CERRStatusString(outString);
    disp(outString)
    
    %------Create 'scan formats' of the structures------------%
    
    segOptS.ROIxVoxelWidth = planC{indexS.scan}(scanNum).scanInfo(1).grid2Units;
    segOptS.ROIyVoxelWidth = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
    segOptS.ROIImageSize   = double([planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1  planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2]);
    
    %Get any offset of CT scans to apply (neg) to structures
    if ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).xOffset)
        xCTOffset = planC{indexS.scan}(scanNum).scanInfo(1).xOffset;
        yCTOffset = planC{indexS.scan}(scanNum).scanInfo(1).yOffset;
    else
        xCTOffset = 0;
        yCTOffset = 0;
    end
    
    segOptS.xCTOffset = xCTOffset;
    segOptS.yCTOffset = yCTOffset;
    
    % dummyM = zeros(segOptS.ROIImageSize);
    dummyM = false(segOptS.ROIImageSize);
    
    segmentsM = [];
    
    %Wipe out old rasterSegments for slices we are about to recalc.
    if ~isempty(planC{indexS.structures}(structNum).rasterSegments)
        toRecalc = ismember(planC{indexS.structures}(structNum).rasterSegments(:,6), slicesV);
        planC{indexS.structures}(structNum).rasterSegments(toRecalc,:) = [];
        segmentsM = planC{indexS.structures}(structNum).rasterSegments;
    end
    
    [xScanV, yScanV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    
    for j = 1:length(slicesV)
        
        slice = slicesV(j);
        
        numSegs = length(planC{indexS.structures}(structNum).contour(slice).segments);
        
        maskM = dummyM;
        % mask3M = [];
        mask3M = false([segOptS.ROIImageSize,numSegs]);
        
        % APA: added Tim's function
        for k = 1 : numSegs
            pointsM = planC{indexS.structures}(structNum).contour(slice).segments(k).points;
            if ~isempty(pointsM)
                %str4 = ['Scan converting structure ' num2str(structNum) ', slice ' num2str(slice) ', segment ' num2str(k) '.'];
                % CERRStatusString(str4)
                
                %[xScanV, yScanV, zScanV] = getScanXYZVals(planC{indexS.scan}(scanNum), slice);
                %convertedContour = convertContourToPixels_1(xScanV, yScanV, planC{indexS.structures}(structNum).contour(slice),k);
                
                [rowV, colV] = xytom(planC{indexS.structures}(structNum).contour(slice).segments(k).points(:,1), planC{indexS.structures}(structNum).contour(slice).segments(k).points(:,2), slice, planC,scanNum);
                
                if any(rowV < 1) || any(rowV > segOptS.ROIImageSize(1))
                    %if any(rowV+5 < 1) || any(rowV-5  > segOptS.ROIImageSize(1))
                    %    %warning('A row index is off the edge of image mask: these set of points will be discarded');
                    %    continue
                    %end
                    %warning('A row index is off the edge of the image mask:  automatically shifting to the edge.')
                    rowV = rowV .* ([rowV >= 1] & [rowV <= segOptS.ROIImageSize(1)]) + ...
                        [rowV > segOptS.ROIImageSize(1)] .* segOptS.ROIImageSize(1) + ...
                        [rowV < 1];
                end
                
                if any(colV < 1) || any(colV > segOptS.ROIImageSize(2))
                    %if any(colV+5 < 1) || any(colV-5  > segOptS.ROIImageSize(2))
                    %    %warning('A column index is off the edge of image mask: these set of points will be discarded');
                    %    continue
                    %end
                    %warning('A column index is off the edge of the image mask:  automatically shifting to the edge.')
                    colV = colV .* ([colV >= 1] & [colV <= segOptS.ROIImageSize(2)]) + ...
                        [colV > segOptS.ROIImageSize(2)] .* segOptS.ROIImageSize(2) + ...
                        [colV < 1];
                end
                
                %convertedContour.segments.points = [round(rowV), round(colV)];
                %convertedContour.segments.points = [(rowV), (colV)];
                maskM = uint32(polyFill(length(yScanV), length(xScanV), rowV, colV));
                if (size(pointsM,1) == 1) || (size(pointsM,1) == 2 && isequal(pointsM(1,:),pointsM(2,:)))
                    maskM(floor(rowV(1)):ceil(rowV(1)),floor(colV(1)):ceil(colV(1))) = uint32(1);
                end
                mask3M(:,:,k) = maskM;
                zValue = pointsM(1,3);
            end
        end
        % APA: added Tim's function ends
        
        if any(mask3M(:))
            
            %Combine masks
            %Add segments together:
            %Any overlap is interpreted as a 'hole'
            
            %             baseM = dummyM;
            %             for m = 1 : size(mask3M,3)
            %                 baseM = baseM + mask3M(:,:,m);  %to catalog overlaps
            %             end
            if size(mask3M,3) > 1
                baseM = sum(mask3M,3);
                maskM = baseM == 1;  %% To leave alone self-intersecting contours (eg. baseM == 2,3.. are left alone)
            else
                maskM = mask3M == 1;
            end
            
            tmpM = mask2scan(maskM, segOptS, slice);       %convert mask into scan segment format
            
            zValuesV = ones(size(tmpM,1),1) * zValue;
            
            %try    %%JOD, 16 Oct 03
            if isfield(planC{indexS.scan}(scanNum).scanInfo(slice),'voxelThickness')
                
                voxelThickness = planC{indexS.scan}(scanNum).scanInfo(slice).voxelThickness;
                
            else
                voxelThicknessV = deduceVoxelThicknesses(scanNum, planC);
                for p = 1 : length(voxelThicknessV)  %put back into planC
                    planC{indexS.scan}(scanNum).scanInfo(p).voxelThickness = voxelThicknessV(p);
                end
                voxelThickness = planC{indexS.scan}(scanNum).scanInfo(slice).voxelThickness;
            end
            thicknessV = ones(size(tmpM,1),1) * voxelThickness;
            
            segmentsM = [segmentsM; [zValuesV, tmpM, thicknessV]];
        end
    end
    planC{indexS.structures}(structNum).rasterSegments = segmentsM;
    planC{indexS.structures}(structNum).rasterized = 1;
    
    %CERRStatusString('')
    
end
