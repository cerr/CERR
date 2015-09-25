function planC = createIMuids(planC)
% function planC = createIMuids(planC)
%
% APA, 10/21/2014

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

nIM = length(planC{indexS.IM});
for i = 1:nIM
    % Copy beams, goals, solution, params fields from IMsetup to IMDosimetry
    if ~isfield(planC{indexS.IM}(i),'IMDosimetry') && isfield(planC{indexS.IM}(i),'IMSetup')
        planC{indexS.IM}(i).IMDosimetry = planC{indexS.IM}(i).IMSetup;
    else
        %do nothing asuming IMDosimerty was properly populated
    end

    % check for empty dosimetry and assign default name
    if ~isempty(planC{indexS.IM}(i).IMDosimetry)
        % Assign a default name 'IM doseSet'
        planC{indexS.IM}(i).IMDosimetry.name = 'IM doseSet';
        % Assume Dosimetry (beamlets) is fresh (1=fresh, 2=stale)
        planC{indexS.IM}(i).IMDosimetry.isFresh = 1;
    end
    
    
    % check for empty IMUID field assign default IMUID
    if isfield(planC{indexS.IM}(i),'IMUID') && isempty(planC{indexS.IM}(i).IMUID)
        planC{indexS.IM}(i).IMUID = createUID('IM');
    end
    
    % check for empty beamUID field assign default beamUID
    if ~isempty(planC{indexS.IM}(i).IMDosimetry.beams) && ((isfield(planC{indexS.IM}(i).IMDosimetry.beams(1),'beamUID') && isempty(planC{indexS.IM}(i).IMDosimetry.beams(1).beamUID)) || ~isfield(planC{indexS.IM}(i).IMDosimetry.beams(1),'beamUID'))
        for iBeam = 1:length(planC{indexS.IM}(i).IMDosimetry.beams)
            planC{indexS.IM}(i).IMDosimetry.beams(iBeam).beamUID = createUID('BEAM');
        end
    end    
    
    % Link structure UID to goals
    if isfield(planC{indexS.IM}(i).IMDosimetry,'goals')
        for j = 1:length(planC{indexS.IM}(i).IMDosimetry.goals)
            structNum = planC{indexS.IM}(i).IMDosimetry.goals(j).structNum;
            if isempty(planC{indexS.IM}(i).IMDosimetry.goals(j).strUID)
                planC{indexS.IM}(i).IMDosimetry.goals(j).strUID = planC{indexS.structures}(structNum).strUID;
            end
        end        

        % Link scan UID to IM
        if isempty(planC{indexS.IM}(i).IMDosimetry.assocScanUID)
            planC{indexS.IM}(i).IMDosimetry.assocScanUID = planC{indexS.scan}(1).scanUID;
        end
        
        % put beamlets under its parent beam
        if isfield(planC{indexS.IM}(i).IMDosimetry,'beamlets')
            structPresentV = ~cellfun('isempty',squeeze({planC{indexS.IM}(i).IMDosimetry.beamlets.beamNum}));
            structPresentM = reshape(structPresentV,size(planC{indexS.IM}(i).IMDosimetry.beamlets));
            beamletTotal = 0;
            for beamNum = 1:length(planC{indexS.IM}(i).IMDosimetry.beams)
                numBeamlets = length(planC{indexS.IM}(i).IMDosimetry.beams(beamNum).xPBPosV);
                planC{indexS.IM}(i).IMDosimetry.beams(beamNum).beamlets = planC{indexS.IM}(i).IMDosimetry.beamlets(structPresentM(:,1),beamletTotal+1:beamletTotal+numBeamlets);
                beamletTotal = beamletTotal + numBeamlets;
            end
            
            % assign strUID
            count = 0;
            strPresentV = find(structPresentM(:,1));
            for strNum = 1:length(strPresentV)
                count = count + 1;
                for beamNum = 1:length(planC{indexS.IM}(i).IMDosimetry.beams)
                    [planC{indexS.IM}(i).IMDosimetry.beams(beamNum).beamlets(count,:).strUID] = deal(planC{indexS.structures}(strPresentV(strNum)).strUID);
                end
            end
            
            % remove beamlets field from IMDosimetry since it is a part of beams now
            planC{indexS.IM}(i).IMDosimetry = rmfield(planC{indexS.IM}(i).IMDosimetry,'beamlets');
            
        end
        
        %rename solution to solutions
        if isfield(planC{indexS.IM}(i).IMDosimetry,'solution')
            planC{indexS.IM}(i).IMDosimetry.solutions =  planC{indexS.IM}(i).IMDosimetry.solution;
            planC{indexS.IM}(i).IMDosimetry = rmfield(planC{indexS.IM}(i).IMDosimetry,'solution');
        end

    end
end
