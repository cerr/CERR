function varargout = promptForVoxelSize(command, varargin)
%"promptForVoxelSize"
%   Asks the user to specify a 3 element voxel size vector to be used
%   in downsampling a dose distribution.  oldDimsV and oldVoxSizeV are
%   vectors of [nr, rc, rs] and [dx, dy, dz] of the old dose distribution
%   respectively.
%
%JRA 11/8/04
%
%Usage:
%   hFig = promptForVoxelSize(oldDimsV, oldVoxSizeV);
%   waitfor(hFig)
%   voxSizeV = promptForVoxelSize('size');
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

persistent voxSizeV;

%Check if no inputs were specified.
if ~exist('command')
    error('Invalid call. Try promptForVoxelSize(oldDimsV, oldVoxSizeV) to initalize or voxSizeV = promptForVoxelSize(''size'') to query.');
end

%Check if 3 inputs in proper format were specified.
if ~ischar(command) & nargin == 3 & isnumeric(command) & isnumeric(varargin{1}) & length(command) == 3 & length(varargin{1}) == 3
    oldDimsV = command;
    oldVoxSizeV = varargin{1};
    command = 'init';    
elseif ~ischar(command)
    error('Invalid call. Try promptForVoxelSize(oldDimsV, oldVoxSizeV) to initalize or voxSizeV = promptForVoxelSize(''size'') to query.');
end

%Find old voxel prompt figures.
hFig = findobj('Tag', 'CERR_DownsampleDose');

switch upper(command)
    case 'INIT'
        %Wipe out old voxel prompt figures;
        if ~isempty(hFig)
            delete(hFig);
        end
        
        screenSize = get(0,'ScreenSize');   
        units = 'pixels';
        y = 300;
        x = 520;
        
        dy = floor((y-30)/2);
        dx = floor((x-30)/2);
        
        ud.oldVoxSizeV = oldVoxSizeV;
        ud.oldDimsV = oldDimsV;
        voxSizeV = oldVoxSizeV;
        
        doseFileName = varargin{2};        
        [pname,fname] = fileparts(doseFileName);
        if ispc
            indSlash = strfind(pname,'\');
        else
            indSlash = strfind(pname,'/');
        end

        if ~isempty(indSlash)
            folderName = pname(indSlash(end):end);
        else
            folderName = pname;            
        end
        
        
        %Create figure and UI controls.
        hFig = figure('Name',[folderName,'\',fname,': Downsample Dose'], 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'CERR_DownsampleDose');        
        uicontrol(hFig, 'units',units,'Position',[10 10 dx 2*dy+10], 'style', 'frame');
        uicontrol(hFig, 'units',units,'Position',[dx+20 dy+20 dx dy], 'style', 'frame');
        uicontrol(hFig, 'units',units,'Position',[dx+20 10 dx dy], 'style', 'frame');        
                
        uicontrol(hFig, 'units',units,'Position',[dx+20 dy-5 100 15], 'style', 'text', 'String', 'New Voxel Size', 'fontweight', 'bold');        
        uicontrol(hFig, 'units',units,'Position',[dx+20 10+2*dy-5 100 15], 'style', 'text', 'String', 'Old Voxel Size', 'fontweight', 'bold');                
        
        uicontrol(hFig, 'units',units,'Position',[dx+35 dy-30 50 20], 'style', 'text', 'String', 'dx:', 'horizontalAlignment', 'left');        
        uicontrol(hFig, 'units',units,'Position',[dx+35 dy-50 50 20], 'style', 'text', 'String', 'dy:', 'horizontalAlignment', 'left');        
        uicontrol(hFig, 'units',units,'Position',[dx+35 dy-70 50 20], 'style', 'text', 'String', 'dz:', 'horizontalAlignment', 'left');    
        uicontrol(hFig, 'units',units,'Position',[dx+35 dy-90 100 20], 'style', 'text', 'String', 'Space Required:', 'horizontalAlignment', 'left');
        
        uicontrol(hFig, 'units',units,'Position',[dx+35 10+2*dy-30 50 20], 'style', 'text', 'String', 'dx:', 'horizontalAlignment', 'left');        
        uicontrol(hFig, 'units',units,'Position',[dx+35 10+2*dy-50 50 20], 'style', 'text', 'String', 'dy:', 'horizontalAlignment', 'left');        
        uicontrol(hFig, 'units',units,'Position',[dx+35 10+2*dy-70 50 20], 'style', 'text', 'String', 'dz:', 'horizontalAlignment', 'left');    
        uicontrol(hFig, 'units',units,'Position',[dx+35 10+2*dy-90 100 20], 'style', 'text', 'String', 'Space Required:', 'horizontalAlignment', 'left');        

        uicontrol(hFig, 'units',units,'Position',[2*dx-45 dy-30 50 20], 'style', 'text', 'String', 'cm', 'horizontalAlignment', 'right');        
        uicontrol(hFig, 'units',units,'Position',[2*dx-45 dy-50 50 20], 'style', 'text', 'String', 'cm', 'horizontalAlignment', 'right');        
        uicontrol(hFig, 'units',units,'Position',[2*dx-45 dy-70 50 20], 'style', 'text', 'String', 'cm', 'horizontalAlignment', 'right');    
        
        ud.handle.dxOld_text = uicontrol(hFig, 'units',units,'Position',[2*dx-75 10+2*dy-30 80 20], 'style', 'text', 'String', '', 'horizontalAlignment', 'right');        
        ud.handle.dyOld_text = uicontrol(hFig, 'units',units,'Position',[2*dx-75 10+2*dy-50 80 20], 'style', 'text', 'String', '', 'horizontalAlignment', 'right');        
        ud.handle.dzOld_text = uicontrol(hFig, 'units',units,'Position',[2*dx-75 10+2*dy-70 80 20], 'style', 'text', 'String', '', 'horizontalAlignment', 'right');    
        ud.handle.MBOld_text = uicontrol(hFig, 'units',units,'Position',[2*dx-75 10+2*dy-90 80 20], 'style', 'text', 'String', '', 'horizontalAlignment', 'right');
        
        ud.handle.dxNew_text = uicontrol(hFig, 'units',units,'Position',[2*dx-75 dy-30+5 62 20], 'style', 'edit', 'String', '', 'callback', 'promptForVoxelSize(''EDIT_CALLBACK'')', 'horizontalAlignment', 'right');        
        ud.handle.dyNew_text = uicontrol(hFig, 'units',units,'Position',[2*dx-75 dy-50+5 62 20], 'style', 'edit', 'String', '', 'callback', 'promptForVoxelSize(''EDIT_CALLBACK'')', 'horizontalAlignment', 'right');        
        ud.handle.dzNew_text = uicontrol(hFig, 'units',units,'Position',[2*dx-75 dy-70+5 62 20], 'style', 'edit', 'String', '', 'callback', 'promptForVoxelSize(''EDIT_CALLBACK'')', 'horizontalAlignment', 'right');    
        ud.handle.MBNew_text = uicontrol(hFig, 'units',units,'Position',[2*dx-75 dy-90 80 20], 'style', 'text', 'String', '', 'horizontalAlignment', 'right');
                
        uicontrol(hFig, 'units',units, 'Position',[20 dy dx-20 dy+10], 'fontsize', 10, 'style', 'text', 'string', 'The dose array being imported is very large and downsampling is recommended.   Please specify a new 3 element voxel size, with larger dx, dy, dz values.  This will decrease the resolution and thus the memory required to display the dose.');
        uicontrol(hFig, 'units',units, 'Position',[20 60 dx-20 75], 'fontsize', 10, 'style', 'text', 'string', 'Example: If [dx, dy, dz] = [.1 .1 .3] specifying [.2 .2 .3] decreases the dose size by a factor of 4.');
        uicontrol(hFig, 'units',units, 'Position',[20 20 dx-20 40], 'fontsize', 8, 'style', 'text', 'string', '(This prompt can be disabled in the CERROptions file by setting optS.promptForNewSize to ''no''.)');                        
        
        uicontrol(hFig, 'units',units, 'Position', [dx+30 20 dx/2-15 20], 'style', 'pushbutton', 'string', 'Continue', 'callback', 'promptForVoxelSize(''Continue'')');
        uicontrol(hFig, 'units',units, 'Position', [2*dx-100 20 dx/2-15 20], 'style', 'pushbutton', 'string', 'Use Default', 'callback', 'promptForVoxelSize(''USE_DEFAULT'')');       
        
        set(hFig, 'userdata', ud);
        
        promptForVoxelSize('UPDATE_MB');
        
        varargout{1} = hFig;
        
    case 'EDIT_CALLBACK'       
        %An edit box has had data typed in it.
        ud = get(hFig, 'userdata');        
        
        dx = str2num(get(ud.handle.dxNew_text, 'string'));
        dy = str2num(get(ud.handle.dyNew_text, 'string'));
        dz = str2num(get(ud.handle.dzNew_text, 'string'));        
        if ~isempty(dx) & ~isempty(dy) & ~isempty(dz)
            voxSizeV = [dx dy dz];
        end
        promptForVoxelSize('UPDATE_MB');        
        
    case 'UPDATE_MB'
        %Recalculate and repopulate all fields.
        ud = get(hFig, 'userdata');
        
        bytesPerDoseElement = 8;
        bytesPerMB = 1024*1024;
        oldDoseArraySizeInMB = prod(ud.oldDimsV)*8/bytesPerMB;        
        
        set(ud.handle.dxOld_text, 'string', [num2str(ud.oldVoxSizeV(1)) ' cm']);
        set(ud.handle.dyOld_text, 'string', [num2str(ud.oldVoxSizeV(2)) ' cm']);
        set(ud.handle.dzOld_text, 'string', [num2str(ud.oldVoxSizeV(3)) ' cm']);        
        set(ud.handle.MBOld_text, 'string', [num2str(oldDoseArraySizeInMB) ' MB']);
        
        ratio = prod(ud.oldVoxSizeV) / prod(voxSizeV);
        
        set(ud.handle.dxNew_text, 'string', [num2str(voxSizeV(1))]);
        set(ud.handle.dyNew_text, 'string', [num2str(voxSizeV(2))]);
        set(ud.handle.dzNew_text, 'string', [num2str(voxSizeV(3))]);        
        set(ud.handle.MBNew_text, 'string', [num2str(oldDoseArraySizeInMB*ratio) ' MB']);                        
        if ratio > 1
            set(ud.handle.MBNew_text, 'foregroundcolor', 'red');    
        else
            set(ud.handle.MBNew_text, 'foregroundcolor', 'black');                
        end
        
    case 'USE_DEFAULT'
        %Use the default value in optS, if it exists.
        ud = get(hFig, 'userdata');        
        pathStr = getCERRPath;
        optName = [pathStr 'CERROptions.m'];
        optS = opts4Exe(optName);        
        try 
            voxSizeV = optS.downsampledVoxelSize;
        catch
            voxSizeV = ud.oldVoxSizeV;
        end
        promptForVoxelSize('UPDATE_MB');                        
                
    case 'SIZE'
        varargout{1} = voxSizeV;
        return;
        
    case 'CONTINUE'
        promptForVoxelSize('EDIT_CALLBACK');
        delete(hFig);        
        drawnow
end