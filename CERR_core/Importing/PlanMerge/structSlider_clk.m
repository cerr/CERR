function structSlider_clk(command,varargin)
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
persistent planC
if ~isempty(varargin)
    planC = varargin{1};
end
indexS = planC{end};

ud = get(findobj('Tag', 'CERR_PlanMergeGui'),'userdata');

hSlider = findobj('Tag','structSlider');
firstVisStruct = ud.firstVisStruct;
switch lower(command)
    case 'init'
        for i=1:16
            structNum  = firstVisStruct+i-1;
            structName = planC{indexS.structures}(structNum).structureName;
            assocScan  = getStructureAssociatedScan(structNum, planC);
            set(ud.handles.strName(i), 'string', structName, 'visible', 'on','tag','oldStr');
            set(ud.handles.strScan(i), 'string', num2str(assocScan), 'visible', 'on','tag','oldStr');            
            set(ud.handles.strCheck(i), 'visible', 'on', 'value', ud.checkedStructs(structNum));
        end

        
    case 'clicked'       
%         try
%             delete(findobj('tag','oldStr'))
%         end
        val = get(hSlider,'value');
        if val == length(planC{indexS.structures})
            return
        else
            startPt = length(planC{indexS.structures})-val;
        end
%         for i=1:16
%             ud.handles.strName(i)  = uicontrol(hFig, 'units',units,'Position',[dx+10+15 loadbot-66-i*20 80 15], 'style', 'text', 'String', 'CT Scan', 'backgroundcolor', frameColor, 'visible', 'off');   
%             ud.handles.strScan(i)  = uicontrol(hFig, 'units',units,'Position',[dx+10+100 loadbot-66-i*20 60 15], 'style', 'text', 'String', '1', 'backgroundcolor', frameColor, 'visible', 'off');   
%             ud.handles.strCheck(i) = uicontrol(hFig, 'units',units,'Position',[dx+10+185 loadbot-66-i*20 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'StructCheck', 'callback', 'planMergeGui(''Check'')', 'visible', 'off');                         
%         end
        for i = 1:16
            structNum  = ceil(startPt+i-1); 
            
            if structNum > length(planC{indexS.structures})  
                break
            end
            structName = planC{indexS.structures}(structNum).structureName;
            assocScan  = getStructureAssociatedScan(structNum, planC);
            set(ud.handles.strName(i), 'string', structName, 'visible', 'on');
            set(ud.handles.strScan(i), 'string', num2str(assocScan), 'visible', 'on');            
            set(ud.handles.strCheck(i), 'visible', 'on', 'value', ud.checkedStructs(structNum));
            if val+1<16
                set(findobj('tag','oldStr'),'visible','off');
                set(findobj('Tag', 'StructCheck'),'visible','off');
            end
        end
        
end
