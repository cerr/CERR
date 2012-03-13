function varargout = LabBookGui(varargin)
%"LabBookGui"
%   A gui to create and manage a labbook.
%
%JRA ??/??/03
%JRA 05/27/05
%
%Usage:
%   LabBookGui('INIT');
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

screenSize = get(0,'ScreenSize');   
y = 300;
x = 519;
units = 'normalized';

%If no arguments default to init.
if(nargin == 0)
    varargin{1} = 'init';
end   

%Command for callback switch statement.
command = varargin{1};

hFig = findobj('tag', 'LabBookGui');

%If asking for INIT, and already initialized, return.
if ~isempty(hFig) & strcmpi(command, 'init');
    figure(hFig);
    return;
%If not initialized and capture requested, init invisible.
elseif isempty(hFig) & strcmpi(command, 'capture');
    oldFig = gcf;
    LabBookGui('INIT')
    hFig = findobj('tag', 'LabBookGui');
    figure(oldFig);
elseif isempty(hFig) & ~strcmpi(command, 'init')
    warning('LabBookGui not initialized.');
    return;
end

switch upper(command)

    case 'INIT'
        hFig = figure('visible', 'off', 'Name','Annotation Dialogue', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'LabBookGui');    
        
        uicontrol('units',units,'Position',[.01 .03 .54 .94],'style', 'frame');
        uicontrol('units',units,'Position',[.56 .67 .43 .3],'style', 'frame');
        
%         uicontrol('units',units,'Position',[.60 .73 .14 .08],'String','Save', 'callback','LabBookGui(''SAVE'');');
        uicontrol('units',units,'Position',[.59 .83 .17 .08],'String','Save & Exit', 'callback','LabBookGui(''SAVEANDEXIT'');', 'Tag', 'LabBookGuiSaveAndExit');
        uicontrol('units',units,'Position',[.8 .83 .17 .08],'String','Save & View', 'callback','LabBookGui(''SAVEANDREPORT'');', 'Tag', 'LabBookGuiSaveAndView');
        uicontrol('units',units,'Position',[.59 .73 .17 .08],'String','Save & Email', 'callback','LabBookGui(''SAVEANDEMAIL'');', 'Tag', 'LabBookGuiSaveAndEmail');         
        uicontrol('units',units,'Position',[.8 .73 .17 .08],'String','Cancel', 'callback','LabBookGui(''Cancel'');');

        uicontrol('units',units,'Position',[.03 .75 .5 .2],'String','Current LabBook Directory:', 'style', 'text', 'HorizontalAlignment', 'left');
        uicontrol('units',units,'Position',[.03 .70 .5 .2],'String',LabBook('GetCurrentBook'), 'style', 'text', 'HorizontalAlignment', 'left', 'Tag', 'CurrentBookEdit');
        uicontrol('units',units,'Position',[.38 .75 .14 .08],'String',' Change... ', 'callback','LabBookGui(''ChangeCurrentBook'');');
        uicontrol('units',units,'Position',[.23 .75 .14 .08],'String','View', 'callback','LabBookGui(''DISPLAYREPORT'');');            
        
        uicontrol('units',units,'Position',[.03 .70 .5 .05],'String','Image Filename:', 'style', 'text', 'HorizontalAlignment', 'left', 'Tag', 'LabBookImageFilename');
        uicontrol('units',units,'Position',[.03 .63 .5 .07],'String','', 'style', 'edit','HorizontalAlignment', 'left', 'Tag', 'ImageNameBox');
        
        uicontrol('units',units,'Position',[.03 .55 .5 .05],'String','Annotation:', 'style', 'text', 'HorizontalAlignment', 'left', 'Tag', 'LabBookAnnotation');
        uicontrol('units',units,'Position',[.03 .05 .5 .5],'String','', 'style', 'edit','HorizontalAlignment', 'left', 'Tag', 'AnnotationBox');
                  
        hAxis = axes('Position',[.56 .03 .43 .62], 'color', [0 0 0], 'Tag', 'LabBookGuiThumb', 'xTick', [], 'yTick', []);
        text(.5, .5, 'No Image', 'parent', hAxis, 'color', [1 1 1], 'horizontalALignment', 'center');
        LabBookGui('REFRESH');
%         h = uicontrol('units', units', 'position', [.56 .03 .43 .62], 'style', 'frame');
%         image(large.cdata);
%         axis off, axis image
    
    case 'REFRESH'
        set(hFig, 'visible', 'on');
        ud = get(hFig, 'userdata');
        saveAndExitButton = findobj(hFig, 'Tag', 'LabBookGuiSaveAndExit');
        saveAndViewButton = findobj(hFig, 'Tag', 'LabBookGuiSaveAndView');     
        annotationTextBox = findobj(hFig, 'Tag', 'LabBookAnnotation');
        filenameTextBox   = findobj(hFig, 'Tag', 'LabBookImageFilename');
        if isempty(ud)
            set([saveAndExitButton saveAndViewButton annotationTextBox filenameTextBox], 'enable', 'off');
        else
            set([saveAndExitButton saveAndViewButton annotationTextBox filenameTextBox], 'enable', 'on');
        end

    case 'CAPTURE'
        pause(0.1)
         [large, thumb] = LabBook('CAPTURE', gcf);
         pause(.1);
         set(hFig, 'UserData', {large, thumb})         
         hAxis = findobj(hFig, 'Tag', 'LabBookGuiThumb');
         axis(hAxis);
         set(hAxis, 'nextplot', 'replaceChildren');
         axis(hAxis, 'ij');
         image(large.cdata, 'parent', hAxis);
         axis(hAxis, 'image');                  
         figure(hFig);
         LabBookGui('REFRESH');
        
    case 'SAVEANDREPORT'
        feval(@LabBookGui,'Save');
        LabBook('DISPLAYREPORT');
        return;
        
    case 'SAVEANDEMAIL'
        saveFile = feval(@LabBookGui,'Save');
        annotation = get(findobj(hFig, 'Tag', 'AnnotationBox'), 'String');
        LabBookEmail('INIT');
        LabBookEmail('MESSAGE', saveFile, annotation);
        return;        
        
    case 'DISPLAYREPORT'            
        LabBook('DISPLAYREPORT');
        
    case 'SAVEANDEXIT'
        feval(@LabBookGui,'Save');
        close;
        
    case 'SAVE'
        storedImages = get(gcf, 'UserData');
        large = storedImages{1};
        thumb = storedImages{2};
        imageName = get(findobj(hFig, 'Tag', 'ImageNameBox'), 'String');
        if isempty(imageName)
            errordlg('Cannot save image unless an image filename is specified!');
            error('Cannot save image unless an image filename is specified!');
            return;
        end
        annotation = get(findobj(hFig, 'Tag', 'AnnotationBox'), 'String');
        filename = LabBook('SAVE', large, thumb, imageName, annotation);
        varargout{1} = filename;
        LabBook('GENERATEREPORT')
        
    case 'CANCEL'
        close;    
        
    case 'CHANGECURRENTBOOK'
        directory_name = uigetdir(fullfile(getCERRPath, 'LabBook'),'Select or create a directory to store this LabBook data.');
        if(directory_name ~= 0)
            LabBook('SETCURRENTBOOK', directory_name);
            set(findobj(hFig, 'Tag', 'CurrentBookEdit'), 'String', LabBook('GetCurrentBook'));
        end            
end