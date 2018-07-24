function addScansToMenu(hScanMenu,topMenuFlag,selectedScan)
% function addScansToMenu(hScanMenu,topMenuFlag)
%
%
% APA, 03/28/2016
% AI, 01/09/2018 : Additional grouping of scans by type
% AI, 07/24/18 Bug fix for empty scan type

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

if nargin==2 && isfield(stateS,'scanSet')
    selectedScan = stateS.scanSet;   %%ADDED 
end


if numScans > maxScansPerGroup
    
    hSubScanMenu = [];
    
    [~,indSortV] = sortrows([scanDatesC' scanTypeC'],2);
    currInd = 1;
    changeInd = currInd; 
    currentScan = indSortV(currInd);
    scanType = 'NoScans';
    %hScanGroupMenu = [];
    
    while currInd <= numScans
        
        currentScan = indSortV(currInd);
        if ~strcmpi(scanType,planC{indexS.scan}(currentScan).scanType)
            if sum(strcmp(planC{indexS.scan}(currentScan).scanType,...
                    {planC{indexS.scan}.scanType}))>1
                hScanGroupMenu = uimenu(hScanMenu, 'label', planC{indexS.scan}(currentScan).scanType,...
                    'interruptible','on','separator','on', 'Checked', 'off');
                changeInd = currInd;
                dispIdx = 1;
            else
                hScanGroupMenu = [];
                hSubScanMenu = uimenu(hScanMenu, 'label', planC{indexS.scan}(currentScan).scanType,...
                    'interruptible','on','separator','on', 'Checked', 'off');
            end
        end
    
        
        scanType = planC{indexS.scan}(currentScan).scanType;
        if mod(currInd-changeInd,maxScansPerGroup) == 0 %Changed
            if ishandle(hScanGroupMenu)
                %create new sub-level
                hSubScanMenu = uimenu(hScanGroupMenu, 'label', planC{indexS.scan}(currentScan).scanType,...
                    'interruptible','on','separator','on', 'Checked', 'off');
                groupEndScan = min(currentScan+maxScansPerGroup-1,length(planC{indexS.scan}));
                groupIdxV = strcmp(scanType,{planC{indexS.scan}(currentScan:groupEndScan).scanType});
                endIdx = find(groupIdxV,1,'last');
                rangeStr = [num2str(dispIdx),'-',num2str(dispIdx+endIdx-1)];
                set(hSubScanMenu,'label',[scanType,' (',rangeStr,')']);
                dispIdx = dispIdx + maxScansPerGroup;
            end
        end
        
        
        scanDate = planC{indexS.scan}(currentScan).scanInfo(1).scanDate;
        dateString = '';
        if ~isempty(scanDate)
            try
                dateString = datestr(datenum(planC{indexS.scan}(currentScan)...
                    .scanInfo(1).scanDate,'yyyymmdd'));
            catch
                dateString = planC{indexS.scan}(currentScan).scanInfo(1).scanDate;
            end
        end
        
        scanDescription = planC{indexS.scan}(currentScan).scanInfo(1).scanDescription; %AI 5/9/17 Display series description    
        if isempty(scanDescription)
            scanTitle = scanType;
        else
            scanTitle = [scanType,': ',scanDescription];
        end

        str2 = num2str(currentScan);
        if topMenuFlag
           
            hScan = uimenu(hSubScanMenu, 'label', [str2,'. ',scanTitle, ' (',dateString,')'],...
                'callback',['sliceCallBack(''selectScan'',''', str2 ,''')'],...
                'tag', ['scanItem',str2],...                               %ADDED
                'interruptible','on','separator','off', 'Checked', 'off');
            
            if selectedScan == currentScan
                set(hScan,'Checked','on')
            end
            
        else
            hScan = uimenu(hSubScanMenu, 'label', [str2,'. ',scanType, ' (',dateString,')'],...
                'callback','CERRAxisMenu(''SET_SCAN'')','userdata', {hAxis, currentScan},...
                'tag', ['scanItem',str2],...                               %ADDED
                'interruptible','on','separator','off', 'Checked', 'off');
            
            if ismember(currentScan,scanSets)
                set(hScan,'Checked','on')
            end
        end
        
        currInd = currInd + 1;
        
    end
    
    return;
    
end


%Add current scan elements to menu.
for i = 1 : numScans
    str = [num2str(i) '.  ' planC{indexS.scan}(i).scanType];
    str2 = num2str(i);
    if topMenuFlag
        hScan = uimenu(hScanMenu, 'label', str,...
            'callback',['sliceCallBack(''selectScan'',''', str2 ,''')'],...
            'interruptible','on','separator','off', 'Checked', 'off',...
            'tag', ['scanItem',str2]);                        %ADDED
        if isfield(stateS,'scanSet') && selectedScan(1) == i
            set(hScan,'Checked','on')
        end
        
    else
        hScan = uimenu(hScanMenu, 'label', str,...
            'callback','CERRAxisMenu(''SET_SCAN'')','userdata', {hAxis, i},...
            'interruptible','on','separator','off',...
            'Checked', 'off', 'tag', ['scanItem',str2]);      %ADDED
        if ismember(i,scanSets)
            set(hScan,'Checked','on')
        end
    end
    if i == 1
        set(hScan,'separator','on')
    end
    
end

