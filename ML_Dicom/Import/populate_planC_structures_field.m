function dataS = populate_planC_structures_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_RTSTRUCTS, scanOriS, attr, ssObj, cObj, optS)
%"populate_planC_structures_field"
%   Given the name of a child field to planC{indexS.structures}, populates that
%   field based on the data contained in dcmdir.PATIENT.STUDY.SERIES.RTSTRUCTS
%   structure passed in, for structure number structNum.
%
%JRA 07/12/06
%YWU Modified 03/01/08
%DK 04/12/09
%   Fixed Coordinate System
%NAV 07/19/16 updated to dcm4che3
%       replaced dcm2ml_Element with getTagValue
%       replaced "get" with "getValue", and 
%       "countItems" with "size()"
%
%Usage:
%   dataS = populate_planC_structures_field(fieldname,dcmdir_PATIENT_STUDY_SERIES_RTSTRUCTS);
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



%For easier handling
%global xOffset yOffset;

%STRUCTS = dcmdir_PATIENT_STUDY_SERIES_RTSTRUCTS;

%Default value for undefined fields.
dataS = '';

% if ~exist('attr', 'var')
%     %Grab the dicom object representing the structures.
%     attr = scanfile_mldcm(STRUCTS.file);
% end
% 
% %Structure Set ROI Sequence
% %SSRS = attr.getValue(hex2dec('30060020'));
% SSRS = attr.getValue(org.dcm4che3.data.Tag.StructureSetROISequence);
% 
% %ROI Contour Sequence
% %RCS = attr.getValue(hex2dec('30060039'));
% RCS = attr.getValue(org.dcm4che3.data.Tag.ROIContourSequence);

% %Count em up.
% 
% if ~isempty(RCS)
%     nStructs = RCS.size();
% else
%     nStructs = 0;
% end
% %Structure Set item for this structure.
% ssObj = SSRS.get(structNum - 1);
% %ssObj = org.dcm4che3.data.Attributes(SSRS)
% %ROI Number
% %ROINumber = getTagValue(ssObj, '30060022');
% ROINumber = ssObj.getInts(org.dcm4che3.data.Tag.ROINumber); % vr=IS
% 
% %Find the contour object for this structure.
% for s=1:nStructs
%     cObj = RCS.get(s - 1);
% 
%     %Referenced ROI Number
%     %RRN = getTagValue(cObj, '30060084');
%     RRN = cObj.getInts(org.dcm4che3.data.Tag.ReferencedROINumber); %IS    
% 
%     if RRN == ROINumber
%         %We found the correct contour for this structure.
%         break;
%     end
% 
% end

switch fieldname

    case 'imageNumber'
        %Currently not implemented

    case 'imageType'
        dataS = 'STRUCTURE';

    case 'caseNumber'
        %Currently not implemented
        
    case 'roiNumber'
        %dataS = ROINumber;
        dataS = ssObj.getInts(805699618); %org.dcm4che3.data.Tag.ROINumber;

    case 'patientName'
        %Patient's Name
        %nameS = getTagValue(attr, '00100010');
        %dataS = [nameS.FamilyName '^' nameS.GivenName '^' nameS.MiddleName];
        nameObj = javaObject('org.dcm4che3.data.PersonName',attr.getString(1048592)); %org.dcm4che3.data.Tag.PatientName;
        compFamilyName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','FamilyName');
        compGivenName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','GivenName');
        compMiddleName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','MiddleName');       
        dataS = [char(nameObj.get(compFamilyName)), '^',...
            char(nameObj.get(compGivenName)), '^',...
            char(nameObj.get(compMiddleName))];        

    case 'structureName'
        %ROI Name
        %dataS = getTagValue(ssObj, '30060026');
        dataS = char(ssObj.getString(805699622,0)); %org.dcm4che3.data.Tag.ROIName;

    case 'numberRepresentation'
        %Artifact of RTOG field names, not representative of CERR data.
        dataS = 'CHARACTER';

    case 'structureFormat'
        dataS = 'SCAN-BASED';
        
    case 'structSetSopInstanceUID'
        %dataS = getTagValue(attr, '00080018');
        dataS = char(attr.getString(524312,0)); %org.dcm4che3.data.Tag.SOPInstanceUID;

    case 'numberOfScans' %aka # of CT slices
        %Referenced Frame of Reference Sequence
        %RFRS = attr.getValue(hex2dec('30060010'));
        %RFRS = attr.getValue(org.dcm4che3.data.Tag.ReferencedFrameOfReferenceSequence);

        %Frame of Reference UID
        %FORUID = getTagValue(ssObj, '30060024');
        %FORUID = char(attr.getStrings(org.dcm4che3.data.Tag.ReferencedFrameOfReferenceUID));

        %Find the series referenced by these contours.  See bottom of file.
        %RSS = getReferencedSeriesSequence(RFRS, FORUID);

        %dataS = getTagValue(RSS,hex2dec('30060016')); % check this
        contourSeq = cObj.getValue(805699648); %org.dcm4che3.data.Tag.ContourSequence;
        if ~isempty(contourSeq)
            dataS = contourSeq.size();
        end

%         %Convert to ML structure format.
%         RSSML = getTagStruct(RSS);
% 
%         if ~isempty(RSSML) && ~isempty(RSSML.ContourImageSequence)
%             %# slices in this series.
%             dataS = length(fields(RSSML.ContourImageSequence));
%         else
%             dataS = '';
%         end


    case 'maximumNumberScans'
        %Currently not implemented

    case 'maximumPointsPerSegment'
        %Currently not implemented

    case 'maximumSegmentsPerScan'
        %Currently not implemented

    case 'structureEdition'
        %Currently not implemented

    case 'unitNumber'
        %Currently not implemented

    case 'writer'
        %Manufacturer
        %dataS = getTagValue(attr, '00080070');
        dataS = char(attr.getString(524400,0)); %org.dcm4che3.data.Tag.Manufacturer;

    case 'dateWritten'
        %Structure Set Date.
        %dataS = getTagValue(attr, '30060008');
        dataS = char(attr.getString(805699592,0)); %org.dcm4che3.data.Tag.StructureSetDate;

    case 'structureColor'
        %Currently not implemented

    case 'structureDescription'
        dataS = char(attr.getString(528446,0)); % series description
        
    case 'roiGenerationAlgorithm'
        dataS = char(attr.getString(805699638,0)); %dataS = getTagValue(ssObj, '30060036');
        
    case 'roiGenerationDescription'
        dataS = char(attr.getString(805699640,0)); %dataS = getTagValue(ssObj, '30060038');

    case 'studyNumberOfOrigin'
        %Currently not implemented

    case 'contour'
        %Contour Sequence
        if ~cObj.contains(805699648) %org.dcm4che3.data.Tag.ContourSequence %hex2dec('30060040')
            return;
        end
        % cSeq = cObj.getValue(hex2dec('30060040'));            
        cSeq = cObj.getValue(805699648); %org.dcm4che3.data.Tag.ContourSequence;

        if cSeq.isEmpty
            return;
        end
        
        nContours = cSeq.size();
        
        %optS = opts4Exe([getCERRPath,'CERROptions.json']);
        %contourSliceTol = optS.contourToSliceTolerance;
        
        for c = 1:nContours
            aContour = cSeq.get(c-1);
            
            % Referenced SOP instance UID
            % refSeq = aContour.getValue(hex2dec('30060016'));
            refSeq = aContour.getValue(805699606); %org.dcm4che3.data.Tag.ContourImageSequence;
            sopInstanceUID = '';
            sopClassUID = '';
            if ~isempty(refSeq)
                % sopInstanceUID = getTagValue(refSeq.get(0), '00081155');
                sopInstanceUID = char(refSeq.get(0).getString(528725,0)); %org.dcm4che3.data.Tag.ReferencedSOPInstanceUID;
                sopClassUID = char(refSeq.get(0).getString(528720,0)); %SOPClassUID
            end
            
            dataS(c).sopInstanceUID = sopInstanceUID;
            dataS(c).sopClassUID = sopClassUID;
            
            %Contour Geometric Type
            %geoType = getTagValue(aContour, '30060042');
            geoType = char(aContour.getString(805699650,0)); %org.dcm4che3.data.Tag.ContourGeometricType;

            switch upper(geoType)
                case 'POINT'
                    warning('Single point contour.');
                case 'OPEN_PLANAR'
                    warning('Open planar contours.')
                case 'OPEN_NONPLANAR'
                    warning('Open, non-planar contours.')
                case 'CLOSED_PLANAR'
                    %Great, continue.
            end

            %Number of Contour Points
            %nPoints = getTagValue(aContour, '30060046');
            nPoints = aContour.getInts(805699654); %org.dcm4che3.data.Tag.NumberOfContourPoints;
            if isempty(nPoints)
                nPoints = 0;
            end
            %             if ~(nPoints > 1)
            %                 dataS(i).segments = [];
            %                 continue;
            %             end

            %Contour Data
            try
                %data    = getTagValue(aContour, '30060050');
                data    = aContour.getDoubles(805699664); %org.dcm4che3.data.Tag.ContourData;
            catch
                disp('vacant contour found ...');
                dataS(c).segments = [];
                continue;
            end
            %Reshape Contour Data
            data    = reshape(data, [3 nPoints])';

            %data(:,3) = -data(:,3); %Z is always negative to match RTOG spec
            
            % Flip based on pt position
            
            %Get assoc scanUID
            assocUID = getAssocScanUID(attr,ssObj);
            assocScanNum = strcmp(assocUID,{scanOriS.scanUID});
            if ~any(assocScanNum) && length(scanOriS)==1
                assocScanNum = 1;
            end
            if any(assocScanNum)
                imgOriV = scanOriS(assocScanNum).imageOrientationPatient;
            else
                imgOriV = [1,0,0,0,1,0]'; % HFS
            end
%              if ~isempty(imgOri)
                  data = convertCoordinates(data, imgOriV);
%              else
%                     %Default it to HFS
%                 data(:,3) = -data(:,3); %Z is always negative to match RTOG spec
%                 data(:,2) = -data(:,2); 
%              end
            
            %Convert from DICOM mm to CERR cm.
            data    = data / 10;

            %Replicate the last data point: CERR needs first/last identical
            if ~isempty(data)
                data(end+1,:) = data(1,:);
%% REMOVED IN LATEST CERR
%{
                if length(unique(data(:,3))) > 1;

                    a = abs(diff(unique(data(:,3))));

                    if (max(a) > contourSliceTol)
                        %ROI Name
                        name = getTagValue(ssObj, '30060026');

                        warning(['CERR does not support out-of-plane contours. Skipping contour ' num2str(i) ' in structure ' name '.']);
                        continue;
                    end
                end
%}
            end

            dataS(c).segments = data;

        end

        %Segments are inserted in order of storage in the DICOM sequence,
        %meaning segments must be sorted and rearranged to match the slice
        %order of the associated scan.   This is handled by a function that
        %has access to both the scan and contour data, dcmdir2planC.

    case 'rasterSegments'
        %Implementation not necessary

    case 'DSHPoints'
        %Implementation not necessary

    case 'orientationOfStructure'
        %In CERR, all structures are oriented transversely.
        dataS = 'TRANSVERSE';

    case 'transferProtocol'
        dataS = 'DICOM';
        
    case 'referencedFrameOfReferenceUID'
        %dataS  = getTagValue(attr, '00200052');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.FrameOfReferenceUID));
        %dataS = char(attr.getString(2097234,0));
        dataS = char(ssObj.getString(805699620,0)); %org.dcm4che3.data.Tag.ReferencedFrameOfReferenceUID;
        
    case 'referencedSeriesUID'
        
        dataS = '';
        
        refFrameOfReferenceSeq = attr.getValue(805699600);
        if ~refFrameOfReferenceSeq.isEmpty
            refFrameOfReferenceSeq = refFrameOfReferenceSeq.get(0);
        else
            return
        end
        
        reRefStudySequence = refFrameOfReferenceSeq.getValue(805699602);
        if ~reRefStudySequence.isEmpty
            reRefStudySequence = reRefStudySequence.get(0);
        else
            return;
        end
        
        rtRefSeriesSequence = reRefStudySequence.getValue(805699604);
        if ~rtRefSeriesSequence.isEmpty
            rtRefSeriesSequence = rtRefSeriesSequence.get(0);
        else
            return
        end
        
        dataS = char(rtRefSeriesSequence.getString(2097166,0));
        
        
               
    case 'DICOMHeaders'
        %Currently not implemented
        %Read all the dcm data into a MATLAB struct.
        if strcmpi(optS.saveDICOMheaderInPlanC,'yes')
            dataS = getTagStruct(attr);
        end
% 
%         %Remove contoursequence data to avoid storing huge amounts of redundant data.
%         try
%             dataS = rmfield(dataS, 'ROIContourSequence');
%         end

%         dataS = '';
        

    case 'visible'
        dataS = true; % default to visible        

    case 'associatedScan'
        %Currently not implemented

    case 'strUID'
        dataS = createUID('structure');

    case 'assocScanUID'
        %wy, use the Referenced frame of reference UID to associate structures to scan.
        %SSRS = attr.get(org.dcm4che2.data.Tag.StructureSetROISequence);
        %SSRS_1 = SSRS.getDicomObject(0);
        %dataS = char(SSRS_1.getString(org.dcm4che2.data.Tag.ReferencedFrameofReferenceUID));
        
        %dataS = getTagValue(SSRS.get(hex2dec('00200052')));
        %dataS = ['CT.',dataS];

        dataS = getAssocScanUID(attr,ssObj);

%         %Convert to ML structure format.
%         RSSML = getTagStruct(RSS);
%         
%         if ~isempty(RSSML)
%             %UID of series structures were contoured on.
%             dataS = RSSML.SeriesInstanceUID;
%             dataS = ['CT.',dataS];
%         else
%             dataS = '';
%         end        

    otherwise
        %         warning(['DICOM Import has no methods defined for import into the planC{indexS.structures}.' fieldname ' field, leaving empty.']);
end



function attr = getReferencedSeriesSequence(Referenced_Frame_Of_Reference_Sequence, Frame_of_Reference_UID);
%"getReferencedSeriesSequence"
%   Searches the RFRS for a match to the FoRUID of a structure and returns
%   the subfield of the RFRS containing information on the series that the
%   contours were defined on.  Not a general function since it is really
%   only used when populating structure fields.

%Easier reading.
referencedSeq = Referenced_Frame_Of_Reference_Sequence;
refUID = Frame_of_Reference_UID;

if ~isempty(referencedSeq)
    nRFRS = referencedSeq.size();
else
    nRFRS = 0;
end
%Search the RFR sequence for the UID matching the FORUID.
for i=1:nRFRS

    myRFR = referencedSeq.get(i-1);

    % RFRUID = getTagValue(myRFR, '00200052');
    RFRUID = char(myRFR.getString(2097234,0)); %org.dcm4che3.data.Tag.FrameOfReferenceUID;

    if isequal(RFRUID,refUID)

        %RT Referenced Study Sequence
        %RTRSS = myRFR.getValue(hex2dec('30060012'));
        RTRSS = myRFR.getValue(805699602); %org.dcm4che3.data.Tag.RTReferencedStudySequence;

        if isempty(RTRSS)
            break;
        end

        RTRSS_1 = RTRSS.get(0);

        %RT Referenced Series Sequence
        %RTRSS = RTRSS_1.getValue(hex2dec('30060014'));
        RTRSS = RTRSS_1.getValue(805699604); %org.dcm4che3.data.Tag.RTReferencedSeriesSequence;

        attr = RTRSS.get(0);

    end

end

if ~exist('attr', 'var')
    warning('No explicit association between structures and a scan could be found.');
    attr = javaObject('org.dcm4che3.data.Attributes');
end

end %End of function

function assocScanUID = getAssocScanUID(attr,ssObj)
%commented by wy
        %Referenced Frame of Reference Sequence
        %referencedSeq = attr.getValue(hex2dec('30060010'));
        referencedSeq = attr.getValue(805699600); %org.dcm4che3.data.Tag.ReferencedFrameOfReferenceSequence; 
        
        %Frame of Reference UID
        %refUID = getTagValue(ssObj, '30060024');
        refUID = char(ssObj.getString(805699620,0)); %org.dcm4che3.data.Tag.ReferencedFrameOfReferenceUID;
        
        %Find the series referenced by these contours.  See bottom of file.
        refSerSeq = getReferencedSeriesSequence(referencedSeq, refUID);
        
        %assocScanUID = getTagValue(refSerSeq,'0020000E');
        assocScanUID = char(refSerSeq.getString(2097166,0)); %org.dcm4che3.data.Tag.SeriesInstanceUID;
        
        assocScanUID = ['CT.',assocScanUID];

end %End of function

end