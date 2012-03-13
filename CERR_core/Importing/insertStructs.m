function insertStructs()
%
%Insert structures from another study into the currently open study.
%A check is made that the CT matches and the structures are not already in the current study.
%
%Last Modified: 18 March 2007   KU
%               
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

%Start diary and timer for import log.
startTime = now;
tmpFileName = tempname;
diary(tmpFileName);


%Load study containing the structure(s) to be inserted.
if isfield(stateS, 'CERRFile') && ~isempty(stateS.CERRFile)
    if stateS.workspacePlan
        %If workspace plan, ie no directory, use CERR root.
        stateS.CERRFile = fullfile(getCERRPath, 'workspacePlan');                    
    end
    dir = fileparts(stateS.CERRFile);
    wd = cd;
    cd(dir);
    [fname, pathname] = uigetfile('*.mat;*.bz2', ...
    'Select the study containing the structure(s) to insert.','Location',[100,100]);  %at position 100, 100 in pixels.               
    cd(wd);
else
    [fname, pathname] = uigetfile('*.mat;*.bz2', ...
    'Select the study containing the structure(s) to insert.','Location',[100,100]);  %at position 100, 100 in pixels.               
end

if fname == 0
    disp('No file selected.');
    return
end

file = [pathname fname];

[temp_planC] = loadPlanC_temp(fname,file);
temp_planC = updatePlanFields(temp_planC);
temp_indexS = temp_planC{end};

%Check color assignment for displaying structures
[assocScanV,relStrNumV] = getStructureAssociatedScan(1:length(temp_planC{temp_indexS.structures}), temp_planC);
for scanNum = 1:length(temp_planC{temp_indexS.scan})
    scanIndV = find(assocScanV==scanNum);
    for i = 1:length(scanIndV)
        strNum = scanIndV(i);
        colorNum = relStrNumV(strNum);
        if isempty(temp_planC{temp_indexS.structures}(strNum).structureColor)
            color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
            temp_planC{temp_indexS.structures}(strNum).structureColor = color;
        end
    end
end

%check if CT is the same as CT in current study.
try
    if ~isequal(temp_planC{temp_planC{end}.scan}(1).scanArray, planC{planC{end}.scan}(1).scanArray)
        sentence1 = 'CT of selected study does not match CT of current study. No structures can be inserted.';
        Zmsgbox=msgbox(sentence1, 'modal');
        waitfor(Zmsgbox);
        clear temp_planC;
        return
    end
catch
    sentence1 = 'CT of selected study does not match CT of current study. No structures can be inserted.';
    Zmsgbox=msgbox(sentence1, 'modal');
    waitfor(Zmsgbox);
    clear temp_planC;
    return
end

%Check that there are structures in temp_planC.
if isempty(temp_planC{temp_planC{end}.structures})
    sentence1 = 'There are no structures in the selected study.';
    Zmsgbox=msgbox(sentence1, 'modal');
    waitfor(Zmsgbox);
    clear temp_planC;
    return
end

%Find any structures in temp_planC not already in planC.
for i=length(temp_planC{temp_planC{end}.structures}):-1:1
%     newStructName = temp_planC{temp_planC{end}.structures}(i).structureName;
    newStructData = temp_planC{temp_planC{end}.structures}(i).contour;
    for j=1:length(planC{planC{end}.structures})
        oldStructName = planC{planC{end}.structures}(j).structureName;
        oldStructData = planC{planC{end}.structures}(j).contour;
        if isequal(newStructData, oldStructData)
            disp(['Structure "',oldStructName,'" already exists. Duplicate structure will not be inserted.']);
            temp_planC{temp_planC{end}.structures}(i) = [];
            break
        end
    end
end

for i = 1:length(temp_planC{temp_planC{end}.structures})
    newStructList{i} = temp_planC{temp_planC{end}.structures}(i).structureName;
end

if isempty(temp_planC{temp_planC{end}.structures})
    disp('**** No new structures were found in the selected study.');
    sentence1 = 'No new structures were found in the selected study.';
    Zmsgbox=msgbox(sentence1, 'modal');
    waitfor(Zmsgbox);
    clear temp_planC;
    return
else
    numNewStructs = length(temp_planC{temp_planC{end}.structures});
    disp(['**** ',num2str(numNewStructs), ' new structures were found in the selected study.']);
    
    Zquestion=questdlg({'The following additional structures were found and will be inserted into the current study:',...
    '',...          
    newStructList{:}},...
    'Insert Structures?', 'Continue', 'Cancel', 'Continue');
end

if strcmpi(Zquestion, 'Cancel')
    clear temp_planC;
    return
end

if ~isempty(planC{planC{end}.structures})
    %Add identifying number to structure name to indicate the structure set of origin.
    %First find the number of the structure set being added.
    n = 2;
    match = 1;
    while match == 1 && n < 9
        match = 0;
        for k=1:length(planC{planC{end}.structures})
            if strncmp(['(',num2str(n),') '], planC{planC{end}.structures}(k).structureName, 4)
                match = 1; 
                n=n+1;
                break
            end                      
        end
    end

    %Now add new structure set number.
    if n < 9
        for i=1:length(temp_planC{temp_planC{end}.structures})
            structName = temp_planC{temp_planC{end}.structures}(i).structureName;      
            temp_planC{temp_planC{end}.structures}(i).structureName = ['(',num2str(n),') ', structName];
        end
    end
end


scanUID = planC{planC{end}.scan}(1).scanUID;

%Add new structures to planC with required UID fields.
for i=1:length(temp_planC{temp_planC{end}.structures})
    temp_planC{temp_planC{end}.structures}(i).assocScanUID = scanUID;
    temp_planC{temp_planC{end}.structures}(i).strUID = createUID('structure');
    planC{planC{end}.structures} = dissimilarInsert(planC{planC{end}.structures}, temp_planC{temp_planC{end}.structures}(i));
end

%Update structure matrices.
optS = planC{planC{end}.CERROptions};
if strcmpi(optS.createUniformizedDataset, 'yes')
    finish = length(planC{planC{end}.structures});
    start = finish - numNewStructs + 1;
    for structs = start:finish
        planC = updateStructureMatrices(planC, structs);
    end
end

% Add associated scan and structure set UID's to structure array, if necessary.
if isempty(planC{planC{end}.structureArray}.assocScanUID)
    planC{planC{end}.structureArray}.assocScanUID = scanUID;
    planC{planC{end}.structureArrayMore}.assocScanUID = scanUID;
end
if isempty(planC{planC{end}.structureArray}.structureSetUID)
    planC{planC{end}.structureArray}.structureSetUID = createUID('structureset');
    planC{planC{end}.structureArrayMore}.structureSetUID = planC{planC{end}.structureArray}.structureSetUID;
end

stateS.structsChanged = 1;
sliceCallBack('refresh')

display(['The structure(s) from study ', fname, ' have been added to the current study.'])

sentence1 = horzcat('The new structures have been added to the current study. ',...
    'The changes have not been saved.  Please remember to save changes ',...
    'before closing the study.');
Zmsgbox=msgbox(sentence1, 'modal');
waitfor(Zmsgbox); 

        
%Stop diary and write it to planC.
diary off;
endTime = now;
logC = file2cell(tmpFileName);
delete(tmpFileName);
indexS = planC{end};

temp_planC{temp_planC{end}.importLog} = [];
temp_planC{temp_planC{end}.importLog}.importLog = logC;
temp_planC{temp_planC{end}.importLog}.startTime = datestr(startTime);
temp_planC{temp_planC{end}.importLog}.endTime = datestr(endTime);

planC{indexS.importLog} = [planC{indexS.importLog}, temp_planC{temp_planC{end}.importLog}];

clear temp_planC;
