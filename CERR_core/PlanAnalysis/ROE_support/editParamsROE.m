function editParamsROE(hObj,hData,hFig,planC)
% Edit model parameters
% AI 05/12/21

ud = guidata(hFig);
tag = get(hObj,'Tag');
indexS = planC{end};

%Get input data
idx = hData.Indices(1);
val = hData.EditData;
val2num = str2num(val);
if isempty(val2num) %Convert from string if numerical
    val2num = val;
end
prtcNum = ud.PrtcNum;
modelsC = ud.Protocols(prtcNum).model;
if isfield(ud,'ModelNum')
    modelNum = ud.ModelNum;
end

%Update parameter
switch(tag)
    case 'strSel'
        if hData.Indices(2)==1
            parameterS = modelsC{modelNum}.parameters;
            inputStructC = fieldnames(parameterS.structures);
            inputStructC = strcat('Select structure',{' '},inputStructC);
            matchIdx = find(strcmp(inputStructC,val));
            modelsC{modelNum}.inputStrNum = matchIdx;
            if ~isfield(modelsC{modelNum},'strNum') || ...
                    modelsC{modelNum}.strNum(matchIdx)==0
                hObj.Data{2} = 'Select from list';
            else
                allStrC = {planC{indexS.structures}.structureName};
                strIdx = modelsC{modelNum}.strNum(matchIdx);
                hObj.Data{2} = allStrC{strIdx};
            end
        else
            strListC = {'Select structure',planC{indexS.structures}.structureName};
            matchIdx = find(strcmp(strListC,val));
            inputStrNum = modelsC{modelNum}.inputStrNum;
            modelsC{modelNum}.strNum(inputStrNum) = matchIdx - 1;
            if isfield(ud.Protocols(prtcNum),'constraints')
                criteriaS = ud.Protocols(prtcNum).constraints;
                expectedStrName = strrep(hObj.Data{1},'Select structure ','');
                selectedStrName = strListC{matchIdx};
                %Update expected str name in criteria data stucture
                if isfield(criteriaS.structures,expectedStrName)
                    expS = criteriaS.structures.(expectedStrName);
                    selectedStrName = strrep(selectedStrName,' ','_');
                    criteriaS.structures.(selectedStrName) = expS;
                    criteriaS.structures = rmfield(criteriaS.structures,expectedStrName);
                    ud.Protocols(prtcNum).constraints = criteriaS;
                end
            end
        end
    case 'doseSel'
        if hData.Indices(2)==1
            return
        else
            dosListC = {'Select Plan',planC{indexS.dose}.fractionGroupID};
            matchIdx = find(strcmp(dosListC,val));
            %modelsC{modelNum}.planNum = matchIdx - 1;
            ud.planNum = matchIdx - 1;
            %Clear pre-computed dvh
            for p = 1:length(ud.Protocols)
                modelC = ud.Protocols(p).model;
                for modNum = 1:length(modelC)
                    if isfield(modelC{modNum},'dv')
                        modelC{modNum} = rmfield(modelC{modNum},'dv');
                    end
                end
                ud.Protocols(p).model = modelC;
            end
            %Auto-populate precribed dose if available
            RxField = ud.handle.tab1H(12);
            if ~isfield(planC{indexS.dose}(matchIdx - 1),'prescribedDose')
                try
                    prescribedDose = getPrescribedDose(matchIdx-1,planC);
                    set(RxField,'String',num2str(prescribedDose));
                    ud.handle.tab1H(12) = RxField;
                end
            else
                prescribedDose = planC{indexS.dose}(matchIdx - 1).prescribedDose;
                set(RxField,'String',num2str(prescribedDose));
                ud.handle.tab1H(12) = RxField;
            end
        end
    case 'fieldEdit'
        modelsC{modelNum} = modelsC{modelNum};
        parName = hObj.Data{idx,1};
        modelsC{modelNum}.(parName) = val2num;
        modelsC{modelNum} = modelsC{modelNum};
        set(ud.handle.tab1H(8),'Enable','On');  %Enable save
    case 'paramEdit'
        %Update modelC
        parName = hObj.Data{idx,1};
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