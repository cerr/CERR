function functionNameC = getSegWrapperFunc(condaEnvListC,algorithmC)
% function functionNameC = getSegWrapperFunc(condaEnvListC,algorithmC)
%
% This function returns the names of wrapper functions for the input
% algorithms and conda environments.
%
% APA, 3/2/2021

numAlgoritms = length(algorithmC);
functionNameC = cell(1,numAlgoritms);
for algoNum = 1:numAlgoritms
    switch upper(algorithmC{algoNum})
        case 'CT_ATRIA_DEEPLAB'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_Heart_DeepLab','model_wrapper','CT_Atria_DeepLab',...
                'runSegAtria.py');
            
        case 'CT_PERICARDIUM_DEEPLAB'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_Heart_DeepLab','model_wrapper','CT_Pericardium_DeepLab',...
                'runSegPericardium.py');
            
        case 'CT_VENTRICLES_DEEPLAB'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_Heart_DeepLab','model_wrapper','CT_Ventricles_DeepLab',...
                'runSegVentricles.py');
            
        case 'CT_HEARTSTRUCTURE_DEEPLAB'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_Heart_DeepLab','model_wrapper','CT_HeartStructure_DeepLab',...
                'runSegHeartStructure.py');
            
        case 'CT_HEARTSUBSTRUCTURES_DEEPLAB'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_Heart_DeepLab','model_wrapper','CT_HeartSubStructures_DeepLab',...
                'runSegHeartSubStructures.py');
            
        case 'CT_CHEWINGSTRUCTURES_DEEPLABV3'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_SwallowingAndChewing_DeepLabV3','model_wrapper',...
                'CT_ChewingStructures_DeepLabV3','chewing_main.py');
            
        case 'CT_PHARYNGEALCONSTRICTOR_DEEPLABV3'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_SwallowingAndChewing_DeepLabV3','model_wrapper',...
                'CT_PharyngealConstrictor_DeepLabV3',...
                'pharyngeal_constrictor_main.py');
            
        case 'CT_HEADANDNECK_SELFATTENTION'
            
        case 'CT_LARYNX_DEEPLABV3'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_SwallowingAndChewing_DeepLabV3','model_wrapper',...
                'CT_Larynx_DeepLabV3','larynx_main.py');
            
            
        case 'CT_LUNG_INCRMRRN'
            
        case 'MR_LUNGNODULES_TUMORAWARE'
            
        case 'MR_PROSTATE_DEEPLAB'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'MR_Prostate_Deeplab_ver2','model_wrapper',...
                'run_inference_mim_test_3D_V3.py');
            
        case 'MRCT_BRAINMETS_VNET'

        case 'CBCT_LUNGTUMOR_CMEDL'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CBCT_LungTumor_CMEDL','model_wrapper',...
                'inference_code.py');
            
        case 'CT_LUNGOAR_INCRMRRN'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_LungOAR_incrMRRN','model_wrapper',...
                'run_wrapper_Jue.py');
                      
        case 'CT_CBCT_LUNG_FULLSHOT_ANATOMICCTXSHAPE'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'CT_CBCT_Lung_Fullshot_AnatomicCtxShape','model_wrapper',...
                'run_code.py');
            
        case 'FDGPET_HEADANDNECK_PIX2PIX'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'fdg2fmiso_hn_pix2pix', 'infer_tbr.py');

        case 'MRI_PANCREAS_FULLSHOT_ANATOMICCTXSHAPE_LASTASBASE'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'MRI_Pancreas_Fullshot_AnatomicCtxShape','model_wrapper',...
                'run_inference_first_to_last.py');

       case 'MRI_PANCREAS_FULLSHOT_ANATOMICCTXSHAPE_FIRSTASBASE'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'MRI_Pancreas_Fullshot_AnatomicCtxShape','model_wrapper',...
                'run_inference_last_to_first.py');
            
        case 'ADC_PROSTDIL_MRRNDS'
            functionNameC{algoNum} = fullfile(condaEnvListC{algoNum},...
                'ADC_ProstDIL_MRRNDS','BasicSegmentation.py');

    end
    
end


