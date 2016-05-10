function addScansToMenu(hScanMenu,topMenuFlag)
% function addScansToMenu(hScanMenu,topMenuFlag)
%
%
% APA, 03/28/2016

global planC stateS
indexS = planC{end};

% Group Scans by scanType in case there are more than 20 scans.
scanTypeC = {planC{indexS.scan}.scanType};
for scanNum = 1:length(planC{indexS.scan})
    scanDatesC{scanNum} = planC{indexS.scan}(scanNum).scanInfo(1).scanDate;
end
numScans = length(scanTypeC);

maxScansPerGroup = 15;

if ~topMenuFlag
    hMenu = get(hScanMenu,'parent');
    hAxis = get(hMenu, 'userdata');
    scanSets = getAxisInfo(hAxis,'scanSets');
end

if numScans > maxScansPerGroup
    
    hSubScanMenu = [];
    
    [~,indSortV] = sortrows([scanDatesC' scanTypeC']);
    currInd = 1;
    changeInd = currInd;
    currentScan = indSortV(currInd);
    scanType = planC{indexS.scan}(currentScan).scanType;
        
    while currInd <= numScans
        
        currentScan = indSortV(currInd);
        if mod(currInd-changeInd,maxScansPerGroup) == 0 || ~strcmpi(scanType,planC{indexS.scan}(currentScan).scanType)            
            if ishandle(hSubScanMenu)
                rangeStr = [num2str(changeInd),'-',num2str(currInd-1)];
                set(hSubScanMenu,'label',[scanType,' (',rangeStr,')'])
            end
            changeInd = currInd;
            % Create new sub-level
            hSubScanMenu = uimenu(hScanMenu, 'label', planC{indexS.scan}(currentScan).scanType,...
                'interruptible','on','separator','on', 'Checked', 'off');  
            scanType = planC{indexS.scan}(currentScan).scanType;
        end
        
        scanDate = planC{indexS.scan}(currentScan).scanInfo(1).scanDate;
        dateString = '';
        if ~isempty(scanDate)
            dateString = datestr(datenum(planC{indexS.scan}(currentScan)...
                .scanInfo(1).scanDate,'yyyymmdd'));
        end
        
        str2 = num2str(currentScan);    
        if topMenuFlag
            hScan = uimenu(hSubScanMenu, 'label', [str2,'. ',scanType, ' (',dateString,')'],...
                'callback',['sliceCallBack(''selectScan'',''', str2 ,''')'],...
                'interruptible','on','separator','off', 'Checked', 'off');
            if stateS.scanSet == currentScan
                set(hScan,'Checked','on')
            end
            
        else
            hScan = uimenu(hSubScanMenu, 'label', [str2,'. ',scanType, ' (',dateString,')'],...
                'callback','CERRAxisMenu(''SET_SCAN'')','userdata', {hAxis, currentScan},...
                'interruptible','on','separator','off', 'Checked', 'off');
            if ismember(currentScan,scanSets)
                set(hScan,'Checked','on')
            end
        end
        
        currInd = currInd + 1;
        
    end
    rangeStr = [num2str(changeInd),'-',num2str(numScans)];
    set(hSubScanMenu,'label',[scanType,' (',rangeStr,')'])
    
    return;
    
end


%Add current scan elements to menu.
for i = 1 : numScans
    str = [num2str(i) '.  ' planC{indexS.scan}(i).scanType];
    str2 = num2str(i);
    if topMenuFlag
        hScan = uimenu(hScanMenu, 'label', str,...
            'callback',['sliceCallBack(''selectScan'',''', str2 ,''')'],...
            'interruptible','on','separator','off', 'Checked', 'off');
        if isfield(stateS,'scanSet') && stateS.scanSet == i
            set(hScan,'Checked','on')
        end

    else
        hScan = uimenu(hScanMenu, 'label', str,...
            'callback','CERRAxisMenu(''SET_SCAN'')','userdata', {hAxis, i},...
            'interruptible','on','separator','off',...
            'Checked', 'off');
        if ismember(i,scanSets)
            set(hScan,'Checked','on')
        end
    end
    if i == 1
        set(hScan,'separator','on')
    end
   
end

