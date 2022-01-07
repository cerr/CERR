function modelVoxelDose(baseScanFile,...
    registeredDoseDir,structName,outcomesFile,...
    savePlancFileName,datasetName,saveHzFileName)
% function modelVoxelDose(baseScanFile,registeredDoseDir,structName,outcomesFile,savePlancFileName)
%
% Image-based data mining of dose distributions. Function to model dose to each voxel within the heart structure.
%
% Example:
% outcomesFile = '\Data\RTOG0617\registrations_pericardium\outcomes_files\RTOG0617_OS.xlsx'
% baseScanFile = '\Data\RTOG0617\CERR_files_tcia\rider_template\RIDER-1225316081_First_resampled_1x1x3.mat';
% registeredDoseDir = '\Data\RTOG0617\registrations_pericardium\dose_export\RTOG0617_registered_to_RIDER_1225316081_First_template';
% structName = 'DL_PERICARDIUM_Aorta_plus_2cm';
% savePlancFileName = '\Data\RTOG0617\registrations_pericardium\dose_export\RTOG0617_registered_to_RIDER_1225316081_First_template\voxelAnalysisResult.mat';
% modelVoxelDose(baseScanFile,registeredDoseDir,structName,outcomesFile,savePlancFileName)
% 
% APA, 10/22/2021


cox_flag = false; % Spearmans rank correlation

% Load Outcomes file
[numM,txtC,rawC] = xlsread(outcomesFile);

% Exploratory analysis

switch upper(datasetName)
    case 'RTOG0617'
        % outcomes
        patIdC = rawC(2:end,1);
        codV = numM(:,5);
        indNotValidV = ismember(codV,[2,3,4,9]) | isnan(numM(:,4)) | isnan(numM(:,3));
        survStatusV = numM(~indNotValidV,4);
        overalSurvMonthsV = numM(~indNotValidV,2);
        armV = numM(~indNotValidV,6);
        diceV = numM(~indNotValidV,3);
        patIdC(indNotValidV) = [];
        
        % dose files
        dirS = dir(registeredDoseDir);
        dirS([dirS.isdir]) = [];
        indV = ~cellfun(@isempty,strfind({dirS.name},'0617-'));
        indV = indV & ~cellfun(@isempty,strfind({dirS.name},'.mat'));
        dirS = dirS(indV);

        
        % dose files
    case 'PORT'
        % outcomes
        patIdC = rawC(2:end,1);
        patIdC = strtok(patIdC);
        indNotValidV = isnan(numM(:,1)) | isnan(numM(:,3));
        survStatusV = numM(~indNotValidV,1);
        survStatusV = ~survStatusV; % flip so that 1 is death
        overalSurvMonthsV = numM(~indNotValidV,2);
        diceV = numM(~indNotValidV,3);
        patIdC(indNotValidV) = [];
        
        % dose files
        dirS = dir(registeredDoseDir);
        dirS([dirS.isdir]) = [];
        indV = ~cellfun(@isempty,strfind({dirS.name},'MSK_PORT_'));
        indV = indV & ~cellfun(@isempty,strfind({dirS.name},'.mat'));
        dirS = dirS(indV);
        
    case 'NEW_CONVN'
        % outcomes
        patIdC = rawC(2:end,1);
        %patIdC = cellfun(@num2str,patIdC,'UniformOutput', false);
        patIdC = strtok(patIdC);
        indNotValidV = isnan(numM(:,1)) | isnan(numM(:,3));
        survStatusV = numM(~indNotValidV,1);
        survStatusV = ~survStatusV; % flip so that 1 is death
        overalSurvMonthsV = numM(~indNotValidV,2);
        diceV = numM(~indNotValidV,3);
        patIdC(indNotValidV) = [];
        
        % dose files
        dirS = dir(registeredDoseDir);
        dirS([dirS.isdir]) = [];
        indV = ~cellfun(@isempty,strfind({dirS.name},'MSK_NEW_CONVN_'));
        indV = indV & ~cellfun(@isempty,strfind({dirS.name},'.mat'));
        dirS = dirS(indV);        
        
    case 'OLD_CONVN'
         % outcomes
        patIdC = rawC(2:end,1);
        %patIdC = cellfun(@num2str,patIdC,'UniformOutput', false);
        patIdC = strtok(patIdC);
        indNotValidV = isnan(numM(:,1)) | isnan(numM(:,3));
        survStatusV = numM(~indNotValidV,1);
        survStatusV = ~survStatusV; % flip so that 1 is death
        overalSurvMonthsV = numM(~indNotValidV,2);
        diceV = numM(~indNotValidV,3);
        patIdC(indNotValidV) = [];
        
        % dose files
        dirS = dir(registeredDoseDir);
        dirS([dirS.isdir]) = [];
        indV = ~cellfun(@isempty,strfind({dirS.name},'MSK_OLD_CONVN_'));
        indV = indV & ~cellfun(@isempty,strfind({dirS.name},'.mat'));
        dirS = dirS(indV);
        
        
end

% % Load Outcomes file
% [numM,txtC,rawC] = xlsread(outcomesFile);
% 
% % Exploratory analysis
% patIdC = rawC(2:end,1);
% codV = numM(:,5);
% indNotValidV = ismember(codV,[2,3,4,9]) | isnan(numM(:,4)) | isnan(numM(:,3));
% survStatusV = numM(~indNotValidV,4);
% overalSurvMonthsV = numM(~indNotValidV,2);
% armV = numM(~indNotValidV,6);
% diceV = numM(~indNotValidV,3);
% patIdC(indNotValidV) = [];

% figure()
% ax1 = gca;
% lowDoseV = armV==1 | armV==3;
% highDoseV = armV==2 | armV==4;
% ecdf(ax1,overalSurvMonthsV(lowDoseV,1),'Censoring',survStatusV(lowDoseV,1),'function','survivor');
% hold on
% [f,x] = ecdf(ax1,overalSurvMonthsV(highDoseV,1),'Censoring',survStatusV(highDoseV,1),'function','survivor');
% stairs(x,f,'--r')
% legend('60 Gy','74 Gy')


% Get structure mask for the cropped region
% baseScanFile = '\\vpensmph\deasylab1\Data\RTOG0617\CERR_files_tcia\rider_template\RIDER-1225316081_First_resampled_1x1x3.mat';
% Load template file and get dose grid
planC = loadPlanC(baseScanFile,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(baseScanFile,planC);
indexS = planC{end};

% Get bounds of the cropping structure
strNamC = {planC{indexS.structures}.structureName};

%structName = 'DL_PERICARDIUM_Aorta_plus_2cm';
indCropStruct = getMatchingIndex(lower(structName),lower(strNamC),'exact');
str3M = getStrMask(indCropStruct,planC);
[rMin,rMax,cMin,cMax,sMin,sMax] = compute_boundingbox(str3M);
croppedStr3M = str3M(rMin:rMax,cMin:cMax,sMin:sMax);

% Get structure mask for Left Atrium
indLeftAtrium = getMatchingIndex('l atrium',lower(strNamC),'exact');
%indLeftAtrium = getMatchingIndex('mitral valve',lower(strNamC),'exact');
leftAtriumMask3M = getStrMask(indLeftAtrium,planC);
croppedLeftAtriumStr3M = leftAtriumMask3M(rMin:rMax,cMin:cMax,sMin:sMax);

numPatients = length(survStatusV);
numVoxels = sum(croppedStr3M(:));

% Load dose files to get volumetric dose
% dirS = dir(registeredDoseDir);
% dirS([dirS.isdir]) = [];
% indV = ~cellfun(@isempty,strfind({dirS.name},'0617-'));
% indV = indV & ~cellfun(@isempty,strfind({dirS.name},'.mat'));
% dirS = dirS(indV);
doseM = zeros(numVoxels,numPatients,'single');
leftAtriumMeanDoseV = zeros(numPatients,1);
fileC = {dirS.name};
for iFile = 1:numPatients
    disp(iFile)
    %ind = find(~cellfun(@isempty,strfind(fileC,patIdC{iFile})));
    if strcmpi(datasetName,'RTOG0617')
        ind = find(strcmpi(patIdC{iFile},strtok(fileC,'_')));
    else
        ind = find(strcmpi(patIdC{iFile},strtok(fileC,'.mat')));
    end        
    dataS = load(fullfile(registeredDoseDir,dirS(ind).name));
    doseM(:,iFile) = dataS.dose3M(croppedStr3M(:));
    leftAtriumMeanDoseV (iFile,1)= mean(dataS.dose3M(croppedLeftAtriumStr3M(:)));
end

% Seed random number generator
rng(0617)

% Initialize vectors to store p-value and hazard ratio for voxels
pValV = NaN(numVoxels,1);
stdPval = NaN(numVoxels,1);
hrV = NaN(numVoxels,1);
stdHrV = NaN(numVoxels,1);

% Censor at 18 months
survAbovMonthCutoffV = overalSurvMonthsV > 18;
overalSurvMonthsV(survAbovMonthCutoffV) = 18;
survStatusV(survAbovMonthCutoffV) = 0; %alive

% Find observations tht are lost to followup before 18 months
indLostFupV = overalSurvMonthsV < 18 & survStatusV == 0;

censoredV = survStatusV == 1; % this is flipped in call to coxphfit to censor observations that are alive
indToUseV = diceV > 0.75;

% Reserve 30% of data for validation
% train: 70%, validation: 30%
%cv = cvpartition(numPatients,'HoldOut',0.3);
%cv = cvpartition(numPatients,'HoldOut',0.01);
indTrainV = indToUseV & ~indLostFupV; % & cv.training;
%indTestV = indToUseV & cv.test;


% Bootstrap the training set
numBoots = 100; %10
numTraining = sum(indTrainV);
trainIndV = find(indTrainV);
indBootM = false([numTraining,numBoots]);
for i=1:numBoots
    selectedV = randsample(numTraining,numTraining,true);
    indBootM(selectedV,i) = 1;
    %indBootM(:,i) = accumarray(selectedV,1, [numTraining,1]);
end
%indBootM = bsxfun(@(x,y) x & y, indBootM, indTrainV);


tic
pValM = zeros(numVoxels,numBoots);
hrM =  zeros(numVoxels,numBoots);

parfor iBoot = 1:numBoots    %parfor
    
    disp(['====== Bootstrap # ',num2str(iBoot)])
    
    selectedV = randsample(numTraining,numTraining,true);
    indV = trainIndV(selectedV);

    for i = 1:numVoxels
        %if ~mod(i,50)
        %   disp(['========', num2str(i), '  ==============='])
        %end
        %statsS = struct();
        
        %indV = trainIndV(indBootM(:,iBoot));
        doseTrainV = doseM(i,indV);
        doseTrainV = doseTrainV + 1e-5*rand(size(doseTrainV));
        doseTrainV = doseTrainV(:);
        survTrainV = overalSurvMonthsV(indV);
        censorTrainV = censoredV(indV);
        
        leftAtriumMeanDoseTrainV = leftAtriumMeanDoseV(indV);
        
        if cox_flag
            % ====== Cox model
            [b,logl,H,statsS] = ...
                coxphfit(double(doseTrainV),survTrainV,...
                'censoring',~censorTrainV);
            % C:\Program Files\Matlab\R2019b\toolbox\stats\stats\private\statsfminbx.m figtr line 186
            
            %statsS = bsxfun(@cox,doseTrainM, survTrainM, censorTrainM);
            pValM(i,iBoot) = statsS.p;
            hrM(i,iBoot) = statsS.beta;
            
        else
            
            % ====== Spearman rank correlation
            %[rho,p] = corr(double(doseTrainV),survTrainV,'Type','spearman');            
            [rho,p] = corr(double(doseTrainV),leftAtriumMeanDoseTrainV,'Type','spearman');            
            pValM(i,iBoot) = p;
            hrM(i,iBoot) = rho;
            
        end
        
    end
    
end
toc

if exist('saveHzFileName','var')
    save(saveHzFileName,'hrM')
end

% Add doses to planC
[xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(1));
grid2Units = abs(xValsV(2)-xValsV(1));
grid1Units = abs(yValsV(1)-yValsV(2));
regParamsS.horizontalGridInterval = grid2Units;
regParamsS.verticalGridInterval= - abs(grid1Units);
regParamsS.coord1OFFirstPoint =  xValsV(cMin);
regParamsS.coord2OFFirstPoint =  yValsV(rMin);
regParamsS.zValues = zValsV(sMin:sMax);
assocScanUID = planC{indexS.scan}(1).scanUID;

if cox_flag
    expHrM = exp(hrM);
else
    expHrM = hrM;
end

% hV = zeros(numVoxels,1);
% pV = zeros(numVoxels,1);
% ciM = zeros(numVoxels,2);
% 
% for i = 1:size(expHrM,1)
%     [hV(i) , pV(i) , ciM(i,:)] = ttest(expHrM(i,:),1.02,'Alpha',0.01,'Tail','right');
% end

% Calculate median of bootstraps
medianHrV = median(expHrM,2);

% Calculate mean of bootstraps
meanHrV = mean(expHrM,2);


% Calculate standard deviation
stdV = std(expHrM,[],2);


% voxelsToKeepV = medianHrV - stdV*2 > 1;
% val3M = NaN(size(croppedStr3M));
% val3M(croppedStr3M(:)) = voxelsToKeepV;
% planC = dose2CERR(val3M,[],...
%     'Median-hazard - (2-sigma) > 1',[],[],'non-CT',regParamsS,'no',...
%     assocScanUID,planC);
% 
% 
% voxelsToKeepV = medianHrV - stdV*3 > 1;
% val3M = NaN(size(croppedStr3M));
% val3M(croppedStr3M(:)) = voxelsToKeepV;
% planC = dose2CERR(val3M,[],...
%     'Median-hazard - (3-sigma) > 1',[],[],'non-CT',regParamsS,'no',...
%     assocScanUID,planC);
% 
% 
% voxelsToKeepV = medianHrV - stdV*4 > 1;
% val3M = NaN(size(croppedStr3M));
% val3M(croppedStr3M(:)) = voxelsToKeepV;
% planC = dose2CERR(val3M,[],...
%     'Median-hazard - (4-sigma) > 1',[],[],'non-CT',regParamsS,'no',...
%     assocScanUID,planC);
% 
% 
% voxelsToKeepV = medianHrV - stdV*4.2 > 1;
% val3M = NaN(size(croppedStr3M));
% val3M(croppedStr3M(:)) = voxelsToKeepV;
% planC = dose2CERR(val3M,[],...
%     'Median-hazard - (4.2-sigma) > 1',[],[],'non-CT',regParamsS,'no',...
%     assocScanUID,planC);


val3M = NaN(size(croppedStr3M));
val3M(croppedStr3M(:)) = stdV;
planC = dose2CERR(val3M,[],...
    'Std Dev Hazard',[],[],'non-CT',regParamsS,'no',...
    assocScanUID,planC);

val3M = NaN(size(croppedStr3M));
val3M(croppedStr3M(:)) = medianHrV; 
planC = dose2CERR(val3M,[],...
    'Median Hazard',[],[],'non-CT',regParamsS,'no',...
    assocScanUID,planC);

val3M = NaN(size(croppedStr3M));
val3M(croppedStr3M(:)) = meanHrV; 
planC = dose2CERR(val3M,[],...
    'Mean Hazard',[],[],'non-CT',regParamsS,'no',...
    assocScanUID,planC);

val3M = NaN(size(croppedStr3M));
val3M(croppedStr3M(:)) = medianHrV ./ stdV; 
planC = dose2CERR(val3M,[],...
    'MedianHazard / StdDev',[],[],'non-CT',regParamsS,'no',...
    assocScanUID,planC);


% ========== add a bootstrap hr to planC
% val3M = NaN(size(croppedStr3M));
% val3M(croppedStr3M(:)) = hrM(:,95); 
% planC = dose2CERR(val3M,[],...
%     'Hazard_boot_95',[],[],'non-CT',regParamsS,'no',...
%     assocScanUID,planC);



% =========== Write individual bootstrap samples to planC
% for iBoot = 1:numBoots
%     % Initialize dose matrix to store voxel-wise p-values
%     dose3M = NaN(size(croppedStr3M));
%     % dose3M(str3M(:)) = -log10(pValV);
%     dose3M(croppedStr3M(:)) = pValM(:,iBoot);
%     
%     hazRat3M = NaN(size(croppedStr3M));
%     hazRat3M(croppedStr3M(:)) = exp(hrM(:,iBoot));
%     
%     planC = dose2CERR(dose3M,[],...
%         ['p_boot_',num2str(iBoot)],[],[],'non-CT',regParamsS,'no',...
%         assocScanUID,planC);
%     planC = dose2CERR(hazRat3M,[],...
%         ['Hazard Ratio_',num2str(iBoot)],[],[],'non-CT',regParamsS,'no',...
%         assocScanUID,planC);
% end



% planC = dose2CERR(dose3M,[], 'p_10_boot_avg','test','test','UniformCT',...
%     regParamsS,'no',assocScanUID,planC);
% planC = dose2CERR(hazRat3M,[], 'Hazard Ratio','test','test','UniformCT',...
%     regParamsS,'no',assocScanUID,planC);
% threshold = max(dose3M(str3M))*0.5;
%threshold = graythresh(dose3M(str3M));
% threshold = 0.05; % p<0.01
% doseNum = 1; %p-value
% assocScanNum = 1;
% planC = doseToStruct(doseNum,threshold,assocScanNum,planC);

planC = save_planC(planC,[],'passed',savePlancFileName);


% % Evaluate on hold out Test set
% % structNum = length(planC{indexS.structures});
% % pValStr3M = getUniformStr(structNum,planC);
% 
% % Get tge mask of "risky" structure
% %strTestInd = getMatchingIndex(strTestName,strC,'exact');
% %testMask3M = getStrMask(strTestInd,planC);
% croppedTestMask3M = testMask3M(rMin:rMax,cMin:cMax,sMin:sMax);
% meanDoseTestV = zeros(numTraining,1);
% maxDoseTestV = zeros(numTraining,1);
% for iFile = 1:numPatients
%     disp(iFile)
%     ind = find(~cellfun(@isempty,strfind(fileC,patIdC{iFile})));
%     dataS = load(fullfile(registeredDoseDir,dirS(ind).name));
%     meanDoseTestV(iFile) = mean(dataS.dose3M(croppedTestMask3M(:)));
%     maxDoseTestV(iFile) = max(dataS.dose3M(croppedTestMask3M(:)));
% end
% 
% bottomMeanCut = quantile(meanDoseTestV,0.33);
% topMeanCut = quantile(meanDoseTestV,0.67);
% bottomMaxCut = quantile(maxDoseTestV,0.33);
% topMaxCut = quantile(maxDoseTestV,0.67);
% 
% survTimeTestV = overalSurvMonthsV(indTrainV);
% censoredTestV = survStatusV(indTrainV);
% meanDoseTestValidV = meanDoseTestV(indTrainV);
% maxDoseTestValidV = maxDoseTestV(indTrainV);
% 
% timeCutoff = 60; %months
% bottomMeanCut = 5; % Gy
% topMeanCut = 5; % Gy
% riskyM = [survTimeTestV(meanDoseTestValidV>topMeanCut & survTimeTestV<timeCutoff), censoredTestV(meanDoseTestValidV>topMeanCut & survTimeTestV<timeCutoff)];
% safeM = [survTimeTestV(meanDoseTestValidV<=bottomMeanCut & survTimeTestV<timeCutoff), censoredTestV(meanDoseTestValidV<=bottomMeanCut & survTimeTestV<timeCutoff)];
% figure, logrank(riskyM,safeM)
% 
% figure(), hold on,
% ecdf(survTimeTestV(meanDoseTestValidV>topMeanCut & survTimeTestV<timeCutoff),'censoring',censoredTestV(meanDoseTestValidV>topMeanCut & survTimeTestV<timeCutoff),'function','survivor');
% ecdf(survTimeTestV(meanDoseTestValidV<=bottomMeanCut & survTimeTestV<timeCutoff),'censoring',censoredTestV(meanDoseTestValidV<=bottomMeanCut & survTimeTestV<timeCutoff),'function','survivor');
% 
% 
% bottomMaxCut = 5; % Gy
% topMaxCut = 5; % Gy
% riskyM = [survTimeTestV(maxDoseTestValidV>topMaxCut & survTimeTestV<timeCutoff), censoredTestV(maxDoseTestValidV>topMaxCut & survTimeTestV<timeCutoff)];
% safeM = [survTimeTestV(maxDoseTestValidV<=bottomMaxCut & survTimeTestV<timeCutoff), censoredTestV(maxDoseTestValidV<=bottomMaxCut & survTimeTestV<timeCutoff)];
% figure, logrank(riskyM,safeM)
% 
% 
% figure(), hold on,
% ecdf(survTimeTestV(maxDoseTestValidV>topMaxCut),'censoring',censoredTestV(maxDoseTestValidV>topMaxCut),'function','survivor');
% ecdf(survTimeTestV(maxDoseTestValidV<=bottomMaxCut),'censoring',censoredTestV(maxDoseTestValidV<=bottomMaxCut),'function','survivor');
% 
% 
% %meanDoseTestV = mean(doseM(pValStr3M(croppedStr3M(:)),indTestV),1);
% % meanDoseTestV = mean(doseM(:,indTestV),1);
% % survTimeTestV = overalSurvMonthsV(indTestV);
% % censoredTestV = censoredV(indTestV);
% % figure(), hold on,
% % ecdf(survTimeTestV(meanDoseTestV>topCut),'censoring',censoredTestV(meanDoseTestV>topCut),'function','survivor');
% % ecdf(survTimeTestV(meanDoseTestV<=bottomCut),'censoring',censoredTestV(meanDoseTestV<=bottomCut),'function','survivor');
% 

disp('=========== DONE saving voxel-wise model ===========')


