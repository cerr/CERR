function dataS = populate_planC_structures_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_RTSTRUCTS, structNum, dcmobj)
%"populate_planC_structures_field"
%   Given the name of a child field to planC{indexS.structures}, populates that
%   field based on the data contained in dcmdir.PATIENT.STUDY.SERIES.RTSTRUCTS
%   structure passed in, for structure number structNum.
%
%JRA 07/12/06
%YWU Modified 03/01/08
%DK 04/12/09
%   Fixed Coordinate System
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
global pPos xOffset yOffset;

STRUCTS = dcmdir_PATIENT_STUDY_SERIES_RTSTRUCTS;

%Default value for undefined fields.
dataS = '';

if ~exist('dcmobj', 'var')
    %Grab the dicom object representing the structures.
    dcmobj = scanfile_mldcm(STRUCTS.file);
end

%Structure Set ROI Sequence
SSRS = dcmobj.get(hex2dec('30060020'));

%ROI Contour Sequence
RCS = dcmobj.get(hex2dec('30060039'));

dcm2ml_Element(dcmobj.get(hex2dec('00200032')));

%Count em up.
nStructs = RCS.countItems;

%Structure Set item for this structure.
ssObj = SSRS.getDicomObject(structNum - 1);

%ROI Number
ROINumber = dcm2ml_Element(ssObj.get(hex2dec('30060022')));

%Find the contour object for this structure.
for i=1:nStructs
    cObj = RCS.getDicomObject(i - 1);

    %Referenced ROI Number
    RRN = dcm2ml_Element(cObj.get(hex2dec('30060084')));

    if RRN == ROINumber
        %We found the correct contour for this structure.
        break;
    end

end

switch fieldname

    case 'imageNumber'
        %Currently not implemented

    case 'imageType'
        dataS = 'STRUCTURE';

    case 'caseNumber'
        %Currently not implemented
        
    case 'roiNumber'
        dataS = ROINumber;

    case 'patientName'
        %Patient's Name
        nameS = dcm2ml_Element(dcmobj.get(hex2dec('00100010')));
        dataS = [nameS.FamilyName '^' nameS.GivenName '^' nameS.MiddleName];

    case 'structureName'
        %ROI Name
        dataS = dcm2ml_Element(ssObj.get(hex2dec('30060026')));

    case 'numberRepresentation'
        %Artifact of RTOG field names, not representative of CERR data.
        dataS = 'CHARACTER';

    case 'structureFormat'
        dataS = 'SCAN-BASED';

    case 'numberOfScans' %aka # of CT slices
        %Referenced Frame of Reference Sequence
        RFRS = dcmobj.get(hex2dec('30060010'));

        %Frame of Reference UID
        FORUID = dcm2ml_Element(ssObj.get(hex2dec('30060024')));

        %Find the series referenced by these contours.  See bottom of file.
        RSS = getReferencedSeriesSequence(RFRS, FORUID);

        %Convert to ML structure format.
        RSSML = dcm2ml_Object(RSS);

        if ~isempty(RSSML) && ~isempty(RSSML.ContourImageSequence)
            %# slices in this series.
            dataS = length(fields(RSSML.ContourImageSequence));
        else
            dataS = '';
        end


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
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('00080070')));

    case 'dateWritten'
        %Structure Set Date.
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('30060008')));

    case 'structureColor'
        %Currently not implemented

    case 'structureDescription'
        %Currently not implemented

    case 'studyNumberOfOrigin'
        %Currently not implemented

    case 'contour'
        %Contour Sequence
        cSeq = cObj.get(hex2dec('30060040'));

        if isempty(cSeq)
            return;
        end

        nContours = cSeq.countItems;
        
        optS = CERROptions;
        contourSliceTol = optS.contourToSliceTolerance;
        
        for i = 1:nContours
            aContour = cSeq.getDicomObject(i-1);
            
            % Referenced SOP instance UID
            refSeq = aContour.get(hex2dec('30060016'));
            sopInstanceUID = dcm2ml_Element(refSeq.getDicomObject(0).get(hex2dec('00081155')));
            
            dataS(i).sopInstanceUID = sopInstanceUID;
            
            %Contour Geometric Type
            geoType = dcm2ml_Element(aContour.get(hex2dec('30060042')));

            switch upper(geoType)
                case 'POINT'
                    %warning('CERR does not support single point contours.');
                    warning('Single point contour.');
                case 'OPEN_PLANAR'
                    %warning('CERR does not support open planar contours.')
                    warning('Open planar contours.')
                case 'OPEN_NONPLANAR'
                    warning('CERR does not support open, non-planar contours.')
                case 'CLOSED_PLANAR'
                    %Great, continue.
            end

            %Number of Contour Points
            nPoints = dcm2ml_Element(aContour.get(hex2dec('30060046')));
            if isempty(nPoints)
                nPoints = 0;
            end
            %             if ~(nPoints > 1)
            %                 dataS(i).segments = [];
            %                 continue;
            %             end

            %Contour Data
            try
                data    = dcm2ml_Element(aContour.get(hex2dec('30060050')));
            catch
                disp('vacant contour found ...');
                dataS(i).segments = [];
                continue;
            end
            %Reshape Contour Data
            data    = reshape(data, [3 nPoints])';

            data(:,3) = -data(:,3); %Z is always negative to match RTOG spec

            if isstr(pPos)
                switch upper(pPos)
                    case 'HFS' %+x,-y,-z
                        data(:,2) = -data(:,2);
                        %data(:,2) = 2*yOffset*10 - data(:,2);
                    case 'HFP' %-x,+y,-z
                        data(:,1) = -data(:,1);
                        data(:,1) = 2*xOffset*10 - data(:,1);
                    case 'HFDR' %
                        data(:,1) = 2*yOffset*10 - data(:,2);
                        data(:,2) = -data(:,1);
                    case 'FFS' %+x,-y,-z
                        data(:,2) = -data(:,2);
                        %data(:,2) = 2*yOffset*10 - data(:,2);
                    case 'FFP' %-x,+y,-z
                        data(:,1) = -data(:,1);
                        data(:,1) = 2*xOffset*10 - data(:,1);
                end
            else
                data(:,2) = -data(:,2); %Default it to HFS
            end

            %Convert from DICOM mm to CERR cm.
            data    = data / 10;

            %Replicate the last data point: CERR needs first/last identical
            if ~isempty(data)
                data(end+1,:) = data(1,:);

%                 if length(unique(data(:,3))) > 1;
% 
%                     a = abs(diff(unique(data(:,3))));
% 
%                     if (max(a) > contourSliceTol)
%                         %ROI Name
%                         name = dcm2ml_Element(ssObj.get(hex2dec('30060026')));
% 
%                         warning(['CERR does not support out-of-plane contours. Skipping contour ' num2str(i) ' in structure ' name '.']);
%                         continue;
%                     end
%                 end
% 
            end

            dataS(i).segments = data;

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

    case 'DICOMHeaders'
        %Currently not implemented
        %Read all the dcm data into a MATLAB struct.
        dataS = dcm2ml_Object(dcmobj);

        %Remove contoursequence data to avoid storing huge amounts of redundant data.
        try
            dataS = rmfield(dataS, 'ROIContourSequence');
        end
        

    case 'visible'
        %Implementation not necessary

    case 'associatedScan'
        %Currently not implemented

    case 'strUID'
        dataS = createUID('structure');

    case 'assocScanUID'
        %wy, use the Referenced frame of reference UID to associate structures to scan.
        %SSRS = dcmobj.get(org.dcm4che2.data.Tag.StructureSetROISequence);
        %SSRS_1 = SSRS.getDicomObject(0);
        %dataS = char(SSRS_1.getString(org.dcm4che2.data.Tag.ReferencedFrameofReferenceUID));
        
        %dataS = dcm2ml_Element(SSRS.get(hex2dec('00200052')));
        %dataS = ['CT.',dataS];
        
        %commented by wy
        %Referenced Frame of Reference Sequence
        RFRS = dcmobj.get(hex2dec('30060010'));
        
        %Frame of Reference UID
        FORUID = dcm2ml_Element(ssObj.get(hex2dec('30060024')));
        
        %Find the series referenced by these contours.  See bottom of file.
        RSS = getReferencedSeriesSequence(RFRS, FORUID);
        
        %Convert to ML structure format.
        RSSML = dcm2ml_Object(RSS);
        
        if ~isempty(RSSML)
            %UID of series structures were contoured on.
            dataS = RSSML.SeriesInstanceUID;
            dataS = ['CT.',dataS];
        else
            dataS = '';
        end        

    otherwise
        %         warning(['DICOM Import has no methods defined for import into the planC{indexS.structures}.' fieldname ' field, leaving empty.']);
end



function dcmobj = getReferencedSeriesSequence(Referenced_Frame_Of_Reference_Sequence, Frame_of_Reference_UID);
%"getReferencedSeriesSequence"
%   Searches the RFRS for a match to the FoRUID of a structure and returns
%   the subfield of the RFRS containing information on the series that the
%   contours were defined on.  Not a general function since it is really
%   only used when populating structure fields.

%Easier reading.
RFRS = Referenced_Frame_Of_Reference_Sequence;
FORUID = Frame_of_Reference_UID;

nRFRS = RFRS.countItems;

%Search the RFR sequence for the UID matching the FORUID.
for i=1:nRFRS

    myRFR = RFRS.getDicomObject(i-1);

    RFRUID = dcm2ml_Element(myRFR.get(hex2dec('00200052')));

    if isequal(RFRUID,FORUID)

        %RT Referenced Study Sequence
        RTRSS = myRFR.get(hex2dec('30060012'));

        if isempty(RTRSS)
            break;
        end

        RTRSS_1 = RTRSS.getDicomObject(0);

        %RT Referenced Series Sequence
        RTRSS = RTRSS_1.get(hex2dec('30060014'));

        dcmobj = RTRSS.getDicomObject(0);

    end

end

if ~exist('dcmobj', 'var')
    warning('No explicit association between structures and a scan could be found.');
    dcmobj = org.dcm4che2.data.BasicDicomObject;
end