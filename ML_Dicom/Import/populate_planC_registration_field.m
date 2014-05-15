function dataS = populate_planC_registration_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_REG, dcmobj)
%"populate_planC_registration_field"
%   Given the name of a child field to planC{indexS.registration}, populates that
%   field based on the data contained in dcmdir.PATIENT.STUDY.SERIES.REGS
%   structure passed in, for structure number structNum.
%
%APA 02/19/2014
%Usage:
%   dataS = populate_planC_registration_field(fieldname,dcmdir_PATIENT_STUDY_SERIES_REGS);
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

STRUCT = dcmdir_PATIENT_STUDY_SERIES_REG;

%Default value for undefined fields.
dataS = '';

if ~exist('dcmobj', 'var')
    %Grab the dicom object representing the structures.
    dcmobj = scanfile_mldcm(STRUCTS.file);
end


% %Structure Set ROI Sequence
% SSRS = dcmobj.get(hex2dec('30060020'));
% 
% %ROI Contour Sequence
% RCS = dcmobj.get(hex2dec('30060039'));
% 
% dcm2ml_Element(dcmobj.get(hex2dec('00200032')));
% 
% %Count em up.
% nStructs = RCS.countItems;

% %Structure Set item for this structure.
% ssObj = SSRS.getDicomObject(structNum - 1);
% 
% %ROI Number
% ROINumber = dcm2ml_Element(ssObj.get(hex2dec('30060022')));
% 
% %Find the contour object for this structure.
% for i=1:nStructs
%     cObj = RCS.getDicomObject(i - 1);
% 
%     %Referenced ROI Number
%     RRN = dcm2ml_Element(cObj.get(hex2dec('30060084')));
% 
%     if RRN == ROINumber
%         %We found the correct contour for this structure.
%         break;
%     end
% 
% end

switch fieldname

    case 'rigidS'
        %Rigid Sequence
        rSeq = dcmobj.get(hex2dec('00700308'));

        if isempty(rSeq)
            return;
        end

        nRegs = rSeq.countItems;

        for i = 1:nRegs
            
            aRegSeq = rSeq.getDicomObject(i-1);
            
            %Frame of Reference UID
            FORUID = dcm2ml_Element(aRegSeq.get(hex2dec('00200052')));
            RIS = aRegSeq.get(hex2dec('00081140'));
            forUID = FORUID;
            
            % Matrix Registration Sequence
            matRegSeq = aRegSeq.get(hex2dec('00700309'));
            
            aMatItemsSeq = matRegSeq.getDicomObject(0);
            matItemsSeq = aMatItemsSeq.get(hex2dec('0070030A'));
            
            numMatrixItems = matItemsSeq.countItems;            
            
            for iMat = 1:numMatrixItems
                aMatItem = matItemsSeq.getDicomObject(iMat-1);
                % Frame of reference Transformation Matrix
                transV = dcm2ml_Element(aMatItem.get(hex2dec('300600C6')));
                % Frame of reference Transformation Matrix Type
                dataS(i).transType{iMat} = dcm2ml_Element(aMatItem.get(hex2dec('0070030C')));
                transM = reshape(transV(:),4,4)';
                transM(1:3,4) = transM(1:3,4)/10;
                dataS(i).transM{iMat} = transM;                
            end
            
            dataS(i).forUID = forUID;
            
        end
        

    case 'deformS'        
        %Deformable Sequence
        dSeq = dcmobj.get(hex2dec('00640002'));

        if isempty(dSeq)
            return;
        end

        nRegs = dSeq.countItems;           

        for i = 1:nRegs
            
            aRegSeq = dSeq.getDicomObject(i-1);
            
            % Get the UID of associated scan
            %Frame of Reference UID
            FORUID = dcm2ml_Element(aRegSeq.get(hex2dec('00640003')));
            RIS = aRegSeq.get(hex2dec('00081140'));
            forUID = FORUID;

            % Pre reg Matrix Registration Sequence
            preDefMatRegSeq = aRegSeq.get(hex2dec('0064000F'));
            preRegTransM = eye(4);
            preRegTransType = '';
            if ~isempty(preDefMatRegSeq)            
                preRegDefObj = preDefMatRegSeq.getDicomObject(0);
                preRegTransM = dcm2ml_Element(preRegDefObj.get(hex2dec('300600C6')));
                preRegTransType = dcm2ml_Element(preRegDefObj.get(hex2dec('0070030C')));
            end
            dataS(i).preRegTransM = reshape(preRegTransM,4,4)';
            dataS(i).preRegTransM(1:3,4) = dataS(i).preRegTransM(1:3,4)/10;
            dataS(i).preRegTransType = preRegTransType;
            
            % Post reg Matrix Registration Sequence
            postDefMatRegSeq = aRegSeq.get(hex2dec('00640010'));
            postRegTransM = eye(4);
            postRegTransType = '';
            if ~isempty(postDefMatRegSeq)            
                postRegDefObj = postDefMatRegSeq.getDicomObject(0);
                postRegTransM = dcm2ml_Element(postRegDefObj.get(hex2dec('300600C6')));
                postRegTransType = dcm2ml_Element(postRegDefObj.get(hex2dec('0070030C')));
            end
            dataS(i).postRegTransM = reshape(postRegTransM,4,4)';
            dataS(i).postRegTransM(1:3,4) = dataS(i).postRegTransM(1:3,4)/10;
            dataS(i).postRegTransType = postRegTransType;
            
            % Deformable registration grid
            defRegSeq = aRegSeq.get(hex2dec('00640005'));
            imageOrientationPatient = [];
            imagePositionPatient = [];
            gridDimensions = [];
            gridResolution = [];
            vectorGridData = [];
            if ~isempty(defRegSeq)
                defRegSeqObj = defRegSeq.getDicomObject(0);
                imgOri = dcm2ml_Element(defRegSeqObj.get(hex2dec('00200037')));
                imgpos    = dcm2ml_Element(defRegSeqObj.get(hex2dec('00200032')))/10;
                gridDimensions          = dcm2ml_Element(defRegSeqObj.get(hex2dec('00640007')));
                pixspac          = dcm2ml_Element(defRegSeqObj.get(hex2dec('00640008')))/10;
                vectorGridData          = dcm2ml_Element(defRegSeqObj.get(hex2dec('00640009')))/10;
            end
            dataS(i).imageOrientationPatient = imgOri;
            dataS(i).imagePositionPatient = imgpos;
            dataS(i).gridDimensions = gridDimensions;
            dataS(i).gridResolution = pixspac;
            vectorGridData = reshape(vectorGridData,[3 gridDimensions(:)']);
            vectorGridData = permute(vectorGridData,[3,2,4,1]);
            dataS(i).xDeform3M = vectorGridData(:,:,:,1);
            dataS(i).yDeform3M = vectorGridData(:,:,:,2);
            dataS(i).zDeform3M = vectorGridData(:,:,:,3);
            dataS(i).forUID = forUID;
            % Get xOffset, yOffset and zOffset
            % i.e. the x, y, and z coordinates of the upper left hand voxel (center of the first voxel transmitted) of the grid
            nCols = gridDimensions(1);
            nRows = gridDimensions(2);
            if (imgOri(1)-1)^2 < 1e-5
                xOffset = imgpos(1) + (pixspac(2) * (nCols - 1) / 2);
            elseif (imgOri(1)+1)^2 < 1e-5
                xOffset = imgpos(1) - (pixspac(2) * (nCols - 1) / 2);
            else
                xOffset = imgpos(1);
            end
            %         xOffset = imgpos(1) + (pixspac(1) * (nCols - 1) / 2);
            
            %Convert from DICOM mm to CERR cm.
            switch upper(pPos)
                case 'HFS'
                    xOffset = xOffset;
                case 'HFP'
                    xOffset = -xOffset;
                case 'FFS'
                    xOffset = xOffset;
                case 'FFP'
                    xOffset = -xOffset;
            end
            dataS(i).xOffset = xOffset;
            
            if (imgOri(5)-1)^2 < 1e-5
                yOffset = imgpos(2) + (pixspac(1) * (nRows - 1) / 2);
            elseif (imgOri(5)+1)^2 < 1e-5
                yOffset = imgpos(2) - (pixspac(1) * (nRows - 1) / 2);
            else
                % by Deshan Yang, 3/2/2010
                yOffset = imgpos(2);
            end
            %         yOffset = imgpos(2) + (pixspac(2) * (nRows - 1) / 2);
            
            %Convert from DICOM mm to CERR cm, invert to match CERR y dir.
            switch upper(pPos)
                case 'HFS'
                    yOffset = - yOffset;
                case 'HFP'
                    yOffset = yOffset;
                case 'FFS'
                    yOffset = - yOffset;
                case 'FFP'
                    yOffset = yOffset;
            end
            dataS(i).yOffset = yOffset;
            
        end
        

    case 'regUID'
        dataS = createUID('registration');

    case 'scanUID'
        %wy, use the Referenced frame of reference UID to associate structures to scan.
        %SSRS = dcmobj.get(org.dcm4che2.data.Tag.StructureSetROISequence);
        %SSRS_1 = SSRS.getDicomObject(0);
        %dataS = char(SSRS_1.getString(org.dcm4che2.data.Tag.ReferencedFrameofReferenceUID));
        
        %dataS = dcm2ml_Element(SSRS.get(hex2dec('00200052')));
        %dataS = ['CT.',dataS];
        
        %commented by wy
        %Referenced Frame of Reference Sequence
        RFRS = dcmobj.get(hex2dec('00640003'));
        
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