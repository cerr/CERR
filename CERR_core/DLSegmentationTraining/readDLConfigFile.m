function optS = readDLConfigFile(paramFilename)
%
% Extract user-input parameters from JSON configuration file and fill in
% default options where required.
%
% AI 9/18/19
% -------------------------------------------------------------------------
% INPUT:
% paramFilename : Path to JSON file with parameters.
%
% Sample JSON configurations available in:
% CERR_core\ModelImplementationLibrary\SegmentationModels\ModelConfigurations
% -------------------------------------------------------------------------

%% Get user inputs from JSON
userInS = jsondecode(fileread(paramFilename));
if ~isfield(userInS,'dataSplit')
    dataSplitV = [0,0,100]; %Assumes testing if not speciifed otherwise.
    userInS.dataSplit = dataSplitV;
end

%% Set defaults for optional inputs
defaultS = struct();
defaultS.modelInputFormat = 'H5';
defaultS.modelOutputFormat = 'H5';
defaultS.register = struct();
defaultS.batchSize = 1;
defaultS.postProc = [];
defaultS.passedScanDim = '3D';
defaultS.filter = struct();
scanModS = struct('warped',0,'filtered',0);
%scanModS(:) = [];
idS.identifier = scanModS;
defaultS.outputAssocScan = idS;

%% Define required sub-fields (general)
defC = fieldnames(defaultS);
reqFieldsC = cell(length(defC),1);
for nField = 1:length(defC)
    if isstruct(defaultS.(defC{nField}))
        reqFieldsC{nField} = fieldnames(defaultS.(defC{nField}));
    else
        reqFieldsC{nField} = 'none';
    end
end

%% Define required sub-fields (model input)
defaultS.input.scan = struct('identifier',idS.identifier,'required','yes',...
    'resample',struct(),'crop',struct(),'resize',struct(),...
    'view',{{'axial'}},'channels',struct());
defaultS.input.scan.crop.method = 'none';
defaultS.input.scan.resize.size = [];
defaultS.input.scan.resize.method = 'none';
defaultS.input.scan.resize.preserveAspectRatio = 'no';
defaultS.input.scan.resample.method = 'none';
defaultS.input.scan.channels.imageType = 'original';
defaultS.input.scan.channels.slice = 'current';
defaultS.exportedFilePrefix = 'inputFileName';

defInputC = fieldnames(defaultS.input);
defaultInS = defaultS.input;
reqInputFieldsC = cell(length(defInputC),1);
for nField = 1:length(defInputC)
    if isstruct(defaultInS.(defInputC{nField}))
        reqInputFieldsC{nField} = fieldnames(defaultInS.(defInputC{nField}));
    else
        reqInputFieldsC{nField} = 'none';
    end
end

%% Read user inputs and populate defaults where missing
optS = populate_user_settings(userInS,defaultS,defC,reqFieldsC);
optInS = populate_user_settings(userInS.input,defaultInS,defInputC,reqInputFieldsC);
optS.input = optInS;

%% ----Supporting functions----
    function optS = populate_user_settings(userInS,defaultS,defC,reqFieldsC)
        optS = userInS;
        for n = 1:length(defC)
            %Check if required fields are present
            if isfield(userInS,defC{n})
                if ~strcmp(reqFieldsC{n},'none')
                    fieldsC = reqFieldsC{n};
                    for m = 1:length(fieldsC)
                        for l = 1:length(userInS.(defC{n}))
                            %If not, populate with defaults
                            if ~isfield(userInS.(defC{n})(l),fieldsC{m})
                                optS.(defC{n})(l).(fieldsC{m}) = defaultS.(defC{n}).(fieldsC{m});
                            end
                        end
                        if isstruct(defaultS.(defC{n}).(fieldsC{m}))
                            reqSubFieldsC = fieldnames(defaultS.(defC{n}).(fieldsC{m}));
                            for k = 1:length(reqSubFieldsC)
                                for j = 1:length(userInS.(defC{n}))
                                    if ~isfield(optS.(defC{n})(j).(fieldsC{m}),reqSubFieldsC{k})
                                        optS.(defC{n})(j).(fieldsC{m}).(reqSubFieldsC{k})= ...
                                            defaultS.(defC{n}).(fieldsC{m}).(reqSubFieldsC{k});
                                    end
                                end
                            end
                        end
                    end
                end
            else
                optS.(defC{n}) = defaultS.(defC{n});
            end
        end

    end

end