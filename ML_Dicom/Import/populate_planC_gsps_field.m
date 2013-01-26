function dataS = populate_planC_gsps_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_GSPS, gspsNum, dcmobj)
%"populate_planC_gsps_field"
%   Given the name of a child field to planC{indexS.GSPS}, populates that
%   field based on the data contained in dcmdir.PATIENT.STUDY.SERIES.PR
%   gsps object passed in, for GSPS object number gspsNum.
%
%APA, 01/25/2013
%
%Usage:
%   dataS = populate_planC_gsps_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_GSPS, gspsNum, dcmobj)
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

GSPS = dcmdir_PATIENT_STUDY_SERIES_GSPS;

%Default value for undefined fields.
dataS = '';

if ~exist('dcmobj', 'var')
    %Grab the dicom object representing the structures.
    dcmobj = scanfile_mldcm(GSPS.file);
end

% Graphical Annotation Sequence
GSPSseq = dcmobj.get(hex2dec('00700001'));

%Count em up.
nGsps = GSPSseq.countItems;

%Structure Set item for this structure.
annotObj = GSPSseq.getDicomObject(gspsNum - 1);

switch fieldname

    case 'SOPInstanceUID'
        %Referenced Image Sequence
        refImageSeq = annotObj.get(hex2dec('00081140'));
        refImageObj = refImageSeq.getDicomObject(0); % Assuming only one image reference.
        dataS = dcm2ml_Element(refImageObj.get(hex2dec('00081155')));
        
        
    case 'graphicAnnotation'
        %Graphic Object Sequence
        graphicObjSeq = annotObj.get(hex2dec('00700009'));

        if isempty(graphicObjSeq)
            return;
        end

        numGraphicAnnot = graphicObjSeq.countItems;
        
        graphicAnnotation(1:numGraphicAnnot) = struct();
        for i = 1:numGraphicAnnot
            aGraphicAnnot = graphicObjSeq.getDicomObject(i-1);
            graphicAnnotation(i).graphicAnnotationUnits   = dcm2ml_Element(aGraphicAnnot.get(hex2dec('00700005')));
            graphicAnnotation(i).graphicAnnotationDims    = dcm2ml_Element(aGraphicAnnot.get(hex2dec('00700020')));
            graphicAnnotation(i).graphicAnnotationNumPts  = dcm2ml_Element(aGraphicAnnot.get(hex2dec('00700021')));
            graphicAnnotation(i).graphicAnnotationData    = dcm2ml_Element(aGraphicAnnot.get(hex2dec('00700022')));
            graphicAnnotation(i).graphicAnnotationType    = dcm2ml_Element(aGraphicAnnot.get(hex2dec('00700023')));
            graphicAnnotation(i).graphicAnnotationFilled  = dcm2ml_Element(aGraphicAnnot.get(hex2dec('00700024')));            
        end
        
        dataS = graphicAnnotation;
        

    case 'textAnnotation'
        %Text Object Sequence
        textObjSeq = annotObj.get(hex2dec('00700008'));

        if isempty(textObjSeq)
            return;
        end

        numTextAnnot = textObjSeq.countItems;
        
        textAnnotation(1:numTextAnnot) = struct();
        
        for i = 1:numTextAnnot
            aTextAnnot = textObjSeq.getDicomObject(i-1);
            textAnnotation(i).boundingBoxAnnotationUnits                = dcm2ml_Element(aTextAnnot.get(hex2dec('00700003')));
            textAnnotation(i).anchorPtAnnotationUnits                   = dcm2ml_Element(aTextAnnot.get(hex2dec('00700004')));
            textAnnotation(i).unformattedTextValue                      = dcm2ml_Element(aTextAnnot.get(hex2dec('00700006')));            
            textAnnotation(i).boundingBoxTopLeftHandCornerPt            = dcm2ml_Element(aTextAnnot.get(hex2dec('00700010')));            
            textAnnotation(i).boundingBoxBottomRightHandCornerPt        = dcm2ml_Element(aTextAnnot.get(hex2dec('00700011')));            
            textAnnotation(i).boundingBoxTextHorizontalJustification    = dcm2ml_Element(aTextAnnot.get(hex2dec('00700012')));            
            textAnnotation(i).anchorPoint                               = dcm2ml_Element(aTextAnnot.get(hex2dec('00700014')));            
            textAnnotation(i).anchorPointVisibility                     = dcm2ml_Element(aTextAnnot.get(hex2dec('00700015')));                        
        end
        
        dataS = textAnnotation;
                

end
