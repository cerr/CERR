function scaleDoseROE(hObj,hEvt,hFig)
% Compute TCP/NTCP at scaled fraction size/number.
%
% AI 05/12/21

ud = guidata(hFig);
protS = ud.Protocols;

%Get selected scale
userScale = get(hObj,'Value');
xScale = userScale;

%Get scale & clear any previous markers
switch(ud.plotMode)
    case {1,2} %NTCP vs. TCP/BED
        y1PlotAxis = ud.handle.modelsAxis(1); %NTCP axis
        y2PlotAxis = [];
        %maxDelFrx = round(max([protS.numFractions])/2); %rounded
        nfrxV = ud.scaleFactors;
    case 3
        y1PlotAxis = ud.handle.modelsAxis(2); %NTCP axis (left)
        y2PlotAxis = ud.handle.modelsAxis(3); %TCP/BED axis (right)
        %fxSizScaleV = linspace(0.5,1.5,99);
        fxSizScaleV = ud.scaleFactors;
        xIdx = abs(fxSizScaleV-userScale) < eps;
        if isempty(xIdx)
            return %Invalid scale factor entered
        end
    case 4
        y1PlotAxis = ud.handle.modelsAxis(4); %NTCP axis
        y2PlotAxis = ud.handle.modelsAxis(5); %TCP/BED axis
        %maxDelFrx = round(max([protS.numFractions])/2);
        nfrxV = ud.scaleFactors;
end
hScaled_y1 = findall(y1PlotAxis,'type','line','LineStyle','-.');
delete(hScaled_y1);
if ~isempty(y2PlotAxis)
    hScaled_y2 = findall(y2PlotAxis,'type','line','LineStyle','-.');
    delete(hScaled_y2);
end

%Clear previous readouts
if isfield(ud,'scaleDisp')
    set(ud.scaleDisp,'String','');
end
y1ReadoutsH = findobj(y1PlotAxis,'tag','NTCPreadout');
y2ReadoutsH = findobj(y2PlotAxis,'tag','TCPBEDreadout');
yReadoutsH = [y1ReadoutsH;y2ReadoutsH];
for nLabel = length(yReadoutsH):-1:1
    delete(yReadoutsH(nLabel));
end

if isfield(ud,'y1Disp')
    ud.y1Disp = gobjects;
end
if isfield(ud,'y2Disp')
     ud.y2Disp = gobjects;
end

xLmtV = get(y1PlotAxis,'xLim');
hDisp_y1 = text(xLmtV(1),0,'','Parent',y1PlotAxis,...
    'FontSize',8,'Color',[.3 .3 .3],'HitTest','on',...
    'PickableParts','visible');
if ~isempty(y2PlotAxis)
    hDisp_y2 = text(xLmtV(2),0,'','Parent',y2PlotAxis,...
        'FontSize',8,'Color',[.3 .3 .3],'HitTest','on',...
        'PickableParts','visible');
end


%Set color order
colorM = ud.plotColorOrderM;

%Scale plots as selected
modNum = 0;
y1 = 0;
y2 = 0;
for l = 1:numel(ud.Protocols)
    
    nMod = length(ud.Protocols(l).model);
    if l == ud.foreground
        pColorM = [colorM,ones(size(colorM,1),1)];
    else
        wt = 0.4;
        pColorM = [colorM,repmat(wt,size(colorM,1),1)];
    end
    
    %Get plan no.
    planNum = ud.planNum;
    
    %Loop over models
    for k = 1:nMod
        modNum = modNum+1;
        
        % Get params
        modelsC = ud.Protocols(l).model;
        paramsS = modelsC{k}.parameters;
        
        % Get struct
        strNum = modelsC{k}.strNum;
        paramsS.structNum = strNum;
        
        % Get plan
        paramsS.planNum = planNum;
        paramsS.numFractions.val = ud.Protocols(l).numFractions;
        paramsS.frxSize.val = ud.Protocols(l).totalDose/ud.Protocols(l).numFractions;
        if isfield(modelsC{k},'abRatio')
            paramsS.abRatio.val = modelsC{k}.abRatio;
        end
        
        % Get dose bins
        if isfield(modelsC{k},'dv')
            dose0C = modelsC{k}.dv{1};
            vol0C = modelsC{k}.dv{2};
            
            %Scale
            if ud.plotMode==3
                scdoseC = cellfun(@(x) x*userScale,dose0C,'un',0);
                paramsS.frxSize.val = userScale*paramsS.frxSize.val;
            else
                nFProtocol = paramsS.numFractions.val;
                scNumFrx = userScale + nFProtocol;
                %nfrxV = linspace(-maxDelFrx,maxDelFrx,99);
                [~,xIdx] = min(abs(nfrxV-userScale));
                if isempty(xIdx)
                    return %Invalid scale factor entered
                end
                paramsS.numFractions.val = scNumFrx;
                scdoseC = cellfun(@(x) x*scNumFrx/nFProtocol,dose0C,'un',0);
            end
            %Apply fractionation correction where required
            eqScaledDoseC = frxCorrectROE(modelsC{k},strNum,paramsS.numFractions.val,scdoseC);
            
            % Pass as vector if nStr==1
            if numel(strNum) == 1
                vol0C = vol0C{1};
                eqScaledDoseC = eqScaledDoseC{1};
            end
            
            % Compute probability
            cpNew = feval(modelsC{k}.function,paramsS,eqScaledDoseC,vol0C);
            
            % Set plot color
            clrIdx = mod(k,size(pColorM,1))+1;
            
            if strcmpi(modelsC{k}.type,'NTCP') %y1 axis
                currAx = 'y1';
                loc = hObj.Min;
                hplotAx = y1PlotAxis;
                y1 = y1+1;
                count = y1;
                hDisp_y1(count) = text(xLmtV(1),0,'','Parent',y1PlotAxis,...
                   'FontSize',8,'Color',[0 0 0],'BackgroundColor',[1 1 1],...
                   'EdgeColor',pColorM(clrIdx,:),'LineWidth',2,...
                   'FontWeight','Bold','Tag','NTCPreadout');
                txtPos = xLmtV(1) - 0.15*abs(xLmtV(1));
                if ud.plotMode==1 || ud.plotMode==2
                    xScale = ud.NTCPCurve(k).XData(xIdx);
                end
                skip=0;
            else %y2 axis
                currAx = 'y2';
                if ud.plotMode==1 || ud.plotMode==2
                    %Skip
                    skip = 1;
                else
                    loc = hObj.Max;
                    hplotAx = y2PlotAxis;
                    y2 = y2+1;
                    count = y2;
                    hDisp_y2(count) = text(xLmtV(2),0,'','Parent',y2PlotAxis,...
                        'FontSize',8,'Color',[0 0 0],'BackgroundColor',...
                        [1 1 1],'EdgeColor',pColorM(clrIdx,:),'LineWidth',...
                        2,'FontWeight','Bold','Tag','TCPBEDreadout');
                    txtPos = xLmtV(2)+.05;
                    skip=0;
                end
            end
            
            if ~skip %Error here: TO DO! Check!
                
                plot([xScale xScale],[0 cpNew],'Color',pColorM(clrIdx,:),...
                    'LineStyle','-.','linewidth',2,'parent',hplotAx);
                plot([loc xScale],[cpNew cpNew],'Color',pColorM(clrIdx,:),...
                    'LineStyle','-.','linewidth',2,'parent',hplotAx);
                
                if strcmp(currAx,'y1')
                    set(hDisp_y1(count),'Position',[txtPos,cpNew],'String',sprintf('%.3f',...
                        cpNew),'Edge',pColorM(clrIdx,:),'LineWidth',2,...
                        'FontWeight','Bold');
                    %Make labels draggable
                    draggable(hDisp_y1(count), "v", [0.01 0.1]);
                else
                    set(hDisp_y2(count),'Position',[txtPos,cpNew],'String',sprintf('%.3f',...
                        cpNew),'Edge',pColorM(clrIdx,:),'LineWidth',2,...
                        'FontWeight','Bold');
                    %Make labels draggable
                    draggable(hDisp_y2(count), "v", [0.01 0.1]);
                end
                
            end
            
        end
    end
end

scaleVal = sprintf('%.3f',xScale);
hXDisp = text(xScale,-.03,scaleVal,'Parent',y1PlotAxis,...
    'FontSize',8,'Color',[.3 .3 .3]);
ud.scaleDisp = hXDisp;
ud.y1Disp = hDisp_y1;
if ~isempty(y2PlotAxis)
    ud.y2Disp = hDisp_y2;
end


guidata(hFig,ud);

end