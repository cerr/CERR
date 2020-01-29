function batchBoundingBox(fpath)
% batchBoundingBox(fpath);
% Batch code to create bounding box around the breast.
%------------------------------------------------------
%Inputs:
% fpath - Path to CERR files containing NFS, FS_pre, FS_post sequences
%------------------------------------------------------
%iyera@mskcc.org 5/8/18 

%Get list of files
dirS = dir([fpath,filesep,'*.mat']);
NFSscanNum = 1;
outFpath = fpath;


%Loop over files
for i = 1:length(dirS)
    
    try 
    fname = fullfile(fpath,dirS(i).name);
    fprintf('\n Processing file %s...',dirS(i).name);
    
    %Load file
    planC = loadPlanC(fname,tempdir);
    
    %Generate bounding box
    scan3M = getScanArray(NFSscanNum,planC);
    [bMaskLeft3M,bMaskRight3M] = getBreastMask(scan3M);
    
    %Convert to CERR structure
    planC = maskToCERRStructure(bMaskLeft3M,0,1,'Auto_bbox_right',planC);   %For 'FFP' position
    planC = maskToCERRStructure(bMaskRight3M,0,1,'Auto_bbox_left',planC);   %For 'FFP' position
    
    
    %Save plan
%     [~,outName,~] = fileparts(fname);
%     outName = [outName,'_autobbox.mat'];
    save_planC(planC,[],'passed',fullfile(outFpath,dirS(i).name));
    
%-------------- Save plots ------------------%     
%     h = getBreastBoundingBox(scan3M);
%     saveas(h,fullfile('B:\Soft\Apte\AxialFiles\IMAGINE\Batch2\Auto_test\plots',outname),'jpeg');
%     close(h);
%-----------------------------------------------%     
    catch e
        fprintf('\n Error with pt: %s. Message: ',fname, e.message);
    end
end
fprintf('\n Complete.');



end