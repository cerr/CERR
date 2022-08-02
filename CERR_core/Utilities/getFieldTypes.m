function [fieldTypeC,locationStrC] = getFieldTypes(inField,locationStr)
% function fieldTypeC = getFieldTypes(inField,locationStr)
% 
% Returns type for all fields in inField.
%
% Example:
% [fieldTypeC,locationStrC] = getFieldTypes(planC,'planC');
%
% APA, 8/2/2022

fieldTypeC = {};
locationStrC = {};
fieldType = class(inField);
switch fieldType
    case 'cell'
    numCells = length(inField);
    for cellNum = 1:numCells
        data = inField{cellNum};
        fieldType = class(data);
        cellLocationStr = [locationStr,'{',num2str(cellNum),'}'];
        if any(strcmpi(fieldType,{'cell','struct'}))
            [outFieldType,outLocationStrC] = getFieldTypes(data,cellLocationStr);
            fieldTypeC = [fieldTypeC,outFieldType];
            locationStrC = [locationStrC,outLocationStrC];
        else
            fieldTypeC{end+1} = fieldType;
            locationStrC{end+1} = cellLocationStr;
        end
    end
    case 'struct'
        fieldNamC = fieldnames(inField);
        numStructs = length(inField);
        numFields = length(fieldNamC);
        for iElem = 1:numStructs
            for iField = 1:numFields
                data = inField(iElem).(fieldNamC{iField});
                fieldType = class(data);
                structLocationStr = [locationStr,'(',num2str(iElem),').',fieldNamC{iField}];
                if any(strcmpi(fieldType,{'cell','struct'}))
                    [outFieldType,outLocationStrC] = getFieldTypes(data,structLocationStr);
                    fieldTypeC = [fieldTypeC,outFieldType];
                    locationStrC = [locationStrC,outLocationStrC];
                else
                    fieldTypeC{end+1} = fieldType;
                    locationStrC{end+1} = structLocationStr;
                end
            end
        end
    otherwise
        fieldType = class(inField);
        if any(strcmpi(fieldType,{'cell','struct'}))
            [outFieldType,outLocationStrC] = getFieldTypes(inField,locationStr);
            fieldTypeC = [fieldTypeC,outFieldType];
            locationStrC = [locationStrC,outLocationStrC];
        else
            fieldTypeC{end+1} = fieldType;
            locationStrC{end+1} = locationStr;
        end
    
end
