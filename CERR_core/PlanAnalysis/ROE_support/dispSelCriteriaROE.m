function [selectedIdv,selTypeC] = dispSelCriteriaROE(hObj,hEvt,hFig,varargin)
%Display selected limits
% AI 05/12/21

cMode = datacursormode(hFig);
cMode.removeAllDataCursors;

if isempty(hEvt)  %Prog call
    
    %Get handles to constraints
    ud = guidata(hFig);
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
    else
        hGuide = [protS(pNum).guidelines];
        set(hGuide(idxV),'Visible','On');
        %numElements = [0,cumsum(arrayfun(@(x)numel(x.guidelines),protS))];
        %for pNum = 1:numel(protS)
        %protS(pNum).guidelines = hGuide(numElements(pNum)+1:numElements(pNum+1));
        %end
        protS(pNum).guidelines = hGuide;
    end
    
    ud.Protocols = protS;
    set(hFig,'userdata',ud);
    
else %Checkbox selection
    
    %Get handles to constraints
    ud = get(hFig,'userdata');
    protS = ud.Protocols;
    
    %Get slelected constraint
    selectedIdv = hEvt.Indices(:,1);
    stateV = cell2mat(hObj.Data(selectedIdv,1));
    stateC = {'Off','On'};
    
    if selectedIdv==1  %'All'
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
        
    elseif selectedIdv==2 %'None'
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
        
    else
        
        ud = get(hFig,'userdata');
        protS = ud.Protocols;
        currProtocol = ud.foreground;
        gNum = numel(protS(currProtocol).guidelines);
        
        selectedIdv = selectedIdv-2;
        type =  get(hObj,'userdata');
        selTypeC = type(selectedIdv);
        
        for pNum = 1:numel(protS)
            for k = 1:numel(selectedIdv)
                if strcmp(selTypeC(k),'guidelines') %guidelines
                    selNum = selectedIdv(k);
                else                               %criteria
                    selNum = selectedIdv(k)- gNum;
                end
                %Toggle display on/off
                set(protS(pNum).(selTypeC{k})(selNum),'Visible',stateC{stateV(k)+1});
                %Expand tooltip if on
                if strcmp(stateC{stateV+1},'On')
                    hExp = cMode.createDatatip(protS(pNum).(selTypeC{k})(selNum));
                    evt.Target = protS(pNum).(selTypeC{k})(selNum);
                    evt.Position = [evt.Target.XData(1),evt.Target.YData(1)];
                    expandDataTipROE(hExp,evt,hFig);
                end
            end
        end
        
    end
    
end

ud.Protocols = protS;
guidata(hFig,ud);

end