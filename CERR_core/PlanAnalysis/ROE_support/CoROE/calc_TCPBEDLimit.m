function [BEDatLimit,TCPatLimit] = calc_TCPBEDLimit(BEDparS,TCPparS,...
    planNum,binWidth,planC)
% Function to compute TCP/BED at a given scale factor
%AI 03/05/2021

indexS = planC{end};
allStructsC = {planC{indexS.structures}.structureName};

%% Calculate tumor BED at violated limit
BEDatLimit = nan;
if ~isempty(BEDparS)
    %Calc dose, vol bins
    strNameC = BEDparS.structures;
    if ~iscell(strNameC)
        strNameC = {strNameC};
    end
    [doseBinsC,volHistC] = getDoseVolBins(strNameC,allStructsC,...
        planNum,binWidth);
    %Calc BED
    BEDatLimit = feval(BEDparS.function,BEDparS,doseBinsC,volHistC);
end

%% Calculate TCP at violated limit
TCPatLimit = nan;
if ~isempty(TCPparS)
    %Calc dose, vol bins
    strNameC = TCPparS.structures;
    if ~iscell(strNameC)
        strNameC = {strNameC};
    end
    [doseBinsC,volHistC] = getDoseVolBins(strNameC,allStructsC,...
        planNum,binWidth);
    %Calc TCP
    TCPatLimit = feval(TCPparS.function,TCPparS,doseBinsC,volHistC);
end

%% Supporting functions

    function [doseBinsC,volHistC] = getDoseVolBins(strNameC,allStructsC,...
            planNum,binWidth)
        for nStr = 1:length(strNameC)
            strIdx = getMatchingIndex(strNameC{nStr},allStructsC,'EXACT');
            if ~isempty(strIdx)
                [dosesV,volsV] = getDVH(strIdx,planNum,planC);
                [doseBinsC{nStr},volHistC{nStr}] = ...
                    doseHist(dosesV,volsV,binWidth);
            else
                error('Structure %s not found',strNameC{nStr});
            end
        end
    end

end