function [structsC,numCriteria,numGuide,limC,typeC] = getConstraintsForDisplayROE(hFig)
% getConstraintsForDisplayROE.m
% Get list of available constraints for display.
%
%AI 10/19/21

%% Get list of available constraints for display
ud = guidata(hFig);

if isfield(ud,'Protocols')
    protS = ud.Protocols;
    currProtocol = ud.foreground;
    if isempty(protS(currProtocol).criteria) && ...
            isempty(protS(currProtocol).guidelines)
        return
    end
    
    numCriteria = 0;
    numGuide = 0;
    
    %Criteria
    
    if ~isempty(protS(currProtocol).criteria)
        criteriaS = [protS(currProtocol).criteria.UserData];
        structsC = {criteriaS.structure};
        limC = {criteriaS.label};
        numCriteria = numel(protS(currProtocol).criteria);
        typeC(1:numCriteria) = {'criteria'};
    else
        structsC = {};
        limC = {};
        typeC = {};
    end
    
    %Guidelines
    if ~isempty(protS(currProtocol).guidelines)
        guideS = [protS(currProtocol).guidelines.UserData];
        strgC = {guideS.structure};
        limgC = {guideS.label};
        limgC = cellfun(@(x) strjoin({x,'(guideline)'}),limgC,'un',0);
        numGuide = numel(protS(currProtocol).guidelines);
        structsC = [strgC,structsC].';
        limC = [limgC,limC].';
        gtypeC(1:numGuide) = {'guidelines'};
        typeC = [gtypeC,typeC];
    end
    
else
    
    return
    
end

end