% Wrapper file
close all, clear all, imtool close all, clc
global planC stateS
%  stateS.optS.IVHBinWidth = 0.2;
%% Sets path for input data
dirPath = '/home/ross/HandN_OUTCOME/HANDN_cerr/';
BSL(:,:) = struct('BSL',{},'sBSL',{},'maxBSL',{},'indMax',{});

fileC = {};
if strcmpi(dirPath,'\') || strcmpi(dirPath,'/')
    filesTmp = getCERRfiles(dirPath(1:end-1));
else
    filesTmp = getCERRfiles(dirPath);
end
fileC = [fileC filesTmp];
length(fileC)

% Output labels
['# Patient                            Region  SUVmax   SUVmean   SUVbkg    BSL    EquiThresh    EquiVol']

%% Load CERR plans
BKG = zeros(length(fileC));
BSL = zeros(length(fileC));
Thresh = zeros(length(fileC));
equiVol = zeros(length(fileC));
iplot = 0;
for iFile = 129:129%length(fileC)
    try
        planC = loadPlanC(fileC{iFile},tempdir);
        planC = updatePlanFields(planC);
        % Quality assure
        quality_assure_planC(fileC{iFile});
    catch
        disp([fileC{iFile}, ' failed to load'])
        continue
    end
    
    % Code to extract data out of planC., etc...
    fullFileName = fileC{iFile};
    %%
    
    % Initialize
    indexS = []; optS = []; numStr =[]; PT = []; RTS = [];
    s0 = []; X = []; Y = []; Z = [];
    
    % Get Scan Info
    indexS = planC{end};
    optS    = planC{indexS.CERROptions};
    headerPT = planC{indexS.scan}.scanInfo.DICOMHeaders;
    voxX = headerPT.PixelSpacing(1)/10;
    voxY = headerPT.PixelSpacing(2)/10;
    voxZ = headerPT.SliceThickness/10;
    voxVol = voxX*voxY*voxZ;
    
    % Get Scan
    PT = double(planC{indexS.scan}.scanArray);
    
    % Get Structure(s)
    RTS =[]; useRTS = 1;
    numStr = length(planC{indexS.structures});
    RTSname = lower({planC{indexS.structures}.structureName});
    for structNum = 1:numStr
        RTS(:,:,:,structNum) = +getUniformStr(structNum);
        if (strcmp(RTSname{:,structNum},'roi1') || strcmp(RTSname{:,structNum},'roi2') || strcmp(RTSname{:,structNum},'roi3') || strcmp(RTSname{:,structNum},'roi4') )
            iplot = iplot + 1;
            %subplot(14,14,iplot)
            useRTS = structNum;
            
            
            % Get VOI mask from Structure and associate PET data
            uSlices = []; maskRTS = []; maskRTStmp = [];
            scanNum                     = getStructureAssociatedScan(useRTS,planC);
            [rasterSeg, planC, isError] = getRasterSegments(useRTS,planC);
            if isempty(rasterSeg)
                warning('Could not create conotour.')
                return
            end
            [maskRTStmp, uSlices]      = rasterToMask(rasterSeg, scanNum, planC);
            maskRTS = double(maskRTStmp);
            rtsPT = PT(:,:,uSlices);
            
            % Estimate BSL
            [BSL(iFile), BKG(iFile), Thresh(iFile), equiVol(iFile), wsPT] = ...
                BSLestimate(rtsPT,double(maskRTS),voxVol);
            
            SUVmean(iFile) = BSL(iFile)/equiVol(iFile);
            SUVmax(iFile) = max(nonzeros(maskRTS.*rtsPT));
            
            PTthresh = wsPT.*rtsPT;
            PTthresh(PTthresh < Thresh(iFile)*max(PTthresh(:))) = 0;
            
            % Visualization
            regionPT = rtsPT; regionPT(regionPT < 0.1) = 0; regionPT(regionPT > 0) = 1;
            s0 = regionprops(regionPT, {'Centroid','BoundingBox'});
            x0(1) = s0.BoundingBox(2); x0(2) = s0.BoundingBox(2+3);
            y0(1) = s0.BoundingBox(1); y0(2) = s0.BoundingBox(1+3);
            z0(1) = s0.BoundingBox(3); z0(2) = s0.BoundingBox(3+3);
            X = floor( x0(1) + 1:x0(1) + x0(2) );
            Y = floor( y0(1) + 1:y0(1) + y0(2) );
            Z = floor( z0(1) + 1:z0(1) + z0(2) );

            imMatThresh = []; imMatRegion = []; imMat = []; imMat2 = [];
%             for i = 1:numel(Z)
%                 imMatThresh = [imMatThresh maskRTS(X,Y,i).*PTthresh(X,Y,i)];
%                 imMatRegion = [imMatRegion wsPT(X,Y,i).*rtsPT(X,Y,i)];
%                 imMat       = [imMat       maskRTS(X,Y,i).*rtsPT(X,Y,i)];
%                 imMat2      = [imMat2      rtsPT(X,Y,i)];
%             end
%             figure,imshow([imMatThresh ; imMatRegion ; imMat ; imMat2],[0 3*BKG(iFile)]);
%              drawnow
            
            % Output results
            % [iFile SUVmax(iFile) SUVmean(iFile) BKG(iFile) BSL(iFile) Thresh(iFile) equiVol(iFile)]
            [num2str(iFile) '  ' fullFileName '  ' RTSname{:,useRTS} '   ' num2str(SUVmax(iFile)) '   ' num2str(SUVmean(iFile)) '   ' num2str(BKG(iFile)) '   ' num2str(BSL(iFile)) '   ' num2str(Thresh(iFile)) '   ' num2str(equiVol(iFile))]
        else
            ['Region: ' RTSname{:,structNum}];
        end
    end
end

