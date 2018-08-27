function anonCERROptionsS = defineAnonCerroptions()
%
% function anonCERROptionsS = defineAnonCerroptions()
%
% Defines the anonymous "CERROptions" data structure. The fields containing PHI have
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

anonCERROptionsS = struct( ...
                                 'loadCT',  'keep', ... 'yes'
                            'loadDoseSet',  'keep', ... 'any'
                         'loadStructures',  'keep', ... {'any'}
                               'CTEndian',  'keep', ... 'big'
                               'loadFilm',  'keep', ... 'none'
                                'zipSave',  'keep', ... 'yes'
                         'scanStructures',  'keep', ... {'any'}
                    'DSHMaxPointInterval',  'keep', ... 0.2000
                       'surfPtStructures',  'keep', ... {''}
                   'downsampleLargeDoses',  'keep', ... 'yes'
                      'doseSizeThreshold',  'keep', ... 100
                       'promptForNewSize',  'keep', ... 'no'
                   'downsampledVoxelSize',  'keep', ... [0.2000 0.2000 0.3000]
                     'importDICOMsubDirs',  'keep', ... 'no'
               'createUniformizedDataset',  'keep', ... 'yes'
               'uniformizeExcludeStructs',  'keep', ... {'normaltissue'  'CT_EXTERNAL'}
                    'uniformizedDataType',  'keep', ... 'uint16'
                 'structureArrayDataType',  'keep', ... 'uint32'
        'lowerLimitUniformCTSliceSpacing',  'keep', ... 0.0050
        'upperLimitUniformCTSliceSpacing',  'keep', ... 10
    'alternateLimitUniformCTSliceSpacing',  'keep', ... 0.3000
                              'useOpenGL',  'keep', ... 1
                       'isodoseLevelMode',  'keep', ... 'auto'
                          'isodoseLevels',  'keep', ... [70 65 60 55 50 45 40 20 10]
                      'autoIsodoseLevels',  'keep', ... 6
                   'autoIsodoseRangeMode',  'keep', ... 1
                       'autoIsodoseRange',  'keep', ... [0 100]
                       'isodoseLevelType',  'keep', ... 'absolute'
                     'isodoseUseColormap',  'keep', ... 1
                       'isodoseThickness',  'keep', ... 1
                     'structureThickness',  'keep', ... 2
                          'structureDots',  'keep', ... 1
                         'displayDoseSet',  'keep', ... ''
                'doseInterpolationMethod',  'keep', ... 'linear'
                           'tickInterval',  'keep', ... 1
                                'CTLevel',  'keep', ... 0
                                'CTWidth',  'keep', ... 300
                               'fontsize',  'keep', ... 8
                                'UIColor',  'keep', ... [0.9000 0.9000 0.9000]
                             'colorOrder',  'keep', ... [28×3 double]
                'contourToSliceTolerance',  'keep', ... 0.0050
                       'inactiveSegStyle',  'keep', ... '--'
                         'activeSegStyle',  'keep', ... '-'
                     'displayPatientName',  'keep', ... 0
                       'initialZoomTrans',  'keep', ... 1.7000
                         'initialZoomSag',  'keep', ... 1
                         'initialZoomCor',  'keep', ... 1
                             'zoomFactor',  'keep', ... 2
                           'dosePlotType',  'keep', ... 'colorwash'
                           'doseColormap',  'keep', ... 'starinterp'
                             'CTColormap',  'keep', ... 'gray256'
                        'colorbarChoices',  'keep', ... {1×15 cell}
                         'staticColorbar',  'keep', ... 0
                            'colorbarMin',  'keep', ... ''
                            'colorbarMax',  'keep', ... ''
                    'transparentZeroDose',  'keep', ... 1
                    'doubleSidedColorbar',  'keep', ... 0
                        'negativeTexture',  'keep', ... 1
                          'colorbarMarks',  'keep', ... []
                  'visualRefColormapRows',  'keep', ... 256
                   'visualRefTopColormap',  'keep', ... 'grayud64'
                'visualRefBottomColormap',  'keep', ... 'full2'
                          'visualRefDose',  'keep', ... 65
                      'visualRefDoseMode',  'keep', ... 'off'
                    'initialTransparency',  'keep', ... 0.5000
                 'calcDoseInsideSkinOnly',  'keep', ... 0
                'CERRStatusStringEnabled',  'keep', ... 1
                      'fusionDisplayMode',  'keep', ... 'colorblend'
                        'fusionCheckSize',  'keep', ... 2
                       'fusionAlgorithms',  'keep', ... {1×6 cell}
                        'fusionTemplates',  'keep', ... {1×6 cell}
              'visual3DxyDownsampleIndex',  'keep', ... 128
                  'numDoseProfileSamples',  'keep', ... 200
                          'ROISampleRate',  'keep', ... 1
                            'DVHBinWidth',  'keep', ... 0.2000
                           'DVHBlockSize',  'keep', ... 5000
                           'DVHLineWidth',  'keep', ... 1.5000
                            'IVHBinWidth',  'keep', ... 0.0500
                           'IVHBlockSize',  'keep', ... 5000
                           'IVHLineWidth',  'keep', ... 1.5000
                        'defaultVOINames',  'keep', ... {1×21 cell}
                          'nudgeDistance',  'keep', ... 0.5000
              'navigationMontageColormap',  'keep', ... 'grayCenter0Width300'
              'navigationMontageOnImport',  'keep', ... 'no'
                      'navigationMontage',  'keep', ... 'no'
             'wavletcompresthreshpersent',  'keep', ... 1
           'wavletcompressiondecomplevel',  'keep', ... 5
                    'IMRTCheckResolution',  'keep', ... 'on'
          'IMRTDoseCalculationAlgorithms',  'keep', ... {'QIB'  'VMC++'}
           'IMRTDoseCalculationTemplates',  'keep', ... {@getQIBTemplate  @getVMCTemplate}
            'IMRTDoseCalculationFunction',  'keep', ... {@generateQIBInfluence  @generateVMCInfluence}
         'IMRTScatterReductionAlgorithms',  'keep', ... {'Exponential'  'Probabilistic'  'Threshold'  'None'}
          'IMRTScatterReductionTemplates',  'keep', ... {1×4 cell}
            'IMRTAutoIsocenterAlgorithms',  'keep', ... {'GeometricCOM'  'Manual'}
             'IMRTAutoIsocenterFunctions',  'keep', ... {@isocenterGeometricCOM  @isocenterManual}
                            'planMetrics',  'keep', ... {1×11 cell}
                          'windowPresets',  'keep', ... [1×11 struct]
                           'scanColorMap',  'keep', ... [1×7 struct]
                         'cachingEnabled',  'keep', ... 0
                     'colorWashCacheSize',  'keep', ... 64
                             'saveFormat',  'keep', ... '-v6'
                          'plotObjFormat',  'keep', ... 'v6'
                             'chkMicroRT',  'keep', ... 0
                           'CompressType',  'keep', ... 'bz2'
                                 'format',  'keep', ... 'DICOM'
                                 'layout',  'keep', ... 5
                           'logOnStartup',  'keep', ... 0
                       'tmpDecompressDir',  'keep', ... ''
                     'ROIInterpretedType',  'keep', ... [1×1 struct]
                     'convert_PET_to_SUV',  'keep', ... 1
                    'overwrite_CERR_File',  'keep', ... 0
                 'sinc_filter_on_display',  'keep', ... 1
               'plastimatch_command_file',  'keep', ... 'bspline_register_cmd_atlasSeg.txt'
                           'linePoolSize',  'keep' ... 300
           );
