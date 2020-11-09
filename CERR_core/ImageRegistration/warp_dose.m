function planC = warp_dose(deformS,doseCreationScanNum,movDoseNum,movPlanC,planC,tmpDirPath,inverseFlag)
% function planC = warp_dose(deformS,doseCreationScanNum,movPlanC,planC)
%
% APA, 07/19/2012

if ~exist('inverseFlag','var') 
    inverseFlag = 0;
end

if ~exist('tmpDirPath','var') || isempty(tmpDirPath)
    tmpDirPath = fullfile(getCERRPath,'ImageRegistration','tmpFiles');
end

indexMovS = movPlanC{end};
indexS = planC{end};

optS = getCERROptions();
plmFlag = 0; elxFlag = 0; antsFlag = 0;
% Create b-spline coefficients file
if isstruct(deformS)
    if ~inverseFlag
        baseScanUID = deformS.baseScanUID;
        movScanUID  = deformS.movScanUID;
    else
        baseScanUID = deformS.movScanUID;
        movScanUID  = deformS.baseScanUID;
    end
%     algorithm = deformS.algorithm;
    registration_tool = deformS.registration_tool;
    switch upper(registration_tool)
        case 'PLASTIMATCH'
            plmFlag = 1;
            disp('Plastimatch selected');
            bspFileName = fullfile(tmpDirPath,['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
            success = write_bspline_coeff_file(bspFileName,deformS.algorithmParamsS);
        case 'ELASTIX'
            elxFlag = 1;
            disp('Elastix selected');
        case 'ANTS'
            antsFlag = 1;
            disp('ANTs selected');
    end   
    
else
    bspFileName = deformS;
    indexS = planC{end};
    indexMovS = movPlanC{end};
    movScanNum = getDoseAssociatedScan(movDoseNum,movPlanC);
    movScanUID = movPlanC{indexMovS.scan}(movScanNum).scanUID;
    baseScanUID = planC{indexS.scan}(doseCreationScanNum).scanUID;
end

% Convert dose to .mha
movDoseUID = movPlanC{indexMovS.dose}(movDoseNum).doseUID;
randPart = floor(rand*1000);
movDoseUniqName = [movDoseUID,num2str(randPart)];
movDoseFileName = fullfile(tmpDirPath,['movDose_',movDoseUniqName,'.mha']);

% Write .mha file for this dose
success = createMhaDosesFromCERR(movDoseNum, movDoseFileName, movPlanC);

%write target space reference mha scan
refScanNum = findScanByUID(planC,baseScanUID);
[refScanUniqName, ~] = genScanUniqName(planC,refScanNum);
refScanFileName = fullfile(tmpDirPath,['baseScan_',refScanUniqName,'.mha']);
success = createMhaScansFromCERR(refScanNum, refScanFileName, planC);

% Generate name for the output .mha file
warpedMhaFileName = fullfile(tmpDirPath,['warped_dose_',baseScanUID,'_',movScanUID,'.mha']);

if plmFlag
    % Switch to plastimatch directory if it exists
    prevDir = pwd;
    plmCommand = 'plastimatch warp ';
    optName = fullfile(getCERRPath,'CERROptions.json');
    optS = opts4Exe(optName);
    if exist(optS.plastimatch_build_dir,'dir') && isunix
        cd(stateS.optS.plastimatch_build_dir)
        plmCommand = ['./',plmCommand];
    end
    
    % Issue plastimatch warp command with nearest neighbor interpolation
    %fail = system([plmCommand, '--input ', movDoseFileName, ' --output-img ',
    %warpedMhaFileName, ' --xf ', bspFileName, ' --algorithm itk']); %
    %ITK-based warping, consider adding it an an option.
    fail = system([plmCommand, '--input ', movDoseFileName, ' --output-img ', warpedMhaFileName, ' --xf ', bspFileName]);
    if fail % try escaping slashes
        system([plmCommand, '--input ', escapeSlashes(movDoseFileName), ' --output-img ', escapeSlashes(warpedMhaFileName), ' --xf ', escapeSlashes(bspFileName)])
    end
end

if antsFlag
            % ANTs path setup
        if ~exist(optS.antspath_dir,'dir')
            error(['ANTSPATH ' optS.antspath_dir ' not found on filesystem. Please review CERROptions.']);
        end
        antspath = fullfile(optS.antspath_dir,'bin');
        setenv('ANTSPATH', antspath);
        antsScriptPath = fullfile(optS.antspath_dir, 'Scripts');
        antsCERRScriptPath = fullfile(getCERRPath,'CERR_core','ImageRegistration','antsScripts');
        if isunix
            setenv('PATH',[antspath ':' antsScriptPath ':' antsCERRScriptPath ':' getenv('PATH')]);
            antsCommand = '';
        else
            setenv('PATH',[antspath ';' antsScriptPath ';' antsCERRScriptPath ';' getenv('PATH')]);
            antsCommand = '';
        end
        % generate transform command
        transformParams = buildAntsTransform(deformS.algorithmParamsS.antsWarpProducts);
        antsCommand = [antsCommand ' antsApplyTransforms -d 3 -r ' refScanFileName ' -i ' movDoseFileName ' -o ' warpedMhaFileName ' ' transformParams]; % ' ' interpParams];
        disp(antsCommand);
        system(antsCommand);
        disp('Warp complete, importing warped scan to planC...');
        
end


% Read the warped output .mha file within CERR
infoS  = mha_read_header(warpedMhaFileName);
data3M = mha_read_volume(infoS);
% [data3M,infoS] = readmha(warpedMhaFileName);
doseName = movPlanC{indexMovS.dose}(movDoseNum).fractionGroupID;
assocScanUID = planC{indexS.scan}(doseCreationScanNum).scanUID;
planC = dose2CERR(flipdim(permute(data3M,[2,1,3]),3),[],...
    ['Warped_',doseName],[],[],'UniformCT',[],'no',...
    assocScanUID,planC);

% Cleanup
try
    delete(movDoseFileName)
    delete(warpedMhaFileName)
    %delete(bspFileName)
end
try
    if isstruct(deformS)
        delete(bspFileName)
    end
end

% Switch back to the previous directory
% cd(prevDir)

% Get DICOMHeader for the original dose
dcmHeaderS = planC{indexS.dose}(movDoseNum).DICOMHeaders;
if ~isempty(dcmHeaderS)
    dcmHeaderS.PixelSpacing = [];
    dcmHeaderS.ImagePositionPatient = [];
    dcmHeaderS.ImageOrientationPatient = [];
    dcmHeaderS.GridFrameOffsetVector = [];
    dcmHeaderS.Rows = [];
    dcmHeaderS.Columns = [];
    dcmHeaderS.SliceThickness = [];
end
planC{indexS.dose}(end).DICOMHeaders = dcmHeaderS;


