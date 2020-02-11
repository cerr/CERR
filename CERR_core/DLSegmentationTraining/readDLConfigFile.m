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

%Set defaults for optional inputs
defaultS = struct();
defaultS.exportedFilePrefix = 'inputFileName';
defaultS.crop.method = 'none';
defaultS.resize.size = [];
defaultS.resize.method = 'none';
defaultS.resample.method = 'none';
defaultS.view = {'axial'};
defaultS.channels.imageType = 'original';
defaultS.channels.slice = 'current';
defaultS.batchSize = 1;
defaultS.postProc = [];

optS = userInS;
defC = fieldnames(defaultS);
for n = 1:length(defC)
    if isfield(userInS,defC{n})
        optS.(defC{n}) = userInS.(defC{n});
    else
        optS.(defC{n}) = defaultS.(defC{n});
    end
end



end