function IM = updateQIBInfluence(IM, structROIV, sampleRateV,updateM)
%"generateQIBInfluence"
%   Uses the QIB engine to populate the beamlet fields of an IM structure.
%   StructROIV is the list of structures, sampleRateV is a vector of sample
%   rates, one for each structROIV.
%   The doses are stored in sparse format.
%   The stored index is with respect to the structure mask registered to the
%   uniformized CT scan.
%
%   This code was broken out of a function by JOD and CZ.
%
%JRA  26 Aug 2004
%LM:  14 Sept 05, JOD, fixed bug in call to mtoxyz
%     17 Dec  05, JOD, fixed bug in un-downsampled ROI
%                      definition; added comments to clarify calculation, and a small speedup change.
%     05 Jul  06, JJW, added missing inverse square law; added sigma_100
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


%-----------Generate influence matrices---------------------%
%Loop over structures (i.e. goal terms)

global planC
global stateS
indexS = planC{end};

%obtain associated scanNum for structures. It is assumed that all the
%structures are associated to same scan (which is checked in IMRTP.m)
scanNum = getStructureAssociatedScan(structROIV(1));

for i = 1 : length(structROIV)

    if ~any(updateM(i,:))
        continue
    end
    
    if sampleRateV(i) ~= 1

        %Ensures that interpolative downsampling won't miss edge points:
        maskSingle3D = getSurfaceExpand(structROIV(i),0.5,1);
        if rem(log2(sampleRateV(i)),1) ~= 0
            error('Sample factor must (currently) be a power of 2.')
        end
        maskSample3D = getDown3Mask(maskSingle3D, sampleRateV(i), 1);
        %Get a mask of where to sample points
        tmp = logical(maskSample3D) & maskSingle3D;
        clear maskSample3D maskSingle3D;

    else

        tmp = getUniformStr(structROIV(i));

    end

    scanIndV = find(tmp(:));  %Indices with respect to the uniformized scan.
    [rowV, colV, sliceV] = find3d(tmp); clear tmp;     %returns locations of mask voxels

    %[xV,yV,zV] = mtoxyz(rowV,colV,sliceV,1,planC,'uniform'); change by
    %JOD.
    [xV,yV,zV] = mtoxyz(rowV,colV,sliceV,scanNum,planC,'uniform');

    doseV = zeros(size(xV));

    numPts = length(xV);

    pM = [xV(:),yV(:),zV(:)];   %Location of dose calc points, downsampled.

%     PBCounter = 1;

    QIBDataS = loadPBData;

    %for j = 1 : length(IM.beams)	
    beamIndV = find(updateM(i,:));
    for j = beamIndV

        disp(['Compute doses to structure number ' num2str(structROIV(i)) ' for beam ' num2str(j) '.'])

        %Get beamlet data for this beam and this structure

        sourceM = repmat([IM.beams(j).x, IM.beams(j).y, IM.beams(j).z],numPts,1);

        pRelM = pM - sourceM;    %get relative vector direction from source to dose calc points.

        RTOGPBVectorsM = IM.beams(j).RTOGPBVectorsM;

        str = int2str(size(RTOGPBVectorsM,1));

        disp(['numPBs = ' str])


        PBM = [];
        for PBNum = 1 : size(RTOGPBVectorsM,1)

            if mod(PBNum, 25) == 0 | (PBNum == size(RTOGPBVectorsM,1))
                disp(['Computed ' int2str(PBNum) ' out of ' str]); pause(0.003);
                try
                    IMRTPGui('status', j, length(beamIndV), structROIV(i), PBNum, size(RTOGPBVectorsM,1));
                end
            end

            PBV = RTOGPBVectorsM(PBNum,:);

            distSamplePts = IM.beams(j).CTTraceS(PBNum).distSamplePts;
            cumDensity    = IM.beams(j).CTTraceS(PBNum).cumDensityRay;

            distV = pRelM * PBV';    %Each row is the dot product of (the un-normalized) source-to-calc point
            %direction and the PB unit vector.
            %Hence, this is the distance along the PB ray line for each dose calc point.

            qM = sourceM + distV * PBV;  %The last term gives the vector i, j, and k components of
            %distance to the depth of closest approach.
            %Each row of sourceM is the i,j,k position of the source.
            %So vector sum locates the positions of closest approach
            %to the dose calc points.

            rM  = pM - qM;    %Each row of pM is the x, y, z location of a dose calc point.
            %rM is then the vector pointing from the dose calc point to the point
            %at which the PB vector makes closest approach.

            %Trap points which are too far away to need dose calcs
            %Uses sepsq if possible, much faster.
            try
                rDistVSquared = sepsq([0 0 0]', rM');  %mex file speedup
                goV = rDistVSquared < (IM.params.cutoffDistance^2);
            catch
                rDistV = (rM(:,1).^2 + rM(:,2).^2 + rM(:,3).^2);    %if mex not there
                goV = rDistV < IM.params.cutoffDistance^2;         %Mod by JOD to speedup, Dec 05.
            end

            rGoM = rM(goV,:);
            %       rGoDistV = rDistV(goV);
            distGoV = distV(goV);

            %We ignore the slight tilt of PB cross-sections with respect to the longitudinal axis.

            [gantryVectorsM] = RTOGVectors2Gantry(rGoM, IM.beams(j).gantryAngle);
            Xb = gantryVectorsM(:,1);
            Yb = gantryVectorsM(:,2);

            tmpV=clip(distGoV,0.001,max(distSamplePts) - 0.001,'limits');

            %get cum density at that point
            radDepthV = interp1([0, distSamplePts],[0, cumDensity],tmpV);

            %Get the widths of the PBs at that distance
            PBWidth_YbV = IM.beams(j).beamletDelta_y(1) * distGoV/IM.beams(j).isodistance; %This is the width 'out-of-plane'
            PBWidth_XbV = IM.beams(j).beamletDelta_x(1) * distGoV/IM.beams(j).isodistance; %This is the width 'in-plane'

            %compute dose using QIB
            [A_zV, a_zV, B_zV, b_zV] = GetPBConsts(radDepthV, IM.beams(j).beamEnergy, QIBDataS, 'nearest');

            doseFlag = IM.params.DoseTerm;

            sigmaVal_100 = IM.beams(j).sigma_100;

            doseV = getQIBDose([Xb,Yb], radDepthV, PBWidth_XbV, PBWidth_YbV, ...
                QIBDataS, A_zV, a_zV, B_zV, b_zV, IM.beams(j).beamEnergy, doseFlag, sigmaVal_100, distGoV);

            % apply inverse square law:
            % (divide by depth dependent area of beamlet scaled to isocenter distance)
            doseV = IM.beams(j).beamletDelta_x(1) * IM.beams(j).beamletDelta_y(1) * doseV ./ (PBWidth_XbV .* PBWidth_YbV);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %This function selectively eliminates some scatter components, if invoked.
            doseV = applyIMRTCompression(IM.params, doseV);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %-----------Construct the dose matrix---------------------%

            indNZV = [doseV == 0];
            whereV = goV;     %First trap on distance
            ind0V = find(whereV);
            whereV(ind0V(indNZV)) = 0;    %zero out indices where dose was not computed from within QIB routine.
            [indV] = find(whereV);        %indV returns locations where dose is non-zero.
            doseV(indNZV) = [];           %eliminate dose entries which were zero.

            beamlet = createIMBeamlet(doseV, scanIndV(indV), j, length(goV));

            if ~isfield(IM.beams(j),'beamlets') || isempty(IM.beams(j).beamlets)
                IM.beams(j).beamlets = beamlet;
            else
                IM.beams(j).beamlets(i,PBNum) = beamlet;
            end            
            IM.beams(j).beamlets(i,PBNum).structureName = planC{indexS.structures}(structROIV(i)).structureName;
            IM.beams(j).beamlets(i,PBNum).sampleRate = sampleRateV(i);
            IM.beams(j).beamlets(i,PBNum).strUID = planC{indexS.structures}(structROIV(i)).strUID;
            %IM.beams(j).beamlets(i,PBNum).IMbeamUID = IM.beams(j).IMbeamUID;            

%             PBCounter = PBCounter + 1;
        end

    end

    clear xV yV zV sourceM pM pRelM qM rM rDistV rGoM rowV sliceV;

end
