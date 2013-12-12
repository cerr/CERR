function scanSlider_clk(command, varargin)
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
persistent planC planInfo
if ~isempty(varargin)
    planInfo = varargin{1};
    planC = varargin{2};
end
indexS = planC{end};

ud = get(findobj('Tag', 'CERR_PlanMergeGui'),'userdata');

hSlider = findobj('Tag','scanSlider');
firstVisScan = ud.firstVisScan;
switch lower(command)
    case 'init'
        for i=1:6
            scanNum  = firstVisScan+i-1;
            modality = planInfo.scans(scanNum).modality;
            size     = planInfo.scans(scanNum).sizeInMB;
            set(ud.handles.scanNumber(i), 'string', num2str(scanNum), 'visible', 'on','tag','oldScan');
            set(ud.handles.scanName(i), 'string', modality, 'visible', 'on','tag','oldScan');
            set(ud.handles.scanSize(i), 'string', [num2str(round(size)) ' MB'], 'visible', 'on','tag','oldScan');
            set(ud.handles.scanCheck(i), 'visible', 'on', 'value', ud.checkedScans(scanNum));
            
        end
        
        
    case 'clicked'
        %         try
        %             delete(findobj('tag','oldStr'))
%         end
        val = get(hSlider,'value');
        if val == length(planC{indexS.scan})
            return
        else
            startPt = length(planC{indexS.scan})-val;
        end
%         for i=1:16
%             ud.handles.strName(i)  = uicontrol(hFig, 'units',units,'Position',[dx+10+15 loadbot-66-i*20 80 15], 'style', 'text', 'String', 'CT Scan', 'backgroundcolor', frameColor, 'visible', 'off');   
%             ud.handles.strScan(i)  = uicontrol(hFig, 'units',units,'Position',[dx+10+100 loadbot-66-i*20 60 15], 'style', 'text', 'String', '1', 'backgroundcolor', frameColor, 'visible', 'off');   
%             ud.handles.strCheck(i) = uicontrol(hFig, 'units',units,'Position',[dx+10+185 loadbot-66-i*20 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'StructCheck', 'callback', 'planMergeGui(''Check'')', 'visible', 'off');                         
%         end
        for i = 1:6
            scanNum  = ceil(startPt+i-1); 
            
            if scanNum > length(planC{indexS.scan})  
                break
            end
            modality = planInfo.scans(scanNum).modality;
            size     = planInfo.scans(scanNum).sizeInMB;
            set(ud.handles.scanNumber(i), 'string', num2str(scanNum), 'visible', 'on');
            set(ud.handles.scanName(i), 'string', modality, 'visible', 'on');
            set(ud.handles.scanSize(i), 'string', [num2str(round(size)) ' MB'], 'visible', 'on');
            set(ud.handles.scanCheck(i), 'visible', 'on', 'value', ud.checkedScans(scanNum));
            if val+1<6
                set(findobj('tag','oldScan'),'visible','off');
                set(findobj('tag', 'ScanCheck'),'visible','off');
            end
        end
        
end
