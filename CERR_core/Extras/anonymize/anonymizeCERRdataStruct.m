function anonStructS = anonymizeCERRdataStruct(structS,anonDefinS)
% function anonStructS = anonymizeCERRdataStruct(structS,anonDefinS)
%
% Anonymizes the passed CERR/Matlab data structure according to the
% anonymization definitions in anonDefinS.
%
% The anonymization is applied to the fields of structS structure array if
% the field names are anything other than Item_*. If the fields of structS
% are Item_* (Item_1, Item_2, Item_3), the anonymization is applied to the
% elements of structS.item_*.
%
% APA, 1/29/2018

% initialize the anonStructS data structure to be same as structS
anonStructS = structS;

% Get the field names of structS
fieldC = fieldnames(anonStructS);

% If the fields are Item_*, then anonymize its sub-fields
itemIteratorFlag = 0;
if length(anonStructS) == 1 && isequal(unique(strtok(fieldC,'_')),{'Item'})
    itemIteratorFlag = 1;
    itemC = fieldC;
    fieldC = fieldnames(anonStructS.Item_1);    
end

% Loop over all the fields and anonymize 
for i = 1:length(fieldC)
    % remove field if it is not defined in the anonymization
    rmFieldFlag = 0;
    if ~itemIteratorFlag && ~isfield(anonDefinS,fieldC{i})
        %anonStructS = rmfield(structS,fieldC{i});
        rmFieldFlag = 1;
    elseif itemIteratorFlag && ~isfield(anonDefinS,fieldC{i})
        rmFieldFlag = 1;
    end
    
    if itemIteratorFlag
        % check string values in case of pre-defined strings
        for elemNum = 1:length(itemC)            
            if ~rmFieldFlag
                valC = anonDefinS.(fieldC{i});
                if isfield(anonStructS.(itemC{elemNum}),(fieldC{i}))
                    fieldVal = anonStructS.(itemC{elemNum}).(fieldC{i});
                else
                    fieldVal = '';
                end
                fieldCalss = class(fieldVal);
            else
                fieldCalss = 'remove';
            end            
            switch fieldCalss
                case {'double','logical','single','uint8','uint16','uint32' ...
                        ,'uint64','int8','int16','int32','int64'}
                    % do nothing to the numeric fields
                case 'char'
                    if isequal(valC,'keep')
                        % keep the field as is (UID fields)
                    elseif isequal(valC,'date')
                        % assign a dummy date
                        disp(strcat('Anonymizing date from "', fieldC{i}, '" field'))
                        anonStructS.(itemC{elemNum}).(fieldC{i}) = '11111111';
                    elseif ~isempty(fieldVal) && ~ismember(fieldVal,valC)
                        disp(strcat('Anonymizing "', fieldC{i}, '" field'))
                        anonStructS.(itemC{elemNum}).(fieldC{i}) = 'CERR anonymized';
                    end                    
                case 'struct'
                    if ~isstruct(anonDefinS.(fieldC{i})) && isequal(anonDefinS.(fieldC{i}),'keep')
                        % keep all the sub-fields of this data-structure
                    else
                        % anonymize sub-fields as per the definitions
                        anonStructS.(itemC{elemNum}).(fieldC{i}) = anonymizeCERRdataStruct...
                            (anonStructS.(itemC{elemNum}).(fieldC{i}), anonDefinS.(fieldC{i}));
                    end
                case 'remove'
                    anonStructS.(itemC{elemNum}) = ...
                        rmfield(anonStructS.(itemC{elemNum}),(fieldC{i}));
                case 'cell'
                    
            end
        end
    else
        % check string values in case of pre-defined strings
        for elemNum = 1:length(structS)                        
            if ~rmFieldFlag
                valC = anonDefinS.(fieldC{i});
                if isfield(anonStructS(elemNum),(fieldC{i}))
                    fieldVal = anonStructS(elemNum).(fieldC{i});
                else
                    fieldVal = '';
                end
                fieldCalss = class(fieldVal);
            elseif isfield(anonStructS,fieldC{i})
                disp(strcat('Removing "', fieldC{i}, '" field'))
                anonStructS = rmfield(anonStructS,fieldC{i});
                continue;
            else
                continue;
            end            
            switch fieldCalss
                case {'double','logical','single','uint8','uint16','uint32' ...
                        ,'uint64','int8','int16','int32','int64'}
                    % do nothing to the numeric fields
                case 'char'
                    if isequal(valC,'keep')
                        % keep the field as is (UID fields)
                    elseif isequal(valC,'date')
                        % assign a dummy date
                        disp(strcat('Anonymizing date from "', fieldC{i}, '" field'))
                        anonStructS(elemNum).(fieldC{i}) = '11111111';
                    elseif ~isempty(fieldVal) && ~ismember(fieldVal,valC)
                        disp(strcat('Anonymizing "', fieldC{i}, '" field'))
                        anonStructS(elemNum).(fieldC{i}) = 'CERR anonymized';
                    end                    
                case 'struct'
                    if ~isstruct(anonDefinS.(fieldC{i})) && isequal(anonDefinS.(fieldC{i}),'keep')
                        % keep all the sub-fields of this data-structure
                    else
                        % anonymize sub-fields as per the definitions
                        anonStructS(elemNum).(fieldC{i}) = anonymizeCERRdataStruct...
                        (anonStructS(elemNum).(fieldC{i}), anonDefinS.(fieldC{i}));  
                    end
                    
                case 'cell'
                    
            end            
        end
    end
    
end


