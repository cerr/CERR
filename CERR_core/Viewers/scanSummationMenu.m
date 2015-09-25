function scanSummationMenu(command)
%"scanSummationMenu"
%   Create the GUI used to sum scans.
%
%   02/15/08  APA Based on scanSummationMenu
%
%Usage:
%   scanSummationMenu()
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
indexS = planC{end};

if nargin == 0
    command = 'init';
end

hFig = findobj('tag', 'CERRScanSummationFigure');

switch upper(command)
    case 'INIT'
        if ~isempty(hFig)
            delete(hFig);
        end
        screenSize = get(0,'ScreenSize');        
        units = 'pixels';
        y = 480;
        x = 480;

        dx = 20;
        dy = 20;
        
        hFig = figure('Name', 'Scan Summation', 'doublebuffer', 'on', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'CERRScanSummationFigure');    
        stateS.handle.scanSummationMenuFig = hFig; 

        bartop = 80;        
        loadbot = y-65-10;
        
        ud.handles.instruction = uicontrol('units',units,'HorizontalAlignment','left','Position',[dx y-dy-60 x-2*dx 20],'String', 'Select the scans to be included in the sum scan.', 'Style','text','Tag','text1');
        ud.handles.labelname = uicontrol('units',units,'HorizontalAlignment','left','Position',[dx y-dy-10 100 15],'String', 'New Scan Name:', 'Style','text','Tag','text2'); 
        ud.handles.newScanName = uicontrol('units',units,'Position',[dx y-dy-35 120 20],'BackgroundColor',[1 1 1],'HorizontalAlignment','left','String', '', 'Style','edit','Tag','scanName');          
        ud.handles.assocname = uicontrol('units',units,'HorizontalAlignment','left','Position',[x-dx-250 y-dy-10 140 15],'String', 'Prefer Images from:', 'Style','text','Tag','scanAssoc');
        for i=1:length(planC{indexS.scan})
            scanStr{i} = [num2str(i), '. ', planC{indexS.scan}(i).scanType];
        end        
        ud.handles.scanSelect = uicontrol('units',units,'Position',[x-dx-250 y-dy-35 120 20],'BackgroundColor',[1 1 1],'HorizontalAlignment','left','String', scanStr, 'Style','popup','value',1,'Tag','scanSelect');

        %Make CANCEL and SUM buttons
        ud.handles.cancelButton = uicontrol(hFig, 'callback', 'scanSummationMenu(''CANCEL'');', 'units',units,'Position',[x-dx-70 y-dy-35 70 20],'String','Cancel', 'Style','pushbutton','Tag','cancelButton');
        ud.handles.sumButton = uicontrol(hFig, 'callback', 'scanSummationMenu(''SUM'');', 'units',units, 'Position',[x-dx-70 y-dy-10 70 20],'String','Sum', 'Style','pushbutton','Tag','sumButton');
        
        %Plans frame and label
        planFrame  = uicontrol(hFig, 'units',units,'Position',[dx dy x-2*dx y-dy-bartop], 'style', 'frame');
        frameColor = get(planFrame, 'BackgroundColor');           

        %Create scrollbar on right side. Inactive to start.
        ud.df.handles.scroll = uicontrol(hFig, 'units',units,'Position',[x-dx-20 dy 20 y-dy-bartop], 'style', 'slider', 'enable', 'off','tag','planSlider', 'callback', 'scanSummationMenu(''SLIDER'')');              
        
        %Create plan UICONTROLS.
        uicontrol(hFig, 'units',units,'Position',[30 loadbot-46 15 15], 'style', 'text', 'String', 'No.', 'fontweight', 'bold', 'backgroundcolor', frameColor);   
        %uicontrol(hFig, 'units',units,'Position',[40 loadbot-46 100 15], 'style', 'text', 'String', 'Plan Name', 'fontweight', 'bold', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[dx+100 loadbot-46 70 15], 'style', 'text', 'String', 'Assoc Scan', 'fontweight', 'bold', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[dx+210 loadbot-46 60 15], 'style', 'text', 'String', 'Select', 'fontweight', 'bold', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[dx+270 loadbot-46 100 15], 'style', 'text', 'String', 'Weighting Factor', 'fontweight', 'bold', 'backgroundcolor', frameColor);     
        
        numRows = 50;
        for i=1:numRows
            ud.handles.scanNum(i)   = uicontrol(hFig, 'units',units,'Position',[30 359-i*20 10 15], 'style', 'text', 'String', num2str(i), 'backgroundcolor', frameColor, 'visible', 'off');    
            ud.handles.scanName(i)  = uicontrol(hFig, 'units',units,'Position',[dx+100 359-i*20 40 15], 'style', 'text', 'String', 'Scan', 'backgroundcolor', frameColor, 'visible', 'off');    
            ud.handles.scanCheck(i) = uicontrol(hFig, 'units',units,'Position',[dx+210 359-i*20 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'ScanCheck', 'callback', 'scanSummationMenu(''Check'')', 'visible', 'off');  
            ud.handles.wtfactor(i)  = uicontrol(hFig, 'units',units,'Position',[dx+270 359-i*20 45 15], 'Style','edit', 'String', '1.0', 'BackgroundColor',[1 1 1],'horizontalAlignment', 'center','Tag','wtfactor', 'callback', 'scanSummationMenu(''Check'')', 'visible', 'off'); 
        end
        ud.numScanRows = numRows; 
        
        ud.firstVisScan     = 1;
        
        set(hFig, 'userdata', ud);   
        
        nScans = length(planC{indexS.scan});
        ud.checkedScans = zeros(nScans, 1);
        
        
        %Set range of currently displayed scans.
        ud.df.range = 1:min(16, nScans);

        set(hFig, 'userdata', ud);
        scanSummationMenu('refresh');        

        
    case 'REFRESH'
        ud = get(hFig, 'userdata');     
        indexS = planC{end};
        
        %Number of visible scans.
        nvScans = length(ud.df.range);
        
        %Refresh scan UIelements.
        set(ud.handles.scanNum,  'visible', 'off');
        set(ud.handles.scanName,  'visible', 'off');        
        set(ud.handles.scanCheck, 'visible', 'off'); 
        set(ud.handles.wtfactor, 'visible', 'off');
        nScans = length(ud.checkedScans);      
        ud.firstVisScan = min(ud.df.range);
        for i=1:min(length(ud.handles.scanName), nvScans)
            scanNum  = ud.firstVisScan+i-1;
            scanName = [num2str(scanNum),'. ',planC{indexS.scan}(scanNum).scanType];
            set(ud.handles.scanNum(scanNum),'visible', 'on')
            set(ud.handles.scanName(scanNum), 'string', scanName, 'visible', 'on', 'Position',[20+100 359-i*20 80 15]);     
            set(ud.handles.scanCheck(scanNum), 'visible', 'on', 'Position',[20+240 359-i*20 25 15]);
            set(ud.handles.wtfactor(scanNum), 'visible', 'on', 'Position',[20+300 359-i*20 45 15]);
        end 
        
        if nScans > 16
            set(ud.df.handles.scroll, 'min', 0, 'max', nScans-nvScans, 'value', nScans-nvScans+1-min(ud.df.range), 'enable', 'on', 'sliderstep', [1/(nScans-nvScans), nvScans/(nScans-nvScans)]);
        else
            set(ud.df.handles.scroll, 'enable', 'off');
        end

        set(hFig, 'userdata', ud);
        
    case 'CHECK'
        checkNum = get(gcbo, 'userdata');
        type     = get(gcbo, 'Tag');
        value    = get(gcbo, 'value');
        
        ud = get(hFig, 'userdata');
        
        switch upper(type)
            case 'SCANCHECK'
                ud.checkedScans(checkNum+ud.firstVisScan-1) = value;
                if value == 1
                    set(ud.handles.newScanName,'string',planC{indexS.scan}(checkNum).scanType)
                    set(ud.handles.scanSelect,'value',checkNum)
                end                
%             case 'WTFACTOR'
%                 factor = str2num(get(ud.handles.wtfactor(i), 'String'));
        end
        
        set(hFig, 'userdata', ud);      
       
        
    case 'SLIDER'
        %Slider was clicked, move ud.df.range.
        ud = get(hFig, 'userdata');
        val = round(get(gcbo, 'value'));
        
        nRows = 16;
        nScans  = length(planC{indexS.scan});
        
        lastScan = nScans - val;
        ud.df.range = max(1, lastScan-nRows+1):lastScan;
        set(hFig, 'userdata', ud);        
        scanSummationMenu('REFRESH');  

        
    case 'SUM'
        hFig = findobj('tag', 'CERRScanSummationFigure');
        ud = get(hFig, 'userdata');
        checkedScans = find(ud.checkedScans);
        if length(checkedScans) < 2
			warndlg('You must select atleast two scans','Incorrect Selection','modal')
            return
        end
        
        % Check for duplicate or blank name.
        newScanName = get(ud.handles.newScanName, 'String');        
        if isempty(newScanName)
            warndlg('Please enter a name for the new scan.', 'Warning','modal');
            return;
        end
        
        %Check that no checked plan has a weighting factor that is blank.
        for i = 1:length(planC{indexS.scan})
            factor = str2num(get(ud.handles.wtfactor(i), 'String'));
            if isempty(factor) && ~isempty(find(checkedScans == i))
                warndlg('Please enter a weighting factor for all selected scans.', 'Warning','modal');
                return
            elseif isempty(factor)
                factor = 0;
            end
            wtfactor(i) = factor;
        end        
        
        %% APA code begins
        assocScan = get(ud.handles.scanSelect,'value');
        [xAssocV, yAssocV, zAssocV] = getScanXYZVals(planC{indexS.scan}(assocScan));

        if assocScan > 0
            assocScanUID = planC{indexS.scan}(assocScan).scanUID;
            %Get associated transM
            assocTransM = planC{indexS.scan}(assocScan).transM;
            if isempty(assocTransM)
                assocTransM = eye(4);
            end
        else %No Association
            assocScanUID = '';
            assocTransM = eye(4);
        end

        scanNums = checkedScans;
        
        %Get the x,y,z grid for new scan
        for i = 1:length(scanNums)
            scanNum = scanNums(i);
            %Get x,y,z values for scanNum
            [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanNum));

            %Get the corners of the original dataset.
            [xCorn, yCorn, zCorn] = meshgrid([min(xV) max(xV)], [min(yV) max(yV)], [min(zV) max(zV)]);

            %Add ones to the corners so we can apply a transformation matrix.
            corners = [xCorn(:) yCorn(:) zCorn(:) ones(prod(size(xCorn)), 1)];

            %Apply transform to corners, so we know boundary of the slice.
            transM = getTransM(planC{indexS.scan}(scanNum),planC);
            if isempty(transM) || isequal(transM,eye(4))
                [xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
                xGrid{scanNum} = xV(:)';
                yGrid{scanNum} = yV(:)';
                zGrid{scanNum} = zV(:)';
            else
                newCorners = inv(assocTransM) * transM * corners';
                xGrid{scanNum} = linspace(min(newCorners(1,:)), max(newCorners(1,:)), length(xV));
                yGrid{scanNum} = linspace(max(newCorners(2,:)), min(newCorners(2,:)), length(yV));
                zGrid{scanNum} = linspace(min(newCorners(3,:)), max(newCorners(3,:)), length(zV));
            end
            xRes{scanNum} = length(xV);
            yRes{scanNum} = length(yV);
            zRes{scanNum} = length(zV);
            
            %Get associated scan
            assocScanV{scanNum} = scanNum;
        end
        newXgrid = linspace(min(cell2mat(xGrid)),max(cell2mat(xGrid)),max(cell2mat(xRes)));
        newYgrid = linspace(max(cell2mat(yGrid)),min(cell2mat(yGrid)),max(cell2mat(yRes)));
        newZgrid = linspace(min(cell2mat(zGrid)),max(cell2mat(zGrid)),round(max(cell2mat(zRes))*1.5));

%         %Obtain scans with same grid
%         if isempty(assocTransM)
%             assocTransM = eye(4);
%         end        
%         scanIndC = {};
%         scanNumsTmp = scanNums;
%         for iSortAll = 1:length(scanNums)
%             iSort = scanNums(iSortAll);
%             indRemaining = scanNums;
%             indRemaining(iSortAll) = [];
%             scanSortM = [iSort];
%             if ~ismember(iSort,[scanIndC{:}])
%                 for jSortAll = 1:length(indRemaining)
%                     jSort = indRemaining(jSortAll);
%                     if ~isempty(getTransM('scan',iSort,planC))
%                         scanITM = inv(assocTransM) * getTransM('scan',iSort,planC);
%                     else
%                         scanITM = inv(assocTransM);
%                     end
%                     if ~isempty(getTransM('scan',jSort,planC))
%                         scanJTM = inv(assocTransM) * getTransM('scan',jSort,planC);
%                     else
%                         scanJTM = inv(assocTransM);
%                     end
%                     if isequal([xRes{iSort},yRes{iSort},zRes{iSort}],[xRes{jSort},yRes{jSort},zRes{jSort}]) && isequal(scanITM,scanJTM)
%                         scanSortM(end+1) = jSort;
%                         indJsort = find(scanNumsTmp == jSort);
%                         scanNumsTmp(indJsort) = [];
%                     end
%                 end
%             end
%             scanIndC{iSort} = scanSortM;
%         end
%         
%         scanNums = scanNumsTmp;
        
        %Loop over scans and add over new grid
        hWait = waitbar(0,['Appending one scans to Scan # ',num2str(assocScan)]);
        scanSumM = zeros([length(newYgrid),length(newXgrid),length(newZgrid)],'single');
        scanEmptyM = zeros([length(newYgrid),length(newXgrid)],'single');
        
        for i = 1:length(scanNums)
            
            scanNum = scanNums(i);
            
            %Check for transM
            if ~isempty(assocTransM) && ~isequal(assocTransM,eye(4))
                scanTtransM = getTransM('scan',scanNum,planC);
                if isempty(scanTtransM)
                    scanTtransM = eye(4);
                end
                inputTM = inv(assocTransM) * scanTtransM;
            else
                inputTM = getTransM('scan',scanNum,planC);
                if isempty(inputTM)
                    inputTM = eye(4);
                end
            end

%             %Get the summation for this grid
%             scanCombinedM = [];
%             for iScanAll = 1:length(scanIndC{scanNum})
%                 iScan = scanIndC{scanNum}(iScanAll);
%                 if ~isempty(scanCombinedM)
%                     scanCombinedM = scanCombinedM + wtfactor(iScan) * single(getScanArray(planC{indexS.scan}(iScan)));
%                 else
%                     scanCombinedM = wtfactor(iScan) * single(getScanArray(planC{indexS.scan}(iScan)));
%                 end
%             end

            %Check if this scan is on same grid as the new one
            %if isequal(xGrid{scanNum},newXgrid) && isequal(yGrid{scanNum},newYgrid) && isequal(zGrid{scanNum},newZgrid)
            chkLength = length(xGrid{scanNum})==length(newXgrid) && length(yGrid{scanNum})==length(newYgrid) && length(zGrid{scanNum})==length(newZgrid);
            if 0 && sum(sum((inputTM-eye(4)).^2)) < 1e-5 && chkLength && max(abs(xGrid{scanNum}-newXgrid)) < 1e-6 && max(abs(yGrid{scanNum}-newYgrid)) < 1e-6 && max(abs(zGrid{scanNum}-newZgrid)) < 1e-6

                scanSumM = scanSumM + scanCombinedM;
                waitbar((i-1)/length(scanNums),hWait,['Calculating contribution from Scan ', num2str(scanNum)])

            else %interpolation required

                %Transform this scan
                scanTmpM = [];

                for slcNum=1:length(newZgrid)
                    [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
                    if min(zAssocV)<newZgrid(slcNum) && newZgrid(slcNum)<max(zAssocV) && scanNum ~= assocScan
                        scanTmp = [];
                    else
                        scanTmp = slice3DVol(planC{indexS.scan}(scanNum).scanArray, xV, yV, zV, newZgrid(slcNum), 3, 'linear', inputTM, [], newXgrid, newYgrid);
                    end
                    if isempty(scanTmp)
                        scanTmpM(:,:,slcNum) = scanEmptyM;
                    else
                        scanTmpM(:,:,slcNum) = scanTmp;
                    end
                    waitbar((i-1)/length(scanNums) + (slcNum-1)/length(newZgrid)/length(scanNums) ,hWait,['Calculating contribution from Scan ', num2str(scanNum)])
                end
                
                scanSumM = scanSumM + wtfactor(scanNum) * scanTmpM;
                
            end

        end
        
        delete(hWait)

        %Create new scan distribution
        newScanNum = length(planC{indexS.scan}) + 1;
        newScanS = initializeCERR('scan');
        newScanS(1).scanArray = scanSumM;        
        newScanS(1).scanType = newScanName;
        newScanS(1).scanUID = createUID('scan');
        newScanS(1).transM = planC{indexS.scan}(assocScan).transM;
        scanInfoS = planC{indexS.scan}(assocScan).scanInfo(1);
        scanInfoS.grid1Units = abs(newYgrid(1)-newYgrid(2));
        scanInfoS.grid2Units = abs(newXgrid(1)-newXgrid(2)); 
        scanInfoS.scanFileName = '';
        scanInfoS.DICOMHeaders = '';
        scanInfoS.sliceThickness =  abs(newZgrid(1)-newZgrid(2));
        scanInfoS.voxelThickness =  abs(newZgrid(1)-newZgrid(2));
        scanInfoS.sizeOfDimension1 = size(scanSumM,1);
        scanInfoS.sizeOfDimension2 = size(scanSumM,2);
        clear scanSumM
        for sInfoNum = 1:length(newZgrid)
            scanInfoNewS = scanInfoS;
            scanInfoNewS.zValue = newZgrid(sInfoNum);
            newScanS(1).scanInfo(sInfoNum) = scanInfoNewS;
        end
        planC{indexS.scan} = dissimilarInsert(planC{indexS.scan},newScanS,newScanNum);
        planC = setUniformizedData(planC);

        % Save scan statistics for fast image rendering
        for scanNum = newScanNum
            scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanNum).scanUID(max(1,end-61):end))];
            stateS.scanStats.minScanVal.(scanUID) = single(min(planC{indexS.scan}(scanNum).scanArray(:)));
            stateS.scanStats.maxScanVal.(scanUID) = single(max(planC{indexS.scan}(scanNum).scanArray(:)));
        end
        
        %switch to new scan, with a short pause to let the dialogue clear.
        pause(.1);
        sliceCallBack('selectScan', num2str(newScanNum));
        
        %Refresh this GUI to include new scan distribution
        ud.df.range = [ud.df.range ud.df.range(end)+1];
        if length(ud.df.range)>16
            ud.df.range = ud.df.range(2:17);
        end
        set(hFig, 'userdata', ud);
        scanSummationMenu('refresh')        

        %% APA code ends

        
        
    case 'CANCEL'
        hFig = findobj('tag', 'CERRScanSummationFigure');
        delete(hFig);
end
