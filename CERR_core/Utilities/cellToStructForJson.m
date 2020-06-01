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
    %uniqFieldC = unique(fieldC,'stable');
    [~,idxV] = unique(fieldC,'first');
    uniqFieldC = fieldC(sort(idxV));
    %if size(uniqFieldC,2) == 1 
        dataS = struct();
        for i = 1:size(fieldC,1)
            for j = 1:size(uniqFieldC,1)
                dataS(i).(uniqFieldC{j}) = valC{i,j};
            end
        end
    %else 
        %dataS = dataC;
    %end
else
    dataS = dataC;
end

