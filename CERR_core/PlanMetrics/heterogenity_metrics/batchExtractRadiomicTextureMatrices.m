function [textureC, errC] = batchExtractRadiomicTextureMatrices(dirName,paramFileName)
% Extract radiomic texture matrices for a cohort of CERR files.
%--------------------------------------------------------------------------
% INPUTS
% dirName       : Path to directory with CERR-format files.
% paramFilename : Path to JSON config file
%
% OUTPUT
% textureC      : Cell array containing texture matrices for the cohort,
%                 that can be extracted using: 
%                 textureM = textureC{ptNum}.(imageType).(textureClass);          
%--------------------------------------------------------------------------
% AI 4/14/2020


% Iterate over all CERR-format files in input dir
dirS = dir([dirName,filesep,'*.mat']);
nameC = {dirS.name};
textureC = cell(length(nameC),1);

errC = {};
count = 0;
for planNum = 1:length(nameC)
    
    try
        
        %Load plan
        fileNam = fullfile(dirName,[nameC{planNum}]);
        planC = loadPlanC(fileNam, tempdir);
        planC = updatePlanFields(planC);
        planC = quality_assure_planC(fileNam,planC);
        
        %Calc texture matrices
        textureS = calcGlobalRadiomicTextureMatrices(paramFileName, planC);
        textureC{planNum} = textureS;
        
    catch e
        
        %Record error msg.
        count = count + 1;
        errC{count} =  [ fileNam,' failed with message ', e.message];
        
    end
    
end