function batch_register_scans_with_struct_priors(baseScanFileNameC,...
    movScansFileNameC, basePriorStructNameC, movPriorStructNameC, ...
    movStrsToDeformC, movDoseToDeformC, registeredDir, paired_scans_flag)
% function batch_register_scans_with_struct_priors(baseScanFileNameC,...
%     movScansFileNameC, basePriorStructNameC, movPriorStructNameC, ...
%     strsToDeformC, registeredDir, paired_scans_flag)
%
% This script registers movScansFileNameC to baseScanFileNameC using
% basePriorStructNameC and movPriorStructNameC structure priors for initial alignment.
% Additionally, the structurnames specified in strsToDeformC are warped on to the base
% scan and the deformed images and segmwntation are written to registeredDir.
%
% APA, 12/30/2021


% RIDER template
% baseScan = '/lab/deasylab1/Data/RTOG0617/CERR_files_tcia/rider_template/RIDER-1225316081_First_resampled_1x1x3.mat';


% Directory containing CERR files
%movScanDir = '/lab/deasylab1/Data/RTOG0617/CERR_files_tcia/dose_mapping_original_plans'; % RTOG0617
%movScanDir = '/lab/deasylab1/Data/Lung_PORT/cerr_files'; % PORT
%movScanDir = '/lab/deasylab1/Maria/Heart_pCT_NSCLC/CERR/All_ph_1_pts_GTVcorrect/ATRIA_VENTR_PERI_DONE/N_241/0617structs_QAed_MT'; % OLD Conventional
% movScanDir = '/lab/deasylab1/Data/LA-NSCLC_Durva_N113/cerr_files_planning_only'; % NEW Conventional
%movScanDir = '/lab/deasylab1/Maria/Lung_EarlyStage_MSK_PFS_pCT_CT_PETCT/CERR_DCM_OMT_Validation/cerr_files_all_fx_corrected'; % MSK early stage Lung (fractionation corrected)


% Directory to write registered scans
%registeredDir = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/CERR_files_RTOG0617_to_RIDER_1225316081_First_template'; %RIDER RIDER-1225316081
%registeredDir = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/CERR_files_PORT_to_RIDER_1225316081_First_template'; %RIDER RIDER-1225316081
%registeredDir = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/CERR_files_OLD_CONVN_to_RIDER_1225316081_First_template'; %RIDER RIDER-1225316081
% registeredDir = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/CERR_files_NEW_CONVN_to_RIDER_1225316081_First_template'; %RIDER RIDER-1225316081
%registeredDir = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/CERR_files_MSK_EarlyStage_to_RIDER_1225316081_First_template'; % MSK early stage Lung (fractionation corrected)

if ~exist(registeredDir,'dir')
    mkdir(registeredDir)
end

% Filename to store dice scores
%diceSaveFileName = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/RTOG0617_peri_dice_RIDER.mat'; %RTOG0617
%diceSaveFileName = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/PORT_peri_dice_RIDER.mat'; %PORT
%diceSaveFileName ='/lab/deasylab1/Data/RTOG0617/registrations_pericardium/OLD_CONVN_peri_dice_RIDER.mat'; %OLD_CONVN
% diceSaveFileName ='/lab/deasylab1/Data/RTOG0617/registrations_pericardium/NEW_CONVN_peri_dice_RIDER.mat'; %NEW_CONVN
%diceSaveFileName = '/lab/deasylab1/Data/RTOG0617/registrations_pericardium/MSK_EarlyStage_peri_dice_RIDER.mat'; %EarlyStage
%
% strsToDeformC = {'DL_HEART_MT','DL_HEART','DL_AORTA', 'DL_LA', 'DL_LV', 'DL_RA', 'DL_RV', 'DL_IVC',...
%     'DL_SVC', 'DL_PA', 'DL_ATRIA', 'DL_PERICARDIUM', 'DL_VENTRICLES'};
% strsToDeformC = {'DL_HEART_MT','DL_PERICARDIUM'};
% strsToDeformC = {'DL_HEART','DL_PERICARDIUM'};

% movDirS = dir(movScanDir);
% movDirS([movDirS.isdir]) = [];
% movScanC = fullfile(movScanDir,{movDirS.name});

% registerToAtlasMultipleScans(baseScan,movScanC,registeredDir,...
%     strNameToWarp,initPlmCmdFile,refinePlmCmdFile)

%hpool = parpool(12);

% % Load base planC
% planC = loadPlanC(baseScan,tempdir);
% planC = updatePlanFields(planC);
% planC = quality_assure_planC(baseScan,planC);
% indexS = planC{end};
% 
% % Generate mask by excluding GTV
% indTumor = findTumorIndex(1,planC);
% baseMask3M = [];
% if length(indTumor) == 1
%     baseMask3M = ~getStrMask(indTumor,planC);
% end
% strC = {planC{indexS.structures}.structureName};
% pericardInd = getMatchingIndex('DL_PERICARDIUM',strC,'exact');
% basePeriMask3M = getStrMask(pericardInd,planC);
% % [minr, maxr, minc, maxc, mins, maxs,baseMask3M] = compute_boundingbox(baseMask3M,3);
% se = strel('sphere',5);
% basePeriMaskDilate3M = imdilate(basePeriMask3M, se);
% diffPeriMask3M = xor(basePeriMaskDilate3M,basePeriMask3M);
% planC{indexS.scan}(1).scanArray(diffPeriMask3M) = 5000;


for iBase = 1:length(baseScanFileNameC)
    
    if paired_scans_flag
        movScansFileToRegisterC = movScansFileNameC(iBase);
        movStrsToDeformToUseC = movStrsToDeformC(iBase);
        movPriorStructNameToUseC = movPriorStructNameC(iBase);
        movDoseToDeformToUseC = movDoseToDeformC(iBase);
    else
        movScansFileToRegisterC = movScansFileNameC;
        movStrsToDeformToUseC = movStrsToDeformC;
        movPriorStructNameToUseC = movStructNameC;
        movDoseToDeformToUseC = movDoseToDeformC;
    end
    
    baseScan = baseScanFileNameC{iBase};
    
    % Load base planC
    planC = loadPlanC(baseScan,tempdir);
    planC = updatePlanFields(planC);
    planC = quality_assure_planC(baseScan,planC);
    indexS = planC{end};
    
    % Mask to restrict cost function
    baseMask3M = [];

    
    baseLandmarkStrC = basePriorStructNameC{iBase}; %{'DL_PERICARDIUM'};
    baseScanNum = 1;
    strBaseC = {planC{indexS.structures}.structureName};
    baseLandmarkListM = [];
    xyzBaseM = zeros(length(baseLandmarkStrC),3);
    for iStr = 1:length(baseLandmarkStrC)
        baseLandmarkStr = baseLandmarkStrC{iStr};
        strIndV = getMatchingIndex(baseLandmarkStr,strBaseC,'exact');
        assocScanNumV = getStructureAssociatedScan(strIndV,planC);
        baseLandmarkInd = strIndV(assocScanNumV == baseScanNum);
        [baseX,baseY,baseZ] = calcIsocenter(baseLandmarkInd,'COM',planC);
        xyzBaseV = [baseX,baseY,baseZ];
        xyzBaseM(iStr,:) = xyzBaseV;
        [xBaseV,yBaseV,zBaseV] = getScanXYZVals(planC{indexS.scan}(baseScanNum));
        baseY =  -yBaseV(1)+(yBaseV(1)-baseY);
        baseZ = -zBaseV(end) + zBaseV(end) - baseZ;
        baseLandmarkListM(iStr,:,1) = [iStr-1, [-baseX,-baseY,baseZ]*10];
    end
    
    allPlanC = {planC};
    
    
    for movNum = 1:length(movScansFileToRegisterC)
        
        movScanFileName = movScansFileToRegisterC{movNum};
        
        %[~,fName] = fileparts(movScanFileName);
        %newFileName = fullfile(registeredDir,[fName,'.mat']);
        %if exist(newFileName,'file')
        %    continue;
        %end
        
        try
            
            %     baseStrNumV = [];
            %     movStrNumV = [];
            
            %     % Load base planC
            %     planC = loadPlanC(baseScan,tempdir);
            %     planC = updatePlanFields(planC);
            %     planC = quality_assure_planC(baseScan,planC);
            %     indexS = planC{end};
            %
            %     % Generate mask by excluding GTV
            %     indTumor = findTumorIndex(1,planC);
            %     if length(indTumor) == 1
            %         baseMask3M = ~getStrMask(indTumor,planC);
            %     end
            
            
            % Load moving planC as planD
            planD = loadPlanC(movScanFileName,tempdir);
            planD = updatePlanFields(planD);
            planD = quality_assure_planC(movScanFileName,planD);
            indexSD = planD{end};
            
            
            
            % Register all image representations to each other starting from the
            % transformation generated previously
            %numScans = length(planC{indexS.scan});
            %     numScans = 1;
            %     allStrNumV = 1:length(planD{indexSD.structures}); % -1 to omit the "noise" structure
            %     assocScanV = getStructureAssociatedScan(allStrNumV,planD);
            %
            %     outBspFile = '';
            
            %inputCmdFile = '';
            %     numScans = 1;
            scanNumV = 1;
            for iScan = 1:length(scanNumV)
                
                scanNum = scanNumV(iScan);
                
                % Registration settings
                registration_tool = 'PLASTIMATCH';
                plmSettingsFile = '/lab/deasylab1/Data/RTOG0617/plastimatch_registration_settings/plm_reg_settings_with_landmark_stiffness_pericard.txt';
                %plmSettingsFile = '//vpensmph/deasylab1/Data/RTOG0617/plastimatch_registration_settings/plm_reg_settings_with_landmark_stiffness_pericard.txt';
                %plmSettingsFile = 'L:/Data/RTOG0617/plastimatch_registration_settings/plm_reg_settings_with_landmark_stiffness_pericard.txt';
                %baseMask3M = [];
                movMask3M = [];
                threshold_bone = -800;
                inBspFile = '';
                outBspFile = '';
                %tmpDirPath = '/lab/deasylab1/Data/RTOG0617/cerr_registration_temp_dir';
                tmpDirPath = '/cluster/home/aptea/segSessions/registration_temp';
                %tmpDirPath = '//vpensmph/deasylab1/Data/RTOG0617/cerr_registration_temp_dir';
                %tmpDirPath = 'L:/Data/RTOG0617/cerr_registration_temp_dir';
                algorithm = 'BSPLINE PLASTIMATCH';
                
                %         % Generate mask by excluding GTV
                %         indTumor = findTumorIndex(scanNum,planD);
                %         if length(indTumor) == 1
                %             movMask3M = ~getStrMask(indTumor,planD);
                %         end
                %         strC = {planD{indexSD.structures}.structureName};
                %         pericardInd = getMatchingIndex('DL_PERICARDIUM',strC,'exact');
                %         movPeriMask3M = getStrMask(pericardInd,planD);
                %         %         [minr, maxr, minc, maxc, mins, maxs,movMask3M] = compute_boundingbox(movMask3M,3);
                %         movPeriMaskDilate3M = imdilate(movPeriMask3M, se);
                %         diffPeriMask3M = xor(movPeriMaskDilate3M,movPeriMask3M);
                %         planD{indexSD.scan}(1).scanArray(diffPeriMask3M) = 5000;
                
                
                % Generate Landmarks
                movLandmarkStrC = movPriorStructNameToUseC{movNum}; %{'DL_PERICARDIUM'};
                
                % Register planD to planC
                baseScanNum = scanNum;
                movScanNum  = scanNum;
                %strBaseC = {planC{indexS.structures}.structureName};
                strMovC = {planD{indexSD.structures}.structureName};
                landmarkListM = [];
                xyzMovM = nan(length(movLandmarkStrC),3);
                for iStr = 1:length(movLandmarkStrC)
                    movLandmarkStr = movLandmarkStrC{iStr};
                    strIndV = getMatchingIndex(movLandmarkStr,strMovC,'exact');
                    assocScanNumV = getStructureAssociatedScan(strIndV,planD);
                    movLandmarkInd = strIndV(assocScanNumV == movScanNum);
                    if length(movLandmarkInd) ~= 1
                        continue;
                    end
                    [movX,movY,movZ] = calcIsocenter(movLandmarkInd,'COM',planD);
                    xyzMovV = [movX,movY,movZ];
                    xyzMovM(iStr,:) = xyzMovV;
                    [xMovV,yMovV,zMovV] = getScanXYZVals(planD{indexSD.scan}(movScanNum));
                    movY =  -yMovV(1)+(yMovV(1)-movY);
                    movZ = -zMovV(end) + zMovV(end) - movZ;
                    landmarkListM(iStr,:,1) = baseLandmarkListM(iStr,:,1);
                    landmarkListM(iStr,:,2) = [iStr-1, [-movX,-movY,movZ]*10];
                end
                
                % Don't use landmarks (update it to use landmarks in future)
                landmarkListM = [];
                
                %         initialTranslationXyzV = xyzMovV-xyzBaseV;
                initialTranslationXyzM = xyzMovM - xyzBaseM;
                initialTranslationXyzV = nanmean(initialTranslationXyzM,1);
                initialTranslationXyzV(1) = initialTranslationXyzV(1);
                initialTranslationXyzV(2) = -initialTranslationXyzV(2);
                initialTranslationXyzV(3) = -initialTranslationXyzV(3);
                
                plnC = allPlanC{1};
                
                % Call registration wrapper
                plnC = register_scans(plnC, baseScanNum, planD, movScanNum,...
                    algorithm, registration_tool, tmpDirPath, baseMask3M,...
                    movMask3M, threshold_bone, plmSettingsFile, inBspFile,...
                    outBspFile, landmarkListM,initialTranslationXyzV);
                
                
                strCreationScanNum = scanNum;
                
                % Warp scan (already warped in register_scans.m)
                deformS = plnC{indexS.deform}(end);
                %planC = warp_scan(deformS,movScanNum,planD,planC);
                
                strsToDeformC = movStrsToDeformToUseC{movScanNum};
                
                movStructNumsV = [];
                strNamC = {planD{indexSD.structures}.structureName};
                for iStr = 1:length(strsToDeformC)
                    movStructNumsV = [movStructNumsV,...
                        getMatchingIndex(strsToDeformC{iStr},strNamC,'exact')];
                end
                
                %planC = warp_structures(deformS,strCreationScanNum,movStructNumsV,planD,planC);
                plnC = warp_structures(deformS,strCreationScanNum,movStructNumsV,planD,plnC,tmpDirPath);
                
                
                doseCreationScanNum = strCreationScanNum;
%                 numDoses = length(planD{indexSD.dose});
                doseToDeformC = movDoseToDeformToUseC{movScanNum}; % update to get the correct dose num
                if ~isempty(doseToDeformC)
                    doseNum = length(planD{indexSD.dose});
                    %for doseNum = 1:numDoses
                    %planC = warp_dose(deformS,doseCreationScanNum,doseNum,planD,planC);
                    plnC = warp_dose(deformS,doseCreationScanNum,doseNum,planD,plnC,tmpDirPath);
                    %end
                end
                
                % delete the output nrrd file
                if strcmpi(algorithm,'DEMONS PLASTIMATCH')
                    delete(outBspFile)
                end
                
            end
            
            if exist(inBspFile,'file')
                delete(inBspFile)
            end
            
            
            % Save base and moving scans
            [~,fName] = fileparts(movScanFileName);
            newFileName = fullfile(registeredDir,fName);
            save_planC(plnC,[],'passed',newFileName);
            
        catch
            
        end % end try-catch
        
    end  % Iterate over moving scans
    
end % Iterate over base scans

