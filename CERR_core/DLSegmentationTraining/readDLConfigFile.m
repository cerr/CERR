function optS = readDLConfigFile(paramFilename)
%
% Extract user-input parameters from JSON configuration file and fill in
% default options where required.
%
% AI 9/18/19
% -------------------------------------------------------------------------
% INPUT:
% paramFilename : Path to JSON file with parameters.
% -------------------------------------------------------------------------

%% Get user inputs from JSON
userInS = jsondecode(fileread(paramFilename));
if ~isfield(userInS,'dataSplit')
    dataSplitV = [0,0,100]; %Assumes testing if not speciifed otherwise.
    userInS.dataSplit = dataSplitV;
end

%% Set defaults for optional inputs
defaultS = struct();
defaultS.register = struct();
defaultS.exportedFilePrefix = 'inputFileName';
defaultS.batchSize = 1;
defaultS.postProc = [];
defaultS.passedScanDim = '3D';
idS.identifier = struct();
defaultS.structAssocScan = idS; 
defaultS.scan = struct('identifier',idS.identifier,'resample',struct(),...
    'crop',struct(),'resize',struct(),'view',{{'axial'}},'channels',struct());
defaultS.scan.crop.method = 'none';
defaultS.scan.resize.size = [];
defaultS.scan.resize.method = 'none';
defaultS.scan.resize.preserveAspectRatio = 'no';
defaultS.scan.resample.method = 'none';
defaultS.scan.channels.imageType = 'original';
defaultS.scan.channels.slice = 'current';


%% Define required sub-fields
defC = fieldnames(defaultS);
reqFieldsC = cell(length(defC),1);
for n = 1:length(defC)
    if isstruct(defaultS.(defC{n}))
        reqFieldsC{n} = fieldnames(defaultS.(defC{n}));
    else
        reqFieldsC{n} = 'none';
    end
end

%% Read user inputs and populate defaults where missing
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