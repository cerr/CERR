function limitV = extractNTCPconstraints(critS,modelStr,modelFile)

limitV = [];

if isfield(critS.structures.(modelStr),'guidelines')
    limitTypeC = fieldnames(critS.structures.(modelStr).guidelines);
    candidateV = find(contains(limitTypeC,'NTCP'));
    for c = 1:length(candidateV)
        guidS = critS.structures.(modelStr).guidelines.(limitTypeC{candidateV(c)});
        if strcmpi(guidS.parameters.modelFile,modelFile)
            limitV(end+1) = guidS.limit;
            break
        end
    end
end

if isfield(critS.structures.(modelStr),'criteria')
    limitTypeC = fieldnames(critS.structures.(modelStr).criteria);
    candidateV = find(contains(limitTypeC,'NTCP'));
    for c = 1:length(candidateV)
        limitS = critS.structures.(modelStr).criteria.(limitTypeC{candidateV(c)});
        if strcmpi(limitS.parameters.modelFile,modelFile)
            limitV(end+1) = limitS.limit;
            break
        end
    end
end


end