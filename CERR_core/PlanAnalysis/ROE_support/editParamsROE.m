function editParamsROE(hObj,hData,hFig,planC)
% Edit model parameters through ROE
%
% AI 12/14/2020

ud = guidata(hFig);
tag = get(hObj,'Tag');
indexS = planC{end};

%Get input data
idx = hData.Indices(1);
val = hData.EditData;
val2num = val;
if ~isnumeric(val)
    val2num = str2num(val);
end
if isempty(val2num)
  val2num = val;
end
prtcNum = ud.PrtcNum;
modelsC = ud.Protocols(prtcNum).model;
if isfield(ud,'ModelNum')
    modelNum = ud.ModelNum;
end

%Update parameter
ind = hData.Indices;
switch(tag)
    case 'strSel'
        if ind(2)==1
            parameterS = modelsC{modelNum}.parameters;
            inputStructC = fieldnames(parameterS.structures);
            inputStructC = strcat('Select structure',{' '},inputStructC);
            matchIdx = find(strcmp(inputStructC,val));
            modelsC{modelNum}.inputStrNum = matchIdx;
            if ~isfield(modelsC{modelNum},'strNum') || ...
              modelsC{modelNum}.strNum(matchIdx)==0
              dataC = get(hObj,'Data');
              dataC{2} = 'Select from list';
              set(hObj,'Data',dataC);
            end
        else
            strListC = {'Select structure',planC{indexS.structures}.structureName};
            matchIdx = find(strcmp(strListC,val));
            inputStrNum = modelsC{modelNum}.inputStrNum;
            modelsC{modelNum}.strNum(inputStrNum) = matchIdx - 1;
            if isfield(ud.Protocols(prtcNum),'constraints')
                criteriaS = ud.Protocols(prtcNum).constraints;
                strData = get(hObj,'Data');
                expectedStrName = strrep(strData{1},'Select structure ','');
                selectedStrName = strListC{matchIdx};
                %Update expected str name in criteria data stucture
                if isfield(criteriaS.structures,expectedStrName)
                    expS = criteriaS.structures.(expectedStrName);
                    criteriaS.structures.(selectedStrName) = expS;
                    criteriaS.structures = rmfield(criteriaS.structures,expectedStrName);
                    ud.Protocols(prtcNum).constraints = criteriaS;
                end
            end
        end
    case 'doseSel'
        if ind(2)==1
            return
        else
            dosListC = {'Select Plan',planC{indexS.dose}.fractionGroupID};
            matchIdx = find(strcmp(dosListC,val));
            %modelsC{modelNum}.planNum = matchIdx - 1;
            ud.planNum = matchIdx - 1;
        end
      case 'fieldEdit'
        modelsC{modelNum} = modelsC{modelNum};
        fieldData = get(hObj,'Data');
        parName = fieldData{idx,1};
        modelsC{modelNum}.(parName) = val2num;
        modelsC{modelNum} = modelsC{modelNum};
        set(ud.handle.inputH(9),'Enable','On');  %Enable save
    case 'paramEdit'
        %Update modelC
        paramData = get(hObj,'Data');
        parName = paramData{idx,1};
        strParam = 0;
        if isfield(modelsC{modelNum}.parameters,'structures')
            structS = modelsC{modelNum}.parameters.structures;
            if isstruct(structS)
                stC = fieldnames(structS);
                found = 0;
                t = 0;
                while ~found & t<numel(stC)
                    found = isfield(structS.(stC{t+1}),parName);
                    t = t+1;
                end
                if found
                    strParam = 1;
                    type = structS.(stC{t}).(parName).type;
                end
            end
        end
        if ~strParam
            type = modelsC{modelNum}.parameters.(parName).type;
        end
        if strcmpi(type{1},'bin')
            desc = modelsC{modelNum}.parameters.(parName).desc;
            ctgIdx = strcmp(desc,val2num);
            value = modelsC{modelNum}.parameters.(parName).cteg(ctgIdx);
            modelsC{modelNum}.parameters.(parName).val = value;
        else
            modelsC{modelNum}.parameters.(parName).val = val2num;
        end
        set(ud.handle.tab1H(8),'Enable','On');  %Enable save
end
ud.Protocols(prtcNum).model = modelsC;
guidata(hFig,ud);

end