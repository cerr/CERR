function[outStrListC,labelMapS] = getAutosegStructnames(labelPath,userOptS)
%function[outStrListC,labelMapS] = getAutosegStructnames(userOptS)
% Returns user-defined names for auto-segmented structures.
%--------------------------------------------------------------------------
% INPUTS
% labelPath : Directory containing JSON with structure name-to-label map.
% userOptS  : Dictionary of configurations genrated from JSON input. 
%             See readDLConfigFile.m for additonal details.
%--------------------------------------------------------------------------
% AI 9/24/21

%% Get structure name-to-label map
labelMapS = userOptS.strNameToLabelMap;
if ischar(labelMapS)
% Handle dynamically-generated maps
    labelMapFileName = fullfile(labelPath,labelMapS);
    valS = jsondecode(fileread(labelMapFileName));
    labelMapS = valS.strNameToLabelMap;
end

%% Return output structure names
outStrListC = {labelMapS.structureName};


end