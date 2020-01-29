function batchSpreadsheet(fPath,latPath)
% USAGE ---
% batchSpreadsheet(fPath,latPath);
% INPUTS---
% fpath   : Path to directory with CERR files containing FGT seg
% latPath : Path to table w/ laterality info
%           Loc: 'M:\Aditi\forDrPike\batch2_reg\code\lattable.mat';
%-----------------------------------------------------------------
%iyera@mskcc.org 5/8/18
%-----------------------------------------------------------------

dirS = dir([fPath,'\*.mat']);
nameC = {dirS.name};
normFlag = 0;
fid = fopen(fullfile(fPath,'FGTRatio_hist.txt'),'w');

%Get laterality
T = load(latPath);
T = T.T;


for i = 1:length(nameC)
    
    try
        fname = nameC{i};
        planC = loadPlanC(fullfile(fPath,fname),tempdir);
        indexS = planC{end};
        
        t = strfind(fname,'_');
        t = t(1);
        
        %Get breast str no.
        H = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders;
        patID = H.PatientID;
        idxV = strcmpi(T.MRN,patID);
        side = T.Laterality(idxV);
        structListC = {planC{indexS.structures}.structureName};
        breastStrC = strfind(structListC,['Warped_Auto_bbox_',lower(side{1})]) ;
        breastC = cellfun(@isempty,breastStrC,'un',0);
        breastStrId = find(~[breastC{:}]);
        
        %Get FGT str no.
        preScanIdx = 2;
        postDeformedScanIdx = 5;
        
        allScansWithAssocStrV = [planC{indexS.structures}.associatedScan];
        
        if ~ismember(preScanIdx,allScansWithAssocStrV)
            %Handles cases with too few slices (no FGT)
            fprintf(fid,'\n%d. %s | FGTRatio = 0\n',i,fname(1:t-1));
        else
            FGTStrIdV(1) = find([planC{indexS.structures}.associatedScan]== preScanIdx);
            FGTStrIdV(2) = find([planC{indexS.structures}.associatedScan] == postDeformedScanIdx);
            
            %Save histogram of post-contrast intensities corresponding to each pre-contrast intensity to spreadsheet
            [edges,uqIntensityV,histM] = getPrePostHist(planC,FGTStrIdV,normFlag);
            fout = fullfile(fPath,[fname(1:t-1),'_histogram.xlsx']);
            saveHist(uqIntensityV,edges,histM,fout);
            
            %Save FGT ratio
            breastMaskM = getUniformStr(breastStrId, planC);
            maskSlices = find(squeeze(sum(sum(breastMaskM))));
            FGTStrId = find(strcmp(structListC,'hist_FGT'));
            FGT1Mask = getUniformStr(FGTStrId, planC);
            FGT1Ratio = nnz(FGT1Mask(:,:,maskSlices))/nnz(breastMaskM(:,:,maskSlices));
            fprintf(fid,'\n%d. %s | FGTRatio = %f\n',i,fname(1:t-1),FGT1Ratio);
        end
        
    catch
        sprintf('\nError processing pt: %s',patID);
        
    end
end
fclose(fid);

end