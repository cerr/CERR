function scaleVal = scaleDoseROE(hObj,hEvt,hFig)
  % Compute TCP/NTCP at scaled fraction size/number.
  %
  % AI 12/17/2020
  
  ud = guidata(hFig);
  protS = ud.Protocols;
  
  %Get selected scale
  userScale = get(hObj,'Value');
  xScale = userScale;
  
  %Get scale & clear any previous markers
  switch(ud.plotMode)
  case {1,2}
    y1PlotAxis = ud.handle.modelsAxis(2); %NTCP axis
    y2PlotAxis = [];
    maxDelFrx = round(max([protS.numFractions])/2); %rounded
  case 3
    y1PlotAxis = ud.handle.modelsAxis(3); %NTCP axis
    y2PlotAxis = ud.handle.modelsAxis(4); %TCP/BED axis
    fxSizScaleV = linspace(0.5,1.5,99);
    xIdx = abs(fxSizScaleV-userScale) < eps;
    if isempty(xIdx)
      return %Invalid scale factor entered
    end
  case 4
    y1PlotAxis = ud.handle.modelsAxis(5); %NTCP axis
    y2PlotAxis = ud.handle.modelsAxis(6); %TCP/BED axis
    maxDelFrx = round(max([protS.numFractions])/2);
  end
  hScaled_y1 = findall(y1PlotAxis,'type','line','LineStyle','-.');
  delete(hScaled_y1);
  if ~isempty(y2PlotAxis)
    hScaled_y2 = findall(y2PlotAxis,'type','line','LineStyle','-.');
    delete(hScaled_y2);
  end
  
  %Clear readouts
  if isfield(ud,'scaleDisp')
    set(ud.scaleDisp,'String','');
  end
  if isfield(ud,'y1Disp')
    set(ud.y1Disp,'String','');
  end
  if isfield(ud,'y2Disp')
    set(ud.y2Disp,'String','');
  end
  xLmtV = get(y1PlotAxis,'xLim');
  hDisp_y1 = text(xLmtV(1),0,'','Parent',y1PlotAxis,...
  'FontSize',10,'Color',[.3 .3 .3]);
  if ~isempty(y2PlotAxis)
    hDisp_y2 = text(xLmtV(2),0,'','Parent',y2PlotAxis,...
    'FontSize',10,'Color',[.3 .3 .3]);
  end
  
  %Set color order
  colorOrderP1M = [0 229 238;123 104 238;255 131 250;0 238 118;218 165 32;141	141	141;0 139 0;28 134 238;238 189 125]/255;
  
  colorOrderP2M = [140 215 218;200 193 235;255 188 254;158 238 198;218 188 105;196	196	196;126 226 126;108 173 238;238 223 204]/255;
    
  
  %Scale plots as selected
  modNum = 0;
  y1 = 0;
  y2 = 0;
  for l = 1:numel(ud.Protocols)
    
    nMod = length(ud.Protocols(l).model);
    if l == ud.foreground
      %pColorM = [colorM,ones(size(colorM,1),1)];
      %transparency not yet supported
      pColorM = colorOrderP1M;
    else
      wt = 0.4;
      %pColorM = [colorM,repmat(wt,size(colorM,1),1)];
      pColorM = colorOrderP2M;
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
      paramsS.abRatio.val = modelsC{k}.abRatio;
      
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
          nfrxV = linspace(-maxDelFrx,maxDelFrx,99);
          [~,xIdx] = min(abs(nfrxV-userScale));
          if isempty(xIdx)
            return %Invalid scale factor entered
          end
          paramsS.numFractions.val = scNumFrx;
          scdoseC = cellfun(@(x) x*scNumFrx/nFProtocol,dose0C,'un',0);
        end
        %Apply fractionation correction where required
        eqScaledDoseC = frxCorrectROE(modelsC{k},strNum,...
        paramsS.numFractions.val,scdoseC);
        
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
          loc = get(hObj,'Min');
          hplotAx = y1PlotAxis;
          y1 = y1+1;
          count = y1;
          hDisp_y1(count) = text(xLmtV(1),0,'','Parent',y1PlotAxis,...
          'FontSize',10,'Color',[.3 .3 .3]);
          hText = hDisp_y1(count);
          txtPos = xLmtV(1) - 0.12*abs(xLmtV(1));
          if ud.plotMode==1 || ud.plotMode==2
            xV = get(ud.NTCPCurve(k),'XData');
            xScale = xV(xIdx);
          end
          skip=0;
        else %y2 axis
          if ud.plotMode==1 || ud.plotMode==2
            %Skip
            skip = 1;
          else
            loc = get(hObj,'Max');
            hplotAx = y2PlotAxis;
            y2 = y2+1;
            count = y2;
            hDisp_y2(count) = text(xLmtV(2),0,'','Parent',y2PlotAxis,...
            'FontSize',10,'Color',[.3 .3 .3]);
            hText = hDisp_y2(count);
            txtPos = xLmtV(2)+.02;
            skip=0;
          end
        end
        
        if ~skip %Error here: TO DO! Check!
          plot([xScale xScale],[0 cpNew],'Color',pColorM(clrIdx,:),'LineStyle',...
          '-.','linewidth',2,'parent',hplotAx);
          plot([loc xScale],[cpNew cpNew],'Color',pColorM(clrIdx,:),'LineStyle',...
          '-.','linewidth',2,'parent',hplotAx);
          set(hText,'Position',[txtPos,cpNew],'String',sprintf('%.3f',cpNew));
        end
        
      end
    end
  end
  scaleVal = sprintf('%.3f',xScale);
  hXDisp = text(xScale,-.03,scaleVal,'Parent',y1PlotAxis,...
  'FontSize',10,'Color',[.3 .3 .3]);
  ud.scaleDisp = hXDisp;
  ud.y1Disp = hDisp_y1;
  if ~isempty(y2PlotAxis)
    ud.y2Disp = hDisp_y2;
  end
  
  guidata(hFig,ud);
  
  end