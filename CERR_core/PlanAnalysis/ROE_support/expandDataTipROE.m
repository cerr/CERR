function txt = expandDataTipROE(hObj,hEvt,hFig)
%Display clinical criteria on selection
%
% AI 05/12/21

%Get userdata
ud = guidata(hFig);

%Check if visible
if strcmpi(get(hObj,'Visible'),'Off')
    return
end

%Get scale at limit
if isempty(hEvt)                 %Initialize (display 1st violation)
    posV = get(hObj,'Position');
    xVal = posV(1);
    pNum = ud.PrtcNum;
    lscale = cLine.UserData.scale;
else
    %Update (display selected limit)
    cLine = hEvt.Target;
    xVal = cLine.XData(1);
    pNum = cLine.UserData.protocol;
    lscale = cLine.UserData.scale;
end

%Get protocol info
pName = ud.Protocols(pNum).protocol;
numFrx = ud.Protocols(pNum).numFractions;
totDose = ud.Protocols(pNum).totalDose;
frxSize = totDose/numFrx;

%Get scaled frx size or nfrx at limit
if ud.plotMode==3
    %Scale frx size
    frxSize = lscale*frxSize;
else
    %Scale nfrx
    numFrx = lscale*numFrx;
end

%Get TCP/BED at limit
if ud.plotMode==2
    yVal = xVal;
    yDisp  = 'TCP';
elseif ud.plotMode==3
    if ~isempty(ud.TCPCurve)
        yDisp  = 'TCP';
        xidx = ud.TCPCurve(pNum).XData == lscale;
        yVal = ud.TCPCurve(pNum).YData(xidx);
    else
        yDisp  = 'BED';
        xidx = ud.BEDCurve(pNum).XData == lscale;
        yVal = ud.BEDCurve(pNum).YData(xidx);
    end
elseif ud.plotMode==4
    if ~isempty(ud.TCPCurve)
        yDisp  = 'TCP';
        xidx = ud.TCPCurve(pNum).XData == xVal;
        yVal = ud.TCPCurve(pNum).YData(xidx);
    else
        yDisp  = 'BED';
        xidx = ud.BEDCurve(pNum).XData == xVal;
        yVal = ud.BEDCurve(pNum).YData(xidx);
    end
else %Plot mode:1
    yVal = xVal;
    yDisp  = 'BED';
end



%Check for all violations at same scale
%---Criteria:---
hCrit = ud.Protocols(pNum).criteria;
limitM = get(hCrit,'xData');

if isempty(limitM)
    %Skip
else
    if iscell(limitM)
        limitM = cell2mat(limitM);
    end
    nCrit =  sum(limitM(:,1) == xVal);
    txt = {};
    if nCrit>0
        limitIdx = find(limitM(:,1) == xVal);
        for k = 1:numel(limitIdx)
            lUd = hCrit(limitIdx(k)).UserData;
            start = (k-1)*8 + 1;
            
            if ud.plotMode==3
                scDisp = ['Current fraction size: ',num2str(frxSize),' Gy'];
            else
                scDisp = ['Current fraction no.: ',num2str(numFrx)];
            end
            
            if strcmpi(yDisp,'BED')
                last = ['Current ',yDisp,': ',num2str(yVal),' Gy'];
            else
                last = ['Current ',yDisp,': ',num2str(yVal)];
            end
            
            strOut = strrep(lUd.structure,'_','-');
            txt(start : start+8) = { [' '],[num2str(k),'. Structure: ',strOut],...
                ['Criterion: ', lUd.label],...
                ['Clinical limit: ', num2str(lUd.limit)],...
                ['Current value: ', num2str(lUd.val)],...
                [' '],...
                ['Protocol: ', pName],...
                scDisp,last};
            
        end
    end
end

%---Guidelines:---
hGuide = ud.Protocols(pNum).guidelines;
limitM = get(hGuide,'xData');

if isempty(limitM)
    %Skip
else
    if iscell(limitM)
        limitM = cell2mat(limitM);
    end
    nGuide =  sum(limitM(:,1) == xVal);
    k0 = length(txt);
    if nGuide>0
        limitIdx = find(limitM(:,1) == xVal);
        %Get structures, limits
        for k = 1:numel(limitIdx)
            lUd = hGuide(limitIdx(k)).UserData;
            start = k0 + (k-1)*8 + 1;
            
            if ud.plotMode==3
                scDisp = ['Current fraction size: ',num2str(frxSize)];
            else
                scDisp = ['Current fraction no.: ',num2str(numFrx)];
            end
            
            if strcmpi(yDisp,'BED')
                last = ['Current ',yDisp,': ',num2str(yVal),' Gy'];
            else
                last = ['Current ',yDisp,': ',num2str(yVal)];
            end
            
            strOut = strrep(lUd.structure,'_','-');
            txt(start : start+8) = {[' '],[num2str(nCrit+k),'. Structure: ',...
                strOut],['Criterion: ', lUd.label],...
                ['Clinical limit (guideline): ', num2str(lUd.limit)],...
                ['Current value: ', num2str(lUd.val)],...
                [' '],...
                ['Protocol: ', pName],...
                scDisp,last};
        end
    end
end

%Display
hObj.Marker = '^';
hObj.MarkerSize = 7;
set(hObj,'Visible','On');
end