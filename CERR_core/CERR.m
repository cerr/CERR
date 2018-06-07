function CERR(varargin)
%"CERR"
%   Master function to open CERR.
%
%JRA 7/5/05
%
%Usage:
%   CERR
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


persistent logFlag

if isunix
    setappdata(0,'UseNativeSystemDialogs',false)
end

screenSize = get(0,'ScreenSize');

y = 376;
x = 519;
units = 'normalized';

%Set Keypressfunction call back for ALL subsequent figures.
set(0,'DefaultFigureCreateFcn','set(gcbo,''WindowKeyPressFcn'',''CERRHotKeys'')')


if(nargin == 0)

%     pathStr = getCERRPath;
%     optName = [pathStr 'CERROptions.m'];
%     optS = opts4Exe(optName);
%     optS = '';
%     if isfield(optS,'logOnStartup') && optS.logOnStartup==1 && isempty(logFlag)
%         publishOpts.outputDir = tempdir;
%         publishOpts.showCode = false;
%         publishOpts.useNewFigure = false;
%         file = publish('publishLog.m',publishOpts);
%         %web(file)
%         logFlag = 1;
%     end

    oldFig = findobj('Tag', 'CERRStartupFig');
    if ishandle(oldFig)
        figure(oldFig);
        set(oldFig, 'visible', 'on');
        return;
    end

    %Set up the GUI window, loading its graphical background.
    if isdeployed
        file = fullfile(getCERRPath,'pics','CERR.png'); 
    else
        file = 'CERR.png';
    end
    [background, map] = imread(file,'png');
    CERRStartupFig = figure('units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'CERRStartupFig','CloseRequestFcn','CERR(''QUIT'')');
    colormap(map);
    set(CERRStartupFig, 'Name',' CERR control panel'); % ES 28 Aug 2003
    set(gca, 'Position', [0 0 1 1]);
    image(background, 'CDataMapping', 'direct','parent',gca)
    axis(gca,'off', 'image')
    
    %get local and remote git info
    if isdeployed
        remoteGitHash = '';
        localGitInfo = struct('hash','','date','');
    else
        [remoteGitHash, localGitInfo] = getGitInfo;
    end
    [ver, date] = CERRCurrentVersion;    
    uicontrol('units',units,'Position',[0 .6 0.3 .04],'String','Local GitHub Hash:','Style','text', 'BackgroundColor', [1 1 1], 'FontSize', 10, 'FontName', 'FixedWidth', 'HorizontalAlignment', 'right');
    if ~isempty(localGitInfo)
        uicontrol('units',units,'Position',[0.31 .6 0.67 .04],'String',localGitInfo.hash,'Style','edit', 'BackgroundColor', [1 1 1], 'FontSize', 10, 'FontName', 'FixedWidth', 'HorizontalAlignment', 'left');
    end
    uicontrol('units',units,'Position',[0 .55 0.3 .04],'String','Date:','Style','text', 'BackgroundColor', [1 1 1], 'FontSize', 10, 'FontName', 'FixedWidth', 'HorizontalAlignment', 'right');
    if ~isempty(localGitInfo)
        uicontrol('units',units,'Position',[0.31 .55 0.4 .04],'String',localGitInfo.date,'Style','edit', 'BackgroundColor', [1 1 1], 'FontSize', 10, 'FontName', 'FixedWidth', 'HorizontalAlignment', 'left');
    end
    
    %Display link for Log file
    if ~isempty(logFlag) && logFlag == 1
        uicontrol('units',units,'Position',[0.55 .50 .25 .05],'String', 'View Change Log', 'callback','CERR(''VIEW LOG'')', 'Style','push', 'BackgroundColor', [1 1 1], 'FontSize', 10, 'FontName', 'FixedWidth', 'HorizontalAlignment', 'center');
    end
           
    %Layer buttons and text labels over the background
    importOptions = {'DICOM';'RTOG';'Gamma Knife';'PLUNC';'DICOM (Deprecated)';'FDF'};

    uicontrol('units',units,'Position',[.055 .27 .3 .05],'String',importOptions,'Style','popup',...
        'BackgroundColor',[1 1 1] ,'tooltipstring','Select Import Option',...
        'HorizontalAlignment','center','FontSize',10,'Tag', 'CERRImportPopUp');

    uicontrol('units',units,'Position',[.1 .16 .17 .07],'String','Import',...
        'callback','CERR(''IMPORT'')','FontSize',10,'Tag', 'CERRImportBtn');

    %     uicontrol('units',units,'Position',[.325 .3 .1 .05],'String','DICOM (J)','Style','text','HorizontalAlignment','left');
    uicontrol('units',units,'Position',[.445 .27 .17 .07],'String','DICOM', 'callback','CERR(''DICOMEXPORT'')','FontSize',10);

    %     uicontrol('units',units,'Position',[.585 .3 .1 .05],'String','Viewer','Style','text','HorizontalAlignment','left');
    uicontrol('units',units,'Position',[.725 .27 .17 .07],'String','Viewer', 'callback','CERR(''CERRSLICEVIEWER'')','FontSize',10);

    %     uicontrol('units',units,'Position',[.835 .50 .1 .05],'String','Quit','callback','CERR(''QUIT'')');
    uicontrol('units',units,'Position',[.835 .50 .1 .05],'String','Help','callback','CERR(''HELP'')');
    
    %git hash comparison between local and remote to see if the version is updated
    tf = [];
    if ~isempty(localGitInfo) && ~isempty(remoteGitHash)
        tf = strcmp(localGitInfo.hash,remoteGitHash);
    end
    if isempty(tf)
    elseif ~tf
        labelStr = ['<html> New version available; View updates at: <a href="">' localGitInfo.url '</a></html>' 'blahblah'];
        jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
        jLabel.setBackground(java.awt.Color(1, 1, 1));
        [hjLabel,hContainer] = javacomponent(jLabel, [15,1,600,20], gcf);
        % Set the mouse-click callback
        set(hjLabel, 'MouseClickedCallback', @(h,e)web([ localGitInfo.url], '-browser'));
    else
         uicontrol('units',units,'Position',[0 .01 1 .04],'String','You have the latest version of CERR','Style','text', 'BackgroundColor', [1 1 1], 'FontSize', 10, 'FontName', 'FixedWidth', 'HorizontalAlignment', 'center');
    end
    
    
    
else
    %A callback has been encountered.
    switch upper(varargin{1})
        case 'DICOMEXPORT'
            if ~isunix
                set(findobj('Tag', 'CERRStartupFig'), 'visible', 'off');
            end
            CERRExportDICOM;
            CERR;
        case 'CERRSLICEVIEWER'
            set(findobj('Tag', 'CERRStartupFig'), 'visible', 'off');
            sliceCallBack('init');

        case 'IMPORT'
            importOptions = {'DICOM';'RTOG';'GAMMAKNIFE';'PLUNC';'DICOMDEPRI';'FDF'};
            importIndx = get(findobj('Tag', 'CERRImportPopUp'),'value');

            if ~isunix
                set(findobj('Tag', 'CERRStartupFig'), 'visible', 'off');
            end

            switch importOptions{importIndx}
                case 'DICOM'
                    CERRImportDCM4CHE;

                case 'RTOG'
                    CERRImport;

                case 'GAMMAKNIFE'
                    CERRImportGammaKnife;

                case 'PLUNC'
                    CERRImportPLUNC;

                case 'DICOMDEPRI'
                    CERRImportDICOM;
                    
                case 'FDF'
                    importVarianFDF;
            end

            CERR;

        case 'QUIT'
            clear CERR.m
            closereq;

        case 'HELP'
            web https://github.com/cerr/CERR/wiki
            
        case 'VIEW LOG'
            fileName = fullfile(tempdir,'publishLog.html');
            web(fileName)

    end
end