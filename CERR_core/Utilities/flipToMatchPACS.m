function planC = flipToMatchPACS(scanNumV,dim,planC)
% flipToMatchPACS(planC,scanNum,dim)
% ---- INPUTS ----
% scanNumV: Indices of scans to be flipped
% dim     : May be 'lr', 'ap', 'si'
% planC   : CERR archive
% ---------------
% AI 9/20/17

indexS = planC{end};

for i = 1:length(scanNumV)
    nSlice = length([planC{indexS.scan}(scanNumV(i)).scanInfo]);
    switch lower(dim)
        
        case 'lr'
            if ~isfield(planC{indexS.scan}(scanNumV(i)).scanInfo(1),'LRflippedToMatchPACS')
                [planC{indexS.scan}(scanNumV(i)).scanInfo(:).LRflippedToMatchPACS] = deal('');
            end
            planC = flipAlongX(scanNumV(i),planC);
            currentFlagV = [planC{indexS.scan}(scanNumV(i)).scanInfo(:).LRflippedToMatchPACS];
            if isempty(currentFlagV)
                currentFlagV = false(nSlice,1);
            end
            flipFlagC = num2cell(~currentFlagV);
            [planC{indexS.scan}(scanNumV(i)).scanInfo(:).LRflippedToMatchPACS] = flipFlagC{:};
            
        case 'ap'
            if ~isfield(planC{indexS.scan}(scanNumV(i)).scanInfo(1),'APflippedToMatchPACS')
                [planC{indexS.scan}(scanNumV(i)).scanInfo(:).APflippedToMatchPACS] = deal('');
            end
            planC = flipAlongY(scanNumV(i),planC);
            currentFlagV = [planC{indexS.scan}(scanNumV(i)).scanInfo(:).APflippedToMatchPACS];
            if isempty(currentFlagV)
                currentFlagV = false(nSlice,1);
            end
            [planC{indexS.scan}(scanNumV(i)).scanInfo(:).APflippedToMatchPACS] = ~currentFlagV;
            
        case 'si'
            if ~isfield(planC{indexS.scan}(scanNumV(i)).scanInfo(1),'SIflippedToMatchPACS')
                [planC{indexS.scan}(scanNumV(i)).scanInfo(:).SIflippedToMatchPACS] = deal('');
            end
            planC = flipAlongZ(scanNumV(i),planC);
            currentFlagV = [planC{indexS.scan}(scanNumV(i)).scanInfo(:).SIflippedToMatchPACS];
            if isempty(currentFlagV)
                currentFlagV = false(nSlice,1);
            end
            [planC{indexS.scan}(scanNumV(i)).scanInfo(:).SIflippedToMatchPACS] = ~currentFlagV;
            
        otherwise
            CERRString('Invalid input. ''dim'' must be ''lr'' ,''ap'' or ''si'' ','console');
            return
    end
    
end



end