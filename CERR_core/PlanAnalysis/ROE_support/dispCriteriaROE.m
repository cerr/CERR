function dispCriteriaROE(hObj,hEvt,hFig,command)
% Callbacks for ROE constraint display

% Get GUI fig handle
ud = guidata(hFig);
cMode = datacursormode(hFig);
cursorInfoS = getCursorInfo(cMode);


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
            cMode = datacursormode(hFig);
            if length(currScaleV)~=1 || sum(dispIdxV)==0 %More than one constraint or none displayed
                %Do nothing
                return
            else
                %Get available limits
                ud = guidata(hFig);
                limitsV = [ arrayfun(@(x) x.XData(1),hGuide),...
                    arrayfun(@(x) x.XData(1),hCrit)];
                currentLimit = unique(limitsV(dispIdxV));
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
                            target = protS(currProtocol).guidelines(nextLimit(l));
                            createDataTipROE(hFig,target);
                            %hData = cMode.createDatatip(hNext);
                            %set(hData,'Visible','On','OrientationMode','Manual',...
                            %    'Tag','criteria','UpdateFcn',...
                            %    @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
                        else                 %Criteria
                            cNum = nextLimit(l)-gNum;
                            dispSelCriteriaROE([],[],hFig,'criteria',...
                                cNum,currProtocol);
                            hNext = hCrit(cNum);
                            target = protS(currProtocol).criteria(cNum);
                            createDataTipROE(hFig,target);
                            %hData = cMode.createDatatip(hNext);
                            %set(hData,'Visible','On','OrientationMode','Manual',...
                            %    'Tag','criteria','UpdateFcn',...
                            %    @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
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
            cMode = datacursormode(hFig);
            if sum(dispIdxV)~=1 || sum(dispIdxV)==0 %More than one constraint or none displayed
                %Do nothing
                return
            else
                %Get available limits
                ud = guidata(hFig);
                limitsV = [ arrayfun(@(x) x.XData(1),hGuide),...
                    arrayfun(@(x) x.XData(1),hCrit)];
                currentLimit = limitsV(dispIdxV);
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
                            %hData = cMode.createDatatip(hNext);
                            %set(hData,'Visible','On','OrientationMode','Manual',...
                            %    'Tag','guidelines','UpdateFcn',...
                            %    @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
                        else                 %Criteria
                            dispSelCriteriaROE([],[],hFig,'criteria',prevLimit(l)-gNum,currProtocol);
                            hNext = hCrit(prevLimit(l)-gNum);
                            %hData = cMode.createDatatip(hNext);
                            %set(hData,'Visible','On','OrientationMode','Manual',...
                            %    'Tag','criteria','UpdateFcn',...
                            %    @(hObj,hEvt)expandDataTipROE(hObj,hEvt,hFig));
                        end
                    end
                    
                end
            end
        end
end

end