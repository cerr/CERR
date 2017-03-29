function [limitV,valV,ntcpLim,tcpLim,toolTipC] = getLimits(critS,type,strNum,doseNum,scale)

global planC;
indexS = planC{end};
structListC = {planC{indexS.structures}.structureName};

% Get DVH
[doseBinsV,volHistV] = getDVH(strNum,doseNum,planC);
doseBinsV = doseBinsV.*scale;

%Get val, limit
fieldsC = fieldnames(critS.(type));
valV = zeros(1,numel(fieldsC));
passV = zeros(1,numel(fieldsC));
nFail = 0;
ntcpLim = [];
tcpLim = [];
for m = 1:numel(fieldsC)
    lim = critS.(type).(fieldsC{m}).limit;
    limitV(m) = lim(1); %TEMP SKIP RANGE
    if strcmpi(fieldsC{m},'ntcp')
        ntcpLim = [limitV(m),m];
    end
    if strcmpi(fieldsC{m},'tcp')
        tcpLim = [limitV(m),m];
    end
    if isfield(critS.(type).(fieldsC{m}),'function')
        fn = critS.(type).(fieldsC{m}).function;
        if isfield(critS.(type).(fieldsC{m}),'additionalInputs')
            additionalInputs = critS.(type).(fieldsC{m}).additionalInputs;
            if numel(additionalInputs)==1  %%%TEMP FIX%%%%%%
             valV(m) = feval(fn,doseBinsV,volHistV,additionalInputs);
            else
                valV(m) = feval(fn,doseBinsV,volHistV,additionalInputs(1),additionalInputs(2));
            end
        else
            valV(m) = feval(fn,doseBinsV,volHistV);
        end
    end
    passV(m) = valV(m)<=limitV(m);
    toolTipC{m} = [structListC{strNum},' ',fieldsC{m},': ',num2str(valV(m))];
end





end