function dataS = cellToStructForJson(dataC)
% function dataS = cellToStructForJson(dataC)
%
%Loops through all elements of input cell array dataC and converts to dataS
%if the elements are structus with same field names. This is necessary to
% make json reading compatible between MATLAB and open source loadjson.m
%
% APA, 7/9/2018

fieldC = {};
valC = {};
for i = 1:length(dataC)
    fieldClass = class(dataC{i});
    switch fieldClass
        case 'struct'
            fieldNamC = fieldnames(dataC{i});
            for j = 1:length(fieldNamC)
                fieldC{i,j} = fieldNamC{j};
                valC{i,j} = dataC{i}.(fieldNamC{j});
            end
        otherwise
            fieldC = {};
            valC = {};
            break;
    end
end


if ~isempty(fieldC)
    emptyIdxC = cellfun(@isempty,fieldC,'un',0);
    if any([emptyIdxC{:}])
      fieldC([emptyIdxC{:}]) = 'empty';
    end
    [~,idxV] = unique(fieldC,'first');
    uniqFieldC = fieldC(sort(idxV));
    dataS = struct();
    for i = 1:size(fieldC,1)
       for j = 1:size(fieldC,2)
          dataS(i).(uniqFieldC{j}) = valC{i,j};
       end
    end
    if isfield(dataS,'empty')
      dataS = rmfield(dataS,'empty');
    end
else
    dataS = dataC;
end
