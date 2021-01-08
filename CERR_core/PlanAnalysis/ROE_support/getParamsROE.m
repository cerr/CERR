function getParamsROE(hObj,hEvt,hFig,planC)
% Store ROE inputs to figure userdata
%
% AI 12/14/2020
  
  ud = guidata(hFig);
  protS = ud.Protocols;
  indexS = planC{end};
  if strcmp(hEvt,'INIT')#initialization
    prtcNum = 1:length(protS);
    %Set default dose plan if only one is available
    planListC = {'Select dose plan',planC{indexS.dose}.fractionGroupID};
    if numel(planListC)==2 
      planIdx = 2;
      ud.planNum = 1; %Default to 1st plan
    end
  else
    prtcNum = ud.PrtcNum;
    protocolS = protS(prtcNum);
  end
  
  %Get dose plan input
  planListC = {'Select dose plan',planC{indexS.dose}.fractionGroupID};
  if isfield(ud,'planNum') && ~isempty(ud.planNum)
    planIdx = ud.planNum + 1;
  else
    %User selection
    planIdx = 1;
    ud.planNum = [];
  end
  
  %Table for selecting dose plan
  hTab = ud.handle.inputH(5);
  fmt = {'char' planListC};
  dosDat = {'Select dose plan',planListC{planIdx}};
  set(hTab,'ColumnFormat',fmt,'Data',dosDat,'Visible','On','Enable','On');
  ud.handle.inputH(5) = hTab;
  set(hFig,'userdata',ud);
  
  planNum = ud.planNum;
  for t = 1:length(prtcNum)
    
    if ~isempty(planNum)
      %Table2 : Plan selection
      hTab2 = ud.handle.inputH(5);
      planDispC = get(hTab2,'ColumnFormat');
      txtDispC = get(hTab2,'Data');
      planListC = planDispC{2};
      set(hTab2,'Data',{txtDispC{1},planListC{planNum+1}});
      ud.handle.inputH(5) = hTab2;
    end
    
    modelsC = protS(prtcNum(t)).model;
    modListC = cellfun(@(x) x.name,modelsC,'un',0);
    if strcmp(hEvt,'INIT')
      modelNumV = 1:length(modListC);
    else
      modelNumV = get(hObj,'Value');
    end
    
    for s = 1:length(modelNumV)
      
      modName = modelsC{modelNumV(s)}.name;
      
      %Get structure input
      if ~isstruct(modelsC{modelNumV(s)}.parameters.structures)
        %If model has no structure-specific parameters
        inputStructC = {modelsC{modelNumV(s)}.parameters.structures};
      else
        inputStructC = fieldnames(modelsC{modelNumV(s)}.parameters.structures);
      end
      numStruct = length(inputStructC);
      structListC = {'Select from list',planC{indexS.structures}.structureName};
      structDispC = cell(numel(inputStructC),1);
      
      if isfield(modelsC{modelNumV(s)},'strNum')
        strIdxV = modelsC{modelNumV(s)}.strNum;
        for r = 1:numel(inputStructC)
          structDispC{r} = ['Select structure ',inputStructC{r}];
        end
      else
        strIdxV = zeros(1,numStruct);
        for r = 1:numel(inputStructC)
          structDispC{r} = ['Select structure ',inputStructC{r}];
          strMatch = strcmpi(inputStructC{r},structListC);
          if ~any(strMatch)
            strIdxV(r) = 0;
          else
            strIdxV(r) = find(strMatch)-1;
          end
        end
      end
      
      
      %Get parameters
      guidata(hFig,ud);
      hPar = extractParamsROE(hFig,modelsC{modelNumV(s)},planC);
      ud = guidata(hFig);
      
  %AI temp hide JSON field display    
      if ~strcmp(hEvt,'INIT')
        %%Add file properties if missing
        %fieldsC = fieldnames(modelsC{modelNumV(s)});
        %valsC = struct2cell(modelsC{modelNumV(s)});
        %filePropsC = %{'modified_at','modified_by','created_at','created_by',};
        %missingFilePropsV = ~ismember(filePropsC,lower(fieldsC));
        %if any(missingFilePropsV)
          %idx = find(missingFilePropsV);
          %for r = 1:numel(idx)
            %fieldsC = [fieldsC(:);filePropsC{r}];
            %valsC = [valsC(:);{''}];
          %end
        %end
        %tab3C = {'name','type','stdFractionSize','prescribedDose','abRatio','function','created_by',...
        %'created_at','modified_by','modified_at'};
        %valsC = valsC(ismember(fieldsC,tab3C));
        %fieldsC = fieldsC(ismember(fieldsC,tab3C));
        
        
        %Display parameters from .json file
        %Table1 : Structure selection
        hTab1 = ud.handle.inputH(4);
        fmtC = {structDispC.',structListC};
        if isfield(modelsC{modelNumV(s)},'inputStrNum')
          inputStrNum = modelsC{modelNumV(s)}.inputStrNum;
        else
          inputStrNum = 1;
          modelsC{modelNumV(s)}.inputStrNum = 1;
        end
        strDat = [structDispC{inputStrNum},structListC(strIdxV(inputStrNum)+1)];
        set(hTab1,'ColumnFormat',fmtC,'Data',strDat,...
        'Visible','On','Enable','On');
        
        %Table2
        
        %Table3 : Miscellaneous fields from .json file
        %hTab3 = ud.handle.inputH(8);
        %set(hTab3,'Data',[fieldsC,cellfun(@num2str,valsC,'un',0)],'Visible','On','Enable','On');
        
        %Parameters
        for r = 1:numel(hPar)
          set(hPar(r),'Visible','On');
        end
        
        %Store tables to userdata
        ud.handle.inputH(4) = hTab1;
        set(ud.handle.inputH(6),'Visible','On'); %Parameters header
        set(ud.handle.inputH(7),'String',['Current model:  ',modName],'Visible','On'); %Display name of currently selected model
        
        %ud.handle.inputH(8) = hTab3;
      end
      
      ud.currentPar = hPar;
      modelsC{modelNumV(s)}.strNum = strIdxV;
      
    end
    protS(prtcNum(t)).model = modelsC;
  end
  
  if ~strcmp(hEvt,'INIT')
    %set current model nos
    ud.ModelNum = modelNumV;
    
    %Enable save
    set(ud.handle.inputH(9),'Enable','On');
  end
  ud.Protocols = protS;
  guidata(hFig,ud);
  
  end