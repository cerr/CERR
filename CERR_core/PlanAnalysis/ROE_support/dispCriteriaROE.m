function dispCriteriaROE(hObj,hEvt,hFig,command)
% Callbacks for ROE constraint display

% Get GUI fig handle
ud = guidata(hFig);
%cMode = datacursormode(hFig);

constTabH = ud.handle.tab2H(5);
constDatC = get(constTabH,'data');

switch(upper(command))
    
    
    case 'NEXT'
        
        protS = ud.Protocols;
        
        for k = 1:length(protS)
            currProtocol = k;
            hCrit = protS(currProtocol).criteria;
            hGuide = protS(currProtocol).guidelines;
            hConstraint = [hGuide,hCrit];
            dispStateC = [];
            if ~isempty(hGuide)
                dispStateC = {hGuide.Visible};
            end
            if ~isempty(hCrit)
                dispStateC = [dispStateC,{hCrit.Visible}];
            end
            dispIdxV = strcmp(dispStateC,'on');
            xScaleC = get(hConstraint(dispIdxV),'XData');
            if iscell(xScaleC)
                currScaleC = cellfun(@(x)x(1,1),xScaleC,'un',0);
                currScaleV = unique([currScaleC{:}]);
            else
                currScaleV = unique(xScaleC);
            end
            gNum = numel(hGuide);
            if length(currScaleV)~=1 || sum(dispIdxV)==0 %More than one constraint or none displayed
                %Do nothing
                return
            else
                %Get available limits
                limitsV = [ arrayfun(@(x) x.XData(1),hGuide),...
                    arrayfun(@(x) x.XData(1),hCrit)];
                currentLimit = unique(limitsV(dispIdxV));
                currSelIdx = find(dispIdxV)+2;
                [limitsV,limOrderV] = sort(limitsV);
                next = find(limitsV > currentLimit,1,'first');
                if isempty(next) || isinf(limitsV(next))
                    %Last limit displayed
                    %OR
                    %Next limit beyond max display scale
                    return
                else
                    nextIdxV = find(limitsV==limitsV(next));
                    nextLimit = limOrderV(nextIdxV);
                    for l = 1:numel(nextLimit)
                        if nextLimit(l) <= gNum  %Guidelines
                            dispSelCriteriaROE([],[],hFig,...
                                'guidelines',nextLimit(l),currProtocol);
                            hNext = hGuide(nextLimit(l));
                            createDataTipROE(hFig,hNext);
                            %hData = cMode.createDatatip(hNext);
                            %set(hData,'Visible','On','OrientationMode','Manual',...
                            %    'Tag','criteria','UpdateFcn',...
                            %    @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
                            
                            strMatchIdx = strcmpi(constDatC(:,2),...
                                hNext.UserData.structure);
                            metricMatchIdx = strcmpi(constDatC(:,3),...
                                [hNext.UserData.label, ' (guideline)']);
                            selMatchIdx = strMatchIdx & metricMatchIdx;
                            constDatC{selMatchIdx,1} = true;
                            constDatC{currSelIdx,1} = false;
                        else                 %Criteria
                            cNum = nextLimit(l)-gNum;
                            dispSelCriteriaROE([],[],hFig,'criteria',...
                                cNum,currProtocol);
                            hNext = hCrit(cNum);
                            createDataTipROE(hFig,hNext);
                            %hData = cMode.createDatatip(hNext);
                            %set(hData,'Visible','On','OrientationMode','Manual',...
                            %    'Tag','criteria','UpdateFcn',...
                            %    @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
                            
                            strMatchIdx = strcmpi(constDatC(:,2),...
                                hNext.UserData.structure);
                            metricMatchIdx = strcmpi(constDatC(:,3),...
                                hNext.UserData.label);
                            selMatchIdx = strMatchIdx & metricMatchIdx;
                            constDatC{selMatchIdx,1} = true;
                            constDatC{currSelIdx,1} = false;
                        end
                    end
                    
                end
            end
        end
        
    case 'PREV'
        
        protS = ud.Protocols;
        
        for k = 1:length(protS)
            currProtocol = k;
            hCrit = protS(currProtocol).criteria;
            hGuide = protS(currProtocol).guidelines;
            dispStateC = [];
            if ~isempty(hGuide)
                dispStateC = {hGuide.Visible};
            end
            if ~isempty(hCrit)
                dispStateC = [dispStateC,{hCrit.Visible}];
            end
            dispIdxV = strcmp(dispStateC,'on');
            gNum = numel(hGuide);
            if sum(dispIdxV)~=1 || sum(dispIdxV)==0 %More than one constraint or none displayed
                %Do nothing
                return
            else
                %Get available limits
                limitsV = [ arrayfun(@(x) x.XData(1),hGuide),...
                    arrayfun(@(x) x.XData(1),hCrit)];
                currentLimit = limitsV(dispIdxV);
                currSelIdx = find(dispIdxV)+2;
                [limitsV,limOrderV] = sort(limitsV,'descend');
                prev = find(limitsV < currentLimit,1,'first');
                if isempty(prev) || isinf(limitsV(prev))
                    %First limit displayed
                    return
                else
                    prvIdxV = find(limitsV==limitsV(prev));
                    prevLimit = limOrderV(prvIdxV);
                    for l = 1:numel(prevLimit)
                        if prevLimit(l) <= gNum  %Guidelines
                            dispSelCriteriaROE([],[],hFig,'guidelines',...
                                prevLimit(l),currProtocol);
                            hNext = hGuide(prevLimit(l));
                            createDataTipROE(hFig,hNext);
                            %hData = cMode.createDatatip(hNext);
                            %set(hData,'Visible','On','OrientationMode','Manual',...
                            %    'Tag','guidelines','UpdateFcn',...
                            %    @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
                            
                            strMatchIdx = strcmpi(constDatC(:,2),...
                                hNext.UserData.structure);
                            metricMatchIdx = strcmpi(constDatC(:,3),...
                                [hNext.UserData.label, ' (guideline)']);
                            selMatchIdx = strMatchIdx & metricMatchIdx;
                            constDatC{selMatchIdx,1} = true;
                            constDatC{currSelIdx,1 } = false;
                        else                 %Criteria
                            cNum = prevLimit(l)-gNum;
                            dispSelCriteriaROE([],[],hFig,'criteria',cNum,currProtocol);
                            hNext = hCrit(cNum);
                            createDataTipROE(hFig,hNext);
                            %hData = cMode.createDatatip(hNext);
                            %set(hData,'Visible','On','OrientationMode','Manual',...
                            %    'Tag','criteria','UpdateFcn',...
                            %    @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
                            
                            strMatchIdx = strcmpi(constDatC(:,2),...
                                hNext.UserData.structure);
                            metricMatchIdx = strcmpi(constDatC(:,3),...
                                hNext.UserData.label);
                            selMatchIdx = strMatchIdx & metricMatchIdx;
                            constDatC{selMatchIdx,1} = true;
                            constDatC{currSelIdx,1} = false;
                        end
                    end
                    
                end
            end
        end
end

ud = guidata(hFig);
set(constTabH,'data',constDatC);
ud.handle.tab2H(5) = constTabH;
guidata(hFig,ud)

end