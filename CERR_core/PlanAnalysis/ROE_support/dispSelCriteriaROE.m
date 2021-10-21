function [currSelectedId,selTypeC] = dispSelCriteriaROE(hObj,hEvt,hFig,varargin)
%Display selected constraints
% AI 05/12/21

cMode = datacursormode(hFig);
%cMode.removeAllDataCursors;
cursorInfoS = getCursorInfo(cMode);


ud = guidata(hFig);
legH = ud.handle.legend;

if isempty(hEvt)  %Prog call
    
    %Get handles to constraints
    protS = ud.Protocols;
    type = varargin{1};
    idxV = varargin{2};
    pNum = varargin{3};
    
    %Turn off currently displayed limits
    hCrit = protS(pNum).criteria;
    hGuide = protS(pNum).guidelines;
    for k = 1:numel(hCrit)
        set(hCrit(k),'Visible','Off')
    end
    for k = 1:numel(hGuide)
        set(hGuide(k),'Visible','Off')
    end
    protS(pNum).criteria = hCrit;
    protS(pNum).guidelines = hGuide;
    
    
    %Turn on selected limit
    if strcmp(type,'criteria')
        hCrit = [protS(pNum).criteria];
        set(hCrit(idxV),'Visible','On');
        %numElements = [0,cumsum(arrayfun(@(x)numel(x.criteria),protS))];
        %for pNum = 1:numel(protS)
        %protS(pNum).criteria = hCrit(numElements(pNum)+1:numElements(pNum+1));
        %end
        protS(pNum).criteria = hCrit;
        
        drawnow;
        legH.EntryContainer.NodeChildren(2).Label.Color = [0,0,0];
        legH.EntryContainer.NodeChildren(1).Label.Color = [0.65,0.65,0.65];
    else
        hGuide = [protS(pNum).guidelines];
        set(hGuide(idxV),'Visible','On');
        %numElements = [0,cumsum(arrayfun(@(x)numel(x.guidelines),protS))];
        %for pNum = 1:numel(protS)
        %protS(pNum).guidelines = hGuide(numElements(pNum)+1:numElements(pNum+1));
        %end
        protS(pNum).guidelines = hGuide;
        
        drawnow;
        legH.EntryContainer.NodeChildren(1).Label.Color = [0,0,0];
        legH.EntryContainer.NodeChildren(2).Label.Color = [0.65,0.65,0.65];
    end
    
    ud.Protocols = protS;
    set(hFig,'userdata',ud);
    
else %Checkbox selection
    
    %Get handles to constraints
    protS = ud.Protocols;
    
    %Get slelected constraint
    currSelectedId = hEvt.Indices(:,1);
    datC = hObj.Data;
    stateV = cell2mat(hObj.Data(currSelectedId,1));
    stateC = {'Off','On'};
    
    if currSelectedId==1  %'All'
        for pNum = 1:numel(protS)
            hCrit = protS(pNum).criteria;
            hGuide = protS(pNum).guidelines;
            %Criteria
            for k = 1:numel(hCrit)
                set(hCrit(k),'Visible',stateC{stateV+1});
            end
            %Guidelines
            for k = 1:numel(hGuide)
                set(hGuide(k),'Visible',stateC{stateV+1});
            end
        end
        
        drawnow;
        legH.EntryContainer.NodeChildren(1).Label.Color = [0,0,0];
        legH.EntryContainer.NodeChildren(2).Label.Color = [0,0,0];

    elseif currSelectedId==2 %'None'
        if stateV == 1
            %Criteria
            for pNum = 1:numel(protS)
                hCrit = protS(pNum).criteria;
                hGuide = protS(pNum).guidelines;
                for k = 1:numel(hCrit)
                    set(hCrit(k),'Visible','Off');
                end
                %Guidelines
                for k = 1:numel(hGuide)
                    set(hGuide(k),'Visible','Off');
                end
            end
        end
        hObj.Data(:,1) = {false};
        
        drawnow;
        legH.EntryContainer.NodeChildren(1).Label.Color = [0.65,0.65,0.65];
        legH.EntryContainer.NodeChildren(2).Label.Color = [0.65,0.65,0.65];
        
    else
        
        protS = ud.Protocols;
        currProtocol = ud.foreground;
        gNum = numel(protS(currProtocol).guidelines);
        
        currSelectedId = currSelectedId-2;
        type =  get(hObj,'userdata');
        selTypeC = type(currSelectedId);
        
        for pNum = 1:numel(protS)
            for k = 1:numel(currSelectedId)
                if strcmp(selTypeC(k),'guidelines') %guidelines
                    selNum = currSelectedId(k);
                    if strcmp(stateC{stateV+1},'On')
                        drawnow;
                        legH.EntryContainer.NodeChildren(1).Label.Color = [0,0,0];
                    else
                        drawnow;
                        legH.EntryContainer.NodeChildren(1).Label.Color = [0.65,0.65,0.65];
                    end
                else                               %criteria
                    selNum = currSelectedId(k)- gNum;
                    if strcmp(stateC{stateV+1},'On')
                        drawnow;
                        legH.EntryContainer.NodeChildren(2).Label.Color = [0,0,0];
                    else
                        drawnow;
                        legH.EntryContainer.NodeChildren(2).Label.Color = [0.65,0.65,0.65];
                    end
                end
                %Toggle display on/off
                set(protS(pNum).(selTypeC{k})(selNum),'Visible',stateC{stateV(k)+1});
                %Expand tooltip if on
                if strcmp(stateC{stateV+1},'On')
                    %Check if datatip exists
                    if ~isfield(ud.handle,'datatips')
                        ud.handle.datatips = [];
                    end
                    
                    target = protS(pNum).(selTypeC{k})(selNum);
                    createDataTipROE(hFig,target);
                end
                
            end
        end
        
    end
    
end

ud.Protocols = protS;
ud.handle.legend = legH;
guidata(hFig,ud);

end