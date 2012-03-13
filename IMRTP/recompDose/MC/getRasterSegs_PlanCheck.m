function planC = getRasterSegs(planC, structsV, slicesV)
%"getRasterSegs"
%   Creates raster scan format versions of the structures, based on the
%   structure contours.  Raster scan format is is a list of row mask
%   segments, for all the row segments of the structure mask.  This is
%   a memory efficient way of storing ROI masks.  3-D or 2-D masks can
%   be rapidly constructed from this information. Regions where different
%   segments overlap are taken as *holes* and set equal to zero (non-members).
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
%
%Usage:
%   function planC = getRasterSegs(planC, structsV, slicesV);

indexS = planC{end};

if exist('structsV') & isnumeric(structsV)
    %Use structsV.
else
    %Rasterize all structures.
    structsV = 1:length(planC{indexS.structures});
end

if exist('slicesV') & isnumeric(slicesV)
    %Use slicesV, but check to be sure that all structsV have the same
    %associatedScan.
    sliceMode = 'User';
    uniqueScans = unique(getStructureAssociatedScan(structsV));
    if length(uniqueScans) > 1
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
    CERRStatusString(outString);

    %------Create 'scan formats' of the structures------------%
    numSlices   = length(planC{indexS.scan}(scanNum).scanInfo);

    segOptS.ROIxVoxelWidth = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
    segOptS.ROIyVoxelWidth = planC{indexS.scan}(scanNum).scanInfo(1).grid2Units;
    segOptS.ROIImageSize   = [planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1  planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2];

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

    dummyM = zeros(segOptS.ROIImageSize);

    segmentsM = [];

    %Wipe out old rasterSegments for slices we are about to recalc.
    if ~isempty(planC{indexS.structures}(structNum).rasterSegments)
        toRecalc = ismember(planC{indexS.structures}(structNum).rasterSegments(:,6), slicesV);
        planC{indexS.structures}(structNum).rasterSegments(toRecalc,:) = [];
        segmentsM = planC{indexS.structures}(structNum).rasterSegments;
    end

    for j = 1:length(slicesV)
        slice = slicesV(j);

        numSegs = length(planC{indexS.structures}(structNum).contour(slice).segments);

        maskM = dummyM;
        mask3M = [];

        for k = 1 : numSegs

            pointsM = planC{indexS.structures}(structNum).contour(slice).segments(k).points;

            if ~isempty(pointsM)

                %Removes duplicate consecutive points.
                goodPtsV = [1;any(diff(pointsM),2)];
                pointsM = pointsM(find(goodPtsV), :);

                if size(pointsM, 1) < 4
                    warning('A segment has less than 3 vertices.  Ignoring.');
                    maskM = dummyM;
                else
                    str4 = ['Scan converting structure ' num2str(structNum) ', slice ' num2str(slice) ', segment ' num2str(k) '.'];
                    CERRStatusString(str4)
                    %[edgeM] = poly2Edges(pointsM(:,1:2),segOptS);  %convert from polygon to edge format
                    %[edge2M, flag2] = repairContour(edgeM, segOptS); %excision repair of self-intersecting contours
                    %if isempty(edge2M)
                    %    warning('A segment consists entirely of self-intersecting edges.  Ignoring.');
                    %    mask3M(:,:,k) = dummyM;
                    %    continue;
                    %end
                    [maskM] = fastPolyFill(pointsM(:,1:2), segOptS);    %convert edge information into zero-one mask
                                                                %new algorithm, June 05.
                end
                zValue = pointsM(1,3);
                mask3M(:,:,k) = maskM;
            end
        end

        if ~isempty(mask3M)

            %Combine masks
            %Add segments together:
            %Any overlap is interpreted as a 'hole'

            baseM = dummyM;
            for m = 1 : size(mask3M,3)
                baseM = baseM + mask3M(:,:,m);  %to catalog overlaps
            end

            maskM = [baseM == 1];

            tmpM = mask2scan(maskM, segOptS, slice);       %convert mask into scan segment format

            len = size(tmpM,1);

            zValuesV = ones(size(tmpM,1),1) * zValue;

            numSlices = length(planC{indexS.scan}(scanNum).scanInfo);

            try    %%JOD, 16 Oct 03

                voxelThickness = planC{indexS.scan}(scanNum).scanInfo(slice).voxelThickness;

            catch

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

    CERRStatusString('')

end
