function exportDVHData(command)
%GUI to export a DVH data file starting with a DVH plot of one or more VOI's.
%VOI's must be renamed to agree with a standard list stored in optS.defaultVOINames. 
%DVH data may then be exported to a delimited text file.
%
%KU 04/14/2006
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

global planC;
global stateS;
persistent exportPlots;
indexS = planC{end};


uicolor              = [.9 .9 .9];
units = 'normalized';


%Get DVH data.
h = findobj('tag', 'DVHPlot');      
ud = get(h, 'userdata');
plots = ud.plots;

for i=1:length(plots)
    strNames{i} = plots(i).struct;
end
strNames = {strNames{:}};

%Get list of standard VOI names.
okList = stateS.optS.defaultVOINames;

if nargin == 0
    command = 'init';
end

switch lower(command)
    case 'init'
        hFig = findobj('tag', 'DVHExportFigure');
        if ~isempty(hFig)
            delete(hFig);
        end
        screenSize = get(0,'ScreenSize');        
        units = 'normalized';
        hFig = figure('Name', 'DVH Data Export', 'doublebuffer', 'off', 'position',[screenSize(3)/10 screenSize(4)/8 screenSize(3)/10*8 screenSize(4)/10*5], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'DVHExportFigure');

        stateS.handles.figure = hFig;        

        %Init List Boxes
        ud.handles.DVHList = uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.05 .10 .25 .85],'String', strNames, 'Style','listbox','Tag','DVHList');
        ud.handles.myDVHList = uicontrol('callback', 'exportDVHData(''SelectDVH'');','units',units,'BackgroundColor',uicolor, 'Position',[.35 .10 .25 .85], 'String', [], 'Style','listbox', 'Enable', 'on', 'Tag','myDVHList');
        
        %Make labels for listboxes
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.05 .95 .15 .04],'String', 'Calculated DVHs: ', 'Style','text', 'horizontalalignment', 'left');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.35 .95 .15 .04],'String', 'Selected For Export: ', 'Style','text', 'horizontalalignment', 'left');

        %make buttons for adding and removing DVH's from list boxes.
        uicontrol('callback', 'exportDVHData(''addDVH'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.3 .65 .05 .05],'String','-->', 'Style','pushbutton','Tag','DVHAdd');
        uicontrol('callback', 'exportDVHData(''removeDVH'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.3 .55 .05 .05],'String','<--', 'Style','pushbutton','Tag','DVHRemove');

        %Make frame for checking and renaming VOI's.
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.65 .45 .3 .5],'String','frame', 'Style','frame','Tag','renameFrame');        

        %Add pop-up menus for renaming VOI's.
        ud.handles.myDVHpopup = uicontrol('callback', 'exportDVHData(''SelectPopupDVH'');','units',units,'BackgroundColor',uicolor, 'Position',[.67 .67 .12 .05],'String', {''}, 'Style','popupmenu','Tag','myDVHpopup');
        ud.handles.okDVHList = uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.81 .67 .12 .05], 'String', okList, 'Style','popupmenu','Tag','okDVHList');
        %Make labels for pop-up menus.
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.66 .72 .13 .05],'String', 'Select VOI to rename', 'Style','text', 'horizontalalignment', 'left');
        uicontrol('units',units,'BackgroundColor',uicolor, 'Position',[.81 .72 .13 .05],'String', 'Select name from list', 'Style','text', 'horizontalalignment', 'left');
        
        %Make buttons for checking VOI names and renaming.
        uicontrol('callback', 'exportDVHData(''checknames'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.70 .87 .2 .05],'String','Check VOI Names', 'Style','pushbutton','Tag','namecheck');
        uicontrol('callback', 'exportDVHData(''rename'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.75 .50 .1 .05],'String','Rename', 'Style','pushbutton','Tag','rename');

        %Make buttons for export and cancel.
        uicontrol('callback', 'exportDVHData(''export'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.65 .35 .1 .05],'String','Export', 'Style','pushbutton','Tag','export');
        uicontrol('callback', 'exportDVHData(''cancel'');', 'units',units,'BackgroundColor',uicolor, 'Position',[.85 .35 .1 .05],'String','Cancel', 'Style','pushbutton','Tag','cancel');
        set(hFig, 'userdata', ud);
        return;       

        
    case 'adddvh' %add current DVH to the "selected for export" list.
        hFig = findobj('tag', 'DVHExportFigure');
        ud = get(hFig, 'userdata');
		index_selected = get(ud.handles.DVHList,'Value');
        exportList = get(findobj('tag', 'myDVHList'), 'String');
        if isempty(exportList)
            exportPlots = plots(index_selected);
        else
            for i = 1:length(exportPlots)
                if isequal(plots(index_selected).volsV, exportPlots(i).volsV)
                    warndlg('That DVH has already been selected for export!', 'Warning', 'modal');
                    break
                elseif i == length(exportPlots)
                    exportPlots = [exportPlots, plots(index_selected)];
                end
            end
        end
        for i=1:length(exportPlots)
            exportNames{i} = exportPlots(i).struct;
        end
        exportNames = {exportNames{:}};
        set(findobj('tag', 'myDVHList'), 'String', exportNames);
        set(findobj('tag', 'myDVHpopup'), 'String', exportNames);

        
    case 'removedvh' %Remove DVH from the "selected for export" list.
        hFig = findobj('tag', 'DVHExportFigure');
        exportList = get(findobj('tag', 'myDVHList'), 'String');
        if isempty(exportList)
            return
        end
        
        ud = get(hFig, 'userdata');
		index_selected = get(ud.handles.myDVHList,'Value');
        exportPlots(index_selected) = [];
        
        if length(exportPlots) >= 1
            for i=1:length(exportPlots)
                exportNames{i} = exportPlots(i).struct;
            end
            exportNames = {exportNames{:}};
            set(findobj('tag', 'myDVHList'), 'String', exportNames);
            set(findobj('tag', 'myDVHpopup'), 'String', exportNames);
        else
            set(findobj('tag', 'myDVHList'), 'String', []);
            set(findobj('tag', 'myDVHpopup'), 'String', {''});
        end
        
        %Fix index if now out of range.
        if index_selected > length(exportPlots) && length(exportPlots) >= 1
            set(findobj('tag', 'myDVHList'), 'Value', index_selected-1);
            set(findobj('tag', 'myDVHpopup'), 'Value', index_selected-1);
        end
        
    case 'checknames'   %Check VOI names against standard list in optS.defaultVOINames.
        exportList = get(findobj('tag', 'myDVHList'), 'String');
        if isempty(exportList)
            warndlg('No DVHs have been selected for export!', 'Warning', 'modal');
            return
        end
        
        k = 0;
        for i = 1:length(exportPlots)
            for j = 1:length(okList)
                if strcmpi(exportPlots(i).struct, okList{j})
                    break
                elseif j == length(okList)
                    k = k+1;
                    badNames{k} = exportPlots(i).struct;
                end                
            end
        end
        
        if k == 0
            sentence1 = ('Ready for export!');
            Zmsgbox=msgbox(sentence1, 'modal');
            waitfor(Zmsgbox);
        else        
            sentence1 = {'The following VOIs must be renamed before the DVHs can be exported:',...
                '',...
                badNames{:}};
            Zmsgbox=msgbox(sentence1);
            waitfor(Zmsgbox);
        end
    
    case 'selectdvh'   %Synchronize selected DVH in export list and pop-up menu.
        hFig = findobj('tag', 'DVHExportFigure');
        ud = get(hFig, 'userdata');
        index_selected = get(ud.handles.myDVHList,'Value');
        if index_selected >=1
            set(findobj('tag', 'myDVHpopup'), 'Value', index_selected);
        else
            set(findobj('tag', 'myDVHList'), 'Value', 1);
        end
        
    case 'selectpopupdvh'   %Synchronize selected DVH in export list and pop-up menu.
        hFig = findobj('tag', 'DVHExportFigure');
        ud = get(hFig, 'userdata');
        index_selected = get(ud.handles.myDVHpopup,'Value');
        set(findobj('tag', 'myDVHList'), 'Value', index_selected);
        
    case 'rename'   %Rename VOI's
        hFig = findobj('tag', 'DVHExportFigure');
        exportList = get(findobj('tag', 'myDVHList'), 'String');
        if isempty(exportList)
            warndlg('Nothing to rename!', 'Warning', 'modal');
            return
        end
        
        ud = get(hFig, 'userdata');
        export_index = get(ud.handles.myDVHpopup,'Value');
        OK_index = get(ud.handles.okDVHList,'Value');
        
        Zquestion=questdlg({'Please confirm:',...
            '',...
            ['The exported DVH for  "' exportPlots(export_index).struct '"  will be renamed  "' okList{OK_index} '."']},...
            'Confirm name change', 'Rename', 'Cancel', 'Cancel');
        
        if strcmpi(Zquestion, 'rename')
            exportPlots(export_index).struct = okList{OK_index};

            for i=1:length(exportPlots)
                    exportNames{i} = exportPlots(i).struct;
            end
            exportNames = {exportNames{:}};
            set(findobj('tag', 'myDVHList'), 'String', exportNames);
            set(findobj('tag', 'myDVHpopup'), 'String', exportNames);
        end
        
    case 'export'   %Export to file.
        exportList = get(findobj('tag', 'myDVHList'), 'String');
        if isempty(exportList)
            warndlg('No DVHs have been selected for export!', 'Warning', 'modal');
            return
        end
        
        k = 0;
        for i = 1:length(exportPlots)   %Check that all the names are OK.
            for j = 1:length(okList)
                if strcmpi(exportPlots(i).struct, okList{j})
                    break
                elseif j == length(okList)
                    k = k+1;
                    badNames{k} = exportPlots(i).struct;
                end                
            end
        end
        
        if k == 0   %%%% All the names are OK.  Do the export!!!!
            exportData = [];            
            dlmwrite('tempfile', length(exportPlots));
            for i = 1:length(exportPlots)                
                exportData(i).struct = exportPlots(i).struct;
                exportData(i).numDoseVals = length(exportPlots(i).xVals);
                exportData(i).array(:,1) = exportPlots(i).xVals';
                
                %Convert dose units from Gy to cGy.
                exportData(i).array(:,1) = 100*(exportData(i).array(:,1));
                
                exportData(i).array(:,2) = exportPlots(i).yVals';
                exportData(i).array(:,3) = [0;exportPlots(i).volsV'];
                
                %Write to temporary file 
                fid = fopen('tempfile', 'a');
                fprintf(fid, '\n%s\n', exportData(i).struct);
                fclose(fid);
                dlmwrite('tempfile', exportData(i).numDoseVals, '-append');
                dlmwrite('tempfile', exportData(i).array, '-append', 'delimiter', '\t', 'precision', 6);                                                                
            end
            %Save file
            [pathstr, name, ext] = fileparts(stateS.CERRFile);
            if strcmpi(ext, '.bz2')
                [pathstr, name, ext] = fileparts(fullfile(pathstr,name));
            end
            [fname, pname] = uiputfile('*.txt', 'Save as', fullfile(pathstr,name));
            if isequal(fname,0) || isequal(pname,0)
                CERRStatusString('Save cancelled. Ready.');
                delete tempfile;
                return;
            end       
            saveFile = fullfile(pname, fname);
            copyfile('tempfile', saveFile);
            delete tempfile;
            hFig = findobj('tag', 'DVHExportFigure');
            delete(hFig);
        else        
            sentence1 = {'The following VOIs must be renamed before the DVHs can be exported:',...
                '',...
                badNames{:}};
            Zmsgbox=msgbox(sentence1);
            waitfor(Zmsgbox);
        end
        
    case 'cancel'
        hFig = findobj('tag', 'DVHExportFigure');
        delete(hFig);
end