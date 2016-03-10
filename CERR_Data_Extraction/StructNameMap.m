function [infoS, doseMapS] = StructNameMap(dirPath,structures_to_extract,dose_to_extract,waitbarH,statusStrH)
%structNameMap.m
%Scan all CERR plans under dirPath and map structure-names to standard
%
%APA, 4/13/09
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

global planC stateS
if isempty(stateS) || ~isfield(stateS,'optS')
    stateS.optS = opts4Exe(fullfile(getCERRPath,'CERROptions.m'));
end

tic
% dirPath = 'I:\3dplans\Reference_plans\plans_dearchived\prostate';
% structures_to_extract = {'Prostate','Prostate Bed','Skin'};
% dose_to_extract = 'Final';
% dirInfoS = dir(dirPath);
% %get directories
% isDirV = [dirInfoS.isdir];
% dirInfoS = dirInfoS(isDirV);
% dirInfoS = dirInfoS(3:end);
infoS = struct('fullFileName','','structMap','','allStructureNames','','doseMap','','allDoseNames','','error','');
infoS(1) = [];

% for i = 1:3%length(dirInfoS)
%     disp(['Plan ',num2str(i)])
    %Find all CERR files
    fileC = {};    
    if strcmpi(dirPath,'\') || strcmpi(dirPath,'/')
        filesTmp = getCERRfiles(dirPath(1:end-1));
    else
        filesTmp = getCERRfiles(dirPath);
    end
    fileC = [fileC filesTmp];
    
    doseMapInitS = struct('DosesToSum',[],'NewDoseName','','AdjustmentType',1,...
        'maxDose',{[]},'save_to_disk',0, 'd',[], 'abRatio',[]);

    %Load CERR plan
    for iFile=1:length(fileC)
        
        drawnow
        set(waitbarH,'position',[0.05 0.18 0.9*iFile/length(fileC) 0.04])
        set(statusStrH,'string',['Loading ',int2str(iFile),' out of ',int2str(length(fileC))])
        
        fileNum = length(infoS)+1;

        try            
            planC = loadPlanC(fileC{iFile},tempdir);
            planC = updatePlanFields(planC);
            % Quality assure
            quality_assure_planC(fileC{iFile},planC);
        catch
            disp([fileC{iFile}, ' failed to load'])
            infoS(fileNum).error = 'Failed to Load';
            continue
        end

        indexS = planC{end};        
        
        infoS(fileNum).fullFileName = fileC{iFile};
        
        for i=1:length(structures_to_extract)
            structMap{i} = getMatchingIndex(structures_to_extract{i},{planC{indexS.structures}.structureName},'exact');
            if isempty(structMap{i})
                structMap{i} = getMatchingIndex(structures_to_extract{i},{planC{indexS.structures}.structureName},'firstchars');
                if isempty(structMap{i})
                    structMap{i} = getMatchingIndex(structures_to_extract{i},{planC{indexS.structures}.structureName},'regex');
                end
            end
        end
        %infoS(fileNum).structMap = {structMap{1}(1)};        
        infoS(fileNum).structMap = structMap;
 
        if length(planC{indexS.dose}) == 1
            infoS(fileNum).doseMap = 1;
        else
            infoS(fileNum).doseMap = getMatchingIndex(dose_to_extract,{planC{indexS.dose}.fractionGroupID},'exact');
            if isempty(infoS(fileNum).doseMap)
                infoS(fileNum).doseMap = getMatchingIndex(dose_to_extract,{planC{indexS.dose}.fractionGroupID},'firstchars');
                if isempty(infoS(fileNum).doseMap)
                    infoS(fileNum).doseMap = getMatchingIndex(dose_to_extract,{planC{indexS.dose}.fractionGroupID},'regex');
                end
            end
        end
        % infoS(fileNum).doseMap = getMatchingIndex(dose_to_extract,{planC{indexS.dose}.fractionGroupID});

        infoS(fileNum).allStructureNames = {planC{indexS.structures}.structureName};
        
        infoS(fileNum).allDoseNames = {planC{indexS.dose}.fractionGroupID};    
        
        doseMapS(fileNum) = doseMapInitS;
        
        if length(planC{indexS.dose})==0 && length(planC{indexS.structures})==0
            infoS(fileNum).error = 'No Dose and Structure present';
            continue
        end

        if length(planC{indexS.dose})==0
            infoS(fileNum).error = 'No Dose present';
            continue
        end

        if length(planC{indexS.structures})==0
            infoS(fileNum).error = 'No Structure present';
            continue
        end
        
        %Get Max dose
        for doseNum = 1:length(planC{indexS.dose})
            doseArrayM = getDoseArray(doseNum,planC);
            maxDoseC{doseNum} = max(doseArrayM(:));
        end
        
        doseMapS(fileNum).maxDose = maxDoseC;
        
    end
    
    set(statusStrH,'string','Directory scanned! Proceed to Sum Doses.')

% end

toc

%Launch GUI for correcting structure names
%structureNameMapGUI('init',infoS,structures_to_extract,dose_to_extract)

return;

