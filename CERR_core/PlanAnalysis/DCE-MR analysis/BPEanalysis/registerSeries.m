function [planOutC,seriesIdxV] = registerSeries(planC,seriesIdxV,mask3M,breastMaskNum,cmdFile)


indexS = planC{end};

%Registration parameters
algorithm = 'BSPLINE PLASTIMATCH';
baseMask3M = mask3M;
movMask3M = mask3M;
threshold_bone = [];


%Register NFS to FS-pre
basePlanC = planC;
movPlanC = planC;
baseScanIndex = seriesIdxV(2);
movingScanIndex = seriesIdxV(1);
[basePlanC,movPlanC] = register_scans(basePlanC, movPlanC, baseScanIndex,...
    movingScanIndex, algorithm, baseMask3M, movMask3M, threshold_bone,cmdFile);
deformS = basePlanC{indexS.deform}(end);
reg1PlanC = warp_scan(deformS,movingScanIndex,movPlanC,basePlanC);
%Warp breast outline
seriesIdxV(1) = length(reg1PlanC{indexS.scan}); %Deformed NFS scan
movStructNum = breastMaskNum;
reg1PlanC = warp_structures(deformS,seriesIdxV(1),movStructNum,movPlanC,reg1PlanC);

%Register FS-post to FS pre
basePlanC = reg1PlanC;
movPlanC = reg1PlanC;
baseScanIndex = seriesIdxV(2);
movingScanIndex = seriesIdxV(3);
[basePlanC,movPlanC] = register_scans(basePlanC, movPlanC, baseScanIndex,...
    movingScanIndex, algorithm, baseMask3M, movMask3M, threshold_bone);
deformS = basePlanC{indexS.deform}(end);
reg2PlanC = warp_scan(deformS,movingScanIndex,movPlanC,basePlanC);
seriesIdxV(3) = length(reg2PlanC{indexS.scan});

planOutC = reg2PlanC;

end