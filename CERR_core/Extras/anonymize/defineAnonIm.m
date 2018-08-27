function anonImS = defineAnonIm()
%
% function anonImS = defineAnonGsps()
%
% Defines the anonymous "IM" data structure. The fields containing PHI have
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


IMSetup = struct(...
    );
isocenterS = struct(...
    'x', 'keep', ...
    'y', 'keep', ...
    'z', 'keep' ...
    );
CTTraceS = struct(...
    'CTNumsRay', 'keep', ...
    'CTCumNumsRay', 'keep', ...
    'distSamplePts', 'keep', ...
    'densityRay', 'keep', ...
    'cumDensityRay', 'keep' ...
    );
beamletS = struct(...
      'structureName',  'keep', ... 'GTV_1'
             'format',  'keep', ... 'uint8'
          'influence',  'keep', ... [777×1 uint8]
            'beamNum',  'keep', ... 1
         'fullLength',  'keep', ... 10999
             'indexV',  'keep', ... [777×1 uint32]
    'maxInfluenceVal',  'keep', ... 0.9484
      'lowDosePoints',  'keep', ... [1×98 uint8]
         'sampleRate',  'keep', ... 2
             'strUID',  'keep' ... 'RS.962017.165054.6162800.2805'
    );
beamS = struct(...
         'beamNum',  'keep', ... 1
         'beamModality',  'keep', ... 'photons'
           'beamEnergy',  'keep', ... 6
            'isocenter',  isocenterS, ... [1×1 struct]
          'isodistance',  'keep', ... 100
             'arcAngle',  'keep', ... 0
           'couchAngle',  'keep', ... 0
      'collimatorAngle',  'keep', ... 0
          'gantryAngle',  'keep', ... 0
      'beamDescription',  'keep', ... 'IM beam'
       'beamletDelta_x',  'keep', ... 1
       'beamletDelta_y',  'keep', ... 1
       'dateOfCreation',  'date', ... '05-Feb-2018'
             'beamType',  'keep', ... 'IM'
                 'zRel',  'keep', ... 0
                 'xRel',  'keep', ... 0
                 'yRel',  'keep', ... 100
            'sigma_100',  'keep', ... 0.4000
               'CTUsed',  'keep', ... []
              'PBMaskM',  'keep', ... []
       'RTOGPBVectorsM',  'keep', ... [61×3 double]
    'RTOGPBVectorsM_MC',  'keep', ... [61×3 double]
              'beamUID',  'keep', ... 'BM.522018.175010.29123.3189'
             'beamlets',  beamletS, ... [1×61 struct]
               'colPBV',  'keep', ... [61×1 double]
               'rowPBV',  'keep', ... [61×1 double]
              'xPBPosV',  'keep', ... [1×61 double]
              'yPBPosV',  'keep', ... [1×61 double]
             'CTTraceS',  CTTraceS, ... [1×61 struct]
                    'x',  'keep', ... 33.4908
                    'y',  'keep', ... 68.9712
                    'z',  'keep' ... 2.9138
    );
IMDosimetry = struct(...
           'beams',  beamS, ... 
           'goals',  'keep', ... 
       'solutions',  'keep', ... 
          'params',  'keep', ... 
    'assocScanUID',  'keep', ... 
            'name',  'keep', ... 
         'isFresh',  'keep'... 
    );

anonImS = struct( ...
    'IMSetup',  'keep', ...
    'IMDosimetry',  IMDosimetry, ...
    'IMUID',  'keep' ...
           );
