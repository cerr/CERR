function optS = getCERROptions

% Read build paths and options from CERROptions.json
optName = fullfile(getCERRPath,'CERROptions.json');
optS = opts4Exe(optName);
