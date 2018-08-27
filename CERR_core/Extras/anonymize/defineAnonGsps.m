function anonGspsS = defineAnonGsps()
%
% function anonFeatureSetS = defineAnonGsps()
%
% Defines the anonymous "GSPS" data structure. The fields containing PHI have
% been left out by default. In order to leave out additional fields, remove
% them from the list below. 
%
% The following three operations are allowed per field of the input data structure:
% 1. Keep the value as is: listed as 'keep' in the list below.
% 2. Allow only the specific values: permitted values listed within a cell array. 
%    If no match is found, a default anonymous string will be inserted.
% 3. Insert dummy date: listed as 'date' in the list below. Date will be
%    replaced by a dummy value of 11/11/1111.
%
% APA, 1/11/2018

anonGraphicAnnotationS = struct(...
     'graphicAnnotationUnits',  'keep', ... 'PIXEL'
      'graphicAnnotationDims',  'keep', ... 2
    'graphicAnnotationNumPts',  'keep', ... 2
      'graphicAnnotationData',  'keep', ... [4×1 single]
      'graphicAnnotationType',  'keep', ... 'POLYLINE'
    'graphicAnnotationFilled',  'keep' ... 'N'
    );
anonTextAnnotationS = struct(...
                'boundingBoxAnnotationUnits',  'keep', ... 'PIXEL'
                   'anchorPtAnnotationUnits',  'keep', ... 'PIXEL'
                      'unformattedTextValue',  'keep', ... ''
            'boundingBoxTopLeftHandCornerPt',  'keep', ... [2×1 single]
        'boundingBoxBottomRightHandCornerPt',  'keep', ... [2×1 single]
    'boundingBoxTextHorizontalJustification',  'keep', ... 'LEFT'
                               'anchorPoint',  'keep', ... [2×1 single]
                     'anchorPointVisibility',  'keep' ... 'Y'
    );
anonGspsS = struct( ...
    'SOPInstanceUID',  'keep', ...
    'graphicAnnotationS',  anonGraphicAnnotationS, ...
    'textAnnotationS',  anonTextAnnotationS, ...
    'presentLabel',  'keep', ...
    'presentDescription',  'keep', ...
    'presentCreationDate',  'keep', ...
    'annotUID',  'keep' ...
           );
