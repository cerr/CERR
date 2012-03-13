function dataS = populate_planC_USscan_field(fieldname, dcmdir_PATIENT_STUDY_SERIES, type)
%"populate_planC_scan_field"
%   Given the name of a child field to planC{indexS.scan}, populates that
%   field based on the data contained in the dcmdir.PATIENT.STUDY.SERIES
%   structure passed in.  Type defines the type of series passed in.
%
%JRA 06/15/06
%
%YWU Modified 03/01/08
%
%Usage:
%   dataS = populate_planC_scan_field(fieldname, dcmdir_PATIENT_STUDY_SERIES);
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

%For easier handling.
SERIES = dcmdir_PATIENT_STUDY_SERIES;

%Default value for undefined fields.
dataS = '';

switch fieldname
    case 'scanArray'
        dataS   = uint16([]);
        zValues = [];

        %Determine number of images
        nImages = length(SERIES.Data);

        %Iterate over slices.
        for imageNum = 1:nImages

            IMAGE   = SERIES.Data(imageNum);

            imgobj  = scanfile_mldcm(IMAGE.file);

            try
                %Pixel Data
                sliceV = dcm2ml_Element(imgobj.get(hex2dec('7FE00010')));


                %Rows
                nRows  = dcm2ml_Element(imgobj.get(hex2dec('00280010')));

                %Columns
                nCols  = dcm2ml_Element(imgobj.get(hex2dec('00280011')));

                %Pixel Representation
                pixRep = dcm2ml_Element(imgobj.get(hex2dec('00280103')));

                switch pixRep
                    case 0
                        sliceV = uint16(sliceV);
                    case 1
                        sliceV = int16(sliceV);
                    otherwise
                        warning('"Pixel Representation" field contains an invalid value, defaulting to unsigned integer.');
                end

                if imgobj.contains(hex2dec('00280008'))
                    % Try to see if tag Number Of Frames is present
                    numofframe  = dcm2ml_Element(imgobj.get(hex2dec('00280008')));

                    if numofframe > 1 & imageNum == 1
                        errordlg('This is Multiframe Ultrasound Study !! We do not support this data type.');
                    end
                else

                    if imgobj.contains(hex2dec('00280002'))
                        % Samples Per Pixel (Check to see if it is a RGB image)
                        samples_Per_Pixel = dcm2ml_Element(imgobj.get(hex2dec('00280002')));
                    else
                        samples_Per_Pixel = 1
                    end

                    %Shape the slice.
                    slice2D = reshape(sliceV, [nRows nCols samples_Per_Pixel]);
                end
            catch
                slice2D = dicomread(IMAGE.file);
            end

            samples_Per_Pixel = dcm2ml_Element(imgobj.get(hex2dec('00280002')));
            if samples_Per_Pixel == 3
                try
                    slice2D = rgb2gray(slice2D);
                catch
                end
            end

            %Store zValue for sorting, converting DICOM mm to CERR cm and
            %inverting to match CERR's z direction.

            % This is a private tag done by Envisioneering Medical
            % Technologies to provide Z coordinates

            try %wy ImageTranslationVectorRET
                transV = dcm2ml_Element(imgobj.get(hex2dec('00185212')));
                %Convert from DICOM mm to CERR cm, invert Z to match CERR Zdir.
                zValues(imageNum)  = -transV(3)/10;
            catch
                disp('error: scan Z-value error!');
            end

            %Store the slice in the 3D matrix.
            dataS(:,:,imageNum) = slice2D;

            clear imageobj;

        end

        %Reorder 3D matrix based on zValues.
        [jnk, zOrder]       = sort(zValues);
        dataS(:,:,1:end)    = dataS(:,:,zOrder);

    case 'scanType'

    case 'scanInfo'
        %Determine number of images
        nImages = length(SERIES.Data);

        %Get scanInfo field names.
        scanInfoInitS = initializeScanInfo;
        names = fields(scanInfoInitS);

        zValues = [];

        %Iterate over slices.
        for imageNum = 1:nImages

            IMAGE   = SERIES.Data(imageNum);
            imgobj  = scanfile_mldcm(IMAGE.file);

            % This is a private tag done by Envisioneering Medical
            % Technologies to provide Z coordinates
            try %wy ImageTranslationVectorRET
                transV = dcm2ml_Element(imgobj.get(hex2dec('00185212')));
                %Convert from DICOM mm to CERR cm, invert Z to match CERR Zdir.
                zValues(imageNum)  = -transV(3)/10;
            catch
                error('error: scan Z-value error!');
            end

            for i = 1:length(names)
                dataS(imageNum).(names{i}) = populate_planC_USscan_scanInfo_field(names{i}, IMAGE, imgobj, imageNum);
            end

            clear imageobj;

        end

        %Reorder scanInfo elements based on zValues.
        [jnk, zOrder]   = sort(zValues);

        dataS(1:end)    = dataS(zOrder);

    case 'uniformScanInfo'
        %Implementation is unnecessary.
    case 'scanArraySuperior'
        %Implementation is unnecessary.
    case 'scanArrayInferior'
        %Implementation is unnecessary.
    case 'thumbnails'
        %Implementation is unnecessary.
    case 'transM'
        %Implementation is unnecessary.
    case 'scanUID'
        %Series Instance UID
        dataS = dcm2ml_Element(SERIES.info.get(hex2dec('0020000E')));
    otherwise
        %         warning(['DICOM Import has no methods defined for import into the planC{indexS.scan}.' fieldname ' field, leaving empty.']);
end