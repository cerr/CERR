function planC = dcmdir2planC(dcmdir)
%"dcmdir2planC"
%   Convert a dcmdir object representing a patient into a planC.
%
%JRA 06/15/06
%YWU 03/01/08
%
%Usage:
%   planC = dcmdir2planC(dcmdir);
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

planInitC = initializeCERR;
       
indexS = planInitC{end};

%Assume a single patient for the moment
dcmdir_PATIENT = dcmdir; %wy .PATIENT{1};

%Get the names of all cells in planC.
cellNames = fields(indexS);

for i = 1:length(cellNames)
   %Populate each field in the planC.
   disp([' Reading ' cellNames{i}  ' ... ']);
   cellData = populate_planC_field(cellNames{i}, dcmdir_PATIENT);
   
   if ~isempty(cellData)
       planInitC{indexS.(cellNames{i})} = cellData;
   end
end

planC = planInitC;
planC = guessPlanUID(planC,1);
%After initial import, run any functions to address issues where
%subfunctions had insufficent data to make relationship determinations.

%process doseOffset
for doseNum = 1:length(planC{indexS.dose})
    if min(planC{indexS.dose}(doseNum).doseArray(:)) < 0
        planC{indexS.dose}(doseNum).doseOffset = -min(planC{indexS.dose}(doseNum).doseArray(:));
        planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray + planC{indexS.dose}(doseNum).doseOffset;
    else
        planC{indexS.dose}(doseNum).doseOffset = [];
    end
end

% process scan zValues for US
try
    if isempty(planC{3}.scanInfo(1).zValue)
        if strcmpi(planC{3}.scanInfo(1).imageType, 'US')
            if ~isempty(planC{8})
                zValues = planC{8}.zValues;
                for i=1:length(planC{3}.scanInfo)
                   planC{3}.scanInfo(i).zValue = zValues(i); 
                end
            end
        end
    end
catch
end

% process scan zValues for MR, by Deshan Yang, 3/2/2010
try
	if strcmpi(planC{indexS.scan}.scanInfo(1).imageType, 'MR')
		% First, set the scan to a fake coordinate system
		info1 = planC{indexS.scan}.scanInfo(1);
		info2 = planC{indexS.scan}.scanInfo(2);
		pos1 = [info1.xOffset info1.yOffset info1.zValue];
		pos2 = [info2.xOffset info2.yOffset info2.zValue];
		deltaPos = pos2-pos1;
		slice_distance = sqrt(sum(deltaPos.^2));
		for i=1:length(planC{indexS.scan}.scanInfo)
			planC{indexS.scan}.scanInfo(i).zValue = pos1(3)+(i-1)*slice_distance;
		end
		
		info1b = info1.DICOMHeaders;
		info2b = info2.DICOMHeaders;
		pos1b = info1b.ImagePositionPatient;
		pos2b = info2b.ImagePositionPatient;
		deltaPosb = pos2b-pos1b;
		
		positionMatrix = [reshape(info1b.ImageOrientationPatient,[3 2])*diag(info1b.PixelSpacing) [deltaPosb(1) pos1b(1);deltaPosb(2) pos1b(2); deltaPosb(3) pos1b(3)]];
		positionMatrix = positionMatrix / 10; % mm to cm
		positionMatrix = [positionMatrix; 0 0 0 1];
		
		positionMatrixInv = inv(positionMatrix);
		planC{3}.Image2PhysicalTransM = positionMatrix;
		
		[xs,ys,zs]=getScanXYZVals(planC{3});
		dx = xs(2)-xs(1);
		dy = ys(2)-ys(1);
		nx = length(xs);
		ny = length(ys);
		virPosMtx = [dx 0 0 xs(1);0 dy 0 ys(1); 0 0 slice_distance zs(1); 0 0 0 1];
		planC{3}.Image2VirtualPhysicalTransM = virPosMtx;

		N = length(planC{indexS.structures});
		if N>0
			% Now, translate the contour points to the same coordinate system
			for nvoi = 1:N
				% for each structure
				M = length(planC{indexS.structures}(nvoi).contour);
				for sliceno = 1:M
					% for each contour
					points = planC{indexS.structures}(nvoi).contour(sliceno).segments;
					% y and z are inverted, now get the original data back
					points(:,2:3) = -points(:,2:3);
					
					if ~isempty(points)
						tempa = [points ones(size(points,1),1)];
						tempa = positionMatrixInv*tempa';
						tempa(3,:) = round(tempa(3,:)); % round the voi points onto the slice

						tempb = virPosMtx*tempa;
						tempb = tempb';

						planC{indexS.structures}(nvoi).contour(sliceno).segments = tempb(:,1:3);
					end
				end
			end
		end
		
		N = length(planC{indexS.dose});
		if N > 0
			% Now, translate the coordinates for dose
			for doseno = 1:N
				dose = planC{indexS.dose}(doseno);
				if ~isfield(dose,'DICOMHeaders')
					continue;
				end
				
				info = dose.DICOMHeaders;

				vec1 = info.ImageOrientationPatient(1:3);
				vec2 = info.ImageOrientationPatient(4:6);
				vec3 = cross(vec1,vec2);
				vec3 = vec3 * (info.GridFrameOffsetVector(2)-info.GridFrameOffsetVector(1));
				pos1 = info.ImagePositionPatient;
				
				% positionMatrix translate voxel indexes to physical
				% coordinates
				dosePositionMatrix = [reshape(info.ImageOrientationPatient,[3 2])*diag(info.PixelSpacing) [vec3(1) pos1(1);vec3(2) pos1(2); vec3(3) pos1(3)]];
				dosePositionMatrix = [dosePositionMatrix; 0 0 0 1];
				
				dosedim = size(dose.doseArray);
				
				% Need to figure out coord1OFFirstPoint,
				% coord2OFFirstPoint, horizontalGridInterval,
				% verticalGridInterval and zValues
				
% 				xOffset = iPP(1) + (pixspac(1) * (nCols - 1) / 2);
% 				yOffset = iPP(2) + (pixspac(2) * (nRows - 1) / 2);
				
				vecs = [0 0 0 1; 1 1 0 1; (dosedim(2)-1)/2 (dosedim(1)-1)/2 0 1];
				vecsout = (dosePositionMatrix*vecs'); % to physical coordinates
				vecsout(1:3,:) = vecsout(1:3,:)/10;
				vecsout = inv(positionMatrix) * vecsout;  % to MR image index (not dose voxel index)
				vecsout = virPosMtx * vecsout; % to the virtual coordinates 
				
% 				dose.coord1OFFirstPoint = vecsout(1,3);
% 				dose.coord2OFFirstPoint = vecsout(2,3);
				dose.coord1OFFirstPoint = vecsout(1,1);
				dose.coord2OFFirstPoint = vecsout(2,1);
				dose.horizontalGridInterval = vecsout(1,2) - vecsout(1,1);
				dose.verticalGridInterval = vecsout(2,2) - vecsout(2,1);
				
				vecs = [zeros(2,dosedim(3));0:(dosedim(3)-1);ones(1,dosedim(3))];
				vecsout = (dosePositionMatrix*vecs); % to physical coordinates
				vecsout(1:3,:) = vecsout(1:3,:)/10;
				vecsout = inv(positionMatrix) * vecsout;  % to MR image index (not dose voxel index)
				vecsout = virPosMtx * vecsout; % to the virtual coordinates 
				
				dose.zValues = vecsout(3,:)';
				
				planC{indexS.dose}(doseno) = dose;
			end
		end
		
	end
catch
end
% end of changes by Deshan Yang


scanNum = length(planC{3});
if (scanNum>1)
    button = questdlg(['There are ' num2str(scanNum) 'scans, do you want to put them together?'],'Merge CT in 4D Series', ...
            'Yes', 'No', 'default');
    switch lower(button)
        case 'yes'
            %sort the all scan series
            if (planC{3}(1).scanInfo(2).zValue > planC{3}(1).scanInfo(1).zValue)
                sortingMode = 'ascend';
            else
                sortingMode = 'descend';
            end
            
            zV = zeros(1, scanNum);
            for i=1:scanNum
                zV(i) = planC{3}(i).scanInfo(1).zValue;
            end
            [B,Ind] = sort(zV, 2, sortingMode);
            
            %add all scans to the first one.
            scanArray = []; scanInfo = [];
            for i=1:scanNum
                scanArray = cat(3, scanArray, planC{3}(Ind(i)).scanArray);
                scanInfo = cat(2, scanInfo, planC{3}(Ind(i)).scanInfo);
            end
            
            %delete all other scans
            planC{3} = planC{3}(1); 
            planC{3}.scanArray = scanArray;
            planC{3}.scanInfo = scanInfo;
            
            %associate all structures to the first scanset.
            strNum = length(planC{4});
            for i=1:strNum
                planC{4}(i).assocScanUID = planC{3}(1).scanUID;
            end
                        
        case 'no'
                    
    end
end

%Sort contours for each structure to match the associated scan.
for i=1:length(planC{indexS.structures})
    structure = planC{indexS.structures}(i);   
    scanInd = getStructureAssociatedScan(i, planC);    
    
    zmesh   = [planC{indexS.scan}(scanInd).scanInfo.zValue];
    slicethickness = diff(zmesh); 
    slicethickness = [slicethickness, slicethickness(end)];
    
    ncont=length(structure.contour);
    voiZ = [];
    if ncont~=0 && ~(ncont==1 && isempty(structure.contour(1)))
        for nc=1:ncont
            if ~isempty(structure.contour(nc))
                if ~isempty(structure.contour(nc).segments)
                    voiZ(nc)=structure.contour(nc).segments(1,3);
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
    
    for j=1:length(zmesh) % loop through the number of CT
        locate_point=find(voiZ==zmesh(j)); % search for a match between Z-location of current CT and voiZ
        if isempty(locate_point)

            [locate_point]=find(voiZ>zmesh(j)-slicethickness(j)./2 & voiZ<zmesh(j)+slicethickness(j)./2);
            
            if isempty(locate_point)
                voi_thickness = max(diff(voiZ));
                [locate_point]=find(voiZ >= zmesh(j)-voi_thickness./2 & voiZ <= zmesh(j)+voi_thickness./2);
            end
            
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
                            seg = structure.contour(index(locate_point(m))).segments;
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
                    segment = structure.contour(index(locate_point(k))).segments;
                    segment(:,3) = zmesh(j);
                    contourTemplate(j).segments(end+1).points = segment;
                end
            else %can not find contours in current slice, try larger radius.
                                
            end
        else
            % if match is found it's because this segment(s) of the VOI was(were) defined at the Z-location 
            % of the current CT
            for k=1:length(locate_point)
                % store all the segments with the Z location of the current CT.
%                 slice=slice+1;
                segment = structure.contour(index(locate_point(k))).segments;
                segment(:,3) = zmesh(j);
                contourTemplate(j).segments(end+1).points = segment;
            end
        end
        clear locate_point;
    end

    planC{indexS.structures}(i).contour = contourTemplate;
    planC{indexS.structures}(i).associatedScan = scanInd;
    
end

%TEMPORARY.
% for i=1:length(planC{indexS.dose})
%    planC{indexS.dose}(i).assocScanUID = planC{indexS.scan}(1).scanUID; 
% end

planC = getRasterSegs(planC);
planC = setUniformizedData(planC);

