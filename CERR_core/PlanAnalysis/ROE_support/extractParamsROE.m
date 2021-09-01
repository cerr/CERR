function hTab = extractParamsROE(hFig,modelS,planC)
  % Extract model parameters & values for table display
  %
  % AI 12/14/2020
  
  %Delete any previous param tables
  ud = guidata(hFig);
  if isfield(ud,'currentPar') && ~isempty(ud.currentPar)
      delete(ud.currentPar);
  end
  
  %Get parameter names
  modelParS = modelS.parameters;
  genParListC = fieldnames(modelParS);
  nPars = numel(genParListC);
  reservedFieldsC = {'type','cteg','desc'};
  
  %Define table dimensions
  rowHt = 25;
  rowSep = 10;
  rowWidth = 120;
  pos = get(hFig,'Position');
  fwidth = pos(3);
  fheight = pos(3);
  left = 10;
  columnWidth ={rowWidth-1,rowWidth-1};
  posV = [.2*fwidth .37*fheight 2*rowWidth rowHt];
  row = 1;
  hTab = [];
  % Create rows displaying model parameters
  for k = 1:nPars
    if strcmpi(genParListC{k},'structures')
      if isstruct(modelParS.(genParListC{k}))
        structS = modelParS.(genParListC{k});
        strListC = fieldnames(structS);
        for s = 1:length(strListC)
          strParListC = fieldnames(structS.(strListC{s}));
          for t = 1:numel(strParListC)
            parS = structS.(strListC{s}).(strParListC{t});
            %parName = [strListC{s},' ',strParListC{t}];
            parName = strParListC{t};
            if ~strcmpi(parName,'optional')
              [columnFormat,dispVal] = extractValROE(parS);
              dataC = {parName,dispVal};
              hTab(row) = uitable(hFig,'Tag','paramEdit','Position', posV + [0 -(row*(rowHt+1)) 0 0 ],...
              'columnformat',columnFormat,'Data',dataC,'Visible','Off','FontSize',10,...
              'columneditable',[false,true],'columnname',[],'rowname',[],...
              'columnWidth',columnWidth,'celleditcallback',@(hObj,hData)editParamsROE(hObj,hData,hFig,planC));
              row = row+1;
            end
          end
        end
      end
    else
      if ~strcmpi(genParListC{k},reservedFieldsC)
        parName = genParListC{k};
        [columnFormat,dispVal] = extractValROE(modelParS.(genParListC{k}));
        dataC = {parName,dispVal};
        hTab(row) = uitable(hFig,'Tag','paramEdit','Position', posV + [0 -(row*(rowHt+1)) 0 0 ],...
        'columnformat',columnFormat,'Data',dataC,'Visible','Off','FontSize',10,...
        'columneditable',[false,true],'columnname',[],'rowname',[],...
        'columnWidth',columnWidth,'celleditcallback',...
        @(hObj,hData)editParamsROE(hObj,hData,hFig,planC));
        row = row+1;
      end
    end
  end
  
  guidata(hFig,ud);
  
end