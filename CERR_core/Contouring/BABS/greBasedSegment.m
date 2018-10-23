% greBasedSegment.m
%
% APA, 3/20/2017

% directory containing all files
dirName = 'H:\Public\Aditya\mimExtensions\CERR_files_Sandra_contours_PC';
dirName = 'H:\Public\Aditya\mimExtensions\CERR_files_Sandra_contours_CT';
dirName = 'H:\Public\Aditya\mimExtensions\Atlas_Sanne\PC_cerr';
% dirName = 'H:\Public\Aditya\mimExtensions\Atlas_Sanne\CT_cropped_cerr';

% directory for writing the registered files (must have \ or / as last character)
registeredDir = 'H:\Public\Aditya\mimExtensions\registered_to_ROBINSON^HEATH_35487047\';
registeredDir = 'H:\Public\Aditya\mimExtensions\registered_to_ROBINSON^HEATH_35487047_CT\';
registeredDir = 'H:\Public\Aditya\mimExtensions\registered_to_MT160_PC\';
% registeredDir = 'H:\Public\Aditya\mimExtensions\registered_to_MT160_CT\';

dirS = dir(dirName);
dirS(1:2) = [];

% base scan file name
indBase = 3; %9 for Sandra's atlas, 3 for Sanne's 
baseScan = fullfile(dirName,dirS(indBase).name);

% moving scan file names
indV = 1:length(dirS);
indV(indBase) = [];
movScanC = fullfile(dirName,{dirS(indV).name});

% registration callback
strNameToWarp = 'Parotid_L_SvD';
registerToAtlas(baseScan,movScanC,registeredDir,strNameToWarp)


% combine using the STAPLE and the GRE metric
regDirS = dir(registeredDir);
regDirS(1:2) = [];
regFilesC = strcat(registeredDir,{regDirS.name});
indBase = [3];
regFilesC(indBase) = [];
structNum = 2;
doseNum = 1;
scanNum = 1;
doseAllM = [];
strAllM = logical([]);
for i = 1:length(regFilesC)
    planC = loadPlanC(regFilesC{i},tempdir);
    indexS = planC{end};    
    % Calculate the GRE metric
    baseScanNum = 1;
    movScanNum = 2;
    planC = calculateGRE(baseScanNum,movScanNum,planC);
    dose3M = getDoseOnCT(doseNum, scanNum, 'uniform', planC);
    str3M = getUniformStr(structNum,planC);
    strAllM(:,i) = str3M(:);
    doseAllM(:,i) = dose3M(:) .* str3M(:);
end

siz = size(str3M);

% STAPLE
numIter = 50;
confidence = 0.8;
numObservers = size(strAllM,2);
p = ones(1,numObservers)*0.999;
q = p;
[W,p,q] = staple(strAllM,confidence,p,q);
stapleStr3M = reshape(W > confidence,siz);
isUniform = 1;
scanNum = 1;
maskToCERRStructure(stapleStr3M,isUniform,scanNum,'STAPLE_80_pct_conf')


% Smooth contour
structNum = 2;
for slc = 1:length(planC{indexS.structures}(structNum).contour)
    for seg = 1:length(planC{indexS.structures}(structNum).contour(slc).segments)
        ptsM = planC{indexS.structures}(structNum).contour(slc).segments(seg).points;
        if isempty(ptsM)
            continue;
        end
        numPts = size(ptsM,1);
        intrvl = ceil(numPts*0.2/10);
        pts1M = spcrv(ptsM(1:intrvl:end,1:2)',3,100)';
        pts1M(:,3) = ptsM(1,3)*pts1M(:,1).^0;
        pts1M(end+1,:) = pts1M(1,:);
        planC{indexS.structures}(structNum).contour(slc).segments(seg).points = pts1M;
    end
end
reRasterAndUniformize

% GRE map
atlasGreV = sum(doseAllM,1) ./ sum(strAllM,1);
indToUse = atlasGreV < prctile(atlasGreV,30);
indToUse = 1:12;
weightedSegM = bsxfun(@times, strAllM(:,indToUse), (1./atlasGreV(indToUse)).^5);
weightedSegM(weightedSegM == 0) = NaN;
Wv = nansum(weightedSegM,2); % voxels weighted by GRE per registration

% Wv = nanmean(weightedSegM,2) < prctile(atlasGreV,50);
% % Wv = strAllM(:,2);
% segM = reshape(Wv,siz);
% maskToCERRStructure(segM,1,1,'GRE Weighted Majority')


% Combine GRE for each voxel
% gama = 1;
% invDoseAllM = 1./(doseAllM(:,indToUse)+eps);
% indZeroV = doseAllM(:,indToUse) > 0;
% invThrV = nanmean(doseAllM(:,indToUse),2);
% thrM = 1 ./ invThrV;
% thrM(invThrV < eps) = 0;
% thrV = mean(thrM,2)+1e10;
% % thr = mean(invDoseAllM(indZeroV)); % global thr
% % indZeroV = indZeroV & invDoseAllM > thrV;
% indZeroV = indZeroV & bsxfun(@le,invDoseAllM', thrV')';
% invDoseAllM(~indZeroV) = NaN;
% Wv = nansum(invDoseAllM.^gama , 2);
% % numMembersV = sum(strAllM,2);
% % Wv = Wv ./ numMembersV;

weightM = reshape(Wv,siz);
weightM(isnan(weightM)) = 0;
showIMDose(weightM,'ConsensusGRE',1);


