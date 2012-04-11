function planC = ImportDVH(command, planC)
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

%global planC;

indexS = planC{end};

if isempty(planC), return; end;
try cd(command);
catch
end;
% read DVH
[FileName,PathName] = uigetfile({'*.*','All files (*.*)';}, sprintf('Loading DVH files'), 'MultiSelect', 'on');
if isequal(FileName,0), return ; end;

scSize = get(0,'ScreenSize');
x = 220; y = 120;
setupDlg = figure('Name','DVH Data Type','NumberTitle','off', ...
    'Position',[(scSize(3)-x)/2, (scSize(4)-y)/2, x, y], 'windowstyle', 'modal');
h = uibuttongroup();
u0 = uicontrol('Style','Radio','String','differential', 'pos',[10 80 100 30],'parent',h,'HandleVisibility','off');
u1 = uicontrol('Style','Radio','String','cumulative', 'pos',[10 40 100 30],'parent',h,'HandleVisibility','off');
u2 = uicontrol('Style','pushbutton','String','Continue', 'pos',[110 10 100 20],'parent',setupDlg,'HandleVisibility','off', ...
    'callback', @continue_callback);
uiwait(setupDlg);
    function continue_callback(source, eventdata)
        so = get(h,'selectedObject');
        if isequal(so, u0)
            setappdata(findobj('tag', 'CERRStartupFig'), 'dvhVolumeType', get(u0, 'string'));
        else
            setappdata(findobj('tag', 'CERRStartupFig'), 'dvhVolumeType', get(u1, 'string'));

        end
        close;
    end

volumeType = getappdata(findobj('tag', 'CERRStartupFig'), 'dvhVolumeType');

if iscell(FileName)
    fileCount = length(FileName);
else
    fileCount = 1;
end;

DVHIndex = length(planC{indexS.DVH}) + 1;

for i = 1:fileCount
    if iscell(FileName)
        dvhFileName = fullfile(PathName, FileName{i});
    else
        dvhFileName = fullfile(PathName, FileName);
    end

    [pathstr, name, ext] = fileparts(dvhFileName);
    name = [name,'.',ext];
    strName = ext(2:end);
    indName = strfind(name, '.');
    doseName = name((indName(end-1)+1):end);
    doseIndex = 1;
    for j=1:length(planC{indexS.dose})
        if isequal(doseName, planC{indexS.dose}(j).fractionGroupID)
            doseIndex = j;
            break;
        end
    end

    try
        [doseBinsV, doseHistV] = readDVHfile(dvhFileName);
    catch
        continue;
    end

    %     doseIndex = stateS.doseSet;
    planC{indexS.DVH}(DVHIndex).volumeType      = volumeType;
    planC{indexS.DVH}(DVHIndex).doseType        = 'plunc';
    planC{indexS.DVH}(DVHIndex).doseUnits        = 'cGy';
    planC{indexS.DVH}(DVHIndex).structureName   = strName;
    planC{indexS.DVH}(DVHIndex).doseIndex       = doseIndex;

    strNum = '';
    for j = 1:length(planC{indexS.structures})
        if  strcmp(upper(strName), upper(planC{indexS.structures}(j).structureName))
            strNum = j;
            break;
        end
    end
    planC{indexS.DVH}(DVHIndex).assocStrUID=planC{indexS.structures}(strNum).strUID;
    planC{indexS.DVH}(DVHIndex).dvhUID = createUID('dvh');
    planC{indexS.DVH}(DVHIndex).assocDoseUID = planC{indexS.dose}(doseIndex).doseUID;

    planC{indexS.DVH}(DVHIndex).fractionGroupID = planC{indexS.dose}(doseIndex).fractionGroupID;

    %Store computational results
    % planC = saveDVHMatrix(DVHIndex, doseBinsV, doseHistV, planC);

    planC{indexS.DVH}(DVHIndex).DVHMatrix(:,1) = doseBinsV;
    planC{indexS.DVH}(DVHIndex).DVHMatrix(:,2) = doseHistV;

    DVHIndex = DVHIndex +1;
end

end