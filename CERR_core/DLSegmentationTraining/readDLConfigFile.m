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
userInS = loadjson(paramFilename)
if ~isfield(userInS,'dataSplit')
    dataSplitV = [0,0,100]; %Assumes testing if not speciifed otherwise.
    userInS.dataSplit = dataSplitV;
end

%% Set defaults for optional inputs
defaultS = struct();
defaultS.exportedFilePrefix = 'inputFileName';
defaultS.crop.method = 'none';
defaultS.resize.size = [];
defaultS.resize.method = 'none';
defaultS.resize.method = 'none';
defaultS.resize.preserveAspectRatio = 'no';
defaultS.resample.method = 'none';
defaultS.view = {'axial'};
defaultS.channels.imageType = 'original';
defaultS.channels.slice = 'current';
defaultS.batchSize = 1;
defaultS.postProc = [];

%% Define required sub-fields
defC = fieldnames(defaultS);
reqSubFieldsC = cell(length(defC),1);
for n = 1:length(defC)
    if isstruct(defaultS.(defC{n}))
        reqSubFieldsC{n} = fieldnames(defaultS.(defC{n}));
    else
        reqSubFieldsC{n} = 'none';
    end
end

%% Read user inputs and populate defaults where missing
optS = userInS;
for n = 1:length(defC)
    if isfield(userInS,defC{n})
        if ~strcmp(reqSubFieldsC{n},'none')
            fieldsC = reqSubFieldsC{n};
            for m = 1:length(fieldsC)
                if ~isfield(userInS.(defC{n}),fieldsC{m})
                    optS.(defC{n}).(fieldsC{m}) = defaultS.(defC{n}).(fieldsC{m});
                end
            end
        end
    else
        optS.(defC{n}) = defaultS.(defC{n});
    end
end



end