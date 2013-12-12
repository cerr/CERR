function planMergeGui(command, varargin)
%"planMergeGui"
%   Raises a GUI to merge two plans together, usually for the purpose of
%   fusion.
%
%JRA 2/28/04
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
%
%Usage:
%   Access through the CERR Gui, OR
%   load a plan and type: planMergeGui('init');

global stateS

if nargin == 0
    command = 'INIT';
end

%Find old planMerge figures.
hFig = findobj('Tag', 'CERR_PlanMergeGui');

if isempty(hFig) & ~strcmpi(command, 'init');
    warning('planMergeGui was not initialized.  Initializing now.');
    command = 'init';
end

switch upper(command)
    case 'INIT'
        %Wipe out old plan merge figures;
        if ~isempty(hFig)
            delete(hFig);
        end
        
        screenSize = get(0,'ScreenSize');   
        units = 'pixels';
        y = 520;
        x = 520;
        
        %dx for each of 2 columns.
        dx = floor((x-30)/2);                               
        
        %Create figure and UI controls.
        hFig = figure('Name','Plan Merge', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'CERR_PlanMergeGui');        
        
        %Status frame.
        bartop = 40;
        statusFrame             = uicontrol(hFig, 'units',units,'Position',[10 10 x-20 30], 'style', 'frame');
        frameColor              = get(statusFrame, 'BackgroundColor');
        statusLabel             = uicontrol(hFig, 'units',units,'Position',[10 25 65 15], 'style', 'text', 'String', 'Status', 'fontweight', 'bold');                                
        ud.handles.statusBar    = uicontrol(hFig, 'units',units,'Position',[70 14 2*dx-165 18], 'style', 'text', 'string', 'Ready.', 'enable', 'inactive', 'backgroundcolor', frameColor, 'horizontalAlignment', 'right');
                
        %Load plan frame and label.
        loadbot = y-65-10;
        uicontrol(hFig, 'units',units,'Position',[10 loadbot dx*2+10 65], 'style', 'frame');                
        uicontrol(hFig, 'units',units,'Position',[10 loadbot+65-15 100 15], 'style', 'text', 'String', 'Select Plan', 'fontweight', 'bold', 'backgroundcolor', frameColor);                                
        
        %Doses frame and label.
        dy = floor((loadbot-bartop-30)/2);
        uicontrol(hFig, 'units',units,'Position',[10 bartop+10 dx dy], 'style', 'frame');          
        uicontrol(hFig, 'units',units,'Position',[10 bartop+10+dy-15 65 15], 'style', 'text', 'String', 'Doses', 'fontweight', 'bold', 'backgroundcolor', frameColor);                      
        
        %Scans frame and label.
        uicontrol(hFig, 'units',units,'Position',[10 bartop+20+dy dx dy], 'style', 'frame');
        uicontrol(hFig, 'units',units,'Position',[10 bartop+20+2*dy-15 65 15], 'style', 'text', 'String', 'Scans', 'fontweight', 'bold', 'backgroundcolor', frameColor);   
        
        %Structures frame and label
        uicontrol(hFig, 'units',units,'Position',[dx+20 bartop+10 dx 2*dy+10], 'style', 'frame');
        uicontrol(hFig, 'units',units,'Position',[dx+20 bartop+20+2*dy-15 90 15], 'style', 'text', 'String', 'Structures', 'fontweight', 'bold', 'backgroundcolor', frameColor);            
         
        ud.handles.dosesSlider   = uicontrol(hFig, 'units',units,'Position',[dx-15 bartop+10+5 20 dy-10], 'style', 'slider', 'enable', 'off');            
        ud.handles.scansSlider   = uicontrol(hFig, 'units',units,'Position',[dx-15 bartop+20+5+dy 20 dy-10], 'style', 'slider', 'enable', 'off', 'tag','scanSlider','callback','scanSlider_clk(''clicked'')');  
        ud.handles.structsSlider = uicontrol(hFig, 'units',units,'Position',[2*dx-5 bartop+10+5 20 2*dy], 'style', 'slider', 'enable', 'off','tag','structSlider','callback','structSlider_clk(''clicked'')');

        ud.handles.Browse       = uicontrol(hFig, 'units',units, 'Position',[20  loadbot+10 dx/2-15 25], 'style', 'pushbutton', 'string', 'Browse...', 'callback', 'planMergeGui(''BROWSE'')');
        ud.handles.filenameText = uicontrol(hFig, 'units',units, 'Position',[130 loadbot+5 375 25], 'fontsize', 8, 'style', 'text', 'string', {'Click Browse to find a plan to merge with the plan currently loaded in CERR.'}, 'backgroundcolor', frameColor);
        ud.handles.pathText     = uicontrol(hFig, 'units',units, 'Position',[130 loadbot+30 375 25], 'fontsize', 8, 'style', 'text', 'string', {''}, 'backgroundcolor', frameColor);        

        %Create scan UIControls.
        uicontrol(hFig, 'units',units,'Position',[12 bartop+10+2*dy-25 12 15], 'style', 'text', 'String', '#', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[25 bartop+10+2*dy-25 80 15], 'style', 'text', 'String', 'Modality', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[120 bartop+10+2*dy-25 60 15], 'style', 'text', 'String', 'Size', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[180 bartop+10+2*dy-25 50 15], 'style', 'text', 'String', 'Merge?', 'backgroundcolor', frameColor); 

        uicontrol(hFig, 'units',units,'Position',[15 bartop+10+2*dy-45 80 15], 'style', 'text', 'String', 'ALL', 'backgroundcolor', frameColor, 'fontweight', 'bold');   
        uicontrol(hFig, 'units',units,'Position',[100 bartop+10+2*dy-45 60 15], 'style', 'text', 'String', '', 'backgroundcolor', frameColor);   
        ud.handles.scanALLCheck = uicontrol(hFig, 'units',units,'Position',[200 bartop+10+2*dy-45 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'callback', 'planMergeGui(''ALLCHECK'')', 'tag', 'scan', 'enable', 'off');                         
                
        numRows = 6;
        for i=1:numRows
            ud.handles.scanNumber(i)  = uicontrol(hFig, 'units',units,'Position',[12 bartop+10+2*dy-45-i*20 20 15], 'style', 'text', 'String', '1', 'backgroundcolor', frameColor, 'visible', 'off');   
            ud.handles.scanName(i)    = uicontrol(hFig, 'units',units,'Position',[30 bartop+10+2*dy-45-i*20 90 15], 'style', 'text', 'String', 'CT Scan', 'backgroundcolor', frameColor, 'visible', 'off');   
            ud.handles.scanSize(i)    = uicontrol(hFig, 'units',units,'Position',[125 bartop+10+2*dy-45-i*20 60 15], 'style', 'text', 'String', '100', 'backgroundcolor', frameColor, 'visible', 'off');   
            ud.handles.scanCheck(i)   = uicontrol(hFig, 'units',units,'Position',[200 bartop+10+2*dy-45-i*20 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'ScanCheck', 'callback', 'planMergeGui(''Check'')', 'visible', 'off');
        end
        ud.numScanRows = numRows;        
        
        %Create dose UICONTROLS.
        uicontrol(hFig, 'units',units,'Position',[15 bartop+dy-25 80 15], 'style', 'text', 'String', 'Name', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[100 bartop+dy-25 60 15], 'style', 'text', 'String', 'Size', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[165 bartop+dy-25 60 15], 'style', 'text', 'String', 'Merge?', 'backgroundcolor', frameColor); 

        uicontrol(hFig, 'units',units,'Position',[15 bartop+dy-45 80 15], 'style', 'text', 'String', 'ALL', 'backgroundcolor', frameColor, 'fontweight', 'bold');   
        uicontrol(hFig, 'units',units,'Position',[100 bartop+dy-45 60 15], 'style', 'text', 'String', '', 'backgroundcolor', frameColor);   
        ud.handles.doseALLCheck = uicontrol(hFig, 'units',units,'Position',[185 bartop+dy-45 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'callback', 'planMergeGui(''ALLCHECK'')', 'tag', 'dose', 'enable', 'off');                         
                
        numRows = 6;
        for i=1:numRows
            ud.handles.doseName(i)  = uicontrol(hFig, 'units',units,'Position',[15 bartop+dy-45-i*20 80 15], 'style', 'text', 'String', 'CT Scan', 'backgroundcolor', frameColor, 'visible', 'off');   
            ud.handles.doseSize(i)  = uicontrol(hFig, 'units',units,'Position',[100 bartop+dy-45-i*20 60 15], 'style', 'text', 'String', '100', 'backgroundcolor', frameColor, 'visible', 'off');   
            ud.handles.doseCheck(i) = uicontrol(hFig, 'units',units,'Position',[185 bartop+dy-45-i*20 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'DoseCheck', 'callback', 'planMergeGui(''Check'')', 'visible', 'off');                        
        end
        ud.numDoseRows = numRows;
        
        %Create struct UICONTROLS.
        uicontrol(hFig, 'units',units,'Position',[dx+10+15 loadbot-46 80 15], 'style', 'text', 'String', 'Name', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[dx+10+100 loadbot-46 60 15], 'style', 'text', 'String', 'AssocScan', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[dx+10+165 loadbot-46 60 15], 'style', 'text', 'String', 'Merge?', 'backgroundcolor', frameColor); 

        uicontrol(hFig, 'units',units,'Position',[dx+10+15 loadbot-66 80 15], 'style', 'text', 'String', 'ALL', 'backgroundcolor', frameColor,'fontweight', 'bold'); 
        uicontrol(hFig, 'units',units,'Position',[dx+10+100 loadbot-66 60 15], 'style', 'text', 'String', '', 'backgroundcolor', frameColor);   
        ud.handles.strALLCheck = uicontrol(hFig, 'units',units,'Position',[dx+10+185 loadbot-66 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'callback', 'planMergeGui(''ALLCHECK'')', 'tag', 'struct', 'enable', 'off');                         
                
        numRows = 16;
        for i=1:numRows
            ud.handles.strName(i)  = uicontrol(hFig, 'units',units,'Position',[dx+10+15 loadbot-66-i*20 80 15], 'style', 'text', 'String', 'CT Scan', 'backgroundcolor', frameColor, 'visible', 'off');   
            ud.handles.strScan(i)  = uicontrol(hFig, 'units',units,'Position',[dx+10+100 loadbot-66-i*20 60 15], 'style', 'text', 'String', '1', 'backgroundcolor', frameColor, 'visible', 'off');   
            ud.handles.strCheck(i) = uicontrol(hFig, 'units',units,'Position',[dx+10+185 loadbot-66-i*20 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'StructCheck', 'callback', 'planMergeGui(''Check'')', 'visible', 'off');                         
        end
        ud.numStructRows = numRows;                

        ud.firstVisStruct   = 1;
        ud.firstVisScan     = 1;
        ud.firstVisDose     = 1;
        
        
        ud.handles.merge = uicontrol(hFig, 'units',units, 'Position', [2*dx-85 14 100 20], 'style', 'pushbutton', 'string', 'Merge', 'callback', 'planMergeGui(''MERGE'')', 'enable', 'off');
%         uicontrol(hFig, 'units',units, 'Position', [2*dx-100 20 dx/2-15 20], 'style', 'pushbutton', 'string', 'Cancel', 'callback', 'planMergeGui(''CANCEL'')');       
%         
        set(hFig, 'userdata', ud);               
        
    case 'STATUS'
        ud = get(hFig, 'userdata');       
        statusString = varargin{1};
        set(ud.handles.statusBar, 'string', statusString);
        drawnow;
        
    case 'CANCEL'
        close(hFig);
        
    case 'BROWSE'
        ud = get(hFig, 'userdata');
        [fname, pathname] = uigetfile({'*.mat;*.mat.bz2', 'CERR Plans (*.mat, *.mat.bz2)';'*.*', 'All Files (*.*)'}, 'Select CERR .mat .mat.bzip2 archive to merge.');
        
        if fname == 0
            return;
        else
            set(ud.handles.pathText, 'string', pathname);
            set(ud.handles.filenameText, 'string', fname, 'userdata', fullfile(pathname, fname));
        end
        
        planMergeGui('STATUS', 'Loading selected plan and analyzing its contents...');
        planMergeGui('LOADPLAN');
        
    case 'LOADPLAN'
        hFig = get(gcbo, 'parent');
        ud = get(hFig, 'userdata');
        fullName = get(ud.handles.filenameText, 'userdata');

        %Get temporary directory to extract uncompress
        optS = stateS.optS;
        if isempty(optS.tmpDecompressDir)
            tmpExtractDir = tempdir;
        elseif isdir(optS.tmpDecompressDir)
            tmpExtractDir = optS.tmpDecompressDir;
        elseif ~isdir(optS.tmpDecompressDir)
            error('Please specify a valid directory within CERROptions.m for optS.tmpDecompressDir')
        end        

        try
            [planC] = loadPlanC(fullName,tmpExtractDir);
%             indexS=planC{end};
%             for i=1:length(planC{indexS.scan}(1).scanInfo)
%                 planC{indexS.scan}(1).scanInfo(i).planDir = fullName;
%             end
        end

        if ~exist('planC');
            planMergeGui('status', 'UNABLE TO LOAD SPECIFIED PLAN. Try another plan.');
            return;
        end
        [planInfo, planC]= getPlanInfo(planC);
        if isempty(planInfo)
            return;
        end
        ud.planInfo = planInfo;        
        setappdata(hFig, 'MERGEPLAN', planC);
        
        indexS = planC{end};
        nStructs = length(planC{indexS.structures});
        ud.checkedStructs = ones(nStructs, 1);
        ud.nStructs = nStructs;
        
        nDoses = length(planC{indexS.dose});
        ud.checkedDoses = ones(nDoses, 1);
        
        nScans = length(planC{indexS.scan});
        ud.checkedScans = ones(nScans, 1);                          
                
        set(ud.handles.doseALLCheck, 'enable', 'on', 'value', 1);
        set(ud.handles.scanALLCheck, 'enable', 'on', 'value', 1);
        set(ud.handles.strALLCheck, 'enable', 'on', 'value', 1);        
        
        set(hFig, 'userdata', ud);
        planMergeGui('refresh');
        planMergeGui('STATUS', 'Plan loaded.  Select elements to merge and click MERGE button.');        
        set(ud.handles.merge, 'enable', 'on')        

    case 'REFRESH'
        ud = get(hFig, 'userdata');
        planInfo = ud.planInfo;
        
        planC = getappdata(hFig, 'MERGEPLAN');        
        indexS = planC{end};
        
        %Refresh Struct UIelements.
        set(ud.handles.strScan,  'visible', 'off');
        set(ud.handles.strName,  'visible', 'off');        
        set(ud.handles.strCheck, 'visible', 'off');                                
        firstVisStruct = ud.firstVisStruct;
        nStructs = length(ud.checkedStructs);  
        
        if nStructs > 16
            hSlider = findobj('tag','structSlider');
            set(hSlider,'enable', 'on','BackgroundColor',[0 0 0]);
            set(hSlider,'min',1,'max',nStructs,'value',nStructs,'sliderstep',[1/(nStructs-1) 1/(nStructs-1)]);         
            structSlider_clk('init',planC);
        else
            for i=1:length(planC{indexS.structures})
                structNum  = firstVisStruct+i-1;
                structName = planC{indexS.structures}(structNum).structureName;
                assocScan  = getStructureAssociatedScan(structNum, planC);
                set(ud.handles.strName(i), 'string', structName, 'visible', 'on');
                set(ud.handles.strScan(i), 'string', num2str(assocScan), 'visible', 'on');            
                set(ud.handles.strCheck(i), 'visible', 'on', 'value', ud.checkedStructs(structNum));
            end
        end
                
        %Refresh scan struct UIelements.
        set(ud.handles.scanSize,  'visible', 'off');
        set(ud.handles.scanName,  'visible', 'off');        
        set(ud.handles.scanCheck, 'visible', 'off');                                
        nScans = length(ud.checkedScans);
        firstVisScan = ud.firstVisScan;
        
        if nScans > 6
            hSlider = findobj('tag','scanSlider');
            set(hSlider,'enable', 'on','BackgroundColor',[0 0 0]);
            set(hSlider,'min',1,'max',nScans,'value',nScans,'sliderstep',[1/(nScans-1) 1/(nScans-1)]);
            scanSlider_clk('init', planInfo, planC);
        else
            for i=1:min(length(ud.handles.scanName), nScans)
                scanNum  = firstVisScan+i-1;
                modality = planInfo.scans(scanNum).modality;
                size     = planInfo.scans(scanNum).sizeInMB;                
                set(ud.handles.scanNumber(i), 'string', num2str(scanNum), 'visible', 'on');
                set(ud.handles.scanName(i), 'string', modality, 'visible', 'on');
                set(ud.handles.scanSize(i), 'string', [num2str(round(size)) ' MB'], 'visible', 'on');
                set(ud.handles.scanCheck(i), 'visible', 'on', 'value', ud.checkedScans(scanNum));
            end
        end
        
        %Refresh dose struct UIelements.
        set(ud.handles.doseSize,  'visible', 'off');
        set(ud.handles.doseName,  'visible', 'off');        
        set(ud.handles.doseCheck, 'visible', 'off');                                
        nDoses = length(ud.checkedDoses);      
        firstVisDose = ud.firstVisDose;
        for i=1:min(length(ud.handles.doseName), nDoses)
            doseNum  = firstVisDose+i-1;
            doseName = planC{indexS.dose}(doseNum).fractionGroupID;
            size     = planInfo.doses(doseNum).sizeInMB;            
            set(ud.handles.doseName(i), 'string', doseName, 'visible', 'on');
            set(ud.handles.doseSize(i), 'string',[num2str(round(size)) ' MB'], 'visible', 'on');            
            set(ud.handles.doseCheck(i), 'visible', 'on', 'value', ud.checkedDoses(doseNum));
        end 
        set(hFig, 'userdata',ud);
        
    case 'CHECK'
        checkNum = get(gcbo, 'userdata');
        type     = get(gcbo, 'Tag');
        value    = get(gcbo, 'value');
        
        ud = get(hFig, 'userdata');
        totStruct = ud.nStructs;
        switch upper(type)
            case 'DOSECHECK'
                ud.checkedDoses(checkNum+ud.firstVisDose-1) = value;
            case 'SCANCHECK'
                ud.checkedScans(checkNum+ud.firstVisScan-1) = value;                
            case 'STRUCTCHECK'
                slidStat = get(findobj('tag','structSlider'),'enable');
                if strcmpi(slidStat,'off')
                    ud.checkedStructs(checkNum+ud.firstVisStruct-1) = value;
                elseif strcmpi(slidStat,'on')
                    val = get(findobj('tag','structSlider'),'value');
                    if val == totStruct
                        startPt = totStruct-val;
                    else
                        startPt = totStruct-val-1;
                    end
                    ud.checkedStructs(checkNum+startPt+ud.firstVisStruct-1) = value;
                end
        end
        
        set(hFig, 'userdata', ud);
        
    case 'ALLCHECK'
        type     = get(gcbo, 'Tag');
        value    = get(gcbo, 'value');
        
        ud = get(hFig, 'userdata');
        
        switch upper(type)
            case 'DOSE'
                if length(ud.checkedDoses) > 0                
                    ud.checkedDoses(1:end) = value;
                end
            case 'SCAN'
                if length(ud.checkedScans) > 0
                    ud.checkedScans(1:end) = value;                
                end
            case 'STRUCT'
                if length(ud.checkedStructs) > 0                
                    ud.checkedStructs(1:end) = value;
                end
        end
        
        set(hFig, 'userdata', ud);
        planMergeGui('REFRESH');
        
        
    case 'MERGE'
        ud = get(hFig, 'userdata');
        mergePlan = getappdata(hFig, 'MERGEPLAN');
        
        global planC
        fileName = fullfile(get(ud.handles.pathText,'string'),get(ud.handles.filenameText,'string'));
        planMergeGui('status', 'Merging, please wait...');
        planC = planMerge(planC, mergePlan, find(ud.checkedScans), find(ud.checkedDoses), find(ud.checkedStructs), fileName);
        
        clear mergePlan;
        rmappdata(hFig, 'MERGEPLAN');        
                
        planMergeGui('CANCEL');
        stateS.planMerged = 1;
        
        %refresh navigation montage if it exists
        navFig = findobj('tag','navigationFigure');
        if ~isempty(navFig)
            navigationMontage('refresh')
        end
        
        %Refresh the Viewer
        currentAxis = stateS.currentAxis;
        for iAxis = 1:length(stateS.handle.CERRAxis)
            axView = getAxisInfo(stateS.handle.CERRAxis(iAxis),'view');
            if ismember(axView,{'transverse','sagittal','coronal'})
                stateS.currentAxis = iAxis;
                sliceCallBack('CHANGESLC','PREVSLICE')
                sliceCallBack('CHANGESLC','NEXTSLICE')
            end
        end
        stateS.currentAxis = currentAxis;        
        
end    