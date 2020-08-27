function dataS = populate_planC_dose_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_RTDOSE, attr, rtPlans, optS)
%"populate_planC_dose_field"
%   Given the name of a child field to planC{indexS.scan}, populates that
%   field based on the data contained in dcmdir.PATIENT.STUDY.SERIES.RTDOSE
%   structure passed in.
%
%JRA 07/12/06
%YWU Modified 03/01/08
%DK 04/12/09
%   Fixed Coordinate System
%NAV 07/19/16 updated to dcm4che3
%   replaced dcm2ml_element with getTagValue
%   and used getValue instead of get
%
%Usage:
%   dataS = populate_planC_dose_field(fieldname,dcmdir_PATIENT_STUDY_SERIES_RTDOSE);
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
global xOffset yOffset;

persistent RTPlanUID maxDose

DOSE = dcmdir_PATIENT_STUDY_SERIES_RTDOSE;

%Default value for undefined fields.
dataS = '';

if ~exist('attr', 'var')
    %Grab the dicom object representing this image.
    attr = scanfile_mldcm(DOSE.file);
end

switch fieldname
    case 'doseUID'
        dataS = createUID('dose');
        
    case 'imageNumber'
        %Currently undefined.
        maxDose = []; RTPlanUID = []; % Reset to avoid junk value
        
    case 'imageType'
        dataS = 'DOSE';
        
    case 'caseNumber'
        %Currently undefined.
        
    case 'patientName'
        %Patient's Name
        dataS = getTagValue(attr, '00100010');
        
    case 'doseNumber'
        %Currently undefined.
        
    case 'doseType'
        %Dose Type
        dT = getTagValue(attr, '30040004');
        
        switch upper(dT)
            case 'PHYSICAL'
                dataS = 'PHYSICAL';
            case 'EFFECTIVE'
                dataS = 'EFFECTIVE';
            case 'ERROR'
                dataS = 'ERROR';
            otherwise
                %Unknown doseType, take the value straight from DICOM.
                dataS = dT;
        end
        
    case 'doseSummationType'
        dataS = getTagValue(attr, '3004000A');
        
    case 'refBeamNumber'
        %Use getValue instead of get
        rtplanSeq = attr.getValue(hex2dec('300C0002'));
        if isempty(rtplanSeq)
            return;
        end
        %Find attribute in first position of sequence
        artpSeq = rtplanSeq.get(0);
        fractionGroupSeq = artpSeq.getValue(hex2dec('300C0020'));
        if isempty(fractionGroupSeq)
            return;
        end
        %If sequence is empty, then size is zero, so if not
        %empty, it is assumed that size is gretaer than zero
        
        %replace with the following for dcm4che3
        aFractionGroupSeq = fractionGroupSeq.get(0);
        beamSeq = aFractionGroupSeq.getValue(hex2dec('300C0004'));
        if isempty(beamSeq)
            return;
        end
        numBeams = beamSeq.size;
        if numBeams > 0
            aBeamSeq = beamSeq.get(0);
            dataS = getTagValue(aBeamSeq,'300C0006');
        end
        
    case 'refFractionGroupNumber'
        rtplanSeq = attr.getValue(hex2dec('300C0002'));
        if isempty(rtplanSeq)
            return;
        end
        artpSeq = rtplanSeq.get(0);
        fractionGroupSeq = artpSeq.getValue(hex2dec('300C0020'));
        if isempty(fractionGroupSeq)
            return;
        end
        %If sequence is empty, then size is zero, so if not
        %empty, it is assumed that size is gretaer than zero
        
        aFractionGroupSeq = fractionGroupSeq.get(0);
        dataS = getTagValue(aFractionGroupSeq, '300C0022');
        
    case 'numberMultiFrameImages'
        dataS = getTagValue(attr, '00280008');
        
    case 'doseUnits'
        %Dose Units
        dU = getTagValue(attr, '30040002');
        
        switch upper(dU)
            case {'GY', 'GYS', 'GRAYS', 'GRAY'}
                dataS = 'GRAYS';
            otherwise
                dataS = dU;
        end
        
    case 'doseScale'
        %Dose Grid Scaling. Imported, not indicative of CERR's representation.
        dataS = getTagValue(attr, '3004000E');
        
    case 'fractionGroupID' %Needs implementation, paired with RTPLAN
        if ~isempty(rtPlans)
            [RTPlanLabel RTPlanUID]= getRelatedRTPlanLabel(rtPlans,attr);
            
            dataS = RTPlanLabel;
        else
            DoseSummationType = getTagValue(attr, '3004000A');
            dU = getTagValue(attr, '30040002');
            maxDose = num2str(maxDose);
            dataS = [DoseSummationType '_' maxDose '_' dU];
        end
        
    case 'assocBeamUID'
        dataS = RTPlanUID;
        
    case 'numberOfTx'
        %Currently undefined.
        
    case 'orientationOfDose'
        %In CERR, Dose is always oriented transversely.
        dataS = 'TRANSVERSE';
        
    case 'imagePositionPatient'
        dataS  = getTagValue(attr, '00200032');
        
    case 'imageOrientationPatient'
        %Image Orientation
        dataS  = getTagValue(attr, '00200037');
        
    case 'numberRepresentation'
        %Artifact of RTOG, not indicative of CERR's representation
        dataS = 'CHARACTER';
        
    case 'numberOfDimensions'
        %In CERR, all dose arrays have 3 dimensions, even those with a
        %single slice (in which case Z exists with size 1).
        dataS = 3;
        
    case 'sizeOfDimension1'
        %Columns
        dataS = getTagValue(attr, '00280011');
        
    case 'sizeOfDimension2'
        %Rows
        dataS = getTagValue(attr, '00280010');
        
    case 'sizeOfDimension3'
        %Number of Frames
        dataS = getTagValue(attr, '00280008');
        
    case 'coord1OFFirstPoint'
        %Image Position (Patient)
        iPP = getTagValue(attr, '00200032');
        
        %Pixel Spacing
        pixspac = getTagValue(attr, '00280030');
        
        %Columns
        nCols  = getTagValue(attr, '00280011');
        
        imgOriV = getTagValue(attr, '00200037');
        
        % Check for oblique scan
        if max(abs((imgOriV(:) - [1 0 0 0 1 0]'))) < 1e-3
            %HFS
            isOblique = 0;
        elseif  max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3
            %FFS;
            isOblique = 0;
        elseif max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
            %HFP
            isOblique = 0;
        elseif max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3
            %FFP
            isOblique = 0;
        else
            %OBLIQUE
            isOblique = 1;
        end
        
        if (imgOriV(1)==-1) && ~isOblique
            dataS = iPP(1) - (abs(pixspac(2)) * (nCols - 1));
            dataS = dataS / 10;
        else
            dataS = iPP(1) / 10;
        end
        
        if ~isOblique
            if max(abs((imgOriV(:) - [1 0 0 0 1 0]'))) < 1e-3
                %'HFS'
                dataS = dataS;
                
            elseif  max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
                %'HFP'
                %dataS = -dataS; %APA commented
                dataS = -dataS; % 1/3/2017
                xDoseSiz = (abs(pixspac(2)) * (nCols - 1))/10;
                dataS = dataS - xDoseSiz; % 1/3/2017
                
            elseif max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3
                %'FFS'
                dataS = -dataS;
                %dataS = dataS; %APA change
                xDoseSiz = (abs(pixspac(2)) * (nCols - 1))/10;
                dataS = dataS - xDoseSiz; % 1/3/2017
                
            elseif max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3
                %'FFP'
                dataS = dataS;
                %dataS = -dataS;
                %dataS = 2*xOffset - dataS;
            end
        else
            dataS = dataS; % default to HFS
        end
        
        
        %APA commented begins
        %         if (imgOri(1)==1)
        %             xOffset = iPP(1) + (pixspac(1) * (nCols - 1) / 2);
        %         end
        %         if (imgOri(1)==-1)
        %             xOffset = iPP(1) - (pixspac(1) * (nCols - 1) / 2);
        %         end
        %
        %         if isstr(pPos)
        %             switch upper(pPos)
        %                 case 'HFS'
        %                     dataS = iPP(1) / 10;
        %                 case 'HFP'
        %                     dataS = -iPP(1) / 10;
        %                 case 'FFS'
        %                     dataS = -iPP(1) / 10;
        %                 case 'FFP'
        %                     dataS = -iPP(1) / 10;
        %             end
        %         else
        %             dataS = iPP(1) / 10; % default to HFS
        %         end
        %APA commented ends
        
        %         %for HFP
        %         if isequal(pPos,'HFP')
        %             %dataS = -dataS;
        %             dataS = (2*xOffset-iPP(1)) / 10;
        %         else
        %             dataS = iPP(1) / 10;
        %         end
        
    case 'coord2OFFirstPoint'
        %Image Position (Patient)
        iPP = getTagValue(attr, '00200032');
        
        %Pixel Spacing
        pixspac = getTagValue(attr, '00280030');
        
        %Rows
        nRows = getTagValue(attr, '00280010');
        
        imgOriV = getTagValue(attr, '00200037');
        
        % Check for oblique scan
        isOblique = 0;
        if max(abs(abs(imgOriV(:)) - [1 0 0 0 1 0]')) > 1e-3
            isOblique = 1;
        end
        
        if (imgOriV(2)==-1) && ~isOblique
            dataS = iPP(2) + (abs(pixspac(1)) * (nRows - 1));
            dataS = dataS / 10;
        elseif  ~isOblique && (imgOriV(2)==0) && (imgOriV(5)==1) && ...
                (max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3 || ...
                max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3)
            % FFP or HFP
            % flip is necessary to display couch at the bottom. How anout HFP?
            % should be based on imgOri(5)?
            dataS = iPP(2) + (abs(pixspac(1)) * (nRows - 1));
            dataS = dataS / 10;
        else
            dataS = iPP(2) / 10;
        end
        
        if ~isOblique
            if max(abs((imgOriV(:) - [1 0 0 0 1 0]'))) < 1e-3
                %'HFS'
                dataS = -dataS;
            elseif max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
                %'HFP'
                dataS = dataS;
            elseif max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3
                %'FFS'
                dataS = -dataS;
            elseif max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3
                %'FFP'
                dataS = dataS;
            end
        else
            dataS = -dataS; % default to HFS
        end
        
        
        %APA commented begins
        %         if (imgOri(2)==1)
        %             yOffset = iPP(2) + (pixspac(2) * (nRows - 1) / 2);
        %         end
        %         if (imgOri(2)==-1)
        %             yOffset = iPP(2) - (pixspac(2) * (nRows - 1) / 2);
        %         end
        %         %Convert from DICOM mm to CERR cm, negate to match CERR Y dir
        %
        %         if isstr(pPos)
        %             switch upper(pPos)
        %                 case 'HFS'
        %                     dataS = -iPP(2) / 10;
        %                 case 'HFP'
        %                     dataS = iPP(2) / 10;
        %                 case 'FFS'
        %                     dataS = -iPP(2) / 10;
        %                 case 'FFP'
        %                     dataS = -iPP(2) / 10;
        %             end
        %         else
        %             dataS = -iPP(2) / 10; % default to HFS
        %         end
        %APA commented ends
        
    case 'horizontalGridInterval'
        %Pixel Spacing
        pixspac = getTagValue(attr, '00280030');
        dataS = abs(pixspac(2)) / 10;
        
        %         %Convert from DICOM mm to CERR cm.
        %         imgOri = getTagValue(attr.get(hex2dec('00200037')));
        %         if isequal(pPos,'HFP')
        %             dataS = pixspac(2) / 10;
        %         else
        %             if (imgOri(5)==1)
        %                 dataS = pixspac(2) / 10;
        %             else
        %                 dataS = -pixspac(2) / 10;
        %             end
        %         end
        
    case 'verticalGridInterval'
        %Pixel Spacing
        pixspac = getTagValue(attr, '00280030');
        dataS = -abs(pixspac(1)) / 10;
        
        %         %Convert from DICOM mm to CERR cm, negate to match CERR Y dir.
        %         imgOri = getTagValue(attr.get(hex2dec('00200037')));
        %         if isequal(pPos,'HFP')
        %             dataS = - pixspac(1) / 10;
        %         else
        %             if (imgOri(1)==1)
        %                 dataS = - pixspac(1) / 10;
        %             else
        %                 dataS = pixspac(1) / 10;
        %             end
        %         end
        
        
    case 'doseDescription'
    case 'doseEdition'
    case 'unitNumber'
    case 'writer'
    case 'dateWritten'
    case 'planNumberOfOrigin'
    case 'planEditionOfOrigin'
    case 'studyNumberOfOrigin'
        
    case 'studyInstanceUID'
        dataS  = getTagValue(attr, '0020000D');
        
    case 'versionNumberOfProgram'
    case 'xcoordOfNormaliznPoint'
        %Type 3 field, may not exist.
        if attr.contains(hex2dec('30040008'))
            
            %Normalization Point
            nP  = getTagValue(attr, '30040008');
            
            %Convert from DICOM mm to CERR cm.
            dataS = nP(1) / 10;
        end
        
    case 'ycoordOfNormaliznPoint'
        %Type 3 field, may not exist.
        if attr.contains(hex2dec('30040008'));
            
            %Normalization Point
            nP  = getTagValue(attr, '30040008');
            
            %Convert from DICOM mm to CERR cm.
            dataS = nP(2) / 10;
        end
        
    case 'zcoordOfNormaliznPoint'
        %Type 3 field, may not exist.
        if attr.contains(hex2dec('30040008'));
            
            %Normalization Point
            nP  = getTagValue(attr, '30040008');
            
            %Convert from DICOM mm to CERR cm.
            dataS = nP(3) / 10;
        end
        
    case 'doseAtNormaliznPoint'
    case 'doseError'
    case 'coord3OfFirstPoint'
    case 'depthGridInterval'
    case 'planIDOfOrigin'
    case 'doseArray'
        %Bits Allocated
        bA = getTagValue(attr, '00280100');
        
        %Pixel Representation
        pixRep = getTagValue(attr, '00280103');
        
        transferSyntaxUID = getTagValue(attr,'00020010');
        
        doseType = getTagValue(attr,'30040004');
        
        mread = 0;
        %wy Pixel Data
        try
            
            % doseV = uint16(getTagValue(attr, '7FE00010'));
            doseV = getTagValue(attr, '7FE00010');
            
            % doseV is a vector of 16 bit numbers
            if strcmpi(class(doseV),'int32')
                doseV = typecast(int16(doseV),'uint16');
            elseif strcmpi(class(doseV),'int16')
                doseV = typecast(doseV,'uint16');
            end
            if isempty(doseV)
                doseV = dicomread(DOSE.file);
                mread = 1;
            end
            
            switch bA
                case 32
                    %doseV is a vector of 16 bit numbers in which the 4 bytes
                    %of 2 consecutive elements represent a single 32 bit point.
                    doseV = bitstream_conversion_to('uint32', doseV);
                case 16
                    %Data already consists of one dose point per word.
                otherwise
                    error('RT Dose objects must have attribute "Bits Allocated" set to either 16 or 32.');
            end
            
        catch
            doseV = dicomread(DOSE.file);
            doseV = squeeze(doseV);
            mread = 1;
        end
        
        %Dose Grid Scaling
        dGS = getTagValue(attr, '3004000E');
        
        %Columns
        nCols = getTagValue(attr, '00280011');
        
        %Rows
        nRows = getTagValue(attr, '00280010');
        
        %Number of Frames
        nSlcs = getTagValue(attr ,'00280008');
        
        %Rescale dose to get real dose values.
        doseV = single(doseV) * dGS;
        
        %Reshape to 3D matrix.
        if mread
            dose3 = reshape(doseV, [nRows nCols nSlcs]);
        else
            dose3 = reshape(doseV, [nCols nRows nSlcs]);
        end
        clear doseV;
        
        %Permute dimensions x and y.
        if ~mread
            dose3 = permute(dose3, [2 1 3]);
        end
        dataS = dose3;
        
        imgOriV = getTagValue(attr, '00200037');
        if (imgOriV(1)==-1)
            dataS = flipdim(dataS, 2);
        end
        
        if (imgOriV(5)==-1)
            dataS = flipdim(dataS, 1);
        end
        
        if (max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3 ||...
                max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3) %HFP or FFP
            %dataS = flipdim(dataS, 2);
            dataS = flipdim(dataS, 1); %APA change
        end
        if max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3 %HFP
            dataS = flipdim(dataS, 2); % 1/3/2017
        end
        
        maxDose = max(dataS(:));
        
    case 'zValues'
        %Image Position (Patient)
        iPP = getTagValue(attr, '00200032');
        imgOriV = getTagValue(attr, '00200037');
        
        % Check if oblique
        isOblique = 0;
        if max(abs(abs(imgOriV(:)) - [1 0 0 0 1 0]')) > 1e-3
            isOblique = 1;
        end
        
        %APA commented begins
        %         if ~isequal(pPos,'HFP')
        %             if (imgOri(1)==-1) || (imgOri(5)==-1)
        %                 iPP(3) = -- iPP(3);
        %             end
        %         end
        %APA commented ends
        %Frame Increment Pointer
        fIP = getTagValue(attr, '00280009');
        
        if size(fIP,1) == 2
            fIP = [fIP(1,:) fIP(2,:)]; %added DK to make fIP a size of 1.
        end
        
        %Follow pointer to attribute containing zValues, usually Grid Frame Offset Vector
        
        try
            gFOV = getTagValue(attr, fIP);
            if ((imgOriV(1)==-1) || (imgOriV(5)==-1)) && ...
                    ~(max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3) %Not HFP
                gFOV = - gFOV;
            end
        catch
            gFOV = 0;
        end
        
        if gFOV(1) == 0
            %Relative Grid Frame, add to zValue from patient position.
            dataS = iPP(3) + gFOV;
        else % iPP(3)==gFOV(1)
            %Absolute Grid Frame, use zValues directly.
            dataS = gFOV;
        end
        
        %Convert from DICOM mm to CERR cm, invert Z to match CERR Zdir.
        if ~isOblique
            dataS = - dataS / 10;
        else
            dataS = dataS / 10;
        end
        
    case 'delivered'
        %Currently unimplemented.
    case 'cachedColor'
        %Currently unimplemented.
    case 'cachedTime'
        %Currently unimplemented.
    case 'numCachedSlices'
        %Currently unimplemented.
        
    case 'transferProtocol'
        dataS = 'DICOM';
        
    case 'DICOMHeaders'
        %Read all the dcm data into a MATLAB struct.
        if strcmpi(optS.saveDICOMheaderInPlanC,'yes')
            %dataS = dcm2ml_Object(attr);
            dataS = getTagStruct(attr);
        end
        
    case 'associatedScan'
        %Currently unimplemented
        
    case 'assocScanUID'
        %wy, use the frame of reference UID to associate dose to scan.
        %dataS = char(dcmobj.getString(org.dcm4che2.data.Tag.FrameofReferenceUID));
        %         dataS = dcm2ml_Element(dcmobj.get(hex2dec('00080018'))); % SOP instance UID
        %         dataS = dcm2ml_Element(dcmobj.get(hex2dec('00200052'))); % Frame of Reference UID
        dataS.forUID = getTagValue(attr, '00200052'); % Frame of Reference UID
        %         rtplanSeq = dcmobj.get(hex2dec('300C0002'));
        %         artpSeq = rtplanSeq.getDicomObject(0);
        %         rtplanML = dcm2ml_Object(artpSeq);
        %         refSOPClassUID = dcm2ml_Element(artpSeq.get(hex2dec('00081150')));
        %         refSOPInstanceUID = dcm2ml_Element(artpSeq.get(hex2dec('00081155')));
        dataS = ''; % implemented in guessPlanUID based on structures set's sopInstanceUID

        
    case 'frameOfReferenceUID'
        dataS = getTagValue(attr, '00200052'); % Frame of Reference UID
        
    case 'refStructSetSopInstanceUID'
        
        dataS = '';

        referencedRTPlanSequence = getTagValue(attr, '300C0002');
        referencedPlanSOPInstanceUID = referencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
        numChars = length(referencedPlanSOPInstanceUID);
        for iPlan = 1:length(rtPlans)
            if strncmp(rtPlans(iPlan).SOPInstanceUID, referencedPlanSOPInstanceUID, numChars)
                dataS = rtPlans(iPlan).ReferencedStructureSetSequence.Item_1.ReferencedSOPInstanceUID;
            end
        end
           
    case 'transM'
        %Implementation is unnecessary.
        
    case 'dvhsequence'
        %Get DVH Sequence.
        dataS = getTagValue(attr, '30040050');
        
    otherwise
        %         warning(['DICOM Import has no methods defined for import into the planC{indexS.dose}.' fieldname ' field, leaving empty.']);
end


    function [RTPlanLabel RTPlanUID]= getRelatedRTPlanLabel(rtPlans,attr)
        
        RTPlanLabel = ''; RTPlanUID = '';
        
        try
            ReferencedRTPlanSequence = getTagValue(attr, '300C0002');
            
            for i = 1:length(rtPlans)
                if strmatch(rtPlans(i).SOPInstanceUID, ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID)
                    RTPlanLabel = rtPlans(i).RTPlanLabel;
                    RTPlanUID = rtPlans(i).BeamUID;
                end
            end
        catch
        end
    end

    function assocScanUID = getAssocScanUID(attr,ssObj)
        %commented by wy
        %Referenced Frame of Reference Sequence
        referencedSeq = attr.getValue(hex2dec('30060010'));
        
        %Frame of Reference UID
        refUID = getTagValue(ssObj, '30060024');
        
        %Find the series referenced by these contours.  See bottom of file.
        refSerSeq = getReferencedSeriesSequence(referencedSeq, refUID);
        
        assocScanUID = getTagValue(refSerSeq,'0020000E');
        
        assocScanUID = ['CT.',assocScanUID];
        
    end %End of function

end
