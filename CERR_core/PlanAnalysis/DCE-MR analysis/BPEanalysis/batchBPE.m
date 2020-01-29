function processedC = batchBPE(BPEfPath,latPath,outPath)
% Batch-segment FGT region using intensity histogram-based thresholding
% Usage :  [mrnC,processedC] = batchBPE(BPEfPath,latPath,outPath);
%
% Inputs:
% BPEfPath - Path to CERR files with bounding boxes
% latPath  - Path to Matlab table w/ laterality info
% % latPath = '\\VPensBST\BstShared\Epidemiology\Pike\Breast_MSK\BPE\Soft\Apte\AxialFiles\IMAGINE\Batch8_jan2019\lattable.mat';
% outPath  - Path to output folder
%
% Output: 'processedC' constains a message indicating if the pt
% was successfully processed and records the error message if not.
%
%--------------------------------------------------
%iyera@mskcc.org 5/8/18
%--------------------------------------------------

%Get laterality
T = load(latPath);
varname = fieldnames(T);
T = T.(varname{1});

%Command file for registration
cmdFile = '\\VPensBST\BstShared\Epidemiology\Pike\Breast_MSK\BPE\Soft\Apte\CERR\CERR_core\ImageRegistration\plastimatch_command\malcolm_pike_mr_breast_data.txt';

% Loop over files
dirS = dir([BPEfPath,filesep,'*.mat']);
nameC = {dirS.name};

outPathC = cell(length(nameC),1);
for n =1:length(outPathC)
    [~,t,~] = fileparts(nameC{n});
    %t = t(1);
    outFname = [t,'_FGTSeg.mat'];
    outPathC{n} = fullfile(outPath,outFname);
end

processedC = cell(length(nameC),1);


for i = 1:length(nameC)
    
    mrn =  nameC{i};
    
    %     try
    %Load file
    fname = nameC{i};
    fulllFileName = fullfile(BPEfPath,fname);
    planC = loadPlanC(fulllFileName,tempdir);
    indexS = planC{end};
    
    H = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders;
    patID = H.PatientID;
    idxV = strcmpi(T.MRN,patID);
    side = T.Laterality(idxV);
    structListC = {planC{indexS.structures}.structureName};
    breastMaskIdx = find(contains(structListC,lower(side)));
    
    
    %Get FGT mask (Method - I  : Histogram-basedthresholding of difference image )
    [planC,seriesIdxV,FGTmask3M] = getFGTMask(planC,breastMaskIdx,[1,2,3],0,cmdFile,0);
    
    if ~isempty(FGTmask3M)
        isUniform = 0;
        planC = maskToCERRStructure(FGTmask3M, isUniform, seriesIdxV(2), 'hist_FGT', planC); %Structure associated w/ FS-pre scan
        FGTStrNum = length(planC{indexS.structures});
        
        %Transfer to post-contrast sequences
        basePlanC = planC;
        movPlanC = planC;
        deform1S = basePlanC{indexS.deform}(end);
        planC = warp_structures(deform1S,seriesIdxV(3),FGTStrNum,movPlanC,basePlanC); %FS-post
    end
    
    %Calculate BPE
    %     FSPreScan3M = double(getScanArray(seriesIdxV(2),planC));
    %     FSPreMask3M = double(getUniformStr(FGTStrNum+1,planC));
    %     FSPreMasked3M = FSPreScan3M.*FSPreMask3M;
    %     FSPostScan3M =  double(getScanArray(seriesIdxV(3),planC));
    %     FSPostMask3M = double(getUniformStr(FGTStrNum+2,planC));
    %     FSPostMasked3M = FSPostScan3M.*FSPostMask3M;
    %     BPE3M = FSPostMasked3M - FSPreMasked3M./(FSPreMasked3M+eps);
    %     planC = BPE2dose(BPE3M,seriesIdxV(1),planC);
    
    %Save files with FGT masks
    out = outPathC{i};
    save_planC(planC,[],'passed',out);
    %delete(fullfile(BPEfPath,fname));
    processedC{i} = ['Processed pt ',mrn];
    
    %     catch e
    %
    %     processedC{i} = ['Pt ',mrn,' failed with error',...
    %         e.message];
    %
    %     end
    
end

% xlname = fullfile(outPath,'Process_status.xlsx');
% xlswrite(xlname,{'Filename','Processed'},1,'A2');
% xlswrite(xlname,mrnC,1,'A2');
% xlswrite(xlname,processedC,1,'B2');



%------------Sub-functions -----
    function planC = BPE2dose(map3M,scanNum,planC)
        % Display maps as dose
        index1S = planC{end};
        scan3M = getScanArray(scanNum,planC);
        [xVals, yVals, zVals] = getScanXYZVals(planC{index1S.scan}(scanNum));
        deltaXYZv(1) = abs(xVals(2)-xVals(1));
        deltaXYZv(2) = abs(yVals(2)-yVals(1));
        deltaXYZv(3) = abs(zVals(2)-zVals(1));
        uniqueSlices = 1:size(scan3M,3);
        zV = zVals(uniqueSlices);
        minr = 1;
        minc = 1;
        regParamsS.horizontalGridInterval = deltaXYZv(1);
        regParamsS.verticalGridInterval   = -deltaXYZv(2);
        regParamsS.coord1OFFirstPoint   = xVals(minc);
        regParamsS.coord2OFFirstPoint   = yVals(minr); % for dose
        regParamsS.zValues  = zV;
        regParamsS.sliceThickness = [planC{index1S.scan}(scanNum).scanInfo(uniqueSlices).sliceThickness];
        assocUID = createUID('FEATURESET');
        planC = dose2CERR(map3M,[],'BPE','BPE','BPE','non CT',regParamsS,'no',assocUID,planC);
    end



end
