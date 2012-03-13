function [CTmaterial materialNames] = generateMaterialMap(CTdensity, materialMap);

% JC Feb 2007
% Assign material numbers based on the density (g/cm3).
% Use to show material numbers/names in CERR GUI.

% Usage: 
% [CTmaterial] = generateMaterialMap(materialMap, planC, scanNumber);

% output: 
    % CTmaterial := same size as the uniformized CT scan, containing
    % material numbers.
    % materialNames := defined material names: eg. 'Air'    'Lung'
    % 'Water'    'Bone'
    
% input:    
% >> materialMap(1)
% ans = 
%           name: 'Air'
%     minDensity: 0
%     maxDensity: 0.0500
    


CTmaterial = zeros(size(CTdensity));
materialNames = cell(size(materialMap));

for i = 1 : length(materialMap),
    CTmaterial(materialMap(i).minDensity <= CTdensity & CTdensity < materialMap(i).maxDensity) = i;
    materialNames{i} = getfield(materialMap, {1,i}, 'name');
end

% If CTmaterial still has "0" elements, it means that the "materialMap"
% doesn't cover the whole CT values.
x = ismember(unique(CTmaterial), [1:length(materialMap)]);
if ismember(0,x)
warning('Input materialMap does NOT cover the whole CT scan values. Please check the CT values for voxels with "0" material number')
end

return;



