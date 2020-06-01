function ddbs = select_outcomes(ddbs)
%function ddbs = select_outcomes(ddbs)
%
%This function populates outcomes from Excel file into the ddbs structure
%
%APA, 12/24/2009
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

try
    %Get Excel File
    [fName,pName] = uigetfile('.xls','Select Excel file containing data');
    if isnumeric(fName)
        return;
    end
    xlFile = fullfile(pName,fName);
    [num,txt,raw] = xlsread(xlFile);
    
    columnNameRawC = {};
    indNaN = [];
    for i = 1:length(raw(1,:))
        if ~isnan(raw{1,i})
            columnNameRawC{end+1} = raw{1,i};
        else
            indNaN = [indNaN i];
        end
    end
    
    raw(:,indNaN) = [];
    
    %Get FileNames to match with DVH extraction    
    [selIndFileName, OK] = listdlg('ListString',columnNameRawC,'PromptString','Select Column containing CERR fileNames');
    if OK && (length(selIndFileName) == 1)
        rowIndicesV = [];
        for j=1:size(raw,1)-1
            if ~isnan(raw{j+1,selIndFileName})
                excel_fileNameC{j} = raw{j+1,selIndFileName};
                rowIndicesV = [rowIndicesV j];
            end
        end
    else
        error('Please select ONE column and try again')
    end
    
    ddbs_fileNameC = {ddbs(:).fileName};
    ddbs_fileNameC = strtok(ddbs_fileNameC,'.');
    
    [jnk,indexMapV] = ismember(ddbs_fileNameC,excel_fileNameC);

    %replace spaces with underscores
    for i=1:size(raw,2)
        raw{1,i} = repSpaceHyp(raw{1,i});
    end

%     %removes columns with non-numeric data
%     indToRemove  = [];
%     for i=1:size(raw,2)
%         if ~isnumeric([raw{2:size(raw,1),i}]) || all(isnan([raw{2:size(raw,1),i}]))
%             indToRemove = [indToRemove i];
%         end
%     end
%     raw(:,indToRemove) = [];

    %get variables from the selection list
    [selMetricsIndV, OK] = listdlg('ListString',raw(1,:),'PromptString','Select Metrics');
    
    %get outcome from the selection list
    [selOutcomesIndV, OK] = listdlg('ListString',raw(1,:),'SelectionMode','single','PromptString','Select Outcome');    

    %set variable fields
    for i=1:length(selMetricsIndV)     
        for j = 1:length(indexMapV)
            if isnumeric(raw{indexMapV(j)+1,selMetricsIndV(i)})
                ddbs(j).(raw{1,selMetricsIndV(i)}) = raw{indexMapV(j)+1,selMetricsIndV(i)};
            else
                ddbs(j).(raw{1,selMetricsIndV(i)}) = NaN;
            end
        end
    end

    %set outcomes field
    for i=1:length(selOutcomesIndV)
        for j = 1:length(indexMapV)
            if isnumeric(raw{indexMapV(j)+1,selOutcomesIndV(i)})
                ddbs(j).outcome.(raw{1,selOutcomesIndV(i)}) = raw{indexMapV(j)+1,selOutcomesIndV(i)};
            else
                ddbs(j).outcome.(raw{1,selOutcomesIndV(i)}) = NaN;
            end
        end        
    end

catch
    errordlg('There was an errror reading the DVH data. Please check the data format and try again.','DVH Import error','modal')
end

return;


% --------- supporting sub-functions
function str = repSpaceHyp(str)
indSpace = strfind(str,' ');
indDot = strfind(str,'.');
str(indDot) = [];
indOpenParan = strfind(str,'(');
indCloseParan = strfind(str,')');
indToReplace = [indSpace indOpenParan indCloseParan];
str(indToReplace) = '_';
indGreaterThan = strfind(str,'>');
indLessThan = strfind(str,'<');
str(indGreaterThan) = 'G';
str(indLessThan) = 'L';
return;
