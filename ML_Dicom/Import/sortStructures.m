function structS = sortStructures(structS, isObliqScanV, planC)

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

%structS = planC{indexS.structures}(i);
%scanInd = getStructureAssociatedScan(, planC);
scanInd = getAssociatedScan(structS.assocScanUID, planC);
scanInd = scanInd(1);

zmesh   = [planC{indexS.scan}(scanInd).scanInfo.zValue];
slicethickness = diff(zmesh);
slicethickness = [slicethickness, slicethickness(end)];

ncont=length(structS.contour);
voiZ = [];
if ncont~=0 && ~(ncont==1 && isempty(structS.contour(1)))
    for nc=1:ncont
        if ~isempty(structS.contour(nc))
            if ~isempty(structS.contour(nc).segments)
                voiZ(nc)=structS.contour(nc).segments(1,3);
            else
                voiZ(nc)= NaN;
            end
        end
    end
else
    voiZ=NaN;
end
[voiZ,index]=sort(voiZ);
voiZ=dicomrt_makevertical(voiZ);
index=dicomrt_makevertical(index);
%     slice=0;

segmentTemplate = struct('points', []);
segmentTemplate(1) = [];
segmentCell = cell(length(zmesh), 1);
[segmentCell{1:end}] = deal(segmentTemplate);
contourTemplate = struct('segments', segmentCell);

% get a list of sopInstanceUIDs
sopInstanceC = {};
for slcNum = 1:length(structS.contour)
    sopInstanceC{slcNum} = structS.contour(slcNum).sopInstanceUID;
end
if ~isempty(sopInstanceC)
    sopInstanceC = sopInstanceC(index);
end

modality = planC{indexS.scan}(scanInd).scanInfo(1).imageType;

optS = opts4Exe([getCERRPath,'CERROptions.json']);
contourSliceTol = optS.contourToSliceTolerance;

for j=1:length(zmesh) % loop through the number of CT
    
    if isObliqScanV(scanInd)  % strcmpi(modality,'mr')
        % APA: use sopInstanceUID to find the matching slice for MR scan
        % sopInstanceUID = planC{indexS.scan}(scanInd).scanInfo(j).DICOMHeaders.SOPInstanceUID;
        sopInstanceUID = planC{indexS.scan}(scanInd).scanInfo(j).sopInstanceUID;
        locate_point = strmatch(sopInstanceUID,sopInstanceC);
    else    
        %locate_point=find(voiZ==zmesh(j)); % search for a match between Z-location of current CT and voiZ
        locate_point = find(abs(voiZ-zmesh(j)) < contourSliceTol);
    end

    if isempty(locate_point) && ~isObliqScanV(scanInd)  % ~strcmpi(modality,'mr')
        
        [locate_point]=find(voiZ>zmesh(j)-slicethickness(j)./2 & voiZ<zmesh(j)+slicethickness(j)./2);
        
        %             if isempty(locate_point)
        %                 voi_thickness = max(diff(voiZ));
        %                 [locate_point]=find(voiZ >= zmesh(j)-voi_thickness./2 & voiZ <= zmesh(j)+voi_thickness./2);
        %             end
        
        
        if ~isempty(locate_point)
            % if a match is found the VOI segment was defined of a
            % plane 'close' to the Z-location of the VOI
            if length(locate_point)>1
                % if this happens we have to decide i we are dealing
                % with multiple segments on the same slice or if
                % mpre segments on different slices, all 'close' to the
                % Z-location of the CT have been 'dragged' into the
                % selection.
                if find(diff(voiZ(locate_point)))
                    % different segments on different slices
                    % pick the first set. Can be coded to cpick the closest
                    % to the Z-location of CT.
                    %locate_point=locate_point(end);
                    
                    %                         listZ = voiZ(locate_point);
                    %                         uniqZ = unique(listZ);
                    %                         indZ = (listZ==uniqZ(end)); %should pick the first or others?
                    %                         locate_point = locate_point(indZ);
                    
                    segZ = 0;
                    segL = 0;
                    for m=1:length(locate_point)
                        seg = structS.contour(index(locate_point(m))).segments;
                        if (length(seg)>segL)
                            segL = length(seg);
                            segZ = seg(1,3);
                        end
                    end
                    listZ = voiZ(locate_point);
                    indZ = (listZ==segZ); %should pick the first or others?
                    locate_point = locate_point(indZ);
                end
            end
            for k=1:length(locate_point)
                %slice=slice+1;
                segment = structS.contour(index(locate_point(k))).segments;
                segment(:,3) = zmesh(j);
                contourTemplate(j).segments(end+1).points = segment;
            end
        else %can not find contours in current slice, try larger radius.
            
        end
    elseif ~isempty(locate_point)
        % if match is found it's because this segment(s) of the VOI was(were) defined at the Z-location
        % of the current CT
        for k=1:length(locate_point)
            % store all the segments with the Z location of the current CT.
            %                 slice=slice+1;
            segment = structS.contour(index(locate_point(k))).segments;
            segment(:,3) = zmesh(j);
            contourTemplate(j).segments(end+1).points = segment;
        end
    end
    clear locate_point;
end

structS.contour = contourTemplate;
structS.associatedScan = scanInd;

